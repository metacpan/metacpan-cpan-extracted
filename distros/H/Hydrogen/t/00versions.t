=pod

=encoding utf-8

=head1 NAME

00versions.t - print versions of dependencies

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2022 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

use strict;
use warnings;
use Test2::V0;

sub diag_version {
	my ( $module, $version ) = @_;
	if ( @_ == 1 ) {
		eval "require $module";
		$version = $module->VERSION;
	}
	diag sprintf '%s %s', $module, $version;
}

diag '';
diag_version 'perl', $];
diag_version 'Carp';
diag_version 'Data::Dumper';
diag_version 'Exporter::Shiny';
diag_version 'List::Util';
diag_version 'Scalar::Util';
diag_version 'Test2::V0';
diag '';

pass;

done_testing;
