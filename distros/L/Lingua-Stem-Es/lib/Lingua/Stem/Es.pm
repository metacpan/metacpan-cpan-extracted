package Lingua::Stem::Es;

use Carp;

use warnings;
use strict;

use utf8;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ();
our @EXPORT_OK   = qw (stem stem_word clear_stem_cache stem_caching);
our @EXPORT      = ();

our $VERSION = '0.04';

our $DEBUG = 0;

my $Stem_Caching = 0;
my $Stem_Cache   = {};

my $vowels     = 'aeiouáéíóúü';
my $consonants = 'bcdfghjklmnñpqrstvwxyz';

my $revowel      = qr/[$vowels]/;
my $reconsonants = qr/[$consonants]/;

sub stem {
    return [] if ( $#_ == -1 );
    my $parm_ref;
    if ( ref $_[0] ) {
        $parm_ref = shift;
    }
    else {
        $parm_ref = {@_};
    }

    my $words      = [];
    my $locale     = 'es';
    my $exceptions = {};
    foreach ( keys %$parm_ref ) {
        my $key = lc($_);
        if ( $key eq '-words' ) {
            @$words = @{ $parm_ref->{$key} };
        }
        elsif ( $key eq '-exceptions' ) {
            $exceptions = $parm_ref->{$key};
        }
        elsif ( $key eq '-locale' ) {
            $locale = $parm_ref->{$key};
        }
        else {
            croak( __PACKAGE__
                  . "::stem() - Unknown parameter '$key' with value '$parm_ref->{$key}'\n"
            );
        }
    }

    local ($_);
    foreach (@$words) {

        # Check against exceptions list
        if ( exists $exceptions->{$_} ) {
            $_ = $exceptions->{$_};
            next;
        }

        # Cache and stem
        my $original_word = $_;
        $_ = stem_word($_);
        $Stem_Cache->{$original_word} = $_ if $Stem_Caching;
    }
    $Stem_Cache = {} if ( $Stem_Caching < 2 );

    return $words;
}

sub stem_word {
    my $word = shift;

    print "*****************\nOriginal: $word\n" if $DEBUG;

    # Flatten case
    $word =~ s/Á/á/g;
    $word =~ s/É/é/g;
    $word =~ s/Í/í/g;
    $word =~ s/Ó/ó/g;
    $word =~ s/Ú/ú/g;
    $word =~ s/Ü/ü/g;
    $word =~ s/Ñ/ñ/g;
    $word = lc $word;
    print "Flatened word: $word\n" if $DEBUG;

    # Check against cache of stemmed words
    if ( $Stem_Caching && exists $Stem_Cache->{$word} ) {
        return $Stem_Cache->{$word};
    }

    # Remove punctuation
    $word =~ s/[^$vowels$consonants]//g;
    return '' unless $word;
    print "Removed punctuation: $word\n" if $DEBUG;

    my $RV = define_RV($word);
    my $suffix;

    ############################################################
    ###########              Step 0                  ###########
    ############################################################
    # Attached pronoun
    # Search for the longest among the following suffixes:
    # me se sela selo selas selos la le lo las les los nos
    # and delete it, if it comes after one of
    # a) iéndo ándo ár ér ír
    # b) ando iendo ar er ir
    # c) yendo following u
    # in RV. In the case of c), yendo must lie in RV, but the preceding u can 
    # be outside it.
    # In the case of a), deletion is followed by removing the acute accent.
    # Always do step 0

    if ($RV) {
        my $pronoun =
          qr/(selas|selos|sela|selo|las|les|los|nos|me|se|la|le|lo)$/;

        if ( ($suffix) = $RV =~ /(?:ándo|iéndo|ár|ér|ír)($pronoun)$/ ) {

            # Case a)
            $word =~ s/$suffix$//;
            $word =~ s/á/a/;
            $word =~ s/é/e/;
            $word =~ s/í/i/;
            $word =~ s/ó/o/;
            $word =~ s/ú/u/;
            $word =~ s/ü/u/;
            print "Step 0 case a: $word\n" if $DEBUG;
        }
        elsif ( ($suffix) = $RV =~ /(?:ando|iendo|ar|er|ir)($pronoun)$/ ) {

            # Case b)
            $word =~ s/$suffix$//;
            print "Step 0 case b: $word\n" if $DEBUG;
        }
        elsif ( ($suffix) =
            $word =~ /uyendo($pronoun)$/ and $RV =~ /yendo$pronoun$/ )
        {

            # Case c)
            $word =~ s/$suffix$//;
            print "Step 0 case c: $word\n" if $DEBUG;
        }
    }

    ############################################################
    ###########              Step 1                  ###########
    ############################################################
    # Standard suffix removal
    # Search for the longest among the following suffixes, and perform the
    # action indicated.
    # Always do step 1

    $RV = define_RV($word);
    my $R1 = define_R1($word);
    my $R2 = define_R2($word);

    if (
        ($suffix) = $R2 =~
        /(amientos|imientos|amiento|imiento|anzas|ismos|ables|ibles|istas|
				 anza|icos|icas|ismo|able|ible|ista|osos|osas|ico|ica|oso|osa)$/x
      )
    {

    # anza anzas ico ica icos icas ismo ismos able ables ible ibles ista istas
    # oso osa osos osas amiento amientos imiento imientos
    # delete if in R2
        $word =~ s/$suffix$//;
        print "Step 1 case 1: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) =
        $R2 =~ /(aciones|adores|adoras|adora|antes?|ancias?|ación|ador)$/ )
    {

        # adora ador ación adoras adores aciones
        # delete if in R2
        # if preceded by ic, delete if in R2
        if ( $R2 =~ /ic$suffix$/ ) {
            $word =~ s/ic$suffix$//;
        }
        else {
            $word =~ s/$suffix$//;
        }
        print "Step 1 case 2: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) = $R2 =~ /(logías?)$/ ) {

        # logía logías
        # replace with log if in R2
        $word =~ s/$suffix$/log/;
        print "Step 1 case 3: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) = $R2 =~ /uci(ones|ón)$/ ) {

        # ución uciones
        # replace with u if in R2
        $word =~ s/uci$suffix$/u/;
        print "Step 1 case 4: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) = $R2 =~ /(encias?)$/ ) {

        # encia encias
        # replace with ente if in R2
        $word =~ s/$suffix$/ente/;
        print "Step 1 case 5: $word\n" if $DEBUG;
    }
    elsif ( $R1 =~ /amente$/ ) {

        # delete if in R1
        # if preceded by iv, delete if in R2 (and if further preceded by at, delete if in R2)
        # otherwise,
        # if preceded by os, ic or ad, delete if in R2
        if ( ($suffix) = $R2 =~ /(os|ic|ad)amente$/ ) {
            $word =~ s/($suffix)amente$//;
        }
        elsif ( ($suffix) = $R2 =~ /((?:at(?=iv))?(?:iv))amente$/ ) {
            $word =~ s/($suffix)amente$//;
        }
        else {
            $word =~ s/amente$//;
        }
        print "Step 1 case 6: $word\n" if $DEBUG;
    }
    elsif ( $R2 =~ /mente$/ ) {

        # mente
        # delete if in R2
        # if preceded by able, ante or ible, delete if in R2
        if ( ($suffix) = $R2 =~ /([ai]ble|ante)mente$/ ) {
            $word =~ s/($suffix)mente$//;
        }
        else {
            $word =~ s/mente$//;
        }
        print "Step 1 case 7: $word\n" if $DEBUG;
    }
    elsif ( $R2 =~ /idad(es)?$/ ) {

        # idad idades
        # delete if in R2
        # if preceded by abil, ic or iv, delete if in R2
        if ( ($suffix) = $R2 =~ /(abil|ic|iv)idad(es)?$/ ) {
            $word =~ s/(abil|ic|iv)idad(es)?$//;
        }
        else {
            $word =~ s/idad(es)?$//;
        }
        print "Step 1 case 8: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) = $R2 =~ /(iv[ao]s?)$/ ) {

        # iva ivo ivas ivos
        # delete if in R2
        # if preceded by at, delete if in R2
        $R2 =~ /at$suffix$/ ? $word =~ s/at$suffix$// : $word =~ s/$suffix$//;
        print "Step 1 case 9: $word\n" if $DEBUG;
    }

    ############################################################
    ###########              Step 2a                 ###########
    ############################################################
    # Verb suffixes beginning 'y'
    # Search for the longest among the following suffixes in RV, and
    # if found, delete if preceded by u. (Note that the preceding u
    # need not be in RV).
    # ya ye yan yen yeron yendo yo yó yas yes yais yamos
    # Do step 2a if no ending was removed by step 1
    elsif ($word =~ /u(yeron|yendo|yamos|yais|ya[ns]?|ye[ns]?|yo|yó)$/
        && $RV =~ /(yeron|yendo|yamos|yais|ya[ns]?|ye[ns]?|yo|yó)$/ )
    {
        $word =~ s/u(yeron|yendo|yamos|yais|ya[ns]?|ye[ns]?|yo|yó)$/u/;
        print "Step 2a: $word\n" if $DEBUG;
    }

    ############################################################
    ###########              Step 2b                 ###########
    ############################################################
    # Other verb suffixes
    # Search for the longest among the following suffixes in RV, and
    # perform the action indicated.
    # Do step 2b if step 2a was done but failed to remove a suffix.

    elsif (
        ($suffix) =
        $RV =~ /(iésemos|iéramos|iríamos|eríamos|aríamos|ásemos|
	áramos|ábamos|isteis|asteis|ieseis|ierais|iremos|iríais|eremos|eríais|aremos|
	aríais|aseis|arais|abais|ieses|ieras|iendo|ieron|iesen|ieran|iréis|irías|irían|        #ancias?|
	eréis|erías|erían|aréis|arías|arían|íamos|imos|amos|idos|ados|íais|ases|aras|idas|     #antes?|
	adas|abas|ando|aron|asen|aran|aban|iste|aste|iese|iera|iría|irás|irán|ería|erás|erán|
	aría|arás|arán|áis|ías|ido|ado|ían|ase|ara|ida|ada|aba|iré|irá|eré|erá|aré|
	ará|ís|as|ir|er|ar|ió|an|id|ed|ad|ía)$/x
      )
    {

        # delete
        $word =~ s/$suffix$//;
        print "Step 2b1: $word\n" if $DEBUG;
    }
    elsif ( ($suffix) = $RV =~ /(emos|éis|en|es)$/ ) {

        # en es éis emos
        # delete, and if preceded by gu delete the u (the gu need not be in RV)
        $word     =~ /gu$suffix$/
          ? $word =~ s/gu$suffix$/g/
          : $word =~ s/$suffix$//;
        print "Step 2b2: $word\n" if $DEBUG;
    }

    ############################################################
    ###########              Step 3                  ###########
    ############################################################
    # Residual suffix
    # Search for the longest among the following suffixes in RV, and
    # perform the action indicated.
    # Always do step 3.

    $RV = define_RV($word);

    if ( ($suffix) = $RV =~ /(os|[aoáíó])$/ ) {

        # os a o á í ó
        # delete if in RV
        $word =~ s/$suffix$//;
        print "Step 3a: $word\n" if $DEBUG;
    }
    elsif ( $RV =~ /[eé]$/ ) {

        # e é
        # delete if in RV, and if preceded by gu with the u in RV, delete the u.
        if ( $word =~ /gu[eé]$/ && $RV =~ /u[eé]$/ ) {
            $word =~ s/gu[eé]$/g/;
        }
        else {
            $word =~ s/[eé]$//;
        }
        print "Step 3b: $word\n" if $DEBUG;
    }
    print "Before step 4: $word\n" if $DEBUG;
    ############################################################
    ###########              Step 4                  ###########
    ############################################################
    # Remove the acute accents
    $word =~ s/á/a/g;
    $word =~ s/é/e/g;
    $word =~ s/í/i/g;
    $word =~ s/ó/o/g;
    $word =~ s/ú/u/g;
    print "Step 4: $word\n" if $DEBUG;

    return $word;
}

sub define_R1 {
    ############################################
    ########         Find R1         ###########
    ############################################
    # R1 is the region after the  first non-vowel following a vowel, 
    # or is the null region at the end of the word if there is 
    # no such non-vowel.
    my $word = shift;
    my $R1;
    ($R1) = $word =~ /^.*?$revowel$reconsonants(.*)$/;
    $R1 ||= '';
    print "R1: $R1\n" if $DEBUG;
    return $R1;
}

sub define_R2 {
    ############################################
    ########         Find R2         ###########
    ############################################
    # R2 is the region after the second non-vowel following a vowel, 
    # or is the null region at the end of the word if there is 
    # no such non-vowel.
    my $word = shift;
    my $R2;
    ($R2) = $word =~ /^.*?$revowel$reconsonants.*?$revowel$reconsonants(.*)$/;
    $R2 ||= '';
    print "R2: $R2\n" if $DEBUG;
    return $R2;
}

sub define_RV {
    ############################################
    ########          Find RV        ###########
    ############################################
    # RV is defined as follows:
    # If the second letter is a consonant, RV is the region 
    # after the next following vowel.
    # If the first two letters are vowels, RV is the region 
    # after the next consonant
    # If the first letter is a consonant and the second a vowel, 
    # RV is the region after the third letter
    # RV is the end of the word if these positions cannot be found.
    my $word = shift;
    my $RV;
    if ( $word =~ /^.$reconsonants.*?$revowel(.*)$/ ) {
        $RV = $1;
        print "$word -- RV: Case 1 '$RV'\n" if $DEBUG;
    }
    elsif ( $word =~ /^$revowel{2,}$reconsonants(.*)$/ ) {
        $RV = $1;
        print "$word -- RV: Case 2 '$RV'\n" if $DEBUG;
    }
    elsif ( $word =~ /^$reconsonants$revowel.(.*)$/ ) {
        $RV = $1;
        print "$word -- RV: Case 3 '$RV'\n" if $DEBUG;
    }
    else {
        $RV = '';
        print "$word -- RV: Case 4 '$RV'\n" if $DEBUG;
    }
    return $RV;
}

sub stem_caching {
    my $parm_ref;
    if ( ref $_[0] ) {
        $parm_ref = shift;
    }
    else {
        $parm_ref = {@_};
    }
    my $caching_level = $parm_ref->{-level};
    if ( defined $caching_level ) {
        if ( $caching_level !~ m/^[012]$/ ) {
            croak(  __PACKAGE__
                  . q{::stem_caching() - Legal values are '0','1' or '2'.}
                  . qq{ '$caching_level' is not a legal value) } );
        }
        $Stem_Caching = $caching_level;
    }
    return $Stem_Caching;
}

sub clear_stem_cache {
    $Stem_Cache = {};
}

1;
__END__

=head1 NAME

Lingua::Stem::Es - Perl Spanish Stemming

=head1 SYNOPSIS

    use Lingua::Stem::Es;

    my $stems = Lingua::Stem::Es::stem({ -words => $word_list_reference,
                                         -locale => 'es',
                                         -exceptions => $exceptions_hash,
                                      });

    my $stem = Lingua::Stem::Es::stem_word( $word );


=head1 DESCRIPTION

This module uses Porter's Stemming Algorithm to return an array reference of
stemmed words.

The algorithm is implemented as described in:

http://snowball.tartarus.org/algorithms/spanish/stemmer.html


The interface was made to follow the conventions set by the L<Lingua::Stem>
module by Benjamin Franz.
This spanish version is based on the work of Sébastien Darribere-Pleyt 
(French Version).

=head1 METHODS

=over

=item stem({ -words => \@words, 
                 -locale => 'es', 
                 -exceptions => \%exceptions });
                                                                                                 
Stems a list of passed words. Returns an anonymous list reference to the stemmed
words. Note that -locale is not necessary, as this module does not uses it and
it defaults to 'es' anyway. '\%exceptions' keys are words that should not be
processed, and the values of this hash are returned in the resulting array
reference.

Example:

    my $stemmed_words = Lingua::Stem::Es::stem({ 
        -words => \@words,
        -locale => 'es',
        -exceptions => \%exceptions,
    });

=item stem_word( $word );

Stems a single word and returns the stem directly.

Example:

    my $stem = Lingua::Stem::Es::stem_word( $word );

=item stem_caching({ -level => 0|1|2 });

Sets the level of stem caching.

'0' means 'no caching'. This is the default level.

'1' means 'cache per run'. This caches stemming results during a single
    call to 'stem'.

'2' means 'cache indefinitely'. This caches stemming results until
    either the process exits or the 'clear_stem_cache' method is called.

=item clear_stem_cache;

Clears the cache of stemmed words.

=back

=cut


=head1 SEE ALSO

You can see the Spanish stemming algorithm from Mr Porter here :

http://snowball.tartarus.org/algorithm/spanish/stemmer.html

I took from his site the voc.txt and output.txt files that are included in this
distribution, for testing. Those two files were released under the BSD License:
http://snowball.tartarus.org/license.php and are therefore bound to it.

=head1 AUTHOR

Julio Fraire, E<lt>julio.fraire@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2001, Dr Martin Porter L<http://snowball.tartarus.org/>

Copyright (C) 2004 by Sébastien Darribere-Pleyt <sebastien.darribere@lefute.com>

Copyright (C) 2008 by Julio Fraire, <julio.fraire@gmail.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

