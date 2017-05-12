package Device::WebIO::Dancer;
$Device::WebIO::Dancer::VERSION = '0.004';
# ABSTRACT: REST interface for Device::WebIO using Dancer
use v5.12;
use Dancer;
use Time::HiRes 'sleep';
use File::Spec;

use constant VID_READ_LENGTH => 4096;
use constant PULSE_TIME      => 0.1;


my ($webio, $default_name, $public_dir);

sub init
{
    my ($webio_ext, $default_name_ext, $public_dir_ext) = @_;
    $webio        = $webio_ext;
    $default_name = $default_name_ext;
    $public_dir   = $public_dir_ext;
    return 1;
}


get '/devices/:name/count' => sub {
    my $name  = params->{name};
    my $count = $webio->digital_input_pin_count( $name );
    return $count;
};

get '/devices/:name/:pin/integer' => sub {
    my ($name) = params->{name};
    my ($pin)  = params->{pin};
    my $int = $webio->digital_input_port( $name );
    return $int;
};

get '/devices/:name/:pin/value' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};

    my $in;
    if( $pin eq '*' ) {
        my $int = $webio->digital_input_port( $name );
        my @values = _int_to_array( $int,
            reverse(0 .. $webio->digital_input_pin_count( $name ) - 1) );
        $in = join ',', @values;
    }
    else {
        $in = $webio->digital_input( $name, $pin );
    }
    return $in;
};

get '/devices/:name/:pin/function' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};

    my $type = _get_io_type( $name, $pin );
    return $type;
};

post '/devices/:name/:pin/function/:func' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $func = uc params->{func};

    if( 'IN' eq $func ) {
        $webio->set_as_input( $name, $pin );
    }
    elsif( 'OUT' eq $func ) {
        $webio->set_as_output( $name, $pin );
    }
    else {
        # TODO
    }

    return '';
};

get '/devices/:name/:pin' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $pin_count = $webio->digital_input_pin_count( $name );
    my @pin_index_list = 0 .. ($pin_count - 1);

    my (@values, @type_values);
    foreach (@pin_index_list) {
        my $type = _get_io_type( $name, $_ );
        push @type_values, $type;

        my $int = ($type eq 'IN') ? $webio->digital_input( $name, $_ ) :
            ($type eq 'OUT') ? 0 :
            0;
        push @values, $int;
    }

    my $combined_types = join ',', reverse map {
        $values[$_] . ':' . $type_values[$_]
    } @pin_index_list;
    return $combined_types;
};

post '/devices/:name/:pin/value/:digit' => sub {
    my $name  = params->{name};
    my $pin   = params->{pin};
    my $digit = params->{digit};

    $webio->digital_output( $name, $pin, $digit );

    return '';
};

post '/devices/:name/:pin/integer/:value' => sub {
    my $name  = params->{name};
    my $pin   = params->{pin};
    my $value = params->{value};

    $webio->digital_output_port( $name, $value );

    return '';
};

get '/devices/:name/video/count' => sub {
    my $name = params->{name};
    my $val  = $webio->vid_channels( $name );
    return $val;
};

get '/devices/:name/video/:channel/resolution' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};

    my $width  = $webio->vid_width( $name, $channel );
    my $height = $webio->vid_height( $name, $channel );
    my $fps    = $webio->vid_fps( $name, $channel );

    return $width . 'x' . $height . 'p' . $fps;
};

post '/devices/:name/video/:channel/resolution/:width/:height/:framerate'
    => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $width   = params->{width};
    my $height  = params->{height};
    my $fps     = params->{framerate};

    $webio->vid_set_width( $name, $channel, $width );
    $webio->vid_set_height( $name, $channel, $height );
    $webio->vid_set_fps( $name, $channel, $fps );

    return '';
};

get '/devices/:name/video/:channel/kbps' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};

    my $bitrate = $webio->vid_kbps( $name, $channel );

    return $bitrate;
};

post '/devices/:name/video/:channel/kbps/:bitrate' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $bitrate = params->{bitrate};
    $webio->vid_set_kbps( $name, $channel, $bitrate );
    return '';
};

get '/devices/:name/video/:channel/allowed-content-types' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $allowed = $webio->vid_allowed_content_types( $name, $channel );
    return join( "\n", @$allowed );
};

get '/devices/:name/video/:channel/stream/:type1/:type2' => sub {
    my $name    = params->{name};
    my $channel = params->{channel};
    my $type1   = params->{type1};
    my $type2   = params->{type2};
    my $mime_type = $type1 . '/' . $type2;

    my $in_fh = $webio->vid_stream( $name, $channel, $mime_type );

    return send_file( '/etc/hosts',
        streaming    => 1,
        system_path  => 1,
        content_type => $mime_type,
        callbacks    => {
            around_content => sub {
                my ($writer, $chunk) = @_;

                my $buf;
                while( read( $in_fh, $buf, VID_READ_LENGTH ) ) {
                    $writer->write( $buf );
                }
                close $in_fh;
            }
        },
    );
};

get '/devices/:name/analog/count' => sub {
    my $name = params->{name};
    my $count = $webio->adc_count( $name );
    return $count;
};

get '/devices/:name/analog/maximum' => sub {
    # TODO deprecate this more explicitly (301 Moved Permanently?)
    my $name = params->{name};
    my $max = $webio->adc_max_int( $name, 0 );
    return $max;
};

get '/devices/:name/analog/:pin/maximum' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $max = $webio->adc_max_int( $name, $pin );
    return $max;
};

get '/devices/:name/analog/:pin/integer/vref' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_volt_ref( $name, $pin );
    return $value;
};

get '/devices/:name/analog/integer/vref' => sub {
    # TODO deprecate this more explicitly (301 Moved Permanently?)
    my $name = params->{name};
    my $value = $webio->adc_volt_ref( $name, 0 );
    return $value;
};

get '/devices/:name/analog/:pin/integer' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};

    my $value;
    if( $pin eq '*' ) {
        my @val = map {
            $webio->adc_input_int( $name, $_ ) // 0
        } 0 .. ($webio->adc_count( $name ) - 1);
        $value = join ',', @val;
    }
    else {
        $value = $webio->adc_input_int( $name, $pin );
    }
    return $value;
};

get '/devices/:name/analog/:pin/float' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_input_float( $name, $pin );
    return $value;
};

get '/devices/:name/analog/:pin/volt' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $value = $webio->adc_input_volts( $name, $pin );
    return $value;
};

get '/devices/:name/image/count' => sub {
    my $name = params->{name};
    my $value = $webio->img_channels( $name );
    return $value;
};

get '/devices/:name/image/:pin/resolution' => sub {
    my $name   = params->{name};
    my $pin    = params->{pin};
    my $width  = $webio->img_width( $name, $pin );
    my $height = $webio->img_height( $name, $pin );
    return $width . 'x' . $height;
};

post '/devices/:name/image/:pin/resolution/:width/:height' => sub {
    my $name   = params->{name};
    my $pin    = params->{pin};
    my $width  = params->{width};
    my $height = params->{height};
    $webio->img_set_width( $name, $pin, $width );
    $webio->img_set_height( $name, $pin, $height );
    return 1;
};

get '/devices/:name/image/:pin/allowed-content-types' => sub {
    my $name = params->{name};
    my $pin  = params->{pin};
    my $types = $webio->img_allowed_content_types( $name, $pin );
    return join( "\n", @$types );
};

get '/devices/:name/image/:pin/stream/:mime1/:mime2' => sub {
    my $name  = params->{name};
    my $pin   = params->{pin};
    my $mime1 = params->{mime1};
    my $mime2 = params->{mime2};
    my $mime  = "$mime1/$mime2";
    my $fh = $webio->img_stream( $name, $pin, $mime );

    local $/ = undef;
    my $buffer = <$fh>;
    close $fh;

    content_type $mime;
    return $buffer;
};

get '/devices/:name/sensor/temperature/c' => sub {
    my $name = params->{name};
    my $count = $webio->temp_celsius( $name );
    return $count;
};

get '/devices/:name/sensor/temperature/k' => sub {
    my $name = params->{name};
    my $count = $webio->temp_kelvins( $name );
    return $count;
};

get '/devices/:name/sensor/temperature/f' => sub {
    my $name = params->{name};
    my $count = $webio->temp_fahrenheit( $name );
    return $count;
};


get '/GPIO/:pin/function' => sub {
    my $pin  = params->{pin};

    my $type = lc _get_io_type( $default_name, $pin );
    return $type;
};

post '/GPIO/:pin/function/:func' => sub {
    my $pin  = params->{pin};
    my $func = uc params->{func};

    if( 'IN' eq $func ) {
        $webio->set_as_input( $default_name, $pin );
    }
    elsif( 'OUT' eq $func ) {
        $webio->set_as_output( $default_name, $pin );
    }
    else {
        # TODO
    }

    return '';
};

get '/GPIO/:pin/value' => sub {
    my $pin = params->{pin};
    my $in = $webio->digital_input( $default_name, $pin );
    return $in;
};

post '/GPIO/:pin/value/:value' => sub {
    my $pin   = params->{pin};
    my $value = params->{value};

    $webio->digital_output( $default_name, $pin, $value );

    return '';
};

post '/GPIO/:pin/pulse' => sub {
    my $pin   = params->{pin};

    $webio->digital_output( $default_name, $pin, 1 );
    sleep PULSE_TIME;
    $webio->digital_output( $default_name, $pin, 0 );

    return '';
};

post '/GPIO/:pin/sequence/:seq' => sub {
    my $pin = params->{pin};
    my $seq = params->{seq};
    my ($duration, $bits) = split /,/, $seq, 2;
    my @bits = split //, $bits;

    foreach my $value (@bits) {
        my $duration_ms = $duration / 1000;

        $webio->digital_output( $default_name, $pin, $value );
        sleep $duration_ms;
    }

    return '';
};


get '/map' => sub {
    return to_json( $webio->pin_desc( $default_name ) );
};

get qr{\A / \* }x => sub {
    return to_json( $webio->all_desc( $default_name ) );
};


get '/' => sub {
    return 'Hello, world!';
};

get '/app/*' => sub {
    my $params = shift;
    my ($file) = @{ params->{splat} };
    my $path   = File::Spec->catfile( $public_dir, 'app', $file );
    send_file( $path,
        system_path => 1,
    );
};



sub _int_to_array
{
    my ($int, @index_list) = @_;
    my @values = map {
        ($int >> $_) & 1
    } @index_list;
    return @values;
}

sub _get_io_type
{
    my ($name, $pin) = @_;
    # Ignore exceptions
    my $type = eval { $webio->is_set_input( $name, $pin ) } ? 'IN'
        : eval { $webio->is_set_output( $name, $pin ) }     ? 'OUT'
        : 'UNSET';
    warn "Caught exception while getting IO type for pin '$pin': $@\n" if $@;
    return $type;
}


1;
__END__


=head1 NAME
    
    Device::WebIO::Dancer - REST API on top of Device::WebIO

=head1 DESCRIPTION

Provides a REST-based interface for controlling C<Device::WebIO> over HTTP.  
The API is in line with the WebIOPi API (L<https://code.google.com/p/webiopi/>).

=head1 DEPLOYMENT

=head2 Apache2/mod_perl2

Set the root Location directive in your VirtualHost to point the PSGI 
script you want:

	<Location />
		SetHandler perl-script
		PerlResponseHandler Plack::Handler::Apache2
		PerlSetVar psgi_app /var/www/raspberrypi.psgi
	</Location>

Create the C<raspberrypi.psgi> file pointed to above:

    use Dancer;
    use Device::WebIO::Dancer;
    use Device::WebIO;
    use Device::WebIO::RaspberryPi;
    use Plack::Builder;

    my $webio = Device::WebIO->new;
    my $rpi = Device::WebIO::RaspberryPi->new;
    $webio->register( 'rpi', $rpi );

    Device::WebIO::Dancer::init( $webio, 'rpi' );
     
    builder {
        dance;
    };

If you would like to use the still image interface on the Raspberry Pi, add 
the user C<www-data> to the group C<video>.

Copy the C<public/> directory from the Device::WebIO::Dancer distribution 
into its own directory in your VirtualHost's docroot.  If you copied it to 
C<app/>, then add to your VirtualHost config:

	<Location /app>
		SetHandler None
	</Location>

This needs to come I<after> the "<Location />" section above.

If you're using C<Device::WebIO::RaspberryPi>, note that the underlying 
Wiring library needs to be init'd before the Apache startup drops its root
privileges.  To make sure you do this, create a C<mod_perl_config.pl> file in 
your Apache2 config dir:

    use Device::WebIO::RaspberryPi;
    my $rpi = Device::WebIO::RaspberryPi->new;
    1;

And run that from the Apache2 config with:

    PerlConfigRequire /etc/apache2/mod_perl_config.pl

Finally, load up the modules you need in C<mod_perl_post_config.pl>:

    use Device::WebIO;
    use Device::WebIO::RaspberryPi;
    use Device::WebIO::Dancer;
    1;

And call that with:

    PerlPostConfigRequire /etc/apache2/mod_perl_post_config.pl

At this point, you should be able to startup Apache.  Calling 
C<http://example.com/*> should get you a JSON dump of the pins.  Calling 
C<http://example.com/app/app/gpio-header/index.html> should get you a 
layout of the pins with their current values.

=head1 LICENSE

Copyright (c) 2014  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are 
permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, this list of 
      conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, this list of
      conditions and the following disclaimer in the documentation and/or other materials 
      provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS 
OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE 
COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, 
EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR 
TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, 
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

=cut
