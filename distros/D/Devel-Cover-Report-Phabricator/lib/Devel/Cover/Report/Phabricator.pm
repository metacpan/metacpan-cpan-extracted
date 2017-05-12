=head1 NAME

Devel::Cover::Report::Phabricator - Produce Phabricator-compatible coverage reports

=head1 SYNOPSIS

	cover -report phabricator

=head1 DESCRIPTION

By default, this module generates a C<phabricator.json> file in
L<Devel::Cover>'s output directory. This file can then be parsed and used to
provide coverage information as part of a unit test report to a
L<Phabricator|http://phabricator.org> server.

Phabricator is a suite of web applications originally developed at Facebook for conducting
code reviews, task management and much more. For documentation on configuring
code coverage for Phabricator, see
L<http://www.phabricator.com/docs/phabricator/article/Arcanist_User_Guide_Code_Coverage.html>.

=head1 OPTIONS

Additional arguments to the C<cover> program are automatically passed to the report object. The additional arguments supported by this report are:

=over

=item outputfile

The file to write the JSON report to. Defaults to I<phabricator.json> in the report directory.

=back

=head1 SEE ALSO

L<Devel::Cover>

L<Devel::Cover::Report::Clover>

L<http://www.phabricator.org/>

=head1 AUTHOR

Mike Cartmell, C<< <mcartmell at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mike Cartmell.

This software is free. It is licensed under the same terms as Perl itself.

=cut

package Devel::Cover::Report::Phabricator;

use strict;
use warnings;

use 5.006;

our $VERSION = '0.01';

use Getopt::Long;
use File::Slurp qw(write_file);
use JSON qw(to_json);
use List::MoreUtils qw(any);

sub get_options {
	my ($self, $opt) = @_;
	$opt->{option} ||= {};
	GetOptions($opt->{option}, 'outputfile=s') or die "Unable to parse command-line options";
	$opt->{option}{outputfile} = 'phabricator.json' if !defined $opt->{option}{outputfile};
}

sub report {
	my ($pkg, $db, $options) = @_;
	my $cover = $db->cover;
	my %coverage;
	for my $file (@{$options->{file}}) {
		my $f = $cover->file($file);
		open my $fh, '<', $file or die "Couldn't open $file: $!";
		my $st = $f->statement;
		next if !$st;
		my $this_cover;
		while (my $line = <$fh>) {
			my $n = $.;
			my $loc = $st->location($n);
			my $report = 'N'; # Not executable
			if ($loc) {
				# Count any covered statement on the line to mean the line is covered
				if (any { $_->covered } @$loc) {
					$report = 'C'; # Covered
				}
				else {
					$report = 'U'; # Uncovered
				}
			}
			$this_cover .= $report;
		}
		$coverage{$file} = $this_cover;
	}
	write_file ("$options->{outputdir}/$options->{option}{outputfile}", to_json(\%coverage));
}

1;
