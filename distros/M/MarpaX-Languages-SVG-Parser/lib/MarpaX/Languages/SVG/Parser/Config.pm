package MarpaX::Languages::SVG::Parser::Config;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.

use Config::Tiny;

use File::HomeDir;

use Moo;

use Path::Tiny; # For path().

use Types::Standard qw/Any Str/;

has config =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => Any, # Cannot use HashRef. See line 65.
	required => 0,
);

has config_file_path =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any, # Can't use Str. See line 61.
	required => 0,
);

has section =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

our $VERSION = '1.06';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;
	my($path) = path(File::HomeDir -> my_dist_config('MarpaX-Languages-SVG-Parser'), '.htmarpax.languages.svg.parser.conf');

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

MarpaX::Languages::SVG::Parser::Config - A config manager for use by MarpaX::Languages::SVG::Parser

=head1 Synopsis

See L<MarpaX::Languages::SVG::Parser/Synopsis>.

=head1 Description

Basically just utility routines for L<MarpaX::Languages::SVG::Parser>.

Only used to generate the SVGs of the BNFs.

=head1 Installation

See L<MarpaX::Languages::SVG::Parser/Installation>.

=head1 Methods

=head2 read()

read() is called automatically by new(). It does the actual reading of the config file.

If the file can't be read, C<die $string> is called.

The path to the config file is determined by:

	path(File::HomeDir -> my_dist_config('MarpaX-Languages-SVG-Parser'), '.htmarpax.languages.svg.parser.conf');

The author runs scripts/copy.config.pl, which uses similar code, to move the config file
from the config/ directory in the disto into an OS-dependent directory.

The run-time code uses this module to look in the same directory as used by scripts/copy.config.pl.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Languages::SVG::Parser>.

=head1 Author

L<MarpaX::Languages::SVG::Parser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
