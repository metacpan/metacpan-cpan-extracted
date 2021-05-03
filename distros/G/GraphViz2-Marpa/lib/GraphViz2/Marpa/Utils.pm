package GraphViz2::Marpa::Utils;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Algorithm::Diff;

use Capture::Tiny 'capture';

use File::Spec;
use File::Temp;

use GraphViz2::Marpa;

use Moo;

use Path::Tiny;

our $VERSION = '2.12';

# ------------------------------------------------

sub get_files
{
	my($self, $dir_name, $type) = @_;

	return (sort map{s/\.$type//; $_} grep{/\.$type$/} path($dir_name) -> children);

} # End of get_files.

# ------------------------------------------------

sub perform_1_test
{
	my($self, $file_name) = @_;

# The EXLOCK option is for BSD-based systems.

	my($temp_dir)      = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($temp_dir_name) = $temp_dir -> dirname;
	my($data_dir_name) = 'data';
	my($html_dir_name) = $temp_dir_name;
	my($in_suffix)     = 'gv';
	my($out_suffix)    = 'gv';

	my(@new_svg, $new_svg);
	my(@old_svg, $old_svg);

	my($in_file)                 = File::Spec -> catfile($data_dir_name, "$file_name.$in_suffix");
	my($out_file)                = File::Spec -> catfile($temp_dir_name, "$file_name.$out_suffix");
	my($stdout, $stderr, $exit)  = capture{system $^X, '-Ilib', 'scripts/g2m.pl', '-input_file', $in_file, '-output_file', $out_file};

	# Unfortunately, we can't die, because for invalid DOT files there cannot be an output file.

	#die "Error: g2m.pl did not create an output *.gv file\n" if (! -e $out_file);

	($old_svg, $stderr, $exit)   = capture{system 'dot', '-Tsvg', $in_file};
	@old_svg                     = split(/\n/, $old_svg);
	($new_svg, $stderr, $exit)   = capture{system 'dot', '-Tsvg', $out_file};
	@new_svg                     = split(/\n/, $new_svg);

	return Algorithm::Diff -> new(\@old_svg, \@new_svg);

} # End of perform_1_test.

# -----------------------------------------------

1;

=pod

=head1 NAME

C<GraphViz2::Marpa::Utils> - A demo page generator for C<GraphViz2::Marpa>

=head1 Synopsis

See L<GraphViz2::Marpa/Synopsis>.

=head1 Description

L<GraphViz2::Marpa> provides a Marpa-based parser for Graphviz C<dot> files,
and this module helps generate the demo page.

This module is really only of interest to the author.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<GraphViz2::Marpa> as you would for any C<Perl> module:

Run:

	cpanm GraphViz2::Marpa

or run:

	sudo cpan GraphViz2::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Marpa::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa::Utils>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (None)

=back

=head1 Methods

=head2 get_files($dir_name, $type)

Returns a sorted list of files of type (extension) $type from directory $dir_name.

=head2 perform_1_test($file_name)

Run C<dot> on the input file, and run C<g2m.pl> on it, and run C<dot> on the output file, and compare
the outputs of the 2 svg files.

Used by scripts/test.html.pl and t/test.t.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/GraphViz2-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2::Marpa>.

=head1 Author

L<GraphViz2::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2012.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2012, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
