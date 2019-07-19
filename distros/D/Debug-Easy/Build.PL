use strict;
use Module::Build;
use Config;

my $build = Module::Build->new(
    'module_name'    => 'Debug::Easy',
    'license'        => 'perl',
    'configure_requires' => {
        'Module::Build' => '>= 0'
    },
    'requires'       => {
        'perl'            => '5.008',
        'Time::HiRes'     => '>= 1.9715',
        'Term::ANSIColor' => '>= 4.00',
        'DateTime'        => '>= 1.18',
        'File::Basename'  => '>= 0',
        'Data::Dumper'    => '>= 0',
    },
    'build_requires' => {
        'Test::More' => '> 0.44'
    },
    'dist'           => {
        'COMPRESS' => 'gzip -9f',
        'SUFFIX'   => 'gz'
    },
    'clean'          => {
        'FILES' => 'Debug-Easy-*'
    }
);

print "\nIs this a threaded Perl? ...";
if ($Config{'useithreads'}) {
    print "YES, good, no changes neeed be done\n\n";
} else {
    print "NO, changes needed\nRemoving threading features ... ";
    my $module = slurp_file('lib/Debug/Easy.pm');
    $module =~ s/use threads;//;
    open(my $FILE,'>','lib/Debug/Easy.pm');
    print $FILE $module;
    close($FILE);
    print "COMPLETE\n\n";
}

$build->create_build_script();

sub slurp_file {
    my $file = shift;

    return (
        do { local (@ARGV, $/) = $file; <> }
    );
}
