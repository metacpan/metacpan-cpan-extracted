# Copyright (c) 2014  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
package GStreamer1;
$GStreamer1::VERSION = '0.003';
use v5.12;
use warnings;
use Glib::Object::Introspection;

# ABSTRACT: Bindings for GStreamer 1.0, the open source multimedia framework

BEGIN {
    foreach my $name ('', (
        #'Allocators',
        'App',
        #'Audio',
        'Base',
        #'Check',
        'Controller',
        #'Fft',
        #'InsertBin',
        #'Mpegts',
        #'Net',
        #'Pbutils',
        #'Riff',
        #'Rtp',
        #'Rtsp',
        #'Sdp',
        #'Tag',
        #'Video',
    )) {
        my $basename = 'Gst' . $name;
        my $pkg      = $name
            ? 'GStreamer1::' . $name
            : 'GStreamer1';
        Glib::Object::Introspection->setup(
            basename => $basename,
            version  => '1.0',
            package  => $pkg,
        );
    }
}

use GStreamer1::Caps::Simple;

1;
__END__


=encoding utf8

=head1 NAME

  GStreamer1 - Bindings for GStreamer 1.0, the open source multimedia framework

=head1 SYNOPSIS

    use GStreamer1;

    GStreamer1::init([ $0, @ARGV ]);
    my $pipeline = GStreamer1::parse_launch( "playbin uri=$URI" );

    $pipeline->set_state( "playing" );

    my $bus = $pipeline->get_bus;
    my $msg = $bus->timed_pop_filtered( GStreamer1::CLOCK_TIME_NONE,
        [ 'error', 'eos' ]);

    $pipeline->set_state( "null" );

=head1 DESCRIPTION

GStreamer1 implements a framework that allows for processing and encoding of 
multimedia sources in a manner similar to a shell pipeline.

Because it's introspection-based, most of the classes follow directly from the 
C API.  Therefore, most of the documentation is by example rather than 
a full breakdown of the class structure.

=head1 PORTING FROM GStreamer

If you're porting from the original GStreamer module, here are some things 
to keep in mind.

=head2 ElementFactory

The original GStreamer had a version of C<< ElementFactory->make() >> which 
could be called with a list of gst plugins and associated names.  GStreamer1 
may add a similar method in the future.  For now, the bindings directly follow 
from the C interface, so they take only one at a time.

Example:

    my $rpi        = GStreamer1::ElementFactory::make( rpicamsrc => 'and_who' );
    my $h264parse  = GStreamer1::ElementFactory::make( h264parse => 'are_you' );
    my $capsfilter = GStreamer1::ElementFactory::make(
        capsfilter => 'the_proud_lord_said' );
    my $avdec_h264 = GStreamer1::ElementFactory::make(
        avdec_h264 => 'that_i_should_bow_so_low' );
    my $jpegenc    = GStreamer1::ElementFactory::make( jpegenc => 'only_a_cat' );
    my $fakesink   = GStreamer1::ElementFactory::make(
        fakesink => 'of_a_different_coat' );

=head2 Adding/linking

The original GStreamer added methods for C<< Pipeline->add() >> and 
C<< Element->link() >> that could take lists of objects.  GStreamer1 may add 
similar methods in the future.  For now, the bindings directly follow from the 
C interface, so they take only one object at a time.

Example:

    my @link = ( $rpi, $h264parse, $capsfilter, $avdec_h264, $jpegenc, $fakesink );
    $pipeline->add( $_ ) for @link;
    foreach my $i (0 .. $#link) {
        last if ! exists $link[$i+1];
        my $this = $link[$i];
        my $next = $link[$i+1];
        $this->link( $next );
    }

=head1 EXAMPLES

See the C<examples/> directory in the distribution.

=head1 SEE ALSO

L<GStreamer> - Perl bindings to the old 0.10 version of GStreamer

L<http://gstreamer.freedesktop.org/>

=head1 SPECIAL THANKS

To Torsten Schönfeld for pointing me in the right direction on creating 
this module.

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
