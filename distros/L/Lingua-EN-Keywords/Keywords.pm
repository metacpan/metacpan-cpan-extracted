package My::Tagger;
@My::Tagger::ISA=qw(Lingua::EN::Tagger);
my %known_stems;
sub stem {
    my ( $self, $word ) = @_;
    return $word unless $self->{'stem'};
    return $known_stems{ $word } if exists $known_stems{$word};
    my $stemref = Lingua::Stem::En::stem( -words => [ $word ] );

    $known_stems{ $word } = $stemref->[0] if exists $stemref->[0];
}

sub stems { reverse %known_stems; }

# To test:
package Lingua::EN::Keywords;
use Lingua::EN::Tagger;
require 5.005_62;
use strict;
use warnings;

my $t = My::Tagger->new(longest_noun_phrase => 5,weight_noun_phrases=>0);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw( keywords);
our $VERSION = '2.0';
sub keywords {
    my %wl = $t->get_words(shift);
    my %newwl; 
    $newwl{unstem($_)} += $wl{$_} for keys %wl;
    return (sort { $newwl{$b} <=> $newwl{$a} } keys %newwl)[0..5];
}
sub unstem {
    my %cache = $t->stems;
    my $word = shift;
    return $cache{$word} || $word;
}
#undef $/;
#my $in = <STDIN>;
#print ((join " ", ((),keywords($in))),"\n");
1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Lingua::EN::Keywords - Automatically extracts keywords from text

=head1 SYNOPSIS

  use Lingua::EN::Keywords;

  my @keywords = keywords($text);

=head1 DESCRIPTION

This is a very simple algorithm which removes stopwords from a
summarized version of a text (generated with Lingua::EN::Summarize)
and then counts up what it considers to be the most important
"keywords". The C<keywords> subroutine returns a list of five keywords
in order of relevance.

This is pretty dumb. Don't expect any clever document categorization
algorithms here, because you won't find them. But it does a reasonable
job.

=head2 EXPORT

C<keywords> subroutine.

=head1 AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 SEE ALSO

perl(1).

=cut
