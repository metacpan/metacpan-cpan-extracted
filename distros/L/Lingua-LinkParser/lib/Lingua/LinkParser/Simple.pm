package Lingua::LinkParser::Simple;

use 5.006;
use strict;

require Exporter;
use AutoLoader qw(AUTOLOAD);
use Lingua::LinkParser;

our @ISA = qw(Exporter);

our @EXPORT = qw(
  extract_subject
);
our $VERSION = '1.17';

sub new {
  my $class = shift;
  my $self = bless {}, $class;
  $self->{parser} = new Lingua::LinkParser;
  $self->{parser}->opts(
      'max_sentence_length' => 70,
      'panic_mode'          => 'TRUE',
      'max_parse_time'      => 20,
      'linkage_limit'       => 50,
      'short_length'        => 10,
      'disjunct_cost'       => 2,
      'min_null_count'      => 0,
      'max_null_count'      => 0,
  );
  $self;
}

sub extract_subject {
  my $self = shift;
  my %args = @_;
  my $sentence = $self->{parser}->create_sentence($args{sentence});
  return unless ($sentence);
  if ($sentence->num_linkages == 0) {
    $self->{parser}->opts('min_null_count' => 1,
                  'max_null_count' => $sentence->length);
    $sentence = $self->{parser}->create_sentence($args{sentence});
    return unless ($sentence);
      # print "null linkages found: ", $sentence->num_linkages, "\n";

      if ($sentence->num_linkages == 0) {
        $self->{parser}->opts('disjunct_cost'    => 3,
                    'min_null_count'   => 1,
                    'max_null_count'   => 30,
                    'max_parse_time'   => 20,
                    'islands_ok'       => 1,
                    'short_length'     => 6,
                    'all_short_connectors' => 1,
                    'linkage_limit'    => 50
        );
       $sentence = $self->{parser}->create_sentence($args{$sentence});
       return unless ($sentence);
    }
  }

  my $verb  = $args{verb};
  my $linkage  = $sentence->linkage(1);
  return unless ($linkage);
  # computing the union and then using the last sublinkage
  # permits conjunctions.
  $linkage->compute_union;
  my $sublinkage = $linkage->sublinkage($linkage->num_sublinkages);
  return unless ($sublinkage);

  my $subject = 'S[s|p]' .                   # singular and plural subject
                '(?:[\w\*]{1,2})*' .         # any optional subscripts
                ':(\d+):' .                  # number of the word
                '(\w+(?:\.\w)*)';            # and save the word itself
  my $other      = '[^\)]+';                 # junk, within the parenthesis
  my $verbre     = '"(' . $args{verb} . '*)\.v"';
                                             # singular and plural verbs
  my $no_objects = '(?![^\)]* O.{1,3}:)';    # don't match objects

  my $pattern = "$subject $other $verbre $no_objects";

  my $wordtxt;
  my @wordlist;
  if ($sublinkage =~ /$pattern/mx) {
    my $wordobj  = $sublinkage->word($1); # the stored word number
    $wordtxt  = $2;
    $verb     = $3;
    foreach my $link ($wordobj->links) { # process array of links
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
    return join (" ", @wordlist) . " $wordtxt";
  }
}

1;
__END__
=head1 NAME

Lingua::LinkParser::Simple - Experiments with some high-level link grammar processing.

=head1 SYNOPSIS

  use Lingua::LinkParser::Simple;
  @subjects = extract_subject(sentence => $sentence, verb => $verb);

=head1 DESCRIPTION

This module allows simple but incomplete access to the features provided by 
Lingua::LinkParser, and should be considered purely experimental. If you have
any cool functions you'd like added here, let me know.

=item extract_subject(sentence => STRING, verb => WORD)

This function tries to parse the sentence, find the specified verb, and return
all words (or noun phrases) that are subjects for that verb.

=head1 AUTHOR

Danny Brian <danny@brians.org>

=head1 SEE ALSO

L<perl>.

=cut
