package Dist::Inkt::Profile::Simple;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose;
use Types::Standard qw( ArrayRef Str );
use namespace::autoclean;

extends 'Dist::Inkt';

with qw(
	Dist::Inkt::Role::CPANfile
	Dist::Inkt::Role::CopyStandardDocuments
	Dist::Inkt::Role::CopyFiles
	Dist::Inkt::Role::MetaProvides
	Dist::Inkt::Role::MetaProvidesScripts
	Dist::Inkt::Role::StaticInstall
	Dist::Inkt::Role::WriteMakefilePL
	Dist::Inkt::Role::WriteMetaJSON
	Dist::Inkt::Role::WriteMetaYML
	Dist::Inkt::Role::WriteDOAPLite
	Dist::Inkt::Role::WriteLICENSE
	Dist::Inkt::Role::WriteREADME
	Dist::Inkt::Role::WriteINSTALL
);

has abstract => (
	is          => 'ro',
	isa         => Str,
	predicate   => 'has_abstract',
);

has author => (
	is          => 'ro',
	isa         => ArrayRef[Str],
	predicate   => 'has_author',
);

has license => (
	is          => 'ro',
	isa         => ArrayRef[Str],
	predicate   => 'has_license',
);

around _build_metadata => sub
{
	my $next = shift;
	my $self = shift;
	my $meta = $self->$next(@_);
	
	$meta->{abstract} = $self->abstract if $self->has_abstract;
	$meta->{author}   = $self->author   if $self->has_author;
	$meta->{license}  = $self->license  if $self->has_license;
	
	return $meta;
};

1;
