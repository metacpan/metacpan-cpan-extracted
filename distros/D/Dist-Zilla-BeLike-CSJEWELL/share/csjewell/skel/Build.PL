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
{{
	$dist_module = join('::', split(/-/, $dist->name));
	$authors_list = join( q{' '}, @{$dist->authors} );
	$repository = $dist->stash_named('%DefaultURLs')->repository_location . lc $dist->name;
	$homepage = $dist->stash_named('%DefaultURLs')->homepage;	
	'';
}}

my $builder = $class->new(
    module_name              => '{{$dist_module}}',
    license                  => '{{$dist->license->meta_name}}',
    dist_author              => [ '{{$authors_list}}' ],
    dist_version_from        => '{{$dist->main_module->name}}',
	create_readme            => 1,
	create_license           => 1,
	create_makefile_pl       => 'small',
	configure_requires       => {
        'Module::Build'      => '0.33',
	},
    requires => {
        'perl'                => '5.008001',	
#        'parent'              => '0.221',
#        'Exception::Class'    => '1.29',
    },
	build_requires => {
        'Test::More'          => '0.88',
	},
    meta_merge     => {
        resources => {
            homepage    => '{{$homepage}}',
            bugtracker  => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist={{$dist->name}}',
            repository  => '{{$repository}}'
        },
    },
    add_to_cleanup      => [ '{{$dist->name}}-*', ],
);

$builder->create_build_script();
