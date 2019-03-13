package HTTP::Tiny::FileProtocol;
$HTTP::Tiny::FileProtocol::VERSION = '0.06';
# ABSTRACT: Add support for file:// protocol to HTTP::Tiny

use strict;
use warnings;

use HTTP::Tiny;
use File::Basename;
use LWP::MediaTypes;
use Carp;

no warnings 'redefine';

my $orig        = *HTTP::Tiny::get{CODE};
my $orig_mirror = *HTTP::Tiny::mirror{CODE};

*HTTP::Tiny::get = sub {
    my ($self, $url, $args) = @_;

    @_ == 2 || (@_ == 3 && ref $args eq 'HASH')
        or croak(q/Usage: $http->get(URL, [HASHREF])/ . "\n");

    if ( $url !~ m{\Afile://} ) {
        return $self->$orig( $url, $args || {});
    }

    my $success;
    my $status       = 599;
    my $reason       = 'Internal Exception';
    my $content      = '';
    my $content_type = 'text/plain';

    (my $path = $url) =~ s{\Afile://}{};

    if ( !-e $path ) {
        $status = 404;
        $reason = 'File Not Found';
        return _build_response( $url, $success, $status, $reason, $content, $content_type );
    }
    elsif ( !-r $path ) {
        $status = 403;
        $reason = 'Permission Denied';
        return _build_response( $url, $success, $status, $reason, $content, $content_type );
    }

    my($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$filesize,
       $atime,$mtime,$ctime,$blksize,$blocks)
            = stat($path);

    $status = 200;
    $success = 1;

    {
        if ( open my $fh, '<', $path ) {
            local $/;
            binmode $fh;

            $content = <$fh>;
            close $fh;

            $content_type = LWP::MediaTypes::guess_media_type( $path );
        }
        else {
            $status = 500;
            $reason = 'Internal Server Error';
            return _build_response( $url, $success, $status, $reason, $content, $content_type );
        }
    }

    return _build_response( $url, $success, $status, $reason, $content, $content_type );
};

*HTTP::Tiny::mirror = sub {
    my ($self, $url, $file, $args) = @_;

    @_ == 3 || (@_ == 4 && ref $args eq 'HASH')
        or croak(q/Usage: $http->mirror(URL, FILE, [HASHREF])/ . "\n");

    if ( $url !~ m{\Afile://} ) {
        return $self->$orig_mirror( $url, $file, $args || {});
    }

    my $tempfile = $file . int(rand(2**31));

    require Fcntl;
    sysopen my $fh, $tempfile, Fcntl::O_CREAT()|Fcntl::O_EXCL()|Fcntl::O_WRONLY()
        or croak(qq/Error: Could not create temporary file $tempfile for downloading: $!\n/);
    binmode $fh;

    my $response = $self->get( $url, $args || {} );

    if ( $response->{success} ) {
        print {$fh} $response->{content};

        rename $tempfile, $file
            or croak(qq/Error replacing $file with $tempfile: $!\n/);
    }

    close $fh
        or croak(qq/Error: Caught error closing temporary file $tempfile: $!\n/);

    unlink $tempfile;
    return $response;
};

sub _build_response {
    my ($url, $success, $status, $reason, $content, $content_type) = @_;

    my $bytes;
    {
        use bytes;
        $bytes = length $content;
    }

    my $response = {
        url     => $url,
        success => $success,
        status  => $status,
        ( !$success ? (reason  => $reason) : () ),
        content => $content // '',
        headers => {
            'content-type'   => $content_type,
            'content-length' => $bytes // 0,
        },
    };

    return $response;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::FileProtocol - Add support for file:// protocol to HTTP::Tiny

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use HTTP::Tiny::FileProtocol;
  
    my $http = HTTP::Tiny->new;
  
    my $response        = $http->get( 'file:///tmp/data.txt' );
    my $mirror_response = $http->get( 'file:///tmp/data.txt', 'data.txt' );

will return

    {
        success => 1,
        status  => 200,
        content => $content_of_file
        headers => {
            content_type   => 'text/plain',
            content_length => $length_of_content,
        },
    }

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
