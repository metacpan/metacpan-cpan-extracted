package Dist::Inkt::Profile::TOBYINK;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.024';

use Moose;
use Types::Standard qw(Bool);
use namespace::autoclean;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::ReadMetaDir
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
	Dist::Inkt::Role::Test::Whitespace
	Dist::Inkt::Role::Test::BumpedVersion
	Dist::Inkt::Role::Test::SaneVersions
	Dist::Inkt::Role::Test::TestSuite
	Dist::Inkt::Role::Test::Kwalitee
	Dist::Inkt::Role::Test::Changes
	Dist::Inkt::Role::Hg
);

has skip_installation => ( is => "ro", isa => Bool, default => 0 );

before Release => sub
{
	my $self = shift;
	return if $self->skip_installation;
	my $tarball = Path::Tiny::path($_[0] || sprintf('%s.tar.gz', $self->targetdir));
	$self->log("Installing locally...");
	if (system("cpanm", $tarball)) {
		die "Could not be installed locally!";
	}
};

after Release => sub
{
	my $self = shift;
	
	require Path::Tiny;
	my $dest = Path::Tiny::path("~")->child("perl5/published");
	return $self->log("$dest does not exist; cannot move tarball safely away")
		unless -d $dest;
	
	my $tarball = Path::Tiny::path($_[0] || sprintf('%s.tar.gz', $self->targetdir));
	$self->log("Moving $tarball to $dest");
	$tarball->move( $dest->child($tarball->basename) );
};

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Dist::Inkt::Profile::TOBYINK - a Dist::Inkt profile for TOBYINK

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Dist-Inkt-Profile-TOBYINK>.

=head1 SEE ALSO

L<Dist::Inkt>, L<Dist::Inkt::DOAP>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2014 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

