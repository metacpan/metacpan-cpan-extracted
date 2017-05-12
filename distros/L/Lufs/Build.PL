use Module::Build;

# overload hack usage of ./perlufs/makefile
# is dirty hack

my $class = Module::Build->subclass(
	class => 'My::Builder',
	code => << 'EOO'
sub process_perlfs_files {
  chdir 'perlfs' || die $!;
  $_[0]->do_system(qw/make all/,"PERL=$^X");
  chdir('..');
}

sub ACTION_install {
  my ($self) = @_;
  require ExtUtils::Install;
  $self->depends_on('build');
  ExtUtils::Install::install($self->install_map, 1, 0, $self->{args}{uninst}||0);
  chdir('perlfs') || die $!;
  $self->do_system(qw/make install/);
  chdir('..');
}
EOO
);

my $build = $class->new(
	dist_name => 'Lufs',
	dist_version_from => 'lib/Lufs.pm',
	dist_author => 'Raoul Zwart <rlzwart@cpan.org>', 
	license => 'perl',
	requires => {
		'HTML::TokeParser::Simple' => 0,
		'Linux::Pid' 		=> 0,
		'Inline::MakeMaker' => 0,
	}
);

push @{$$build{properties}{build_elements}}, 'perlfs';
$build->add_to_cleanup(map "perlfs/$_", qw#perlfs.lo liblufs-perlfs.so.2.0.0#);

$build->create_build_script;
