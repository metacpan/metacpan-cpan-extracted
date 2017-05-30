# Copyright (c) 2016  Timm Murray
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
package Game::Asset::SDLSound;
$Game::Asset::SDLSound::VERSION = '0.2';
# ABSTRACT: Load sound files out of Game::Asset files for playing in SDL
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use SDL ();
use SDL::Mixer ();
use SDL::Mixer::Music ();
use SDL::RWOps ();

use constant type => 'sound';

with 'Game::Asset::Type';

has '_content' => (
    is => 'rw',
);
has '_sound' => (
    is => 'rw',
    isa => 'Maybe[SDL::RWOps]',
);


sub play
{
    my ($self) = @_;
    my $content = $self->_content;
    my $rw = SDL::RWOps->new_const_mem( $content );

    my $music = SDL::Mixer::Music::load_MUS_RW( $rw );
    SDL::Mixer::Music::play_music( $music, 0 );
    return;
}

sub _process_content
{
    my ($self, $content) = @_;
    $self->_content( $content );
    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

  Game::Asset::SDLSound - Load sound files out of Game::Asset files for playing in SDL

=head1 SYNOPSIS

    my $asset = Game::Asset->new({
        file => 't_data/test.zip',
    });
    my $sound = $asset->get_by_name( 'test_wav' );

    my $sdl = Game::Asset::SDLSound::Manager->new;
    $sdl->init;
    $sound->play;
    while( $sdl->is_playing ) { }
    $sdl->finish;


    # In your index.yml for the Game::Asset archive, add:
    flac: Game::Asset::SDLSound
    mp3: Game::Asset::SDLSound
    ogg: Game::Asset::SDLSound
    wav: Game::Asset::SDLSound

=head1 DESCRIPTION

Loads sound files from a L<Game::Asset> archive for playing in SDL. Support 
is provided for FLAC, OGG, MP3, and WAV files. Note that which of these can 
be played will depend on how your SDL_Mixer library is compiled. For more 
information on supported formats, see L<SDL::Mixer>.

=head1 METHODS

=head2 play

Starts playing the sound. Before calling this, you will need to setup the 
SDL mixer environment. See L<Game::Asset::SDLSound::Manager> for more 
information.

=head1 SEE ALSO

=over 4

=item * L<SDL::Mixer>

=item * L<SDL::Mixer::Music>

=back

=head1 LICENSE

Copyright (c) 2016  Timm Murray
All rights reserved.

Redistribution and use in source and binary forms, with or without 
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright 
      notice, this list of conditions and the following disclaimer in the 
      documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.

=cut
