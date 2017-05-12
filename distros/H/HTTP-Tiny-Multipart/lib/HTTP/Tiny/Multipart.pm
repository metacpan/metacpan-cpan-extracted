package HTTP::Tiny::Multipart;

# ABSTRACT: Add post_multipart to HTTP::Tiny

use strict;
use warnings;

use HTTP::Tiny;
use File::Basename;
use Carp;
use MIME::Base64;

our $VERSION = 0.05;

sub _get_boundary {
    my ($headers, $content) = @_;
 
    # Generate and check boundary
    my $boundary;
    my $size = 1;

    while (1) {
        $boundary = encode_base64 join('', map chr(rand 256), 1 .. $size++ * 3);
        $boundary =~ s/\W/X/g;
        last unless grep{ $_ =~ m{$boundary} }@{$content};
    }
 
    # Add boundary to Content-Type header
    my $before = 'multipart/form-data';
    my $after  = '';
    if( defined $headers->{'content-type'} ) {
        if( $headers->{'content-type'} =~ m!^(.*multipart/[^;]+)(.*)$! ) {
            $before = $1;
            $after  = $2;
        }
    }

    $headers->{'content-type'} = "$before; boundary=$boundary$after";
 
    return "--$boundary\x0d\x0a";
}

sub _build_content {
    my ($data) = @_;

    my @params = ref $data eq 'HASH' ? %$data : @$data;
    @params % 2 == 0
        or Carp::croak("form data reference must have an even number of terms\n");
 
    my @terms;
    while( @params ) {
        my ($key, $value) = splice(@params, 0, 2);
        if ( ref $value eq 'ARRAY' ) {
            unshift @params, map { $key => $_ } @$value;
        }
        else {
            my $filename     = '';
            my $content      = $value;
            my $content_type = '';

            if ( ref $value and ref $value eq 'HASH' ) {
                if ( $value->{content} ) {
                    $content = $value->{content};
                }

                if ( $value->{filename} ) {
                    $filename = $value->{filename};
                }
                else {
                    $filename = $key;
                }

                $filename = '; filename="' . basename( $filename ) . '"';

                if ( $value->{content_type} ) {
                    $content_type = "\x0d\x0aContent-Type: " . $value->{content_type};
                }
            }

            push @terms, sprintf "Content-Disposition: form-data; name=\"%s\"%s%s\x0d\x0a\x0d\x0a%s\x0d\x0a",
                $key, 
                $filename,
                $content_type,
                $content;
        }
    }

    return \@terms;
}

no warnings 'redefine';

*HTTP::Tiny::post_multipart = sub {
    my ($self, $url, $data, $args) = @_;

    (@_ == 3 || @_ == 4 && ref $args eq 'HASH')
        or Carp::croak(q/Usage: $http->post_multipart(URL, DATAREF, [HASHREF])/ . "\n");

    (ref $data eq 'HASH' || ref $data eq 'ARRAY')
        or Carp::croak("form data must be a hash or array reference\n");
 
    my $headers = {};
    while ( my ($key, $value) = each %{$args->{headers} || {}} ) {
        $headers->{lc $key} = $value;
    }

    delete $args->{headers};

    my $content_parts = _build_content($data);
    my $boundary      = _get_boundary($headers, $content_parts);

    my $last_boundary = $boundary;
    substr $last_boundary, -2, 0, "--";
 
    return $self->request('POST', $url, {
            %$args,
            content => $boundary . join( $boundary, @{$content_parts}) . $last_boundary,
            headers => {
                %$headers,
            },
        }
    );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Tiny::Multipart - Add post_multipart to HTTP::Tiny

=head1 VERSION

version 0.05

=head1 SYNOPSIS

    use HTTP::Tiny;
    use HTTP::Tiny::Multipart;
  
    my $http = HTTP::Tiny->new;
  
    my $content = "This is a test";
  
    my $response = $http->post_multipart( 'http://localhost:3000/', { 
        file => {
            filename => 'test.txt',
            content  => $content,
        }
    } );

creates this request

  POST / HTTP/1.1
  Content-Length: 104
  User-Agent: HTTP-Tiny/0.025
  Content-Type: multipart/form-data; boundary=go7DX
  Connection: close
  Host: localhost:3000
  
  --go7DX
  Content-Disposition: form-data; name="file"; filename="test.txt"
  
  This is a test
  --go7DX--

And
    use HTTP::Tiny;
    use HTTP::Tiny::Multipart;

    my $http = HTTP::Tiny->new;
  
    my $content = "This is a test";
  
    my $response = $http->post_multipart( 'http://localhost:3000/', { 
        file => {
            filename => 'test.txt',
            content  => $content,
            content_type  => 'text/plain',
        },
        testfield => 'test'
    } );

creates

  POST / HTTP/1.1
  Content-Length: 104
  User-Agent: HTTP-Tiny/0.025
  Content-Type: multipart/form-data; boundary=go7DX
  Connection: close
  Host: localhost:3000
  
  --go7DX
  Content-Disposition: form-data; name="file"; filename="test.txt"
  Content-Type: text/plain
  
  This is a test
  --go7DX
  Content-Disposition: form-data; name="testfield"
  
  test
  --go7DX--

=head1 CONTRIBUTORS

=over 4

=item * Stephen Thirlwall

=back

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
