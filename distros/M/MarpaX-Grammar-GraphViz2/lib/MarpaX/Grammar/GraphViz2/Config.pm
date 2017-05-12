package MarpaX::Grammar::GraphViz2::Config;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Config::Tiny;

use File::HomeDir;

use Moo;

use Path::Tiny; # For path().

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

our $VERSION = '2.00';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = path('config', '.htmarpax.grammar.graphviz2.conf');

	$self -> read($path);

} # End of BUILD.

# ------------------------------------------------

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

# ------------------------------------------------

1;

=pod

=head1 NAME

MarpaX::Grammar::GraphViz2::Config - Helps generate the demo page for MarpaX::Grammar::GraphViz2

=head1 Synopsis

This module is only for use by the author of C<MarpaX::Grammar::GraphViz2>.

See scripts/generate.demo.pl.

=head1 Description

C<MarpaX::Grammar::GraphViz2::Config> helps generate the demo page for L<MarpaX::Grammar::GraphViz2>.

=head1 Methods

=head2 read()

read() is called automatically by BUILD(). It does the actual reading of the config file.

If the file can't be read, die is called.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Grammar::GraphViz2>.

=head1 Author

L<MarpaX::Grammar::GraphViz2> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
