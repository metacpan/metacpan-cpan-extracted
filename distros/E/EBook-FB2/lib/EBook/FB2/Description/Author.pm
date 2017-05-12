# Copyright (c) 2009, 2010 Oleksandr Tymoshenko <gonzo@bluezbox.com>
# All rights reserved.

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.

# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.

package EBook::FB2::Description::Author;
use Moose;

has [qw/first_name middle_name last_name nickname id/] => (
    isa     => 'Str',
    is      => 'rw'
);

has _home_pages => ( 
    isa     => 'ArrayRef',
    is => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        home_pages      => 'elements',
        add_home_page   => 'push',
    },
);

has _emails => ( 
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        emails      => 'elements',
        add_email   => 'push',
    },
);

sub load
{
    my ($self, $node) = @_;

    my @nodes = $node->findnodes('first-name');
    if (@nodes) {
        $self->first_name($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('middle-name');
    if (@nodes) {
        $self->middle_name($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('last-name');
    if (@nodes) {
        $self->last_name($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('nickname');
    if (@nodes) {
        $self->nickname($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('home-page');
    foreach my $n (@nodes) {
        $self->add_home_page($n->string_value());
    }

    @nodes = $node->findnodes('email');
    foreach my $n (@nodes) {
        $self->add_email($n->string_value());
    }

    @nodes = $node->findnodes('id');
    if (@nodes) {
        $self->id($nodes[0]->string_value());
    }
}

sub to_str
{
    my $self = shift;
    my $name = $self->first_name;
    $name .= ' ' . $self->middle_name if defined($self->middle_name);
    if ($name ne '') {
        $name .= ' "' . $self->nickname . '"' 
            if defined($self->nickname);
    }
    else {
        $name = $self->nickname if defined($self->nickname);
    }

    $name .= ' ' . $self->last_name if defined($self->last_name);

    return $name;
}

1;

__END__
=head1 NAME

EBook::FB2::Description::Author

=head1 SYNOPSIS

EBook::FB2::Description::Author - person description: author/translator

=head1 SUBROUTINES/METHODS

=over 4

=item emails()

Returns list of person's email addresses

=item first_name()

Returns persons's first name

=item home_pages()

Returns persons's homepage

=item id()

Returns persons's identifier assigned by the library

=item last_name()

TODO: document last_name()

Returns person's last name

=item middle_name()

Returns person's middle name

=item nickname()

Returns person's nickname

=item to_str()

Returns string representation



=back

=head1 AUTHOR

Oleksandr Tymoshenko, E<lt>gonzo@bluezbox.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to  E<lt>gonzo@bluezbox.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2009, 2010 Oleksandr Tymoshenko.

L<http://bluezbox.com>

This module is free software; you can redistribute it and/or
modify it under the terms of the BSD license. See the F<LICENSE> file
included with this distribution.
