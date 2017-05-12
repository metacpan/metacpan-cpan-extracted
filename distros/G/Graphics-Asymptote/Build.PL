use strict;
use warnings;
use Module::Build;
use File::Temp qw( tempfile );

my $builder = Module::Build->new(
    module_name         => 'Graphics::Asymptote',
    license             => 'perl',
    dist_author         => 'David Mertens <dcmertens.perl+Asymptote@gmail.com>',
    dist_version_from   => 'lib/Graphics/Asymptote.pm',
    requires => {
        'Test::More'  => 0,
        'version'     => 0,
		'Time::HiRes' => 0,
		'perl'        => 5.010000,
    },
    recommends => {
	    'PDL'     => 0,
    },
	
    add_to_cleanup      => [ 'Graphics-Asymptote-*' ],
);

# Check that asy is in the execution path by running asy on an empty file
my ($empty_file, $empty_file_name) = tempfile(UNLINK => 1);
unless (system('asy', $empty_file_name) == 0) {
    print "Could not locate the asymptote interpreter in the path\n";
    exit 0;
}

$builder->create_build_script();
