package Debian::Copyright::Stanza::OrSeparated;
require v5.10.1;
use strict;
use warnings;

use Array::Unique;
use Text::ParseWords qw(quotewords);
use overload
    '""' => \&as_string,
    'eq' => \&equals;

our $VERSION = '0.2';

=head1 NAME

Debian::Copyright::Stanza::OrSeparated - 'or' separated field abstraction

=head1 VERSION

This document describes Debian::Copyright::Stanza::OrSeparated version 0.2 .

=cut

=head1 SYNOPSIS

    my $f = Debian::Copyright::Stanza::OrSeparated->new('Artistic');
    $f->add('GPL-1+ or BSD');
    print $f->as_string;
        # 'Artistic or GPL-1+ or BSD'
    print "$f";     # the same
    $f->sort;

=head1 DESCRIPTION

Debian::Copyright::Stanza::OrSeparated abstracts handling of the License
fields in Files blocks, which are lists separated by 'or'. It also supports
a body field representing the optional extended description of a License field.

=head1 CONSTRUCTOR

=head2 new (initial values)

The initial values list is parsed and may contain strings that are in fact
'or'-separated lists. These are split appropriately using L<Text::ParseWords>'
C<quotewords> routine.

=cut

sub new {
    my $self = bless {list=>[],body=>""}, shift;

    tie @{$self->{list}}, 'Array::Unique';

    my $body = exists $self->{body} ? $self->{body} : "";
    my @list = ();
    foreach my $e (@_) {
        if ($e =~ m{\A([^\n]+)\n(.+)\z}xms) {
            push @list, $1;
            $body .= $2;
        }
        else {
            push @list, $e;
        }
    }
    $self->add(@list) if @list;
    $self->{body} = $body if $body;

    $self;
}

=head1 METHODS

=head2 as_string

Returns text representation of the list. A simple join of the elements by
C< or >. The same function is used for overloading the stringification
operation.

=cut

sub as_string
{
    my $self = shift;
    my $body = exists $self->{body} ? "\n$self->{body}" : "";
    return join( ' or ', @{ $self->{list} } ).$body;
}

=head2 equals

Natural implementation of the equality function.

=cut

sub equals 
{
    my @args = map { ref $_ ? $_->as_string : $_ } @_;
    return $args[0] eq $args[1];
}

sub _parse {
    my $self = shift;

    my @output;

    for (@_) {
        my @items = quotewords( qr/\s+or\s+/, 1, $_ );
        push @output, @items;
    }

    return @output;
}

=head2 add I<@items>

Adds the given items to the list. Items that are already present are not added,
keeping the list unique.

=cut

sub add {
    my ( $self, @items) = @_;

    push @{$self->{list}}, $self->_parse(@items);
}

=head2 sort

A handy method for sorting the list.

=cut

sub sort {
    my $self = shift;

    @{$self->{list}} = sort @{$self->{list}};
}

=head1 COPYRIGHT & LICENSE

Copyright (C) 2011-12 Nicholas Bamber L<nicholas@periapt.co.uk>

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

1;

1;
