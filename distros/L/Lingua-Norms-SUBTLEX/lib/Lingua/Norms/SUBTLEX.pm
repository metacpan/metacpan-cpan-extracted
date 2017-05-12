package Lingua::Norms::SUBTLEX;
use 5.006;
use strict;
use warnings FATAL => 'all';
use Config;
use Carp qw(carp croak);
use English '-no_match_vars';
use File::Slurp qw(read_dir);
use File::Spec;
use List::AllUtils qw(none);
use Statistics::Lite qw(max mean median stddev);
use String::Util qw(hascontent nocontent);
use Text::CSV::Separator qw(get_separator);
use Readonly;
Readonly my $YARKONI_MAX => 20;

$Lingua::Norms::SUBTLEX::VERSION = '0.05';

=head1 NAME

Lingua::Norms::SUBTLEX - Retrieve frequency values and frequency-based lists for words from Subtitles Corpora

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

 use feature qw(say);
 use Lingua::Norms::SUBTLEX;
 my $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'US'); # or NL, UK, DE
 my $bool = $subtlex->is_normed(string => 'fuip'); # isa_word ? 
 my $frq = $subtlex->frq_opm(string => 'frog'); # freq. per million, or get log/zipf
 my $href = $subtlex->freqhash(words => [qw/frog fish ape/]); # freqs. for a list of words
 say "$_ freq per mill = $href->{$_}" for keys %{$href};

 # stats, parts-of-speech, orthographic relations:
 say "mean freq per mill = ", $subtlex->mean_frq(words => [qw/frog fish ape/]); # or median, std-dev.
 say "frog part-of-speech = ", $subtlex->pos(string => 'frog');
 my ($count, $orthons_aref) = $subtlex->on_count(string => 'frog'); # or scalar context for count only; or freq_max/mean
 say "orthon of frog = $_" for @{$orthons_aref}; # e.g., from
 
 # retrieve (list of) words to certain specs:
 my $aref = $subtlex->list_words(freq => [2, 400], onc => [1,], length => [4, 4], cv_pattern => 'CCVC', regex => '^f');
 my $string = $subltex->random_word();

=head1 DESCRIPTION

The module facilitates access to raw data and descriptive statistics on word-frequency and parts-of-speech, as provided in the SUBTLEX-DE, SUBTLEX-NL, SUBTLEX-UK and SUBTLEX-US databases (see L<REFERENCES|Lingua::Norms::SUBTLEX/REFERENCES>). For example, the SUBTLEX-US database is based on a study of 74,286 letter-strings, with frequencies of occurrence within a corpus of some 30 million words from the subtitles of 8,388 film and television episodes. The frequency data obtained in this way have been shown to offer more psychologically predictive measures than those derived from books, newsgroup posts, and similar.

There are three groups of retrievable stats and sampling rules: (1) frequency; (2)contextual diversity (number of films/episodes appeared in); and (3) parts-of-speech. Depending on the source language, frequency is given as a count (L<frq_count|Lingua::Norms::SUBTLEX/frq_count>), occurrences per million (L<frq_opm|Lingua::Norms::SUBTLEX/frq_opm>), logarithm of the opm (L<frq_log|Lingua::Norms::SUBTLEX/frq_log>), and/or 7-point scaled (L<frq_zipf|Lingua::Norms::SUBTLEX/frq_zipf>); contextual diversity is given as a count (L<cd_count|Lingua::Norms::SUBTLEX/cd_count>), a percentage (L<cd_pct|Lingua::Norms::SUBTLEX/cd_pct>), or a logarithm (L<cd_log|Lingua::Norms::SUBTLEX/cd_log>). For parts-of-speech, L<pos|Lingua::Norms::SUBTLEX/pos> returns a string giving the dominant part. Sampling is given by the same labels, with keys with min/max values (or a whitelist of acceptable parts-of-speech).

A small sample from each of the databases is included in the installation distribution for testing purposes. The complete files need to be downloaded via the following URLs. The local directory location or actual pathname of these files can be given in class construction (by the arguments B<dir> and B<path>); otherwise the default location--the directory "SUBTLEX" alongside the module itself in the locally configured Perl sitelib--will be used, and the correct file determined by  inclusion of B<lang> value within its filename. The filenames of the original files downloaded from the following sites are supported in this way, and it does not matter if (as varies between the files) the fields are comma-separated or tab-delimited.

The three databases (comprised of one file per language) do not provide values for all methods. All three provide values for only the methods frq_count, cd_count, cd_pct, and pos. Further details of unsupported methods per database/lang are given below.

=over 4

=item SUBTLEX-US

For the B<American> norms, install the file "SUBTLEXusExcel2007.csv" from L<expsy.ugent.be/subtlexus/|http://expsy.ugent.be/subtlexus/>. All methods are supported by this database.

=item SUBTLEX-UK

For the B<British> norms, install the file "SUBTLEX-UK.txt" from within the "SUBTLEX-UK.zip" archive via L<psychology.nottingham.ac.uk/subtlex-uk/|http://www.psychology.nottingham.ac.uk/subtlex-uk/>. This database does not define values for occurrences per million (or log occurrences per million); the methods for these stats will return an empty string.

=item SUBTLEX-NL

For the B<Dutch> norms, install the file "SUBTLEX-NL.with-pos.txt" from within the archive "SUBTLEX-NL.with-pos.txt.zip" via L<crr.ugent.be|http://crr.ugent.be/programs-data/subtitle-frequencies/subtlex-nl>. This database does not define a value for Zipf frequency, so the "zipf" method will return an empty string if called with NL as the "lang".

=item SUBTLEX-DE

For the B<German> norms, dowload the file "SUBTLEX-DE_cleaned_with_Google00.txt" via L<crr.ugent.be|http://crr.ugent.be/archives/534>. There is no CD, POS or Zipf data at this point, so only the "frq_" methods, and the "on_" methods (based on realtime calculation work with this language. The file contains other information, including Google-based frequencies, for which this module does not provide retrieval at this time.

=back

There are several other languages from this project which might be supported by this module in a later version (originally, only SUBTLEX-US was supported).

=head1 SUBROUTINES/METHODS

All methods are called via the class object, and with named (hash of) arguments, usually B<string>, where relevant.

=head2 new

 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'US'); # or 'UK', 'NL', 'DE' - looking in Perl sitelib
 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'US', dir => 'file_location'); # where to look
 $subtlex = Lingua::Norms::SUBTLEX->new(lang => 'US', path => 'actual_file');

Returns a class object for accessing other methods. The parameter B<lang> should be set to specify the particular language database: DE (German), NL (Dutch), UK (British) or US (American); otherwise US (being the first published in the series) is the default. Optional arguments B<dir> or B<path> can be given to specify the location or actual file (respectively) of the database. The default location is within the "Lingua/Norms/SUBTLEX" directory within the 'sitelib' configured for the local Perl installation (as per L<Config.pm|Config>). The method will C<croak> if the given B<path> or default location cannot be found.

=cut

sub new {
    my ( $class, %args ) = @_;
    my $self = bless {}, ref($class) ? ref($class) : $class;

    # determine database location:
    my $lang = $args{'lang'} ? delete $args{'lang'} : 'US';
    my $mod_dir =
      File::Spec->catdir( $Config{'sitelib'}, qw/Lingua Norms SUBTLEX/ );
    if ( $args{'path'} ) {    # -by specific arg:
        $self->{'path'} = $args{'path'};
    }
    else {                    # by dir and lang args:
        my $dir;
        if ( $args{'dir'} ) {    # check it's a dir:
            croak "Value for argument 'dir' ($args{'dir'}) is not a directory"
              if !-d $args{'dir'};
            $dir = delete $args{'dir'};
        }
        else {                   # use module's dir :
            $dir = $mod_dir;
        }
        for ( read_dir($dir) ) {
            if (/(?:SUBTLEX\-)?\Q$lang/imsx) {
                $self->{'path'} = File::Spec->catfile( $dir, $_ );
                last;
            }
        }
    }
    croak "Cannot find required database for language $lang"
      if nocontent( $self->{'path'} );    # or !-T $self->{'path'};

    # determine delimiter:
    $self->{'delim'} = get_separator( path => $self->{'path'}, lucky => 1 );

    # identify needed field indices within this file:
    # - arg 'fieldpath' only used for testing, assumed not useful for user:
    my %fields = ( US => 1, UK => 2, NL => 3, DE => 4 );
    croak 'Cannot determine fields for given language'
      if nocontent( $fields{$lang} );
    my $fieldpath =
        $args{'fieldpath'}
      ? $args{'fieldpath'}
      : File::Spec->catfile( $mod_dir, 'fields.csv' );
    open( my $fh, q{<}, $fieldpath ) or carp 'Cannot determine field indices';
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;
        chomp;
        my @dat = split m/[,]/msx;
        $self->{'IDX'}->{ $dat[0] } =
          hascontent( $dat[ $fields{$lang} ] ) ? $dat[ $fields{$lang} ] : q{};
    }
    close $fh or croak $OS_ERROR;
    return $self;
}

=head2 Frequencies and POS for individual words or word-lists

=head3 is_normed

 $bool = $subtlex->is_normed(string => $word);

I<Alias>: isa_word

Returns a boolean value to specify whether or not the letter-string passed as B<string> is represented in the SUBTLEX corpus. This might be thought of as a lexical decision ("is this string a word?") but note that some very low frequency letter-strings in the corpus would not be considered words in the average context (perhaps, in part, because of misspelt subtitles).

=cut

sub is_normed {
    my ( $self, %args ) = @_;
    croak 'No string to test; pass a string to the function'
      if nocontent( $args{'string'} );
    my $str = $args{'string'};
    my $res = 0;                 # boolean to return from this sub
    open my $fh, q{<}, $self->{'path'} or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip headings
        /^([^\Q$self->{'delim'}\E]+)/msx
          or next;   # isolate first token ahead of delimiter as $1 in this file
        if ( $str eq $1 ) {    # first token equals given string?
            $res = 1;          # set result to return as true
            last;              # got it, so abort look-up
        }
    }
    close $fh or croak $OS_ERROR;
    return $res;               # zero if string not found in file
}
*isa_word = \&is_normed;

=head3 frq_count

 $val = $subtlex->frq_count(string => 'aword');

Returns the raw number of occurrences in all the films/TV episodes for the word passed as B<string>, or the empty-string if the string is not represented in the norms. 

=cut

sub frq_count {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'frq_count'} );
}
*freq = \&frq_opm;

=head3 frq_opm

 $val = $subtlex->frq_opm(string => 'aword');

I<Alias>: opm

Returns frequency per million for the word passed as B<string>, or the empty-string if the string is not represented in the norms.

=cut

sub frq_opm {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'frq_opm'} );
}
*freq = \&frq_opm;    # legacy only
*opm  = \&frq_opm;

=head3 frq_log

 $val = $subtlex->frq_log(string => 'aword');

Returns log frequency per million for the word passed as B<string>, or the empty-string if the string is not represented in the norms.

=cut

sub frq_log {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'frq_log'} );
}
*lfreq = \&frq_log;    # legacy only

=head3 frq_zipf

 $val = $subtlex->frq_zipf(string => 'aword');

Returns zipf frequency for the word passed as B<string>, or the empty-string if the string is not represented in the norms. The Zipf scale ranges from 1 to 7, with values of 1-3 representing low frequency words, and values of 4-7 representing high frequency words. See Van Heuven et al. (2014) and L<crr.ugent.be/archives|http://crr.ugent.be/archives/1352>.

=cut

sub frq_zipf {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'frq_zipf'} );
}
*zipf = \&frq_zipf;    # legacy only

=head3 cd_count

 $cd = $subtlex->cd_count(string => 'aword');

Corresponds to the column labelled "CDcount" in the datafile.

=cut

sub cd_count {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'cd_count'} );
}

=head3 cd_pct

 $cd = $subtlex->cd_pct(string => 'aword');

Returns a percentage measure to two decimal places of the number of films/TV episodes in which the given string was included in its subtitles. This corresponds to the measure "SUBTLCD" described in Brysbaert and New (2009). Note: where "cd" stands for "contextual diversity."

=cut

sub cd_pct {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'cd_pct'} );
}

=head3 cd_log

Returns log10(L<cd_pct|Lingua::Norms::SUBTLEX/cd_pct> + 1) for the given string, with 4-digit precision. This corresponds to the measure "Lg10CD" described in Brysbaert and New (2009), where it is stated that "this is the best value to use if one wants to match words on word frequency" (p. 988). Note: "cd" stands for "contextual diversity," which is based on the number of films and TV episodes in which the string was represented.

=cut

sub cd_log {
    my ( $self, %args ) = @_;
    return _get_fieldvalue( $self, $args{'string'},
        $self->{'IDX'}->{'cd_log'} );
}

=head3 frq_hash

 $href = $subtlex->frq_hash(strings => [qw/word1 word2/], scale => opm|log|zipf);

Returns frequency as values within a reference to a hash keyed by the words passed as B<strings>. By default, the values in the hash are corpus frequency per million. If the optional argument B<scale> is defined, and it equals I<log>, then the values are log-frequency; similarly, I<zipf> yields zipf-frequency. Note, however, that some databases do not support all types of scales; in which case the returned value will be the empty string. 

=cut

sub frq_hash {
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
      ? $self->{'IDX'}->{ $args{'scale'} }
      : $self->{'IDX'}->{'frq_opm'};
    my %frq = map { lc($_) => [ undef, $_ ] }
      @{$strs};    # keep lower-case to search associated with original case
    open my $fh, q{<}, $self->{'path'} or croak "$OS_ERROR\n";
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;
        chomp;
        my @line = split m/\Q$self->{'delim'}\E/msx;
        if ( hascontent( $frq{ lc( $line[0] ) } ) ) {
            $frq{ lc( $line[0] ) }->[0] = $line[$col_i];
        }
    }
    close $fh or croak $OS_ERROR;
    return { map { $_->[1] => _nummify($_->[0]) }
          values %frq };    # assign values to original case strings
}
*freqhash = \&frq_hash;

=head3 pos

 $pos_str = $subtlex->pos(string => 'aword');

Returns part-of-speech string for a given word. The return value is undefined if the word is not found.

=cut

sub pos {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $word = $args{'string'};
    my $pos;
    open my $fh, q{<}, $self->{'path'} or croak "$OS_ERROR\n";
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$self->{'delim'}\E]+)/msx;
        if ( $word eq $1 ) {
            chomp;
            my @line = split m/\Q$self->{'delim'}\E/msx, $_;
            $pos = $line[ $self->{'IDX'}->{'pos'} ];
            last;
        }
    }
    close $fh or croak $OS_ERROR;
    return $pos;
}

=head2 Descriptive frequency statistics for lists

These methods return a descriptive statistic (mean, median or standard deviation) for a list of B<strings>. Like L<freqhash|Lingua::Norms::SUBTLEX/freqhash>, they take an optional argument B<scale> to specify if the returned values should be raw frequencies per million, log frequencies, or zip-frequencies.

=head3 frq_mean

 $mean = $subtlex->frq_mean(strings => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the arithmetic mean of the frequencies for the given B<words>, or mean of the log frequencies if B<log> => 1.

=cut

sub frq_mean {
    my ( $self, %args ) = @_;
    return mean( values %{ $self->freqhash(%args) } );
}
*mean_freq = \&frq_mean;

=head3 frq_median

 $median = $subtlex->frq_median(words => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the median of the frequencies for the given B<words>, or median of the log frequencies if B<log> => 1.

=cut

sub frq_median {
    my ( $self, %args ) = @_;
    return median( values %{ $self->freqhash(%args) } );
}
*median_freq = \*frq_median;

=head3 frq_sd

 $sd = $subtlex->frq_sd(words => [qw/word1 word2/], scale => 'raw|log|zipf');

Returns the standard deviation of the frequencies for the given B<words>, or standard deviation of the log frequencies if B<log> => 1.

=cut

sub frq_sd {
    my ( $self, %args ) = @_;
    return stddev( values %{ $self->freqhash(%args) } );
}
*sd_freq = \*frq_sd;

=head2 Orthographic neighbourhood measures

These methods return stats re the orthographic relatedness of a specified letter-B<string> to words in the SUBTLEX corpus. Unless otherwise stated, an orthographic neighbour here means letter-strings that are identical except for a single-letter substitution while holding string-length constant, i.e., the Coltheart I<N> of a letter-string, as defined in Coltheart et al. (1977). These measures are calculated in realtime; they are not listed in the datafile for look-up, so expect some extra-normal delay in getting a returned value.

=head3 on_count

 $n = $subtlex->on_count(string => $letters);
 ($n, $orthons_aref) = $subtlex->on_count(string => $letters);

Returns orthographic neighbourhood count (Coltheart I<N>) within the SUBTLEX corpus. Called in array context, also returns a reference to an array of the neighbours retrieved, if any.

=cut

sub on_count {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $word = lc( $args{'string'} );
    require Lingua::Orthon;
    my $ortho = Lingua::Orthon->new();
    my ( $z, @orthons ) = (0);
    open my $fh, q{<}, $self->{'path'} or die "$OS_ERROR\n";
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$self->{'delim'}\E]+)/msx or next;
        my $test = lc($1);
        if ( $ortho->are_orthons( $word, $test ) ) {
            push @orthons, $test;
            $z++;
        }
    }
    close $fh or croak $OS_ERROR;
    return wantarray ? ( $z, \@orthons ) : $z;
}

=head3 on_frq_max

 $m = $subtlex->on_frq_max(string => $letters);

Returns the maximum SUBTLEX frequency per million among the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If (unusually) all the frequencies are the same, then that value is returned. If the string has no (Coltheart-type) neighbours, undef is returned.

=cut

sub on_frq_max {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f(
        $args{'string'},             $self->{'path'},
        $self->{'IDX'}->{'frq_opm'}, $self->{'delim'}
    );
    return scalar @{$frq_aref} ? max( @{$frq_aref} ) : undef;
}
*on_freq_max = \&on_frq_max;

=head3 on_frq_opm_mean

 $m = $subtlex->on_frq_mean(string => $letters);

Returns the mean SUBTLEX frequencies per million of the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If the string has no (Coltheart-type) neighbours, undef is returned. 

=cut

sub on_frq_opm_mean {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f(
        $args{'string'},             $self->{'path'},
        $self->{'IDX'}->{'frq_opm'}, $self->{'delim'}
    );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}
*on_freq_mean = \&on_frq_opm_mean;

=head3 on_frq_log_mean

 $m = $subtlex->on_frq_log_mean(string => $letters);

Returns the mean log of SUBTLEX frequencies of the orthographic neighbours (per Coltheart I<N>) of a particular letter-string. If the string has no  (Coltheart-type) neighbours, undef is returned.

=cut

sub on_frq_log_mean {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f(
        $args{'string'},             $self->{'path'},
        $self->{'IDX'}->{'frq_log'}, $self->{'delim'}
    );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}
*on_lfreq_mean = \&on_frq_log_mean;

=head3 on_frq_zipf_mean

 $m = $subtlex->on_frq_zipf_mean(string => $letters);

Returns the mean zipf of SUBTLEX frequencies of the orthographic neighbours (per Coltheart I<N>) of a given letter-string. If the string has no (Coltheart-type) <b></b>neighbours, undef is returned.

=cut

sub on_frq_zipf_mean {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    my $frq_aref = _get_orthon_f(
        $args{'string'},              $self->{'path'},
        $self->{'IDX'}->{'frq_zipf'}, $self->{'delim'}
    );
    return scalar @{$frq_aref} ? mean( @{$frq_aref} ) : undef;
}
*on_zipf_mean = \&on_frq_zipf_mean;

=head3 on_ldist

 $m = $subtlex->on_ldist(string => $letters, lim => 20);

I<Alias>: ldist

Returns the mean L<Levenshtein Distance|http://www.let.rug.nl/%7Ekleiweg/lev/levenshtein.html> from a letter-string to its B<lim> closest orthographic neighbours. The default B<lim>it is 20, as defined in Yarkoni et al. (2008). The module uses the matrix-based calculation of Levenshtein Distance as implemented in L<Lingua::Orthon|Lingua::Orthon> module. No defined value is returned if no Levenshtein Distance is found (whereas zero would connote "identical to everything").

=cut

sub on_ldist {
    my ( $self, %args ) = @_;
    croak 'No string to test' if !$args{'string'};
    $args{'lim'} ||= $YARKONI_MAX;
    return _get_orthon_ldist( $args{'string'}, $self->{'path'}, $args{'lim'},
        $self->{'delim'} );
}
*ldist = \&on_ldist;

=head2 Retrieving letter-strings/words

=head3 list_strings

 $aref = $subtlex->list_words(freq => [1, 20], onc => [0, 3], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');
 $aref = $subtlex->list_words(zipf => [0, 2], onc => [0, 3], length => [4, 4], cv_pattern => 'CVCV', regex => '^f');

I<Alias>: list_words

Returns a list of words from the SUBTLEX corpus that satisfies certain criteria: minimum and/or maximum letter-length (specified by the named argument B<length>), minimum and/or maximum frequency (argument B<freq>) or zip-frequency (argument B<zipf>), minimum and/or maximum orthographic neighbourhood count (argument B<onc>), a consonant-vowel pattern (argument B<cv_pattern>), or a specific regular expression (argument B<regex>).

For the minimum/maximum constrained criteria, the two limits are given as a referenced array where the first element is the minimum and the second element is the maximum. For example, [3, 7] would specify letter-strings of 3 to 7 letters in length; [4, 4] specifies letter-strings of only 4 letters in length. If only one of these is to be constrained, then the array would be given as, e.g., [3] to specify a minimum of 3 letters without constraining the maximum, or ['',7] for a maximum of 7 letters without constraining the minimum (checking if the element C<hascontent> as per String::Util).

The consonant-vowel pattern is specified as a string by the usual convention, e.g., 'CCVCC' defines a 5-letter word starting and ending with pairs of consonants, the pairs separated by a vowel. 'Y' is defined here as a consonant.

A finer selection of particular letters can be made by giving a regular expression as a string to the B<regex> argument. In the example above, only letter-strings starting with the letter 'f', followed by one of more other letters, are specified. Alternatively, for example, '[^aeiouy]$' specifies that the letter-strings must not end with a vowel (here including 'y'). The entire example for '^f', including the shown arguments for B<cv_pattern>, B<freq>, B<onc> and B<length>, would return only two words: I<fiji> and I<fuse> from SUBTLEX-US.

The selection procedure will be made particularly slow wherever B<onc> is specified (as this has to be calculated in real-time) and no arguments are given for B<cv_pattern> and B<regex> (which are tested ahead of any other criteria).

Syllable-counts might be added in future; existing algorithms in the Lingua family are not sufficiently reliable for the purposes to which the present module might often be put; an alternative is being worked on.

The value returned is always a reference to the list of words retrieved (or to an empty list if none was retrieved).

=cut

sub list_strings {
    my ( $self, %args ) = @_;
    my %patterns = ();
    if ( hascontent( $args{'regex'} ) ) {
        $patterns{'regex'} = qr/$args{'regex'}/msx;
    }
    if ( hascontent( $args{'cv_pattern'} ) ) {
        my $tmp = q{};
        my @c = split m//msx, uc( $args{'cv_pattern'} );
        foreach (@c) {
            $tmp .= $_ eq 'C' ? '[BCDFGHJKLMNPQRSTVWXYZ]' : '[AEIOU]';
        }
        $patterns{'cv_pattern'} = qr/^$tmp$/imsx;
    }

    my @list = ();
    open my $fh, q{<}, $self->{'path'} or croak $OS_ERROR;
  LINES:
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        chomp;
        my @line = split m/\Q$self->{'delim'}\E/msx;
        next if !_in_range( length( $line[0] ), @{ $args{'length'} } );
        for ( keys %patterns ) {
            next LINES if $line[0] !~ $patterns{$_};
        }
        for (qw/freq opm frq_opm frq_log log frq_zipf zipf cd_pct cd_log/) {
            if ( ref $args{$_} ) {
                next LINES
                  if !_in_range( _nummify($line[ $self->{'IDX'}->{$_} ]),
                    @{ $args{$_} } );
            }
        }
        if ( ref $args{'pos'} ) {
            next LINES
              if none { $_ eq $line[ $self->{'IDX'}->{'pos'} ] }
            @{ $args{'pos'} };
        }
        next LINES
          if !_in_range( scalar( $self->on_count( string => $line[0] ) ),
            @{ $args{'onc'} } );
        push @list, $line[0];
    }
    close $fh or croak;

    return \@list;
}
*list_words = \&list_strings;

=head3 all_strings

 $aref = $subtlex->all_strings();

I<Alias>: all_words

Returns a reference to an array of all letter-strings in the corpus, in their given order.

=cut

sub all_strings {
    my ( $self, %args ) = @_;
    my @list = ();
    open my $fh, q{<}, $self->{'path'} or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$self->{'delim'}\E]+)/msx or next;
        push @list, $1;
    }
    close $fh or croak;
    return \@list;
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
      File::RandomLine->new( $self->{'path'}, { algorithm => 'uniform' } );
    my @ari = ();
    while ( not scalar @ari or $ari[0] eq 'Word' ) {
        @ari = split m/\Q$self->{'delim'}\E/msx, $rl->next;
    }
    return wantarray ? @ari : $ari[0];
}
*random_word = \&random_string;

=head2 Miscellaneous

=head3 nlines

 $num = $subtlex->nlines();

Returns the number of lines, less the column headings, in the installed language file. Expects/accepts no arguments.

=cut

sub nlines {
    my $self = shift;
    my $z    = 0;
    open( my $fh, q{<}, $self->{'path'} ) or croak "$OS_ERROR\n";
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        $z++;
    }
    close $fh or croak $OS_ERROR;
    return $z;
}

### PRIVATMETHODEN:

sub _get_orthon_f {
    my ( $str, $path, $idx, $delim ) = @_;
    my $word = lc($str);
    require Lingua::Orthon;
    my $ortho = Lingua::Orthon->new();
    my @freqs = ();
    open( my $fh, q{<}, $path ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$delim\E]+)/xsm or next;     # capture first token
        my $test = lc($1);
        if ( $ortho->are_orthons( $word, $test ) ) {    # Lingua::Orthon method
            chomp;
            my @line = split m/\Q$delim\E/xsm;
            push @freqs, _nummify($line[$idx]);
        }
    }
    close $fh or croak $OS_ERROR;
    return \@freqs;
}

sub _get_orthon_ldist {
    my ( $str, $path, $lim, $delim ) = @_;
    my $word = lc($str);
    require Lingua::Orthon;
    my $ortho  = Lingua::Orthon->new();
    my @ldists = ();
    open( my $fh, q{<}, $path ) or croak $OS_ERROR;
    my @tests = ();
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$delim\E]+)/msx or next;
        my $test = lc($1);
        next if $word eq $test;
        push @ldists, $ortho->ldist( $word, $test );
    }
    close $fh or croak $OS_ERROR;
    my @sorted = sort { $a <=> $b } @ldists;
    return mean( @sorted[ 0 .. $lim - 1 ] );
}

sub _get_fieldvalue {
    my ( $self, $str, $col_i ) = @_;
    croak
      'No word to test; pass a letter-string named \'string\' to the function'
      if nocontent($str);
    $str = lc($str);
    my $val = q{};    # default value returned is empty string
    open( my $fh, q{<}, $self->{'path'} ) or croak $OS_ERROR;
    while (<$fh>) {
        next if $INPUT_LINE_NUMBER == 1;    # skip column heading line
        /^([^\Q$self->{'delim'}\E]+)/msx;
        if ( $str eq $1 ) {
            chomp;    # or zipf will return with "\n" appended
            my @line = split m/\Q$self->{'delim'}\E/msx, $_;
            $val = _nummify($line[$col_i]);
            last;
        }
    }
    close $fh or croak;
    return $val;
}

sub _in_range {
    my ( $n, $min, $max ) = @_;
    my $res = 1;
    if ( hascontent($min) and $n < $min ) {    # fails min
        $res = 0;
    }
    if ( $res && ( hascontent($max) and $n > $max ) ) {    # fails max and min
        $res = 0;
    }
    return $res;
}

sub _nummify {
    my $val = shift;
    $val =~ s/,([^,]+)$/.$1/; # replace ultimate , with .
    return $val;
}

=head1 DIAGNOSTICS

=over 4

=item Cannot determine field indices

When constructing the class object with L<new|Lingua::Norms::SUBTLEX/new>, the module needs to read in the contents of a file named "fields.csv" which should be housed within the SUBTLEX directory where the module itself is located (alongside the downloaded SUBTLEX files). This is necessary because the field indices for the various stats vary from one language file to the next. This should have been done with installation of the module itself. Check that this file is indeed within the Perl/site/lib/Lingua/Norms/SUBTLEX directory. If it is not, download and install the file to that location via the L<CPAN|http://www.cpan.org> package of this module.

=item Value given to argument 'dir' (VALUE) in new() is not a directory

Croaked from L<new|Lingua::Norms::SUBTLEX/new> if called with a value for the argument B<dir>, and this value is not actually a directory/folder. This is the directory/folder in which the actual SUBTLEX datafiles should be located.

=item Cannot find required database for language $lang

Croaked from L<new|Lingua::Norms::SUBTLEX/new> if none of the given values to arguments B<lang>, B<dir> or B<path> are valid, and even the default site/lib directory and US database are not accessible. Check that your have indeed a file with the given value of B<lang> (DE, NL, UK or US) within the Perl/site/lib/Lingua/Norms/SUBTLEX directory, or at least that the SUBTLEX-US file is located within it, and can be read via your script.

=item Cannot determine fields for given language

Croaked upon construction if no fields are recognized for the given language. The value given to B<lang> must be one of DE, NL, UK or US.

=item No string to test; pass a string to the function

Croaked by several methods that expect a value for the named argument B<string>, and when no such value is given. These methods require the letter-string to be passed to it as a I<key> => I<value> pair, with the key B<string> followed by the value of the string to test.

=item No string(s) to test; pass one or more letter-strings named \'strings\' as a referenced array

Same as above but specifically croaked by L<frq_hash|Lingua::Norms::SUBTLEX/frq_hash> which accepts more than one string in a single call.

=item Need to install and have access to module File::RandomLine

Croaked by method L<random_string|Lingua::Norms::SUBTLEX/random_string> if the module it depends on (File::RandomLine) is not installed or accessible. This should have been installed (if not already) upon installation of the present module. See L<CPAN|http://www.cpan.org> to download and install this module manually.

=back

=head1 DEPENDENCIES

L<File::RandomLine|File::RandomLine> : needed to work L<random_string|Lingua::Norms::SUBTLEX/random_string>.

L<File::Slurp|File::Slurp> : handy for directory reading when calling L<new|Lingua::Norms::SUBTLEX/new>.

L<Lingua::Orthon|Lingua::Orthon> : needed to calculate Levenshtein Distance, assessing orthographic neighbourhood.

L<List::AllUtils|List::AllUtils> : handy C<none> function.

L<Statistics::Lite|Statistics::Lite> : needed for the various statistical methods.

L<String::Util|String::Util> : utilities for determining valid string values.

L<Text::CSV::Separator|Text::CSV::Separator> : depended upon to determine the delimiter (comma or tab) within the datafiles.

=head1 REFERENCES

B<Brysbaert, M., Buchmeier, M., Conrad, M., Jacobs, A.M., Boelte, J., & Boehl, A.> (2011). The word frequency effect: A review of recent developments and implications for the choice of frequency estimates in German. I<Experimental Psychology>, I<58>, 412-424. doi: L<10.1027/1618-3169/a000123|http://dx.doi.org/10.1027/1618-3169/a000123>

B<Brysbaert, M., & New, B.> (2009). Moving beyond Kucera and Francis: A critical evaluation of current word frequency norms and the introduction of a new and improved word frequency measure for American English. I<Behavior Research Methods>, I<41>, 977-990. doi: L<10.3758/BRM.41.4.977|http://dx.doi.org/10.3758/BRM.41.4.977>

B<Brysbaert, M., New, B., & Keuleers,E.> (2012). Adding part-of-speech information to the SUBTLEX-US word frequencies. I<Behavior Research Methods>, I<44>, 991-997. doi: L<10.3758/s13428-012-0190-4|http://dx.doi.org/10.3758/s13428-012-0190-4>

B<Coltheart, M., Davelaar, E., Jonasson, J. T., & Besner, D.> (1977). Access to the internal lexicon. In S. Dornic (Ed.), I<Attention and performance> (Vol. 6, pp. 535-555). London, UK: Academic.

B<Keuleers, E., Brysbaert, M., & New, B.> (2010). SUBTLEX-NL: A new frequency measure for Dutch words based on film subtitles. I<Behavior Research Methods>, I<42>, 643-650. doi: L<10.3758/BRM.42.3.643|http://dx.doi.org/10.3758/BRM.42.3.643>

B<Van Heuven, W. J. B., Mandera, P., Keuleers, E., & Brysbaert, M.> (2014). SUBTLEX-UK: A new and improved word frequency database for British English. I<Quarterly Journal of Experimental Psychology>, I<67>, 1176-1190. doi: L<10.1080/17470218.2013.850521|http://dx.doi.org/10.1080/17470218.2013.850521>

B<Yarkoni, T., Balota, D. A., & Yap, M.> (2008). Moving beyond Coltheart's I<N>: A new measure of orthographic similarity. I<Psychonomic Bulletin and Review>, I<15>, 971-979. doi: L<10.3758/PBR.15.5.971|http://dx.doi.org/10.3758/PBR.15.5.971>

=head1 AUTHOR

Roderick Garton, C<< <rgarton at cpan.org> >>

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests to C<bug-lingua-norms-subtlfreq-0.05 at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Norms-SUBTLEX-0.05>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::Norms::SUBTLEX


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-Norms-SUBTLEX-0.05>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-Norms-SUBTLEX-0.05>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-Norms-SUBTLEX-0.05>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-Norms-SUBTLEX-0.05/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2015 Roderick Garton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.

To the maximum extent permitted by applicable law, the author of this module disclaims all warranties, either express or implied, including but not limited to implied warranties of merchantability and fitness for a particular purpose, with regard to the software and the accompanying documentation.

=cut

1;    # End of Lingua::Norms::SUBTLEX

