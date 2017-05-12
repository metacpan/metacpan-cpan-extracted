package Dist::Inkt::Role::WriteChanges;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.022';

use Moose::Role;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'Changes';
};

sub Build_Changes
{
	my $self = shift;
	my $file = $self->targetfile('Changes');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	$self->rights_for_generated_files->{'Changes'} ||= [
		$self->_inherited_rights
	] if $self->DOES('Dist::Inkt::Role::WriteCOPYRIGHT');
	$file->spew_utf8($self->doap_project->changelog);
}

1;
