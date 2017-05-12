package KSx::Highlight::Summarizer;

$VERSION = '0.06';

@ISA = KinoSearch::Highlight::Highlighter;
use KinoSearch::Highlight::Highlighter;

use strict;

use List::Util qw 'min';
use Number::Range;

use Hash::Util::FieldHash::Compat 'fieldhashes';
fieldhashes \my( %ellipsis, %summ_len, %page_h, %encoder );

sub _range_endpoints {
  my $range = shift;
  my @range = $range->range;
  my $previous = shift @range;
  my $subrange = [($previous) x 2];
  my @arrays;
  foreach my $current (@range) {
    if ($current == ($previous + 1)) {
      $subrange->[1] = $current;
    }
    else {
      push @arrays, $subrange;
      $subrange = [($current) x 2];
    }
    $previous = $current;
  }
  return @arrays, $subrange; # Make sure the last subrange isn’t left out!
}

sub new {
	my($pack, %args) = @_;
	my $ellipsis = exists $args{ellipsis} ? delete $args{ellipsis}
		: ' ... ';
	my $summ_len = exists $args{summary_length}
		? delete $args{summary_length} : 0;
	my $page_h = delete $args{page_handler};
	my $encoder   = delete $args{encoder};

	# accept args that the superclass only allows one to set through
	# accessor methods:
        my $pre_tag = delete $args{pre_tag};
        my $post_tag = delete $args{post_tag};

	my $self = SUPER::new $pack %args;

	$ellipsis{$self} = $ellipsis;
	$summ_len{$self} = $summ_len;
	$page_h{$self}   = $page_h;
	$encoder{$self}  = $encoder;

	defined $pre_tag and $self->set_pre_tag($pre_tag);
	defined $post_tag and $self->set_post_tag($post_tag);

	return $self;
}

sub create_excerpt {
    my ($self, $hitdoc) = @_;
	
    my $field = $self->get_field;
    my $x_len = $self->get_excerpt_length;
    my $limit = int($x_len /3 );

    # retrieve the text from the chosen field
    my $text = $hitdoc->{$field};
    return unless defined $text;
    my $text_length = length $text;
    return '' unless $text_length;

    # get offsets and weights of words that match
    my $searcher = $self->get_searchable;
    my $posits = $self->get_compiler->highlight_spans(
        searchable => $searcher,
        field      => $field,
        doc_vec    => $searcher->fetch_doc_vec(
                          $hitdoc->get_doc_id
                      ),
    );
    my @locs = map [$_->get_offset,$_->get_weight], @{
     KinoSearch::Highlight::HeatMap->new(
        spans  => $posits,
        window => $limit*2
     )->get_spans
    };
    @locs = map $$_[0], sort { $$b[1] <=> $$a[1] } @locs;
    
    @locs or @locs = 0;

#warn "@locs" if $summ_len{$self};
    # determine the rough boundaries of the excerpts
    my $range = new Number::Range;
    my $summ_len = $summ_len{$self};
    for(@locs) {
        no warnings; # suppress Number::Range’s nasty warnings
	my $start = $_-$limit;
	$start = 0 if $start < 0;
        $range->addrange($start . '..' . min($start+$x_len, $text_length));
	last if !$summ_len || $range->size >= $summ_len;
    }
    my @excerpt_bounds = _range_endpoints($range);
#use DDS; warn Dump \@excerpt_bounds if $summ_len;

    # close small gaps between ranges
    for(my $c = 1; $c < @excerpt_bounds;++$c) {
        $excerpt_bounds[$c][0] - $excerpt_bounds[$c-1][1] <= 10 and
            $excerpt_bounds[$c-1][1] = $excerpt_bounds[$c][1],
            splice(@excerpt_bounds, $c, 1),
            --$c;
    }

    # extract the offsets from the highlight spans
    my(@starts, @ends);
    for(@$posits) {
     push(@starts, my $start = $_->get_offset);
     push(@ends,   $start + $_->get_length);
    }

    # make the summary
    my $summary = '';
    my $ellipsis = $ellipsis{$self};
    my $token_re = qr/\b\w+(?:'\w+)?\b/;
    my $prev_ellipsis; # whether the previous excerpt ended with an ellip.
    my $prev_page = 0; # last page number of previous excerpt
    my $page_h = $page_h{$self};
    for(@excerpt_bounds) {
        # make the excerpt
        my ($start,$end) = @$_;

        # determine the page number that $start falls within
        my $page_no;
        $page_h and $page_no =
            substr($text, 0,$start) =~ y/\014// + 1;

        my $x; # short for x-cerpt
        my $need_ellipsis;

#warn "<<".substr($text,$start,$limit).">>";
        # look for a page break within $limit chars from $start (except we
        # shouldn’t do it if $start is 0 because there’s  a  good  chance
        # we’ll go past the very word for whose sake this excerpt exists)
	# ~~~ What about a case in which a page break plus maybe a few
	#     spaces occur just *before* $start. That shouldn’t get an
	#     ellipsis  (as in the  elsif  block  below),  should  it?
        if($page_h && $start &&
           substr($text,$start,$limit) =~ /^(.*)\014/s) {
            $start += length($1) + 1;
            $page_no += 1 + $1 =~ y/\014//;
            $x = substr $text, $start;
        }
        elsif( $start ) { # if this is not the beginning of the doc
            my $sb = $self->find_sentences(
                text => $text, offset => $start, length => $limit
            );
            if(@$sb) {
                $start = $$sb[0];
            }
            else { ++ $need_ellipsis }
            $x = substr $text, $start;
            if($need_ellipsis) {                      
                # skip past possible partial tokens, but don’t insert an
                # ellipsis yet, because it might need to come after a
                # page marker
                if ($x =~ s/
                    \A
                    (
                    .{1,$limit}?  # don't go outside the window
                    )
                    (?=$token_re)  # just b4 the start of a full token
                    //xsm
                    )
                {
                    $start += length($1);
                }
            }
        }
        else { $x = substr $text, $start }

        # trim unwanted text from the end of the excerpt
        $x = substr $x, 0, $end-$start+1;  # +1 ’cos we need that extra
                                           #  char later
        my $end_with_ellipsis = 0;

        # if we’ve trimmed the end of the text
        if ( $end < $text_length) {{ # doubled so ‘last’ will work
            # check to see whether there are page breaks after the high-
            # lighted word, and stop at the first one if so
            if ($page_h and substr($x, $limit*-2) =~ s/(\014[^\014]*)//) {
                $end -= length $1; last;
            }

            # remove possible partial tokens from the end of the excerpt
            my $extra_char = chop $x; # the char we left dangling earlier
            # if the extra char wasn't part of a token, then we’re not
            # splitting one
            if ( $extra_char =~ $token_re ) {
                $x =~ s/$token_re$//;  # if this fails, that's fine
            }

            # if the excerpt doesn't end with a full stop, end with
            # an ellipsis
            if ( $x !~ /\.\s*\Z/xsm ) {
                $x =~ s/\W+\Z//xsm;
                $x .= $ellipsis;
                ++$end_with_ellipsis;
            }
        }}
#warn $x if $page_h;

        # get the offsets that are within range for the excerpt, and make
        # them relative to $start
        my @relative_starts = map $_-$start, @starts;
        my @relative_ends   = map $_-$start, @ends;
        my $this_x_len = $end - $start;
        while ( @relative_starts and $relative_starts[0] < 0 ) {
            shift @relative_starts;
            shift @relative_ends;
        }
        while ( @relative_ends and $relative_ends[-1] > $this_x_len ) {
            pop @relative_starts;
            pop @relative_ends;
        }

        # insert highlight tags and page break markers
        # sstart and send stand for span start and end
        my ( $sstart, $send, $last_sstart, $last_send ) =
           (  undef,  undef,  0,            0 );
        if($page_h) { # Some of this code *is* repeated redundantly, but it
                      # should  theoretically  run  faster  since  the
                      # if($page_h) check doesn’t have to be made every
                      # time through the loop.
            $prev_page != $page_no
            ? (
                $summary .= &$page_h($hitdoc, $page_no),
                $need_ellipsis && ($summary .= $ellipsis)
            ) : $need_ellipsis && !$prev_ellipsis &&
                ($summary .= $ellipsis)
            ;
            while (@relative_starts) {
                $send   = shift @relative_ends;
                $sstart = shift @relative_starts;
                $summary .= _encode_with_pb( $self,
                    substr( $x, $last_send, $sstart - $last_send ),
                    $page_h, \$page_no, $hitdoc
                ) unless !$last_send && !$sstart;
                $summary .= $self->highlight(
                    _encode_with_pb( $self,
                        substr( $x, $sstart, $send - $sstart ),
                        $page_h, \$page_no, $hitdoc
                    )
                );
                $last_send = $send;
            }
            $summary .= _encode_with_pb( $self,
                substr( $x, $last_send ),
                $page_h, \$page_no, $hitdoc
            ) unless $last_send == length $x;
            $prev_page = $page_no;
        }
        else {
           $need_ellipsis and !$prev_ellipsis and $summary .= $ellipsis;
           while (@relative_starts) {
                $send   = shift @relative_ends;
                $sstart = shift @relative_starts;
                $summary .= $self->encode(
                    substr( $x, $last_send, $sstart - $last_send ) )
		    unless !$last_send && !$sstart;
                $summary .= $self->highlight(
                    $self->encode(
                        substr( $x, $sstart, $send - $sstart )
                    )
                );
                $last_send = $send;
            }
            $summary .= $self->encode( substr( $x, $last_send ) )
                unless $last_send == length $x;
        }

        $prev_ellipsis = $end_with_ellipsis;

    }

    return $summary;
}

# This is not called as a method above, because it’s a private routine that
# should not be overridden (it is not guaranteed to exist in future ver-
# sions), and it’s faster to call it as a function.
sub _encode_with_pb { # w/page breaks
	my ($self, $text, $page_h, $page_no_ref, $hitdoc) = @_;
	my @to_encode = split /\014/, $text, -1; # -1 to allow trailing
	my $ret = '';                            #  null fields
	$ret .= $self->encode(shift @to_encode) if length $to_encode[0];
	for(@to_encode) {
		$ret .= &$page_h($hitdoc, ++$$page_no_ref);
		$ret .= $self->encode($_) if length;
	}
	$ret;
}

sub encode {
	my @__ = @_; # workaround for perl5.8.8 bug
	&{
		$encoder{$__[0]} or return shift(@__)->SUPER::encode(@__)
	}($__[1])
}

1;

__END__

=head1 NAME

KSx::Highlight::Summarizer - KinoSearch Highlighter subclass that provides more comprehensive summaries

=head1 VERSION

0.06 (beta)

=head1 SYNOPSIS

  use KSx::Highlight::Summarizer;
  my $summarizer = new KSx::Highlight::Summarizer
      searchable => $searcher,
      query      => 'foo bar',
      field      => 'content',
      
      # optional:
      pre_tag        => '<b>',
      post_tag       => '</b>',
      encoder        => sub {
          my $str = shift; $str =~ s/([&'"<])/'&#'.ord($1).';'/eg; $str
      },
      page_handler   => sub { "<h3>Page $_[1]:</h3>" },
      ellipsis       => "\x{2026}", # default: ' ... '
      excerpt_length => 150,        # default: 200
      summary_length => 400,
  ;

  my $excerpt = $summarizer->create_excerpt( $hit );

=head1 DESCRIPTION 

This module extends L<KinoSearch::Highlight::Highlighter> (which provides
an excerpt for a search result, with search words highlighted) to provide
various customisations, especially summaries, i.e., multiple excerpts
joined together with ellipses.

The superclass finds the best location with the text of a search result,
takes a single piece of text surrounding it, and then formats it, 
highlighting words as appropriate. This module will also take the second 
best
location and create an excerpt for that (removing overlap), and so on until 
the C<summary_length> is reached or exceeded.

=head1 METHODS

=head2 new

This is the constructor. It takes hash-style arguments, as shown in the
L</SYNOPSIS>. The various arguments are as follows:

=over 4

=item searchable

A reference to an object that isa L<KinoSearch::Search::Searchable> (e.g.,
a L<KinoSearch::Searcher>)

=item query

A query string or object

=item field

The name of the field for which to make a summary

=item pre_tag, post_tag

These two are strings of text to be inserted around highlighted words, such
as HTML tags. The defaults are '<strong>' and '</strong>'.

=item encoder

An code ref that is
expected to encode the text fed to it, e.g., with HTML entities

=item page_handler

A coderef. If this is provided, it will be called for every page break
(form feed; ASCII character 12) in the summary, and its return value 
substituted for that
page break. The arguments will be (0) the hit (a L<KinoSearch::Doc::HitDoc>
object) and (1) the page number.

=item ellipsis

The ellipsis mark to use. The default is three ASCII dots surrounded by
spaces: S<' ... '>

=item excerpt_length

The length of each excerpt (default is 200), not including ellipses.
Actually, an excerpt may end up being shorter than this, because the start
is trimmed to the nearest sentence boundary or page break, and the end is
trimmed to the nearest word boundary.

=item summary_length

The approximate length of the summary, not including ellipses. Excerpts are
collected together until the lengths of the excerpts (before trimming)
equal or exceed the number passed to this argument. If this is omitted,
only one excerpt will be made.

=back

=head2 create_excerpt

This requires a L<KinoSearch::Doc::HitDoc> object as its sole argument. It
creates and returns a summary.

=head1 BUGS

A very long custom ellipsis, or two page breaks a few characters apart, can
break the page-counting algorithm.

=head1 SINE QUIBUS NON

This module requires perl and the following modules, which available from
the CPAN:

L<Number::Range>

L<Hash::Util::FieldHash::Compat>

The development version of L<KinoSearch> available at
L<http://www.rectangular.com/svn/kinosearch/trunk>, revision 4604 or later.
It has only been tested 
with revision 4625.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2008-9 Father Chrysostomos <sprout at, um, cpan.org>

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 ACKNOWLEDGEMENTS

Much of the code in this module is based on revision 3122 of Marvin
Humphrey's C<KinoSearch::Highlight::Highlighter>, of which this is a 
subclass.

=cut
