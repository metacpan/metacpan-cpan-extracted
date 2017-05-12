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

package EBook::FB2::Body;
use Moose;
use EBook::FB2::Body::Section;

has name => ( isa => 'Str', is => 'rw' );
has title => ( isa => 'Ref', is => 'rw' );
has _epigraphs => ( 
    isa     => 'ArrayRef',
    is => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        epigraphs       => 'elements',
        add_epigraph    => 'push',
    }
);
has image => ( isa => 'Str', is => 'rw' );
has _sections => ( 
    isa     => 'ArrayRef',
    is      => 'ro',
    traits  => ['Array'],
    default => sub { [] },
    handles => {
        sections    => 'elements',
        add_section => 'push',
    }
);

sub load
{
    my ($self, $node) = @_;

    my $anode = $node->getAttribute("name");
    if (defined($anode)) {
        $self->name($anode);
    }

    my @nodes = $node->findnodes("title");
    if (@nodes) {
        $self->title($nodes[0]);
    }
    @nodes = $node->findnodes("epigraph");
    foreach my $n (@nodes) {
        $self->add_epigraph($n);
    }

    @nodes = $node->findnodes("image");
    if (@nodes) {
        my $map = $nodes[0]->getAttributes;
        # find href attribute, a litle bit hackerish
        my $i = 0;
        while ($i < $map->getLength) {
            my $item = $map->item($i);
            if ($item->getName =~ /:href/i) {
                my $id = $item->getValue;
                $id =~ s/^#//;
                $self->image($id);
                last;
            }
            $i++;
        }
    }

    @nodes = $node->findnodes("section");
    foreach my $n (@nodes) {
        my $s = EBook::FB2::Body::Section->new();
        $s->load($n);
        $self->add_section($s);
    }
}

1;

__END__
=head1 NAME

EBook::FB2::Body

=head1 SYNOPSIS

    EBook::FB2::Body - class that represents <body> element

=head1 SUBROUTINES/METHODS

=over 4

=item epigraphs()

Returns array of references to XML::DOM::Node objects, parsed epigraphs 
of body element 

=item sections()

Returns array of references to L<EBook::FB2::Body::Section> objects, 
sections of body element

=item name()

Returns name of body element. Ususally it's either empty or "notes"

=item image()

Returns id of image associated with body element

=item title()

Returns title of body element

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
