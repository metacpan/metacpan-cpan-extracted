=head

Demo program of CPAN module Lingua::EN::Sentence, sentence splitter

=cut
use strict;
use warnings;
use Lingua::EN::Sentence qw( get_sentences add_acronyms  get_EOS set_EOS set_locale);

print("Started\n");
my $text = q{
A sentence usually ends with a dot, exclamation or question mark optionally followed by a space!
A string followed by 2 carriage returns denotes a sentence, even though it doesn't end in a dot

Dots after single letters such as U.S.A. or in numbers like -12.34 will not cause a split
as well as common abbreviations such as Dr. I. Smith, Ms. A.B. Jones, Apr. Calif. Esq.
and (some text) ellipsis such as ... or . . are ignored.
Some valid cases canot be deteected, such as the answer is X. It cannot easily be
differentiated from the single letter-dot sequence to abbreviate a person's given name.
Numbered points within a sentence will not cause a split 1. Like this one.
See the code for all the rules that apply.
This string has 7 sentences.
};

my $sentences=get_sentences($text);     ## Get the sentences.
my $num_sentences = (@$sentences);
my $i;
print("There are: $num_sentences sentences\n" );
foreach my $sent (@$sentences)
{
    $i++;
    print("SENTENCE $i:$sent\n");
}

 $text = q{First sentence.
12. point 12
Some numbers 12.46, -.123,3:.
Some ‘utf quotes wrap this’ “And more”};

# Filter out common multi byte characters, such as the utf symbols for curly quotes
# These will cause wide character warnings to be issued
$text =~ s/‘/'/g;
$text =~ s/’/'/g;  
$text =~ s/“/"/g;
$text =~ s/”/"/g;

# Change lines starting with numbered points from x. to x) to avoid confusion with dots
 $text =~ s/\n(\d{1,})./\n$1\)/g;
 
 $sentences=get_sentences($text);     ## Get the sentences.
my $num_sentences = (@$sentences);
foreach my $sent (@$sentences)
{
    print("$sent\n");
}










