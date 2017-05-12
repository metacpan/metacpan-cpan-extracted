# Documentation and Copyright exist after __END__

package Lingua::Spelling::Alternative;
require 5.001;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

use Exporter;
$VERSION = '0.02';
@ISA = ('Exporter');

#@EXPORT = qw();
@EXPORT_OK = qw(
	&alternatives
	);

my $debug=0;

#
# make new instance of language, get args
#
sub new {
	my $class = shift;
	my $self = {};
	bless($self, $class);
	$self->{ARGS} = {@_};
	$debug = $self->{ARGS}->{DEBUG};
	@{$self->{affix_regexp}} = ();
	@{$self->{affix_add}} = ();
	@{$self->{affix_sub}} = ();
	$self ? return $self : return undef;
}


#
# load affix file in internal structures
#

sub load_affix {
	my $self = shift;
	my $filename = shift;

	my $suffixes=0;

	my ($regexp,$add,$sub);

	print STDERR "reading affix file $filename\n" if ($debug);

	open (A,$filename) || die "Can't open affix file $filename: $!";
	while(<A>) {
		chomp;
		next if (/^#|^[\s\t\n\r]*$/);

		if (/^suffixes/i) {
			$suffixes++;
			next;
		}

		next if (! $suffixes);

		if (/^flag[\s\t]+\*{0,1}(.):/i) {
			undef $regexp;
			undef $add;
			undef $sub;
			next;
		}

		if (/^[\s\t]*([^>#]+)>[\s\t]+-([^\,\s\t]+),([^\s\t]+)/) {
			$regexp = $1;
			$add = $2;
			$sub = $3 if ($3 ne "-");
		} elsif (/^[\s\t]*([^>#]+)>[\s\t]+([^\s\t\#]+)/) {
			$regexp = $1;
			$sub = $2;
		}

		sub nuke_s {
			my $tmp = $_[0];
			return if (!$tmp);
		#	$tmp=~s/^\s+//g;
		#	$tmp=~s/\s+$//g;
			$tmp=~s/\s+//g;
			return $tmp;
		}

		push @{$self->{affix_regexp}},nuke_s($regexp);
		push @{$self->{affix_add}},nuke_s($add);
		push @{$self->{affix_sub}},nuke_s($sub);
	}
	return 1;
}

#
# function for reading raw findaffix output
#

sub load_findaffix {
	my $self = shift;
	my $filename = shift;

	print STDERR "reading findaffix output $filename\n" if ($debug);

	open (A,$filename) || die "Can't open findaffix output $filename: $!";
	while(<A>) {
		chomp;
		my @line=split(m;/;,$_,4);
		if ($#line > 2) {
			push @{$self->{affix_regexp}},'.';
			push @{$self->{affix_sub}},$line[0];
			push @{$self->{affix_add}},$line[1];
		}
	}
	return 1;
}

#
# function which returns original word and all alternatives
#

sub alternatives {
	my $self = shift;
	my @out;
	foreach my $word (@_) {
		push @out,$word;		# save original word
		next if (length($word) < 3);	# cludge: preskoci kratke
		for(my $i=0; $i<=$#{$self->{affix_regexp}}; $i++) {
			my $regexp = $self->{affix_regexp}[$i];
			my $add = $self->{affix_add}[$i];
			my $sub = $self->{affix_sub}[$i];
			print STDERR "r:'$regexp'\t-'",$sub||'',"'\t+'",$add||'',"'\n" if ($debug);
			next if length($word) < length($sub);
			my $tmp_word = $word;
			if ($sub) {
				next if ($word !~ m/$sub$/i);
				if ($add) {
					$tmp_word =~ s/$sub$/$add/i;
				} else {
					$tmp_word =~ s/$sub$//i;
				}
			} else {
				$tmp_word = $word.$add;
			}
			print STDERR "\t ?:$tmp_word\n" if ($debug);
			if ($tmp_word =~ m/$regexp/ix) {
#				print "$word -> $tmp_word\t-$sub, +$add, regexp: $regexp\n";
				push @out,lc($tmp_word);
			}
		}
	}
	return @out;
}

#
# function which return minimal word of all alternatives
#

sub minimal {
	my $self = shift;
	my @out;
	foreach my $word (@_) {
		my @alt = $self->alternatives($word);
		my $minimal = shift @alt;
		foreach (@alt) {
			$minimal=$_ if (length($_) < length($minimal));
		}
		push @out,$minimal;
	}
	return @out;
}

###############################################################################
1;
__END__

=head1 NAME

Alternative.pm - alternative spelling of a given word in a given language

=head1 SYNOPSIS

  use Lingua::Spelling::Alternative;

  my $en = new Lingua::Spelling::Alternative;
  $en->load_affix('/usr/lib/ispell/default.aff') or die $!;
  print join(" ",$en->alternatives("cars")),"\n";

=head1 DESCRIPTION

This module is designed to return all forms of a given word
(for example when you want to see all possible forms of some word
entered in search engine) which can be generated using affix file (from
ispell) or using findaffix output file (also part of ispell package)

=head1 PUBLIC METHODS

=over 4

=item new

The new() constructor (without parameters) create container for new language.
Only parameter it supports is DEBUG which turns on (some) debugging output.

=item load_affix

Function load_affix() loads ispell's affix file for later usage.

=item load_findaffix

This function loads output of findaffix program from ispell package.
This is better idea (if you are creating affix file for particular language
yourself or you can get your hands on one) because affix file from ispell
is limited to 26 entries (because each entry is denoted by single character).

=item alternatives

Function alternatives return array of all alternative spellings of particular
word(s). It will also return spelling which are not correct if there is
rule like that in affix file.

=item minimal

This function returns minimal of all alternatives of a given word(s). It's
a poor man's version of normalize (because we don't know grammatic of
particular language, just some spelling rules).

=back

=head1 PRIVATE METHODS

Documented as being not documented.

=head1 EXAMPLES

Please see the test.pl program in distribution which exercises some
aspects of Alternative.pm.

=head1 BUGS

There are no known bugs. If you find any, please report it in CPAN's
request tracker at: http://rt.cpan.org/

=head1 CONTACT AND COPYRIGHT

Copyright 2002-2003 Dobrica Pavlinusic (dpavlin@rot13.org). All
rights reserved.  This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
