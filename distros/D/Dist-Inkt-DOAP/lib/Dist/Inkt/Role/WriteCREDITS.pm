package Dist::Inkt::Role::WriteCREDITS;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.100';

use Moose::Role;
use namespace::autoclean;

with 'Dist::Inkt::Role::RDFModel';

after PopulateMetadata => sub {
	my $self = shift;
	
	my @maint = $self->doap_project->gather_all_maintainers;
	push @{ $self->metadata->{author} ||= [] }, map "$_", @maint if @maint;
	
	my %already = map +($_ => 1), @maint;
	my @contrib = grep !$already{$_}, $self->doap_project->gather_all_contributors;
	push @{ $self->metadata->{x_contributors} ||= [] }, map "$_", @contrib if @contrib;
};

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'CREDITS';
};

sub Build_CREDITS
{
	my $self = shift;
	my $file = $self->targetfile('CREDITS');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	$self->rights_for_generated_files->{'CREDITS'} ||= [
		'None', 'public-domain'
	] if $self->DOES('Dist::Inkt::Role::WriteCOPYRIGHT');
	
	my $fh = $file->openw_utf8;
	
	my %already;
	for my $role (qw/ maintainer contributor thanks /)
	{
		(my $method = "gather_all_${role}s") =~ s/ss$/s/s;
		my @peeps =
			sort { $a->to_string cmp $b->to_string }
			grep { blessed($_) and not $already{$_}++ }
			$self->doap_project->$method;
		next unless @peeps;
		
		printf {$fh} ("%s:\n", ucfirst $role);
		printf {$fh} ("- %s\n", $_->to_string) for @peeps;
		printf {$fh} ("\n");
	}
	
	close($fh);
}

1;
