package Lingua::Norms::SUBTLEX;
use 5.12.0;
use strict;
use warnings FATAL => 'all';
use base qw(Lingua::Orthon);
use Config;
use Carp qw(carp croak);

#use Encode qw(encode decode);
#use Encode::Guess;
use English '-no_match_vars';
use File::Spec;
use List::AllUtils qw(all any first firstidx none uniq);
use Number::Misc qw(is_numeric);
use Path::Tiny;
use Readonly;
use Statistics::Lite qw(count max mean median stddev sum);
use String::Trim qw(trim);
use String::Util qw(hascontent crunch fullchomp nocontent unquote);
use Text::CSV::Hashify;
use Text::CSV::Separator qw(get_separator);
use Text::Unidecode;

#use open ':encoding(utf8)';

$Lingua::Norms::SUBTLEX::VERSION = '0.06';

=pod

=encoding utf8

=head1 NAME

Lingua::Norms::SUBTLEX - Retrieve word frequencies and related values and lists from subtitles corpora

=head1 VERSION

This is documentation for B<Version 0.06> of Lingua::Norms::SUBTLEX.

=head1 SYNOPSIS

 use Lingua::Norms::SUBTLEX 0.06;
 my $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'UK');
 
 # Is the string 'frog' in the subtitles corpus?
 my $bool = $subtlex->is_normed(string => 'frog');

 # Occurrences-per-million:
 # - for a single string:
 my $frq = $subtlex->frq_opm(string => 'frog'); # freq. per million; also count, log-f, Zipf

 # - for a list of strings: 
 my $href = $subtlex->frq_hash(strings => [qw/frog fish ape/]); # freqs. for a list of words
 print "'$_' opm\t$href->{$_}\n" for keys %{$href};

 # stats:
 printf "mean opm\t%f\n", $subtlex->frq_mean(strings => [qw/frog fish ape/]); # or median, std-dev.
 
 # parts-of-speech:
 printf "'frog' part-of-speech = %s\n", $subtlex->pos_dom(string => 'frog');
 
 # retrieve (list of) words to certain specs, e.g., min/max range:
 my $aref = $subtlex->select_words(freq => [2, 400], length => [4, 4], cv_pattern => 'CCVC', regex => '^f');
 printf "Number of 4-letter CCVC strings with 2-400 opm starting with 'f' = %d\n", scalar @{$aref};

 printf "A randomly selected subtitles string is '%s'\n", $subtlex->random_string();

=head1 DESCRIPTION

This module facilitates access to corpus frequency and other lexical attributes of character strings (generally, words), as provided in the various SUBTLEX and related projects (see L<REFERENCES|Lingua::Norms::SUBTLEX/REFERENCES>) on the basis of the representation of these strings in film and television subtitles (see L<www.opensubtitles.org|http://www.opensubtitles.org>). Word frequencies obtained in this way have been shown to be generally more predictive of performance in word recognition tasks than frequencies derived from books, newsgroup posts, and similar sources (but see Herdagdelen & Marelli, 2017).

There are three main groups of measures that are potentially retrievable from the SUBTLEX datatables: (1) frequency; (2) contextual diversity (number of films/TV episodes appeared in); and (3) parts-of-speech. The module tries to uniformly offer, across the available files, frequency as a count (L<frq_count|Lingua::Norms::SUBTLEX/frq_count>), occurrences per million (L<frq_opm|Lingua::Norms::SUBTLEX/frq_opm>), logarithm of the opm or frequency count (L<frq_log|Lingua::Norms::SUBTLEX/frq_log>), and/or the 7-point scaled Zipf frequency (L<frq_zipf|Lingua::Norms::SUBTLEX/frq_zipf>). "Contextual diversity" is given as a count (L<cd_count|Lingua::Norms::SUBTLEX/cd_count>), a percentage (L<cd_pct|Lingua::Norms::SUBTLEX/cd_pct>), and/or a logarithm (L<cd_log|Lingua::Norms::SUBTLEX/cd_log>). For parts-of-speech, the module returns, via L<pos_dom|Lingua::Norms::SUBTLEX/pos_dom>, the dominant linguistic syntactical role of the word, as well as all defined parts-of-speech for a word (via L<pos_all|Lingua::Norms::SUBTLEX/pos_all>).

However, not all these methods are available across all projects; e.g., SUBTLEX-NL does not define Zipf frequency, and SUBTLEX-DE does not define CD, POS or Zipf frequency. In these cases, the method in question will return an empty string.

=head1 CORPORA SPECS and SOURCES

The SUBTLEX files need to be downloaded via the URLs shown in the table below (only a small sample from each of each of the SUBTLEX corpora is included in the installation distribution for testing purposes). So, for example, for the I<American> norms, install the file named "SUBTLEX-US frequency list with PoS and Zipf information.csv" via L<ugent.be/pp/experimentele-psychologie/|http://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexus/overview.htm>.

The local directory location or actual pathname of these files can be given in class construction (by the arguments B<dir> and B<path>, respectively); or it will be sought from the default location--within the directory "SUBTLEX" alongside the module itself in the locally configured Perl sitelib--given the B<lang> argument to L<new()|Lingua::Norms:SUBTLEX/new>, or to L<set_lang()||Lingua::Norms:SUBTLEX/set_lang>. The filenames of the original files downloaded from the following sites should be found in this way, but it should uniquely include the "key" shown in the table. The module will attempt to identify the correct field separator for the file (which can be comma-separated or tab-delimited). Only the files specified in the table are likely to be reliably accessed at this time.

=for html <p>&nbsp;&nbsp;<table style="font-size:x-small;" align="center">
<tr><th>Language</th><th>Key</th><th>URL</th><th>File</th></tr>
<tr><td>Dutch</td><td>NL_all</td><td><a href="http://crr.ugent.be/programs-data/subtlex-nl">crr.ugent.be</a></td><td>SUBTLEX-NL.with-pos.txt</td></tr>
<tr><td>&nbsp;</td><td>NL_min</td><td><a href="http://crr.ugent.be/programs-data/subtlex-nl">crr.ugent.be</a></td><td>SUBTLEX-NL.cd-above2.with-pos.txt</td></tr>
<tr><td>English (American)</td><td>US</td><td><a href="http://www.ugent.be/pp/experimentele-psychologie/en/research/documents/subtlexus/overview.htm">expsy.ugent.be/subtlexus</a></td><td>SUBTLEX-US frequency list with PoS and Zipf information.csv</td>
</tr>
<tr><td>English (British)</td><td>UK</td><td><a href="http://www.psychology.nottingham.ac.uk/subtlex-uk/">psychology.nottingham.ac.uk</a></td><td>SUBTLEX-UK.txt</td></tr>
<tr><td>French</td><td>FR</td><td><a href="http://www.lexique.org/public/">lexique.org</a></td><td>Lexique381.txt</td></tr>
<tr><td>German</td><td>DE</td><td><a href="http://crr.ugent.be/archives/534">crr.ugent.be</a></td><td>SUBTLEX-DE_cleaned_with_Google00.txt</td></tr>
<tr><td>Portuguese</td><td>PT</td><td><a href="http://p-pal.di.uminho.pt/about/database">p-pal.di.uminho.pt</a></td><td>SUBTLEX-PT_Soares_et_al._QJEP.csv</td></tr>
</table></p>

Notes regarding these different corpora.

=over 4

=item * SUBTLEX-DE

The file has separate entries for words starting with an uppercase and a lowercase letter (e.g., for when a letter-string is both a noun and an adjective).

=item * Lexique (SUBTLEX-FR)

If not giving the full path to this file, it should be renamed to include "FR" (e.g., "FR_Lexique.csv") and stored in the default directory. The file also includes frequencies from books.

=item * SUBTLEX-PT

The I<Portuguese> subtitles data are available as an Excel file (directly from L<here|http://p-pal.di.uminho.pt/static/files/db/SUBTLEX-PT_Soares_et_al._QJEP.xlsx>). This file needs to be saved as a (csv) text file to be usable here.

=item * SUBTLEX-UK

Includes words that might be spelled with a dash both with a dash and without; so there are separate entries for I<x-ray> and I<xray>, and for I<no-one> and I<noone>. It includes some strings with apostrophes (e.g., I<howe'er>, I<k'nex>); but common contractions like I<he's>, I<isn't> and I<ain't> do not appear; they are stripped of their apostrophes, listed, e.g., as I<hes>, I<isnt> and I<aint>. All strings are in lower-case; so I<Africa> is represented as I<africa>.

=item * SUBTLEX-US

There are no strings with capitalized onsets in this file, or with punctuation marks, including apostrophes and dashes (e.g., I<Aaron> and I<Freudian> are represented as I<aaron> and I<freudian>; I<you've> as I<youve>, and I<x-ray> as I<xray>). 

The earlier, original file "SUBTLEXusExcel2007.csv" presents strings as they were originally capitalised: there is, e.g., I<Aaron> and I<Hawkeye>--but neither I<aaron> nor I<hawkeye>. This file does not provide part-of-speech or Zipf frequencies.

=back

There are several other languages from this project which might be supported by this module in a later version (originally, only SUBTLEX-US was supported).

See the new() method as to how this module handles case-sensitivity and diacritical marks. For files where strings are UTF-8 encoded, the strings being looked up should also be UTF-8 encoded (if they are diacritically marked, e.g. "embâcle")(see L<Encode|Encode>).

If using Miscrosoft Excel to save any of these files, even if in CSV format, Excel will turn the words "true" and "false" into the Boolean strings "TRUE" and "FALSE", as well as throw them aside from alphabetic sorting (right down to the bottom of an alphabetic sort). That will surely stuff up any neatly intended pattern-matching for these words.

=head1 SUBROUTINES/METHODS

All methods are called via the class object, and with named (hash of) arguments, usually B<string>, where relevant.

=head2 new

 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'DE'); # - looking in Perl sitelib
 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'DE', dir => 'file_directory'); # folder in which file is located
 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'DE', path => 'file/is/here.csv'); # complete path to file for given language

Returns a class object for accessing other methods. The argument B<lang> is required, specifying the particular language datafile by a "key" as given in the above table. Optional arguments B<dir> or B<path> can be given to specify the location or filepath of the database. The default location is the "Lingua/Norms/SUBTLEX" directory within the 'sitelib' configured for the local Perl installation (as per L<Config.pm|Config>). The method will C<croak> if the file cannot be found.

The optional argument B<match_level> specifies how string comparison, as when looking up a given word in the SUBTLEX corpus, should be conducted, with the function used to test string equality being derived from the C<eq> function in L<Unicode::Collate|Unicode::Collate> (part of the standard Perl distribution). This matching level applies to the look-up of strings within all methods, including those specifically assessing orthographic equality. This argument can take one of three values: see L<set_eq|Lingua::Norms::SUBTLEX/set_eq>:

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, ref($class) ? ref($class) : $class;
    $self->{'_MODULE_DIR'} =
      File::Spec->catdir( $Config{'sitelib'}, qw/Lingua Norms SUBTLEX/ );
    $self->_set_spec_hash( $args{'fieldpath'} );
    $self->set_lang(%args);
    $self->set_eq( match_level => $args{'match_level'} );

    #_set_encoding($args{'decode'});
    return $self;
}

=head2 Frequencies and POS for individual words or word-lists

=head3 is_normed

 $bool = $subtlex->is_normed(string => $word);

I<Alias>: isa_word

Returns 1 or 0 as to whether or not the letter-string passed as B<string> is represented in the subtitles file. For some files, this might be thought of as a lexical decision ("does this string spell a word?"); but others include misspelled words (e.g., "pyscho"), digit strings, abbreviations ...

=cut

sub is_normed {
    my ( $self, %args ) = @_;
    my $str = _get_usr_str( $args{'string'} );
    my $res = 0;                               # boolean to return from this sub
    open my $fh, q{<}, $self->{'_PATH'} or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;       # skip headings
        my $file_str = _get_file_str( $_, $self->{'_DELIM'} )
          ;    # have to declare as can be empty (!)
        next if nocontent($file_str);
        if ( $self->{'_EQ'}->( $str, $file_str ) )
        {      # first token equals given string?
            $res = 1;    # set result to return as true
            last;        # got it, so abort look-up
        }
    }
    close $fh or croak $OS_ERROR;
    return $res;         # zero if string not found in file
}
*isa_word = \&is_normed;

=head3 frq_count

 $int = $subtlex->frq_count(string => 'aword');

Returns the raw number of occurrences in all the films/TV episodes for the word passed as B<string>, or 0 if the string is not found in language file.

=cut

sub frq_count {
    my ( $self, %args ) = @_;
    return _val_or_0(
        _get_val_for_str(
            _get_usr_str( $args{'string'} ),
            $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'frq_count_idx' ),
            map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
        )
    );
}

=head3 frq_opm

 $val = $subtlex->frq_opm(string => 'aword');

I<Alias>: opm

Returns frequency per million for the word passed as B<string>, or 0 if the string is not found in language file.

=cut

sub frq_opm {
    my ( $self, %args ) = @_;
    return _val_or_0(
        _get_val_for_str(
            _get_usr_str( $args{'string'} ),
            $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'frq_opm_idx' ),
            map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
        )
    );
}
*freq = \&frq_opm;    # legacy only

=head3 frq_log

 $val = $subtlex->frq_log(string => 'aword');

Returns log frequency per million for the word passed as B<string>, or the empty-string if the string is not represented in the norms.

=cut

sub frq_log {
    my ( $self, %args ) = @_;
    return _get_val_for_str(
        _get_usr_str( $args{'string'} ),
        $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'frq_log_idx' ),
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
    );
}
*lfreq = \&frq_log;    # legacy only

=head3 frq_zipf

 $val = $subtlex->frq_zipf(string => 'aword');

Returns Zipf frequency for the word passed as B<string>, or the empty-string if the string is not represented in the language file. The Zipf scale ranges from about 1 to 7, with values of 1-3 generally representing low frequency words, and values of generally 4-7+ representing high frequency words, with respect to various recognition measures used in the study of word frequency effects. See Van Heuven et al. (2014) and L<crr.ugent.be/archives|http://crr.ugent.be/archives/1352> for more information.

=cut

sub frq_zipf {
    my ( $self, %args ) = @_;
    return _get_val_for_str(
        _get_usr_str( $args{'string'} ),
        $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'frq_zipf_idx' ),
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
    );
}
*zipf = \&frq_zipf;    # legacy only

=head3 frq_zipf_calc

 $calc = $subtlex->frq_zipf_calc( string => 'favourite' );
 $calc = $subtlex->frq_zipf_calc( string => 'favourite', corpus_size => POS_FLOAT_in_millions, n_wordtypes => POS_INT );

Returns an estimate of Zipf frequency by calculating its value from the given or retrievable L<frq_count|Lingua::Norms::SUBTLEX/frq_count> or L<frq_opm|Lingua::Norms::SUBTLEX/frq_opm>, and the given or retrievable values of the corpus_size and n_wordtypes for the particular SUBTLEX project; i.e., the values of corpus_size and n_wordtypes can be provided as named arguments. As introduced by Van Heuven et al. (2014) (see also L<crr.ugent.be/archives|http://crr.ugent.be/archives/1352>):

=for html <p>&nbsp;&nbsp;Zipf = log<sub>10</sub>[ ( frq_count + 1 ) / ( corpus_size + n_wordtypes )/1000000 ] + 3</p>

How well the returned value satisfies the "border relations" desired of the index (e.g., that up to 1 opm corresponds to Zipf of E<lt> 3) depends on the reliability of the corpus size and wordtype counts, and any rounding of these values (where relevant) and (if required) of the opm. Examinations of the returned values show that, when using the canned and reported values (which is the default here), they align with these definitions, and with any canned Zipf values, within the margins of about the third or fourth decimal place.

=cut

sub frq_zipf_calc {
    my ( $self, %args ) = @_;
    my $corpus_size =
      defined $args{'size_corpus'}
      ? $args{'size_corpus'}
      : $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'size_corpus_mill' );
    my $n_wordtypes =
      defined $args{'n_wordtypes'}
      ? $args{'n_wordtypes'}
      : $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'n_wordtypes' );

    $n_wordtypes /= 1_000_000;

    my $frq_count =
      is_numeric( $args{'frq_count'} )
      ? $args{'frq_count'}
      : is_numeric( $args{'frq_opm'} ) ? sprintf "%.0f",
      $args{'frq_opm'} * $corpus_size : eval { $self->frq_count(%args) };

    if ($EVAL_ERROR or not is_numeric($frq_count) ) {
        my $frq_opm = eval { $self->frq_opm(%args) };
        if (not $EVAL_ERROR and is_numeric($frq_opm) ) {
            $frq_count = sprintf "%.0f", $frq_opm * $corpus_size;
        }
    }
    $frq_count ||= 0;

    return _log10( ( 1 + $frq_count ) / ( $corpus_size + $n_wordtypes ) ) + 3;

}

=head3 frq_opm2count

 $int = $subtlex->frq_opm2count(string => STRING);

Returns the raw number of occurrences of a string (the frq_count) based on the number of occurrences per million (frq_opm), and the corpus size in millions. Returns 0 if the string is not found in language file.

The B<frq_opm> can be given as a named argument, or it will be retrieved by the L<frq_opm|Lingua::Norms::SUBTLEX/frq_opm> respective method, where this is defined for a particular language file. The B<corpus_size> (in millions) can also be given as a named argument, or it will be retrieved from the specifications file (specs.csv in the module's directory), where this value has been obtainable from published reports.

=cut

sub frq_opm2count {
    my ( $self, %args ) = @_;
    my $frq_opm =
      defined $args{'frq_opm'} ? $args{'frq_opm'} : $self->frq_opm(%args);
    my $corpus_size =
      defined $args{'size_corpus'}
      ? $args{'size_corpus'}
      : $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'size_corpus_mill' );
    return sprintf "%.0f", $frq_opm * $corpus_size;
}

=head3 cd_count

 $cd = $subtlex->cd_count(string => STRING);

Returns the number of samples (films/TV episodes) comprising the corpus in which the string occurred in its subtitles; so-called "contextual diversity". Returns 0 if the string is not found in language file.

=cut

sub cd_count {
    my ( $self, %args ) = @_;
    return _val_or_0(
        _get_val_for_str(
            _get_usr_str( $args{'string'} ),
            $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'cd_count_idx' ),
            map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
        )
    );
}

=head3 cd_pct

 $cd = $subtlex->cd_pct(string => 'aword');

Returns a percentage measure for the number of samples (films/TV episodes) comprising the corpus in which the B<string> occurred in its subtitles; so-called "contextual diversity".  Returns 0 if the string is not found in language file.

=cut

sub cd_pct {
    my ( $self, %args ) = @_;
    return _val_or_0(
        _get_val_for_str(
            _get_usr_str( $args{'string'} ),
            $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'cd_pct_idx' ),
            map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
        )
    );
}

=head3 cd_log

 $cd = $subtlex->cd_log(string => 'aword');

Returns log10(L<cd_pct|Lingua::Norms::SUBTLEX/cd_pct> + 1) for the given string, with 4-digit precision. Note: Brysbaert and New (2009) state that "this is the best value to use if one wants to match words on word frequency" (p. 988).

=cut

sub cd_log {
    my ( $self, %args ) = @_;
    return _get_val_for_str(
        _get_usr_str( $args{'string'} ),
        $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'cd_log_idx' ),
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
    );
}

=head3 pos_dom

 $pos_str = $subtlex->pos_dom(string => STRING, conform => BOOL);

Returns the dominant part-of-speech for the given string. The return value is undefined if the string is not found. If the field in the original file (as in SUBTLEX-PT) is actually for all possible parts-of-speech, the first element in the returned string (once split by non-word characters), is returned (assuming, as in SUBTLEX-PT) that this is indeed the most frequent part-of-speech for the particular string.

For interpretation of the POS codes: for NL, see L<crr.ugent.be/archives/362|http://crr.ugent.be/archives/362> ("SPEC" is there defined as "often personal or geographical names" and so similar to "Name" in SUBTLEX-UK).

To transliterate the various codes into a common two-letter code, then set B<conform> => 1 (default is not defined, returning the POS string as given in the original files). The two-letter codes are:

 NN noun (common)
 NM name (proper)
 PN pronoun
 VB verb
 AJ adjective
 AV adverb
 PP proposition
 CJ conjunction
 IJ interjection
 DA determiner or article
 NB number
 OT other
 UK unknown

The "OT" code includes some rare POS values (e.g., "marker", "ONO"), anomalous values (e.g., "2"), and values not defined in the associated reports. The "UK" code ("unknown") is comprised of values specifically recorded as "unclassified" or similar, or where the POS field is empty.

=cut

sub pos_dom {
    my ( $self, %args ) = @_;
    my $str = _get_val_for_str(
        _get_usr_str( $args{'string'} ),
        $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'pos_dom_idx' ),
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
    );
    my @ari = map { trim($_) } grep { hascontent($_) } split /[\W]/xsm, $str;
    return $args{'conform'}
      ? _pos_is( $ari[0], $self->{'_FIELDS'}, $self->{'_LANG'} )->[0]
      : $ari[0];
}
*pos = \&pos_dom;

=head3 pos_all

 $pos_aref = $subtlex->pos_all(string => STRING, conform => BOOL);

Returns all parts-of-speech for the given string as a referenced array. The return value is an empty list if the string is not found. If the language file does not define this field, the returned value is simply the same as what would, if possible, be returned from L<pos_dom|Lingua::Norms::SUBTLEX/pos_dom> (i.e., if that value is defined), but now as a referenced array.

=cut

sub pos_all {
    my ( $self, %args ) = @_;
    my $str = _get_val_for_str(
        _get_usr_str( $args{'string'} ),
        $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'pos_all_idx' ),
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/)
    );

  # grep to ensure no empty values as might come from a head/trailing delimiter:
    my @ari = map { trim($_) } grep { hascontent($_) } split /[\W]/xsm, $str;
    return $args{'conform'}
      ? [ map { @{ _pos_is( $_, $self->{'_FIELDS'}, $self->{'_LANG'} ) } }
          @ari ]
      : \@ari;
}

=head2 Multiple strings/values lists

Array given as measures to the following methods might include one or more of the following:

 frq_count
 frq_opm
 frq_log
 frq_zipf
 cd_count
 cd_pct
 cd_log
 pos_dom
 pos_all

=head3 values_list

 $aref = $subtlex->values_list(string => STRING, values => AREF);

Returns values for a single letter-string as a referenced array.

=cut

sub values_list {
    my ( $self, %args ) = @_;
    my @idx_ari;
    if ( ref $args{'values'} ) {
        for my $field ( @{ $args{'values'} } ) {
            push @idx_ari,
              $self->{'_FIELDS'}->datum( $self->{'_LANG'}, $field . '_idx' );
        }
    }
    return _get_val_for_strs( _get_usr_str( $args{'string'} ),
        \@idx_ari, map { $self->{$_} } (qw/_PATH _DELIM _EQ/) );
}

=head3 multi_list

 $hashref = $subtlex->multi_list(strings => AREF_of_char_strings, measures => AREF_of_FIELD_NAMES);

 $frq_hashref = $subtlex->multi_list(strings => [qw/ICH PEA CHOWDER ZEER AIME/], measures => [qw/frq_opm frq_zipf/]);
    # $frq_hashref = { 
    #        ICH => {
    #            frq_opm => 20000,
    #            frq_zipf => 7.01,
    #        },
    #        PEA => {
    #            frq_opm ...
    #        },
    #        ...
    #    }

Returns multiple values for a list of strings as a hashref of hashrefs. This is perhaps the most efficient method here for retrieving several values for several words, but only for a small number of words; it could take a long time to return given large lists.

So, given one or more words in the array ref B<strings>, and several measures/values to find for each of them (such as 'frq_opm', 'pos_dom' or any other values defined for the particular language file) in the the array B<measures>, the method looks line-by-line through the file to check if the line's string is equal to any of those in B<strings>. If so, it collates the relevant measures in a hash keyed by the string, whose values are themselves a hash of the measure-names keying each respective measure-value. The found string is then removed from the look-up list, and the next line is looked-up in the same way. The search stops as soon as there are no more strings in the look-up list (all have been found).

In this way, there is only one pass through the file for the entire search; no line is looked-up more than once for all strings or their respective measure values. The method could be used for looking up a single string and/or a single value, but the other methods for doing this avoid the overhead of checking an array of strings, and splitting the line against the delimiter; this is only done here to facilitate caching multiple values whereas other methods avoid doing this as they only need to find one value after a known number of delimiters.

=cut

sub multi_list {
    my ( $self, %args ) = @_;
    croak 'Need a referenced list of strings to look up'
      if !ref $args{'strings'};
    my @strings = map { _get_usr_str($_) } @{ $args{'strings'} };
    my %idx_hash = ();
    if ( ref $args{'measures'} ) {
        for my $field ( @{ $args{'measures'} } ) {
            my $idx =
              $self->{'_FIELDS'}->datum( $self->{'_LANG'}, $field . '_idx' );
            if ( nocontent($idx) ) {
                next;

#    croak "The requested value '$field' is not defined for the current SUBTLEX file";
            }
            $idx_hash{$idx} = $field;
        }
    }
    return _get_any_vals_for_string_list( [@strings], \%idx_hash,
        map { $self->{$_} } (qw/_PATH _DELIM _EQ/) );
}

=head2 Descriptive frequency statistics for lists

These methods return a descriptive statistic (sum, mean, median or standard deviation) for a list of B<strings>. Like L<freqhash|Lingua::Norms::SUBTLEX/freqhash>, they take an optional argument B<scale> to specify if the returned values should be occurrences per million, log frequencies, or Zipf values. Providing this as an argument obviates the need to provide multiple methods for each different type of frequency measure, e.g., "mean_opm()", mean_log_opm()", ...

Because not all types of frequency scales (count, opm, log, Zipf) are provided in all SUBTLEX corpora, these methods will C<croak> if there are no canned stats for the particular scale called for.

It might be thought useful to allow any valid scale to be returned by, say, providing each method without a value for B<scale>; a hash-ref of frequency values, keyed by scale-type, might be returned. However, this seems to be unrecommended; it assumes that users are blind as to what measures they want (as well as to what they can get).

=head3 frq_sum

 $sum = $subtlex->frq_sum(strings => [qw/word1 word2/], scale => 'count|opm|log|zipf');

Returns the sum of the count, opm, log (usually opm) or Zipf frequency, depending on the value of B<scale>.

=cut

sub frq_sum {
    my ( $self, %args ) = @_;
    return sum( $self->_frq_vals(%args) );
}

=head3 frq_mean

 $mean = $subtlex->frq_mean(strings => [qw/word1 word2/], scale => 'count|opm|log|zipf');

Returns the arithmetic average of the count, opm, log (usually opm) or Zipf frequency, depending on the value of B<scale>.

=cut

sub frq_mean {
    my ( $self, %args ) = @_;
    return mean( $self->_frq_vals(%args) );
}
*mean_freq = \&frq_mean;

=head3 frq_median

 $median = $subtlex->frq_median(strings => [qw/word1 word2/], scale => 'count|opm|log|zipf');

Returns the median count, opm, log (usually opm) or Zipf frequency for the given B<strings>, depending on the value of B<scale>.

=cut

sub frq_median {
    my ( $self, %args ) = @_;
    return median( $self->_frq_vals(%args) );
}
*median_freq = \*frq_median;

=head3 frq_sd

 $sd = $subtlex->frq_sd(strings => [qw/word1 word2/], scale => 'count|opm|log|zipf');

Returns the standard deviation of the count, opm, log (usually opm) or Zipf frequency, depending on the value of B<scale>.

=cut

sub frq_sd {
    my ( $self, %args ) = @_;
    return stddev( $self->_frq_vals(%args) );
}
*sd_freq = \*frq_sd;

sub _frq_vals {
    my ( $self, %args ) = @_;
    croak
'No string(s) to test; pass one or more letter-strings named \'strings\' as a referenced array'
      if !$args{'strings'};
    my $strs =
      ref $args{'strings'}
      ? $args{'strings'}
      : croak 'No reference to an array of letter-strings found';
    my $col_i =
      hascontent( $args{'scale'} )
      ? $self->{'_FIELDS'}
      ->datum( $self->{'_LANG'}, 'frq_' . $args{'scale'} . '_idx' )
      : $self->{'_FIELDS'}->datum( $self->{'_LANG'}, 'frq_opm_idx' );
    my @vals = ();
    for my $str ( @{$strs} ) {
        push @vals,
          _get_val_for_str( _get_usr_str($str), $col_i,
            map { $self->{$_} } (qw/_PATH _DELIM _EQ/) );
    }
    return @vals;
}

=head2 Retrieving letter-strings/words

=head3 select_strings

 $aref = $subtlex->select_strings(frq_opm => [1, 20], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');
 $aref = $subtlex->select_strings(frq_zipf => [0, 2], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');

I<Alias>: select_words

Returns a list of strings (presumably words) from the SUBTLEX corpus that satisfies certain criteria, as per the following arguments:

=over 2

=item length

minimum and/or maximum length of the string (or "letter-length")

=item frq_opm, frq_log, cd_count, etc.

minimum and/or maximum frequency (as given in whatever unit offered by the datafile for the set language)

=item cv_pattern

a consonant-vowel pattern, given as a string by the usual convention, e.g., 'CCVCC' defines a 5-letter word starting and ending with pairs of consonants, the pairs separated by a vowel. 'Y' is defined here as a consonant. The tested strings are stripped of marks and otherwise ASCII transliterated (using L<Text::Unidecode|Text::Unidecode>) ahead of the check.

=item regex

a regular expression (L<perlretut|perlretut>). In the examples above, only letter-strings starting with the letter 'f', followed by one of more other letters, are specified for retrieval. Alternatively, for example, the regex value '[^aeiouy]$' specifies that the letter-strings to be returned must not end with a vowel (or 'y'). The tested strings are stripped of marks and otherwise ASCII transliterated (using L<Text::Unidecode|Text::Unidecode>) ahead of matching, so if the string in the file has, say, a 'u' with an Umlaut, it will match a 'u' in the regex.

=back

For the minimum/maximum constrained criteria, the two limits are given as a referenced array where the first element is the minimum and the second element is the maximum. For example, [3, 7] would specify letter-strings of 3 to 7 letters in length; [4, 4] specifies letter-strings of only 4 letters in length. If only one of these is to be constrained, then the array would be given as, e.g., [3] to specify a minimum of 3 letters without constraining the maximum, or ['',7] for a maximum of 7 letters without constraining the minimum (checking if the element C<hascontent> as per String::Util).

The value returned is always a reference to the list of words retrieved (or to an empty list if none was retrieved).

Calling this method as "list_strings" or "list_words" is deprecated; to avoid confusion with L<all_strings|Lingua::Norms::SUBTLEX/all_strings>, which also returns a list of strings. A deprecation warning and wrap to the method is in place as of version 0.06 if using this name; they will be removed in a subsequent version.

=cut

sub select_strings {
    my ( $self, %args ) = @_;
    my %patterns = ();
    if ( hascontent( $args{'regex'} ) ) {
        $patterns{'regex'} = qr/$args{'regex'}/xms;
    }
    if ( hascontent( $args{'cv_pattern'} ) ) {
        my $tmp = q{};
        my @c = split m//ms, uc( $args{'cv_pattern'} );
        foreach (@c) {
            $tmp .= $_ eq 'C' ? '[BCDFGHJKLMNPQRSTVWXYZ]' : '[AEIOU]';
        }
        $patterns{'cv_pattern'} = qr/^$tmp$/ixms;
    }

    my @list = ();
    open my $fh, q{<}, $self->{'_PATH'} or croak $OS_ERROR;
  LINES:
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        my @line = split m/\Q$self->{'_DELIM'}\E/xms;
        next if !_in_range( length( $line[0] ), @{ $args{'length'} } );
        for ( keys %patterns ) {
            next LINES if unidecode( $line[0] ) !~ $patterns{$_};
        }
        for (qw/frq_count frq_opm frq_log frq_zipf cd_count cd_pct cd_log/) {
            if (
                ref $args{$_}
                and hascontent(
                    $self->{'_FIELDS'}->datum( $self->{'_LANG'}, $_ . '_idx' )
                )
              )
            {
                next LINES
                  if !_in_range(
                    _clean_value(
                        $line[
                          $self->{'_FIELDS'}
                          ->datum( $self->{'_LANG'}, $_ . '_idx' )
                        ]
                    ),
                    @{ $args{$_} }
                  );
            }
        }
        if ( ref $args{'pos'} ) {
            next LINES
              if none {
                $_ eq $line[ $self->{'_FIELDS'}
                  ->datum( $self->{'_LANG'}, 'pos_dom_idx' ) ]
            }
            @{ $args{'pos'} };
        }
        push @list, $line[0];
    }
    close $fh or croak $OS_ERROR;

    return \@list;
}
*select_words = \&select_strings;

=head3 all_strings

 $aref = $subtlex->all_strings();

I<Alias>: all_words

Returns a reference to an array of all letter-strings in the corpus. These are culled of empty and duplicate strings, and then alphabetically sorted.

=cut

sub all_strings {
    my ( $self, %args ) = @_;
    my @list = ();
    open my $fh, q{<}, $self->{'_PATH'} or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        push @list, _get_file_str( $_, $self->{'_DELIM'} );
    }
    close $fh or croak $OS_ERROR;
    return [ sort { lc($a) cmp lc($b) } uniq( grep { hascontent($_) } @list ) ];
}
*all_words = \&all_strings;

=head3 random_string

 $string = $subtlex->random_string();
 @data = $subtlex->random_string();

I<Alias>: random_word

Picks a random line from the corpus, using L<File::RandomLine|File::RandomLine> (except the top header line). Returns the word in that line if called in scalar context; otherwise, the array of data for that line. (A future version might let specifying a match to specific criteria, self-aborting after trying X lines.)

=cut

sub random_string {
    my ( $self, %args ) = @_;
    eval { require File::RandomLine; };
    croak 'Need to install and access module File::RandomLine' if $EVAL_ERROR;
    my $rl =
      File::RandomLine->new( $self->{'_PATH'}, { algorithm => 'uniform' } );
    my @ari = ();
    while ( not scalar @ari or $ari[0] eq 'Word' ) {
        @ari = split m/\Q$self->{'_DELIM'}\E/xms, $rl->next;
    }
    return wantarray ? @ari : $ari[0];
}
*random_word = \&random_string;

=head2 Miscellaneous

=head3 n_lines

 $num = $subtlex->n_lines();

Returns the number of lines, less the column headings and any lines with no content, in the installed language file. Expects/accepts no arguments.

=cut

sub n_lines {
    my $self = shift;
    my $z    = 0;
    open( my $fh, q{<}, $self->{'_PATH'} ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        next if nocontent($_);
        $z++;
    }
    close $fh or croak $OS_ERROR;
    return $z;
}
*nlines = \&n_lines;                        # legacy alias

=head3 pct_alpha

Returns the percentage of strings in the subtitles file that satisfy "look like words" relative to the number of lines (as per L<n_lines|Lingua::Norms::SUBTLEX/n_lines>). Specifically, after ASCII transliteration of the string (per L<Text::Unidecode|Text::Unidecode>), does it match to /[\p{XPosixAlpha}\-']/ (per L<perluniprops|perluniprops/Properties accessible through \p{} and \P{}>, but including apostrophes and dashes)?

=cut

sub pct_alpha {
    my ( $self, %args ) = @_;
    my $all_strs_aref = $self->all_strings();
    my $count_all     = count( @{$all_strs_aref} );
    my $pct           = q{};
    if ( $count_all > 0 ) {
        my $count_alpha_strings = count( grep { m/[\p{XPosixAlpha}\-']/xsm }
              map { unidecode($_) } @{$all_strs_aref} );
        $pct = 100 * $count_alpha_strings / $count_all;
    }
    return $pct;
}

=head3 set_lang

 $lang = $subtlex->set_lang(lang => STR); # DE, FR, NL_all, NL_min, PT, UK or US
 $lang = $subtlex->set_lang(lang => STR, path => 'this/is/the/file.csv');
 $lang = $subtlex->set_lang(lang => STR, dir => 'file/is/in/here');

Set or guess location of datafile; see L<new|Lingua::Norms::SUBTLEX/new>. Naturally, the given value of B<lang> (required)--which is used as a database ID--should correspond with any given B<path> to the SUBTLEX datafile (optional but recommended). If only a B<dir> value is given, the SUBTLEX datafile should be named so that it uniquely includes the specific value of B<lang>.

=cut

sub set_lang {
    my ( $self, %args ) = @_;
    ## firstly, establish the language to use, and the directory in which this module lives:
    return if nocontent($args{'lang'});
    #@ is the complete pathname actually given in args?
    croak 'Need a valid <lang> attribute' if not ref $self->{'_FIELDS'}->record( $args{'lang'} );
    
    $self->{'_LANG'} = delete $args{'lang'};

    if ( hascontent( $args{'path'} ) ) {
        if ( !-e $args{'path'} ) {
            croak
              "Path given for SUBTLEX corpus does not exist: '$args{'path'}'";
        }
        else {
            $self->{'_PATH'} = delete $args{'path'};
        }
    }
    else {
        my ( $lang, $dir, $path ) = ( $self->{'_LANG'} );
        if ( $args{'dir'} ) {    # check it's a dir:
            croak "Value for argument 'dir' ($args{'dir'}) is not a directory"
              if !-d $args{'dir'};
            $dir = delete $args{'dir'};
        }
        else {                   # use module's dir :
            $dir = $self->{'_MODULE_DIR'};
        }
        for ( path($dir)->children ) {
            if (/(?:SUBTLEX[\-_])?\Q$lang/imsx) {
                $path = $_;
                last;
            }
        }
        if ( nocontent($path) or not -T $path )
        {                        # only already defined if it exists
            croak
"Cannot find required SUBTLEX datafile for language '$self->{'_LANG'}' within '$dir'.\nInstall the database (from the URL given in the POD) into either:\n\t(1) the Lingua/Norms/SUBTLEX directory within your Perl distribution (with the filename specified in the POD);\n\t(2) a directory you specify to new(dir => 'my/dir/to/lang/file') (again with the filename specified in the POD); or\n\t(3) a directory, specifying the complete path to that file in new(path => 'this/is/the/file.csv'), including its filename";
        }
        else {
            $self->{'_PATH'} = $path;
        }
    }

    $self->{'_DELIM'} =
      get_separator( path => $self->{'_PATH'}, lucky => 1 );

    return $self->{'_LANG'};
}

=head3 get_lang

 $str = $subtlex->get_lang();

Returns the language code (e.g., 'UK', 'FR') currently set for the module (which determines the file being looked up, if not explicitly given). The empty string is returned if the language has not been set.

=cut

sub get_lang {
    my ( $self, %args ) = @_;
    return hascontent( $self->{'_LANG'} ) ? $self->{'_LANG'} : q{};
}

=head3 get_path2db

 $path = $subtlex->get_path2db();

Returns the path (directory and filename) from which the module's methods are currently set to look-up strings, frequencies, etc.

=cut

sub get_path2db {
    my ( $self, %args ) = @_;
    return path( $self->{'_PATH'} )->stringify;
}

=head3 get_index

 $int = $subtlex->get_index(measure => 'frq_opm');

Returns the index within the currently looked-up file that contains the given B<measure>.

=cut

sub get_index {
    my ( $self, %args ) = @_;
    my $var = delete $args{'measure'} or croak 'Need a named measure';
    return $self->{'_FIELDS'}->datum( $self->{'_LANG'}, $var . '_idx' )
      ;    #{$var};
}

=head3 set_eq

 $subtlex->set_eq(match_level => INT); # undef, 0, 1, 2 or 3

See L<Lingua::Orthon|Lingua::Orthon/set_eq>.

=head3 url2datafile

 $url = $subtlex->url2datafile(lang => STRING);
 %loc = $subtlex->url2datafile(lang => STRING);

Returns the URL (complete path) where the SUBTLEX file for a given language is stored, and from which it should be downloadable. These are locations as specified (at the time of releasing this version of the module) at L<expsy.ugent.be/subtlexus/|http://expsy.ugent.be/subtlexus/> and/or L<crr.ugent.be|http://crr.ugent.be/>, and so as listed in the L<DOWNLOADS|Lingua::Norms::SUBTLEX/DOWNLOADS (mandatory)> section. This could include an archive from within which the file needs to be retrieved. Called in list context, this method returns a hash with keys for 'www_dir', 'archive' (if the file is within an archive) and 'filename'. (This module does not fetch the file off the WWW itself; it should be installed and available on the local machine/network--see L<new|Lingua::Norms::SUBTLEX/new>).

=cut

sub url2datafile {

#my ($self, %args) = @_;
#croak 'A value for the argument <lang> needs to be given for SUBTLEX url2datafile' if nocontent($args{'lang'});
#my $lang = delete $args{'lang'};
#croak "The value for the argument <lang> => $lang is not recognised" if none { $_ => $lang } (qw/UK US NL DE/);
# Hard-copy of WWW dirs, archives (where rel) and filenames for the SUBTLEX files:
    ## some datafiles are within compressed archives, some not, so ...
    #my %req_filespecs = %{$path_hash{$lang}};

#return wantarray ? %req_filespecs : File::Spec->catfile($req_filespecs{$lang}->{'www_dir'}, $req_filespecs{$lang}->{'archive'}, $req_filespecs{$lang}->{'file'});
}

### PRIVATMETHODEN:

sub _get_usr_str {
    my $str = shift;
    croak 'No string to test; pass a value for <string> to the requested method'
      if nocontent($str);
    return $str;

    #return decode( 'UTF-8', $str );#
}

# Given a line from a SUBTLEX file, return all the characters from the start of the line up to the delimiter for that file, after stripping it of any quote characters - e.g., if the line starts: "abacus",20,30 ... and the delimiter is a comma, return: abacus
sub _get_file_str {
    my ( $line, $delim ) = @_;
    $line =~ /^([^\Q$delim\E]+)/xms;
    return trim( unquote($1) );

    #my $str = decode('UTF-8', trim(unquote($1)) );
    #print STDERR "<$str>\n";
    #return $str;

#my $code = guess_encoding($str, qw/ascii utf8 utf16 iso-8859-1 cp1250 latin1 greek/);
#print STDERR "$str\t", $code->decode($str), "\n";
#return $code->decode($str);
}

sub _get_val_for_str {
    my ( $str, $col_i, $path, $delim, $eq_fn ) = @_;
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if nocontent($str);
    croak "The requested value is not defined for the current SUBTLEX corpus"
      if nocontent($col_i);

    my $val = q{};    # default value returned is empty string
    open( my $fh, q{<}, $path ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        my $file_str =
          _get_file_str( $_, $delim );    # have to declare as can be empty (!)
        next if nocontent($file_str);
        if ( $eq_fn->( $str, $file_str ) ) {
            $val = _get_val( $_, $delim, $col_i );
            last;
        }
    }
    close $fh or croak $OS_ERROR;
    return $val;
}

sub _get_val {
    my ( $line, $delim, $col_i ) = @_;

# if the line has quoted fields, and uses the delimiter within the quotes,
# as in SUBTLEX-PT, need to firstly clean the line up:
# this "fix" assumes the quotes are either double- or single quotes and nothing else,
# and there is no trailing delimiter.
# It strips the quotes, and replaces the comma with a vertical bar:
    $line =~ s/["']([^"'\Q$delim\E]+)\Q$delim\E([^"'\Q$delim\E]+)["']/$1|$2/gxsm;

    $line =~ m/^(
            [^\Q$delim\E]* # any character from the start not including the delimiter (which might be \t)
            \Q$delim\E # now ending with the delimiter, perhaps as a quoted string 
            )
            {$col_i,}? # as many times as necessary to get to the required field value
            ([^\Q$delim\E]*) # which should be here
            /msx;
    return _clean_value($2);    # now format the number, strip space ...
}

sub _get_val_for_strs {
    my ( $str, $col_i_aref, $path, $delim, $eq_fn ) = @_;

    # Check we have a string, and valid filed indices:
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if nocontent($str);
    croak "The requested value is not defined for the SUBTLEX corpus"
      if any { nocontent($_) } @{$col_i_aref};

    my $val = [];

    # Search for the string, and isolate the requested values:
    open( my $fh, q{<}, $path ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        my $file_str =
          _get_file_str( $_, $delim );    # have to declare as can be empty (!)
        next if nocontent($file_str);
        if ( $eq_fn->( $str, $file_str ) ) {
            my @line = split m/\Q$delim\E/xms;
            for my $col_i ( @{$col_i_aref} ) {
                push @{$val}, _clean_value( $line[$col_i] );
            }
            last;
        }
    }
    close $fh or croak;

# return the reference to array if there is more than 1 value, otherwise just the single value itself
    ## but if the string itself was not found, return the empty string for the number of requested fields:
    my $n_vals = scalar grep { hascontent($_) } @{$val};
    return
        $n_vals
      ? $n_vals > 1
          ? $val
          : $val->[0]
      : scalar @{$col_i_aref} > 1 ? [ q{} x scalar @{$col_i_aref} ]
      :                             q{};
}

sub _get_any_vals_for_string_list {
    my ( $str_aref, $col_i_href, $path, $delim, $eq_fn ) = @_;
    my %string_vals = ();
    my @usr_strings = sort { $a cmp $b } @{$str_aref};

    # Search for the string, and isolate the requested values:
    open( my $fh, q{<}, $path ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        my $file_str =
          _get_file_str( $_, $delim );    # have to declare as can be empty (!)
        next if nocontent($file_str);
        if ( my $found = first { $eq_fn->( $_, $file_str ) } @usr_strings ) {
            my @line = split m/\Q$delim\E/xms;    # split the line
            for my $col_i ( keys %{$col_i_href} ) {
                $string_vals{$file_str}->{ $col_i_href->{$col_i} } =
                  _clean_value( $line[$col_i] );
            }
            last if scalar keys %string_vals == scalar @{$str_aref};
            splice @usr_strings, ( firstidx { $_ eq $found } @usr_strings ), 1;

            #print STDERR "checking ",join(q{,}, @usr_strings),"\n";
        }
    }
    close $fh or croak;
    return \%string_vals;

# return the reference to array if there is more than 1 value, otherwise just the single value itself
    ## but if the string itself was not found, return the empty string for the number of requested fields:
#my $n_vals = scalar grep { hascontent($_) } @{$val};
#return $n_vals ? $n_vals > 1 ? $val : $val->[0] : scalar @{$col_i_aref} > 1 ? [q{} x scalar @{$col_i_aref}] : q{};
}

# Loads a hash-ref of the "specs" for each language file, including the field indices in each file for the measures they contain:
## Called only by new() after setting the MODULE_DIR
sub _set_spec_hash {
    my ( $self, $fieldpath ) = @_;
    $fieldpath ||= File::Spec->catfile( $self->{'_MODULE_DIR'}, 'specs.csv' );
    $self->{'_FIELDS'} = Text::CSV::Hashify->new(
        { file => $fieldpath, format => 'hoh', key => 'Lang_stub' } );
    return;
}

sub _in_range {
    my ( $n, $min, $max ) = @_;
    my $res = 1;
    if ( !is_numeric($n) ) {
        $res = 0;
    }
    else {
        if ( hascontent($min) and $n < $min ) {    # fails min
            $res = 0;
        }
        if ( $res && ( hascontent($max) and $n > $max ) ) {  # fails max and min
            $res = 0;
        }
    }
    return $res;
}

sub _clean_value {
    my $val = shift;
    return q{} if nocontent($val);
    $val =~ s/,([^,]+)$/.$1/xsm;    # replace ultimate , with .
    return trim( unquote($val) );
}

sub _pos_is {
    my ( $pos_aref, $fields, $lang ) = @_;
    $pos_aref = [$pos_aref] if !ref $pos_aref;
    my @test_str = map { split /[\W\.]+/xsm } @{$pos_aref};
    return [qw/UK/] if !scalar @test_str;
    my @pos_ari = ();
    for my $pos_str (@test_str) {
        push @pos_ari, first {
            hascontent( $fields->datum( $lang, 'pos_' . $_ ) )
              and first { $_ =~ m/^$pos_str$/xsm }(split /\|/, $fields->datum( $lang, 'pos_' . $_ ))
        }
        qw/NN VB AJ AV CJ PN PP DA NM IJ NB OT UK/;

    }
    return \@pos_ari;
}

sub _log10 {
    return log(shift) / log(10);
}

sub _val_or_0 {
    my $val = shift;
    return ( is_numeric($val) ) ? $val : 0;
}

sub _croak_defunct {
    croak
'That method is defunct. See the POD for an alternative, and the CHANGES file';
}
*freqhash         = \&_croak_defunct;
*ldist            = \&_croak_defunct;
*on_count         = \&_croak_defunct;
*on_ldist         = \&_croak_defunct;
*on_freq_max      = \&_croak_defunct;
*on_zipf_mean     = \&_croak_defunct;
*on_freq_mean     = \&_croak_defunct;
*on_lfreq_mean    = \&_croak_defunct;
*on_frq_opm_max   = \&_croak_defunct;
*on_frq_opm_max   = \&_croak_defunct;
*on_frq_zipf_mean = \&_croak_defunct;

sub _carp_deprecated {
    my ( $self, %args ) = @_;
    carp
'That method is deprecated. See the POD for an alternative, and the CHANGES file';
    return;
}
*list_words   = \&_carp_deprecated;
*list_strings = \&_carp_deprecated;

=head1 DIAGNOSTICS

=over 4

=item * Need a valid <lang> attribute

When constructing the class object with L<new|Lingua::Norms::SUBTLEX/new>, the B<lang> argument must have a valid value, as indicated in the table above. Also, the module needs to read in the contents of a file named "specs.csv" which should be located within the SUBTLEX directory where the module itself is located (alongside the downloaded SUBTLEX files). This file specifies the field indices for the various stats within each SUBTLEX datafile. Check that this file is indeed within the Perl/site/lib/Lingua/Norms/SUBTLEX directory. If it is not, download and install the file to that location via the L<CPAN|http://www.cpan.org> package of this module.

=item * Value given to argument 'dir' (VALUE) in new() is not a directory

Croaked from L<new|Lingua::Norms::SUBTLEX/new> if called with a value for the argument B<dir>, and this value is not actually a directory/folder. This is the directory/folder in which the actual SUBTLEX datafiles should be located.

=item * Cannot find required database for language ...

Croaked from L<new|Lingua::Norms::SUBTLEX/new> if none of the given values to arguments B<lang>, B<dir> or B<path> are valid, and even the default site/lib directory and US database are not accessible. Check that your have indeed a file with the given value of B<lang> (DE, NL, UK or US) within the Perl/site/lib/Lingua/Norms/SUBTLEX directory, or at least that the SUBTLEX-US file is located within it, and can be read via your script.

=item * Cannot determine fields for given language

Croaked upon construction if no fields are recognized for the given language. The value given to B<lang> must be one of DE, NL, UK or US.

=item * The requested value is not defined for the ... SUBTLEX corpus

Croaked when calling for a value for a statistic that is not defined for a given language, e.g., when requesting a value for the Zipf frequency in the NL corpus.

=item * No string to test; pass a value for <string> to FUNCTION()

Croaked by several methods that expect a value for the named argument B<string>, and when no such value is given. These methods require the letter-string to be passed to it as a I<key> => I<value> pair, with the key B<string> followed by the value of the string to test.

=item * No string(s) to test; pass one or more letter-strings named \'strings\' as a referenced array

Same as above but specifically croaked by L<frq_hash|Lingua::Norms::SUBTLEX/frq_hash> which accepts more than one string in a single call.

=item * Need to install and have access to module File::RandomLine

Croaked by method L<random_string|Lingua::Norms::SUBTLEX/random_string> if the module it depends on (File::RandomLine) is not installed or accessible. This should have been installed (if not already) upon installation of the present module. See L<CPAN|http://www.cpan.org> to download and install this module manually.

=back

=head1 DEPENDENCIES

L<File::RandomLine|File::RandomLine> : for L<random_string|Lingua::Norms::SUBTLEX/random_string>

L<Lingua::Orthon|Lingua::Orthon> : for C<set_eq> method

L<List::AllUtils|List::AllUtils> : C<all>, C<any>, C<none>, C<uniq> and other functions

L<Number::Misc|Number::Misc> : C<is_numeric>

L<Path::Tiny|Path::Tiny> : for directory reading when calling L<new|Lingua::Norms::SUBTLEX/new>

L<Statistics::Lite|Statistics::Lite> : for various statistical methods

L<String::Trim|String::Trim> : C<trim>

L<String::Util|String::Util> : for determining valid string values

L<Text::CSV::Hashify|Text::CSV::Hashify> : reads in the specs file

L<Text::CSV::Separator|Text::CSV::Separator> : for determining the field delimiter within the datafiles

L<Text::Unidecode|Text::Unidecode> : for plain ASCII transliterations of Unicode text

=head1 REFERENCES

Brysbaert, M., Buchmeier, M., Conrad, M., Jacobs, A.M., Boelte, J., & Boehl, A. (2011). The word frequency effect: A review of recent developments and implications for the choice of frequency estimates in German. I<Experimental Psychology>, I<58>, 412-424. doi: L<10.1027/1618-3169/a000123|http://dx.doi.org/10.1027/1618-3169/a000123>

Brysbaert, M., & New, B. (2009). Moving beyond Kucera and Francis: A critical evaluation of current word frequency norms and the introduction of a new and improved word frequency measure for American English. I<Behavior Research Methods>, I<41>, 977-990. doi: L<10.3758/BRM.41.4.977|http://dx.doi.org/10.3758/BRM.41.4.977>

Brysbaert, M., New, B., & Keuleers,E. (2012). Adding part-of-speech information to the SUBTLEX-US word frequencies. I<Behavior Research Methods>, I<44>, 991-997. doi: L<10.3758/s13428-012-0190-4|http://dx.doi.org/10.3758/s13428-012-0190-4>

Herdagdelen, A., & Marelli, M. (2017). Social media and language processing: How Facebook and Twitter provide the best frequency estimates for studying word recognition. I<Cognitive Science>, I<41>, 976-995. doi:L<10.1111/cogs.12392|http://dx.doi.org/10.1111/cogs.12392>

Keuleers, E., Brysbaert, M., & New, B. (2010). SUBTLEX-NL: A new frequency measure for Dutch words based on film subtitles. I<Behavior Research Methods>, I<42>, 643-650. doi: L<10.3758/BRM.42.3.643|http://dx.doi.org/10.3758/BRM.42.3.643>

New, B., Brysbaert, M., Veronis, J., & Pallier, C. (2007). The use of film subtitles to estimate word frequencies. I<Applied Psycholinguistics>, I<28>, 661-677.

Soares, A. P., Machado, J., Costa, A., Comesaña, M., & Perea, M. (in press). On the advantages of frequency measures extracted from subtitles: The case of Portuguese. I<Quarterly Journal of Experimental Psychology>.

Van Heuven, W. J. B., Mandera, P., Keuleers, E., & Brysbaert, M. (2014). SUBTLEX-UK: A new and improved word frequency database for British English. I<Quarterly Journal of Experimental Psychology>, I<67>, 1176-1190. doi: L<10.1080/17470218.2013.850521|http://dx.doi.org/10.1080/17470218.2013.850521>

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-lingua-norms-subtlfreq-0.06 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Norms-SUBTLEX-0.06>.  I will be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Norms::SUBTLEX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Norms-SUBTLEX-0.06>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Norms-SUBTLEX-0.06>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Norms-SUBTLEX-0.06>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Norms-SUBTLEX-0.06/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2018 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=cut

1;   # End of Lingua::Norms::SUBTLEX
