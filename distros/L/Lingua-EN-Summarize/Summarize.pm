package Lingua::EN::Summarize;

use strict;
use Carp;
use Exporter;
use Text::Wrap qw(wrap);
use Text::Sentence qw(split_sentences);
use Lingua::EN::Summarize::Filters;

use vars qw($VERSION @ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(summarize);
$VERSION = '0.2';


sub summarize {
  my ($text, %options) = @_;

  ### This section massages the text into a usable format before summarizing.

  # Run each filter over the text.
  return unless $text;
  if ($options{filter}) {
    my @filters = ref $options{filter} eq 'ARRAY' ?
                            @{$options{filter}} : $options{filter};

    foreach (@filters) {
      no strict 'refs';

      if (ref $_ eq 'CODE') {
	$text = $_->( $text );
      } elsif (exists $Lingua::EN::Summarize::Filters::{$_}
	       and *{"Lingua::EN::Summarize::Filters::$_"}{CODE}) {
	$text = &{"Lingua::EN::Summarize::Filters::$_"}( $text );
      } else {
	croak "Unknown text filter \"$_\"";
      }
    }
  }

  # Strip whitespace and formatting out of the text.
  $text =~ s/^\s+//;
  $text =~ s/\s+/ /sg;
  $text =~ s/\s+$//;

  unless (exists $options{maxlength} and $options{maxlength} > 0) {
    $options{maxlength} = length( $text ) / 30;
  }


  ### Here's where the interesting logic happens.
  
  # First we break it into sentence pieces. Kind of. Sort of.
  my $keywords = "(is|are|was|were|will|have)";
  my @clauses = grep { /\b$keywords\b/i }
                   map { split /(,|;|--)/ } split_sentences( $text );

  my $stopwords = "(and|but|instead)";
  foreach (@clauses) {
    s/^\s+//;
    s/^$stopwords\s+//i;
    $_ = ucfirst;
    $_ .= ". " unless /[.!?]$/;
  }

  # Assemble the resulting phrases into the summary response.
  my $summary = '';
  while (@clauses and length $summary < $options{maxlength}) {
    $summary .= " " . shift @clauses;
  }


  ### Done! Do any necessary postprocessing before returning.

  # Prettyprint the summary to make it look nice on a terminal, if requested.
  if ($options{wrap}) {
    $Text::Wrap::columns = $options{wrap};
    $summary = wrap( '', '', $summary );
  }

  $summary =~ s/^\s+//mg;
  $summary =~ s/[ \t]+/ /g;    # if we use \s, that screws up the wrapping
  $summary =~ s/\s+$//mg;

  return $summary;
}


1;
__END__


=pod

=head1 NAME

Lingua::EN::Summarize - A simple tool for summarizing bodies of English text.

=head1 SYNOPSIS

  use Lingua::EN::Summarize;
  my $summary = summarize( $text );                    # Easy, no? :-)
  my $summary = summarize( $text, maxlength => 500 );  # 500-byte summary
  my $summary = summarize( $text, filter => 'html' );  # Strip HTML formatting
  my $summary = summarize( $text, wrap => 75 );        # Wrap output to 75 col.

=head1 DESCRIPTION

This is a simple module which makes an unscientific effort at
summarizing English text. It recognizes simple patterns which look like
statements, abridges them, and concatenates them into something vaguely
resembling a summary. It needs more work on large bodies of text, but
it seems to have a decent effect on small inputs at the moment.

Lingua::EN::Summarize exports one function, C<summarize()>, which takes
the text to summarize as its first argument, and any number of optional
directives in C<name =E<gt> value> form. The options it'll take are:

=over

=item maxlength

Specifies the maximum length, in bytes, of the generated summary.

=item wrap

Prettyprints the summary output by wrapping it to the number of columns
which you specify.

=item filter

Passes the text through a filter before handing it to the summarizer.
Currently, only two filters are implemented: C<"html">, which uses
HTML::TreeBuilder and HTML::FormatText to strip all HTML formatting from
a document, and C<"easyhtml">, which quickly (and less accurately)
strips all HTML from a document using a simple regular expression, if
you don't have the abovementioned modules. An C<"email"> filter, for
converting mail and news messages to easily-summarizable text, is in the
works for the next version.

=back

Unlike the HTML::Summarize module (which is quite interesting, and worth
a look), this module considers its input to be plain English text, and
doesn't try to gather any information from the formatting. Thus, without
any cues from the document's format, the scheme that HTML::Summarize
uses isn't applicable here. The current scheme goes something like this:

"Filter the text according to the user's C<filter> option. Split the text
into discrete sentences with the Text::Sentence module, then further
split them into clauses on commas and semicolons. Keep only the ones
that have a (subject very-simple-verb object) structure. Construct the
summary out of the first sentences in the list, staying within the
C<maxlength> limit, or under 30% of the size of the original text,
whichever is smaller."

Needless to say, this is a very simple and not terribly universally
effective scheme, but it's good enough for a first draft, and I'll bang
on it more later. Like I said, it's not a scientific approach to the
problem, but it's better than nothing (and often better than
HTML::Summarize!), and I don't really need A.I. quality output from it.

=head1 AUTHOR

Dennis Taylor, E<lt>dennis@funkplanet.comE<gt>

=head1 SEE ALSO

HTML::Summarize, Text::Sentence,
http://www.vancouvertoday.com/city_guide/dining/reviews/barbers_modern_club.html

=cut
