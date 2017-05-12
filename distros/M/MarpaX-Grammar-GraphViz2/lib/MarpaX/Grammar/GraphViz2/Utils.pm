package MarpaX::Grammar::GraphViz2::Utils;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.
use open      qw(:std :utf8); # Undeclared streams in UTF-8.

use Config;

use Date::Simple;

use File::Basename;
use File::Spec;

use MarpaX::Grammar::GraphViz2::Config;
use MarpaX::Grammar::GraphViz2::Filer;

use HTML::Entities::Interpolate;

use Moo;

use Path::Tiny;   # For path().

use Text::Xslate 'mark_raw';

has config =>
(
	default  => sub{return MarpaX::Grammar::GraphViz2::Config -> new -> config},
	is       => 'rw',
#	isa      => 'HashRef',
	required => 0,
);

our $VERSION = '2.00';

# ------------------------------------------------

sub generate_demo_environment
{
	my($self) = @_;

	my(@environment);

	# mark_raw() is needed because of the HTML tag <a>.

	push @environment,
	{left => 'Author', right => mark_raw(qq|<a href="http://savage.net.au/">Ron Savage</a>|)},
	{left => 'Date',   right => Date::Simple -> today},
	{left => 'OS',     right => 'Debian V 6'},
	{left => 'Perl',   right => $Config{version} };

	return \@environment;

} # End of generate_demo_environment.

# ------------------------------------------------

sub generate_demo_index
{
	my($self)          = @_;
	my($html_dir_name) = 'html';
	my($config)        = $self -> config;
	my($templater)     = Text::Xslate -> new
	(
		input_layer => '',
		path        => $$config{template_path},
	);
	my(%file) = MarpaX::Grammar::GraphViz2::Filer -> new -> get_files('share', 'bnf');

	my($image_name, %image);

	for my $file (grep{! /c.ast/} keys %file)
	{
		$image{$file}{bnf_name}   = $file{$file};
		$image_name               = path('html', $file);
		$image_name               =~ s/bnf$/svg/;
		$image{$file}{image_name} = "$image_name.svg";
	}

	my($count1) = 0;
	my($count2) = 0;
	my($index)  = $templater -> render
	(
	'graphviz2.index.tx',
	{
		default_css     => "$$config{css_url}/default.css",
		data =>
			[
			map
			{
				{
					bnf_name   => $image{$_}{bnf_name},
					count      => ++$count1,
					image      => "./$_.svg",
					image_name => $image{$_}{image_name},
				};
			} sort keys %image
			],
		environment     => $self -> generate_demo_environment,
		fancy_table_css => "$$config{css_url}/fancy.table.css",
		index           =>
			[
			map
			{
				{
					bnf_name => basename($image{$_}{bnf_name}),
					count    => ++$count2,
				};
			} sort keys %image
			],
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

# ------------------------------------------------

1;

=pod

=head1 NAME

L<MarpaX::Grammar::GraphViz2::Utils> - Helps generate the demo page for MarpaX::Grammar::GraphViz2

=head1 Synopsis

This module is only for use by the author of C<MarpaX::Grammar::GraphViz2>.

See scripts/generate.demo.pl.

=head1 Description

Some utils to simplify generation of the demo page.

It is not expected that end-users would ever need to use this module.

=head1 Constructor and Initialization

=head2 Calling new()

C<new()> is called as C<< my($obj) = MarpaX::Grammar::GraphViz2::Utils -> new() >>.

It returns a new object of type C<MarpaX::Grammar::GraphViz2::Utils>.

=head1 Methods

=head2 generate_demo_environment()

Returns a hashref of OS, etc, values.

Keys are C<left> and C<right>, to suit C<htdocs/assets/templates/marpax/grammar/graphviz2/fancy.table.tx>.

C<*.tx> files are used by L<Text::Xslate>.

Called by L</generate_demo_index()>.

=head2 generate_demo_index()

Calls L<MarpaX::Grammar::GraphViz2::Filer/get_files($dir_name, $type)> and L</generate_demo_environment()>.

Writes C<html/index.html>.

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
