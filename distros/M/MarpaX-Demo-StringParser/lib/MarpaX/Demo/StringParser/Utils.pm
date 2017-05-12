package MarpaX::Demo::StringParser::Utils;

use strict;
use utf8;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Config;

use Date::Simple;

use File::Slurp; # For read-file().
use File::Spec;

use MarpaX::Demo::StringParser::Config;
use MarpaX::Demo::StringParser::Filer;

use HTML::Entities::Interpolate;

use Marpa::R2;

use Moo;

use Text::CSV::Slurp;
use Text::Xslate 'mark_raw';

has config =>
(
	default  => sub{return MarpaX::Demo::StringParser::Config -> new -> config},
	is       => 'rw',
#	isa      => 'HashRef',
	required => 0,
);


our $VERSION = '2.04';

# ------------------------------------------------

sub generate_demo_environment
{
	my($self)   = @_; # Chomp only works in list context (or with array_ref).
	my($debian) = read_file('/etc/debian_version', chomp => 1);

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => "Debian V $debian"},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;

} # End of generate_demo_environment.

# -----------------------------------------------

sub generate_demo_index
{
	my($self)          = @_;
	my($data_dir_name) = 'data';
	my($html_dir_name) = 'html';
	my(%data_file)     = MarpaX::Demo::StringParser::Filer -> new -> get_files($data_dir_name, 'dash');

	my($html_name);
	my($line, @line);
	my($name);

	for my $key (sort keys %data_file)
	{
		$name      = "$data_dir_name/$key.dash";
		$line      = read_file($name, binmode => ':encoding(utf-8)');
		@line      = split(/\n/, $line);
		$html_name = "$html_dir_name/$key.svg";

		$data_file{$key} =
		{
			dash   => join('<br />', map{$Entitize{$_} || ''} @line),
			input  => $name,
			output => -e $html_name ? $html_name : 'None',
			title  => $line[0],
		};
	}

	my(@key)       = sort keys %data_file;
	my($config)    = $self -> config;
	my($templater) = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my($count) = 0;
	my($index) = $templater -> render
	(
	'marpax.demo.stringparser.tx',
	{
		default_css     => "$$config{css_url}/default.css",
		data =>
			[
			map
			{
				{
					count  => ++$count,
					dash   => mark_raw($data_file{$_}{dash}),
					image  => "./$_.svg",
					input  => mark_raw($data_file{$_}{input}),
					output => mark_raw($data_file{$_}{output}),
					title  => mark_raw($data_file{$_}{title}),
				};
			} @key
			],
		date            => Date::Simple -> today,
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		marpa_version   => $Marpa::R2::VERSION,
		version         => $VERSION,
	}
	);
	my($file_name) = File::Spec -> catfile($html_dir_name, 'index.html');

	open(my $fh, '>', $file_name);
	print $fh $index;
	close $fh;

	print "Wrote $file_name\n";

	# Return 0 for success and 1 for failure.

	return 0;

} # End of generate_demo_index.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<MarpaX::Demo::StringParser::Utils> - Utils used by MarpaX::Demo::StringParser

=head1 Synopsis

See scripts/generate.index.pl.

Note: scripts/generate.index.pl outputs to a directory called 'html' in the 'current' directory.

See L<the demo page|http://savage.net.au/Perl-modules/html/marpax.demo.stringparser/> for sample output.

=head1 Description

Some utils to simplify testing.

End-users do not need to call the methods in this module.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<MarpaX::Demo::StringParser> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Demo::StringParser

or run:

	sudo cpan MarpaX::Demo::StringParser

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

C<new()> is called as C<< my($obj) = MarpaX::Demo::StringParser::Utils -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Demo::StringParser::Utils>.

Key-value pairs accepted in the parameter list:

=over 4

=item o (none)

=back

=head1 Methods

=head2 generate_demo_environment()

Returns a hashref of OS, etc, values.

Keys are C<left> and C<right>, to suit C<htdocs/assets/templates/marpax/demo/stringparser/fancy.table.tx>.

C<*.tx> files are used by L<Text::Xslate>.

Called by L</generate_demo_index()>.

=head2 generate_demo_index()

Calls L<MarpaX::Demo::StringParser::Filer/get_files($dir_name, $type)> and L</generate_demo_environment()>.

Writes C<html/index.html>.

See scripts/generate.index.pl.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Machine-Readable Change Log

The file CHANGES was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Demo::StringParser>.

=head1 Author

L<MarpaX::Demo::StringParser> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
