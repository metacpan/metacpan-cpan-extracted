#!/usr/bin/perl

use strict;
use warnings;

#podselect is shipped with Pod::Parser.
#load this module to ensure it is installed.
use Pod::Parser;

my @blockplugins  = qw/definition headline hr list paragraph pre quote/;
my @inlineplugins = qw/acronym basic htmlescape link link::article link::external link::file link::image link::nolink replace/;

#load modules to get their full path from %INC later
foreach my $plugin (@blockplugins, @inlineplugins) {
	my $module = "Konstrukt::Plugin::wiki::markup::$plugin";
	#try to load
	eval "require $module";
	#error?
	die "Cannot load module $module! $@" if $@;
} 

#build doc
my $doc =
	"=head1 NAME\n\n" .
	"Konstrukt::Plugin::wiki::syntax - Overview of the Syntax of the wiki plugin. For more details, take a look at the documentation of each markup plugin.\n\n" .
	"=head1 BLOCK SYNTAX\n\n" .
	extract_sections_from_plugins(@blockplugins) .
	"=head1 INLINE SYNTAX\n\n" .
	extract_sections_from_plugins(@inlineplugins) .
	"=head1 AUTHOR\n\nCopyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved.\n\nThis document is free software.\nIt is distributed under the same terms as Perl itself.\n\n" .
	"=head1 SEE ALSO\n\nL<Konstrukt::Doc>, L<Konstrukt::Plugin::wiki>\n\n=cut\n";

print $doc;

sub extract_sections_from_plugins {
	my $text = '';
	foreach my $plugin (@_) {
		my $module = "Konstrukt::Plugin::wiki::markup::$plugin.pm";
		$module =~ s/::/\//g;
		$text .= "=head2 $plugin\n\n";
		#select description and example
		my $selection = `podselect -section 'DESCRIPTION|EXAMPLE' $INC{$module}`;
		#remove/replace headings
		$selection =~ s/^=head1 DESCRIPTION.*$//gm;
		$selection =~ s/^=head1 EXAMPLE.*$/Example:/gm;
		$text .= $selection;
	}
	#decrease headings level
	return $text;
}
