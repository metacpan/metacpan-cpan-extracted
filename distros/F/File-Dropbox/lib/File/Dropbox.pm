package File::Dropbox;
use strict;
use warnings;
use feature ':5.10';
use base qw{ Tie::Handle Exporter };
use Symbol;
use JSON;
use Errno qw{ ENOENT EISDIR EINVAL EPERM EACCES EAGAIN ECANCELED EFBIG };
use Fcntl qw{ SEEK_CUR SEEK_SET SEEK_END };
use Furl;
use IO::Socket::SSL;
use Net::DNS::Lite;

our $VERSION = 0.7;
our @EXPORT_OK = qw{ contents metadata putfile movefile copyfile createfolder deletefile };

my $hosts = {
	content => 'api-content.dropbox.com',
	api     => 'api.dropbox.com',
};

my $version = 1;

my $header1 = join ', ',
	'OAuth oauth_version="1.0"',
	'oauth_signature_method="PLAINTEXT"',
	'oauth_consumer_key="%s"',
	'oauth_token="%s"',
	'oauth_signature="%s&%s"';

my $header2 = 'Bearer %s';

sub new {
	my $self = Symbol::gensym;
	tie *$self, __PACKAGE__, my $this = { @_[1 .. @_ - 1] };

	*$self = $this;

	return $self;
} # new

sub TIEHANDLE {
	my $self = bless $_[1], ref $_[0] || $_[0];

	$self->{'chunk'}   //= 4 << 20;
	$self->{'root'}    //= 'sandbox';

	die 'Unexpected root value'
		unless $self->{'root'} =~ m{^(?:drop|sand)box$};

	$self->{'furl'} = Furl->new(
		timeout   => 10,
		inet_aton => \&Net::DNS::Lite::inet_aton,
		ssl_opts  => {
			SSL_verify_mode => SSL_VERIFY_PEER(),
		},

		%{ $self->{'furlopts'} //= {} },
	);

	$self->{'closed'}   = 1;
	$self->{'length'}   = 0;
	$self->{'position'} = 0;
	$self->{'mode'}     = '';
	$self->{'buffer'}   = '';

	return $self;
} # TIEHANDLE

sub READ {
	my ($self, undef, $length, $offset) = @_;

	undef $!;

	die 'Read is not supported on this handle'
		if $self->{'mode'} ne '<';

	substr($_[1] //= '', $offset // 0) = '', return 0
		if $self->EOF();

	my $furl = $self->{'furl'};

	my $url = 'https://';
	$url .= join '/', $hosts->{'content'}, $version;
	$url .= join '/', '/files', $self->{'root'}, $self->{'path'};

	my $response = $furl->get($url, [
		Range => sprintf('bytes=%i-%i', $self->{'position'}, $self->{'position'} + ($length || 1)),

		@{ &__headers__ },
	]);

	return $self->__error__($response)
		if $response->code != 206;

	my $meta  = $response->header('X-Dropbox-Metadata');
	my $bytes = $response->header('Content-Length');

	$self->{'position'} += $bytes > $length? $length : $bytes;

	substr($_[1] //= '', $offset // 0) = substr $response->content(), 0, $length;

	return $bytes;
} # READ

sub READLINE {
	my ($self) = @_;
	my $length;

	undef $!;

	die 'Readline is not supported on this handle'
		if $self->{'mode'} ne '<';

	if ($self->EOF()) {
		return if wantarray;

		# Special case: slurp mode + scalar context + empty file
		# return '' for first call and undef for subsequent
		return ''
			unless $self->{'eof'} or defined $/;

		$self->{'eof'} = 1;
		return undef;
	}

	{
		$length = length $self->{'buffer'};

		if (not wantarray and $length and defined $/) {
			my $position = index $self->{'buffer'}, $/;

			if (~$position) {
				$self->{'position'} += ($position += length $/);
				return substr $self->{'buffer'}, 0, $position, '';
			}
		}

		local $self->{'position'} = $self->{'position'} + $length;

		my $bytes = $self->READ($self->{'buffer'}, $self->{'chunk'}, $length);

		return if $!;
		redo   if not $length or $bytes;
	}

	$length = length $self->{'buffer'};

	if ($length) {
		# Multiline
		if (wantarray and defined $/) {
			$self->{'position'} += $length;

			my ($position, $length) = (0, length $/);
			my @lines;

			foreach ($self->{'buffer'}) {
				while (~(my $offset = index $_, $/, $position)) {
					$offset += $length;
					push @lines, substr $_, $position, $offset - $position;
					$position = $offset;
				}

				push @lines, substr $_, $position
					if $position < length;

				$_ = '';
			}

			return @lines;
		}

		# Slurp or last chunk
		$self->{'position'} += $length;
		return substr $self->{'buffer'}, 0, $length, '';
	}

	return undef;
} # READLINE

sub SEEK {
	my ($self, $position, $whence) = @_;

	undef $!;

	die 'Seek is not supported on this handle'
		if $self->{'mode'} ne '<';

	$self->{'buffer'} = '';

	delete $self->{'eof'};

	if ($whence == SEEK_SET) {
		$self->{'position'} = $position
	}

	elsif ($whence == SEEK_CUR) {
		$self->{'position'} += $position
	}

	elsif ($whence == SEEK_END) {
		$self->{'position'} = $self->{'length'} + $position
	}

	else {
		$! = EINVAL;
		return 0;
	}

	$self->{'position'} = 0
		if $self->{'position'} < 0;

	return 1;
} # SEEK

sub TELL {
	my ($self) = @_;

	die 'Tell is not supported on this handle'
		if $self->{'mode'} ne '<';

	return $self->{'position'};
} # TELL

sub WRITE {
	my ($self, $buffer, $length, $offset) = @_;

	undef $!;

	die 'Write is not supported on this handle'
		if $self->{'mode'} ne '>';

	die 'Append-only writes supported'
		if $offset and $offset != $self->{'offset'} + $self->{'length'};

	$self->{'offset'} //= $offset;
	$self->{'buffer'}  .= $buffer;
	$self->{'length'}  += $length;

	$self->__flush__() or return 0
		while $self->{'length'} >= $self->{'chunk'};

	return 1;
} # WRITE

sub CLOSE {
	my ($self) = @_;

	undef $!;

	return 1
		if $self->{'closed'};

	my $mode = $self->{'mode'};

	if ($mode eq '>') {
		if ($self->{'length'} or not $self->{'upload_id'}) {
			do {
				@{ $self }{qw{ closed mode }} = (1, '') and return 0
					unless $self->__flush__();
			} while length $self->{'buffer'};
		}
	}

	$self->{'closed'} = 1;
	$self->{'mode'}   = '';

	return $self->__flush__()
		if $mode eq '>';

	return 1;
} # CLOSE

sub OPEN {
	my ($self, $mode, $file) = @_;

	undef $!;

	($mode, $file) = $mode =~ m{^([<>]?)(.*)$}s
		unless $file;

	$mode ||= '<';

	$mode = '<' if $mode eq 'r';
	$mode = '>' if $mode eq 'a' or $mode eq 'w';

	die 'Unsupported mode'
		unless $mode eq '<' or $mode eq '>';

	$self->CLOSE()
		unless $self->{'closed'};

	$self->{'length'}   = 0;
	$self->{'position'} = 0;
	$self->{'buffer'}   = '';

	delete $self->{'offset'};
	delete $self->{'revision'};
	delete $self->{'upload_id'};
	delete $self->{'meta'};
	delete $self->{'eof'};

	$self->{'path'} = $file
		or die 'Path required';

	return 0
		if $mode eq '<' and not $self->__meta__();

	$self->{'mode'}   = $mode;
	$self->{'closed'} = 0;

	return 1;
} # OPEN

sub EOF {
	my ($self) = @_;

	die 'Eof is not supported on this handle'
		if $self->{'mode'} ne '<';

	return $self->{'position'} >= $self->{'length'};
} # EOF

sub BINMODE { 1 }

sub __headers__ {
	return [
		'Authorization',
		$_[0]->{'oauth2'}?
			sprintf $header2, $_[0]->{'access_token'}:
			sprintf $header1, @{ $_[0] }{qw{ app_key access_token app_secret access_secret }},
	];
}

sub __flush__ {
	my ($self) = @_;
	my $furl = $self->{'furl'};
	my $url;

	$url  = 'https://';
	$url .= join '/', $hosts->{'content'}, $version;

	$url .= join '/', '/commit_chunked_upload', $self->{'root'}, $self->{'path'}
		if $self->{'closed'};

	$url .= '/chunked_upload'
		unless $self->{'closed'};

	$url .= '?';

	$url .= join '=', 'upload_id', $self->{'upload_id'}
		if $self->{'upload_id'};

	$url .= '&'
		if $self->{'upload_id'};

	$url .= join '=', 'offset', $self->{'offset'} || 0
		unless $self->{'closed'};

	my $response;

	unless ($self->{'closed'}) {
		use bytes;

		my $buffer = substr $self->{'buffer'}, 0, $self->{'chunk'}, '';
		my $length = length $buffer;

		$self->{'length'} -= $length;
		$self->{'offset'} += $length;

		$response = $furl->put($url, &__headers__, $buffer);
	} else {
		$response = $furl->post($url, &__headers__);
	}

	return $self->__error__($response)
		if $response->code != 200;

	$self->{'meta'} = from_json($response->content())
		if $self->{'closed'};

	unless ($self->{'upload_id'}) {
		$response = from_json($response->content());
		$self->{'upload_id'} = $response->{'upload_id'};
	}

	return 1;
} # __flush__

sub __meta__ {
	my ($self) = @_;
	my ($url, $meta);

	my $furl = $self->{'furl'};

	$url  = 'https://';
	$url .= join '/', $hosts->{'api'}, $version;
	$url .= join '/', '/metadata', $self->{'root'}, $self->{'path'};

	$url .= '?hash='. delete $self->{'hash'}
		if $self->{'hash'};

	my $response = $furl->get($url, &__headers__);

	my $code = $response->code();

	if ($code == 200) {
		$meta = $self->{'meta'} = from_json($response->content());

		# XXX: Dropbox returns metadata for recently deleted files
		if ($meta->{'is_deleted'}) {
			$! = ENOENT;
			return 0;
		}
	} elsif ($code != 304) {
		return $self->__error__($response);
	}

	if ($meta->{'is_dir'}) {
		$! = EISDIR;
		return 0;
	}

	$self->{'revision'} = $meta->{'rev'};
	$self->{'length'}   = $meta->{'bytes'};

	return 1;
} # __meta__

sub __fileops__ {
	my ($type, $handle, $source, $target) = @_;

	my $self = *$handle{'HASH'};
	my $furl = $self->{'furl'};
	my ($url, @arguments);

	$url  = 'https://';
	$url .= join '/', $hosts->{'api'}, $version;
	$url .= join '/', '/fileops', $type;

	if ($type eq 'move' or $type eq 'copy') {
		@arguments = (
			from_path => $source,
			to_path   => $target,
		);
	} else {
		@arguments = (
			path => $source,
		);
	}

	push @arguments, root => $self->{'root'};

	my $response = $furl->post($url, $self->__headers__(), \@arguments);

	return $self->__error__($response)
		if $response->code != 200;

	$self->{'meta'} = from_json($response->content());

	return 1;
} # __fileops__

sub __error__ {
	my ($self, $response) = @_;
	my $code = $response->code();

	if ($code == 400) {
		$! = EINVAL;
	}

	elsif ($code == 401 or $code == 403) {
		$! = EACCES;
	}

	elsif ($code == 404) {
		$! = ENOENT;
		return 0;
	}

	elsif ($code == 406) {
		$! = EPERM;
		return 0;
	}

	elsif ($code == 500 and $response->content() =~ m{\A(?:Cannot|Failed)}) {
		$! = ECANCELED;
	}

	elsif ($code == 503) {
		$self->{'meta'} = { retry => $response->header('Retry-After') };

		$! = EAGAIN;
	}

	elsif ($code == 507) {
		$! = EFBIG;
	}

	else {
		die join ' ', $code, $response->decoded_content();
	}

	return 0;
} # __error__

sub contents ($;$$) {
	my ($handle, $path, $hash) = @_;

	die 'GLOB reference expected'
		unless ref $handle eq 'GLOB';

	*$handle->{'hash'} = $hash
		if $hash;

	if (open $handle, '<', $path || '/' or $! != EISDIR) {
		delete *$handle->{'meta'};
		return;
	}

	undef $!;
	return @{ *$handle->{'meta'}{'contents'} };
} # contents

sub putfile ($$$) {
	my ($handle, $path, $data) = @_;

	die 'GLOB reference expected'
		unless ref $handle eq 'GLOB';

	close $handle or return 0;

	my $self = *$handle{'HASH'};
	my $furl = $self->{'furl'};
	my ($url, $length);

	$url  = 'https://';
	$url .= join '/', $hosts->{'content'}, $version;
	$url .= join '/', '/files_put', $self->{'root'}, $path;

	{
		use bytes;
		$length = length $data;
	}

	my $response = $furl->put($url, $self->__headers__(), $data);

	return $self->__error__($response)
		if $response->code != 200;

	$self->{'path'} = $path;
	$self->{'meta'} = from_json($response->content());

	return 1;
} # putfile

sub movefile    ($$$) { __fileops__('move', @_) }
sub copyfile    ($$$) { __fileops__('copy', @_) }
sub deletefile   ($$) { __fileops__('delete', @_) }
sub createfolder ($$) { __fileops__('create_folder', @_) }

sub metadata ($) {
	my ($handle) = @_;

	die 'GLOB reference expected'
		unless ref $handle eq 'GLOB';

	my $self = *$handle{'HASH'};

	die 'Meta is unavailable for incomplete upload'
		if $self->{'mode'} eq '>';

	return $self->{'meta'};
} # metadata

=head1 NAME

File::Dropbox - Convenient and fast Dropbox API abstraction

=head1 SYNOPSIS

    use File::Dropbox;
    use Fcntl;

    # Application credentials
    my %app = (
        oauth2        => 1,
        access_token  => $access_token,
    );

    my $dropbox = File::Dropbox->new(%app);

    # Open file for writing
    open $dropbox, '>', 'example' or die $!;

    while (<>) {
        # Upload data using 4MB chunks
        print $dropbox $_;
    }

    # Commit upload (optional, close will be called on reopen)
    close $dropbox or die $!;

    # Open for reading
    open $dropbox, '<', 'example' or die $!;

    # Download and print to STDOUT
    # Buffered, default buffer size is 4MB
    print while <$dropbox>;

    # Reset file position
    seek $dropbox, 0, Fcntl::SEEK_SET;

    # Get first character (unbuffered)
    say getc $dropbox;

    close $dropbox;

=head1 DESCRIPTION

C<File::Dropbox> provides high-level Dropbox API abstraction based on L<Tie::Handle>. Code required to get C<access_token> and
C<access_secret> for signed OAuth 1.0 requests or C<access_token> for OAuth 2.0 requests is not included in this module.
To get C<app_key> and C<app_secret> you need to register your application with Dropbox.

At this moment Dropbox API is not fully supported, C<File::Dropbox> covers file read/write and directory listing methods. If you need full
API support take look at L<WebService::Dropbox>. C<File::Dropbox> main purpose is not 100% API coverage,
but simple and high-performance file operations.

Due to API limitations and design you can not do read and write operations on one file at the same time. Therefore handle can be in read-only
or write-only state, depending on last call to L<open|perlfunc/open>. Supported functions for read-only state are: L<open|perlfunc/open>,
L<close|perlfunc/close>, L<seek|perlfunc/seek>, L<tell|perlfunc/tell>, L<readline|perlfunc/readline>, L<read|perlfunc/read>,
L<sysread|perlfunc/sysread>, L<getc|perlfunc/getc>, L<eof|perlfunc/eof>. For write-only state: L<open|perlfunc/open>, L<close|perlfunc/close>,
L<syswrite|perlfunc/syswrite>, L<print|perlfunc/print>, L<printf|perlfunc/printf>, L<say|perlfunc/say>.

All API requests are done using L<Furl> module. For more accurate timeouts L<Net::DNS::Lite> is used, as described in L<Furl::HTTP>. Furl settings
can be overriden using C<furlopts>.

=head1 METHODS

=head2 new

    my $dropbox = File::Dropbox->new(
        access_secret => $access_secret,
        access_token  => $access_token,
        app_secret    => $app_secret,
        app_key       => $app_key,
        chunk         => 8 * 1024 * 1024,
        root          => 'dropbox',
        furlopts      => {
            timeout => 20
        }
    );

    my $dropbox = File::Dropbox->new(
        access_token => $access_token,
        oauth2       => 1
    );

Constructor, takes key-value pairs list

=over

=item access_secret

OAuth 1.0 access secret

=item access_token

OAuth 1.0 access token or OAuth 2.0 access token

=item app_secret

OAuth 1.0 app secret

=item app_key

OAuth 1.0 app key

=item oauth2

OAuth 2.0 switch, defaults to false.

=item chunk

Upload chunk size in bytes. Also buffer size for C<readline>. Optional. Defaults to 4MB.

=item root

Access type, C<sandbox> for app-folder only access and C<dropbox> for full access.

=item furlopts

Parameter hash, passed to L<Furl> constructor directly. Default options

    timeout   => 10,
    inet_aton => \&Net::DNS::Lite::inet_aton,
    ssl_opts  => {
        SSL_verify_mode => SSL_VERIFY_PEER(),
    }

=back

=head1 FUNCTIONS

All functions are not exported by default but can be exported on demand.

    use File::Dropbox qw{ contents metadata putfile };

First argument for all functions should be GLOB reference, returned by L</new>.

=head2 contents

Arguments: $dropbox [, $path]

Function returns list of hashrefs representing directory content. Hash fields described in L<Dropbox API
docs|https://www.dropbox.com/developers/core/docs#metadata>. C<$path> defaults to C</>. If there is
unfinished chunked upload on handle, it will be commited.

    foreach my $file (contents($dropbox, '/data')) {
        next if $file->{'is_dir'};
        say $file->{'path'}, ' - ', $file->{'bytes'};
    }

=head2 metadata

Arguments: $dropbox

Function returns stored metadata for read-only handle, closed write handle or after
call to L</contents> or L</putfile>.

    open $dropbox, '<', '/data/2013.dat' or die $!;

    my $meta = metadata($dropbox);

    if ($meta->{'bytes'} > 1024) {
        # Do something
    }

=head2 putfile

Arguments: $dropbox, $path, $data

Function is useful for uploading small files (up to 150MB possible) in one request (at least
two API requests required for chunked upload, used in open-write-close sequence). If there is
unfinished chunked upload on handle, it will be commited.

    local $/;
    open my $data, '<', '2012.dat' or die $!;

    putfile($dropbox, '/data/2012.dat', <$data>) or die $!;

    say 'Uploaded ', metadata($dropbox)->{'bytes'}, ' bytes';

    close $data;

=head2 copyfile

Arguments: $dropbox, $source, $target

Function copies file or directory from one location to another. Metadata for copy
can be accessed using L</metadata> function.

    copyfile($dropbox, '/data/2012.dat', '/data/2012.dat.bak') or die $!;

    say 'Created backup with revision ', metadata($dropbox)->{'revision'};

=head2 movefile

Arguments: $dropbox, $source, $target

Function moves file or directory from one location to another. Metadata for moved file
can be accessed using L</metadata> function.

    movefile($dropbox, '/data/2012.dat', '/data/2012.dat.bak') or die $!;

    say 'Created backup with size ', metadata($dropbox)->{'size'};

=head2 deletefile

Arguments: $dropbox, $path

Function deletes file or folder at specified path. Metadata for deleted item
is accessible via L</metadata> function.

    deletefile($dropbox, '/data/2012.dat.bak') or die $!;

    say 'Deleted backup with last modification ', metadata($dropbox)->{'modification'};

=head2 createfolder

Arguments: $dropbox, $path

Function creates folder at specified path. Metadata for created folder
is accessible via L</metadata> function.

    createfolder($dropbox, '/data/backups') or die $!;

    say 'Created folder at path ', metadata($dropbox)->{'path'};

=head1 SEE ALSO

L<Furl>, L<Furl::HTTP>, L<WebService::Dropbox>, L<Dropbox API|https://www.dropbox.com/developers/core/docs>

=head1 AUTHOR

Alexander Nazarov <nfokz@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2016 Alexander Nazarov

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
