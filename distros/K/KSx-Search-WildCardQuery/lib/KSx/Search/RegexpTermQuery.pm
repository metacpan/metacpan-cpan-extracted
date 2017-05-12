use strict;
use warnings;

package KSx::Search::RegexpTermQuery;
use base qw( KinoSearch::Search::Query );

our $VERSION = '0.05';

use Hash::Util::FieldHash::Compat 'fieldhashes';
fieldhashes \my( %re, %prefix, %field );

sub new {
    my ($package, %args) = @_;

    my $re = delete $args{regexp};
    my $field = delete $args{field};

    my $self = $package->SUPER::new(%args);

    $re{$self} = $re;
    $field{$self} = $field;

    # get the literal prefix of the regexp, if any.
    if($re{$self} =~
        m<^
            (?:    # prefix for qr//'s, without allowing /i :
                \(\? ([a-hj-z]*) (?:-[a-z]*)?:
            )?
            (\\[GA]|\^) # anchor
            ([^#\$()*+.?[\]\\^]+) # literal pat (no metachars or comments)
        >x
    ) {{
        my ($mod,$anchor,$prefix) = ($1||'',$2,$3);
	$anchor eq '^' and $mod =~ /m/ and last;
	for($prefix) {
            $mod =~ /x/ and s/\s+//g;
        }
        $prefix{$self} = $prefix;
    }}

    $self;
}

#sub extract_terms {
#    my $self = shift;
#    return @{ $self->{terms} };
#}

sub make_compiler {
    return KSx::Search::RegexpTermCompiler->new(
        parent => @_
    );
}


package KSx::Search::RegexpTermCompiler;
use base qw( KinoSearch::Search::Compiler );

use Hash::Util::FieldHash::Compat 'fieldhashes';

fieldhashes \my ( %idf, %raw_impact, #%plists,
                  %terms,
                  %query_norm_factor, % normalized_impact, %tfs );
sub new {
    my($pack, %args) = @_;

    my $searcher = $args{searchable};
    my $reader      = $searcher->get_reader;
    my $lex_reader  = $reader->fetch("KinoSearch::Index::LexiconReader");
    my $post_reader = $reader->fetch("KinoSearch::Index::PostingsReader");

    # Retrieve the correct Similarity for the Query's field.
    my $sim = $args{similarity} = 
        $searcher->get_schema->fetch_sim($field{$args{parent}});

    my $self = $pack->SUPER::new(%args);

    my $parent = $args{parent};

    # Get a lexicon and find our place therein
    my( $re, $prefix ) = ($re{$parent}, $prefix{$parent});
    ref $re eq 'Regexp' or $re = qr/$re/; # avoid repetitive recompilation
    my $lexcn = $lex_reader->lexicon( field => $field{$parent} );
    $lexcn->seek(defined $prefix ? $prefix : '');
    
    # iterate through it, stopping at terms that match
    my @terms; #my @plists;
    my %hits; # The keys are the doc nums; the values the tfs.

    while () {
        my $term = get_term $lexcn;
        
        # sift out unwanted terms
        last if defined $prefix and index( $term, $prefix ) != 0;
        next unless $term =~ $re;

        # for terms that match...

        push @terms, $term;

        # We have to iterate through the documents in each posting list,
        # recording the doc numbers, so we can calc the doc freq later on.
        # E.g., if there are two documents, one containing ‘dog’ and ‘dot,’
        # and the other containing just ‘dog,’ and the re is /^do.*/, then
        # the doc freq has to be 2, since the re matches two docs. The doc
        # freqs of the individual terms are 1 and 2, so we can’t add or
        # average them.
        my $plist = $post_reader->posting_list(
	                              term => $term,
	                              field => $field{$parent},
	                          );
	my $posting; my $weight;
        while (my $doc_num = $plist ->next) {
            # For efficiency’s sake, we’ll collect the results now, to
            # avoid iterating through postings (the slowest part of search-
            # ing) more than once, even though this code probably belongs
            # in RegexpTermScorer
            my $posting ||= $plist->get_posting;
            $hits{$doc_num} +=
             $weight ||= $posting->get_freq * $posting->get_weight
        }

    } continue {
        last unless  $lexcn->next ;
    }
    my $doc_freq = scalar keys %hits;

    # Save the hits and terms for later
#    $plists{$self} = \@plists;
    $tfs{$self} = \%hits;
    $terms{$self} = \@terms;

    # Calculate and store the IDF
    my $max_doc = $searcher->doc_max;
    my $idf = $idf{$self} = $max_doc
    ?    1 + log( $max_doc / ( 1 + $doc_freq ) )
    :    1
    ;

    $raw_impact{$self} = $idf * $parent->get_boost;

    # make final preparations
    $self->perform_query_normalization($searcher);

    $self;
}

sub perform_query_normalization {
# copied from KinoSearch::Search::Weight originally
    my ( $self, $searcher ) = @_;
    my $sim = $self->get_similarity;

    my $factor = $self->sum_of_squared_weights;    # factor = ( tf_q * idf_t )
    $factor = $sim->query_norm($factor);           # factor /= norm_q
    $self->normalize($factor);                     # impact *= factor
}

sub get_value { shift->get_parent->get_boost }

sub sum_of_squared_weights { $raw_impact{+shift}**2 }

sub normalize { # copied from TermQuery
    my ( $self, $query_norm_factor ) = @_;
    $query_norm_factor{$self} = $query_norm_factor;

    # Multiply raw impact by ( tf_q * idf_q / norm_q )
    #
    # Note: factoring in IDF a second time is correct.  See formula.
    $normalized_impact{$self}
        = $raw_impact{$self} * $idf{$self} * $query_norm_factor;
}

sub make_matcher {
    my $self = shift;

    return KSx::Search::RegexpTermScorer->new(
#        posting_lists => $plists{$self},
        @_,
        compiler      => $self,
    );
}

sub highlight_spans {  # plagiarised form of TermWeight’s routine
    my ($self, %args) = @_;
    my $doc_vector = $args{doc_vec};
    my $field_name = $args{field};
    return if $field{$self->get_parent} ne $field_name;
    my $searcher   = $args{searcher};
    my $terms      = $terms{$self};

    require KinoSearch::Search::Span;

    my @posits;
    my $weight_val = $self->get_value;
    for (@$terms) {
        my $term_vector
            = $doc_vector->term_vector( field => $field_name, term => $_ );
        next unless defined $term_vector;
        my $starts = $term_vector->get_start_offsets->to_arrayref;
        my $ends   = $term_vector->get_end_offsets->to_arrayref;
        while (@$starts) {
            my $start = shift @$starts;
            push @posits, KinoSearch::Search::Span->new(
                offset => $start,
                length   => shift(@$ends)-$start, 
                weight       => $weight_val,
            );
        }
    }

    return \@posits;
}


package KSx::Search::RegexpTermScorer;
use base 'KinoSearch::Search::Matcher';

use Hash::Util::FieldHash::Compat 'fieldhashes';
fieldhashes\my(  %doc_nums, %pos, %wv,  %sim, %compiler );

sub new {
	my ($class, %args) = @_;
#	my $plists = delete $args{posting_lists};
	my $compiler   = delete $args{compiler};
	my $reader     = delete $args{reader};
	my $need_score = delete $args{need_score};
	my $self   = $class->SUPER::new(%args);
	$sim{$self} = $compiler->get_similarity;

	my $tfs = $tfs{$compiler};
	$doc_nums{$self} = [ sort { $a <=> $b } keys %$tfs ];
	
	$pos{$self} = -1;
	$wv {$self} = $compiler->get_value;
	$compiler{$self} = $compiler;
	
	$self
}

sub next {
	my $self = shift;
	my $doc_nums = $doc_nums{$self};
	return 0 if $pos{$self} >= $#$doc_nums;
	return $$doc_nums[ ++$pos{$self} ];
}

sub get_doc_num {
	my $self = shift;
	my $pos = $pos{$self};
	my $doc_nums = $doc_nums{$self};
	return $pos < scalar @$doc_nums ? $$doc_nums[$pos] : 0;
}

sub score {
	my $self = shift;
	my $pos = $pos{$self};
	my $doc_nums = $doc_nums{$self};
	return $wv{$self} * $sim{$self}->tf(
	  $tfs{$compiler{$self}}{$$doc_nums[$pos]}
	);
}


1;

__END__

=head1 NAME

KSx::Search::RegexpTermQuery - Regular expression term query class for KinoSearch

=head1 VERSION

0.05

=head1 SYNOPSIS

    use KSx::Search::RegexpTermQuery
    my $query = new KSx::Search::RegexpTermQuery
        regexp => qr/^foo/,
        field  => 'content',
    ;

    $searcher->hits($query);
    # etc.

=head1 DESCRIPTION 

This module provides search query objects for KinoSearch that find terms
that match a particular regular expression. Note that a query will only
match a single term; it is not a regexp match against an entire field.

=head1 PERFORMANCE

If a regular expression has a fixed literal prefix anchored to the
beginning of the string (e.g., the C<foo> in
C<qr/^foo[dl]$/>), only the 'foo' words in the index will be scanned, so
this should not be too slow, as long as the prefix is fairly long, or
there are sufficiently few 'foo' words. If, however, there is no literal
prefix (e.g., C<qr/foo/>), the I<entire> index will be scanned, so beware.

=head1 METHODS

=head2 new

This is the constructor. It constructs. Call it with hash-style arguments
as shown in the L</SYNOPSIS>. The C<regexp> can be a C<qr//> thingy or a
string. 

=head1 PREREQUISITES

L<Hash::Util::FieldHash::Compat>

The development version of L<KinoSearch> available at
L<http://www.rectangular.com/svn/kinosearch/trunk>, revision 4810 or 
higher.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2008-9 Father Chrysostomos <sprout at, um, cpan.org>

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Much of the code in this module was plagiarized from Marvin Humphrey's
KinoSearch modules.

=head1 SEE ALSO

L<KinoSearch>, L<KinoSearch::Search::Query>, 
L<KSx::Search::WildCardQuery>

=cut
