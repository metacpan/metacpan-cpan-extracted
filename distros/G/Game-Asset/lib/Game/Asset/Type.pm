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
package Game::Asset::Type;
$Game::Asset::Type::VERSION = '0.3';
use strict;
use warnings;
use Moose::Role;


requires 'type';
requires '_process_content';

has 'name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'full_name' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);
has 'has_been_processed' => (
    traits => ['Bool'],
    is => 'ro',
    isa => 'Bool',
    handles => {
        '_set_has_been_processed' => 'set',
    },
);
has '_orig_content' => (
    is => 'rw',
    isa => 'Str',
);


sub process_content
{
    my ($self, $content) = @_;
    return if $self->has_been_processed;
    $self->_process_content( $content );
    $self->_set_has_been_processed;
    return;
}


1;
__END__


=head1 NAME

  Game::Asset::Type - Role for asset types

=head1 DESCRIPTION

Each file in the asset archive is represented by a class that does this role. 
Types are determined by L<Game::Asset> using the file extension.

=head1 PROVIDES

=head2 process_content

This is called with the full data. If it's the first time the data was passed, 
then it calls C<_process_content()> and sets C<has_been_processed()> to true.

=head2 name

The short name (without extension) of the asset.

=head2 full_name

The full name (with extension) of the asset.

=head2 has_been_processed

Boolean. If true, then the asset data has already been passed once to 
C<process_content()>.

=head2 _orig_content

The C<_process_content()> method should set this to the original, untouched 
data passed in.

=head1 REQUIRES

=head2 type

Returns the name of the type.

=head2 _process_content

Passed the untouched data so it can be processed.

=cut
