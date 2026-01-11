package MARC::Validator::Filter;

use strict;
use warnings;

use Module::Pluggable require => 1;

our $VERSION = 0.01;

1;

__END__

=encoding utf8

=head1 NAME

MARC::Validator::Filter - MARC validator filter plugins.

=head1 SYNOPSIS

 use MARC::Validator::Filter;

 my @plugins = MARC::Validator::Filter->plugins;

=head1 METHODS

=head2 C<plugins>

 my @plugins = MARC::Validator::Filter->plugins;

Get list of present plugins.

Returns list of plugin module name strings.

=head1 EXAMPLE

=for comment filename=plugins_list.pl

 use strict;
 use warnings;

 use MARC::Validator::Filter;

 my @plugins = MARC::Validator::Filter->plugins;

 if (@plugins) {
         print "List of plugins:\n";
         foreach my $plugin (@plugins) {
                 print "- $plugin\n";
         }
 } else {
         print "No plugins.\n";
 }

 # Output like:
 # List of plugins:
 # - MARC::Validator::Filter::Plugin::AACR2
 # - MARC::Validator::Filter::Plugin::Material
 # - MARC::Validator::Filter::Plugin::RDA

=head1 DEPENDENCIES

L<Module::Pluggable>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Validator-Filter>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025-2026 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.01

=cut
