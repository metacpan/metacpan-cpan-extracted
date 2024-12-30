use 5.006;
use Module::Build();

if ( $ENV{PERL_USE_UNSAFE_INC} ) { 
    warn <<'UNSAFE'; 
PERL_USE_UNSAFE_INC not needed for Build and test
UNSAFE
    warn << 'DEV' if -d q(.git);
Set PERL_USE_UNSAFE_INC=0 for development
DEV
}

my $build = Module::Build->new(
    module_name        => 'File::Copy::Link',
    license            => 'perl',
    requires           => { File::Spec => 0, File::Copy => 0, perl => 5.006 },
    recommends         => { Cwd => 2.18, },
    script_files       => [qw(bin/copylink)],
    dist_author        => 'Robin Barker <rmbarker@cpan.org>',
    test_requires      => { Test::More => 0, File::Temp => 0 },
    configure_requires => { 'Module::Build' => 0.40 },
    create_makefile_pl => 'traditional',
);

{
    local $SIG{__WARN__} = sub {
        return if $_[0] =~ m{
		\A
		WARNING\:\ the\ following\ files\ are\ missing\ in\ your\ kit\:
		(\s+ (Makefile\.PL | META\.\S+) )+
		\s+ Please\ inform\ the\ author\.
		\s+ \z
	}msx;
        warn $_[0];
        return;
    };
    $build->create_build_script;
}

# $Id$

