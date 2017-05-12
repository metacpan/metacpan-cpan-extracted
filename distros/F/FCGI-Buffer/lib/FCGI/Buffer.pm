package FCGI::Buffer;

use strict;
use warnings;

# FIXME: save_to treats ?arg1=a&arg2=b and ?arg2=b&arg1=a as different
# FIXME: save_to treats /cgi-bin/foo.fcgi and /cgi-bin2/foo.fcgi as the same

use Digest::MD5;
use IO::String;
use CGI::Info;
use Carp;
use HTTP::Date;
use DBI;

=head1 NAME

FCGI::Buffer - Verify, Cache and Optimise FCGI Output

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

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

To also make use of server caches, that is to say to save regenerating
output when different clients ask you for the same data, you will need
to create a cache.
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

To temporarily prevent the use of server-side caches, for example whilst
debugging before publishing a code change, set the NO_CACHE environment variable
to any non-zero value.
If you get errors about Wide characters in print it means that you've
forgotten to emit pure HTML on non-ascii characters.
See L<HTML::Entities>.
As a hack work around you could also remove accents and the like by using
L<Text::Unidecode>,
which works well but isn't really what you want.

=head1 SUBROUTINES/METHODS

=cut

use constant MIN_GZIP_LEN => 32;

=head2 new

Create an FCGI::Buffer object.  Do one of these for each FCGI::Accept.

=cut

# FIXME: Call init() on any arguments that are given
sub new {
	my $class = shift;

	return unless($class);

	my $buf = IO::String->new();

	my $rc = {
		buf => $buf,
		old_buf => select($buf),
		generate_304 => 1,
		generate_last_modified => 1,
		compress_content => 1,
		optimise_content => 0,
		lint_content => 0,
	};
	# $rc->{o} = ();

	if($ENV{'SERVER_PROTOCOL'} &&
	  ($ENV{'SERVER_PROTOCOL'} eq 'HTTP/1.1')) {
		$rc->{generate_etag} = 1;
	} else {
		$rc->{generate_etag} = 0;
	}

	return bless $rc, $class;
}

sub DESTROY {
	if(defined($^V) && ($^V ge 'v5.14.0')) {
		return if ${^GLOBAL_PHASE} eq 'DESTRUCT';	# >= 5.14.0 only
	}
	my $self = shift;

	select($self->{old_buf});
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
	my $headers;
	($headers, $self->{body}) = split /\r?\n\r?\n/, $buf, 2;

	if($self->{'logger'}) {
		if($ENV{'HTTP_IF_NONE_MATCH'}) {
			$self->{logger}->debug("HTTP_IF_NONE_MATCH: $ENV{HTTP_IF_NONE_MATCH}");
		}
		if($ENV{'HTTP_IF_MODIFIED_SINCE'}) {
			$self->{logger}->debug("HTTP_IF_MODIFIED_SINCE: $ENV{HTTP_IF_MODIFIED_SINCE}");
		}
		$self->{logger}->debug("Generate_etag = $self->{generate_etag}",
			"Generate_304 = $self->{generate_304}",
			"Generate_last_modified = $self->{generate_last_modified}");
	}
	unless($headers || $self->is_cached()) {
		if($self->{'logger'}) {
			$self->{'logger'}->debug('There was no output');
		}
		return;
	}
	if($ENV{'REQUEST_METHOD'} && ($ENV{'REQUEST_METHOD'} eq 'HEAD')) {
		$self->{send_body} = 0;
	} else {
		$self->{send_body} = 1;
	}

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
		if(defined($content_type[0]) && (lc($content_type[0]) eq 'text') && (lc($content_type[1]) =~ /^html/) && defined($self->{body})) {
			if($self->{optimise_content}) {
				# require HTML::Clean;
				require HTML::Packer;	# Overkill using HTML::Clean and HTML::Packer...

				if($self->{'logger'}) {
					$self->{'logger'}->trace('Packer');
				}

				my $oldlength = length($self->{body});
				my $newlength;

				if($self->{optimise_content} == 1) {
					$self->_optimise_content();
				} else {
					while(1) {
						$self->_optimise_content();
						$newlength = length($self->{body});
						last if ($newlength >= $oldlength);
						$oldlength = $newlength;
					}
				}

				# If we're on http://www.example.com and have a link
				# to http://www.example.com/foo/bar.htm, change the
				# link to /foo/bar.htm - there's no need to include
				# the site name in the link
				unless(defined($self->{info})) {
					if($self->{cache}) {
						$self->{info} = CGI::Info->new({ cache => $self->{cache} });
					} else {
						$self->{info} = CGI::Info->new();
					}
				}

				my $href = $self->{info}->host_name();
				my $protocol = $self->{info}->protocol();

				unless($protocol) {
					$protocol = 'http';
				}

				$self->{body} =~ s/<a\s+?href="$protocol:\/\/$href"/<a href="\/"/gim;
				$self->{body} =~ s/<a\s+?href="$protocol:\/\/$href/<a href="/gim;
				$self->{body} =~ s/<a\s+?href="$protocol:\/\//<a href="\/\//gim;

				# If we're in "/cgi-bin/foo.cgi?arg1=a" replace
				# "/cgi-bin/foo.cgi?arg2=b" with "?arg2=b"

				if(my $script_name = $ENV{'SCRIPT_NAME'}) {
					if($script_name =~ /^\//) {
						$self->{body} =~ s/<a\s+?href="$script_name(\?.+)?"/<a href="$1"/gim;
					}
				}

				# TODO use URI->path_segments to change links in
				# /aa/bb/cc/dd.htm which point to /aa/bb/ff.htm to
				# ../ff.htm

				# TODO: <img border=0 src=...>
				$self->{body} =~ s/<img\s+?src="$protocol:\/\/$href"/<img src="\/"/gim;
				$self->{body} =~ s/<img\s+?src="$protocol:\/\/$href/<img src="/gim;

				# Don't use HTML::Clean because of RT402
				# my $h = new HTML::Clean(\$self->{body});
				# # $h->compat();
				# $h->strip();
				# my $ref = $h->data();

				# Don't always do javascript 'best' since it's confused
				# by the common <!-- HIDE technique.
				# See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790
				my $options = {
					remove_comments => 1,
					remove_newlines => 0,
					do_stylesheet => 'minify'
				};
				if($self->{optimise_content} >= 2) {
					$options->{do_javascript} = 'best';
					$self->{body} =~ s/(<script.*?>)\s*<!--/$1/gi;
					$self->{body} =~ s/\/\/-->\s*<\/script>/<\/script>/gi;
					$self->{body} =~ s/(<script.*?>)\s+/$1/gi;
				}
				$self->{body} = HTML::Packer->init()->minify(\$self->{body}, $options);
				if($self->{optimise_content} >= 2) {
					# Change document.write("a"); document.write("b")
					# into document.write("a"+"b");
					while(1) {
						$self->{body} =~ s/<script\s*?type\s*?=\s*?"text\/javascript"\s*?>(.*?)document\.write\((.+?)\);\s*?document\.write\((.+?)\)/<script type="text\/JavaScript">${1}document.write($2+$3)/igs;
						$newlength = length($self->{body});
						last if ($newlength >= $oldlength);
						$oldlength = $newlength;
					}
				}
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
						warn($errtext);
						$self->{body} .= $errtext;
					}
				}
			}
		}
	}

	$self->{status} = 200;

	if(defined($headers) && ($headers =~ /^Status: (\d+)/m)) {
		$self->{status} = $1;
	}

	if($self->{'logger'}) {
		$self->{'logger'}->debug("Initial status = $self->{status}");
	}

	# Generate the eTag before compressing, since the compressed data
	# includes the mtime field which changes thus causing a different
	# Etag to be generated
	if($ENV{'SERVER_PROTOCOL'} &&
	  ($ENV{'SERVER_PROTOCOL'} eq 'HTTP/1.1') &&
	  $self->{generate_etag} && defined($self->{body})) {
		# encode to avoid "Wide character in subroutine entry"
		require Encode;
		$self->{_encode_loaded} = 1;
		$self->{etag} = '"' . Digest::MD5->new->add(Encode::encode_utf8($self->{body}))->hexdigest() . '"';
		if($ENV{'HTTP_IF_NONE_MATCH'} && $self->{generate_304} && ($self->{status} == 200)) {
			$self->_check_if_none_match();
		}
	}

	my $dbh;
	if(my $save_to = $self->{save_to}) {
		my $sqlite_file = $save_to->{directory} . '/fcgi.buffer.sql';
		if(!-r $sqlite_file) {
			if(!-d $save_to->{directory}) {
				mkdir $save_to->{directory};
			}
			$dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef);
			if($self->{save_to}->{create_table}) {
				$dbh->prepare('CREATE TABLE fcgi_buffer(key char PRIMARY KEY, language char, browser_type char, path char UNIQUE NOT NULL, uri char NOT NULL, creation timestamp NOT NULL)')->execute();
			}
		} else {
			$dbh = DBI->connect("dbi:SQLite:dbname=$sqlite_file", undef, undef);
		}
	}

	my $encoding = $self->_should_gzip();
	my $unzipped_body = $self->{body};

	if(defined($unzipped_body)) {
		my $range = $ENV{'Range'} ? $ENV{'Range'} : $ENV{'HTTP_RANGE'};

		if($range && !$self->{cache}) {
			# TODO: Partials
			if($range =~ /^bytes=(\d*)-(\d*)/) {
				if($1 && $2) {
					$self->{body} = substr($self->{body}, $1, $2-$1);
				} elsif($1) {
					$self->{body} = substr($self->{body}, $1);
				} elsif($2) {
					$self->{body} = substr($self->{body}, 0, $2);
				}
				$unzipped_body = $self->{body};
				$self->{'status'} = 206;
			}
		}
		$self->_compress({ encoding => $encoding });
	}

	if($self->{cache}) {
		require Storable;

		my $cache_hash;
		my $key = $self->_generate_key();

		# Cache unzipped version
		if(!defined($self->{body})) {
			if($self->{send_body}) {
				$self->{cobject} = $self->{cache}->get_object($key);
				if(defined($self->{cobject})) {
					$cache_hash = Storable::thaw($self->{cobject}->value());
					$headers = $cache_hash->{'headers'};
					$self->_set_content_type($headers);
					@{$self->{o}} = ("X-FCGI-Buffer-$VERSION: Hit");
					if($self->{info}) {
						my $host_name = $self->{info}->host_name();
						push @{$self->{o}}, "X-Cache: HIT from $host_name";
						push @{$self->{o}}, "X-Cache-Lookup: HIT from $host_name";
					} else {
						push @{$self->{o}}, 'X-Cache: HIT';
						push @{$self->{o}}, 'X-Cache-Lookup: HIT';
					}
				} else {
					carp "Error retrieving data for key $key";
				}
			}

			# Nothing has been output yet, so we can check if it's
			# OK to send 304 if possible
			if($self->{send_body} && $ENV{'SERVER_PROTOCOL'} &&
			  ($ENV{'SERVER_PROTOCOL'} eq 'HTTP/1.1') &&
			  $self->{generate_304} && ($self->{status} == 200)) {
				if($ENV{'HTTP_IF_MODIFIED_SINCE'}) {
					$self->_check_modified_since({
						since => $ENV{'HTTP_IF_MODIFIED_SINCE'},
						modified => $self->{cobject}->created_at()
					});
				}
			}
			if($self->{send_body} && ($self->{status} == 200)) {
				$self->{body} = $cache_hash->{'body'};
				if($dbh) {
					my $changes = $self->_save_to($self->{body}, $dbh);
					if($changes && (my $ttl = $self->{save_to}->{ttl})) {
						push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str(time + $ttl);
					}
				}
				if(!defined($self->{body})) {
					# Panic
					$headers = 'Status: 500 Internal Server Error';
					@{$self->{o}} = ('Content-type: text/plain');
					$self->{body} = "Can't retrieve body for key $key, cache_hash contains:\n";
					foreach my $k (keys %{$cache_hash}) {
						$self->{body} .= "\t$k\n";
					}

					if($dbh) {
						my $query = "SELECT DISTINCT path FROM fcgi_buffer WHERE key = '$key'";
						my $sth = $dbh->prepare($query);
						if($self->{logger}) {
							$self->{logger}->debug($query);
						}
						if($sth->execute() && (my $href = $sth->fetchrow_hashref())) {
							if(my $path = $href->{'path'}) {
								unlink($path);
							}
						}
						$query = "DELETE FROM fcgi_buffer WHERE key = '$key'";
						$dbh->prepare($query)->execute();
						if($self->{logger}) {
							$self->{logger}->debug($query);
						}
					}

					$self->{cache}->remove($key);

					if($self->{logger}) {
						$self->{logger}->error("Can't retrieve body for key $key");
					} else {
						carp "Can't retrieve body for key $key";
					}
					warn($self->{body});
					$self->{send_body} = 0;
					$self->{status} = 500;
				}
			}
			if($self->{send_body} && $ENV{'SERVER_PROTOCOL'} &&
			  ($ENV{'SERVER_PROTOCOL'} eq 'HTTP/1.1') &&
			  ($self->{status} == 200)) {
				if($ENV{'HTTP_IF_NONE_MATCH'} && $self->{generate_etag}) {
					if(!defined($self->{etag})) {
						unless($self->{_encode_loaded}) {
							require Encode;
							$self->{_encode_loaded} = 1;
						}
						$self->{etag} = '"' . Digest::MD5->new->add(Encode::encode_utf8($self->{body}))->hexdigest() . '"';
					}
					$self->_check_if_none_match();
				}
			}
			if($self->{status} == 200) {
				$encoding = $self->_should_gzip();
				if($self->{send_body}) {
					if($self->{generate_etag} && !defined($self->{etag}) && ((!defined($headers)) || ($headers !~ /^ETag: /m))) {
						$self->{etag} = '"' . Digest::MD5->new->add(Encode::encode_utf8($self->{body}))->hexdigest() . '"';
					}
					$self->_compress({ encoding => $encoding });
				}
			}
			my $cannot_304 = !$self->{generate_304};
			unless($self->{etag}) {
				if(defined($headers) && ($headers =~ /^ETag: "([a-z0-9]{32})"/m)) {
					$self->{etag} = $1;
				} else {
					$self->{etag} = $cache_hash->{'etag'};
				}
			}
			if($ENV{'HTTP_IF_NONE_MATCH'} && $self->{send_body} && ($self->{status} != 304) && $self->{generate_304}) {
				if(!$self->_check_if_none_match()) {
					$cannot_304 = 1;
				}
			}
			if($self->{cobject}) {
				if($ENV{'HTTP_IF_MODIFIED_SINCE'} && ($self->{status} != 304) && !$cannot_304) {
					$self->_check_modified_since({
						since => $ENV{'HTTP_IF_MODIFIED_SINCE'},
						modified => $self->{cobject}->created_at()
					});
				}
				if(($self->{status} == 200) && $self->{generate_last_modified}) {
					if($self->{logger}) {
						$self->{logger}->debug('Set Last-Modified to ', HTTP::Date::time2str($self->{cobject}->created_at()));
					}
					push @{$self->{o}}, "Last-Modified: " . HTTP::Date::time2str($self->{cobject}->created_at());
				}
			}
		} else {
			# Not in the server side cache
			if($self->{status} == 200) {
				my $changes = $self->_save_to($unzipped_body, $dbh);

				unless($self->{cache_age}) {
					# It would be great if CHI::set()
					# allowed the time to be 'lru' for least
					# recently used.
					$self->{cache_age} = '10 minutes';
				}
				$cache_hash->{'body'} = $unzipped_body;
				if($changes && $encoding) {
					$self->_compress({ encoding => $encoding });
				}
				if($self->{o} && scalar(@{$self->{o}})) {
					# Remember, we're storing the UNzipped
					# version in the cache
					my $c;
					if(defined($headers) && length($headers)) {
						$c = "$headers\r\n" . join("\r\n", @{$self->{o}});
					} else {
						$c = join("\r\n", @{$self->{o}});
					}
					$c =~ s/^Content-Encoding: .+$//mg;
					$c =~ s/^Vary: Accept-Encoding.*\r?$//mg;
					$c =~ s/\n+/\n/gs;
					if(length($c)) {
						$cache_hash->{'headers'} = $c;
					}
				} elsif(defined($headers) && length($headers)) {
					$headers =~ s/^Content-Encoding: .+$//mg;
					$headers =~ s/^Vary: Accept-Encoding.*\r?$//mg;
					$headers =~ s/\n+/\n/gs;
					if(length($headers)) {
						$cache_hash->{'headers'} = $headers;
					}
				}
				if($self->{generate_etag} && defined($self->{etag})) {
					$cache_hash->{'etag'} = $self->{etag};
				}
				# TODO: Support the Expires header
				# if($headers !~ /^Expires: /m))) {
				# }
				if($self->{logger}) {
					$self->{logger}->debug("Store $key in the cache, age = ", $self->{cache_age}, ' ', length($cache_hash->{'body'}), ' bytes');
				}
				$self->{cache}->set($key, Storable::freeze($cache_hash), $self->{cache_age});

				# Create a static page with the information and link to that in the output
				# HTML
				if($dbh && $self->{info} && $self->{save_to} && (my $request_uri = $ENV{'REQUEST_URI'})) {
					my $query = "SELECT DISTINCT creation FROM fcgi_buffer WHERE key = ?";
					if($self->{logger}) {
						$self->{logger}->debug("$query: $key");
					}
					my $sth = $dbh->prepare($query);
					$sth->execute($key);
					if(my $href = $sth->fetchrow_hashref()) {
						if(my $ttl = $self->{save_to}->{ttl}) {
							push @{$self->{o}}, 'Expires: ' .
								HTTP::Date::time2str($href->{'creation'} + $ttl);
						}
					} else {
						my $dir = $self->{save_to}->{directory};
						my $browser_type = $self->{info}->browser_type();
						my $language = $self->{lingua}->language();
						my $bdir = "$dir/$browser_type";
						if($bdir =~ /^(.+)$/) {
							$bdir = $1; # Untaint
						}
						my $ldir = "$bdir/$language";
						my $script_name = $self->{info}->script_name();
						my $sdir = "$ldir/$script_name";
						if(!-d $bdir) {
							mkdir $bdir;
							mkdir $ldir;
							mkdir $sdir;
						} elsif(!-d $ldir) {
							mkdir $ldir;
							mkdir $sdir;
						} elsif(!-d $sdir) {
							mkdir $sdir;
						}
						my $path = "$sdir/" . $self->{info}->as_string() . '.html';
						if($path =~ /^(.+)$/) {
							$path = $1; # Untaint
							$path =~ tr/[\|;]/_/;
						}
						if(open(my $fout, '>', $path)) {
							my $u = $request_uri;
							$u =~ s/\?/\\?/g;
							my $copy = $unzipped_body;
							my $changes = ($copy =~ s/<a\s+href="$u"/<a href="$path"/gi);

							# handle <a href="?arg3=4">Call self with different args</a>
							$script_name = $ENV{'SCRIPT_NAME'};
							$copy =~ s/<a\s+href="(\?.+?)"/<a href="$script_name$1"/gi;

							print $fout $copy;
							close $fout;
							# Do INSERT OR REPLACE in case another program has
							# got in first,
							$query = "INSERT OR REPLACE INTO fcgi_buffer(key, language, browser_type, path, uri, creation) VALUES('$key', '$language', '$browser_type', '$path', '$request_uri', strftime('\%s','now'))";
							if($self->{logger}) {
								$self->{logger}->debug($query);
							}
							$dbh->prepare($query)->execute();

							if($changes && (my $ttl = $self->{save_to}->{ttl})) {
								push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str(time + $ttl);
							}
						} elsif($self->{logger}) {
							$self->{logger}->warn("Can't create $path");
						}
					}
				}
				if($self->{generate_last_modified}) {
					$self->{cobject} = $self->{cache}->get_object($key);
					if(defined($self->{cobject})) {
						push @{$self->{o}}, "Last-Modified: " . HTTP::Date::time2str($self->{cobject}->created_at());
					} else {
						push @{$self->{o}}, "Last-Modified: " . HTTP::Date::time2str(time);
					}
				}
			}
			if($self->{info}) {
				my $host_name = $self->{info}->host_name();
				if(defined($self->{x_cache})) {
					push @{$self->{o}}, 'X-Cache: ' . $self->{x_cache} . " from $host_name";
				} else {
					push @{$self->{o}}, "X-Cache: MISS from $host_name";
				}
				push @{$self->{o}}, "X-Cache-Lookup: MISS from $host_name";
			} else {
				if(defined($self->{x_cache})) {
					push @{$self->{o}}, 'X-Cache: ' . $self->{x_cache};
				} else {
					push @{$self->{o}}, 'X-Cache: MISS';
				}
				push @{$self->{o}}, 'X-Cache-Lookup: MISS';
			}
			push @{$self->{o}}, "X-FCGI-Buffer-$VERSION: Miss";
		}
		# We don't need it any more, so give Perl a chance to
		# tidy it up seeing as we're in the destructor
		delete $self->{cache};
	} elsif($self->{info}) {
		my $host_name = $self->{info}->host_name();
		push @{$self->{o}}, ("X-Cache: MISS from $host_name", "X-Cache-Lookup: MISS from $host_name");
		if($self->_save_to($unzipped_body, $dbh) && $encoding) {
			$self->_compress({ encoding => $encoding });
		}
	} else {
		push @{$self->{o}}, ('X-Cache: MISS', 'X-Cache-Lookup: MISS');
	}

	if($self->{generate_etag} && ((!defined($headers)) || ($headers !~ /^ETag: /m))) {
		if(defined($self->{etag})) {
			push @{$self->{o}}, "ETag: $self->{etag}";
			if($self->{logger}) {
				$self->{logger}->debug("Set ETag to $self->{etag}");
			}
		} elsif($self->{logger} && (($self->{status} == 200) || $self->{status} == 304) && !$self->is_cached()) {
			$self->{logger}->warn("BUG: ETag not generated, status $self->{status}");
		}
	}

	my $body_length;
	if(defined($self->{body})) {
		if(utf8::is_utf8($self->{body})) {
			utf8::encode($self->{body});
		}
		$body_length = length($self->{body});
	} else {
		$body_length = 0;
	}

	if(defined($headers) && length($headers)) {
		# Put the original headers first, then those generated within
		# FCGI::Buffer
		unshift @{$self->{o}}, split(/\r\n/, $headers);
		if($self->{body} && $self->{send_body}) {
			unless(grep(/^Content-Length: \d/, @{$self->{o}})) {
				push @{$self->{o}}, "Content-Length: $body_length";
			}
		}
		unless(grep(/^Status: \d/, @{$self->{o}})) {
			require HTTP::Status;
			HTTP::Status->import();

			push @{$self->{o}}, 'Status: ' . $self->{status} . ' ' . HTTP::Status::status_message($self->{status});
		}
	} else {
		push @{$self->{o}}, "X-FCGI-Buffer-$VERSION: No headers";
	}

	if($body_length && $self->{send_body}) {
		push @{$self->{o}}, ('', $self->{body});
	}

	# XXXXXXXXXXXXXXXXXXXXXXX
	if(0) {
		# This code helps to debug Wide character prints
		my $wideCharWarningsIssued = 0;
		my $widemess;
		$SIG{__WARN__} = sub {
			$wideCharWarningsIssued += "@_" =~ /Wide character in .../;
			$widemess = "@_";
			if($self->{logger}) {
				$self->{logger}->fatal($widemess);
				my $i = 1;
				$self->{logger}->trace('Stack Trace');
				while((my @call_details = (caller($i++)))) {
					$self->{logger}->trace($call_details[1], ':', $call_details[2], ' in function ', $call_details[3]);
				}
			}
			CORE::warn(@_);	# call the builtin warn as usual
		};

		if(scalar @{$self->{o}}) {
			print join("\r\n", @{$self->{o}});
			if($wideCharWarningsIssued) {
				my $mess = join("\r\n", @{$self->{o}});
				$mess =~ /[^\x00-\xFF]/;
				open(my $fout, '>>', '/tmp/NJH');
				print $fout "$widemess:\n",
					$mess,
					'x' x 40,
					"\n";
				close $fout;
			}
		}
	} elsif(scalar @{$self->{o}}) {
		print join("\r\n", @{$self->{o}});
	}
	# XXXXXXXXXXXXXXXXXXXXXXX

	if((!$self->{send_body}) || !defined($self->{body})) {
		print "\r\n\r\n";
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
		push @{$self->{o}}, "Status: 304 Not Modified";
		$self->{status} = 304;
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
	$self->{body} =~ s/(((\s+|\r)\n|\n(\s+|\+)))/\n/g;
	# $self->{body} =~ s/\r\n/\n/gs;
	# $self->{body} =~ s/\s+\n/\n/gs;
	# $self->{body} =~ s/\n+/\n/gs;
	# $self->{body} =~ s/\n\s+|\s+\n/\n/g;
	$self->{body} =~ s/\<\/div\>\s+\<div/\<\/div\>\<div/gis;
	# $self->{body} =~ s/\<\/p\>\s\<\/div/\<\/p\>\<\/div/gis;
	# $self->{body} =~ s/\<div\>\s+/\<div\>/gis;	# Remove spaces after <div>
	$self->{body} =~ s/(<div>\s+|\s+<div>)/<div>/gis;
	$self->{body} =~ s/\s+<\/div\>/\<\/div\>/gis;	# Remove spaces before </div>
	$self->{body} =~ s/\s+\<p\>|\<p\>\s+/\<p\>/im;	# TODO <p class=
	$self->{body} =~ s/\s+\<\/p\>|\<\/p\>\s+/\<\/p\>/gis;
	$self->{body} =~ s/<html>\s+<head>/<html><head>/is;
	$self->{body} =~ s/\s*<\/head>\s+<body>\s*/<\/head><body>/is;
	$self->{body} =~ s/<html>\s+<body>/<html><body>/is;
	$self->{body} =~ s/<body>\s+/<body>/is;
	$self->{body} =~ s/\s+\<\/html/\<\/html/is;
	$self->{body} =~ s/\s+\<\/body/\<\/body/is;
	$self->{body} =~ s/\s(\<.+?\>\s\<.+?\>)/$1/;
	# $self->{body} =~ s/(\<.+?\>\s\<.+?\>)\s/$1/g;
	$self->{body} =~ s/\<p\>\s/\<p\>/gi;
	$self->{body} =~ s/\<\/p\>\s\<p\>/\<\/p\>\<p\>/gi;
	$self->{body} =~ s/\<\/tr\>\s\<tr\>/\<\/tr\>\<tr\>/gi;
	$self->{body} =~ s/\<\/td\>\s\<\/tr\>/\<\/td\>\<\/tr\>/gi;
	$self->{body} =~ s/\<\/td\>\s*\<td\>/\<\/td\>\<td\>/gis;
	$self->{body} =~ s/\<\/tr\>\s\<\/table\>/\<\/tr\>\<\/table\>/gi;
	$self->{body} =~ s/\<br\s?\/?\>\s?\<p\>/\<p\>/gi;
	$self->{body} =~ s/\<br\>\s+/\<br\>/gi;
	$self->{body} =~ s/\s+\<br\>/\<br\>/gi;
	$self->{body} =~ s/\<br\s?\/\>\s/\<br \/\>/gi;
	$self->{body} =~ s/[ \t]+/ /gs;	# Remove duplicate space, don't use \s+ it breaks JavaScript
	$self->{body} =~ s/\s\<p\>/\<p\>/gi;
	$self->{body} =~ s/\s\<script/\<script/gi;
	$self->{body} =~ s/(<script>\s|\s<script>)/<script>/gis;
	$self->{body} =~ s/(<\/script>\s|\s<\/script>)/<\/script>/gis;
	$self->{body} =~ s/\<td\>\s/\<td\>/gi;
	$self->{body} =~ s/\s+\<a\shref="(.+?)"\>\s?/ <a href="$1">/gis;
	$self->{body} =~ s/\s?<a\shref=\s"(.+?)"\>/ <a href="$1">/gis;
	$self->{body} =~ s/\s+<\/a\>\s+/<\/a> /gis;
	$self->{body} =~ s/(\s?<hr>\s+|\s+<hr>\s?)/<hr>/gis;
	# $self->{body} =~ s/\s<hr>/<hr>/gis;
	# $self->{body} =~ s/<hr>\s/<hr>/gis;
	$self->{body} =~ s/<\/li>\s+<li>/<\/li><li>/gis;
	$self->{body} =~ s/<\/li>\s+<\/ul>/<\/li><\/ul>/gis;
	$self->{body} =~ s/<ul>\s+<li>/<ul><li>/gis;
	$self->{body} =~ s/\<\/option\>\s+\<option/\<\/option\>\<option/gis;
	$self->{body} =~ s/<title>\s*(.+?)\s*<\/title>/<title>$1<\/title>/is;
}

# Create a key for the cache
sub _generate_key {
	my $self = shift;
	if($self->{cache_key}) {
		return $self->{cache_key};
	}
	unless(defined($self->{info})) {
		$self->{info} = CGI::Info->new({ cache => $self->{cache} });
	}

	my $key = $self->{info}->browser_type() . '::' . $self->{info}->domain_name() . '::' . $self->{info}->script_name() . '::' . $self->{info}->as_string();

	if($self->{lingua}) {
		$key .= '::' . $self->{lingua}->language();
	}
	if($ENV{'HTTP_COOKIE'}) {
		# Different states of the client are stored in different caches
		# Don't put different Google Analytics in different caches, and anyway they
		# would be wrong
		foreach my $cookie(split(/;/, $ENV{'HTTP_COOKIE'})) {
			unless($cookie =~ /^__utm[abcz]/) {
				$key .= "::$cookie";
			}
		}
	}

	# Honour the Vary headers
	my $headers = $self->{'headers'};
	if($headers && ($headers =~ /^Vary: .*$/m)) {
		if(defined($self->{logger})) {
			$self->{logger}->debug('Found Vary header');
		}
		foreach my $h1(split(/\r?\n/, $headers)) {
			my ($h1_name, $h1_value) = split /\:\s*/, $h1, 2;
			if(lc($h1_name) eq 'vary') {
				foreach my $h2(split(/\r?\n/, $headers)) {
					my ($h2_name, $h2_value) = split /\:\s*/, $h2, 2;
					if($h2_name eq $h1_value) {
						$key .= "::$h2_value";
						last;
					}
				}
			}
		}
	}
	$key =~ s/\//::/g;
	$key =~ s/::::/::/g;
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
    # By default, generate_tag, generate_304 and compress_content are ON,
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
	cache_age => '10 minutes',	# how long to store responses in the cache
	logger => $self->{logger},
	lint_content => 0,	# Pass through HTML::Lint
	generate_304 => 1,	# When appropriate, generate 304: Not modified
	save_to => { directory => '/var/www/htdocs/save_to', ttl => 600, create_table => 1 },
	info => CGI::Info->new(),
	lingua => CGI::Lingua->new(),
    });

If no cache_key is given, one will be generated which may not be unique.
The cache_key should be a unique value dependent upon the values set by the
browser.

The cache object will be an object that understands get_object(),
set(), remove() and created_at() messages, such as an L<CHI> object. It is
used as a server-side cache to reduce the need to rerun database accesses.

Items stay in the server-side cache by default for 10 minutes.
This can be overridden by the cache_control HTTP header in the request, and
the default can be changed by the cache_age argument to init().

Save_to is feature which stores output of dynamic pages to your
htdocs tree and replaces future links that point to that page with static links
to avoid going through CGI at all.
Ttl is set to the number of seconds that the static pages are deemed to
be live for, the default is 10 minutes.
If set to 0, the page is live forever.
To enable save_to, a info and lingua arguments must also be given.
It works best when cache is also given.
Only use where output is guaranteed to be the same with a given set of arguments
(the same criteria for enabling generate_304).

Info is an optional argument to give information about the FCGI environment, e.g.
a L<CGI::Info> object.

Logger will be an object that understands debug() such as an L<Log::Log4perl>
object.

To generate a last_modified header, you must give a cache object.

Init allows a reference of the options to be passed. So both of these work:
    use FCGI::Buffer;
    #...
    my $buffer = FCGI::Buffer->new();
    $b->init(generate_etag => 1);
    $b->init({ generate_etag => 1, info => CGI::Info->new() });

Generally speaking, passing by reference is better since it copies less on to
the stack.

If you give a cache to init() then later give cache => undef,
the server side cache is no longer used.
This is useful when you find an error condition when creating your HTML
and decide that you no longer wish to store the output in the cache.

=cut

sub init {
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	# Safe options - can be called at any time
	if(defined($params{generate_etag})) {
		$self->{generate_etag} = $params{generate_etag};
	}
	if(defined($params{generate_last_modified})) {
		$self->{generate_last_modified} = $params{generate_last_modified};
	}
	if(defined($params{compress_content})) {
		$self->{compress_content} = $params{compress_content};
	}
	if(defined($params{optimise_content})) {
		$self->{optimise_content} = $params{optimise_content};
	}
	if(defined($params{lint_content})) {
		$self->{lint_content} = $params{lint_content};
	}
	if(defined($params{logger})) {
		$self->{logger} = $params{logger};
	}
	if(defined($params{lingua})) {
		$self->{lingua} = $params{lingua};
	}
	# Don't forget to handle where lingua could have been set in a previous init() call
	if(defined($params{save_to}) && $self->{lingua} && $self->can_cache()) {
		$self->{save_to} = $params{save_to};
		if(!exists($params{save_to})) {
			$self->{save_to} = 600;
		}
	}
	if(defined($params{generate_304})) {
		$self->{generate_304} = $params{generate_304};
	}
	if(defined($params{info}) && (!defined($self->{info}))) {
		$self->{info} = $params{info};
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
		if(defined($ENV{'HTTP_CACHE_CONTROL'})) {
			my $control = $ENV{'HTTP_CACHE_CONTROL'};
			if(defined($self->{logger})) {
				$self->{logger}->debug("cache_control = $control");
			}
			if($control =~ /^max-age\s*=\s*(\d+)$/) {
				# There is an argument not to do this
				# since one client will affect others
				$self->{cache_age} = "$1 seconds";
				if(defined($self->{logger})) {
					$self->{logger}->debug("cache_age = $self->{cache_age}");
				}
			}
		}
		$self->{cache_age} ||= $params{cache_age};
		if((!defined($params{cache})) && defined($self->{cache})) {
			if(defined($self->{logger})) {
				if($self->{cache_key}) {
					$self->{logger}->debug('disabling cache ', $self->{cache_key});
				} else {
					$self->{logger}->debug('disabling cache');
				}
			}
			delete $self->{cache};
		} else {
			$self->{cache} = $params{cache};
		}
		if(defined($params{cache_key})) {
			$self->{cache_key} = $params{cache_key};
		}
	}

	return $self;
}

sub import {
	# my $class = shift;
	shift;

	return unless scalar(@_);

	init(@_);
}

=head2 set_options

Synonym for init, kept for historical reasons.

=cut

sub set_options {
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	$self->init(\%params);
}

=head2 can_cache

Returns true if the server is allowed to store the results locally.

=cut

sub can_cache {
	my $self = shift;

	if(defined($self->{x_cache})) {
		return ($self->{x_cache} eq 'HIT');
	}
	if(defined($ENV{'NO_CACHE'}) || defined($ENV{'NO_STORE'})) {
		$self->{x_cache} = 'MISS';
		return 0;
	}
	if(defined($ENV{'HTTP_CACHE_CONTROL'})) {
		my $control = $ENV{'HTTP_CACHE_CONTROL'};
		if(defined($self->{logger})) {
			$self->{logger}->debug("cache_control = $control");
		}
		# TODO: check Authorization header not present
		if(($control eq 'no-store') ||
		   ($control eq 'no-cache') ||
		   ($control eq 'max-age=0') ||
		   ($control eq 'private')) {
			$self->{x_cache} = 'MISS';
			return 0;
		}
	}
	$self->{x_cache} = 'HIT';
	return 1;
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

    # To use server side caching you must give the cache argument, however
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

=cut

sub is_cached {
	my $self = shift;

	unless($self->{cache}) {
		if($self->{logger}) {
			$self->{logger}->debug("is_cached: cache hasn't been enabled");
		}
		return 0;
	}

	my $key = $self->_generate_key();

	if($self->{logger}) {
		$self->{logger}->debug("is_cached: looking for key = $key");
	}
	$self->{cobject} = $self->{cache}->get_object($key);
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

sub _my_age {
	my $self = shift;

	if($self->{script_mtime}) {
		return $self->{script_mtime};
	}
	unless(defined($self->{info})) {
		if($self->{cache}) {
			$self->{info} = CGI::Info->new({ cache => $self->{cache} });
		} else {
			$self->{info} = CGI::Info->new();
		}
	}

	my $path = $self->{info}->script_path();
	unless(defined($path)) {
		return;
	}

	my @statb = stat($path);
	$self->{script_mtime} = $statb[9];
	return $self->{script_mtime};
}

sub _should_gzip {
	my $self = shift;

	if($self->{compress_content} && ($ENV{'HTTP_ACCEPT_ENCODING'} || $ENV{'HTTP_TE'})) {
		if(defined($self->{content_type})) {
			my @content_type = @{$self->{content_type}};
			if($content_type[0] ne 'text') {
				return '';
			}
		}
		my $accept = lc($ENV{'HTTP_ACCEPT_ENCODING'} ? $ENV{'HTTP_ACCEPT_ENCODING'} : $ENV{'HTTP_TE'});
		foreach my $method(split(/,\s?/, $accept)) {
			if(($method eq 'gzip') || ($method eq 'x-gzip') || ($method eq 'br')) {
				return $method;
			}
		}
	}

	return '';
}

sub _set_content_type {
	my $self = shift;
	my $headers = shift;

	foreach my $header (split(/\r?\n/, $headers)) {
		my ($header_name, $header_value) = split /\:\s*/, $header, 2;
		if (lc($header_name) eq 'content-type') {
			my @content_type;
			@content_type = split /\//, $header_value, 2;
			$self->{content_type} = \@content_type;
			return;
		}
	}
}

sub _compress()
{
	my $self = shift;
	my %params = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

	my $encoding = $params{encoding};

	if((length($encoding) == 0) || (length($self->{body}) < MIN_GZIP_LEN)) {
		return;
	}

	if($encoding eq 'gzip') {
		require Compress::Zlib;
		Compress::Zlib->import;

		# Avoid 'Wide character in memGzip'
		unless($self->{_encode_loaded}) {
			require Encode;
			$self->{_encode_loaded} = 1;
		}
		my $nbody = Compress::Zlib::memGzip(\Encode::encode_utf8($self->{body}));
		if(length($nbody) < length($self->{body})) {
			$self->{body} = $nbody;
			unless(grep(/^Content-Encoding: gzip/, @{$self->{o}})) {
				push @{$self->{o}}, 'Content-Encoding: gzip';
			}
			unless(grep(/^Vary: Accept-Encoding/, @{$self->{o}})) {
				push @{$self->{o}}, 'Vary: Accept-Encoding';
			}
		}
	} elsif($encoding eq 'br') {
		require IO::Compress::Brotli;
		IO::Compress::Brotli->import();

		unless($self->{_encode_loaded}) {
			require Encode;
			$self->{_encode_loaded} = 1;
		}
		my $nbody = IO::Compress::Brotli::bro(Encode::encode_utf8($self->{body}));
		if(length($nbody) < length($self->{body})) {
			$self->{body} = $nbody;
			unless(grep(/^Content-Encoding: br/, @{$self->{o}})) {
				push @{$self->{o}}, 'Content-Encoding: br';
			}
			unless(grep(/^Vary: Accept-Encoding/, @{$self->{o}})) {
				push @{$self->{o}}, 'Vary: Accept-Encoding';
			}
		}
	}
}

sub _check_if_none_match {
	my $self = shift;

	if($self->{logger}) {
		$self->{logger}->debug("Compare $ENV{HTTP_IF_NONE_MATCH} with $self->{etag}");
	}
	if($ENV{'HTTP_IF_NONE_MATCH'} eq $self->{etag}) {
		push @{$self->{o}}, 'Status: 304 Not Modified';
		$self->{send_body} = 0;
		$self->{status} = 304;
		if($self->{logger}) {
			$self->{logger}->debug('Set status to 304');
		}
		return 1;
	}
	if($self->{cache} && $self->{logger} && $self->{logger}->is_debug()) {
		my $cached_copy = $self->{cache}->get($self->_generate_key());

		if($cached_copy && $self->{body}) {
			require Text::Diff;
			Text::Diff->import();

			$cached_copy = Storable::thaw($cached_copy)->{body};
			my $diffs = diff(\$self->{body}, \$cached_copy);
			$self->{logger}->debug('diffs: ', $diffs);
		} else {
			$self->{logger}->debug('Nothing to compare');
		}
	}
	return 0;
}

# replace dynamic links with static links
sub _save_to {
	my ($self, $unzipped_body, $dbh) = @_;

	return 0 unless($dbh && $self->{info} && (my $request_uri = $ENV{'REQUEST_URI'}));

	my $query;
	my $copy = $unzipped_body;
	my $changes = 0;
	my $creation;
	my %seen_links;
	while($unzipped_body =~ /<a\shref="(.+?)"/gis) {
		my $link = $1;
		next if($seen_links{$link});	# Already updated in the copy
		$seen_links{$link} = 1;
		$link =~ tr/[\|;]/_/;

		my $search_uri = $link;
		if($search_uri =~ /^\?/) {
			# CGI script has links to itself
			# $search_uri = "${request_uri}${link}";
			my $r = $request_uri;
			$r =~ s/\?.*$//;
			$search_uri = "${r}$link";
		} else {
			next if($link =~ /^https?:\/\//);	# FIXME: skips full URLs to ourself
								#	Though optimise_content fixes that
			next if($link =~ /.html?$/);
			next if($link =~ /.jpg$/);
			next if($link =~ /.gif$/);
		}
		if($self->{save_to}->{ttl}) {
			$query = "SELECT DISTINCT path, creation FROM fcgi_buffer WHERE uri = ? AND language = ? AND browser_type = ? AND creation >= strftime('\%s','now') - " . $self->{save_to}->{ttl};
		} else {
			$query = "SELECT DISTINCT path, creation FROM fcgi_buffer WHERE uri = ? AND language = ? AND browser_type = ?";
		}
		if($self->{logger}) {
			$self->{logger}->debug("$query: $search_uri");
		}
		my $sth = $dbh->prepare($query);
		if(!defined($sth)) {
			if($self->{logger}) {
				$self->{logger}->warn("failed to prepare '$query'");
			}
		} else {
			$sth->execute($search_uri, $self->{lingua}->language(), $self->{info}->browser_type());
			if(my $href = $sth->fetchrow_hashref()) {
				if(my $path = $href->{'path'}) {
					if(-r $path) {
						$link =~ s/\?/\\?/g;
						my $rootdir = $self->{info}->rootdir();
						$path =~ s/^$rootdir//;
						$changes += ($copy =~ s/<a\s+href="$link">/<a href="$path">/gis);
						# Find the first link that will expire and use that
						if((!defined($creation)) || ($href->{'creation'} < $creation)) {
							$creation = $href->{'creation'};
						}
					} else {
						$query = "DELETE FROM fcgi_buffer WHERE path = ?";
						$dbh->prepare($query)->execute($path);
						if($self->{logger}) {
							$self->{logger}->warn("Remove entry for non-existant file $path");
						}
					}
				}
			}
		}
	};
	my $expiration = 0;
	if(defined($creation) && (my $ttl = $self->{save_to}->{ttl})) {
		$expiration = $creation + $ttl;
	}
	if($changes && (($expiration == 0) || ($expiration >= time))) {
		if($self->{logger}) {
			# $self->{logger}->debug("$changes links now point to static pages");
			$self->{logger}->info("$changes links now point to static pages");
		}
		$unzipped_body = $copy;
		$self->{'body'} = $unzipped_body;
		if(my $ttl = $self->{save_to}->{ttl}) {
			push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str($creation + $ttl);
		}
	} elsif($expiration && ($expiration < time)) {
		# Delete the save_to files
		if($self->{save_to}->{ttl}) {
			$query = "SELECT path FROM fcgi_buffer WHERE creation < strftime('\%s','now') - " . $self->{save_to}->{ttl};
		} else {
			$query = 'SELECT path FROM fcgi_buffer';	# Hmm, I suspect this is overkill
		}
		my $sth = $dbh->prepare($query);
		$sth->execute();
		while(my $href = $sth->fetchrow_hashref()) {
			if(my $path = $href->{'path'}) {
				if($self->{logger}) {
					$self->{logger}->debug("unlink $path");
				}
				unlink $path;
			}
		}
		if($self->{save_to}->{ttl}) {
			$query = "DELETE FROM fcgi_buffer WHERE creation < strftime('\%s','now') - " . $self->{save_to}->{ttl};
		} else {
			$query = 'DELETE FROM fcgi_buffer';	# Hmm, I suspect this is overkill
		}
		if($self->{logger}) {
			$self->{logger}->debug($query);
		}
		$dbh->prepare($query)->execute();
	# } else {
		# Old code
		# if($self->{save_to}->{ttl}) {
			# $query = "SELECT DISTINCT path, creation FROM fcgi_buffer WHERE key = '$key' AND creation >= strftime('\%s','now') - " . $self->{save_to}->{ttl};
		# } else {
			# $query = "SELECT DISTINCT path, creation FROM fcgi_buffer WHERE key = '$key'";
		# }
		# my $sth = $dbh->prepare($query);
		# $sth->execute();
		# my $href = $sth->fetchrow_hashref();
		# if(my $path = $href->{'path'}) {
			# # FIXME: don't do this if we've passed the TTL, and if we are clean
			# #	up the database and remove the static page
			# $request_uri =~ s/\?/\\?/g;
			# if(($unzipped_body =~ s/<a href="$request_uri"/<a href="$path"/gi) > 0) {
				# $self->{'body'} = $unzipped_body;
				# if(my $ttl = $self->{save_to}->{ttl}) {
					# push @{$self->{o}}, 'Expires: ' . HTTP::Date::time2str($href->{creation} + $ttl);
				# }
			# }
		# }
	}
	return $changes;
}

=head1 AUTHOR

Nigel Horne, C<< <njh at bandsman.co.uk> >>

=head1 BUGS

FCGI::Buffer should be safe even in scripts which produce lots of different
output, e.g. e-commerce situations.
On such pages, however, I strongly urge to setting generate_304 to 0 and
sending the HTTP header "Cache-Control: no-cache".

When using L<Template>, ensure that you don't use it to output to STDOUT,
instead you will need to capture into a variable and print that.
For example:

    my $output;
    $template->process($input, $vars, \$output) || ($output = $template->error());
    print $output;

Can produce buggy JavaScript if you use the <!-- HIDING technique.
This is a bug in L<JavaScript::Packer>, not FCGI::Buffer.
See https://github.com/nevesenin/javascript-packer-perl/issues/1#issuecomment-4356790

Mod_deflate can confuse this when compressing output.
Ensure that deflation is off for .pl files:

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png|pl)$ no-gzip dont-vary

If you request compressed output then uncompressed output (or vice
versa) on input that produces the same output, the status will be 304.
The letter of the spec says that's wrong, so I'm noting it here, but
in practice you should not see this happen or have any difficulties
because of it.

FCGI::Buffer has not been tested against FastCGI.

I advise adding FCGI::Buffer as the last use statement so that it is
cleared up first.  In particular it should be loaded after
L<Log::Log4Perl>, if you're using that, so that any messages it
produces are printed after the HTTP headers have been sent by
FCGI::Buffer;

Save_to doesn't understand links in JavaScript, which means that if you use self-calling
CGIs which are loaded as a static page they may point to the wrong place.
The workaround is to avoid self-calling CGIs in JavaScript

Please report any bugs or feature requests to C<bug-fcgi-buffer at rt.cpan.org>,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FCGI-Buffer>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

CGI::Buffer, HTML::Packer, HTML::Lint

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FCGI::Buffer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FCGI-Buffer>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/FCGI-Buffer>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/FCGI-Buffer>

=item * Search CPAN

L<http://search.cpan.org/dist/FCGI-Buffer/>

=back

=head1 ACKNOWLEDGEMENTS

The inspiration and code for some of this is cgi_buffer by Mark
Nottingham: http://www.mnot.net/cgi_buffer.

=head1 LICENSE AND COPYRIGHT

The licence for cgi_buffer is:

    "(c) 2000 Copyright Mark Nottingham <mnot@pobox.com>

    This software may be freely distributed, modified and used,
    provided that this copyright notice remain intact.

    This software is provided 'as is' without warranty of any kind."

The rest of the program is Copyright 2015-2017 Nigel Horne,
and is released under the following licence: GPL

=cut

1; # End of FCGI::Buffer
