package Dist::Inkt::Role::WriteLICENSE;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.026';

use Moose::Role;
use Software::LicenseUtils;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'LICENSE';
};

# I've submitted this hash as a patch for Software::LicenseUtils.
# Maybe I won't need to hard-code it here.
#
my %meta_keys = (
	## CPAN::Meta::Spec 2.0
	##
	agpl_3       => 'AGPL_3',
	apache_1_1   => 'Apache_1_1',
	apache_2_0   => 'Apache_2_0',
	artistic_1   => 'Artistic_1_0',
	artistic_2   => 'Artistic_2_0',
	bsd          => 'BSD',
	freebsd      => 'FreeBSD',
	gfdl_1_2     => 'GFDL_1_2',
	gfdl_1_3     => 'GFDL_1_3',
	gpl_1        => 'GPL_1',
	gpl_2        => 'GPL_2',
	gpl_3        => 'GPL_3',
	lgpl_2_1     => 'LGPL_2_1',
	lgpl_3_0     => 'LGPL_3_0',
	mit          => 'MIT',
	mozilla_1_0  => 'Mozilla_1_0',
	mozilla_1_1  => 'Mozilla_1_1',
	openssl      => 'OpenSSL',
	perl_5       => 'Perl_5',
	qpl_1_0      => 'QPL_1_0',
	ssleay       => 'SSLeay',
	sun          => 'Sun',
	zlib         => 'Zlib',
	# open_source
	restricted   => 'None',
	# unrestricted
	# unknown
	
	## META-spec 1.4
	##
	apache       => [ map { "Apache_$_" } qw(1_1 2_0) ],
	# apache_1_1
	perl         => 'Perl_5',
	artistic     => 'Artistic_1_0',
	# artistic_2
	# bsd
	gpl          => [ map { "GPL_$_" } qw(1 2 3) ],
	lgpl         => [ map { "LGPL_$_" } qw(2_1 3_0) ],
	# mit
	mozilla      => [ map { "Mozilla_$_" } qw(1_0 1_1 2_0) ],
	# open_source
	restrictive  => 'None',
	# unrestricted
	# unknown
);

sub Build_LICENSE
{
	my $self = shift;
	
	my $file = $self->targetfile('LICENSE');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $L = $self->metadata->{license};
	unless (@{ $L || [] }==1)
	{
		$self->log('WARNING: did not find exactly one licence; found %d', scalar(@{ $L || [] }));
		return;
	}
	
	my $class;
	unless ($class = $meta_keys{$L->[0]})
	{
		$self->log("WARNING: could not grok licence '%s'", @$L);
		return;
	}
	
	if (ref $class)
	{
		$self->log("WARNING: ambiguous licence '%s'", @$L);
		return;
	}
	
	my $holders = Moose::Util::english_list(
		$self->can('doap_project')
			? map($_->to_string('compact'), @{$self->doap_project->maintainer})
			: @{$self->metadata->{author}}
	);
	
	$class = "Software::License::$class";
	eval "require $class;";
	my $licence = $class->new({
		year   => [localtime]->[5] + 1900,
		holder => $holders,
	});
	
	$file->spew_utf8( $licence->fulltext );
}

1;
