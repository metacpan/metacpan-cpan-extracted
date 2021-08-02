package Dist::Inkt::Role::WriteREADME;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.026';

use Moose::Role;
use Pod::Text;
use namespace::autoclean;

has source_for_readme => (
	is      => 'ro',
	lazy    => 1,
	default => sub { shift->lead_module },
);

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'README';
};

sub Build_README
{
	my $self = shift;
	
	my $file = $self->targetfile('README');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $pod = 'Pod::Text'->new(
		sentance => 0,
		width    => 78,
		errors   => 'die',
		quotes   => q[``],
		utf8     => 1,
	);
	
	my $input = $self->source_for_readme;
	unless ($input =~ /\.(pm|pod)$/)
	{
		$input =~ s{::}{/}g;
		$input = "lib/$input.pm";
	}
	$input = $self->sourcefile($input);

	# inherit rights from input pod
	$self->rights_for_generated_files->{'README'} ||= [
		$self->_determine_rights($input)
	] if $self->can('_determine_rights');

	$pod->parse_from_file("$input", "$file");
}

1;
