package KinoSearch1::Index::TermVector;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        # params / members
        field         => undef,
        text          => undef,
        positions     => undef,
        start_offsets => undef,
        end_offsets   => undef,
    );
    __PACKAGE__->ready_get_set(
        qw(
            field
            text
            positions
            start_offsets
            end_offsets
            )
    );
}

sub init_instance {
    my $self = shift;
    $self->{$_} ||= [] for qw( positions start_offsets end_offsets );
}
1;

__END__

__POD__

==begin devdocs

==head1 NAME

KinoSearch1::Index::TermVector - Term freq and positional data  

==head1 DESCRIPTION

Ancillary information about a Term.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut


