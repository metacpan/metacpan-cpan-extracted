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

package EBook::FB2::Description::PublishInfo;
use Moose;

use EBook::FB2::Description::Sequence;

has [qw/book_name publisher city year isbn/] => (isa => 'Str', is => 'rw');

has _sequences => ( 
    isa     => 'ArrayRef',
    is => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        sequences     => 'elements',
        add_sequence  => 'push',
    },
);

sub load
{
    my ($self, $node) = @_;

    my @nodes = $node->findnodes('book-name');
    if (@nodes) {
        $self->book_name($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('publisher');
    if (@nodes) {
        $self->publisher($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('city');
    if (@nodes) {
        $self->city($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('year');
    if (@nodes) {
        $self->year($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('isbn');
    if (@nodes) {
        $self->isbn($nodes[0]->string_value());
    }

    @nodes = $node->findnodes('sequence');
    foreach my $node (@nodes) {
        my $seq = EBook::FB2::Description::Sequence->new();
        $seq->load($node);
        $self->add_sequence($seq);
    }
}

1;

__END__
=head1 NAME

EBook::FB2::Description::PublishInfo

=head1 SYNOPSIS

    EBook::FB2::Description::PublishInfo - TODO

=head1 SUBROUTINES/METHODS

=over 4

=item book_name()

Returns publication name

=item city()

Returns city of publication

=item isbn()

Returns publication ISDN

=item publisher()

Returns publisher

=item sequences()

Sequences publication belongs to (reference to L<EBook::FB2::Description::Sequence>)

=item year()

Returns year of publication


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
