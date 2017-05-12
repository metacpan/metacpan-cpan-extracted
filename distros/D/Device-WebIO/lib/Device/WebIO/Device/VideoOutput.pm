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
package Device::WebIO::Device::VideoOutput;
$Device::WebIO::Device::VideoOutput::VERSION = '0.010';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';

requires 'vid_channels';
requires 'vid_height';
requires 'vid_width';
requires 'vid_fps';
requires 'vid_kbps';
requires 'vid_set_height';
requires 'vid_set_width';
requires 'vid_set_fps';
requires 'vid_set_kbps';
requires 'vid_allowed_content_types';
requires 'vid_stream';

1;
__END__


=head1 NAME

  Device::WebIO::Device::VideoOutput - Role for video

=head1 REQUIRED METHODS

=head2 vid_channels

    vid_channels();

Return the number of video channels.

=head2 vid_height

    vid_height( $channel );

Return the height of the video for the given channel.

=head2 vid_width

    vid_width( $channel );

Return the width of the video for the given channel.

=head2 vid_fps

    vid_fps( $channel );

Return the framerate of the video for the given channel.

=head2 vid_kbps

    vid_kbps( $channel );

Return the bitrate of the video for the given channel.

=head2 vid_set_width

    vid_set_width( $channel, $width );

Set the width of the video for the given channel.

=head2 vid_set_height

    vid_set_height( $channel, $height );

Set the height of the video for the given channel.

=head2 vid_set_fps

    vid_set_fps( $channel, $fps );

Set the framerate of the video for the given channel.

=head2 vid_set_kbps

    vid_set_kbps( $channel, $kbps );

Set the bitrate of the video for the given channel.

=head2 vid_allowed_content_types

    vid_allowed_content_types( $channel );

Return a list of supported MIME types by the given channel.

=head2 vid_stream

    vid_stream( $channel, $type );

Return a filehandle for reading the video stream for the given channel.  
C<$type> must be one of the types returned by C<vid_allowed_content_types()>.

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
