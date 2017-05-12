use strict;
use warnings;
use Module::Build;

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code  => <<'END_CODE',

sub ACTION_authortest {
	my ($self) = @_;

	$self->depends_on('build');

	$self->test_files( qw( t xt/author ) );
	$self->depends_on('test');

	return;
}



sub ACTION_releasetest {
	my ($self) = @_;

	$self->depends_on('build');

	$self->test_files( qw( t xt/author xt/release ) );
	$self->depends_on('test');

	return;
}



sub ACTION_manifest {
	my ($self, @arguments) = @_;

	if (-e 'MANIFEST') {
		unlink 'MANIFEST' or die "Can't unlink MANIFEST: $!";
	}

	return $self->SUPER::ACTION_manifest(@arguments);
}

sub ACTION_distmeta {
	my ($self) = @_;

	$self->depends_on('manifest');

	return $self->SUPER::ACTION_distmeta();
}
END_CODE
);


my $builder = $class->new(
	module_name              => 'Dist::Zilla::BeLike::CSJEWELL',
	license                  => 'perl',
	dist_author              => [ 'Curtis Jewell <CSJewell@cpan.org>' ],
	dist_version_from        => 'lib/Dist/Zilla/BeLike/CSJEWELL.pm',
	create_readme            => 1,
	create_license           => 1,
	create_makefile_pl       => 'small',
	configure_requires       => {
		'Module::Build'      => '0.33',
	},
	requires => {
		'perl'                                => '5.008003',	
		'Dist::Zilla'                         => '4.102221',
		'Dist::Zilla::Plugin::Mercurial'      => '0.03',
		'Dist::Zilla::Plugin::Twitter'        => '0.009',
		'Module::Build'                       => '0.33',
		'Moose'                               => '1.09',
		'autodie'                             => '2.10',
		'Pod::Readme'                         => '0.10',
		'Software::License'                   => '0.101620',
		# These next 2 are from libnet 1.22.
		'Net::Netrc'                          => '2.12',
		'Net::FTP'                            => '2.77',
		# These are what the author tests require.
		# Might as well have the prospective builder install
		#  them now.
		'Perl::MinimumVersion'                => '1.26',
		'Pod::Coverage::Moose'                => '0.01',
		'Pod::Coverage'                       => '0.21',
		'Test::Pod::Coverage'                 => '1.08',
		'Pod::Simple'                         => '3.14',
		'Test::Pod'                           => '1.44',
		'Perl::Tidy'                          => '20090616',
		'PPIx::Regexp'                        => '0',
		'PPIx::Utilities::Statement'          => '0',
		'Email::Address'                      => '0',
		'Perl::Critic::Utils::Constants'      => '0',
		'Perl::Critic::More'                  => '0',
		'Perl::Critic'                        => '1.108',
		'Test::Perl::Critic'                  => '0',
		'Test::MinimumVersion'                => '0.101080',
		'Parse::CPAN::Meta'                   => '1.40',
		'Test::CPAN::Meta'                    => '0.17',
		'Test::DistManifest'                  => '1.009',
		'Test::Fixme'                         => '0.04',
		'Pod::Spell::CommonMistakes'          => '0.01',
		'Test::Pod::Spelling::CommonMistakes' => '0.01',
		'Test::CheckChanges'                  => '0.14',
		'Test::HasVersion'                    => '0.012',
		'Test::Prereq::Build'                 => '1.037',
		'Test::Portability::Files'            => '0.05',
	},
	build_requires => {
		'Test::More'                          => '0.88',
		'Test::UseAllModules'                 => '0.12',
	},
	meta_merge     => {
		resources => {
			homepage    => 'http://csjewell.comyr.com/perl/',
			bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-BeLike-CSJEWELL',
			repository  => 'http://bitbucket.org/csjewell/dist-zilla-belike-csjewell'
		},
	},
	share_dir => {
		module => {
			'Dist::Zilla::MintingProfile::CSJEWELL'  => 'share',
		}
	},
	add_to_cleanup      => [ 'Dist-Zilla-BeLike-CSJEWELL-*', ],
);

$builder->create_build_script();
