package Dist::Inkt::Role::MetaProvides;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.024';

use Moose::Role;
use Module::Metadata;
use namespace::autoclean;

after PopulateMetadata => sub
{
	my $self = shift;
	$self->log("Finding provided packages");
	
	my $provides = 'Module::Metadata'->provides(
		version  => '2',
		dir      => $self->sourcefile('lib'),
	);
	
	for my $pkg ( @{ $self->metadata->{no_index}{package} or [] } ) {
		delete $provides->{$pkg};
	}
	
	for my $ns ( @{ $self->metadata->{no_index}{namespace} or [] } ) {
		for my $pkg (keys %$provides) {
			delete $provides->{$pkg}
				if $pkg =~ m{^\Q$ns\E::};
		}
	}
	
	for my $dir ( @{ $self->metadata->{no_index}{directory} or [] } ) {
		for my $pkg (keys %$provides) {
			delete $provides->{$pkg}
				if $provides->{$pkg}{file} =~ m{^\Q$dir\E/};
		}
	}
	
	for my $file ( @{ $self->metadata->{no_index}{file} or [] } ) {
		for my $pkg (keys %$provides) {
			delete $provides->{$pkg}
				if $provides->{$pkg}{file} eq $file;
		}
	}
	
	# XXX - should also filter result using manifest_skip
	
	$self->metadata->{provides} = $provides;
};

1;
