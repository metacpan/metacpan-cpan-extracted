package Lingua::Sentence;

use strict;
use warnings;

use Carp           ();
use File::ShareDir ();
use File::Spec     ();
use Path::Tiny     ();

our $VERSION = '1.100';
$VERSION = eval $VERSION;

sub new {
    my ($class, $lang_id, $prefix_file) = @_;
    Carp::croak("Invalid language id: $lang_id")
        unless ($lang_id && $lang_id =~ /^[a-z][a-z]$/i);

    # Try loading nonbreaking prefix file specified in constructor
    my $dir = File::ShareDir::dist_dir('Lingua-Sentence');
    my $fallback = File::Spec->catfile($dir, 'nonbreaking_prefix.' . $lang_id);
    my $fallback_en = File::Spec->catfile($dir, 'nonbreaking_prefix.en');
    if (defined($prefix_file)) {
        unless (-e $prefix_file) {
            warn
                "WARNING: Specified prefix file '$prefix_file' does not exist, attempting fall-back to $lang_id version...\n";
            $prefix_file = $fallback;
        }
    }
    else {
        $prefix_file = $fallback;
    }

    #default back to English if we don't have a language-specific prefix file
    unless (-e $prefix_file) {
        $prefix_file = $fallback_en;
        warn
            "WARNING: No known abbreviations for language '$lang_id', attempting fall-back to English version...\n";
    }

    # grab all non-breaking prefixes and store them in a hashref
    my $nb_prefix = {};
    my $pt        = Path::Tiny::path($prefix_file);
    if ($pt->is_file) {
        for my $line ($pt->lines_utf8({chomp => 1})) {
            next unless $line;
            next if substr($line, 0, 1) eq '#';
            if ($line =~ /^(.*?)\s+#NUMERIC_ONLY#/) {
                $nb_prefix->{$1} = 2;
            }
            else {
                $nb_prefix->{$line} = 1;
            }
        }
    }
    else {
        die("ERROR: No abbreviations files found in $dir\n");
    }

    return bless {LangID => $lang_id, Nonbreaking => $nb_prefix,}, $class;
}

sub split {
    my $self = shift;
    if (!ref $self) {
        return "Unnamed $self";
    }
    my $text = shift;
    if (!$text) {
        return '';
    }
    return _preprocess($self, $text);
}

sub split_array {
    my $self = shift;
    if (!ref $self) {
        return "Unnamed $self";
    }
    my $text = shift;
    if (!$text) {
        return ();
    }
    my $splittext = _preprocess($self, $text);
    chomp $splittext;
    return split(/\n/, $splittext);
}

sub _preprocess {
    my ($self, $text) = @_;

    #####add sentence breaks as needed#####

    #non-period end of sentence markers (?!) followed by sentence starters.
    $text =~ s/([?!]) +(['"([\x{00bf}\x{00A1}\p{IsPi}]*[\p{IsUpper}])/$1\n$2/g;

    #multi-dots followed by sentence starters
    $text
        =~ s/(\.[\.]+) +(['"([\x{00bf}\x{00A1}\p{IsPi}]*[\p{IsUpper}])/$1\n$2/g;

# add breaks for sentences that end with some sort of punctuation inside a quote or parenthetical and are followed by a possible sentence starter punctuation and upper case
    $text
        =~ s/([?!\.][\ ]*['")\]\p{IsPf}]+) +(['"([\x{00bf}\x{00A1}\p{IsPi}]*[\ ]*[\p{IsUpper}])/$1\n$2/g;

# add breaks for sentences that end with some sort of punctuation are followed by a sentence starter punctuation and upper case
    $text
        =~ s/([?!\.]) +(['"([\x{00bf}\x{00A1}\p{IsPi}]+[\ ]*[\p{IsUpper}])/$1\n$2/g;

    # special punctuation cases are covered. Check all remaining periods.
    my $word;
    my $i;
    my @words = split(/ +/, $text);
    $text = "";
    for ($i = 0; $i < (scalar(@words) - 1); $i++) {
        if ($words[$i] =~ /([\p{IsAlnum}\.\-]*)([\'\"\)\]\%\p{IsPf}]*)(\.+)$/) {

            #check if $1 is a known honorific and $2 is empty, never break
            my $prefix         = $1;
            my $starting_punct = $2;
            if (   $prefix
                && $self->{Nonbreaking}{$prefix}
                && $self->{Nonbreaking}{$prefix} == 1
                && !$starting_punct)
            {
                #not breaking;
            }
            elsif ($words[$i] =~ /(\.)[\p{IsUpper}\-]+(\.+)$/) {

                #not breaking - upper case acronym
            }
            elsif ($words[$i + 1]
                =~ /^([ ]*['"([\x{00bf}\x{00A1}\p{IsPi}]*[ ]*[\p{IsUpper}0-9])/)
            {
#the next word has a bunch of initial quotes, maybe a space, then either upper case or a number
                $words[$i] = $words[$i] . "\n"
                    unless ($prefix
                    && $self->{Nonbreaking}{$prefix}
                    && $self->{Nonbreaking}{$prefix} == 2
                    && !$starting_punct
                    && ($words[$i + 1] =~ /^[0-9]+/));

#we always add a return for these unless we have a numeric non-breaker and a number start
            }

        }
        $text = $text . $words[$i] . " ";
    }

 #we stopped one token from the end to allow for easy look-ahead. Append it now.
    $text = $text . $words[$i];

   # clean up spaces at head and tail of each line as well as any double-spacing
    $text =~ s/ +/ /g;
    $text =~ s/\n /\n/g;
    $text =~ s/ \n/\n/g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    #add trailing break
    $text .= "\n" unless $text =~ /\n$/;

    return $text;
}

1;
__END__

=head1 NAME

Lingua::Sentence - Perl extension for breaking text paragraphs into sentences

=head1 SYNOPSIS

	use Lingua::Sentence;

	my $splitter = Lingua::Sentence->new("en");

	my $text = 'This is a paragraph. It contains several sentences. "But why," you ask?';

	print $splitter->split($text);


=head1 DESCRIPTION

This module allows splitting of text paragraphs into sentences. It is based on scripts developed by Philipp Koehn and Josh Schroeder for processing the Europarl corpus (L<http://www.statmt.org/europarl/>).

The module uses punctuation and capitalization clues to split paragraphs into an newline-separated string with one sentence per line. For example:

	This is a paragraph. It contains several sentences. "But why," you ask?

goes to:

	This is a paragraph.
	It contains several sentences.
	"But why," you ask?

Languages currently supported by the module are:

=over


=item Catalan

=item Czech

=item Dutch

=item English

=item French

=item German

=item Greek

=item Hungarian

=item Icelandic

=item Italian

=item Latvian

=item Polish

=item Portuguese

=item Russian

=item Spanish

=item Slovak

=item Slovenian

=item Swedish

=back

=head2 Nonbreaking Prefixes Files

Nonbreaking prefixes are loosely defined as any word ending in a period that does NOT indicate an end of sentence marker. A basic example is Mr. and Ms. in English.

The sentence splitter module uses the nonbreaking prefix files included in this distribution.

To add a file for other languages, follow the naming convention nonbreaking_prefix.?? and use the two-letter language code you intend to use when creating a Lingua::Sentence object.

The sentence splitter module will first look for a file for the language it is processing, and fall back to English if a file
for that language is not found.

For the splitter, normally a period followed by an uppercase word results in a sentence split. If the word preceeding the period
is a nonbreaking prefix, this line break is not inserted.

A special case of prefixes, NUMERIC_ONLY, is included for special cases where the prefix should be handled ONLY when before numbers.
For example, "Article No. 24 states this." the No. is a nonbreaking prefix. However, in "No. It is not true." No functions as a word.

See the example prefix files included in the distribution for more examples.

=head3 CREDITS

Thanks for the following individuals for supplying nonbreaking prefix files:
Bas Rozema (Dutch), HilE<aacute>rio Leal Fontes (Portuguese), JesE<uacute>s GimE<eacute>nez (Catalan & Spanish), Anne-Kathrin Schumann (Russian)

=head2 EXPORT

=over

=item new($lang_id)

Instantiate an object to split sentences in language $lang_id. If the language is not supported, a splitter object for English will be instantiated.

=item new($lang_id,$nonbreaking_prefix_file)

Instantiate an object to split sentences in language $lang_id and the nonbreaking prefix file $nonbreaking_prefix_file. If the file does not exist, a splitter object for English will be instantiated.

=item split($text)

Split sentences in $text by inserting newline characters at the sentence breaks. The resulting string is also terminated with a newline.

=item split_array($text)

Split sentences in $text into an array of sentences.

=back

=head1 SUPPORT

Bugs should always be submitted via the project hosting bug tracker

L<http://code.google.com/p/corpus-tools/issues/list>

For other issues, contact the maintainer.

=head1 SEE ALSO

L<Text::Sentence>, L<Lingua::EN::Sentence>, L<Lingua::DE::Sentence>, L<Lingua::HE::Sentence>

=head1 AUTHOR

Achim Ruopp, E<lt>achimru@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Digital Silk Road

Portions Copyright (C) 2005 by Philip Koehn and Josh Schroeder (used with permission)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
