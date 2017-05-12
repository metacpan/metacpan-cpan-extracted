package KinoSearch1::Search::BooleanClause;
use strict;
use warnings;
use KinoSearch1::Util::ToolSet;
use base qw( KinoSearch1::Util::Class );

BEGIN {
    __PACKAGE__->init_instance_vars(
        occur => 'SHOULD',
        query => undef,
    );
}

sub init_instance {
    my $self = shift;

    croak("invalid value for 'occur': '$self->{occur}'")
        unless $self->{occur} =~ /^(?:MUST|MUST_NOT|SHOULD)$/;
}

__PACKAGE__->ready_get_set(qw( occur query ));

sub is_required   { shift->{occur} eq 'MUST' }
sub is_prohibited { shift->{occur} eq 'MUST_NOT' }

my %string_representations = (
    MUST     => '+',
    MUST_NOT => '-',
    SHOULD   => '',
);

sub to_string {
    my $self   = shift;
    my $string = $string_representations{"$self->{occur}"}
        . $self->{query}->to_string;
    return $string;
}

1;

__END__

==begin devdocs

==head1 NAME

KinoSearch1::Search::BooleanClause - clause in a BooleanQuery

==head1 DESCRIPTION 

A clause in a BooleanQuery.

==head1 COPYRIGHT

Copyright 2005-2010 Marvin Humphrey

==head1 LICENSE, DISCLAIMER, BUGS, etc.

See L<KinoSearch1> version 1.01.

==end devdocs
==cut

