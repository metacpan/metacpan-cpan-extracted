package Formatter::HTML::HTML;

use 5.006;
use strict;
use warnings;
use HTML::Tidy;
use HTML::TokeParser;

use base qw( HTML::Tidy );


our $VERSION = '0.97';

=head1 NAME

Formatter::HTML::HTML - Formatter to clean existing HTML

=head1 SYNOPSIS

  use Formatter::HTML::HTML;
  my $formatter = Formatter::HTML::HTML->format($data);
  print $formatter->document;
  print $formatter->title;
  my $links = $text->links;
  print ${$links}[0]->{url};

=head1 DESCRIPTION

This module will clean the document using L<HTML::Tidy>. It also
inherits from that module, so you can use methods of that class. It
can also parse and return links and the title (using
L<HTML::TokeParser>).

=head1 METHODS

This module conforms with the L<Formatter> API specification, version 0.95:

=over

=item C<format($string [, {config_file =E<gt> 'path/to/tidy.cfg'} )>

The format function that you call to initialise the formatter. It
takes the plain text as a string argument and returns an object of
this class.

Optionally, you may give a hashref with the full file name of the tidy
config. This enables you to have this Formatter return valid XHTML,
just set it correctly in the config. Note also that you may break the
Formatter by e.g. returning configuring tidy to return just a
fragment, and it is your own resonsibility to make sure you don't.

=cut

sub format {
  my ($that, $text, $config)  = @_;
  my $class = ref($that) || $that;
  my $tidy = new HTML::Tidy($config); # In fact, we let it do the hard work
  my $clean = $tidy->clean($text);    # allready. It has to be done anyway.
  my $self = {
	      _out => $clean,
	     };
  bless($self, $class);
  return $self;
}


=item C<document([$charset])>

Will return a full, cleaned and valid HTML document. You may specify
an optional C<$charset> parameter. This will include a HTML C<meta>
element with the chosen character set. It will still be your
responsibility to ensure that the document served is encoded with this
character set.


=cut

sub document {
  my $self = shift;
  my $charset = shift;
  my $cleaned = $self->{_out};
  if (($charset) && ($cleaned !~ m/charset/)) {
    $cleaned =~ s|(<head.*?>)|$1\n<meta http-equiv="Content-Type" content="text/html; charset=$charset">|si;
  }
  return $cleaned;
}


=item C<fragment>

This will return only the contents of the C<body> element.

=cut

sub fragment {
  my $self = shift;
  if ($self->{_out} =~ m|<body.*?>(.*)</body>|si) {
    return $1;
  } else {
    return $self->{_out}
  }
}

=item C<links>

Will return all links found the input plain text string as an
arrayref. The arrayref will for each element keys url and title, the
former containing the URL, the latter the text of the link.


=cut

sub links {
  my $self = shift;
  my @arr;
  my $p = HTML::TokeParser->new(\$self->{_out});

  while (my $token = $p->get_tag("a")) {
    my $url = $token->[1]{href} || "-";
    my $text = $p->get_trimmed_text("/a");
    push(@arr, {url => $url, title => $text});
  }
  return \@arr;
}

# Both links and title are taken right from examples in TokeParser!
# Nice of them, huh? :-)

=item C<title>

Will return the title of the document as seen in the HTML C<title>
element or undef if none can be found.

=cut


sub title {
  my $self = shift;
  my $p = HTML::TokeParser->new(\$self->{_out});

  if ($p->get_tag("title")) {
    return $p->get_trimmed_text;
  }
  return undef;
}


1;
__END__

=back


=head1 SEE ALSO

L<Formatter>, L<HTML::Tidy>, L<HTML::TokeParser>

=head1 TODO

Both the C<fragment> and C<document> methods use naive regular
expressions to strip off elements and add a C<meta> element
respectively. This is clearly not very reliable, and should be done
with a proper parser.

=head1 SUBVERSION REPOSITORY

This module is currently maintained in a Subversion repository. The
trunk can be checked out anonymously using e.g.:

  svn checkout http://svn.kjernsmo.net/Formatter-HTML-HTML/trunk Formatter-HTML-HTML

=head1 AUTHOR

Kjetil Kjernsmo, E<lt>kjetilk@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kjetil Kjernsmo

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
