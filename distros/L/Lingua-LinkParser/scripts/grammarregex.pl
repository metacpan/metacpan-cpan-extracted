use strict;
use Lingua::LinkParser;

## Demonstrates the creation of a regular expression to match linkages
## within a sentence linkage string. Give it "Perl rocks!" as input.

my $parser   = new Lingua::LinkParser;

$parser->opts('disjunct_cost' => 2);
$parser->opts('linkage_limit' => 101);

while (1)
{
  print "Enter a sentence about somethig that 'rocks'> "; 
  my $input = <STDIN>;
  last if $input =~ /^\s*$/;
  my $sentence = $parser->create_sentence($input);
  my $linkage  = $sentence->linkage(1);
  # computing the union and then using the last sublinkage 
  # permits conjunctions.
  $linkage->compute_union;
  my $sublinkage = $linkage->sublinkage($linkage->num_sublinkages);
  
  my $what_rocks  = 'S[s|p]' .         # match the link label
                    '(?:[\w\*]{1,2})*'.# match any optional subscripts
                    '\:(\d+)\:' .      # match number of the word
                    '(\w+(?:\.\w)*)';  # match and save the word itself
  my $other_stuff = '[^\)]+';          # match other stuff within parenthesis
  my $rocks       = '\"(rock[s|ed]*).v\"';    # match and store verb

  # Fixed from printed code in TPJ #19.
  my $no_objects = '(?![^\)]* O.{1,3}:)';  # don't match objects

  my $pattern     = "$what_rocks $other_stuff $rocks $no_objects";

  if ( $sublinkage =~ /$pattern/mx )
  {
    my $wordobj = $sublinkage->word($1);
    my $wordtxt = $2;
    my $verb    = $3;
    my @wordlist = ();
    foreach my $link ($wordobj->links)
    {
      # proper nouns and noun modifiers
      if ($link->linklabel =~ /^G|AN|A/)
      {
        $wordlist[$link->linkposition] = $link->linkword;
      }
      # possessive pronouns, via a noun determiner
      if ($link->linklabel =~ /^D[s|m]/)
      {
        my $wword = $sublinkage->word($link->linkposition);
        foreach my $llink ($wword->links)
        {
          if ($llink->linklabel =~ /^YS/)
          {
            $wordlist[$llink->linkposition] = $llink->linkword;
            $wordlist[$link->linkposition]  = $link->linkword;
            my $wwword = $sublinkage->word($llink->linkposition);
            foreach my $lllink ($wwword->links)
            {
              if ($lllink->linklabel =~ /^G|AN/)
              {
                $wordlist[$lllink->linkposition] = $lllink->linkword;
              }
            }
          }
        }
      }
    }
    print "   -> ", join (" ", @wordlist, $wordtxt), "\n";
  }
}

