package MarpaX::Demo::SampleScripts;

use 5.010;
use diagnostics;
use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8);    # Fatalize encoding glitches.
use open      qw(:std :utf8);    # Undeclared streams in UTF-8.
use charnames qw(:full :short);  # Unneeded in v5.16.

use Data::Dumper;
use Data::Section;

use Marpa::R2;
use Marpa::R2::HTML;

use Moo;

use POSIX;

use Try::Tiny;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

our $VERSION = '1.04';

# ------------------------------------------------

sub run
{
	my($self) = @_;

	# Return 0 for success and 1 for failure.

	return 0;

} # End of run.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<MarpaX::Demo::SampleScripts> - A collection of scripts using Marpa::R2

=head1 Synopsis

See scripts/*.pl.

=head1 Description

C<MarpaX::Demo::SampleScripts> demonstrates various grammars and various ways to write and test
scripts.

The whole point of this module is in scripts/*.pl.

=head1 Installation

Install C<MarpaX::Demo::SampleScripts> as you would for any C<Perl> module:

Run:

	cpanm MarpaX::Demo::SampleScripts

or run:

	sudo cpan MarpaX::Demo::SampleScripts

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

C<new()> is called as C<< my($parser) = MarpaX::Demo::SampleScripts -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<MarpaX::Demo::SampleScripts>.

Key-value pairs accepted in the parameter list:

=over 4

(None).

=back

=head1 Methods

=head2 run()

This method does nothing, and return 0 for success.

=head1 Files Shipped with this Module

Many of these scripts are gists, i.e. from https://gist.github.com/. You can always go there are
search for some I<unique> text within the script, to see if there are other versions, or commentary
available.

=head2 Runnable Scripts

All these scripts are in the scripts/ directory.

=over 4

=item o ambiguous.grammar.03.pl

A grammar for the
L<Velocity|http://velocity.apache.org/engine/releases/velocity-1.4/specification-bnf.html> language.

=item o grammar.inspector.01.pl

Display Marpa's view of the structure of a grammar.

=item o html.02.pl

Process defective HTML.

=item o match.parentheses.01.pl

Match nested parantheses, i.e. the '(' and ')' pair.

=item o match.parentheses.02.pl

This sophisticated example checks files for matching brackets: (){}[].

Or, it can be run (self-tested) with the '--test' option'.

The new rejection events are used, along with the Ruby Slippers, meaning it requires L<Marpa::R2>
V 2.098000.

This program uses the method of adding known tokens (my $suffix = '(){}[]';) to the end of the input
string so Marpa can be told to search just that part of the string when the logic dictates that a
Ruby Slippers token (bracket) is to be passed to Marpa to satisfy the grammar. It's put at the end
so that it does not interfere with line and column counts in the original input string.

=item o parmaterized.grammar.01.pl

Handle parts of the grammar as strings, and interpolate various things into those strings, before
using them to build the final grammar.

=item o quoted.strings.01.pl

=over 4

=item o Handle events

=item o Handle utf8 input

=item o Handle doublequoted strings

=item o Handle single-quoted strings

=back

=item o quoted.strings.02.pl

Handle nested, double-quoted, strings.

=item o quoted.strings.03.pl

Handle strings quoted with various characters, and with escaped characters in there too.

=item o quoted.strings.04.pl

Uses a grammar with pauses to handle various types of quoted strings, with manual scanning.

See quoted.strings.05.pl for getting Marpa to handling the scanning of HTML.

=item o quoted.strings.05.pl

Handles HTML.

=over 4

=item o Handle strings containing escaped characters

=item o Handle events

=item o Handle unquoted strings

=item o Handle doublequoted strings

=item o Handle single-quoted strings

=back

=item o use.utf8.01.pl

=over 4

=item o Handle events

=item o Handle utf8 input

=item o Handle unquoted strings

=item o Handle doublequoted strings

=item o Handle single-quoted strings

=back

=back

=head2 Un-runnable Scripts

All these scripts are in the examples/ directory.

=over 4

=item o action.parse.pl

Show how, during an action sub, another parse can be done using the output of the parse which
triggered the action. The inner parse uses the same grammar as the outer parse.

=item o ambiguous.grammar.01.pl

Contains both ambiguous and un-ambiguous grammars.

Uses MarpaX::ASF::PFG, which is not on MetaCPAN.

=item o heredoc.pl

Parse multiple heredocs.

=item o html.01.pl

Processes HTML.

Uses L<HTML::WikiConverter>, which won't install without patches, and which the author apparently
refuses to fix.

=item o match.keywords.pl


=back

=head1 FAQ

=head2 Do any scripts handle HTML?

Yes. See scripts/quoted.strings.05.pl.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX::Demo::SampleScripts>.

=head1 Author

L<MarpaX::Demo::SampleScripts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2014.

Marpa's homepage: <http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
