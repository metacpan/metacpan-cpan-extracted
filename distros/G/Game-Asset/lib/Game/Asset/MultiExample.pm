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
package Game::Asset::MultiExample;
$Game::Asset::MultiExample::VERSION = '0.6';
use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Game::Asset::PlainText;
use Game::Asset::Null;


use constant type => 'multi_example';

with 'Game::Asset::Multi';

has 'txt' => (
    is => 'ro',
    isa => 'Game::Asset::PlainText',
    writer => '_set_txt',
);
has 'null' => (
    is => 'ro',
    isa => 'Game::Asset::Null',
    writer => '_set_null',
);


sub content { $_[0]->_orig_content }

sub _process_content
{
    my ($self, $content) = @_;
    $self->_orig_content( $content );

    my $args = {
        name => $self->name,
        full_name => $self->full_name,
    };

    my $txt = Game::Asset::PlainText->new( $args );
    my $null = Game::Asset::Null->new( $args );
    $_->process_content( $content ) for $txt, $null;

    $self->_set_txt( $txt );
    $self->_set_null( $null );
    return;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

