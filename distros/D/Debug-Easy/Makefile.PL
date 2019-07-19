use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;

print "\nIs this a threaded Perl? ...";
if ($Config{'useithreads'}) {
    print "YES, good no changes needed\n\n";
} else {
    print "NO, changes required\nRemoving threading features ... ";
    my $module = slurp_file('lib/Debug/Easy.pm');
    $module =~ s/use threads;//;

    open(my $FILE,'>','lib/Debug/Easy.pm');
    print $FILE $module;
    close($FILE);
    print "COMPLETE\n\n";
}

if (WriteMakefile(
    NAME               => 'Debug::Easy',
    AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
    VERSION_FROM       => 'lib/Debug/Easy.pm',
    ABSTRACT_FROM      => 'lib/Debug/Easy.pm',
    PL_FILES           => {},
    MIN_PERL_VERSION   => 5.006001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'  => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.44,
    },
    PREREQ_PM      => {
        'Time::HiRes'     => 1.9715,
        'Term::ANSIColor' => 4.00,
        'DateTime'        => 1.18,
        'File::Basename'  => 0,
        'Data::Dumper'    => 0,
    },
    dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
    clean => {FILES    => 'Debug-Easy-* _build*'},
)) {
    exit(0);
}

exit(1);

sub slurp_file {
    my $file = shift;

    # Read in a text file without using open
    return (
        do { local (@ARGV, $/) = $file; <> }
    );
}

