package Lingua::EN::Summarize::Filters;

use strict;
use Carp;


sub easyhtml {
  my $text = shift;

  # A very simple-minded HTML stripper.
  $text =~ s/<(?:[^>\'\"]*|([\'\"]).*?\1)*>//gs;
  return $text;
}


sub html {
  my $html = shift;
  my $text = '';

  # closure!
  my $callback = sub { $text .= shift };

  require HTML::Parser;
  my $parser = HTML::Parser->new( api_version => 3,
				  text_h => [ $callback, "dtext" ] );
  $parser->parse( $html );
  $parser->eof();

  return $text;
}


sub email {
  my $text = shift;

  # magic goes here
  croak "Not implemented yet FIXME FIXME FIXME";
}



1;
__END__


=pod

=head1 NAME

Lingua::EN::Summarize::Filters - Helper functions for the Summarize module

=head1 SYNOPSIS

  See the Lingua::EN::Summarize documentation.

=head1 DESCRIPTION

See the Lingua::EN::Summarize documentation.

=head1 AUTHOR

Dennis Taylor, E<lt>dennis@funkplanet.comE<gt>

=head1 SEE ALSO

Lingua::EN::Summarize (got the point yet? :-)

=cut
