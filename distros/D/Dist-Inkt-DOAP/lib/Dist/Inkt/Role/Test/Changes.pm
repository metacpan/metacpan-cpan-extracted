use 5.010001;
use strict;
use warnings;

package Dist::Inkt::Role::Test::Changes;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use Moose::Role;
with qw(
	Dist::Inkt::Role::Test
	Dist::Inkt::Role::RDFModel
);

after BUILD => sub {
	my $self = shift;
	
	$self->setup_prebuild_test(sub {
		my $self = shift;
		
		$self->log("Checking DOAP changeset metadata is current");
		
		my $latest_in_meta = $self->doap_project->sorted_releases->[-1];
		$latest_in_meta = $latest_in_meta->revision if $latest_in_meta;
		
		if (!defined $latest_in_meta)
		{
			$self->log("No versions listed in DOAP");
			die "Please update DOAP changelog";
		}
		
		my $current_version = $self->version;
		
		unless ($self->version eq $latest_in_meta)
		{
			$self->log("Latest version according to DOAP metadata is $latest_in_meta, but this is $current_version");
			die "Please update DOAP changelog";
		}
	});
};

1;
