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

package EBook::FB2::Description::TitleInfo;
use Moose;
use EBook::FB2::Description::Author;
use EBook::FB2::Description::Genre;
use EBook::FB2::Description::Sequence;

has [qw/book_title keywords date lang src_lang/] => (
    isa     => 'Str',
    is      => 'rw'
);

has annotation => ( isa => 'Ref', is => 'rw' );

has _genres => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Object]',
    is      => 'rw',
    default => sub { [] },
    handles => {
       genres       => 'elements',
       add_genre    => 'push',
    },
);

has _authors => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Object]',
    is      => 'rw',
    default => sub { [] },
    handles => {
       authors      => 'elements',
       add_author   => 'push',
    },
);

has _translators => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Object]',
    is      => 'rw',
    default => sub { [] },
    handles => {
       translators      => 'elements',
       add_translator   => 'push',
    },
);

has _sequences => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Object]',
    is      => 'rw',
    default => sub { [] },
    handles => {
       sequences        => 'elements',
       add_sequence     => 'push',
    },
);

has _coverpages => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Str]',
    is      => 'rw',
    default => sub { [] },
    handles => {
       coverpages       => 'elements',
       add_coverpage    => 'push',
    },
);

sub load
{
    my ($self, $node) = @_;

    my @nodes = $node->findnodes('book-title');
    if (@nodes) {
        $self->book_title($nodes[0]->string_value);
    }

    @nodes = $node->findnodes('keywords');
    if (@nodes) {
        $self->keywords($nodes[0]->string_value);
    }

    @nodes = $node->findnodes('lang');
    if (@nodes) {
        $self->lang($nodes[0]->string_value);
    }

    @nodes = $node->findnodes('src-lang');
    if (@nodes) {
        $self->src_lang($nodes[0]->string_value);
    }

    @nodes = $node->findnodes('date');
    if (@nodes) {
        # TODO: parse node to ::Data object
        $self->date($nodes[0]->string_value);
    }

    # Now handle multiple entities
    @nodes = $node->findnodes('author');
    foreach my $node (@nodes) {
        my $author = EBook::FB2::Description::Author->new;
        $author->load($node);
        $self->add_author($author);
    }

    @nodes = $node->findnodes('translator');
    foreach my $node (@nodes) {
        my $translator = EBook::FB2::Description::Author->new;
        $translator->load($node);
        $self->add_translator($translator);
    }

    @nodes = $node->findnodes('genre');
    foreach my $node (@nodes) {
        my $genre = EBook::FB2::Description::Genre->new;
        $genre->load($node);
        $self->add_genre($genre);
    }

    @nodes = $node->findnodes('sequence');
    foreach my $node (@nodes) {
        my $seq = EBook::FB2::Description::Sequence->new;
        $seq->load($node);
        $self->add_sequence($seq);
    }

    @nodes = $node->findnodes('coverpage/image');
    foreach my $node (@nodes) {
        my $map = $node->getAttributes;
        # find href attribute, a litle bit hackerish
        my $i = 0;
        while ($i < $map->getLength) {
            my $item = $map->item($i);
            if ($item->getName =~ /:href/i) {
                my $id = $item->getValue;
                $id =~ s/^#//;
                $self->add_coverpage($id);
            }
            $i++;
        }
    }

    @nodes = $node->findnodes('annotation');
    if (@nodes) {
        $self->annotation($nodes[0]);
    }


}

1;

__END__
=head1 NAME

EBook::FB2::Description::TitleInfo

=head1 SYNOPSIS

EBook::FB2::Description::TitleInfo - meta information of hardcopy document 

=head1 SUBROUTINES/METHODS

=over 4

=item annotation()

Returns reference to XML::DOM::Node, parsed annotation

=item authors()

Returns list of book authors (references to L<EBook::FB2::Description::Author>)

=item book_title()

Returns book title

=item coverpages()

Returns list of ids that references to images with original cover artwork

=item date()

Returns book creation date

=item genres()

Returns list of genres book falls in (references to 
L<EBook::FB2::Description::Genre>)

=item keywords()

Returns book keyword

=item lang()

Returns book language: "en", "ru", etc...

=item sequences()

Returns list of sequences book belongs to (references to L<EBook::FB2::Description::Sequence>)

=item src_lang()

Original book language. Valid if book is translation.

=item translators()

Returns list of translators represented by references to 
L<EBook::FB2::Description::Author> objects;

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
