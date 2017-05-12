package Formatter::HTML::Preformatted;

use 5.006;
use strict;
use warnings;
use URI::Find::Simple qw( list_uris change_uris );


our $VERSION = '0.95';

=head1 NAME

Formatter::HTML::Preformatted - Absolute minimal HTML formatting of pure text

=head1 SYNOPSIS

  use Formatter::HTML::Preformatted;
  my $formatter = Formatter::HTML::Preformatted->format($data);
  print $formatter->fragment;
  my @links = $text->links;
  print ${$links}[0]->{url};

=head1 DESCRIPTION

This module will simply take any text-string and put it in a HTML
C<pre> element. It will escape tags and entities. It will also look
through it to see if there are any URIs, and they will be turned into
hyperlinks.

=head1 METHODS

This module conforms with the L<Formatter> API specification, version 0.95:

=over

=item C<format($string)>

The format function that you call to initialise the formatter. It
takes the plain text as a string argument and returns an object of
this class.

=cut

sub format {
  my $that  = shift;
  my $class = ref($that) || $that;
  my $self = {
	      _text => shift,
	     };
  bless($self, $class);
  return $self;
}

=item C<fragment>

To get only the text enclosed in the minimal C<pre> element, you will
call this method. It returns a string with the HTML fragment.

=cut

sub fragment {
  my $self = shift;
  my $raw = $self->{_text};
  # Escaping the stuff that needs escaping.
  $raw =~ s/&/&amp;/g;
  $raw =~ s/\>/&gt;/g;
  $raw =~ s/\</&lt;/g;
  
  return "<pre>\n" . change_uris($raw, sub { "<a href=\"$_[0]\">$_[0]</a>" }) . "\n</pre>\n";
}

=item C<document([$charset])>

Will add a document type declaration and some minimal markup, to
return a full, valid, HTML document. You may specify an optional
C<$charset> parameter. This will include a HTML C<meta> element with
the chosen character set. It will still be your responsibility to
ensure that the document served is encoded with this character set.

=cut

sub document {
  my $self = shift;
  my $result = '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">' . "\n<html>\n";
  my $charset = shift;
  if ($charset) {
    $result .= "<head>\n" . '<meta http-equiv="Content-Type" content="text/html; charset=' . $charset . '">' . "\n</head>\n";
  }
  $result .= "<body>\n" . $self->fragment . "\n</body>\n</html>\n";
  return $result;
}


=item C<links>

Will return all links found the input plain text string. They will be
found in an arrayref where each element has a key C<url>.

=cut

sub links {
  my $self = shift;
  my @arr;
  foreach (list_uris($self->{_text})) {
    push(@arr, {url => $_, title => ''});
  }
  return \@arr;
}

=item C<title>

Since this formatter has no way of finding the title of the document
this method will always return C<undef>.

=cut


sub title {
  return undef;
}





1;
__END__

=back


=head1 SEE ALSO

L<Formatter>, L<Formatter::HTML::Textile>, L<URI::Find::Simple>

=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2005 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
