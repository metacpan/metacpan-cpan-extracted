=head

Demo program of CPAN module Lingua::EN::Sentence, sentence splitter

=cut

use strict;
use warnings;


use Lingua::EN::Sentence qw( get_sentences add_acronyms  get_EOS set_EOS set_locale);

my $text = q{First sentence.
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


print("Started\n");
my $sentences=get_sentences($text);     ## Get the sentences.
my $num_sentences = (@$sentences);

print("There are: $num_sentences sentences\n" );
my $i;
foreach my $sent (@$sentences)
{
    $i++;
    print("SENTENCE $i >>>$sent<<<\n");
}





