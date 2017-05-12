package Egg::Release::DBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: DBI.pm 335 2008-05-12 05:11:27Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Egg::Release::DBI - Package kit of model DBI.

=head1 DESCRIPTION

=over 4

=item * Egg::Model::DBI

Model to use DBI.

=item * Egg::Model::DBI::Base

Base class for connection object.

=item * Egg::Model::DBI::dbh

Wrapper module of data base handler.

=item * Egg::Mod::EasyDBI

Module to treat DBI easily.

=item * Egg::Plugin::EasyDBI

Plugin to use Egg::Mod::EasyDBI.

=item * Egg::Helper::Model::DBI

Helper to generate connection module.

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Model::DBI>,
L<Egg::Model::DBI::Base>,
L<Egg::Model::DBI::dbh>,
L<Egg::Mod::EasyDBI>,
L<Egg::Plugin::EasyDBI>,
L<Egg::Helper::Model::DBI>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

