package Gedcom::Date::Phrase;

use strict;

use vars qw($VERSION @ISA);

our $VERSION = '0.10';
@ISA = qw/Gedcom::Date/;

use Gedcom::Date;

sub parse {
    my $class = shift;
    my ($str) = @_;

    my ($phrase) = $str =~ /^\((.*)\)$/
        or return;

    my $self = bless {
        phrase => $phrase
    }, $class;

    return $self;
}

sub gedcom {
    my $self = shift;

    if (!defined $self->{gedcom}) {
        $self->{gedcom} = "($self->{phrase})";
    }
    $self->{gedcom};
}

sub earliest {
    return DateTime::Infinite::Past->new;
}

sub latest {
    return DateTime::Infinite::Future->new;
}

sub sort_date {
    return '????-??-??';
}

sub as_text {
    my ($self, $lang) = @_;

    return "($self->{phrase})";
}

1;

__END__

=head1 NAME

Gedcom::Date::Phrase - Perl class for Gedcom date phrases

=head1 SYNOPSIS

  use Gedcom::Date::Phrase;

  my $date = Gedcom::Date::Phrase->parse( '(today)' );

=head1 DESCRIPTION

Parse dates from Gedcom files.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 REPOSITORY

L<https://github.com/ronsavage/Gedcom-Date>.

=head1 See Also

L<Genealogy::Date>.

L<Genealogy::Gedcom::Date>.

=head1 COPYRIGHT

Copyright (c) 2003 Eugene van der Pijll.  All rights reserved.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
