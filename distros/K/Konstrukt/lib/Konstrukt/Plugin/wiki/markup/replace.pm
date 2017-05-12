=head1 NAME

Konstrukt::Plugin::wiki::markup::replace - Inline plugin to handle simple replacements

=head1 SYNOPSIS
	
	my $r = use_plugin 'wiki::markup::replace';
	my $rv = $r->process($tag);

=head1 DESCRIPTION

This one will do a simple search and replace for a configurable list of
replacements.

=head1 CONFIGURATION

The replacements can be configured in your konstrukt.settings file.
The setting is a comma separated list of replacements, where each replacement
consists of a string to match and the replacement string
(separated by a " | ", note the non-optional whitespaces around the pipe and
that whitespaces around the separating comma will belog to the match/replace
string).

The matching will be case-insensitive. Most symbols will only match with spaces
around them (note the extra space) to avoid ambiguity.

The defaults are (must be on one line in the real config):

	wiki/replace
		>> | &raquo;,
		<< | &laquo;,
		 *  |  &lowast; ,
		 1/2  |  &frac12; ,
		 1/4  |  &frac14; ,
		 3/4  |  &frac34; ,
		 ->  |  &rarr; ,
		 <-  |  &larr; ,
		 <->  |  &harr; ,
		 =>  |  &rArr; ,
		 <=  |  &lArr; ,
		 <=>  |  &hArr; ,
		 -  |  &ndash; ,
		 --  |  &mdash; ,
		... | &hellip;,
		(C) |  &copy;,
		(R) |  &reg;

If you want to add custom replacements without putting all the defaults into
your config, you can use this setting:

	wiki/replace_custom :) | :D,foo | bar

So you would only need to modify the defaults if you want to alter/remove
any replacements.

=head1 EXAMPLE

Note that most of these symbols have to be surrounded by whitespaces to prevent
the replacement in some abmiguous/unwanted cases.

Quotes:

	some >>beautifully quoted<< text

Asterisk:

	beautiful asterisk * here

Fractions:
	
	0 < 1/4 < 1/2 < 3/4 < 1

Arrows:
	
	small -> rightarrow
	
	small <- leftarrow
	
	small <-> leftrightarrow
	
	big => rightarrow

	big <= leftarrow
	
	big <=> leftrightarrow

Dashes:
	
	small - dash
	
	long -- dash
	
Symbols:

	copyright (C)
	
	registered (R)
	
Horizontal Ellipsis:
	
	The End...
	
=cut

package Konstrukt::Plugin::wiki::markup::replace;

use strict;
use warnings;

use Konstrukt::Parser::Node;
use base 'Konstrukt::Plugin::wiki::markup::inlineplugin';

=head1 METHODS

=head2 init

Initialization.

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default('wiki/replace', '>> | &raquo;,<< | &laquo;, *  |  &lowast; , 1/2  |  &frac12; , 1/4  |  &frac14; , 3/4  |  &frac34; , ->  |  &rarr; , <-  |  &larr; , <->  |  &harr; , =>  |  &rArr; , <=  |  &lArr; , <=>  |  &hArr; , -  |  &ndash; , --  |  &mdash; ,... | &hellip;,(C) | &copy;,(R) | &reg;');
	$Konstrukt::Settings->default('wiki/replace_custom', '');
	
	return 1;
}
#= /init

=head2 process

This method will do the work.

B<Parameters>:

=over

=item * $nodes - Container node (of type L<Konstrukt::Parser::Node>) containing
all (text-)nodes of this documents.

=back

=cut
sub process {
	my ($self, $nodes) = @_;
	
	#parse replacement settings
	my @pairs = ((split /,/, $Konstrukt::Settings->get('wiki/replace')), (split /,/, $Konstrukt::Settings->get('wiki/replace_custom')));
	my $replace;
	foreach my $pair (@pairs) {
		my ($pattern, $replacement) = split / \| /, $pair;
		$replace->{$pattern} = $replacement if defined $pattern and defined $replacement;
	}
	
	#generate regexp
	my $match = "(" . join('|', map { $_ =~ s/(\W)/\\$1/g; $_; } keys %{$replace}) . ")";
	
	#walk through all nodes and apply replacements
	my $node = $nodes->{first_child};
	while (defined $node) {
		if (not $node->{wiki_finished} and $node->{type} eq 'plaintext') {
			$node->{content} =~ s/$match/<nowiki>$replace->{$1}<\/nowiki>/gi;
		}
		$node = $node->{next};
	}
	
	return 1;
}
# /process

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::wiki>

=cut
