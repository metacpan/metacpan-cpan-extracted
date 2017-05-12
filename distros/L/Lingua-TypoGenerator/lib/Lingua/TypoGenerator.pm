package Lingua::TypoGenerator;

use 5.006;
use utf8; 
use strict;

our $VERSION = '0.01';

use base 'Exporter';
our @EXPORT_OK = qw(typos);

our $HTYPOS = " qwertyuiop asdfghjkl zxcvbnm ýúíó ùìò ÿüïö ûîô";
our @ACCENT_CLASSES = qw(
    aáàâäãå
    eéèêë
    iíìîï
    oóòôöõø
    uúùûü
    yýÿ
    nñ
);


# Takes one word and returns a list of probable typos
sub typos {
    my ($s, %args) = @_;
    my %seen;

    # Typos involving one character
    for (my $i = 0; $i < length $s; ++$i){ 
	my $c = substr($s, $i, 1);

	next unless $c =~ /\w/;

	my $t = $s; # deletions
	substr($t, $i, 1) = "";
	$seen{$t} = 1;

	# horizontal keyboard typos
	if($HTYPOS =~ /(.)$c(.)/i){
	    if ($1 ne ' '){
		$t = $s;
		substr($t, $i, 1) = $1;
		$seen{$t} = 1;
	    }
	    if ($2 ne ' '){
		$t = $s;
		substr($t, $i, 1) = $2;
		$seen{$t} = 1;
	    }
	}

        if ($args{accents}) {
            for (@ACCENT_CLASSES) {
                my $class = $_;
                if($class =~ s/$c//i){
                    for my $letter (split(//, $class)){
                        $t = $s;
                        substr($t, $i, 1) = $letter;
                        $seen{$t} = 1;
                    }
                }
            }
        }
    }

    # Typos involving a pair of adjacent characters
    for (my $i = 1; $i < length $s; ++$i){ 
	my $t = $s;

	next unless substr($t, $i - 1, 2) =~ /\w\w/;

	my $c = substr $t, $i, 1; # transpositions
	substr($t, $i, 1) = substr($t, $i - 1, 1);
	substr($t, $i - 1, 1) = $c;
	$seen{$t} = 1;

	$t = $s;  # duplications with replacement
	substr($t, $i, 1) = substr($t, $i - 1, 1);
	$seen{$t} = 1;

	$t = $s;  # duplications with insertion
	substr($t, $i, 0) = substr($t, $i - 1, 1);
	$seen{$t} = 1;
    }

    delete $seen{$s}; # make sure to exclude original word!

    return sort keys %seen;
}

1;

__END__

=head1 NAME

Lingua::TypoGenerator - Generate plausible typos for a word

=head1 SYNOPSIS

    use Lingua::TypoGenerator 'typos';
    my @typos = typos("information");
    # returns qw(ibformation, ifnormation, iformation, iiformation, ...)

    # use accents
    @typos = typos("año", accents => 1);
    # returns qw(aao, aaño, ano, ao, aoñ, añ, añi, añp...)

=head1 DESCRIPTION

This module has a single exportable function, C<typos>, which, given a string,
returns a list of "plausible typos". It works by deleting characters,
duplicating characters, transposing adjacent characters, and replacing 
characters by adjacent keys in the QWERTY keyboard. It can also optionally
add, remove or change the type of accent in a character.

=head1 FUNCTIONS

    @typos = typos($word, %options);

Return a list of typos given a word. The only available option at this time
is C<< accents => 1 >>, which enables accent munging.

=head1 TODO

This module has a "Western European" and QWERTY bias. Ideally, future versions
should include options for localization and different keyboards.

=head1 AUTHOR

Ivan Tubert-Brohman E<lt>itub@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2004 Ivan Tubert-Brohman. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same terms as
Perl itself.

=cut

