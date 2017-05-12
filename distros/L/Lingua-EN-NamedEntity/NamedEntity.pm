package Lingua::EN::NamedEntity;

use Lingua::Stem::En;
Lingua::Stem::En::stem_caching({ -level => 2});

use 5.006;
use strict;
use warnings;
use Carp;
use Fcntl;
use DB_File;

my $wordlist = _find_file("wordlist");
our %dictionary;
tie %dictionary, "DB_File", $wordlist, O_RDONLY
  or carp "Couldn't open wordlist: $!\n";

my $forename = _find_file("forename");
our %forenames;
tie %forenames, "DB_File", $forename, O_RDONLY
  or carp "Couldn't open forename list: $!\n";


require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(extract_entities);

our $VERSION = '1.93';


# Regexps for constructing capitalised sequences
my $conjunctives = qr/of|and|the|&|\+/i;
my $break = qr/\b|^|$/;
my $people_initial = qr/Mrs?|Ms|Dr|Sir|Lady|Lord/;
my $people_terminal = qr/Sr|Jr|Esq/;
my $places_initial = qr/Mt|Ft|St|Lake|Mount/;
my $places_terminal = qr/St(reet)?|Ave(nue)?/i;
my $abbr = qr/$people_initial|$people_terminal|$places_initial|St/;
my $capped = qr/$break (?:$abbr(\.|$break)|[A-Z][a-z]* $break)/x;
my $folky = qr/-(?:(?:in|under|over|by|the)-)+/i;
my $middle = qr/ $folky | 
                [\s-] (?:$conjunctives [\s-])* /x;
my $phrase = qr/$capped (?:$middle $capped)*/x;

my $word = qr/\s*\b\w+\b\s*/;
my $context = qr/$word{1,2}/;

sub extract_entities {
    my $text = shift;
    $text =~ s/\n/ /g;
    $text =~ s/ +/ /g;
    my @candidates;
    @candidates = _combine_contexts(map { _categorize_entity($_) }
                                    _spurn_dictionary_words(_extract_capitalized($text)));
}

sub _categorize_entity {
    my $e = shift;
    $e->{scores} = { person => 1, place => 1, organisation => 1};
    $e->{count} = 1;
    bless $e, "Lingua::EN::NamedEntity";
    $e->_definites and return $e;
    $e->_name_clues;
    $e->_place_clues;
    $e->_org_clues;
    $e->_fix_scores;
    return $e;
}

sub _definites {
    my $e = shift;
    my $ent = $e->{entity};
    if ($ent =~ /^$people_initial\.?\b/ or $ent =~ /\b$people_terminal\.?$/) {
        $e->{scores}{person} = 100;
        return 1;
    }
    if ($ent =~ /^$places_initial\.?\b/ or $ent =~ /\b$places_terminal\.?$/) {
        $e->{scores}{place} = 100;
        return 1;
    }
    return 0;
}

my $pre_name =
qr/chair|\w+man|\w+person|director|executive|manager|president|secretary|chancellor|
minister|governor|chief|deputy|head|member|officer/ix;
sub _name_clues {
    my $e = shift;
    my $ent = $e->{entity};
    my @x;
    $e->{scores}{person} += 10 if $e->{pre} =~ /(\b|^)$pre_name(\b|$)/;
    $e->{scores}{person} += 3 if (@x = split /\W+/, $ent) == 2; 
    my @words = grep { exists $forenames{lc $_} } split /\W+/, $ent;
    $e->{scores}{person} += 5 * @words;
}

my $pre_place = qr/in|at/i;
sub _place_clues {
    my $e = shift;
    my @x;
    $e->{scores}{place} += 3  if (@x = split /\W+/, $e->{entity}) == 1; 
    $e->{scores}{place} += 3 if $e->{pre} =~ /(^|\b)$pre_place(\b|$)/;
}

sub _org_clues {
    my $e = shift;
    my $ent = $e->{entity};
    $e->{scores}{organisation} += 10 if $ent =~ /\b(&|and|\+)\b/;
    my @words = grep { _stemmed_word_in_dictionary($_) } split /\W+/, $ent;
    $e->{scores}{organisation} += @words;
}

sub _fix_scores {
    my $e = shift;
    if (!$e->{class}) {
        $e->{class} = (sort {$e->{scores}{$b}<=>$e->{scores}{$a}} keys
        %{$e->{scores}} )[0];
    }
    return $e;
}

sub _spurn_dictionary_words {
    my @initial = @_;
    my @candidates;
    # Spurn sentence-initial dictionary words
    for my $e (@initial) {
        do { push @candidates, $e; next} if $e->{pre} and $e->{entity} =~ / /; 
        my $word = lc $e->{entity};
        next if exists $dictionary{$word} ||
                _stemmed_word_in_dictionary($word);
        push @candidates, $e;
    }
    return @candidates;
}

sub _stemmed_word_in_dictionary {
    my $word = lc shift;
    my ($stemmed) = @{ Lingua::Stem::En::stem({ -words => [ $word ] }) };
    return exists $dictionary{$stemmed};
}

sub _extract_capitalized {
    my $text = shift;
    my @results;
    while ($text =~ /($phrase)/ms) {
        my $entity = $1;
        $text =~ s/($context?)\Q$entity\E($context?)/$2/;
        my ($pre, $post)= ($1, $2);
        while ($entity =~ s/^($conjunctives\s+)// or
               $entity =~ s/^(.+?)(Mrs?|Ms|Dr|Mt|Ft)/$2/) {
            $pre .= $1;
        }
        next if length $entity <2;
        push @results, { entity => $entity, pre => $pre, post => $post };
    }
    return @results;
}

sub _combine_contexts {
    my @entities = @_;
    my %combined;
    my @rv;
    # If something's a person in one sentence, it's likely to be one in
    # another too!
    for my $e (@entities) {
        $combined{$e->{entity}}{entity} = $e->{entity};
        $combined{$e->{entity}}{count} += $e->{count};
        for my $class (keys %{$e->{scores}}) {
            $combined{$e->{entity}}{scores}{$class} += $e->{scores}{$class}
        }
    }
    for my $e (values %combined) {
        push @rv, _fix_scores($e);
     }
    return @rv;
}


sub _find_file {
    my $file = shift;
    my @files = grep { -e $_ } map { "$_/Lingua/EN/NamedEntity/$file" } @INC;
    return $files[0];
}

1;
__END__

=encoding UTF-8

=head1 NAME

Lingua::EN::NamedEntity - Basic Named Entity Extraction algorithm

=head1 SYNOPSIS

  use Lingua::EN::NamedEntity;
  my @entities = extract_entities($some_text);

=head1 DESCRIPTION

"Named entities" is the NLP jargon for proper nouns which represent
people, places, organisations, and so on. This module provides a 
very simple way of extracting these from a text. If we run the
C<extract_entities> routine on a piece of news coverage of recent UK
political events, we should expect to see it return a list of hash
references looking like this:
 
  { entity => 'Mr Howard', class => 'person', scores => { ... }, },
  { entity => 'Ministry of Defence', class => 'organisation', ... },
  { entity => 'Oxfordshire', class => 'place', ... },

The additional C<scores> hash reference in there breaks down the various
possible classes for this entity in an open-ended scale. 

The hash also includes the number of occurrences for that entity.

Naturally, the more text you throw at this, the more accurate it becomes.

=head2 extract_entities

Pass to C<<extract_entities>> a text, and it will return a list of
entities, as described above.

=head1 AUTHOR

Simon Cozens, C<simon@kasei.com>

Maintained by Alberto Simões, C<ambs@cpan.org>

=head1 ACKNOWLEDGMENTS

Thanks to Jon Allen for help with Makefile.PL failure.

Thanks to Bo Adler for a patch with entity count.

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2008 by Alberto Simões
Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
