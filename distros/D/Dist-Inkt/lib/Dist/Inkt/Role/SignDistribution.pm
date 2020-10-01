package Dist::Inkt::Role::SignDistribution;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.025';

use Moose::Role;
use Module::Signature ();
use Types::Standard qw(Bool);
use File::chdir;
use namespace::autoclean;

has should_sign => (
	is       => 'ro',
	isa      => Bool,
	default  => sub { !$ENV{PERL_DIST_INKT_NOSIGNATURE} },
);

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'SIGNATURE' if $self->should_sign;
};

sub Build_SIGNATURE
{
	my $self = shift;
	my $file = $self->targetfile('SIGNATURE');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	$self->rights_for_generated_files->{'SIGNATURE'} ||= [
		'None', 'public-domain'
	];
	$file->spew('placeholder');
}

after BuildManifest => sub {
	my $self = shift;
	
	$self->should_sign or return;
	$self->targetfile('SIGNATURE')->exists or die("Missing SIGNATURE");
	
	local $CWD = $self->targetdir;
	system("cpansign sign");
	if ($?) {
		$self->log("ERROR: signature failed!!!");
		die("Bailing out");
	}
};

1;
