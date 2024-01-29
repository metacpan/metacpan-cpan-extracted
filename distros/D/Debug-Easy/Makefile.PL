use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use Config;

print q{
[0m[31m ____       _                     [32m_____[37m
[31m|  _ \  ___| |__[37m  [31m_   _  __ _[37m _ _[32m| ____|__ _ ___ _   _
[31m| | | |/ _ \ '_ \| | | |/[37m [31m_`[37m (_|_)  [32m_| / _` / __| | | |
[31m| |_| |  __/[37m [31m|_) | |_| | (_| [37m|_ _| [32m|__| (_| \__ \ |_| |
[31m|____/ \___|_.__/ \__,_|\__, [37m(_|_)[32m_____\__,_|___/\__, |
[37m                        [31m|___/[37m                    [32m|___/
[37m                     [1;33m____    _ _____
[0m            __   __ [1;33m|___ \  / |___ /
[0m            \ \ / /   [1;33m__) | | | |_ \
[0m             \ V /   [1;33m/[0m [1;33m__/ _| |___)[0m [1;33m|[0m
              \_/   [1;33m|_____(_)_|____/
[0m
};
print "\nIs this a threaded Perl? ...";
if ($Config{'useithreads'}) {
    print "YES, good no changes needed\n\n";
} else {
    print "NO, changes required\nRemoving threading features ... ";
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
        AUTHOR             => q{Richard Kelsch <rkelsch@cpan.org>},
        VERSION_FROM       => 'lib/Debug/Easy.pm',
        ABSTRACT_FROM      => 'lib/Debug/Easy.pm',
        PL_FILES           => {},
        MIN_PERL_VERSION   => 5.008000,
        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => 0,
			'Config'              => 0,
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
    exit(0);
} ## end if (WriteMakefile(NAME...))

exit(1);

sub slurp_file {
    my $file = shift;

    # Read in a text file without using open
    return (
        do { local (@ARGV, $/) = $file; <> }
    );
} ## end sub slurp_file
