use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;
use Term::ANSIColor;

print colored(['bright_yellow'],q{
  _____       _                     ______                  ___   __ _____
 |  __ \     | |                _ _|  ____|                |__ \ /_ | ____|
 | |  | | ___| |__  _   _  __ _(_|_) |__   __ _ ___ _   _     ) | | | |__
 | |  | |/ _ \ '_ \| | | |/ _` |   |  __| / _` / __| | | |   / /  | |___ \
 | |__| |  __/ |_) | |_| | (_| |_ _| |___| (_| \__ \ |_| |  / /_ _| |___) |
 |_____/ \___|_.__/ \__,_|\__, (_|_)______\__,_|___/\__, | |____(_)_|____/
                           __/ |                     __/ |
                          |___/                     |___/
});
print "\nIs this a threaded Perl? ...";
if ($Config{'useithreads'}) {
    print colored(['green'],'YES'), ", good no changes needed\n\n";
} else {
    print colored(['red'],'NO'), ", changes required\nRemoving threading features ... ";
    my $module = slurp_file('lib/Debug/Easy.pm');
    $module =~ s/use threads;//;

    open(my $FILE, '>', 'lib/Debug/Easy.pm');
    print $FILE $module;
    close($FILE);
    print "COMPLETE\n\n";
} ## end else [ if ($Config{'useithreads'...})]

if (
    WriteMakefile(
        NAME               => 'Debug::Easy',
        AUTHOR             => q{Richard Kelsch <rich@rk-internet.com>},
        VERSION_FROM       => 'lib/Debug/Easy.pm',
        ABSTRACT_FROM      => 'lib/Debug/Easy.pm',
        PL_FILES           => {},
        MIN_PERL_VERSION   => 5.008000,
        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => 0,
			'Config'              => 0,
            'Term::ANSIColor'     => 0,
        },
        BUILD_REQUIRES => {
            'Test::More' => 0.44,
        },
        PREREQ_PRINT => 1,
        PREREQ_PM    => {
            'Time::HiRes'     => 0,
            'Term::ANSIColor' => 0,
            'DateTime'        => 0,
            'File::Basename'  => 0,
            'Data::Dumper'    => 0,
        },
        dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
        clean => { FILES    => 'Debug-Easy-* _build*' },
    )
) {
    print "\nConfiguration of Debug::Easy ", colored(['green'],'Successful'), "\n\n";
    exit(0);
} ## end if (WriteMakefile(NAME...))

print "\nConfiguration of Debug::Easy ", colored(['red'],'Failed'), "\n\n";
exit(1);

sub slurp_file {
    my $file = shift;

    # Read in a text file without using open
    return (
        do { local (@ARGV, $/) = $file; <> }
    );
} ## end sub slurp_file
