package Lingua::DE::TypoGenerator;

use strict;
use warnings;
use constant LDT_VCHARSETS => ( 'ISO-8859-1' ); #, 'ISO-8859-15', 'UTF-8' );
use constant LDT_DEFCHARSET => 'ISO-8859-1';
use constant LDT_KEYBOARDLAY => ( '1234567890', 'qwertzuiopü', 'asdfghjklöä', 'yxcvbnm' );
use vars qw($VERSION @ISA @EXPORT);
require 5.8.0;

BEGIN {
	$VERSION = '0.2';

	use Exporter;
	@ISA = qw(Exporter);

	@EXPORT = qw(typos);
}

sub new {
	my $class = shift;
	my %opt = @_;

	my $self = {
		charset => $opt{'charset'},
	};
	
	# Check charset
	my $v_charset = 0;
	foreach my $ccharset (LDT_VCHARSETS) {
		if ($self->{'charset'} and $self->{'charset'} eq $ccharset) {
			$v_charset = 1;
		}
	}
	if (!$v_charset) { $self->{'charset'} = LDT_DEFCHARSET; }

	# Bless and return
	return bless $self, $class;
}

sub typos {
	my $self;
	if (@_ == 2) {
		$self = shift;
	}
	my $word = shift;

	# Self init if required
	if (!$self) {
		$self = new('Lingua::DE::TypoGenerator');
	}

	my @typos = ();

	# Forget characters
	@typos = (@typos, $self->_typo_forgetchar($word));

	# Double characters
	@typos = (@typos, $self->_typo_doublechar($word));

	# Twist characters
	@typos = (@typos, $self->_typo_twistchars($word));

	# Miss keys
	@typos = (@typos, $self->_typo_misskeys($word));

	# Sort unique
	@typos = $self->_unique_array(@typos);

	return @typos;
}

sub _typo_forgetchar {
	my $self = shift;
	my $word = shift;

	my @typos = ();

	for (my $i = 0; $i < length($word); $i++) {
		push @typos, substr($word, 0, $i).substr($word, $i + 1);
	}
	
	return @typos;
}

sub _typo_doublechar {
	my $self = shift;
	my $word = shift;

	my @typos = ();

	for (my $i = 0; $i < length($word); $i++) {
		push @typos, substr($word, 0, $i).substr($word, $i, 1).substr($word, $i);
	}

	return @typos;
}

sub _typo_twistchars {
	my $self = shift;
	my $word = shift;

	my @typos = ();

	for (my $i = 0; $i < length($word) - 1; $i++) {
		my @c = split //, $word;
		my $b = $c[$i];
		$c[$i] = $c[$i + 1];
		$c[$i + 1] = $b;
		push @typos, join('', @c) unless $#c < 0;
	}

	return @typos;
}

sub _typo_misskeys {
	my $self = shift;
	my $word = shift;

	my @typos = ();
	my @kblay = LDT_KEYBOARDLAY;

	for (my $i = 0; $i < length($word); $i++) {
		my $c = substr($word, $i, 1);
		my $kl = -1;
		my $ki = -1;
		KBLAYIT: for (my $j = 0; $j < scalar(@kblay); $j++) {
			$ki = index($kblay[$j], $c);
			if ($ki > -1) {
				$kl = $j;
				last KBLAYIT;
			}
		}
		last if $kl == -1;
		last if $ki == -1;
		for (my $line = $kl - 1; $line <= $kl + 1; $line++) {
			next if $line < 0;
			next if $line > $#kblay;

			for (my $col = $ki - 1; $col <= $ki + 1; $col+=2) {
				next if $col < 0;
				next if $ki > length($kblay[$line]);

				push @typos, substr($word, 0, $i).substr($kblay[$line], $ki, 1).substr($word, $i + 1);
			}
		}
	}

	return @typos;
}

sub _unique_array {
	my $self = shift;
	my @in = @_;

	my %uq = ();
	foreach my $e (@in) {
		$uq{$e} = 1;
	}

	return sort keys %uq;
}

# Satisfy require
1;
__END__
=head1 NAME

Lingua::DE::TypoGenerator - German Typo Generator 

=head1 SYNOPSIS

  Object invocation:
  use Lingua::DE::TypoGenerator;
  my $ldt = Lingua::DE::TypoGenerator->new();
  my @typos = $ldt->typos("keyword");

  Old invocation:
  use Lingua::DE::TypoGenerator qw(typos);
  my @typos = typos("keyword");

=head1 DESCRIPTION

Lingua::DE::TypoGenerator will generate a list of all typo errors
a user with a German keyboard is likely to produce for a given word.

You can either use the module in OO-style or import the "typos" function.
Calling typos with a keyword will return an array of all likely typos.

=head1 SEE ALSO

If you are looking for a similar module that uses an englisch keyboard
layout you should take a look at Lingua::TypoGenerator which, by the way,
inspired this module.

The newest version of the module should always be in CPAN or on my
homepage http://www.chengfu.net/

=head1 AUTHOR

Mario Witte, E<lt>mario.witte@chengfu.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Mario Witte 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
