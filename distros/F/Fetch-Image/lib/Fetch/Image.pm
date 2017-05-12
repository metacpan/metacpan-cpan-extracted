package Fetch::Image;
use strict;
use warnings;

use LWP::UserAgent::Paranoid;
use Data::Validate::Image;
use Data::Validate::URI qw/is_web_uri/;
use File::Temp;
use Exception::Simple;
use URI;

our $VERSION = '1.000000';
$VERSION = eval $VERSION;

sub new{
    my ( $invocant, $config ) = @_;

    my $class = ref( $invocant ) || $invocant;
    my $self = {};
    bless( $self, $class );

    $self->{'image_validator'} = Data::Validate::Image->new;

    $self->{'config'} = $config;

    # setup some defaults
    if ( !defined($self->{'config'}->{'max_filesize'}) ){
        $self->{'config'}->{'max_filesize'} = 524_288;
    }

    # default allowed image types if none defined
    if ( !defined($self->{'config'}->{'allowed_types'}) ){
        $self->{'config'}->{'allowed_types'} = {
            'image/png' => 1,
            'image/jpg' => 1,
            'image/jpeg' => 1,
            'image/pjpeg' => 1,
            'image/bmp' => 1,
            'image/gif' => 1,
        };
    }

    return $self;
}

sub fetch{
    my ( $self, $url ) = @_;

    my $uri = URI->new( $url );
    $url = $uri->as_string;

    if ( !defined( $url ) ){
        Exception::Simple->throw("no url");
    } elsif ( !defined( is_web_uri( $url ) ) ){
        Exception::Simple->throw("invalid url");
    }

    my $ua = $self->_setup_ua( $url );

    my $head = $self->_head( $ua, $url );
    return $self->_save( $ua, $url )
        || Exception::Simple->throw("generic error");
}

sub _setup_ua{
    my ( $self, $url ) = @_;

    my $ua = LWP::UserAgent::Paranoid->new;

    if ( defined( $self->{'config'}->{'user_agent'} ) ){
        $ua->agent( $self->{'config'}->{'user_agent'} );
    }

    if ( defined( $self->{'config'}->{'timeout'} ) ){
        $ua->timeout( $self->{'config'}->{'timeout'} );
    }
    $ua->cookie_jar( {} ); #don't care for cookies

    $ua->default_header( 'Referer' => $url ); #naughty, maybe, but will get around 99% of anti-leach protection :D

    return $ua;
}

# returns a HTTP::Response for a HTTP HEAD request
sub _head{
    my ( $self, $ua, $url ) = @_;

    my $head = $ua->head( $url );

    $head->is_error && Exception::Simple->throw("transfer error");

    exists( $self->{'config'}->{'allowed_types'}->{ $head->header('content-type') } )
        || Exception::Simple->throw("invalid content-type");

    if (
        $head->header('content-length')
        && ( $head->header('content-length') > $self->{'config'}->{'max_filesize'} )
    ){
    #file too big
        Exception::Simple->throw("filesize exceeded");
    }

    return $head;
}

# returns a File::Temp copy of the requested url
sub _save{
    my ( $self, $ua, $url ) = @_;

    my $response = $ua->get( $url )
        || Exception::Simple->throw("download Failed");

    my $temp_file = File::Temp->new
        || Exception::Simple->throw("temp file save failed");
    $temp_file->print( $response->content );
    $temp_file->close;

    my $image_info = $self->{'image_validator'}->validate($temp_file->filename);

    if ( !$image_info ){
        $temp_file->DESTROY;
        Exception::Simple->throw("not an image");
    };

    $image_info->{'temp_file'} = $temp_file;
    return $image_info;
}

1;

=head1 NAME

Fetch::Image - fetch a remote image into a L<File::Temp>

=head1 SYNOPSIS

    use Fetch::Image;
    use Try::Tiny; #or just use eval {}, it's all good

    my $fetcher = Fetch::Image->new( {
        'max_filesize' => 524_288,
        'user_agent' => 'mozilla firefox or something...',
        'allowed_types' => {
            'image/png' => 1,
            'image/jpg' => 1,
            'image/jpeg' => 1,
            'image/pjpeg' => 1,
            'image/bmp' => 1,
            'image/gif' => 1,
        },
    } );

    my $image_info = try{
        $fetcher->fetch('http://www.google.com/logos/2011/trevithick11-hp.jpg');
    } catch {
        #error gets caught here...
        warn $_; #this
        warn $_->error; #or this
    };

    use Data::Dumper;
    warn Dumper( $image_info );

    #the image is now a Temp::File in $image_info->{'temp_file'};

=head1 DESCRIPTION

Class that will fetch a remote image and return a hash of the image_info and the L<File::Temp>

=head1 METHODS

=head2 new

takes 3 options

    my $fetcher = Fetch::Image->new( {
        'max_filesize' => 524_288, #default value (bytes)
        'user_agent' => 'mozilla firefox or something...',
        'allowed_types' => {  #allowed content types (default all of these)
            'image/png' => 1,
            'image/jpg' => 1,
            'image/jpeg' => 1,
            'image/pjpeg' => 1,
            'image/bmp' => 1,
            'image/gif' => 1,
        },
    } );

=head2 fetch

takes 1 argument, the url of the image to fetch

returns a hash of the image info, from L<Data::Validate::Image>, with an extra property, 'temp_file' which is the L<File::Temp>

=head1 AUTHORS

Mark Ellis E<lt>markellis@cpan.orgE<gt>

=head1 SEE ALSO

L<Data::Validate::Image>, L<File::Temp>

=head1 LICENSE

Copyright 2014 by Mark Ellis E<lt>markellis@cpan.orgE<gt>

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
