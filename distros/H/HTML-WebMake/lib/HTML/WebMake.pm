=head1 NAME

HTML::WebMake - a simple web site management system

=head1 SYNOPSIS

  my $f = new HTML::WebMake::Main ();
  $f->readfile ($filename);
  $f->make();
  my $failures = $f->finish();
  exit $failures;

=head1 DESCRIPTION

WebMake is a simple web site management system, allowing an entire site to be
created from a set of text and markup files and one WebMake file.

It requires no dynamic scripting capabilities on the server; WebMake sites can
be deployed to a plain old FTP site without any problems.

It allows the separation of responsibilities between the content editors, the
HTML page designers, and the site architect; only the site architect needs to
edit the WebMake file itself, or know perl or WebMake code.

A multi-level website can be generated entirely from 1 or more WebMake files
containing content, links to content files, perl code (if needed), and output
instructions.  Since the file-to-page mapping no longer applies, and since
elements of pages can be loaded from different files, this means that standard
file access permissions can be used to restrict editing by role.

Since WebMake is written in perl, it is not limited to command-line invocation;
using the C<HTML::WebMake::Main> module directly allows WebMake to be run from
other Perl scripts, or even mod_perl (WebMake uses C<use strict> throughout,
and temporary globals are used only where strictly necessary).

=cut

package HTML::WebMake;

use vars	qw{
  	@ISA $VERSION
};

@ISA = qw();

$VERSION = "2.2";
sub Version { $VERSION; }

###########################################################################

1;


__END__

=head1 MORE DOCUMENTATION

See also http://webmake.taint.org/ for more information.

=head1 SEE ALSO

L<HTML::WebMake::Main>

L<webmake>

L<Text::EtText>

=head1 AUTHOR

Justin Mason E<lt>jm /at/ jmason.orgE<gt>

=head1 COPYRIGHT

WebMake is distributed under the terms of the GNU Public License.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN
as well as:

  http://webmake.taint.org/

=cut

