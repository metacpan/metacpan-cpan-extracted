package JavaScript::Bookmarklet;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(make_bookmarklet);
our $VERSION   = '0.02';

use URI::Escape qw(uri_escape_utf8);

sub make_bookmarklet {
    my $src    = shift;
    my $no_src = shift;
    $src =~ s{^// ?javascript:.+\n}{}
      ;    # Zap the first line if there's already a bookmarklet comment:
    my $bookmarklet = $src;
    $bookmarklet =~ s{^\s*//.+\n}{}gm;    # Kill comments.
    $bookmarklet =~ s{\t}{ }gm;           # Tabs to spaces
    $bookmarklet =~ s{ +}{ }gm;           # Space runs to one space
    $bookmarklet =~ s{^\s+}{}gm;          # Kill line-leading whitespace
    $bookmarklet =~ s{\s+$}{}gm;          # Kill line-ending whitespace
    $bookmarklet =~ s{\n}{}gm;            # Kill newlines
    $bookmarklet =
      "javascript:"
      . uri_escape_utf8($bookmarklet, qq('" \x00-\x1f\x7f-\xff))
      ;    # Escape single- and double-quotes, spaces, control chars, unicode:
    return $no_src ? $bookmarklet : "// $bookmarklet\n" . $src;
}

1;

__END__

=head1 NAME

JavaScript::Bookmarklet - utility library and command-line
script for converting human-readable JavaScript code into
bookmarklet form.

=head1 SYNOPSIS

  use JavaScript::Bookmarklet qw(make_bookmarklet);

  my $src = <<JAVASCRIPT
  var str = document.title;
  alert(str);
  JAVASCRIPT

  my $bookmarklet = make_bookmarklet($src);
  print $bookmarklet;

The output of this script would be:

  // javascript:var%20str%20=%20document.title;alert(str);
  var str = document.title;
  alert(str);

=head1 DESCRIPTION

A "bookmarklet" is a little JavaScript script that's
intended to be run from a web browser's bookmarks bar or
menu. The reason they work as "bookmarks" is that the
JavaScript source code is crammed into the form of a URL
using the "javascript:" scheme.

This package is based on a text filter John Gruber of Daring
Fireball fame wrote that makes writing --- and especially
revising --- JavaScript bookmarklets much more pleasant.

Developing or modifying bookmarklets can be irritating, to
say the least, because of this requirement that the
JavaScript code be in the form of a URL.

So the problem developing bookmarklets is this: You want to
write and edit normal JavaScript code, but you need to
publish hard-to-read URLs.

This package provides to means of using this functionality
-- as a utility method that can be called in an application
and as a script that can be used on the command-line or in
editors like BBEdit.

=head1 METHODS

=head2 make_bookmarklet $javascript, [$no_src]

This method takes a required SCALAR string ($javascript)
that is presumed to be valid working JavaScript code and
compresses it in to bookmarklet form. Optionally a boolean
flag ($no_src) can be passed with the JavaScript code
forcing the method to only return the bookmarklet screen and
not the merged output of the bookmarklet and source code.

This method can be exported by request.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JavaScript-Bookmarklet>

For other issues, contact the author.

=head1 AUTHOR

Timothy Appnel <tima@cpan.org>

=head1 SEE ALSO

http://daringfireball.net/2007/03/javascript_bookmarklet_builder, 
L<make-bookmarklet>

=head1 COPYRIGHT AND LICENCE

The software is released under the Artistic License. The
terms of the Artistic License are described at
http://www.perl.com/language/misc/Artistic.html. Except
where otherwise noted, JavaScript::Bookmarklet is Copyright
2008, Timothy Appnel, tima@cpan.org. All rights reserved.
