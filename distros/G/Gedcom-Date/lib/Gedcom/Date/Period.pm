package Gedcom::Date::Period;

use strict;

use vars qw($VERSION @ISA);

our $VERSION = '0.10';
@ISA = qw/Gedcom::Date/;

use Gedcom::Date;

sub parse {
    my $class = shift;
    my ($str) = @_;

    my ($from, $to);
    if ($str =~ /^FROM (.*?) TO (.*)$/) {
        $from = Gedcom::Date::Simple->parse($1) or return;
        $to = Gedcom::Date::Simple->parse($2) or return;
    } elsif ($str =~ /^FROM (.*)$/) {
        $from = Gedcom::Date::Simple->parse($1) or return;
    } elsif ($str =~ /^TO (.*)$/) {
        $to = Gedcom::Date::Simple->parse($1) or return;
    } else {
        return;
    }

    my $self = bless {
        from => $from,
        to => $to
    }, $class;

    return $self;
}

sub gedcom {
    my $self = shift;

    if (!defined $self->{gedcom}) {
        $self->{gedcom} = join ' ',
                          map {defined $self->{$_} ?
                               (uc, $self->{$_}->gedcom()) :
                               ()
                              }
                          qw/from to/;
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
    my ($self) = @_;

    if (defined $self->{from}) {
        return $self->{from}->sort_date;
    } else {
        return $self->{to}->sort_date;
    }
}

my %text = (
    en => ['from %0', 'to %1', 'from %0 to %1'],
    nl => ['vanaf %0', 'tot %1', 'van %0 tot %1'],
);

sub text_format {
    my ($self, $lang) = @_;
    $lang ||= 'en';

    my $type = defined($self->{to}) ?
                   (defined($self->{from}) ? 2 : 1 ) : 0;
    return ($text{$lang}[$type], $self->{from}, $self->{to});
}

1;

__END__

=head1 NAME

Gedcom::Date::Period - Perl class for Gedcom date periods

=head1 SYNOPSIS

  use Gedcom::Date::Period;

  my $date = Gedcom::Date::Period->parse(
                        'FROM 10 JUL 2003 TO 20 AUG 2003' );

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
