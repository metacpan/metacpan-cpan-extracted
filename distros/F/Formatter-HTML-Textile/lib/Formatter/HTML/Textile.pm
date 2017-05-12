=head1 NAME

Formatter::HTML::Textile - Formatter to make HTML from Textile

=head1 DESCRIPTION

This module will format Textile input to HTML. It conforms
with the L<Formatter> API specification, version 1.0.

=head1 SYNOPSIS

  my $textile = <<TEXTILE;
  h1. textile document
  
  this is a "textile":http://textism.com/tools/textile/ document
  TEXTILE

  my $formatter = Formatter::HTML::Textile->format( $textile );

  print "title is ".$formatter->title."\n";
  print $formatter->document;
  
  my @links = @{ $formatter->links };
  print "Links urls: ";
  print join ", " map { $_->{url} } @links;
  print "\n";

=head1 METHODS

=over 4

=item format($string)

This is a constructor method and initializes the formatter with the
passed text.

This method returns a Formatter::HTML::Textile object.

=item document()

It returns a full HTML document, comprising the formatted textile
source converted to HTML. You may specify an optional C<$charset>
parameter. This will include a HTML C<meta> element with the chosen
character set. It will still be your responsibility to ensure that the
document served is encoded with this character set.

=item fragment()

returns a minimal HTML chunk as textile.

=item links()

Returns all the links found in the document, as a listref of hashrefs,
with keys 'title', which is the title of the link, and 'url', which is
the link.

=item title()

Returns the title of the document

=back

=head1 SEE ALSO

L<Formatter>, L<Text::Textile>

=head1 AUTHOR

Originally written by Tom Insam, maintained by Kjetil Kjernsmo from
2005-11-19.

=head1 COPYRIGHT

Copyright 2005 Tom Insam tom@jerakeen.org, 2005, 2009 Kjetil Kjernsmo,
kjetilk@cpan.org.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut


package Formatter::HTML::Textile;
use warnings;
use strict;
use Carp qw( croak );

our $VERSION = 1.02;

use base qw( Text::Textile );

sub format {
  my $class = shift;
  my $self = ref($class) ? $class : $class->new;
  $self->{_text} = shift || "";
  return $self;
}

sub document {
  my $self = shift;
  my $charset = shift;
  # TODO - holy cow this is a horrible hack. Make work, damnit. Needs docstrings,
  # etc, etc, etc.
  my $out = "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.01//EN\">\n<html><head>";  
  if ($charset) {
    $out .= '<meta http-equiv="Content-Type" content="text/html; charset='.$charset.'">';
  }
  $out .= '<title>'
         .$self->title
         .'</title></head><body>'
         .$self->fragment
         .'</body></html>';
  return $out;
}


sub fragment {
  my $self = shift;
  return $self->process($self->{_text});
}



sub links {
  my $self = shift;
  my @arr;
  require HTML::TokeParser;
  my $p = HTML::TokeParser->new(\$self->fragment);

  while (my $token = $p->get_tag("a")) {
    my $url = $token->[1]{href} || "-";
    my $text = $p->get_trimmed_text("/a");
    push(@arr, {url => $url, title => $text});
  }
  return \@arr;
}


sub title {
  my $self = shift;
  if ( $self->{_text} =~ /^h1\.\s*(.*)$/im ) {
    return $1;
  }
  return undef;
}


1;

