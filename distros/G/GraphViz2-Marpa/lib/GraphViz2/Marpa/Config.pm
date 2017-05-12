package GraphViz2::Marpa::Config;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Config::Tiny;

use File::HomeDir;
use File::Spec;

use Moo;

has config =>
(
	default  => sub{return {} },
	is       => 'rw',
#	isa      => 'HashRef',
	required => 0,
);

has config_file_path =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

has section =>
(
	default  => sub{return ''},
	is       => 'rw',
#	isa      => 'Str',
	required => 0,
);

our $VERSION = '2.11';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = File::Spec -> catfile(File::HomeDir -> my_dist_config('GraphViz2-Marpa'), '.htgraphviz2.marpa.conf');

	$self -> read($path);

} # End of BUILD.

# -----------------------------------------------

sub read
{
	my($self, $path) = @_;

	$self -> config_file_path($path);

	# Check [global].

	$self -> config(Config::Tiny -> read($path) );

	if (Config::Tiny -> errstr)
	{
		die Config::Tiny -> errstr;
	}

	$self -> section('global');

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Check [x] where x is host=x within [global].

	$self -> section(${$self -> config}{$self -> section}{'host'});

	if (! ${$self -> config}{$self -> section})
	{
		die "Config file '$path' does not contain the section [@{[$self -> section]}]\n";
	}

	# Move desired section into config, so caller can just use $self -> config to get a hashref.

	$self -> config(${$self -> config}{$self -> section});

}	# End of read.

# --------------------------------------------------

1;

=pod

=head1 NAME

C<GraphViz2::Marpa::Config> - A config file helper for C<GraphViz2::Marpa>

=head1 Synopsis

See L<GraphViz2::Marpa>.

=head1 Description

L<GraphViz2::Marpa> provides a Marpa-based parser for Graphviz C<dot> files,
and this module helps finding and loading the config file, which in turn
helps generate the demo page.

This module is really only of interest to the author.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = GraphViz2::Marpa::Config -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<GraphViz2::Marpa::Config>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Methods

=head2 read($path)

Uses $path to find and read the config file into a hashref. By default it assumes
scripts/copy.config.pl has been run, and loads (effectively from config/),
.htgraphviz2.marpa.conf.

If the file can't be read, die is called.

See also scripts/copy.config.pl and scripts/find.config.pl.

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
