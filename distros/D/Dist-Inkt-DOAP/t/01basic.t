=pod

=encoding utf-8

=head1 PURPOSE

Test that Dist::Inkt::DOAP compiles.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=cut

use strict;
use warnings;
use Test::More;

use_ok('Dist::Inkt::DOAP');
use_ok('Dist::Inkt::Role::WriteCREDITS');
use_ok('Dist::Inkt::Role::ReadMetaDir');
use_ok('Dist::Inkt::Role::RDFModel');
use_ok('Dist::Inkt::Role::WriteDOAP');
use_ok('Dist::Inkt::Role::WriteChanges');
use_ok('Dist::Inkt::Role::WriteCOPYRIGHT');
use_ok('Dist::Inkt::Role::ProcessDOAP');
use_ok('Dist::Inkt::Role::DetermineRightsFromRdf');
use_ok('Dist::Inkt::Role::ProcessDOAPDeps');

done_testing;

