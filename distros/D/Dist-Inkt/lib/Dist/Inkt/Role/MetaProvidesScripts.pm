package Dist::Inkt::Role::MetaProvidesScripts;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use Path::Tiny 'path';
use namespace::autoclean;

after PopulateMetadata => sub
{
	my $self = shift;
	$self->log("Finding provided scripts");
	
	my $src = $self->sourcefile;
	
	### XXX - should filter by manifest_skip
	my %scripts = (
		map {
			my $path = path($_);
			$path->basename => { file => $path->relative($src) };
		}
		map {
			$_->children;
		}
		grep {
			$_->exists;
		}
		(
			$src->child('bin'),
			$src->child('script'),
		),
	);
	
	$self->metadata->{x_provides_scripts} = \%scripts if scalar keys %scripts;
};

1;
