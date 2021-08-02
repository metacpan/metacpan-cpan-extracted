package Dist::Inkt::Role::WriteINSTALL;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.026';

use Moose::Role;
use namespace::autoclean;

after BUILD => sub {
	my $self = shift;
	unshift @{ $self->targets }, 'INSTALL';
};

sub Build_INSTALL
{
	my $self = shift;
	my $file = $self->targetfile('INSTALL');
	$file->exists and return $self->log('Skipping %s; it already exists', $file);
	$self->log('Writing %s', $file);
	
	my $pod = 'Pod::Text'->new(
		sentance => 0,
		width    => 78,
		errors   => 'die',
		quotes   => q[``],
		utf8     => 1,
	);
	$pod->output_fh($file->openw_utf8);
	$pod->parse_string_document(
		join(
			"\n\n",
			"=pod",
			"=encoding utf-8",
			$self->installfile_summary,
			$self->installfile_cpanm,
			$self->installfile_cpan,
			$self->installfile_manual,
			$self->installfile_features,
			"=cut",
			"",
		)
	);
}

sub installfile_summary
{
	my $self = shift;
	return sprintf("Installing %s should be straightforward.\n\n", $self->name);
}

sub installfile_cpanm
{
	my $self = shift;
	return (
		"=head1 INSTALLATION WITH CPANMINUS",
		"If you have cpanm, you only need one line:",
		sprintf("\t%% cpanm %s", $self->lead_module),
		"If you are installing into a system-wide directory, you may need to pass the \"-S\" flag to cpanm, which uses sudo to install the module:",
		sprintf("\t%% cpanm -S %s", $self->lead_module),
	);
}

sub installfile_cpan
{
	my $self = shift;
	return (
		"=head1 INSTALLATION WITH THE CPAN SHELL",
		"Alternatively, if your CPAN shell is set up, you should just be able to do:",
		sprintf("\t%% cpan %s", $self->lead_module),
	);
}

sub installfile_manual
{
	my $self = shift;
	return (
		"=head1 MANUAL INSTALLATION",
		"As a last resort, you can manually install it. Download the tarball and unpack it.",
		"Consult the file META.json for a list of pre-requisites. Install these first.",
		sprintf("To build %s:", $self->name),
		"\t% perl Makefile.PL\n".
		"\t% make && make test",
		"Then install it:",
		"\t% make install",
		"If you are installing into a system-wide directory, you may need to run:",
		"\t% sudo make install",
	);
}

sub installfile_features
{
	my $self = shift;
	my @features = sort keys %{$self->metadata->{optional_features}}
		or return;
	
	return (
		"=head1 OPTIONAL FEATURES",
		sprintf("%s provides several optional features, which may require additional pre-requisites. These features are:", $self->name),
		"=over",
		map(
			sprintf(
				"=item *\n\n%s (%s)",
				$_,
				$self->metadata->{optional_features}{$_}{description} || 'no description'
			),
			@features
		),
		"=back",
		"cpanminus 1.7000 and above support installing optional features:",
		sprintf("\t%% cpanm --with-feature=%s %s", $features[0], $self->lead_module),
		"Otherwise, Makefile.PL can prompt you to select features. Set the C<MM_INSTALL_FEATURES> environment variable to \"1\" before running Makefile.PL.",
	);
}

1;
