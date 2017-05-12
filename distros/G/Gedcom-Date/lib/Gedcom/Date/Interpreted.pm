package Gedcom::Date::Interpreted;

use strict;

use vars qw($VERSION @ISA);

our $VERSION = '0.10';
@ISA = qw/Gedcom::Date/;

use Gedcom::Date;

sub parse {
    my $class = shift;
    my ($str) = @_;

    my ($date, $phrase) = $str =~ /^INT (.*?) \((.*)\)$/
        or return;

    my $date_s = Gedcom::Date::Simple->parse($date)
        or return;

    my $self = bless {
        date => $date_s,
        phrase => $phrase
    }, $class;

    return $self;
}

sub gedcom {
    my $self = shift;

    if (!defined $self->{gedcom}) {
        $self->{gedcom} = 'INT '.$self->{date}->gedcom().
                          " ($self->{phrase})";
    }
    $self->{gedcom};
}

sub latest {
    my ($self) = @_;

    return $self->{date}->latest;
}

sub earliest {
    my ($self) = @_;

    return $self->{date}->earliest;
}

sub sort_date {
    my ($self) = @_;

    return $self->{date}->sort_date;
}

my %text = (
    en => 'on %0',
    nl => 'op %0',
);

sub text_format {
    my ($self, $lang) = @_;

    return ($text{$lang}, $self->{date});
}

1;

__END__

=head1 NAME

Gedcom::Date::Interpreted - Perl class for interpreted Gedcom dates

=head1 SYNOPSIS

  use Gedcom::Date::Interpreted;

  my $date = Gedcom::Date::Interpreted->parse( 'INT 10 JUL 2003 (today)' );

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
