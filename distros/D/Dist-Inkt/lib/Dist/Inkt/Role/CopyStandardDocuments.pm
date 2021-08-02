package Dist::Inkt::Role::CopyStandardDocuments;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.026';

use Moose::Role;
use Types::Path::Tiny -types;
use Path::Tiny 'path';
use namespace::autoclean;

has standard_documents_dir => (
	is       => 'ro',
	isa      => AbsPath,
	coerce   => 1,
	lazy     => 1,
	builder  => '_build_standard_documents_dir',
);

sub _build_standard_documents_dir
{
	return path('~/perl5/standard-documents');
}

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'StandardDocuments';
};

sub Build_StandardDocuments
{
	my $self = shift;
	
	my $src = $self->standard_documents_dir;
	$src->exists or return;
	$src->is_dir or return;
	
	my $dest = $self->targetdir;
	
	for ($src->children)
	{
		my $file = path($_);
		$file->is_file or next;
		my $relative = $file->relative($src);
		my $destfile = $relative->absolute($dest);
		$self->log("Copying $file");
		$file->copy($destfile);
	}
}

1;
