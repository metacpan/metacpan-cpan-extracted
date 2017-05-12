#!/usr/bin/perl

use strict;
use warnings;

#podselect is shipped with Pod::Parser.
#load this module to ensure it is installed.
use Pod::Parser;

#get list of plugins
opendir DIR, "lib/Konstrukt/Plugin";
my @plugins = sort map { s/\.pm$//; $_ } grep { !/^test$/ } grep { /\.pm$/ } (readdir DIR);
closedir DIR;

#load modules to get their full path from %INC later
foreach my $plugin (@plugins) {
	my $module = "Konstrukt::Plugin::$plugin";
	#try to load
	eval "require $module";
	#error?
	die "Cannot load module $module! $@" if $@;
} 

#build doc
my $doc =
	"=head1 NAME\n\n" .
	"Konstrukt::Doc::PluginList - Complete list of the plugins that are shipped with this package.\n\n" .
	"=head1 PLUGINS\n\n" .
	extract_sections_from_plugins(@plugins) .
	"=head1 AUTHOR\n\nCopyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved.\n\nThis document is free software.\nIt is distributed under the same terms as Perl itself.\n\n" .
	"=head1 SEE ALSO\n\nL<Konstrukt::Doc>\n\n=cut\n";

print $doc;

sub extract_sections_from_plugins {
	my $text = '';
	foreach my $plugin (@_) {
		my $module = "Konstrukt::Plugin::$plugin.pm";
		$module =~ s/::/\//g;
		$text .= "\n=head2 $plugin\n\n";
		#select description and example
		my $selection = `podselect -section 'NAME|SYNOPSIS' $INC{$module}`;
		#remove/replace headings
		$selection =~ s/^=head1 (NAME|SYNOPSIS).*$//gm;
		#replace head2 by head3
		$selection =~ s/^=head2/=head3/gm;
		#remove the plugin name from the short description
		$selection =~ s/^Konstrukt::Plugin::$plugin\s+-\s*//gm;
		$text .= $selection;
		$text .= "Complete documentation: L<Konstrukt::Plugin::$plugin>.";
	}
	#decrease headings level
	return $text;
}
