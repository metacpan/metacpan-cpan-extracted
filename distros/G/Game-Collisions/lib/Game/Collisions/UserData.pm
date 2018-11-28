# Copyright (c) 2018  Timm Murray
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
package Game::Collisions::UserData;
$Game::Collisions::UserData::VERSION = '0.3';
use strict;
use warnings;


sub on_aabb_move
{
    # Allow subclass to override
}


1;
__END__


=head1 NAME

  Game::Collisions::UserData - Role for picking up movement to the AABB

=head1 SYNOPSIS

    package MyUserData;
    use base 'Game::Collisions::UserData';

    sub new { ... }

    sub on_aabb_move
    {
        my ($self, $args) = @_;
        my $add_x = $args->{add_x};
        my $add_y = $args->{add_y};
        ...
    }


    package main;
    my $user_data = MyUserData->new;
    my $collide = Game::Collisions->new;
    my $box = $collide->make_aabb({
        x => 0,
        y => 0,
        length => 1,
        height => 1,
        user_data => $user_data,
    });

    # MyUserData instance is called from here
    $box->move({
        add_x => 1,
        add_y => 3,
    });

=head1 DESCRIPTION

Set an instance of this to the C<user_data> on an AABB, and it will have its 
C<on_aabb_move()> method called right after any movement.

=head1 OVERRIDABLE METHODS

=head2 on_aabb_move

    sub on_aabb_move
    {
        my ($self, $args) = @_;
        my $add_x = $args->{add_x};
        my $add_y = $args->{add_y};
        ...
    }
 
Is passed the C<add_x> and C<add_y> parameters that were passed when the AABB
moved.

=cut
