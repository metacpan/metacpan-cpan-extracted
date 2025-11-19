package MARC::Validator;

use strict;
use warnings;

use Module::Pluggable require => 1;

our $VERSION = 0.07;

1;

__END__

=encoding utf8

=head1 NAME

MARC::Validator - Set of plugins for MARC validation.

=head1 SYNOPSIS

 use MARC::Validator;

 my @plugins = MARC::Validator->plugins;

=head1 METHODS

=head2 C<plugins>

 my @plugins = MARC::Validator->plugins;

Get list of present plugins.

Returns list of plugin module name strings.

=head1 EXAMPLE

=for comment filename=plugins_list.pl

 use strict;
 use warnings;

 use MARC::Validator;

 my @plugins = MARC::Validator->plugins;

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
 # - MARC::Validator::Plugin::Field008
 # - MARC::Validator::Plugin::Field020
 # - MARC::Validator::Plugin::Field040
 # - MARC::Validator::Plugin::Field260
 # - MARC::Validator::Plugin::Field264

=head1 DEPENDENCIES

L<Module::Pluggable>.

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/MARC-Validator>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© 2025 Michal Josef Špaček

BSD 2-Clause License

=head1 ACKNOWLEDGEMENTS

Development of this software has been made possible by institutional support
for the long-term strategic development of the National Library of the Czech
Republic as a research organization provided by the Ministry of Culture of
the Czech Republic (DKRVO 2024–2028), Area 11: Linked Open Data.

=head1 VERSION

0.07

=cut
