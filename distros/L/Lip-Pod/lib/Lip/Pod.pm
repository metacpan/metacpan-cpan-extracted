#!/usr/bin/perl -w
use strict;

=begin lip

=for none
###############################################################################
###############################################################################

=head1 NAME

Lip::Pod - Literate Perl filter

=cut

=for none
###############################################################################
###############################################################################

=head1 CONCEPT

Leaves all pod code intact, and indents all non-pod code by two spaces. C<=cut>
directives are eaten. An C<=head1>, C<=cut> pair is wrapped around the output.
Lines consisting entirely of '#' (and at least 3 of them) are ignored in the
non-pod zones (to allow for dividing lines in the source code).

=cut


=for none
###############################################################################
###############################################################################

=head1 SUBCLASS Pod::Parser

Defines a subclass of B<Pod::Parser> which implements the indentation and
C<=cut> skipping described in L<SYNOPSIS>.

=cut

package Lip::Pod;

use Pod::Parser;

use vars qw(@ISA);
@ISA = qw(Pod::Parser);

use Text::Tabs;


=for none
###############################################################################

=head2 begin_input()

Print out the Literate Perl preamble.

=cut

sub begin_input
{
	my ($self) = @_;
	my $out_fh = $self->output_handle();

	print $out_fh "=pod\n\n";
}


=for none
###############################################################################

=head2 command()

Pass through all commands, except C<=cut>, which is not passed through so that
the entire output is POD.

=cut

sub command
{
	my ($self, $cmd, $text, $line_num, $pod_para) = @_;

	if      (($cmd eq 'begin') and ($text =~ m/^\s*lip\s*$/)) {
		$self->{lip} = 1;
		return;
	} elsif (($cmd eq 'end') and ($text =~ m/^\s*lip\s*$/)) {
		$self->{lip} = 0;
		return;
	}

	return unless $self->{lip};

	return if $cmd eq 'cut';
	return if (($cmd eq 'for') and ($text =~ m/^\s*none\b/));

	my $out_fh    = $self->output_handle();

	print $out_fh "=$cmd ", $text;
}


=for none
###############################################################################

=head2 end_input()

Print out the Literate Perl postamble.

=cut

sub end_input
{
	my ($self) = @_;

	my $out_fh = $self->output_handle();

	print $out_fh "=cut\n\n";
}


=for none
###############################################################################

=head2 preprocess_paragraph()

Indents non-POD paragraphs by two spaces.

=cut

sub preprocess_paragraph
{
	my ($self, $text, $line_num) = @_;
	my @text;

	return $text if $text =~ m/^=begin\s+lip\s*$/;

	return ""    unless $self->{lip};
	return $text unless $self->cutting;

	@text = split($/, $text, -1);
	@text = expand(@text);
	map { s/^(\s*\S)/  $1/; } @text;
	$text = join($/, @text);

	my $out_fh = $self->output_handle();
	print $out_fh $text;

	return "";
}


=for none
###############################################################################
###############################################################################

=end lip

=cut

1;

__END__


=for none
###############################################################################
###############################################################################

=head1 NAME

Lip::Pod - Literate Perl to POD conversion


=for none
###############################################################################
###############################################################################

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use strict;
  use Lip::Pod;
  package main;
  my $parser = new Lip::Pod;
  $parser->parseopts( -want_nonPODs => 1, -process_cut_cmd => 1 );
  push @ARGV, '-' unless @ARGV;
  for (@ARGV) { $parser->parse_from_file($_); }
  exit 0;


=for none
###############################################################################
###############################################################################

=head1 DESCRIPTION

Donald Knuth introduced Literate Programming, which is the idea that computer
programs should be written in an expository style, as works of literature.
He created a system called B<web>, which implemented his ideas for Pascal
and TeX. Later, a derivative system, B<cweb> was created for the C programming
language (with text still in TeX).

Full Literate Programming in the style of Knuth involves disconnecting the
order of presentation to humans from the order of presentation to a machine.
The input files written by the author/programmer are in an order convenient
for instructing the reader, not necessarily in the order required to build
an executable program. Programs then process the combined text/code input
to create human-readable output (the program is called B<weave> in Knuth's
system), or compiler-appropriate output (B<tangle> in B<web>).

This module implements a very simple Literate Programming capability for
Perl. Just as Perl's Plain Old Documentation (POD) is intended to be just
powerful enough to be useful, and easy for the programmer, Literate Perl
(LIP) is intended to bring the basic benefits of Literate Programming to
Perl without radically altering the way programmers/authors work.

When you use LIP, you put the contents of your source file in the best order
you can for exposition that does not interfere with its function. This may
involve, for example, alphabetizing subroutines and/or grouping them by
some criteria. Here is a simple example:

  #!/usr/bin/perl -w
  use strict;

  =begin lip

  =head1 NAME

  hello - LIP example

  =head1 IMPLEMENTATION

  Print a friendly message to standard output.

  =cut

  print "Hello, world!\n";

  exit 0;

  =end lip

  =cut

Running this program will have the expected result. Running it through
B<lip2pod> will select the internal documenation and include the code itself
as verbatim paragraphs. This results in POD output that can be formatted
nicely by one of the B<pod2*> "podlators".

External documenation (like this) can be tacked on to the end of a file
as usual. So, adding these lines to the end of the example above:

  __END__

  =head1 NAME

  hello - LIP example

  =head1 SYNOPSIS

    hello

  =head1 DESCRIPTION

  A simple example used to demonstrate the use of B<Lip::Pod> and B<lip2pod>.

  =cut

results in a single file that

=over 4

=item *

is executable; and

=item *

contains internal documentation that can be formatted nicely (after
conversion via B<lip2pod>; and

=item *

contains external documentation using the same mechanism as non-LIP files.

=back

This module leverages the B<Pod::Parser> and B<Text::Tabs> modules.
B<Pod::Parser> is a standard module as of Perl version 5.6. For use with
prior versions of Perl, download the latest copy from the CPAN.


=for none
###############################################################################
###############################################################################

=head1 REFERENCES

=over 4

=item *

Knuth, Donald Ervin. I<Literate Programming>, Center for the Study of Language
and Information, 1992. ISBN 0-987073-80-6 (paper).

=back


=for none
###############################################################################
###############################################################################

=head1 AUTHOR

Gregor N. Purdy E<lt>gregor@focusresearch.comE<gt>


=for none
###############################################################################
###############################################################################

=head1 COPYRIGHT

This program is free software. You may copy or redistribute it under the
same terms as Perl itself.

=cut

