package EBook::Ishmael::EBook::Metadata;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

sub new {

    my $class = shift;

    my $self = {
        Author      => undef,
        Software    => undef,
        Created     => undef,
        Modified    => undef,
        Format      => undef,
        Title       => undef,
        Language    => undef,
        Genre       => undef,
        ID          => undef,
        Description => undef,
        Contributor => undef,
    };

    return bless $self, $class;

}

sub hash {

    my $self = shift;

    my $hash;

    for my $k (keys %$self) {
        if (not defined $self->{$k}) {
            next;
        }
        if (ref $self->{$k} eq 'ARRAY') {
            $hash->{$k} = [ @{ $self->{$k} } ];
        } else {
            $hash->{$k} = $self->{$k};
        }
    }

    return $hash;

}

sub author {

    my $self = shift;

    return defined $self->{Author} ? @{ $self->{Author} } : ();

}

sub set_author {

    my $self = shift;
    my @set  = grep { defined } @_;

    if (@set) {
        $self->{Author} = \@set;
    } else {
        $self->{Author} = undef;
    }

}

sub add_author {

    my $self = shift;
    my @add  = grep { defined } @_;

    push @{ $self->{Author} }, @add;

}

sub software {

    my $self = shift;

    return $self->{Software};

}

sub set_software {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Software} = undef;
    } else {
        $self->{Software} = $set;
    }

}

sub created {

    my $self = shift;

    return $self->{Created};

}

sub set_created {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Created} = undef;
    } elsif ($set =~ /^-?\d+$/) {
        $self->{Created} = $set;
    } else {
        die "created must be either undef or an integar";
    }

}

sub modified {

    my $self = shift;
    my $set  = shift;

    return $self->{Modified};

}

sub set_modified {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Modified} = undef;
    } elsif ($set =~ /^-?\d+$/) {
        $self->{Modified} = $set;
    } else {
        die "modified must be either an integar or undef";
    }

}

sub format {

    my $self = shift;

    return $self->{Format};

}

sub set_format {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Format} = undef;
    } else {
        $self->{Format} = $set;
    }

}

sub title {

    my $self = shift;

    return $self->{Title};

}

sub set_title {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Title} = $set;
    } else {
        $self->{Title} = $set;
    }

}

sub language {

    my $self = shift;

    return defined $self->{Language} ? @{ $self->{Language} } : ();

}

sub set_language {

    my $self = shift;
    my @set  = grep { defined } @_;

    if (@set) {
        $self->{Language} = \@set;
    } else {
        $self->{Language} = undef;
    }

}

sub add_language {

    my $self = shift;
    my @add  = grep { defined } @_;

    push @{ $self->{Language} }, @add;

}

sub genre {

    my $self = shift;

    return defined $self->{Genre} ? @{ $self->{Genre} } : ();

}

sub set_genre {

    my $self = shift;
    my @set  = grep { defined } @_;

    if (@set) {
        $self->{Genre} = \@set;
    } else {
        $self->{Genre} = undef;
    }

}

sub add_genre {

    my $self = shift;
    my @add  = grep { defined } @_;

    push @{ $self->{Genre} }, @add;

}

sub id {

    my $self = shift;

    return $self->{ID};

}

sub set_id {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{ID} = undef;
    } else {
        $self->{ID} = $set;
    }

}

sub description {

    my $self = shift;

    return $self->{Description};

}

sub set_description {

    my $self = shift;
    my $set  = shift;

    if (not defined $set) {
        $self->{Description} = undef;
    } else {
        $self->{Description} = $set;
    }

}

sub contributor {

    my $self = shift;

    return defined $self->{Contributor} ? @{ $self->{Contributor} } : ();

}

sub set_contributor {

    my $self = shift;
    my @set  = grep { defined } @_;

    if (@set) {
        $self->{Contributor} = \@set;
    } else {
        $self->{Contributor} = undef;
    }

}

sub add_contributor {

    my $self = shift;
    my @add  = grep { defined } @_;

    push @{ $self->{Contributor} }, @add;

}

1;

=head1 NAME

EBook::Ishmael::EBook::Metadata - Ebook metadata interface

=head1 SYNOPSIS

  use EBook::Ishmael::EBook::Metadata;

  my $meta = EBook::Ishmael::EBook::Metadata->new;

  $meta->title([ 'Moby-Dick' ]);
  $meta->author([ 'Herman Melville' ]);
  $meta->language([ 'en' ]);

=head1 DESCRIPTION

B<EBook::Ishmael::EBook::Metadata> is a module used by L<ishmael> to provide
a format-agnostic interface to ebook metadata. This is developer documentation,
for user documentation please consult the L<ishmael> manual.

=head1 METHODS

=head2 $m = EBook::Ishmael::EBook::Metadata->new()

Returns a blessed C<EBook::Ishmael::EBook::Metadata> object.

=head2 $h = $m->hash

Returns a plain hash ref of the object's metadata.

=head2 Accessors

=head3 @a = $m->author()

=head3 $m->set_author(@a)

=head3 $m->add_author(@a)

Set/get the author(s) of the ebook.

=head3 $s = $m->software()

=head3 $m->set_software($s)

Set/get the software used to create the ebook.

=head3 $c = $m->created()

=head3 $m->set_created($c)

Set/get the creation date of the ebook.

=head3 $o = $m->modified()

=head3 $m->set_modified($o)

Set/get the modification date of the ebook.

=head3 $f = $m->format()

=head3 $m->set_format($f)

Set/get the format of the ebook.

=head3 $t = $m->title()

=head3 $m->set_title($t)

Set/get the title of the ebook.

=head3 @l = $m->language()

=head3 $m->set_language(@l)

=head3 $m->add_language(@l)

Set/get the language(s) of the ebook.

=head3 @g = $m->genre()

=head3 $m->set_genre(@g)

=head3 $m->add_genre(@a)

Set/get the genre(s) of the ebook.

=head3 $i = $m->id()

=head3 $m->set_id($i)

Set/get the identifier of the ebook.

=head3 $d = $m->description()

=head3 $m->set_description($d)

Set/get the text description of the ebook.

=head3 @c = $m->contributor()

=head3 $m->set_contributor(@c)

=head3 $m->add_contributor(@c)

Set/get the contributor(s) of the ebook.

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
