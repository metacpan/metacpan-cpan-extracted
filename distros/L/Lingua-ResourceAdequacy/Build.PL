use Module::Build;
my $class = Module::Build->subclass(
				    class => "Module::Build::Custom",
code => <<'SUBCLASS' );

sub ACTION_install {
    my $self = shift;
    $self->SUPER::ACTION_install;
}
SUBCLASS

my $build = $class->new
    (
     module_name => 'Lingua::ResourceAdequacy',
     dist_version_from => 'lib/Lingua/ResourceAdequacy.pm',
     license => 'gpl',
     requires => {'perl' => '5.005',
		  Test::Pod => 0,
		  Test::More => 0,
		  Test::Pod::Coverage => 0,
		  Test::Simple => 0,
		  },
    build_requires => {
        "Module::Build"     => 0.28,
    },
     installdirs => 'core',
     );


$build->create_build_script;

