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
package Device::WebIO::Device::StillImageOutput;
$Device::WebIO::Device::StillImageOutput::VERSION = '0.020';
use v5.12;
use Moo::Role;

with 'Device::WebIO::Device';

requires 'img_channels';
requires 'img_height';
requires 'img_width';
requires 'img_quality';
requires 'img_set_height';
requires 'img_set_width';
requires 'img_set_quality';
requires 'img_allowed_content_types';
requires 'img_stream';

1;
__END__


=head1 NAME

  Device::WebIO::Device::StillImageOutput - Role for still images

=head1 REQUIRED METHODS

=head2 img_channels

    img_channels();

Return the number of video channels.

=head2 img_height

    img_height( $channel );

Return the height of the video for the given channel.

=head2 img_width

    img_width( $channel );

Return the width of the video for the given channel.

=head2 img_quality

    img_quality( $channel );

Return the quality of the compression.  For JPEG, this would be 0 through 100.

=head2 img_set_width

    img_set_width( $channel, $width );

Set the width of the video for the given channel.

=head2 img_set_height

    img_set_height( $channel, $height );

Set the height of the video for the given channel.

=head2 img_set_quality

    img_set_quality( $channel, $quality );

Set the quality of compression.  For JPEG, this would be 0 through 100.

=head2 img_allowed_content_types

    img_allowed_content_types( $channel );

Return a list of supported MIME types by the given channel.

=head2 img_stream

    img_stream( $channel, $type );

Return a filehandle for reading the image stream for the given channel.  
C<$type> must be one of the types returned by C<img_allowed_content_types()>.

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
