package Lingua::Identify;

use 5.006;
use strict;
use warnings;

use utf8;
use base 'Exporter';

our %EXPORT_TAGS =
  (
   all => [ qw(
                  langof			
                  langof_file
                  confidence
                  get_all_methods
                  activate_all_languages
                  deactivate_all_languages
                  get_all_languages
                  get_active_languages
                  get_inactive_languages
                  is_active
                  is_valid_language
                  activate_language
                  deactivate_language
                  set_active_languages
                  name_of
             )
          ],
   language_identification => [ qw(
                                      langof
                                      langof_file
                                      confidence		
                                      get_all_methods
                                 )
                              ],

   language_manipulation => [ qw(
                                    activate_all_languages
                                    deactivate_all_languages
                                    get_all_languages	
                                    get_active_languages
                                    get_inactive_languages	
                                    is_active
                                    is_valid_language	
                                    activate_language
                                    deactivate_language
                                    set_active_languages
                                    name_of
                               )
                            ],
  );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();

our $VERSION = '0.56';


# DEFAULT VALUES #
our %default_methods    = qw/smallwords 1.3 prefixes2 1.5 suffixes3 1.5 ngrams3 1.2/;
my $default_maxsize     = 1_000_000;
my %default_extractfrom = qw/head 1/;

=head1 NAME

Lingua::Identify - Language identification

=head1 SYNOPSIS

  use Lingua::Identify qw(:language_identification);
  $a = langof($textstring); # gives the most probable language

or the complete way:

  @a = langof($textstring); # gives pairs of languages / probabilities
                            # sorted from most to least probable

  %a = langof($textstring); # gives a hash of language / probability

or the expert way (see section OPTIONS, under HOW TO PERFORM IDENTIFICATION)

  $a = langof( { method => [qw/smallwords prefix2 suffix2/] }, $text);

  $a = langof( { 'max-size' => 3_000_000 }, $text);

  $a = langof( { 'extract_from' => ( 'head' => 1, 'tail' => 2)}, $text);

=head1 DESCRIPTION

B<STARTING WITH VERSION 0.25, Lingua::Identify IS UNICODE BY DEFAULT!>

C<Lingua::Identify> identifies the language a given string or file is
written in.

See section WHY LINGUA::IDENTIFY for a list of C<Lingua::Identify>'s strong
points.

See section KNOWN LANGUAGES for a list of available languages and HOW TO
PERFORM IDENTIFICATION to know how to really use this module.

If you're in a hurry, jump to section EXAMPLES, way down below.

Also, don't forget to read the following section, IMPORTANT WARNING.

=head1 A WARNING ON THE ACCURACY OF LANGUAGE IDENTIFICATION METHODS

Take a word that exists in two different languages, take a good look at it and
answer this question: "What language does this word belong to?".

You can't give an answer like "Language X", right? You can only say it looks
like any of a set of languages.

Similarly, it isn't always easy to identify the language of a text if the only
two active languages are very similar.

Now that we've taken out of the way the warning that language identification
is not 100% accurate, please keep reading the documentation.

=head1 WHY LINGUA::IDENTIFY

You might be wondering why you should use Lingua::Identify instead of any other
tool for language identification.

Here's a list of Lingua::Identify's strong points:

=over 6

=item * it's free and it's open-source;

=item * it's portable (it's Perl, which means it will work in lots of different
platforms);

=item * unicode support;

=item * 4 different methods of language identification and growing (see
METHODS OF LANGUAGE IDENTIFICATION for more details on this one);

=item * it's a module, which means you can easily write your own application
(be it CGI, TK, whatever) around it;

=item * it comes with I<langident>, which means you don't actually need to
write your own application around it;

=item * it's flexible (at the moment, you can actually choose the
methods to use and their relevance, the max size of input to analyze
each time and which part(s) of the input to analyze)

=item * it supports big inputs (through the 'max-size' and
'extract_from' options)

=item * it's easy to deal with languages (you can activate and
deactivate the ones you choose whenever you want to, which can improve
your times and accuracy);

=item * it's maintained.

=back

=cut

# initialization

our (@all_languages,@active_languages,%languages,%regexen,@methods);
BEGIN {

    use Class::Factory::Util;
    for ( Lingua::Identify->subclasses() ) {
        /^[A-Z][A-Z]$/ || next;
        eval "require Lingua::Identify::$_ ;";
        if ($languages{_versions}{lc $_} < 0.02) {
            for my $k (keys %languages) {
                delete($languages{$k}{lc $_}) if exists $languages{$k}{lc $_};
            }
        }
    }

    @all_languages = @active_languages = keys %{$languages{_names}};

    @methods = qw/smallwords/;

}

=head1 HOW TO PERFORM IDENTIFICATION

=head2 langof

To identify the language a given text is written in, use the I<langof> function.
To get a single value, do:

  $language = langof($text);

To get the most probable language and also the percentage of its probability,
do:

  ($language, $probability) = langof($text);

If you want a hash where each active language is mapped into its percentage,
use this:

  %languages = langof($text);

=cut

sub langof {
    my %config = ();
    %config = (%config, %{+shift}) if ref($_[0]) eq 'HASH';

=head3 OPTIONS

I<langof> can also be given some configuration parameters, in this way:

  $language = langof(\%config, $text);

These parameters are detailed here:

=over 6

=item * B<extract-from>

When the size of the input exceeds the C'max-size', C<langof> analyzes
only the beginning of the file. You can specify which part of the file
is analyzed with the 'extract-from' option:

  langof( { 'extract_from' => 'tail' } , $text );

Possible values are 'head' and 'tail' (for now).

You can also specify more than one part of the file, so that text is
extracted from those parts:

  langof( { 'extract_from' => [ 'head', 'tail' ] } , $text );

(this will be useful when more than two possibilities exist)

You can also specify different values for each part of the file (not
necessarily for all of them:

 langof( { 'extract_from' => { head => 40, tail => 60 } } , $text);

The line above, for instance, retrives 40% of the text from the
beginning and 60% from the end. Note, however, that those values are
not percentages. You'd get the same behavior with:

 langof( { 'extract_from' => { head => 80, tail => 120 } } , $text);

The percentages would be the same.

=item * B<max-size>

By default, C<langof> analyzes only 1,000,000 bytes. You can specify
how many bytes (at the most) can be analyzed (if not enough exist, the
whole input is still analyzed).

  langof( { 'max-size' => 2000 }, $text);

If you want all the text to be analyzed, set max-size to 0:

  langof( { 'max-size' => 0 }, $text);

See also C<set_max_size>.

=item * B<method>

You can choose which method or methods to use, and also the relevance of each of
them.

To choose a single method to use:

  langof( {method => 'smallwords' }, $text);

To choose several methods:

  langof( {method => [qw/prefixes2 suffixes2/]}, $text);

To choose several methods and give them different weight:

  langof( {method => {smallwords => 0.5, ngrams3 => 1.5} }, $text);

To see the list of available methods, see section METHODS OF LANGUAGE
IDENTIFICATION.

If no method is specified, the configuration for this parameter is the
following (this might change in the future):

  method => {
    smallwords => 0.5,
    prefixes2  => 1,
    suffixes3  => 1,
    ngrams3    => 1.3
  };

=item * B<mode>

By default, C<Lingua::Identify> assumes C<normal> mode, but others are
available.

In C<dummy> mode, instead of actually calculating anything,
C<Lingua::Identify> only does the preparation it has to and then
returns a bunch of information, including the list of the active
languages, the selected methods, etc. It also returns the text meant
to be analised.

Do be warned that, with I<langof_file>, the dummy mode still reads the
files, it simply doesn't calculate language.

  langof( { 'mode' => 'dummy' }, $text);

This returns something like this:

  { 'methods'          => {   'smallwords' => '0.5',
                              'prefixes2'  => '1',
                          },
    'config'           => {   'mode' => 'dummy' },
    'max-size'         => 1000000,
    'active-languages' => [ 'es', 'pt' ],
    'text'             => $text,
    'mode'             => 'dummy',
  }

=back

=cut

    # select the methods
    my %methods = defined $config{'method'}   ? _make_hash($config{'method'})
                                              : %default_methods;

    # select max-size
    my $maxsize = defined $config{'max-size'} ? $config{'max-size'}
                                              : $default_maxsize;

    # get the text
    my $text = join "\n", @_;
    return wantarray ? () : undef unless $text;

    # this is the support for big files; if the input is bigger than the $maxsize, we act
    if ($maxsize < length $text && $maxsize != 0) {
        # select extract_from
        my %extractfrom = defined $config{'extract_from'} ? _make_hash($config{'extract_from'})
                                                          : %default_extractfrom;
        my $total_weight = 0;
        for (keys %extractfrom) {
            if ($_ eq 'head' or $_ eq 'tail') {
                $total_weight += $extractfrom{$_};
                next;
            }
            else {
                delete $extractfrom{$_};
            }
        }
        for (keys %extractfrom) {
            $extractfrom{$_} = $extractfrom{$_} / $total_weight;
        }

        $extractfrom{'head'} ||= 0;
        $extractfrom{'tail'} ||= 0;

        my $head = int $maxsize * $extractfrom{'head'};
        my $tail = length($text) - $head - int $maxsize * $extractfrom{'tail'};
        substr( $text, $head, $tail, '');
    }

    # dummy mode exits here
    $config{'mode'} ||= 'normal';
    if ($config{'mode'} eq 'dummy') {
        return {
                'method'           => \%methods,
                'max-size'         => $maxsize,
                'config'           => \%config,
                'active-languages' => [ sort (get_active_languages()) ],
                'text'             => $text,
                'mode'             => $config{'mode'},
               };
    }

    # use the methods
    my (%result, $total);
    for (keys %methods) {
        my %temp_result;

        if (/^smallwords$/) {
            %temp_result = _langof_by_word_method('smallwords', $text);
        }
        elsif (/^(prefixes[1-4])$/) {
            %temp_result = _langof_by_prefix_method($1, $text);
        }
        elsif (/^(suffixes[1-4])$/) {
            %temp_result = _langof_by_suffix_method($1, $text);
        }
        elsif (/^(ngrams[1-4])$/) {
            %temp_result = _langof_by_ngram_method($1, $text);
        }

        for my $l (keys %temp_result) {
            my $temp = $temp_result{$l} * $methods{$_};
            $result{$l} += $temp;
            $total += $temp;
        }
    }

    # report the results
    my @result = (
                  map  { ( $_, ($total ? $result{$_} / $total : 0)) }
                  sort { $result{$b} <=> $result{$a} } keys %result
                 );

    return wantarray ? @result : $result[0];
}

sub _make_hash {
    my %hash;
    my $temp = shift;
    for (ref($temp)) {
        if (/^HASH$/) {
            %hash = %{$temp};
        }
        elsif (/^ARRAY$/) {
            for (@{$temp}) {
                $hash{$_}++;
            }
        }
        else {
            $hash{$temp} = 1;
        }
    }
    %hash;
}

=head2 langof_file

I<langof_file> works just like I<langof>, with the exception that it
reveives filenames instead of text. It reads these texts (if existing
and readable, of course) and parses its content.

Currently, I<langof_file> assumes the files are regular text. This may
change in the future and the files might be scanned to check their
filetype and then parsed to extract only their textual content (which
should be pretty useful so that you can perform language
identification, say, in HTML files, or PDFs).

To identify the language a file is written in:

  $language = langof_file($path);

To get the most probable language and also the percentage of its probability,
do:

  ($language, $probability) = langof_file($path);

If you want a hash where each active language is mapped into its percentage,
use this:

  %languages = langof_file($path);

If you pass more than one file to I<langof_file>, they will all be
read and their content merged and then parsed for language
identification.

=cut

sub langof_file {
  my %config = ();
  if (ref($_[0]) eq 'HASH') {%config = (%config, %{+shift})}

=head3 OPTIONS

I<langof_file> accepts all the options I<langof> does, so refer to
those first (up in this document).

  $language = langof_file(\%config, $path);

I<langof_file> currently only reads the first 10,000 bytes of each
file.

You can force an input encoding with C<< { encoding => 'ISO-8859-1' } >> 
in the configuration hash.

=cut

  # select max-size
  my $maxsize = defined $config{'max-size'} ? $config{'max-size'}
                                            : $default_maxsize;

  my @files = @_;
  my $text  = '';

  for my $file (@files) {
      #-r and -e or next;
      if (exists($config{encoding})) {
          open(FILE, "<:encoding($config{encoding})", $file) or next;
      } else {
          open(FILE, "<:utf8", $file) or next;
      }
      local $/ = \$maxsize;
      $text .= <FILE>;
      close(FILE);
  }

  return langof(\%config,$text);
}

=head2 confidence

After getting the results into an array, its first element is the most probable
language. That doesn't mean it is very probable or not.

You can find more about the likeliness of the results to be accurate by
computing its confidence level.

  use Lingua::Identify qw/:language_identification/;
  my @results = langof($text);
  my $confidence_level = confidence(@results);
  # $confidence_level now holds a value between 0.5 and 1; the higher that
  # value, the more accurate the results seem to be

The formula used is pretty simple: p1 / (p1 + p2) , where p1 is the
probability of the most likely language and p2 is the probability of
the language which came in second. A couple of examples to illustrate
this:

English 50% Portuguese 10% ...

confidence level: 50 / (50 + 10) = 0.83

Another example:

Spanish 30% Portuguese 10% ...

confidence level: 30 / (25 + 30) = 0.55

French 10% German 5% ...

confidence level: 10 / (10 + 5) = 0.67

As you can see, the first example is probably the most accurate one.
Are there any doubts? The English language has five times the
probability of the second language.

The second example is a bit more tricky. 55% confidence. The
confidence level is always above 50%, for obvious reasons. 55% doesn't
make anyone confident in the results, and one shouldn't be, with
results such as these.

Notice the third example. The confidence level goes up to 67%, but the
probability of French is of mere 10%. So what? It's twice as much as
the second language. The low probability may well be caused by a great
number of languages in play.

=cut

sub confidence {
    defined $_[1] and $_[1] or return 0;
    defined $_[3] and $_[3] or return 1;
    $_[1] / ($_[1] + $_[3]);
}

=head2 get_all_methods

Returns a list comprised of all the available methods for language
identification.

=cut

sub get_all_methods {
  qw/smallwords
     prefixes1 prefixes2 prefixes3 prefixes4
     suffixes1 suffixes2 suffixes3 suffixes4
     ngrams1 ngrams2 ngrams3 ngrams4/
}

=head1 LANGUAGE IDENTIFICATION IN GENERAL

Language identification is based in patterns.

In order to identify the language a given text is written in, we repeat a given
process for each active language (see section LANGUAGES MANIPULATION); in that
process, we look for common patterns of that language. Those patterns can be
prefixes, suffixes, common words, ngrams or even sequences of words.

After repeating the process for each language, the total score for each of them
is then used to compute the probability (in percentage) for each language to be
the one of that text.

=cut

sub _langof_by_method {
    my ($method, $elements, $text) = @_;
    my (%result, $total);

    for my $language (get_active_languages()) {
        for (keys %{$languages{$method}{$language}}) {
            if (exists $$elements{$_}) {
                $result{$language} +=
                  $$elements{$_} * ${languages{$method}{$language}{$_}};
                $total +=
                  $$elements{$_} * ${languages{$method}{$language}{$_}};
            }
        }
    }

    my @result = (
                  map  { ( $_, ($total ? $result{$_} / $total : 0)) }
                  sort { $result{$b} <=> $result{$a} } keys %result
                 );

    return wantarray ? @result : $result[0];
}

=head1 METHODS OF LANGUAGE IDENTIFICATION

C<Lingua::Identify> currently comprises four different ways for language
identification, in a total of thirteen variations of those.

The available methods are the following: B<smallwords>, B<prefixes1>,
B<prefixes2>, B<prefixes3>, B<prefixes4>, B<suffixes1>, B<suffixes2>,
B<suffixes3>, B<suffixes4>, B<ngrams1>, B<ngrams2>, B<ngrams3> and B<ngrams4>.

Here's a more detailed explanation of each of those ways and those methods

=head2 Small Word Technique - B<smallwords>

The "Small Word Technique" searches the text for the most common words of each
active language. These words are usually articles, pronouns, etc, which happen
to be (usually) the shortest words of the language; hence, the method name.

This is usually a good method for big texts, especially if you happen to have
few languages active.

=cut

sub _langof_by_word_method {
    my ($method, $text) = @_;

    sub _words_count {
        my ($words, $text) = @_;
        for my $word (split /[\s\n]+/, $text) {
            $words->{$word}++
        }
    }

    my %words;
    _words_count(\%words, $text);
    return _langof_by_method($method, \%words, $text);
}

=head2 Prefix Analysis - B<prefixes1>, B<prefixes2>, B<prefixes3>, B<prefixes4>

This method analyses text for the common prefixes of each active language.

The methods are, respectively, for prefixes of size 1, 2, 3 and 4.

=cut

sub _langof_by_prefix_method {
    use Text::Affixes;

    (my $method = shift) =~ /^prefixes(\d)$/;
    my $text = shift;

    my $prefixes = get_prefixes( {min => $1, max => $1}, $text);

    return _langof_by_method($method, $$prefixes{$1}, $text);
}

=head2 Suffix Analysis - B<suffixes1>, B<suffixes2>, B<suffixes3>, B<suffixes4>

Similar to the Prefix Analysis (see above), but instead analysing common
suffixes.

The methods are, respectively, for suffixes of size 1, 2, 3 and 4.

=cut

sub _langof_by_suffix_method {
  use Text::Affixes;

  (my $method = shift) =~ /^suffixes(\d)$/;
  my $text = shift;

  my $suffixes = get_suffixes({min => $1, max => $1}, $text);

  return _langof_by_method($method, $$suffixes{$1}, $text);
}

###

# Have you seen my brother? He's a two line long comment. I think he
# might be lost... :-\ Me and my father have been looking for him for
# some time now :-/

###

=head2 Ngram Categorization - B<ngrams1>, B<ngrams2>, B<ngrams3>, B<ngrams4>

Ngrams are sequences of tokens. You can think of them as syllables, but they
are also more than that, as they are not only comprised by characters, but also
by spaces (delimiting or separating words).

Ngrams are a very good way for identifying languages, given that the most
common ones of each language are not generally very common in others.

This is usually the best method for small amounts of text or too many active
languages.

The methods are, respectively, for ngrams of size 1, 2, 3 and 4.

=cut

sub _langof_by_ngram_method {
  use Text::Ngram qw(ngram_counts);

  (my $method = shift) =~ /^ngrams([1-4])$/;
  my $text = shift;

  my $ngrams = ngram_counts( {spaces => 0}, $text, $1);

  return _langof_by_method($method, $ngrams, $text);
}

=head1 LANGUAGE MANIPULATION

When trying to perform language identification, C<Lingua::Identify> works not with
all available languages, but instead with the ones that are active.

By default, all available languages are active, but that can be changed by the
user.

For your convenience, several methods regarding language manipulation were
created. In order to use them, load the module with the tag
:language_manipulation.

These methods work with the two letters code for languages.

=over 6

=item B<activate_language>

Activate a language

  activate_language('en');

  # or

  activate_language($_) for get_all_languages();

=cut

sub activate_language {
  unless (grep { $_ eq $_[0] } @active_languages) {
    push @active_languages, $_[0];
  }
  return @active_languages;
}

=item B<activate_all_languages>

Activates all languages

  activate_all_languages();

=cut

sub activate_all_languages {
  @active_languages = get_all_languages();
  return @active_languages;
}

=item B<deactivate_language>

Deactivates a language

  deactivate_language('en');

=cut

sub deactivate_language {
  @active_languages = grep { ! ($_ eq $_[0]) } @active_languages;
  return @active_languages;
}

=item B<deactivate_all_languages>

Deactivates all languages

  deactivate_all_languages();

=cut

sub deactivate_all_languages {
  @active_languages = ();
  return @active_languages;
}

=item B<get_all_languages>

Returns the names of all available languages

  my @all_languages = get_all_languages();

=cut

sub get_all_languages {
  return @all_languages;
}

=item B<get_active_languages>

Returns the names of all active languages

  my @active_languages = get_active_languages();

=cut

sub get_active_languages {
  return @active_languages;
}

=item B<get_inactive_languages>

Returns the names of all inactive languages

  my @active_languages = get_inactive_languages();

=cut

sub get_inactive_languages {
  return grep { ! is_active($_) } get_all_languages();
}

=item B<is_active>

Returns the name of the language if it is active, an empty list otherwise

  if (is_active('en')) {
    # YOUR CODE HERE
  }

=cut

sub is_active {
  return grep { $_ eq $_[0] } get_active_languages();
}

=item B<is_valid_language>

Returns the name of the language if it exists, an empty list otherwise

  if (is_valid_language('en')) {
    # YOUR CODE HERE
  }

=cut

sub is_valid_language {
  return grep { $_ eq $_[0] } get_all_languages();
}

=item B<set_active_languages>

Sets the active languages

  set_active_languages('en', 'pt');

  # or

  set_active_languages(get_all_languages());

=cut

sub set_active_languages {
  @active_languages = grep { is_valid_language($_) } @_;
  return @active_languages;
}

=item B<name_of>

Given the two letter tag of a language, returns its name

  my $language_name = name_of('pt');

=cut

sub name_of {
  my $tag = shift || return undef;
  return $languages{_names}{$tag};
}

=back

=cut

1;
__END__

=head1 KNOWN LANGUAGES

Currently, C<Lingua::Identify> knows the following languages (33 total):

=over 6

=item AF - Afrikaans

=item BG - Bulgarian

=item BR - Breton

=item BS - Bosnian

=item CY - Welsh

=item DA - Danish

=item DE - German

=item EN - English

=item EO - Esperanto

=item ES - Spanish

=item FI - Finnish

=item FR - French

=item FY - Frisian

=item GA - Irish

=item HR - Croatian

=item HU - Hungarian

=item ID - Indonesian

=item IS - Icelandic

=item IT - Italian

=item LA - Latin

=item MS - Malay

=item NL - Dutch

=item NO - Norwegian

=item PL - Polish

=item PT - Portuguese

=item RO - Romanian

=item RU - Russian

=item SL - Slovene

=item SO - Somali

=item SQ - Albanian

=item SV - Swedish

=item SW - Swahili

=item TR - Turkish

=back

=head1 CONTRIBUTING WITH NEW LANGUAGES

Please do not contribute with modules you made yourself. It's easier
to contribute with unprocessed text, because that allows for new
versions of Lingua::Identify not having to drop languages down in case
I can't contact you by that time.

Use I<make-lingua-identify-language> to create a new module for your
own personal use, if you must, but try to contribute with unprocessed
text rather than those modules.

=head1 EXAMPLES

=head2 THE BASIC EXAMPLE

Check the language a given text file is written in:

  use Lingua::Identify qw/langof/;

  my $text = join "\n", <>;

  # identify the language by letting the module decide on the best way
  # to do so
  my $language = langof($text);

=head2 IDENTIFYING BETWEEN TWO LANGUAGES

Check the language a given text file is written in, supposing you
happen to know it's either Portuguese or English:

  use Lingua::Identify qw/langof set_active_languages/;
  set_active_languages(qw/pt en/);

  my $text = join "\n", <>;

  # identify the language by letting the module decide on the best way
  # to do so
  my $language = langof($text);

=head1 TO DO

=over 6

=item * WordNgrams based methods;

=item * More languages (always);

=item * File recognition and treatment;

=item * Deal with different encodings;

=item * Create sets of languages and allow their activation/deactivation;

=item * There should be a way of knowing the default configuration
(other than using the dummy mode, of course, or than accessing the variables
directly);

=item * Add a section about other similar tools.

=back

=head1 ACKNOWLEDGMENTS

The following people and/or projects helped during this tool
development:

   * EuroParl v5 corpus was used to train Dutch, German, English,
     Spanish, Finish, French, Italian, Portuguese, Danish and Swedish.

=head1 SEE ALSO

langident(1), Text::ExtractWords(3), Text::Ngram(3), Text::Affixes(3).

ISO 639 Language Codes, at http://www.w3.org/WAI/ER/IG/ert/iso639.htm

=head1 AUTHOR

Alberto Simoes, C<< <ambs@cpan.org> >>

Jose Castro, C<< <cog@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Alberto Simoes, All Rights Reserved.
Copyright 2004-2008 Jose Castro, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
