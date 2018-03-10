package Dist::Inkt::Profile::KJETILK;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.101';

use Moose;
use Types::Standard qw(Bool);
use namespace::autoclean;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::ReadMetaDir
   Dist::Inkt::Role::AddExternalRDF
	Dist::Inkt::Role::Git
	Dist::Inkt::Role::ProcessDOAP
	Dist::Inkt::Role::ProcessDOAPDeps
	Dist::Inkt::Role::CPANfile
	Dist::Inkt::Role::DetermineRightsFromRdf
	Dist::Inkt::Role::CopyStandardDocuments
	Dist::Inkt::Role::CopyFiles
	Dist::Inkt::Role::MetaProvides
	Dist::Inkt::Role::MetaProvidesScripts
	Dist::Inkt::Role::StaticInstall
	Dist::Inkt::Role::WriteMakefilePL
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteDOAP
	Dist::Inkt::Role::WriteChanges
	Dist::Inkt::Role::WriteCOPYRIGHT
	Dist::Inkt::Role::WriteCREDITS
	Dist::Inkt::Role::WriteLICENSE
	Dist::Inkt::Role::WriteREADME
	Dist::Inkt::Role::WriteINSTALL
	Dist::Inkt::Role::SignDistribution
	Dist::Inkt::Role::Release
	Dist::Inkt::Role::Test::BumpedVersion
	Dist::Inkt::Role::Test::TestSuite
	Dist::Inkt::Role::Test::Changes
);



1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Profile::KJETILK - a Dist::Inkt profile for KJETILK

=head1 SEE ALSO

L<Dist::Inkt>, L<Dist::Inkt::DOAP>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

Adapted by Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

