use strict;
use warnings;
use Module::Build;

# If you updated this file, don't forget to update the Makefile.PL file as well!

my $builder = Module::Build->new(
    module_name         => 'Getopt::Euclid',
    dist_author         => 'Damian Conway <DCONWAY@cpan.org>',
    license             => 'perl',
    dist_version_from   => 'lib/Getopt/Euclid.pm',

    build_requires      => {
        'Test::More'            => 0,
        'Pod::Checker'          => 0,
    },

    requires            => {
        'version'               => 0,
        'Pod::Select'           => 0,
        'Pod::PlainText'        => 0,
        'File::Basename'        => 0,
        'File::Spec::Functions' => 0,
        'List::Util'            => 0,
        'Text::Balanced'        => 0,
    },

    recommends          => {
        'IO::Pager::Page'       => 0,
    },

    add_to_cleanup      => [ 'Getopt-Euclid-*' ],
);

$builder->create_build_script();

if ( -e 'MANIFEST.SKIP' ) {
   generate_readme( 'lib/Getopt/Euclid.pm', 'README' ); 
}



sub generate_readme {
   my ($in, $out) = @_;
   `pod2text $in $out`;
   warn "Warning: Could not generate $out.\n$!\n" if $? == -1;
   return $?; # exit status
}
