package Dist::Inkt::Role::WriteDOAPLite;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'DOAP';
};

sub Build_DOAP
{
	my $self = shift;
	my $file = $self->targetfile('doap.ttl');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	$self->rights_for_generated_files->{'doap.ttl'} ||= [
		$self->_inherited_rights
	];
	
	require CPAN::Changes;
	require RDF::DOAP::Lite;
	
	my $changes;
	$changes = CPAN::Changes->load($self->sourcefile('Changes'))
		if $self->sourcefile('Changes')->exists;
	
	my $doap = $changes
		? RDF::DOAP::Lite->new(meta => $self->metadata, changes => $changes)
		: RDF::DOAP::Lite->new(meta => $self->metadata);
	
	$doap->doap_ttl( $file->absolute->stringify );
}

1;
