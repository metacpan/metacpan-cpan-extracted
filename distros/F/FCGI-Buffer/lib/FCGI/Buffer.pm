package FCGI::Buffer;

use strict;
use warnings;

# FIXME: save_to treats /cgi-bin/foo.fcgi and /cgi-bin2/foo.fcgi as the same

# TODO: Features
# TODO: Plack::Middleware::Buffer, to bring this pipeline to PSGI.  That's a
#	better next step than async or Mojolicious routes, neither of which
#	fit a CGI output filter
# TODO: Explicit invalidation: purge(uri), cache tags, and a purge_expired()
#	for cron so that cleaning up doesn't depend upon page traffic
# TODO: A "cacheable" callback so that callers can decide for each response
# TODO: Compress more types: JSON, SVG, JS and XML are skipped since only text/*
#	qualifies.  Honour q= priorities, and write precompressed .gz and .br
#	static copies
# TODO: Honour Range requests when a cache is in use, and several ranges
# TODO: Honour the Expires header given by the script when caching
# TODO: stale-while-revalidate and stale-if-error, to serve an old copy if the
#	script fails
# TODO: Document web server rules so that an expired static link falls back to
#	the script rather than giving a 404
# TODO: save_to: include the full path of the script, which closes the FIXME above
# TODO: A metrics hook: hit ratio, bytes saved and the time taken by each stage
# TODO: save_to: max_bytes and a parameter allowlist, to go with max_pages
# TODO: Detect that a script died part way through its output for all content
#	types.  Only unterminated HTML is detected, see "How the output is sent"
#
# TODO: Technical debt
# TODO: Split up _send_output() with an explicit finish() and named stages:
#	parse, optimise, validate, cache, encode and emit
# TODO: A real header object instead of regular expressions on strings
# TODO: An HTML tokenizer instead of the regular expressions in
#	_optimise_content()
# TODO: HTML::Packer takes quadratic time on many unterminated <script> tags,
#	2.7 seconds for 400KB.  Report it upstream, or replace it with the above
# TODO: Harden the SQLite layer: schema versioning and WAL
# TODO: Write static pages atomically: write to a temporary file and rename it.
#	At the moment readers can see a partial page, and neither print nor
#	close is checked
# TODO: Move the RFC references from 7233 to 9110 and 9111, and record deliberate
#	deviations in the POD
# TODO: Remove the version from the X-FCGI-Buffer header's name.  It advertises
#	the exact version to every client, and changes with each release

use Digest::MD5;
use File::Path;
use File::Spec;
use IO::String;
use CGI::Info;
use Carp;
use HTTP::Date;
use DBI;
use Readonly;
use Scalar::Util;

Readonly my $DEFAULT_GENERATE_304 => 1;
Readonly my $FORM_TOKEN_COOKIE => 'csrf_token';
Readonly my $DEFAULT_GENERATE_LAST_MODIFIED => 1;
Readonly my $DEFAULT_COMPRESS_CONTENT => 1;
Readonly my $DEFAULT_OPTIMISE_CONTENT => 0;
Readonly my $DEFAULT_LINT_CONTENT => 0;
Readonly my $MIN_GZIP_LEN => 32;
Readonly my $DEFAULT_PROTOCOL => 'http';
Readonly my $DEFAULT_CACHE_DURATION => '10 minutes';
Readonly my $DEFAULT_SAVE_TO_TTL => 600;
Readonly my $DEFAULT_SAVE_TO_MAX_PAGES => 10000;
Readonly my $SAVE_TO_DATABASE => 'fcgi.buffer.sql';

# A client's max-age can change how long a page is kept, but not by more than this
Readonly my $MAX_CLIENT_CACHE_SECONDS => 600;

# The protocols that understand ETag, If-None-Match and If-Modified-Since
Readonly my $CONDITIONAL_PROTOCOL => qr/^HTTP\/(?:1\.1|[23](?:\.0)?)$/;

# Cache-Control directives, in a request or a response, which forbid using the
# server cache
Readonly my %NO_CACHE_DIRECTIVES => map { $_ => 1 } qw(no-store no-cache private);

# Request methods that are safe to answer from a cache or with a 304
Readonly my %SAFE_METHODS => map { $_ => 1 } qw(GET HEAD);

# The methods that FCGI::Buffer calls on the logger
Readonly my @LOGGER_METHODS => qw(trace debug info warn error);

# An ETag sent with compressed content ends in the name of the encoding
Readonly my $ENCODED_ETAG_SUFFIX => qr/-(?:gzip|br|zstd)"$/;

# Content encodings that we can produce, and the module needed for each
Readonly my %ENCODING_MODULE => (
	'gzip' => 'Compress::Zlib',
	'x-gzip' => 'Compress::Zlib',
	'br' => 'IO::Compress::Brotli',
	'zstd' => 'Compress::Zstd',
);

# Options to init() which can be changed at any time, and are only changed
# when a defined value is given
Readonly my @SAFE_OPTIONS => qw(
	generate_etag generate_last_modified compress_content optimise_content
	lint_content logger lingua generate_304
);

=head1 NAME

FCGI::Buffer - Verify, Cache and Optimise FCGI Output

=head1 VERSION

Version 0.23

=cut

our $VERSION = '0.23';

=head1 SYNOPSIS

FCGI::Buffer verifies the HTML that you produce by passing it through
C<HTML::Lint>.

FCGI::Buffer optimises FCGI programs by reducing, filtering and compressing
output to speed up the transmission and by nearly seamlessly making use of
client and server caches.

To make use of client caches, that is to say to reduce needless calls
to your server asking for the same data:

    use FCGI;
    use FCGI::Buffer;
    # ...
    my $request = FCGI::Request();
    while($request->FCGI::Accept() >= 0) {
        my $buffer = FCGI::Buffer->new();
        $buffer->init(
                optimise_content => 1,
                lint_content => 0,
        );
	# ...
    }

To also make use of server caches, that is to say,
to save regenerating output when different clients ask you for the same data,
you will need to create a cache.
But that's simple:

    use FCGI;
    use CHI;
    use FCGI::Buffer;

    # ...
    my $request = FCGI::Request();
    while($request->FCGI::Accept() >= 0) {
        my $buffer = FCGI::Buffer->new();
        $buffer->init(
	    optimise_content => 1,
	    lint_content => 0,
	    cache => CHI->new(driver => 'File')
        );
	if($buffer->is_cached()) {
	    # Nothing has changed - use the version in the cache
	    $request->Finish();
	    next;
	# ...
	}
    }

To temporarily prevent the use of server-side caches, for example, whilst
debugging before publishing a code change, set the NO_CACHE environment variable
to any value.

=head1 SUBROUTINES/METHODS

=cut

=head2 new

Create an FCGI::Buffer object.
Do one of these for each FCGI::Accept.

Takes the same options as init(), as a hash or a reference to a hash.

=head3 API SPECIFICATION

=head4 INPUT

	{
		generate_etag => { type => 'boolean', optional => 1 },
		generate_last_modified => { type => 'boolean', optional => 1 },
		generate_304 => { type => 'boolean', optional => 1 },
		compress_content => { type => 'boolean', optional => 1 },
		optimise_content => { type => 'integer', min => 0, max => 2, optional => 1 },
		lint_content => { type => 'boolean', optional => 1 },
		cache => { type => 'object', can => [ 'get_object', 'set', 'remove' ], optional => 1 },
		cache_key => { type => 'string', optional => 1 },
		cache_duration => { type => 'string', optional => 1 },
		save_to => { type => 'hashref', optional => 1 },
		info => { type => 'object', optional => 1 },
		lingua => { type => 'object', can => 'language', optional => 1 },
		logger => { type => 'object', can => [ 'trace', 'debug', 'info', 'warn', 'error' ], optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'FCGI::Buffer' }

Returns undef, with a warning, if it's called as a function or is given an odd
number of arguments.

=head3 FORMAL SPECIFICATION

	new
	  args? : OPTION -+-> VALUE
	  self! : BUFFER
	  selected : FILEHANDLE
	  ---
	  self!.old_buf = selected
	  selected' = self!.buf
	  self!.generate_etag = args?.generate_etag
	    if generate_etag is in dom args?,
	    otherwise it is true exactly when the protocol is conditional

=cut

sub new
{
	my $proto = shift;
	my $class = ref($proto) || $proto;

	# Use FCGI::Buffer->new(), not FCGI::Buffer::new()
	if(!defined($class)) {
		carp(__PACKAGE__, ': use ->new() not ::new() to instantiate');
		return;
	}

	# Handle hash or hashref arguments
	my %args;
	if((@_ == 1) && (ref $_[0] eq 'HASH')) {
		%args = %{$_[0]};
	} elsif((@_ % 2) == 0) {
		%args = @_;
	} else {
		carp(__PACKAGE__, ': Invalid arguments passed to new()');
		return;
	}

	# These need checking, which init() does
	my %checked;
	foreach my $option('cache', 'logger', 'save_to') {
		$checked{$option} = delete $args{$option} if(exists($args{$option}));
	}

	# Initialize buffer and object properties
	my $buf = IO::String->new() or croak(__PACKAGE__, ': Failed to initialize IO::String');
	my $rc = {
		buf => $buf,
		old_buf => select($buf),
		generate_304 => $DEFAULT_GENERATE_304,
		generate_last_modified => $DEFAULT_GENERATE_LAST_MODIFIED,
		compress_content => $DEFAULT_COMPRESS_CONTENT,
		optimise_content => $DEFAULT_OPTIMISE_CONTENT,
		lint_content => $DEFAULT_LINT_CONTENT,
		%args,
	};
	# $rc->{o} = ();

	# Premise 1: an ETag is only useful if the protocol supports If-None-Match
	# Premise 2: an explicit generate_etag argument is the caller's decision
	# Conclusion: default it from the protocol, but only when it isn't given
	if(!defined($rc->{generate_etag})) {
		$rc->{generate_etag} = _is_conditional_protocol() ? 1 : 0;
	}

	# Return the blessed object
	my $self = bless $rc, $class;
	$self->init(\%checked) if(%checked);
	return $self;
}

sub DESTROY
{
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	# Premise 1: anything from here on can fail, e.g. a logger or a cache
	# Premise 2: until this is done, all that the process prints goes into
	#	this buffer, which is about to disappear
	# Conclusion: this must be the first thing that is done
	select($self->{old_buf});

	# This can run while the caller's eval is unwinding
	local($@, $!, $?);

	# Premise 1: Perl only gives a warning for an exception in a destructor
	# Premise 2: the client would be given an empty response
	# Conclusion: catch it, and send the output as the script printed it
	return if(eval { $self->_send_output(); 1 });

	$self->_problem(__PACKAGE__ . ": $@");
	return if($self->{_sent});
	$self->{_sent} = 1;
	if(defined($self->{_raw}) && length($self->{_raw})) {
		print _to_bytes($self->{_raw});
	} else {
		# The script relied upon a cache that has now failed
		print "Status: 500 Internal Server Error\r\n\r\n";
	}
}

# Everything that the script printed has been buffered, process and send it
sub _send_output
{
	my $self = shift;

	if((!defined($self->{buf})) || (!defined($self->{buf}->getpos()))) {
		# Unlikely
		if($self->{'logger'}) {
			$self->{'logger'}->info('Nothing to send');
		}
		return;
	}
	my $pos = $self->{buf}->getpos();
	$self->{buf}->setpos(0);
	my $buf;
	read($self->{buf}, $buf, $pos);

	# Keep this before anything else that can fail, it's what will be sent if
	# something does
	$self->{_raw} = $buf;

	if($self->{'logger'}) {
		$self->{'logger'}->trace('>In ' . __PACKAGE__ . ' _send_output');
	}
	my $headers;
	($headers, $self->{body}) = split /\r?\n\r?\n/, $buf, 2;

	if($self->{'logger'}) {
		if($ENV{'HTTP_IF_NONE_MATCH'}) {
			$self->{logger}->debug("HTTP_IF_NONE_MATCH: $ENV{HTTP_IF_NONE_MATCH}");
		}
		if($ENV{'HTTP_IF_MODIFIED_SINCE'}) {
			$self->{logger}->debug("HTTP_IF_MODIFIED_SINCE: $ENV{HTTP_IF_MODIFIED_SINCE}");
		}
		$self->{logger}->debug("Generate_etag = $self->{generate_etag}, ",
			"Generate_304 = $self->{generate_304}, ",
			"Generate_last_modified = $self->{generate_last_modified}");
	}

	unless($headers || $self->is_cached()) {
		if($self->{'logger'}) {
			$self->{'logger'}->debug('There was no output');
		}
		if(!defined($headers)) {
			require HTTP::Status;
			HTTP::Status->import();

			if(!defined($self->{'status'})) {
				if($self->{'info'}) {
					$self->{'status'} = $self->{'info'}->status();
				} else {
					$self->{'status'} = 200;
				}
			}
			$self->{_sent} = 1;
			print 'Status: ', $self->{status}, ' ',
				HTTP::Status::status_message($self->{status}),
				"\n\n";
		}
		return;
	}
	$self->{send_body} = (defined($ENV{'REQUEST_METHOD'}) && ($ENV{'REQUEST_METHOD'} eq 'HEAD')) ? 0 : 1;

	if($headers) {
		$self->_set_content_type($headers);
	}

	if(defined($self->{body}) && ($self->{body} eq '')) {
		# E.g. if header of Location is given with no body, for
		#	redirection
		delete $self->{body};
		if($self->{cache}) {
			# Don't try to retrieve it below from the cache
			$self->{send_body} = 0;
		}
	} elsif(defined($self->{content_type})) {
		my @content_type = @{$self->{content_type}};
		if(defined($content_type[0]) && (lc($content_type[0]) eq 'text') && (lc($content_type[1]) =~ /^html/) && defined($self->{body}) && !$self->{_script_encoded}) {
			if($self->{optimise_content}) {
				# require HTML::Clean;
				require HTML::Packer;	# Overkill using HTML::Clean and HTML::Packer...

				if($self->{'logger'}) {
					$self->{'logger'}->trace('Packer');
				}

				# Whitespace is significant in these, in a <textarea>
				# it's the user's data
				my $preformatted = $self->_protect_preformatted();

				# Level 1 is one pass, higher levels repeat until
				# the body stops shrinking
				my $oldlength = length($self->{body});
				$self->_optimise_content();
				if($self->{optimise_content} >= 2) {
					while(length($self->{body}) < $oldlength) {
						$oldlength = length($self->{body});
						$self->_optimise_content();
					}
				}

				# If we're on http://www.example.com and have a link
				# to http://www.example.com/foo/bar.htm, change the
				# link to /foo/bar.htm - there's no need to include
				# the site name in the link
				my $info = $self->_info();
				my $href = $info->host_name();
				my $protocol = $info->protocol() || $DEFAULT_PROTOCOL;

				$self->{body} =~ s/<a\s+href="\Q$protocol\E:\/\/\Q$href\E"/<a href="\/"/gi;
				$self->{body} =~ s/<a\s+href="\Q$protocol\E:\/\/\Q$href\E(?=[\/?#])/<a href="/gi;
				$self->{body} =~ s/<a\s+href="\Q$protocol\E:\/\//<a href="\/\//gi;

				# If we're in "/cgi-bin/foo.cgi?arg1=a" replace
				# "/cgi-bin/foo.cgi?arg2=b" with "?arg2=b"
				# A link to "/cgi-bin/foo.cgi" with no arguments is
				# left alone, since href="" would mean the current
				# page, arguments and all

				my $script_name = $ENV{'SCRIPT_NAME'};
				if(defined($script_name) && ($script_name =~ /^\//)) {
					$self->{body} =~ s/<a\s+href="\Q$script_name\E(\?[^"]+)"/<a href="$1"/gi;
				}

				# TODO use URI->path_segments to change links in
				# /aa/bb/cc/dd.htm which point to /aa/bb/ff.htm to
				# ../ff.htm

				# TODO: <img border=0 src=...>
				$self->{body} =~ s/<img\s+src="\Q$protocol\E:\/\/\Q$href\E"/<img src="\/"/gi;
				$self->{body} =~ s/<img\s+src="\Q$protocol\E:\/\/\Q$href\E(?=[\/?#])/<img src="/gi;

				# Don't use HTML::Clean because of RT402
				# my $h = new HTML::Clean(\$self->{body});
				# # $h->compat();
				# $h->strip();
				# my $ref = $h->data();

				# Don't always do javascript 'best' since it's confused
				# by the common <!-- HIDE technique.
				my $options = {
					remove_comments => 1,
					remove_newlines => 0,
					do_stylesheet => 'minify'
				};
				if($self->{optimise_content} >= 2) {
					$options->{do_javascript} = 'best';
					# [^>] stops the tag running on into the
					# rest of the page
					$self->{body} =~ s/(<script[^>]*+>)\s*+<!--/$1/gi;
					$self->{body} =~ s/\/\/-->\s*+<\/script>/<\/script>/gi;
					$self->{body} =~ s/(<script[^>]*+>)\s++/$1/gi;
				}
				$self->{body} = HTML::Packer->init()->minify(\$self->{body}, $options);
				if($self->{optimise_content} >= 2) {
					# Change document.write("a"); document.write("b")
					# into document.write("a"+"b");
					# Premise 1: every substitution removes
					#	");document.write(" and adds "+"
					# Premise 2: so every substitution shortens the body
					# Conclusion: looping until nothing is substituted
					#	is the same as looping until it stops
					#	shrinking, and always terminates
					# Nothing may cross a </script>, otherwise
					# writes in different scripts get merged
					1 while($self->{body} =~ s{
						(<script\s+type\s*=\s*"text/javascript"\s*>)		# $1: opening tag, kept as written
						((?:(?!</script>).)*?)					# $2: code before the writes, within this script
						document\.write\(((?:(?!</script>)[^;])*?)\);\s*+	# $3: first argument
						document\.write\(((?:(?!</script>)[^;])*?)\)		# $4: second argument
					}{$1${2}document.write($3+$4)}gisx);
				}
				$self->_restore_preformatted($preformatted);
			}
			if($self->{lint_content}) {
				require HTML::Lint;
				HTML::Lint->import;

				if($self->{'logger'}) {
					$self->{'logger'}->trace('Lint');
				}
				my $lint = HTML::Lint->new();
				$lint->parse($self->{body});
				$lint->eof();

				if($lint->errors) {
					$headers = 'Status: 500 Internal Server Error';
					@{$self->{o}} = ('Content-type: text/plain');
					$self->{body} = '';
					foreach my $error ($lint->errors) {
						my $errtext = $error->where() . ': ' . $error->errtext() . "\n";
						if($self->{logger}) {
							$self->{logger}->warn($errtext);
						} else {
							warn($errtext);
						}
						$self->{body} .= $errtext;
					}
				}
			}
		}
	}

	if(defined($headers) && ($headers =~ /^Status:\s*(\d+)/mi)) {
		$self->{status} = $1;
	} elsif(defined($self->{info})) {
		$self->{status} = $self->{info}->status();
	} else {
		$self->{status} = 200;
	}

	if($self->{'logger'}) {
		$self->{'logger'}->debug("Initial status = $self->{status}");
	}

	# Range, Content-Length, compression and static pages all work in bytes.
	# A script which printed bytes is left alone: encoding those would
	# encode any UTF-8 in them a second time
	if(defined($self->{body})) {
		$self->{body} = _to_bytes($self->{body});
	}

	my $dbh = $self->_try('save_to database', sub { $self->_save_to_dbh() });

	my $encoding = $self->_should_gzip();

	# The cache and the static page hold the page with its links as the script
	# wrote them, since the links are looked at again for each request
	my $unzipped_body = $self->{body};

	# Premise 1: the ETag says which version of the page the client has
	# Premise 2: changing a link gives a different version
	# Conclusion: change the links first, otherwise a client with the old links
	#	is told by a 304 that they're still current
	if(defined($unzipped_body) && ($self->{status} == 200)) {
		$self->_save_to($unzipped_body, $dbh);
	}

	# Generate the eTag before compressing, since the compressed data
	# includes the mtime field which changes thus causing a different
	# Etag to be generated
	if($self->{generate_etag} && defined($self->{body}) && _is_conditional_protocol()) {
		$self->_generate_etag();

		if($ENV{'HTTP_IF_NONE_MATCH'} && $self->{generate_304} && ($self->{status} == 200)) {
			$self->_check_if_none_match();
		}
	}

	if(defined($unzipped_body)) {
		# Conditions are looked at before Range, and If-Modified-Since
		# isn't looked at if If-None-Match was checked and failed.
		# _check_modified_since() checks generate_304 itself
		if((!$self->{cache}) && $self->{info} && $ENV{'HTTP_IF_MODIFIED_SINCE'} && ($self->{status} == 200) &&
		   !($ENV{'HTTP_IF_NONE_MATCH'} && defined($self->{etag}))) {
			$self->_check_modified_since({
				since => $ENV{'HTTP_IF_MODIFIED_SINCE'},
				modified => $self->_my_age()
			});
		}

		my $range = $ENV{'Range'} || $ENV{'HTTP_RANGE'};

		# Only a successful GET can be cut up, and only if the client's
		# copy, if it has given one, is still the current one
		if($range && !$self->{cache} && ($self->{status} == 200) && _is_get() && $self->_if_range_matches() &&
		   defined(my $partial = _apply_range($self->{body}, $range))) {
			# Premise 1: Content-Range counts the bytes of what is sent
			# Premise 2: the offsets the client gave are in the page,
			#	not in a compressed copy which isn't the same each time
			# Conclusion: a part of a page is never compressed
			$encoding = '';
			$self->{_partial} = 1;
			$self->_set_status($partial->{status});
			push @{$self->{o}}, "Content-Range: $partial->{content_range}";
			if($partial->{status} == 416) {
				# Range Not Satisfiable has no body
				delete $self->{body};
				undef $unzipped_body;
				$self->{send_body} = 0;
			} else {
				$self->{body} = $unzipped_body = $partial->{body};
			}
		}
		# A 304 or 412 has no body to compress, and mustn't say that it has
		if($self->{send_body} || ($self->{status} == 200)) {
			$self->_compress({ encoding => $encoding });
		}
	}

	if($self->{cache}) {
		require Storable;

		if($self->{'cache_age'}) {
			# Legacy
			$self->{'cache_duration'} = $self->{'cache_age'};
		}

		my $cache_hash;
		my $key = $self->_generate_key();

		# Cache unzipped version
		if(!defined($self->{body})) {
			if($self->{send_body}) {
				# is_cached() has already looked, and it mustn't
				# have expired since then
				$self->{cobject} ||= $self->_cache_lookup($key);
				if(defined($self->{cobject})) {
					$cache_hash = Storable::thaw($self->{cobject}->value());
					$headers = $cache_hash->{'headers'};
					$self->_set_content_type($headers);
					@{$self->{o}} = ("X-FCGI-Buffer-$VERSION: Hit", @{$self->_x_cache_headers('HIT', 'HIT')});
				} elsif($self->{logger}) {
					$self->{logger}->warn(ref($self), ": Error retrieving data for key $key");
				} else {
					carp(ref($self), ": error retrieving data for key $key");
				}
			}

			if($self->{send_body} && ($self->{status} == 200) && defined($cache_hash)) {
				$self->{body} = _to_bytes($cache_hash->{'body'});
				if($dbh) {
					$self->_save_to($self->{body}, $dbh);
				}
				if(!defined($self->{body})) {
					# Panic
					$headers = 'Status: 500 Internal Server Error';
					@{$self->{o}} = ('Content-type: text/plain');
					$self->{body} = "Can't retrieve body for key $key, cache_hash contains:\n";
					foreach my $k (keys %{$cache_hash}) {
						$self->{body} .= "\t$k\n";
					}

					$self->_try('removing a bad entry', sub {
						if($dbh) {
							my $query = 'SELECT DISTINCT path FROM fcgi_buffer WHERE key = ?';
							my $sth = $dbh->prepare($query);
							if($self->{logger}) {
								$self->{logger}->debug("$query: $key");
							}
							if($sth->execute($key) && (my $href = $sth->fetchrow_hashref())) {
								if(my $path = $href->{'path'}) {
									unlink($path);
								}
							}
							$query = 'DELETE FROM fcgi_buffer WHERE key = ?';
							$dbh->do($query, undef, $key);
							if($self->{logger}) {
								$self->{logger}->debug("$query: $key");
							}
						}

						$self->{cache}->remove($key);
					});

					if($self->{logger}) {
						$self->{logger}->error("Can't retrieve body for key $key");
						$self->{logger}->warn($self->{body});
					} else {
						carp("Can't retrieve body for key $key");
						warn($self->{body});
					}
					$self->{send_body} = 0;
					$self->_set_status(500);
				}
			}
			if($self->{send_body} && ($self->{status} == 200) && $self->{generate_etag} && ((!defined($headers)) || ($headers !~ /^ETag: /m))) {
				$self->_generate_etag();
			}
			unless($self->{etag}) {
				# Keep the quotes, they're part of the ETag and
				# If-None-Match includes them
				if(defined($headers) && ($headers =~ /^ETag:\s*("[a-f0-9]{32}")/mi)) {
					$self->{etag} = $1;
				} else {
					$self->{etag} = $cache_hash->{'etag'};
				}
			}
			# Nothing has been output yet, so we can check if it's OK to
			# send 304 if possible.
			# Premise 1: the ETag includes any changes to the links, the
			#	date doesn't, and browsers send both
			# Premise 2: RFC 9110 13.1.3 says not to look at the date if
			#	there's an If-None-Match
			# Conclusion: only one of them is ever looked at
			# _check_modified_since() checks generate_304 itself
			if($self->{status} == 200) {
				if($ENV{'HTTP_IF_NONE_MATCH'} && defined($self->{etag})) {
					if($self->{generate_304}) {
						$self->_check_if_none_match();
					}
				} elsif($ENV{'HTTP_IF_MODIFIED_SINCE'} && $self->{cobject}) {
					$self->_check_modified_since({
						since => $ENV{'HTTP_IF_MODIFIED_SINCE'},
						modified => $self->{cobject}->created_at()
					});
				}
			}
			# A 304 has no body to compress, and mustn't say that it has
			if(($self->{status} == 200) && $self->{send_body}) {
				$encoding = $self->_should_gzip();
				$self->_compress({ encoding => $encoding });
			}
			if($self->{cobject}) {
				if(($self->{status} == 200) && $self->{generate_last_modified}) {
					if($self->{logger}) {
						$self->{logger}->debug('Set Last-Modified to ', HTTP::Date::time2str($self->{cobject}->created_at()));
					}
					push @{$self->{o}}, 'Last-Modified: ' . HTTP::Date::time2str($self->{cobject}->created_at());
				}
			}
		} else {
			# Not in the server-side cache
			if($self->{status} == 200) {
				unless($self->{cache_duration}) {
					# It would be great if CHI::set()
					# allowed the time to be 'lru' for least
					# recently used.
					$self->{cache_duration} = $DEFAULT_CACHE_DURATION;
				}
				$cache_hash->{'body'} = $unzipped_body;

				my $storable = $self->_is_storable($headers, $unzipped_body);
				if($storable) {
					if($self->{o} && scalar(@{$self->{o}})) {
						# Remember, we're storing the UNzipped
						# version in the cache.  An Expires that
						# was generated here is about the links
						# in this response, and they are looked
						# at again for each request
						my $generated = join("\r\n", grep { !/^Expires:/i } @{$self->{o}});
						my $c;
						if(defined($headers) && length($headers)) {
							$c = "$headers\r\n$generated";
						} else {
							$c = $generated;
						}
						$c =~ s/^Content-Encoding: .+$//mgi;
						$c =~ s/^Content-Length: .+$//mgi;
						$c =~ s/^Vary: Accept-Encoding.*\r?$//mgi;
						$c =~ s/\n+/\n/gs;
						if(length($c)) {
							$cache_hash->{'headers'} = $c;
						}
					} elsif(defined($headers) && length($headers)) {
						my $c = $headers;
						$c =~ s/^Content-Encoding: .+$//mgi;
						$c =~ s/^Content-Length: .+$//mgi;
						$c =~ s/^Vary: Accept-Encoding.*\r?$//mgi;
						$c =~ s/\n+/\n/gs;
						if(length($c)) {
							$cache_hash->{'headers'} = $c;
						}
					}
					if($self->{generate_etag}) {
						$self->_generate_etag();
						$cache_hash->{'etag'} = $self->{etag};
					}
					if($self->{logger}) {
						$self->{logger}->debug("Store $key in the cache, age = ", $self->{cache_duration}, ' ', length($cache_hash->{'body'}), ' bytes');
					}
					$self->_try('storing in the cache', sub {
						$self->{cache}->set($key, Storable::freeze($cache_hash), $self->{cache_duration});
					});

					# Create a static page with the information and link to that in the output
					# HTML
					# Pages whose content depends on who the client is are
					# never saved, since anyone following the static
					# link would be given them
					if($dbh && $self->{info} && $self->{save_to} && (my $request_uri = $ENV{'REQUEST_URI'}) && $self->_is_html() && !_is_per_client()) {
						$self->_try('writing a static page', sub {
							$self->_write_static_page($key, $unzipped_body, $dbh, $request_uri);
						});
					}
				}
				if($self->{generate_last_modified}) {
					$self->{cobject} = $storable ? $self->_cache_lookup($key) : undef;
					if(defined($self->{cobject})) {
						push @{$self->{o}}, 'Last-Modified: ' . HTTP::Date::time2str($self->{cobject}->created_at());
					} else {
						push @{$self->{o}}, 'Last-Modified: ' . HTTP::Date::time2str(time);
					}
				}
			}
			push @{$self->{o}}, @{$self->_x_cache_headers(defined($self->{x_cache}) ? $self->{x_cache} : 'MISS', 'MISS')}, "X-FCGI-Buffer-$VERSION: Miss";
		}
		# We don't need it any more, so give Perl a chance to
		# tidy it up seeing as we're in the destructor
		delete $self->{cache};
	} elsif($self->{info}) {
		push @{$self->{o}}, @{$self->_x_cache_headers('MISS', 'MISS')};
		if($self->{generate_last_modified}) {
			if(my $age = $self->_my_age()) {
				push @{$self->{o}}, 'Last-Modified: ' . HTTP::Date::time2str($age);
			}
		}
	} else {
		push @{$self->{o}}, @{$self->_x_cache_headers('MISS', 'MISS')};
	}

	# The branch that was taken when there was no ETag had an empty body,
	# but called is_cached() which looks in the cache, so it is removed
	$self->_add_vary($headers);

	if($self->{generate_etag} && defined($self->{etag}) && ((!defined($headers)) || ($headers !~ /^ETag:/mi))) {
		# The compressed and the uncompressed versions aren't the same
		# bytes, so can't have the same strong ETag.
		# _check_if_none_match() removes the suffix again, and a 304 is
		# about the copy that the client has so gives back its ETag
		my $etag = defined($self->{_matched_etag}) ? $self->{_matched_etag} : $self->{etag};
		if($self->{_content_encoding} && !defined($self->{_matched_etag})) {
			$etag =~ s/"$/-$self->{_content_encoding}"/;
		}
		push @{$self->{o}}, "ETag: $etag";
		if($self->{logger}) {
			$self->{logger}->debug("Set ETag to $etag");
		}
	}

	my $body_length = 0;
	if(defined($self->{body})) {
		$self->{body} = _to_bytes($self->{body});
		$body_length = length($self->{body});
	}

	if(defined($headers) && length($headers)) {
		# Put the original headers first, then those generated within
		# FCGI::Buffer.  The script is free to end its lines with \n
		unshift @{$self->{o}}, grep { length } split(/\r?\n/, $headers);

		# The body may well have changed since the script worked out its
		# length
		if(defined($self->{body})) {
			@{$self->{o}} = grep { !/^Content-Length:/i } @{$self->{o}};
		}
		if($body_length && $self->{send_body}) {
			push @{$self->{o}}, "Content-Length: $body_length";
		}
		$self->_set_status_header();
	} else {
		push @{$self->{o}}, "X-FCGI-Buffer-$VERSION: No headers";
	}

	@{$self->{o}} = _one_expires(@{$self->{o}});

	if($body_length && $self->{send_body}) {
		push @{$self->{o}}, ('', $self->{body});
	}

	# The Wide character debugging code that was here was inside if(0), so
	# could never run
	$self->{_sent} = 1;
	if(scalar(@{$self->{o}})) {
		print join("\r\n", @{$self->{o}});
	}

	if(!($self->{send_body} && defined($self->{body}))) {
		print "\r\n\r\n";
	}
}

sub _generate_etag {
	my $self = shift;

	return if defined($self->{'etag'});
	return unless defined($self->{'body'});

	# bytes to avoid "Wide character in subroutine entry"
	$self->{etag} = '"' . Digest::MD5->new->add(_to_bytes($self->{body}))->hexdigest() . '"';
	if($self->{'logger'}) {
		$self->{'logger'}->debug('Etag = ', $self->{'etag'});
	}
}

sub _check_modified_since {
	my $self = shift;

	if($self->{logger}) {
		$self->{logger}->trace('In _check_modified_since');
	}

	if(!$self->{generate_304}) {
		return;
	}
	# RFC 9110 13.1.3: If-Modified-Since is ignored for other methods
	return unless(_is_safe_method());

	my $params = shift;

	if(!defined($$params{since})) {
		return;
	}
	my $s = HTTP::Date::str2time($$params{since});
	if(!defined($s)) {
		if($self->{logger}) {
			$self->{logger}->info("$$params{since} is not a valid date");
		}
		return;
	}

	my $age = $self->_my_age();
	if(!defined($age)) {
		if($self->{logger}) {
			$self->{logger}->info("Can't determine my age");
		}
		return;
	}
	if($age > $s) {
		if($self->{logger}) {
			$self->{logger}->debug('_check_modified_since: script has been modified');
		}
		# Script has been updated so it may produce different output
		return;
	}

	if($self->{logger}) {
		$self->{logger}->debug("_check_modified_since: Compare $$params{modified} with $s");
	}
	if($$params{modified} <= $s) {
		push @{$self->{o}}, 'Status: 304 Not Modified';
		$self->_set_status(304);
		$self->{send_body} = 0;
		if($self->{logger}) {
			$self->{logger}->debug('Set status to 304');
		}
	}
}

# Reduce output, e.g. remove superfluous white-space.
sub _optimise_content {
	my $self = shift;

	# FIXME: regex bad, HTML parser good
	# Regexp::List - wow!
	# Remove whitespace around newlines.  Possessive quantifiers and only
	# starting at the beginning of a run of whitespace keep it linear
	$self->{body} =~ s{
		(?<![^\S\n])	# start only at the beginning of a whitespace run
		[^\S\n]*+	# trailing spaces, tabs and \r before the newline
		\n
		\s*+		# blank lines and indentation after it
	}{\n}gx;
	# $self->{body} =~ s/\r\n/\n/gs;
	# $self->{body} =~ s/\s+\n/\n/gs;
	# $self->{body} =~ s/\n+/\n/gs;
	# $self->{body} =~ s/\n\s+|\s+\n/\n/g;
	$self->{body} =~ s/\<\/div\>\s+\<div/\<\/div\>\<div/gis;
	# $self->{body} =~ s/\<\/p\>\s\<\/div/\<\/p\>\<\/div/gis;
	# $self->{body} =~ s/\<div\>\s+/\<div\>/gis;	# Remove spaces after <div>
	# In these, (?<!\s) and possessive quantifiers stop each alternation
	# being retried at every position inside a long run of whitespace
	$self->{body} =~ s/(?:<div>\s++|(?<!\s)\s++<div>)/<div>/gi;
	$self->{body} =~ s/\s+<\/div\>/\<\/div\>/gis;	# Remove spaces before </div>
	$self->{body} =~ s/(?:(?<!\s)\s++<p>|<p>\s++)/<p>/i;	# TODO <p class=
	$self->{body} =~ s/(?:(?<!\s)\s++<\/p>|<\/p>\s++)/<\/p>/gi;
	$self->{body} =~ s/<html>\s+<head>/<html><head>/is;
	$self->{body} =~ s/(?<!\s)\s*+<\/head>\s++<body>\s*+/<\/head><body>/i;
	$self->{body} =~ s/<html>\s+<body>/<html><body>/is;
	$self->{body} =~ s/<body>\s+/<body>/is;
	$self->{body} =~ s/\s+\<\/html/\<\/html/is;
	$self->{body} =~ s/\s+\<\/body/\<\/body/is;
	# $self->{body} =~ s/(\<.+?\>\s\<.+?\>)\s/$1/g;
	$self->{body} =~ s/\<p\>\s/\<p\>/gi;
	$self->{body} =~ s/\<\/p\>\s\<p\>/\<\/p\>\<p\>/gi;
	$self->{body} =~ s/\<\/tr\>\s\<tr\>/\<\/tr\>\<tr\>/gi;
	$self->{body} =~ s/\<\/td\>\s\<\/tr\>/\<\/td\>\<\/tr\>/gi;
	$self->{body} =~ s/\<\/td\>\s*\<td\>/\<\/td\>\<td\>/gis;
	$self->{body} =~ s/\<\/tr\>\s\<\/table\>/\<\/tr\>\<\/table\>/gi;
	$self->{body} =~ s/\<br\s?\/?\>\s?\<p\>/\<p\>/gi;
	$self->{body} =~ s/\<br\>\s+/\<br\>/gi;
	$self->{body} =~ s/\s+\<br/\<br/gi;
	$self->{body} =~ s/\<br\s?\/\>\s/\<br \/\>/gi;
	$self->{body} =~ s/[ \t]+/ /gs;	# Remove duplicate space, don't use \s+ it breaks JavaScript
	$self->{body} =~ s/\s\<p\>/\<p\>/gi;
	$self->{body} =~ s/\s\<script/\<script/gi;
	$self->{body} =~ s/(<script>\s|\s<script>)/<script>/gis;
	$self->{body} =~ s/(<\/script>\s|\s<\/script>)/<\/script>/gis;
	$self->{body} =~ s/\<td\>\s/\<td\>/gi;
	# The link can't leave its quotes, so these can't span tags or
	# backtrack across the rest of the page
	$self->{body} =~ s{
		(?<!\s)\s++		# a whole run of whitespace, starting at its first character
		<a\shref="([^"]*+)">	# $1: the link
		\s?
	}{ <a href="$1">}gix;
	$self->{body} =~ s{
		\s?
		<a\shref=\s"([^"]*+)">	# $1: the link
	}{ <a href="$1">}gix;
	$self->{body} =~ s/\s+<\/a\>\s+/<\/a> /gis;
	$self->{body} =~ s/(?:\s?<hr>\s++|(?<!\s)\s++<hr>\s?)/<hr>/gi;
	# $self->{body} =~ s/\s<hr>/<hr>/gis;
	# $self->{body} =~ s/<hr>\s/<hr>/gis;
	$self->{body} =~ s/<\/li>\s+<li>/<\/li><li>/gis;
	$self->{body} =~ s/<\/li>\s+<\/ul>/<\/li><\/ul>/gis;
	$self->{body} =~ s/<ul>\s+<li>/<ul><li>/gis;
	$self->{body} =~ s/\s+<\/li>/<\/li>/gis;
	$self->{body} =~ s/\<\/option\>\s+\<option/\<\/option\>\<option/gis;
	# A title can't contain a tag.  [^<] and the possessive quantifiers stop
	# each unterminated <title> from being searched to the end of the page
	$self->{body} =~ s{<title>\s*+([^<]*+)</title>}{
		my $title = $1;
		$title =~ s/(?<!\s)\s++\z//;
		"<title>$title</title>"
	}eix;
	$self->{body} =~ s/<\/center>\s+<center>/ /gis;
}

# Create a key for the cache
sub _generate_key {
	my $self = shift;
	if($self->{cache_key}) {
		return $self->{cache_key};
	}
	$self->_info();

	my $key = __PACKAGE__ . '::' . $self->{info}->browser_type() . '::' . $self->{info}->domain_name() . '::' . $self->{info}->script_name() . '::' . $self->{info}->as_string();

	if(defined($ENV{'PATH_INFO'}) && length($ENV{'PATH_INFO'})) {
		# /cgi-bin/foo.fcgi/bar and /cgi-bin/foo.fcgi/baz are different pages
		$key .= '::PATH_INFO=' . $ENV{'PATH_INFO'};
	}
	if($self->{lingua}) {
		$key .= '::' . $self->{lingua}->language();
	}
	# Different states of the client are stored in different caches
	foreach my $cookie(_client_cookies()) {
		$key .= "::$cookie";
	}

	# The key is needed before the script has given its headers, so a Vary
	# header can't be part of it.  _is_storable() doesn't store those pages
	$key =~ s/\//::/g;
	$key =~ s/(?:::){2,}/::/g;
	$key =~ s/::$//;
	if(defined($self->{logger})) {
		$self->{logger}->trace("Returning $key");
	}
	$self->{cache_key} = $key;
	return $key;
}

=head2 init

Set various options and override default values.

    # Put this toward the top of your program before you do anything
    # By default, generate_etag, generate_304 and compress_content are ON,
    # optimise_content and lint_content are OFF.  Set optimise_content to 2 to
    # do aggressive JavaScript optimisations which may fail.
    use FCGI::Buffer;

    my $buffer = FCGI::Buffer->new()->init({
	generate_etag => 1,	# make good use of client's cache
	generate_last_modified => 1,	# more use of client's cache
	compress_content => 1,	# if gzip the output
	optimise_content => 0,	# optimise your program's HTML, CSS and JavaScript
	cache => CHI->new(driver => 'File'),	# cache requests
	cache_key => 'string',	# key for the cache
	cache_duration => '10 minutes',	# how long to store responses in the cache
	logger => $self->{logger},
	lint_content => 0,	# Pass through HTML::Lint
	generate_304 => 1,	# When appropriate, generate 304: Not modified
	save_to => { directory => '/var/www/htdocs/save_to', ttl => 600, create_table => 1, max_pages => 10000 },
	info => CGI::Info->new(),
	lingua => CGI::Lingua->new(),
    });

If no cache_key is given, one will be generated which may not be unique.
The cache_key should be a unique value dependent upon the values set by the
browser.

The cache object will be an object that understands get_object(),
set(), remove() and created_at() messages, such as an L<CHI> object. It is
used as a server-side cache to reduce the need to rerun database accesses.

Items stay in the server-side cache by default for 10 minutes, the default can
be changed by the cache_duration argument to init().
An item that has expired is no longer used.
The max-age directive of the client's Cache-Control HTTP header overrides this
if it's a number no larger than 600 seconds.
A larger value or something that isn't a number is ignored,
so a client can't fill your cache with items that are kept for years.

Responses are not stored in the server-side cache if the script's headers
include Set-Cookie,
or a Cache-Control of no-store, no-cache or private,
or a Content-Encoding,
or a Vary on anything except Accept-Encoding
(and Accept-Language, if a lingua argument has been given),
or if the output is an HTML page with an <html> tag but no </html> tag,
which suggests that the script died part way through.
If your script finds an error after printing other types of content,
turn off the cache and save_to as described below.

Save_to is feature which stores output of dynamic pages to your
htdocs tree and replaces future links that point to that page with static links
to avoid going through CGI at all.
Ttl is set to the number of seconds that the static pages are deemed to
be live for, the default is 10 minutes.
If set to 0, the page is live forever.
A page that has passed its ttl is saved again the next time it's requested,
and is removed when any page is requested.
Max_pages is the most static pages to keep, the default is 10000, and 0 means no
limit.
It stops a client from filling your disc by asking for many different arguments.
Create_table says to create the table in the database if it doesn't exist.
To enable save_to, info and cache arguments must also be given,
and a lingua argument should be given if the output depends on the language.
Without a cache no static pages are written.
The directory must be inside the document root,
otherwise the static pages can't be linked to, so save_to is turned off and a
warning given once.
Only use where output is guaranteed to be the same with a given set of arguments
(the same criteria for enabling generate_304).
Only HTML pages are saved.
Pages generated for clients that send cookies (other than Google Analytics
cookies and C<csrf_token>) or have logged in, or those that aren't stored in the server-side
cache for the reasons above, are not saved,
since the static page would be given to everyone.
Those cookies don't change which entry in the server-side cache is used,
so a script whose output depends on one must send a Set-Cookie header with that
output.
A page that includes the value of the C<csrf_token> cookie is never stored.
Links can give the arguments of a page in any order.
Several virtual hosts can share a directory.
You can turn it off on a case by case basis thus:

    my $params = CGI::Info->new()->params();
    if($params->{'send_private_email'}) {
        $buffer->init('save_to' => undef);
    }

Info is an optional argument to give information about the FCGI environment, e.g.
a L<CGI::Info> object.

Logger will be an object that understands trace(), debug(), info(), warn() and
error(), such as an L<Log::Log4perl> object.
A logger without those is ignored, with a warning.
is_debug() is also used, if it's there.

A Last-Modified header is generated if you give a cache object or an info
object, since the time comes from when the cache entry was created or from the
script's file.

Init allows a reference of the options to be passed. So both of these work:

    use FCGI::Buffer;
    #...
    my $buffer = FCGI::Buffer->new();
    $buffer->init(generate_etag => 1);
    $buffer->init({ generate_etag => 1, info => CGI::Info->new() });

Generally speaking, passing by reference is better since it copies less on to
the stack.

If you give a cache to init() then later give cache => undef,
the server-side cache is no longer used.
This is useful when you find an error condition when creating your HTML
and decide that you no longer wish to store the output in the cache.

Init always returns the object, so that calls can be chained.
If the save_to argument can't be used,
for example if the directory can't be written to,
a warning is given once and the page is sent without save_to.

=head3 API SPECIFICATION

=head4 INPUT

The same as new(), where save_to is:

	{
		directory => { type => 'string' },
		ttl => { type => 'integer', min => 0, optional => 1 },
		create_table => { type => 'boolean', optional => 1 },
		max_pages => { type => 'integer', min => 0, optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'FCGI::Buffer' }

=head3 MESSAGES

	+------------------------------------+------------------------------+--------------------------+
	| Message                            | Meaning                      | Resolution               |
	+------------------------------------+------------------------------+--------------------------+
	| Too late to call init              | Output was printed first     | Call init earlier        |
	| save_to must be a hash reference   | Another type was given       | Give a hash reference    |
	| save_to needs a directory          | The directory key is missing | Give a directory         |
	| D isn't a directory                | It can't be created          | Check the path           |
	| D isn't writeable                  | Permissions                  | Check the permissions    |
	| D is not under the document root   | Pages could not be linked to | Move it under the root   |
	| The logger doesn't understand M    | Missing method               | Use another logger       |
	+------------------------------------+------------------------------+--------------------------+

=head3 FORMAL SPECIFICATION

	init
	  params? : OPTION -+-> VALUE
	  self, self' : BUFFER
	  ---
	  dom params? is a subset of OPTION
	  self'.save_to is defined =>
	    can_cache(self) and writeable(self'.save_to.directory) and
	    under(rootdir, self'.save_to.directory)
	  params?.cache = undef => self'.cache is undefined
	  result! = self'

=cut

sub init {
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Safe options - can be called at any time
	foreach my $option(@SAFE_OPTIONS) {
		if(defined($params{$option})) {
			$self->{$option} = $params{$option};
		}
	}
	if(defined($params{'logger'})) {
		$self->_check_logger();
	}

	# Before save_to, which needs it
	if(defined($params{info}) && (!defined($self->{info}))) {
		$self->{info} = $params{info};
	}

	if(defined($params{save_to}) && $self->can_cache()) {
		if(my $problem = $self->_save_to_problem($params{save_to})) {
			# The page can still be sent, so this isn't fatal.  It
			# would be repeated for each request of a long running
			# process, but only needs saying once
			$self->_problem_once($problem);
			delete $self->{'save_to'};
		} else {
			$self->{save_to} = $params{save_to};
			if(!exists($params{save_to}->{'ttl'})) {
				$self->{save_to}->{'ttl'} = $DEFAULT_SAVE_TO_TTL;
			}
		}
	} elsif(exists($params{'save_to'}) && !defined($params{'save_to'})) {
		delete $self->{'save_to'};
	}

	# Unsafe options - must be called before output has been started
	my $pos = $self->{buf}->getpos;
	if($pos > 0) {
		if(defined($self->{logger})) {
			my @call_details = caller(0);
			$self->{logger}->warn("Too late to call init, $pos characters have been printed, caller line $call_details[2] of $call_details[1]");
		} else {
			# Must do Carp::carp instead of carp for Test::Carp
			Carp::carp "Too late to call init, $pos characters have been printed";
		}
	}
	if(exists($params{cache}) && $self->can_cache()) {
		# There is an argument not to do this since one client will
		# affect others, so it's limited
		my $max_age = _client_max_age();
		if(defined($max_age) && ($max_age <= $MAX_CLIENT_CACHE_SECONDS)) {
			$self->{cache_duration} = "$max_age seconds";
			if(defined($self->{logger})) {
				$self->{logger}->debug("cache_duration = $self->{cache_duration}");
			}
		}
		$self->{cache_duration} ||= $params{cache_duration};
		if(defined($params{cache})) {
			$self->{cache} = $params{cache};
		} else {
			if(defined($self->{logger}) && defined($self->{cache})) {
				$self->{logger}->debug('disabling cache', ($self->{cache_key} ? " $self->{cache_key}" : ''));
			}
			delete $self->{cache};
		}
		if(defined($params{cache_key})) {
			$self->{cache_key} = $params{cache_key};
		}
	}

	return $self;
}

=head2 set_options

Synonym for init, kept for historical reasons.

=head3 API SPECIFICATION

=head4 INPUT

The same as init().

=head4 OUTPUT

	{ type => 'object', isa => 'FCGI::Buffer' }

=head3 FORMAL SPECIFICATION

	set_options == init

=cut

sub set_options {
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	$self->init(\%params);
}

=head2 can_cache

Returns true if the server is allowed to store the results locally.
This is the value of X-Cache in the returned header.

The cache isn't used if the NO_CACHE or NO_STORE environment variables are set,
if the request method isn't GET or HEAD,
if the client has logged in (the Authorization header or REMOTE_USER is set),
or if the client's Cache-Control header includes any of no-store, no-cache,
private or max-age=0.
The answer is decided on the first call, and doesn't change for the rest of the
request.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

	{ type => 'boolean' }

=head3 FORMAL SPECIFICATION

	can_cache
	  env : NAME -+-> STRING
	  result! : BOOLEAN
	  ---
	  result! = true <=>
	    NO_CACHE, NO_STORE, HTTP_AUTHORIZATION, REMOTE_USER are not in dom env and
	    (REQUEST_METHOD is not in dom env or env(REQUEST_METHOD) is in {GET, HEAD}) and
	    directives(env(HTTP_CACHE_CONTROL)) has none of {no-store, no-cache, private, max-age=0}

=cut

sub can_cache {
	my $self = shift;

	if(defined($self->{x_cache})) {
		return ($self->{x_cache} eq 'HIT');
	}
	if(defined($self->{logger}) && defined($ENV{'HTTP_CACHE_CONTROL'})) {
		$self->{logger}->debug("cache_control = $ENV{HTTP_CACHE_CONTROL}");
	}

	# A request may give several directives, e.g. "no-cache, max-age=0",
	# and any one of them forbids the cache
	my $control = _cache_control();
	my $max_age = _client_max_age();
	my $forbidden = defined($ENV{'NO_CACHE'}) || defined($ENV{'NO_STORE'}) ||
		(!_is_safe_method()) || _is_logged_in() ||
		(grep { $NO_CACHE_DIRECTIVES{$_} } keys %{$control}) ||
		(defined($max_age) && ($max_age == 0));

	$self->{x_cache} = $forbidden ? 'MISS' : 'HIT';
	return $forbidden ? 0 : 1;
}

=head2 is_cached

Returns true if the output is cached. If it is then it means that all of the
expensive routines in the FCGI script can be by-passed because we already have
the result stored in the cache.

    # Put this toward the top of your program before you do anything

    # Example key generation - use whatever you want as something
    # unique for this call, so that subsequent calls with the same
    # values match something in the cache
    use CGI::Info;
    use CGI::Lingua;
    use FCGI::Buffer;

    my $i = CGI::Info->new();
    my $l = CGI::Lingua->new(supported => ['en']);

    # To use server-side caching you must give the cache argument, however
    # the cache_key argument is optional - if you don't give one then one will
    # be generated for you
    my $buffer = FCGI::Buffer->new();
    if($buffer->can_cache()) {
        $buffer->init(
	    cache => CHI->new(driver => 'File'),
	    cache_key => $i->domain_name() . '/' . $i->script_name() . '/' . $i->as_string() . '/' . $l->language()
        );
        if($buffer->is_cached()) {
	    # Output will be retrieved from the cache and sent automatically
	    exit;
        }
    }
    # Not in the cache, so now do our expensive computing to generate the
    # results
    print "Content-type: text/html\n";
    # ...

An entry that has expired isn't cached,
and neither is any entry if the script's file has changed since,
or if the age of the script can't be determined.
If the cache fails, a warning is given and the output isn't cached.

=head3 API SPECIFICATION

=head4 INPUT

None.

=head4 OUTPUT

	{ type => 'boolean' }

=head3 FORMAL SPECIFICATION

	is_cached
	  cache : KEY -+-> ENTRY
	  key : KEY
	  script_mtime : TIME
	  now : TIME
	  result! : BOOLEAN
	  ---
	  result! = true <=>
	    key is in dom cache and
	    cache(key).value is defined and
	    cache(key).expires_at > now and
	    script_mtime <= cache(key).created_at

=cut

sub is_cached {
	my $self = shift;

	unless($self->{cache}) {
		if($self->{logger}) {
			$self->{logger}->debug("is_cached: cache hasn't been enabled");
			my $i = 0;
			while((my @call_details = (caller($i++)))) {
				$self->{logger}->debug($call_details[1], ':', $call_details[2], ' calling function ', $call_details[3]);
			}
		}
		return 0;
	}

	my $key = $self->_generate_key();

	if($self->{logger}) {
		$self->{logger}->debug("is_cached: looking for key = $key");
	}
	$self->{cobject} = $self->_cache_lookup($key);
	unless($self->{cobject}) {
		if($self->{logger}) {
			$self->{logger}->debug('not found in cache');
		}
		return 0;
	}
	unless($self->{cobject}->value($key)) {
		if($self->{logger}) {
			$self->{logger}->warn('is_cached: object is in the cache but not the data');
		}
		delete $self->{cobject};
		return 0;
	}

	# If the script has changed, don't use the cache since we may produce
	# different output
	my $age = $self->_my_age();
	unless(defined($age)) {
		if($self->{logger}) {
			$self->{logger}->debug("Can't determine script's age");
		}
		# Can't determine the age. Play it safe an assume we're not
		# cached
		delete $self->{cobject};
		return 0;
	}
	if($age > $self->{cobject}->created_at()) {
		# Script has been updated so it may produce different output
		if($self->{logger}) {
			$self->{logger}->debug('Script has been updated');
		}
		delete $self->{cobject};
		# Nothing will be in date and all new searches would miss
		# anyway, so may as well clear it all
		# FIXME: RT104471
		# $self->{cache}->clear();
		return 0;
	}
	if($self->{logger}) {
		$self->{logger}->debug('Script is in the cache');
	}
	return 1;
}

# Determine the last modification time of the script and cache it for subsequent calls
sub _my_age {
	my $self = shift;

	return $self->{script_mtime} if(defined($self->{script_mtime}));

	# croak() never returns, so nothing is needed after it
	my $path = $self->_info()->script_path();
	croak 'Failed to retrieve script path' unless(defined($path));

	my @statb = stat($path);
	$self->{'script_mtime'} = $statb[9];	# Set script_mtime to the modification time of the script
	return $self->{script_mtime};
}

# Return the content encoding to use, or '' for none.
# Premise 1: _compress() fails the request with a 406 if it can't load the
#	module for the encoding
# Premise 2: the client is happy with any of the encodings it lists
# Conclusion: choose the first listed encoding that can be loaded, then the 406
#	can't happen
sub _should_gzip
{
	my $self = shift;

	return '' unless($self->{compress_content});
	my $accept = $ENV{'HTTP_ACCEPT_ENCODING'} || $ENV{'HTTP_TE'};
	return '' unless($accept);
	return '' if(defined($self->{content_type}) && (lc($self->{content_type}->[0]) ne 'text'));
	return '' if($self->{_script_encoded});	# It would be compressed twice

	foreach my $method(split(/\s*,\s*/, lc($accept))) {
		# e.g. "gzip;q=0.8", where q=0 means "not acceptable"
		my ($name, @params) = split(/\s*;\s*/, $method);
		next if(grep { /^q=0(?:\.0*)?$/ } @params);
		return $name if($ENCODING_MODULE{$name} && _can_load($ENCODING_MODULE{$name}));
	}

	return '';
}

# Can the given module be loaded?  The answer is remembered
{
	my %loadable;

	sub _can_load
	{
		my $module = shift;

		if(!exists($loadable{$module})) {
			$loadable{$module} = eval "require $module; 1" ? 1 : 0;
		}
		return $loadable{$module};
	}
}

sub _set_content_type
{
	my $self = shift;
	my $headers = shift;

	foreach my $header (split(/\r?\n/, $headers)) {
		my ($header_name, $header_value) = split /\:\s*/, $header, 2;
		next unless(defined($header_name) && defined($header_value));
		if(lc($header_name) eq 'content-type') {
			my @content_type = split /\//, $header_value, 2;
			$self->{content_type} = \@content_type;
		} elsif((lc($header_name) eq 'content-encoding') && (lc($header_value) !~ /^\s*identity\s*$/)) {
			$self->{_script_encoded} = 1;
		}
	}
}

# Compress the body with the given encoding, from _should_gzip()
sub _compress
{
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $encoding = $params{encoding};

	# This can be called again after the links in the body have been changed,
	# by which time the body is no longer compressed
	delete $self->{_content_encoding};
	@{$self->{o}} = grep { !/^Content-Encoding:/ } @{$self->{o}} if($self->{o});

	return unless(defined($self->{'body'}) && defined($encoding) && length($encoding));
	return if(length($self->{body}) < $MIN_GZIP_LEN);

	# Premise: _should_gzip() only returns encodings whose module loads
	# Conclusion: if one can't be loaded here, the request can't be met
	my $module = $ENCODING_MODULE{$encoding};
	if((!defined($module)) || !_can_load($module)) {
		$self->_set_status(406);
		return;
	}

	# Avoid 'Wide character in memGzip'
	my $bytes = _to_bytes($self->{body});
	my $compressed;
	if($module eq 'Compress::Zlib') {
		$compressed = Compress::Zlib::memGzip(\$bytes);
	} elsif($module eq 'Compress::Zstd') {
		# Facebook
		$compressed = Compress::Zstd::compress(\$bytes);
	} else {
		$compressed = IO::Compress::Brotli::bro($bytes);
	}

	# Don't send it compressed if that makes it larger
	return unless(defined($compressed) && (length($compressed) < length($bytes)));

	$self->{body} = $compressed;
	$encoding = 'gzip' if($encoding eq 'x-gzip');
	$self->{_content_encoding} = $encoding;
	foreach my $header("Content-Encoding: $encoding", 'Vary: Accept-Encoding') {
		push @{$self->{o}}, $header unless(grep { $_ eq $header } @{$self->{o}});
	}
}

sub _check_if_none_match {
	my $self = shift;

	if($ENV{'HTTP_IF_NONE_MATCH'} && defined($self->{etag})) {
		if($self->{logger}) {
			$self->{logger}->debug("Compare $ENV{HTTP_IF_NONE_MATCH} with $self->{etag}");
		}
		# The header is "*" or a list of entity tags, any of which may be
		# weak.  If-None-Match uses the weak comparison (RFC 9110 8.8.3.2),
		# under which the compressed version of a page matches
		my $matched = 0;
		foreach my $tag(split(/\s*,\s*/, $ENV{'HTTP_IF_NONE_MATCH'})) {
			(my $client_etag = $tag) =~ s/^W\///;
			(my $etag = $client_etag) =~ s/$ENCODED_ETAG_SUFFIX/"/;
			if($etag eq $self->{etag}) {
				$self->{_matched_etag} = $client_etag;
				$matched = 1;
				last;
			}
			$matched = 1 if($etag eq '*');
		}
		if($matched) {
			# RFC 9110 13.1.2: 304 is only for GET and HEAD
			my $status = _is_safe_method() ? 304 : 412;
			require HTTP::Status;
			push @{$self->{o}}, "Status: $status " . HTTP::Status::status_message($status);
			$self->{send_body} = 0;
			$self->_set_status($status);
			if($self->{logger}) {
				$self->{logger}->debug("Set status to $status");
			}
			return 1;
		}
	}
	if($self->{cache} && $self->{logger} && $self->{logger}->can('is_debug') && $self->{logger}->is_debug() && _can_load('Text::Diff')) {
		$self->_try('comparing with the cache', sub {
			my $cached_copy = $self->{cache}->get($self->_generate_key());

			if($cached_copy && $self->{body}) {
				require Storable;

				$cached_copy = Storable::thaw($cached_copy)->{body};
				my $diffs = Text::Diff::diff(\$self->{body}, \$cached_copy);
				$self->{logger}->debug('diffs: ', $diffs);
			} else {
				$self->{logger}->debug('Nothing to compare');
			}
		});
	}
	return 0;
}

# Run some code which isn't essential to sending the page, e.g. something using
# a cache or a database.  If it fails, give a warning and return undef
sub _try {
	my ($self, $what, $code) = @_;

	my $rc;
	return $rc if(eval { $rc = $code->(); 1 });
	$self->_problem(__PACKAGE__ . ": $what failed: $@");
	return;
}

# Report something which has gone wrong.  This can be called from anywhere, so
# the logger itself may be the thing that's failing
sub _problem {
	my ($self, $message) = @_;

	if($self->{logger}) {
		return if(eval { $self->{logger}->warn($message); 1 });
	}
	# Must be Carp::carp instead of carp for Test::Carp
	Carp::carp($message);
}

# As _problem, for a problem which doesn't change from one request to the next
{
	my %reported;

	sub _problem_once {
		my ($self, $message) = @_;

		$self->_problem($message) unless($reported{$message}++);
	}
}

# Check that the logger can do what will be asked of it, otherwise forget it.
# AUTOLOAD is taken on trust
sub _check_logger {
	my $self = shift;

	my $logger = $self->{logger};
	foreach my $method(@LOGGER_METHODS) {
		next if(Scalar::Util::blessed($logger) && ($logger->can($method) || $logger->can('AUTOLOAD')));
		delete $self->{logger};
		$self->_problem_once(__PACKAGE__ . ": The logger doesn't understand $method()");
		return;
	}
}

# Why this save_to argument to init() can't be used, or undef if it can
sub _save_to_problem {
	my ($self, $save_to) = @_;

	return 'save_to must be a hash reference' unless(ref($save_to) eq 'HASH');

	my $dir = $save_to->{'directory'};
	return 'save_to needs a directory' unless(defined($dir) && length($dir));

	if(! -d $dir) {
		mkdir $dir;
		return "$dir isn't a directory" if(! -d $dir);
	}
	return "$dir isn't writeable" if(! -w $dir);

	# Premise 1: static pages are only of use if they can be linked to
	# Premise 2: this could otherwise only be noticed for each link in each page
	# Conclusion: say so now, and don't write pages that nothing can link to
	if($self->{info} && !defined($self->_path_to_url(File::Spec->catfile($dir, 'x')))) {
		return "$dir is not under the document root";
	}
	return;
}

# Connect to the save_to database, if there is one
sub _save_to_dbh {
	my $self = shift;

	my $save_to = $self->{save_to};
	return unless($save_to);

	my $sqlite_file = File::Spec->catfile($save_to->{directory}, $SAVE_TO_DATABASE);
	if($self->{logger}) {
		$self->{logger}->debug("save_to sqlite file: $sqlite_file");
	}
	my $is_new = !-r $sqlite_file;
	if($is_new && !-d $save_to->{directory}) {
		mkdir $save_to->{directory};
	}
	require DBD::SQLite;
	my $dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef, { RaiseError => 1, PrintError => 0 });
	if($is_new && $save_to->{create_table}) {
		# Another process can get in between the two lines above
		$dbh->do('CREATE TABLE IF NOT EXISTS fcgi_buffer(key char PRIMARY KEY, language char, browser_type char, path char UNIQUE NOT NULL, uri char NOT NULL, creation timestamp NOT NULL)');
	}
	return $dbh;
}

# Look for an entry in the cache that can still be used.  A failing cache is the
# same as an empty one.
# CHI's get_object() returns an object even if it has expired
sub _cache_lookup {
	my ($self, $key) = @_;

	my $object = $self->_try('reading the cache', sub { return $self->{cache}->get_object($key) });
	return unless(defined($object));
	if($object->can('is_expired') && $object->is_expired()) {
		if($self->{logger}) {
			$self->{logger}->debug("$key has expired");
		}
		return;
	}
	return $object;
}

# A string as bytes: a string of characters is encoded, bytes are left alone
sub _to_bytes {
	my $string = shift;

	utf8::encode($string) if(defined($string) && utf8::is_utf8($string));
	return $string;
}

# Is the output an HTML page?
sub _is_html {
	my $self = shift;

	my $content_type = $self->{content_type};
	return 0 unless(defined($content_type) && defined($content_type->[1]));
	return ((lc($content_type->[0]) eq 'text') && (lc($content_type->[1]) =~ /^html/)) ? 1 : 0;
}

# The values of a header in a block of headers
sub _header_values {
	my ($headers, $name) = @_;

	return () unless(defined($headers));
	return map { /^[^:]+:\s*(.*?)\s*$/ ? $1 : () } grep { /^\Q$name\E:/i } split(/\r?\n/, $headers);
}

# May this response be kept and given to other clients?
sub _is_storable {
	my ($self, $headers, $body) = @_;

	# It would log the next client in as this one
	return 0 if(_header_values($headers, 'Set-Cookie') || _header_values($headers, 'Set-Cookie2'));

	# It would give this client's form token to the next one
	return 0 if(_has_form_token($body));

	foreach my $control(_header_values($headers, 'Cache-Control')) {
		foreach my $directive(split(/\s*,\s*/, lc($control))) {
			(my $name = $directive) =~ s/\s*=.*$//;
			return 0 if($NO_CACHE_DIRECTIVES{$name});
		}
	}

	# The cache holds the uncompressed version, so this can't be stored
	return 0 if($self->{_script_encoded});

	# Accept-Encoding is dealt with here, and lingua is part of the key
	foreach my $vary(_header_values($headers, 'Vary')) {
		foreach my $name(split(/\s*,\s*/, lc($vary))) {
			next if($name eq 'accept-encoding');
			next if(($name eq 'accept-language') && $self->{lingua});
			return 0;
		}
	}

	# Perl doesn't tell a destructor that it's being called because of a die,
	# but this is what the page will look like if that has happened
	if($self->_is_html() && defined($body) && ($body =~ /<html\b/i) && ($body !~ /<\/html\s*+>/i)) {
		if($self->{logger}) {
			$self->{logger}->debug('Not storing an HTML page with no </html>');
		}
		return 0;
	}
	return 1;
}

# Stop the regular expressions from changing the contents of <pre> and <textarea>
# by swapping them for a marker.  Returns what's needed to put them back.
# The end of a tag is only looked for once if it isn't there, so that hostile
# input can't make this quadratic
sub _protect_preformatted {
	my $self = shift;

	my $body = $self->{body};
	my $marker = 'FCGIBUFFERPRESERVED' . int(rand(1_000_000_000)) . 'N';
	my (@saved, %no_end);
	my $out = '';
	my $last = 0;

	while($body =~ /<(pre|textarea)\b/gi) {
		my $tag = lc($1);
		my $start = $-[0];
		my $after = pos($body);

		next if($no_end{$tag});
		unless($body =~ /<\/$tag\s*+>/gi) {
			$no_end{$tag} = 1;
			pos($body) = $after;
			next;
		}
		my $end = $+[0];
		push @saved, substr($body, $start, $end - $start);
		$out .= substr($body, $last, $start - $last) . $marker . $#saved . 'X';
		$last = $end;
		pos($body) = $end;
	}
	$self->{body} = $out . substr($body, $last);
	return { marker => $marker, saved => \@saved };
}

# Put back what _protect_preformatted() took out
sub _restore_preformatted {
	my ($self, $preformatted) = @_;

	my $saved = $preformatted->{'saved'};
	$self->{body} =~ s/\Q$preformatted->{marker}\E(\d+)X/$saved->[$1]/g if(scalar(@{$saved}));
}

# Tell caches that what's sent depends on what the client accepts.  This is also
# needed when the output isn't compressed, or that's what a cache would then give
# to clients that can take it compressed
sub _add_vary {
	my ($self, $headers) = @_;

	return unless(defined($headers) && length($headers));
	return unless($self->{compress_content} && defined($self->{body}) && !$self->{_script_encoded});
	return if(defined($self->{content_type}) && (lc($self->{content_type}->[0]) ne 'text'));
	return if($headers =~ /^Vary:.*\baccept-encoding\b/mi);
	return if(grep { /^Vary:.*\baccept-encoding\b/i } @{$self->{o}});
	push @{$self->{o}}, 'Vary: Accept-Encoding';
}

# Send one Status header, that of the status we've ended up with, keeping the
# script's one if it's the same since it may have its own wording
sub _set_status_header {
	my $self = shift;

	my $status = $self->{status};
	my $found = 0;
	@{$self->{o}} = grep {
		my $keep = 1;
		if(/^Status:\s*(\d+)/i) {
			$keep = (!$found) && ($1 == $status);
			$found ||= $keep;
		}
		$keep
	} @{$self->{o}};

	unless($found) {
		require HTTP::Status;
		HTTP::Status->import();

		push @{$self->{o}}, 'Status: ' . $status . ' ' . HTTP::Status::status_message($status);
		$self->_set_status($status);
	}
}

# If-Range asks for a part only if the client's copy is the current one
# (RFC 9110 14.5), which needs an exact match of a strong validator
sub _if_range_matches {
	my $self = shift;

	my $if_range = $ENV{'HTTP_IF_RANGE'};
	return 1 unless(defined($if_range) && length($if_range));

	if($if_range =~ /^(?:W\/)?"/) {
		$self->_generate_etag();
		return (defined($self->{etag}) && ($if_range eq $self->{etag})) ? 1 : 0;
	}
	my $since = HTTP::Date::str2time($if_range);
	return 0 unless(defined($since) && $self->{info});
	my $age = $self->_my_age();
	return (defined($age) && ($age == $since)) ? 1 : 0;
}

# The CGI::Info object, which is created if it wasn't given
sub _info {
	my $self = shift;

	if(!defined($self->{info})) {
		$self->{info} = CGI::Info->new($self->{cache} ? { cache => $self->{cache} } : ())
			or croak(__PACKAGE__, ': Failed to create CGI::Info object');
	}
	return $self->{info};
}

# Set the HTTP status, and tell CGI::Info if we have one
sub _set_status {
	my ($self, $status) = @_;

	$self->{status} = $status;
	if($self->{info}) {
		$self->{info}->status($status);
	}
}

# Does the protocol support conditional requests (ETag etc.)?
sub _is_conditional_protocol {
	return defined($ENV{'SERVER_PROTOCOL'}) && ($ENV{'SERVER_PROTOCOL'} =~ $CONDITIONAL_PROTOCOL);
}

# Is the request one that can be answered from a cache or with a 304?
# There is no method when running from the command line
sub _is_safe_method {
	return (!defined($ENV{'REQUEST_METHOD'})) || $SAFE_METHODS{$ENV{'REQUEST_METHOD'}};
}

sub _is_get {
	return (!defined($ENV{'REQUEST_METHOD'})) || ($ENV{'REQUEST_METHOD'} eq 'GET');
}

sub _is_logged_in {
	return $ENV{'HTTP_AUTHORIZATION'} || $ENV{'REMOTE_USER'};
}

# The client's cookies, except for Google Analytics ones and the token that
# protects forms, which are different for each client but don't change the output.
# A page with a form is sent that token in a Set-Cookie header, so _is_storable()
# doesn't store it
sub _client_cookies {
	return () unless($ENV{'HTTP_COOKIE'});
	return grep { !/^(?:__utm[abcz]|\Q$FORM_TOKEN_COOKIE\E=)/ } split(/;\s*/, $ENV{'HTTP_COOKIE'});
}

# Does this page include the client's own form token?  _client_cookies() ignores
# the cookie that holds it, on the understanding that it doesn't change the output.
# A script that puts its value into the page has made the page per client
sub _has_form_token {
	my $body = shift;

	return 0 unless($ENV{'HTTP_COOKIE'} && defined($body));

	foreach my $cookie(split(/;\s*/, $ENV{'HTTP_COOKIE'})) {
		next unless($cookie =~ /^\Q$FORM_TOKEN_COOKIE\E=(.+)$/);
		my $token = $1;
		return 1 if(index($body, $token) >= 0);
		# The cookie may be encoded, what's printed may not be
		if($token =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge) {
			return 1 if(index($body, $token) >= 0);
		}
	}
	return 0;
}

# Does the output depend on who the client is?
# Separate from the key since the key may have been given to us by the caller
sub _is_per_client {
	return _is_logged_in() || scalar(_client_cookies());
}

# The directives in the request's Cache-Control header, as a hashref of
# lower case name to value (undef when there is no value)
sub _cache_control {
	my %directives;

	if(defined(my $control = $ENV{'HTTP_CACHE_CONTROL'})) {
		foreach my $directive(split(/\s*,\s*/, lc($control))) {
			my ($name, $value) = split(/\s*=\s*/, $directive, 2);
			next unless(defined($name) && length($name));
			$value =~ s/^"(.*)"$/$1/ if(defined($value));
			$directives{$name} = $value;
		}
	}
	return \%directives;
}

# The max-age directive in the request, or undef if there isn't a valid one.
# This comes from the client, so it mustn't be trusted to be a number
sub _client_max_age {
	my $max_age = _cache_control()->{'max-age'};

	return (defined($max_age) && ($max_age =~ /^\d+$/)) ? $max_age : undef;
}

# The X-Cache and X-Cache-Lookup headers, as an arrayref
sub _x_cache_headers {
	my ($self, $cache, $lookup) = @_;

	my $from = $self->{info} ? ' from ' . $self->{info}->host_name() : '';
	return [ "X-Cache: $cache$from", "X-Cache-Lookup: $lookup$from" ];
}

# Work out the response to a Range header, as a hashref of the new status,
# body and Content-Range header, or undef if the range isn't one that we
# support, in which case the header is ignored and the whole body is sent.
# Only a single range of bytes is supported.
#	206: the part of the body asked for
#	416: a valid range which is outside of the body, so has no body
sub _apply_range {
	my ($body, $range) = @_;

	return unless($range =~ /^bytes=(\d*)-(\d*)$/);
	my ($first, $last) = ($1, $2);
	my $length = length($body);

	# "bytes=-" says nothing
	return if(($first eq '') && ($last eq ''));

	# A backwards range is invalid, so is ignored (RFC 7233 2.1)
	return if(($first ne '') && ($last ne '') && ($first > $last));

	if($first eq '') {
		# "bytes=-n" is the last n bytes, all of it if there are
		# fewer than n
		$first = ($last >= $length) ? 0 : $length - $last;
		$last = $length - 1;
		# Premise 1: the last 0 bytes is an empty range
		# Premise 2: so is any range of an empty body
		# Conclusion: both leave $first > $last, and can't be satisfied
	} elsif(($last eq '') || ($last >= $length)) {
		# A range past the end stops at the end
		$last = $length - 1;
	}

	# A range starting at or after the end can't be satisfied
	if(($first >= $length) || ($first > $last)) {
		return { status => 416, content_range => "bytes */$length" };
	}

	return {
		status => 206,
		body => substr($body, $first, $last - $first + 1),
		content_range => "bytes $first-$last/$length",
	};
}

# Create the static page for this request
sub _write_static_page {
	my ($self, $key, $unzipped_body, $dbh, $request_uri) = @_;

	my $ttl = $self->{save_to}->{ttl};
	my $query = 'SELECT DISTINCT creation FROM fcgi_buffer WHERE key = ?';
	if($self->{logger}) {
		$self->{logger}->debug("$query: $key");
	}
	my ($creation) = $dbh->selectrow_array($query, undef, $key);

	# A page that has passed its ttl is replaced, it would otherwise never
	# be updated
	if(defined($creation) && ((!$ttl) || (($creation + $ttl) >= time))) {
		if($ttl) {
			push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str($creation + $ttl);
		}
		return;
	}

	# Each different set of arguments, which the client chooses, gives a file
	my $max_pages = exists($self->{save_to}->{max_pages}) ? $self->{save_to}->{max_pages} : $DEFAULT_SAVE_TO_MAX_PAGES;
	if($max_pages && !defined($creation)) {
		my ($count) = $dbh->selectrow_array('SELECT COUNT(*) FROM fcgi_buffer');
		if($count >= $max_pages) {
			$self->_problem_once(__PACKAGE__ . ": save_to has reached its limit of $max_pages pages");
			return;
		}
	}

	my $dir = $self->{save_to}->{directory};
	my $browser_type = $self->{info}->browser_type();
	my $language = $self->_save_to_language();
	my $bdir = File::Spec->catfile($dir, _safe_filename($browser_type));
	if($bdir =~ /^(.+)$/) {
		$bdir = $1;	# Untaint
	}
	my $ldir = File::Spec->catfile($bdir, _safe_filename($language));
	my $sdir = File::Spec->catfile($ldir, _safe_filename($self->{info}->script_name()));
	if($self->{logger}) {
		$self->{logger}->debug("Create paths to $sdir");
	}
	File::Path::make_path($sdir);
	my $path = File::Spec->catfile($sdir, $self->_save_to_filename() . '.html');

	# The file has the same name for each virtual host using this directory,
	# and must not replace the page of another one
	my ($owner) = $dbh->selectrow_array('SELECT key FROM fcgi_buffer WHERE path = ?', undef, $path);
	if(defined($owner) && ($owner ne $key)) {
		$path = File::Spec->catfile($sdir, $self->_save_to_filename($self->_save_to_host()) . '.html');
	}
	if($path =~ /^(.+)$/) {
		$path = $1;	# Untaint
	}

	my $copy = $unzipped_body;

	# handle <a href="?arg3=4">Call self with different args</a>
	# The static page is somewhere else, so make the links absolute.
	# REQUEST_URI comes from the client and is about to be stored in a page
	# that everyone can see
	my $r = $request_uri;
	$r =~ s/\?.*$//;
	$r = _escape_attribute($r);
	$copy =~ s/<a\s+href="(\?[^"]*)"/<a href="$r$1"/gi;

	# Links to this page now point to its static copy
	my $changes = 0;
	if(defined(my $url = $self->_path_to_url($path))) {
		$changes = ($copy =~ s/((?i:<a\s+href="))\Q$request_uri\E"/$1$url"/g);
	}

	# Avoid Wide character
	return unless($self->_write_atomically($path, _to_bytes($copy)));

	# Do INSERT OR REPLACE in case another program has got in first
	my $uri = $self->_save_to_uri($request_uri);
	$query = "INSERT OR REPLACE INTO fcgi_buffer(key, language, browser_type, path, uri, creation) VALUES(?, ?, ?, ?, ?, strftime('\%s','now'))";
	if($self->{logger}) {
		$self->{logger}->debug("$query: $key, $language, $browser_type, $path, $uri");
	}
	$dbh->do($query, undef, $key, $language, $browser_type, $path, $uri);

	if($changes && $ttl) {
		push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str(time + $ttl);
	}
}

# Keep one of the Expires headers, the earliest, since the page is out of date
# as soon as any part of it is.  RFC 9111 4.2.1 allows a cache to treat a response
# with more than one as stale.  A date that can't be understood means already
# expired (RFC 9111 5.3)
sub _one_expires {
	my @headers = @_;

	my @expires = grep { /^Expires:/i } @headers;
	return @headers if(scalar(@expires) < 2);

	my ($earliest, $earliest_time);
	foreach my $header(@expires) {
		my ($date) = $header =~ /^Expires:\s*(.*)$/i;
		my $time = HTTP::Date::str2time($date) || 0;
		if((!defined($earliest_time)) || ($time < $earliest_time)) {
			($earliest, $earliest_time) = ($header, $time);
		}
	}
	return ((grep { !/^Expires:/i } @headers), $earliest);
}

# Write a file so that anyone reading it sees all of the old file or all of the
# new one, never a part of it, and the old one survives a failure such as a full
# disc.  Returns true if it worked
sub _write_atomically {
	my ($self, $path, $contents) = @_;

	require File::Basename;
	require File::Temp;

	my ($fout, $tmp) = eval {
		File::Temp::tempfile('.fcgi-buffer-XXXXXXXX', DIR => File::Basename::dirname($path), SUFFIX => '.tmp', UNLINK => 0);
	};
	unless($fout) {
		$self->_problem("Can't create $path");
		return 0;
	}
	if($tmp =~ /^(.+)$/s) {
		$tmp = $1;	# Untaint
	}

	# File::Temp creates files that only their owner can read, but it's the
	# web server that sends these
	my $ok = chmod(0666 & ~umask(), $fout) && (print $fout $contents);
	$ok = close($fout) && $ok;
	if($ok && rename($tmp, $path)) {
		return 1;
	}
	$self->_problem("Can't create $path: $!");
	unlink $tmp;
	return 0;
}

# Make a string safe to put into an HTML attribute
sub _escape_attribute {
	my $string = shift;

	$string =~ s/&/&amp;/g;
	$string =~ s/"/&quot;/g;
	$string =~ s/'/&#39;/g;
	$string =~ s/</&lt;/g;
	$string =~ s/>/&gt;/g;
	return $string;
}

# The name of the virtual host that this request is for
sub _save_to_host {
	my $self = shift;

	my $host = $self->{info}->can('domain_name') ? $self->{info}->domain_name() : undef;
	return defined($host) ? $host : 'default';
}

# What the database holds for a URI.  The same URI on another virtual host is a
# different page, and this needs no change to the database's schema.
# The order of the arguments doesn't make a different page, a link can give them
# in any order
sub _save_to_uri {
	my ($self, $uri) = @_;

	if($uri =~ /^([^?]*)\?(.*)$/s) {
		$uri = "$1?" . join('&', sort split(/[&;]/, $2));
	}
	return $self->_save_to_host() . $uri;
}

# replace dynamic links with static links
sub _save_to {
	my ($self, $unzipped_body, $dbh) = @_;

	# The links can be changed later, the page can still be sent
	return $self->_try('save_to', sub { $self->_rewrite_links($unzipped_body, $dbh) }) || 0;
}

sub _rewrite_links {
	my ($self, $unzipped_body, $dbh) = @_;

	return 0 unless($dbh && $self->{info} && (my $request_uri = $ENV{'REQUEST_URI'}));
	return 0 if(!defined($unzipped_body));
	return 0 unless($self->_is_html());

	# Links can't be followed to a page that has expired, so take the
	# opportunity to clear those up
	$self->_purge_save_to($dbh);

	my $query;
	my $copy = $unzipped_body;
	my $changes = 0;
	my $creation;
	my %seen_links;
	my $language = $self->_save_to_language();
	my $browser_type = $self->{info}->browser_type();
	while($unzipped_body =~ /<a\s+href="([^"]+)"/gi) {
		my $link = $1;
		next if($seen_links{$link});	# Already updated in the copy
		$seen_links{$link} = 1;

		# The link is as it appears in the HTML, the database holds
		# the REQUEST_URI
		my $search_uri = $link;
		$search_uri =~ s/&amp;/&/g;
		if($search_uri =~ /^\?/) {
			# CGI script has links to itself
			# $search_uri = "${request_uri}${link}";
			my $r = $request_uri;
			$r =~ s/\?.*$//;
			$search_uri = "${r}$search_uri";
		} else {
			next if($link =~ /^https?:\/\//);	# FIXME: skips full URLs to ourself
								#	Though optimise_content fixes that
			next if($link =~ /\.(?:html?|jpg|gif)$/i);
		}
		if($self->{save_to}->{ttl}) {
			$query = "SELECT DISTINCT path, creation FROM fcgi_buffer WHERE uri = ? AND language = ? AND browser_type = ? AND creation >= strftime('\%s','now') - ?";
		} else {
			$query = 'SELECT DISTINCT path, creation FROM fcgi_buffer WHERE uri = ? AND language = ? AND browser_type = ?';
		}
		if($self->{logger}) {
			$self->{logger}->debug("$query: $search_uri, $language, $browser_type");
		}
		my $sth = $dbh->prepare($query);
		my $uri = $self->_save_to_uri($search_uri);
		if($self->{save_to}->{ttl}) {
			$sth->execute($uri, $language, $browser_type, $self->{save_to}->{ttl});
		} else {
			$sth->execute($uri, $language, $browser_type);
		}
		if(my $href = $sth->fetchrow_hashref()) {
			if(my $path = $href->{'path'}) {
				if(-r $path) {
					my $url = $self->_path_to_url($path);
					if(!defined($url)) {
						if($self->{logger}) {
							$self->{logger}->warn("$path is not under the document root, can't link to it");
						}
						next;
					}
					if($self->{logger}) {
						$self->{logger}->debug("Changing links from $link to $url");
					}
					$changes += ($copy =~ s/((?i:<a\s+href="))\Q$link\E"/$1$url"/g);
					# Find the first link that will expire and use that
					if((!defined($creation)) || ($href->{'creation'} < $creation)) {
						$creation = $href->{'creation'};
					}
				} else {
					$sth->finish();
					$query = 'DELETE FROM fcgi_buffer WHERE path = ?';
					$dbh->do($query, undef, $path);
					if($self->{logger}) {
						$self->{logger}->warn("Remove entry for non-existant file $path");
					}
				}
			}
		}
	}
	if($changes) {
		my $ttl = $self->{save_to}->{ttl};
		if($self->{logger}) {
			# $self->{logger}->debug("$changes links now point to static pages");
			if($changes == 1) {
				if($ttl) {
					$self->{logger}->info('1 link now points to a static page for ', $creation + $ttl - time, 's');
				} else {
					$self->{logger}->info('1 link now points to a static page');
				}
			} else {
				$self->{logger}->info("$changes links now point to static pages");
			}
		}
		$self->{'body'} = $copy;
		if($ttl) {
			push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str($creation + $ttl);
		}
	}
	return $changes;
}

# Delete the static pages that have passed their ttl
sub _purge_save_to {
	my ($self, $dbh) = @_;

	my $ttl = $self->{save_to}->{ttl};
	return unless($ttl);

	my $paths = $dbh->selectcol_arrayref("SELECT path FROM fcgi_buffer WHERE creation < strftime('\%s','now') - ?", undef, $ttl);
	return unless(scalar(@{$paths}));

	foreach my $path(@{$paths}) {
		if($self->{logger}) {
			$self->{logger}->debug("unlink $path");
		}
		unlink $path;
	}
	$dbh->do("DELETE FROM fcgi_buffer WHERE creation < strftime('\%s','now') - ?", undef, $ttl);
}

# The language as stored in the save_to database
sub _save_to_language {
	my $self = shift;

	if($self->{'lingua'}) {
		my $language = $self->{'lingua'}->language();
		return $language if(defined($language) && length($language));
	}
	return 'default';
}

# Make a string safe to use as a file or directory name, and in a URL.
# If anything had to be changed, a digest of the original is appended so that
# different strings don't map onto the same file
sub _safe_filename {
	my $name = shift;

	require Encode;

	my $safe = $name;
	$safe =~ s/[^A-Za-z0-9=_.,+-]/_/g;
	$safe =~ s/^\./_/;
	if(($safe ne $name) || (length($safe) > 200)) {
		$safe = substr($safe, 0, 200) . '-' . substr(Digest::MD5::md5_hex(Encode::encode_utf8($name)), 0, 8);
	}
	if($safe =~ /^(.+)$/) {
		$safe = $1;	# Untaint
	}
	return $safe;
}

# The basename of the static page for this request, optionally with a prefix
sub _save_to_filename {
	my ($self, $prefix) = @_;

	my $name = $self->{'info'}->as_string();
	if(defined($name) && length($name)) {
		# Keep the historical "arg1=a_arg2=b" naming
		$name =~ s/;\s*/_/g;
	} else {
		# An empty name would give a hidden file
		$name = 'index';
	}
	if(defined($ENV{'PATH_INFO'}) && length($ENV{'PATH_INFO'})) {
		$name = "$ENV{PATH_INFO}_$name";
	}
	$name = "${prefix}_$name" if(defined($prefix));
	return _safe_filename($name);
}

# Convert the filename of a static page into the URL used to reach it, or undef
# if it isn't under the document root
sub _path_to_url {
	my ($self, $path) = @_;

	my $rootdir = $self->{'info'}->rootdir();
	return unless(defined($rootdir) && length($rootdir));

	require Cwd;
	foreach my $p(\$rootdir, \$path) {
		my $real = Cwd::realpath(${$p});
		${$p} = File::Spec->canonpath(defined($real) ? $real : ${$p});
	}

	my @root = File::Spec->splitdir($rootdir);
	my @dirs = File::Spec->splitdir($path);
	pop @root if(@root && ($root[-1] eq ''));

	return if(scalar(@dirs) <= scalar(@root));
	foreach my $d(@root) {
		my $p = shift @dirs;
		return if(($^O eq 'MSWin32') ? (lc($d) ne lc($p)) : ($d ne $p));
	}

	require Encode;
	return join('/', '', map {
		my $s = Encode::encode_utf8($_);
		$s =~ s/([^A-Za-z0-9\-._~=,+])/sprintf('%%%02X', ord($1))/ge;
		$s
	} @dirs);
}

=head1 HOW THE OUTPUT IS SENT

=over 4

=item * Compression

The first encoding listed by the client (in Accept-Encoding, or TE) that
FCGI::Buffer can produce is used.
Encodings with q=0 are skipped.

Premise 1: the client is happy with any of the encodings that it lists.
Premise 2: an encoding can only be produced if its module is installed.
Conclusion: an encoding whose module isn't installed is passed over for the
next one, rather than failing the request.
If none can be used, the output is sent uncompressed.

Only text is compressed, and not output for which the script has given its own
Content-Encoding.
A Vary: Accept-Encoding header is sent with anything that could be compressed.

=item * Character encoding

The module works on what your script prints.

If your script prints bytes, such as UTF-8 that hasn't been decoded,
they are sent exactly as they are.

If your script prints a string of characters,
that is to say one with Perl's UTF-8 flag set,
it's encoded as UTF-8.
There's no need for you to set a layer on the file handle,
and you should say so in your Content-Type header with a charset.

So multibyte content is safe either way,
but it's best not to join the two in one string,
since Perl would then treat the bytes as Latin-1 characters.

Offsets in a Range request, the Content-Length header and the ETag are all
worked out from the bytes that are sent.

=item * Range

A single range of bytes, such as C<bytes=0-99>, C<bytes=100-> or
C<bytes=-100> (the last 100 bytes), is honoured with a 206 status and a
Content-Range header.
A range which starts after the end of the page, or C<bytes=-0>,
can't be satisfied and gets a 416 status with no body.
Anything else, such as several ranges or a backwards range, is ignored and the
whole page is sent.

A range is only honoured for a GET request with a status of 200 and when no
server-side cache has been given, otherwise the whole page is sent,
which RFC 9110 allows.
An If-Range header is honoured.
A part of a page is never compressed, so it has the ETag of the uncompressed
version.
It is a part of the page after any links have been changed to point to static
pages.

=item * Conditional requests

If-None-Match may be a list of ETags, weak ETags or "*".
If it is given, If-Modified-Since isn't looked at.
The ETag is of the page as it's sent, so it changes when a link is changed to
point to a static page.
Last-Modified is when the page was put into the cache and doesn't change,
so a client that only sends If-Modified-Since can be given a 304 and keep the
old links.
Browsers send both.
For methods other than GET and HEAD a match gives a 412 status, although the
script will have already run,
and If-Modified-Since is ignored.

If there would be more than one Expires header,
because the script gave one and there are links to static pages,
only the earliest is sent.

The ETag of compressed output ends with the name of the encoding,
e.g. C<"0123456789abcdef0123456789abcdef-gzip">, since it isn't the same bytes
as the uncompressed version.
If-None-Match treats them as a match, but If-Range doesn't.

=item * Headers

The module sends one Status header, and works out Content-Length itself even
if the script has given one, since the output may have changed.
Header lines can end in either CRLF or LF.

=item * Failures

Nothing that goes wrong with the cache, the save_to database or the logger stops
the page from being sent.
A warning is given,
and if the page can't be processed further it's sent as the script printed it.
If the script printed nothing because it relied upon the cache,
the status is 500.

=item * Optimisation

optimise_content leaves the contents of <pre> and <textarea> alone.

=back

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 BUGS

FCGI::Buffer should be safe even in scripts that produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge setting generate_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using L<Template>, ensure that you don't use it to output to STDOUT,
instead,
you will need to capture into a variable and print that.
For example:

    my $output;
    $template->process($input, $vars, \$output) || ($output = $template->error());
    print $output;

Can produce buggy JavaScript if you use the <!-- HIDING technique.
This is a bug in L<JavaScript::Packer>, not FCGI::Buffer.

Mod_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary

If you request compressed output then uncompressed output (or vice
versa) on input that produces the same output, the status will be 304.
The letter of the spec says that's wrong, so I'm noting it here, but
in practice, you should not see this happen or have any difficulties
because of it.

FCGI::Buffer has not been tested against FastCGI.

I advise adding FCGI::Buffer as the last use statement so that it is
cleared up first.  In particular, it should be loaded after
L<Log::Log4perl>, if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
FCGI::Buffer;

Save_to doesn't understand links in JavaScript, which means that if you use self-calling
CGIs loaded as a static page,
they may point to the wrong place.
The workaround is to avoid self-calling CGIs in JavaScript

Please report any bugs or feature requests to C<bug-fcgi-buffer at rt.cpan.org>
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer>.
I will be notified, and then you'll automatically be notified of the progress on
your bug as I make changes.

The lint operation only works on HTML4, because of a restriction in L<HTML::Lint>.

=head1 SEE ALSO

L<CGI::Buffer>,
L<HTML::Packer>,
L<HTML::Lint>

=head1 SUPPORT

This module is provided as-is without any warranty.

You can find documentation for this module with the perldoc command.

    perldoc FCGI::Buffer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer>

=item * Search CPAN

L<http://search.cpan.org/dist/FCGI-Buffer/>

=back

=head1 ACKNOWLEDGEMENTS

The inspiration and code for some of this is cgi_buffer by Mark
Nottingham: L<https://www.mnot.net/blog/2003/04/24/etags>.

=head1 LICENSE AND COPYRIGHT

The licence for cgi_buffer is:

    "(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

    This software may be freely distributed, modified and used,
    provided that this copyright notice remain intact.

    This software is provided 'as is' without warranty of any kind."

The rest of the program is Copyright 2015-2026 Nigel Horne,
and is released under the following licence: GPL2

=cut

1; # End of FCGI::Buffer
