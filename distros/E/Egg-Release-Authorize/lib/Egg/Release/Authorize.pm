package Egg::Release::Authorize;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: Authorize.pm 347 2008-06-14 18:57:53Z lushe $
#
use strict;
use warnings;

our $VERSION = '0.06';

1;

__END__

=head1 NAME

Egg::Release::Authorize - Package kit for attestation. 

=head1 DESCRIPTION

It is a package kit for the attestation.

The following modules are included.

=over 4

=item * Model

L<Egg::Model::Auth>,

=over 4

=item * Base class module.

L<Egg::Model::Auth::Base>,
L<Egg::Model::Auth::Base::API>,

=item * API system.

L<Egg::Model::Auth::API::DBI>,
L<Egg::Model::Auth::API::DBIC>,
L<Egg::Model::Auth::API::File>,

=item * Bind system.

L<Egg::Model::Auth::Bind::Cookie>,

=item * Crypt system.

L<Egg::Model::Auth::Crypt::CBC>,
L<Egg::Model::Auth::Crypt::Func>,
L<Egg::Model::Auth::Crypt::MD5>,
L<Egg::Model::Auth::Crypt::SHA1>,

=item * Plugin system.

L<Egg::Model::Auth::Plugin::Keep>,

=item * Session system.

L<Egg::Model::Auth::Session::FileCache>,
L<Egg::Model::Auth::Session::SessionKit>,

=back

=item * Helper

L<Egg::Helper::Model::Auth>,

=back

=head1 SEE ALSO

L<Egg::Release>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

