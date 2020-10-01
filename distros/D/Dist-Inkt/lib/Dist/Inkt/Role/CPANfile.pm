package Dist::Inkt::Role::CPANfile;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use namespace::autoclean;

after PopulateMetadata => sub
{
	my $self = shift;
	
	return unless $self->sourcefile('cpanfile')->exists;
	
	$self->log('Processing cpanfile');
	
	require Module::CPANfile;
	my $file = Module::CPANfile->load( $self->sourcefile('cpanfile') );
	
	my $orig = $self->metadata->prereqs;
	$orig = CPAN::Meta::Prereqs->new($orig) unless blessed($orig);
	my $merged = $file->prereqs->with_merged_prereqs($orig);
	$self->metadata->{prereqs} = $merged->as_string_hash;
};

1;
