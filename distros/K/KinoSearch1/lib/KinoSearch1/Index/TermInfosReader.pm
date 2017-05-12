package KinoSearch1::Index::TermInfosReader;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # constructor params / members
        invindex => undef,
        seg_name => undef,
        finfos   => undef,

        # members
        orig_enum  => undef,
        index_enum => undef,
    );
}

use KinoSearch1::Index::SegTermEnum;

sub init_instance {
    my $self     = shift;
    my $invindex = $self->{invindex};

    # prepare a main Enum which can access all terms
    $self->{orig_enum} = KinoSearch1::Index::SegTermEnum->new(
        finfos   => $self->{finfos},
        instream => $invindex->open_instream("$self->{seg_name}.tis"),
    );

    # load an index Enum into memory which can point to places in main
    $self->{index_enum} = KinoSearch1::Index::SegTermEnum->new(
        finfos   => $self->{finfos},
        instream => $invindex->open_instream("$self->{seg_name}.tii"),
        is_index => 1,
    );
    $self->{index_enum}->fill_cache;
}

# Return a SegTermEnum, pre-located at the right spot if a Term is supplied.
sub terms {
    my ( $self, $term ) = @_;
    if ( defined $term ) {
        $self->fetch_term_info($term);
    }
    else {
        $self->{orig_enum}->reset;
    }
    return $self->{orig_enum}->clone_enum;
}

# Given a Term, return a TermInfo if the Term is present in the segment, or
# undef if it's not.
sub fetch_term_info {
    my ( $self, $term ) = @_;
    my $termstring = $term->get_termstring( $self->{finfos} );

    # termstring will be undefined if field doesn't exist
    return unless defined $termstring;

    $self->_seek_enum($termstring);

    return $self->_scan_enum($termstring);
}

# Locate the main Enum as close as possible to where the term might be found.
sub _seek_enum {
    my ( $self, $termstring ) = @_;
    my $index_enum = $self->{index_enum};

    # get the approximate possible location of the term in the main Enum
    my $tii_position        = $index_enum->scan_cache($termstring);
    my $ballpark_termstring = $index_enum->get_termstring;
    my $ballpark_tinfo      = $index_enum->get_term_info;

    # point the main Enum just before the term
    $self->{orig_enum}->seek(
        $ballpark_tinfo->get_index_fileptr,
        ( ( $tii_position * $self->{orig_enum}->get_index_interval ) - 1 ),
        $ballpark_termstring,
        $ballpark_tinfo,
    );
}

# One-by-one targeted iteration through TermEnum.
sub _scan_enum {
    my ( $self, $target_termstring ) = @_;
    my $orig_enum = $self->{orig_enum};

    # iterate through the Enum until the result is ge the term
    $orig_enum->scan_to($target_termstring);

    # if the stopping point matches the target, return info; otherwise, undef
    my $found_termstring = $orig_enum->get_termstring;
    if ( defined $found_termstring
        and $found_termstring eq $target_termstring )
    {
        return $orig_enum->get_term_info;
    }
    return;
}

sub get_skip_interval {
    shift->{orig_enum}->get_skip_interval;
}

sub close {
    my $self = shift;
    $self->{orig_enum}->close;
    $self->{index_enum}->close;
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermInfosReader - look up Terms in an invindex

==head1 DESCRIPTION

A TermInfosReader manages the relationship between two SegTermEnum objects - a
primary and an index.  

It would be possible, though extremely inefficient, to scan through a single
SegTermEnum every time you wanted to know about a Term.  Having an index makes
the process much quicker, and you need a TermInfosReader to deal with the
index.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

