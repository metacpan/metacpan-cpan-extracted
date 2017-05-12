#! perl

# Author          : Johan Vromans
# Created On      : Tue Dec 30 11:56:22 2008
# Last Modified By: Johan Vromans
# Last Modified On: Sat Jun 19 00:48:45 2010
# Update Count    : 24
# Status          : Unknown, Use with caution!

# Om deze module te gebruiken dient deze te worden geplaatst in de
# werk-directory. Vervolgens moet aan .eekboek.conf de volgende sectie
# worden toegevoegd:
#
#    [shell]
#    userdefs = Kasverkoop
#
# De naam achter userdefs moet uiteraard dezelfde zijn als die
# waaronder de module is opgeslagen, zonder de ".pm" extensie.

package EB::Shell::Kasverkoop;

use strict;
use warnings;

use EB;

# Implementatie opdracht "kasverkoop".
#
# kasverkoop datum debiteur omschrijving bedrag
#
# Dit wordt omgezet in twee opdrachten:
#
# verkoop datum Kasboeking debiteur omschrijving bedrag
# kas datum omschrijving deb debiteur bedrag

sub EB::Shell::do_kasverkoop {
    my ($self, @args) = @_;

    # Controleer argumenten. "--nr=.." is een intern doorgegeven
    # argument wanneer de vorm "kasverkoop:boekstuknummer" wordt
    # gebruikt.
    my $bsknr;
    if ( @args && $args[0] =~ /^--?nr=(.+)/ ) {
	$bsknr = $1;
	shift(@args);
    }

    my $datum;
    if ( @args && $args[0] =~/^\d+-\d+(-\d+)?$/  ) {
	$datum = shift(@args);
    }
    else {
	$datum = iso8601date();
    }

    # Nu moeten nog drie argumenten overblijven.
    die("Onvoldoende argumenten. Nodig: [ datum ] debiteur omschrijving bedrag\n")
      unless @args == 3;

    # Opmaken verkoopboeking.
    my @cmd1 = qw(verkoop);
    push(@cmd1, $datum, $args[1], $args[0], $args[1], $args[2]);

    # Opmaken kasboeking.
    my @cmd2 = qw(kas);
    push(@cmd2, "--nr=$bsknr") if $bsknr;
    push(@cmd2, $datum, $args[1], "deb", $args[0], $args[2]);

    for my $command ( \@cmd1, \@cmd2 ) {
	warn("+ @$command\n") if $self->{echo};
	my $cmd = shift(@$command);
	my $m = $self->can("do_$cmd");
	die("Onbekende opdracht: $cmd (eigen schuld)") unless $m;
	my $output = $self->$m(@$command);
	$self->print("$output\n") if $output;
    }

    return;
}

# En uiteraard, de hulpboodschap.

sub EB::Shell::help_kasverkoop {
    return <<EOD;
Eenvoudige manier om een kasverkoop te boeken.

  kasverkoop <datum> <debiteur> <omschrijving> <bedrag>

Bijvoorbeeld:

  kasverkoop 28-01 PIETJE "Dansles" 25,00

Dit wordt omgezet in de opdrachten:

  verkoop 28-01 "Kasverkoop" PIETJE "Dansles" 25,00
  kas 28-01 "Kasverkoop" deb PIETJE 25,00
EOD
}

# Package ends here.

1;
