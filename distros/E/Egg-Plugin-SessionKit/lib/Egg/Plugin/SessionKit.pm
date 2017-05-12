package Egg::Plugin::SessionKit;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: SessionKit.pm 322 2008-04-17 12:33:58Z lushe $
#
use strict;
use warnings;
use base qw/ Egg::Plugin::Session /;

our $VERSION= '3.05';

1;

__END__

=head1 NAME

Egg::Plugin::SessionKit - Package kit to use session.

=head1 DESCRIPTION

It is a package kit to use the session function.

The following modules are included.

=over 4

=item * Model

L<Egg::Model::Session>,

=over 4

=item * Base class module.

L<Egg::Model::Session::Manager::Base>,
L<Egg::Model::Session::Manager::TieHash>,

=item * Component module.

=over 4

=item * Base system

L<Egg::Model::Session::Base::DBI>,
L<Egg::Model::Session::Base::DBIC>,
L<Egg::Model::Session::Base::FileCache>,

=item * Bind sytem

L<Egg::Model::Session::Bind::Cookie>,

=item * ID system

L<Egg::Model::Session::ID::IPaddr>,
L<Egg::Model::Session::ID::MD5>,
L<Egg::Model::Session::ID::SHA1>,
L<Egg::Model::Session::ID::UniqueID>,
L<Egg::Model::Session::ID::UUID>,

=item * Store system

L<Egg::Model::Session::Store::Base64>,
L<Egg::Model::Session::Store::UUencode>,

=item * Plugin system

L<Egg::Model::Session::Plugin::AbsoluteIP>,
L<Egg::Model::Session::Plugin::AgreeAgent>,
L<Egg::Model::Session::Plugin::CclassIP>,
L<Egg::Model::Session::Plugin::Ticket>,

=back

=back

=item * Plugin

L<Egg::Plugin::Session>,

=item * Helper

L<Egg::Helper::Model::Session>,

=back

=head1 SEE ALSO

L<Egg::Release>,
L<Egg::Plugin::Session>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

