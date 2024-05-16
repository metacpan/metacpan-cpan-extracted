#!perl
require 5.006;
use ExtUtils::MakeMaker;

use File::Spec;

use strict;
use warnings;

use lib 'lib';

# one of these is not like the other
# this is really a sanity check that loading bogus modules doesn't Fuck Shit Up
use Devel::CheckOS;
my @dont_care = Devel::CheckOS::list_family_members('Unix');
   @dont_care = Devel::CheckOS::list_family_members('MicrosoftWindows');

my(@OSes, @notOSes) = ();
if($ENV{AUTOMATED_TESTING}) {
    print "I will now ask you some questions to make sure I've detected your\n";
    print "system correctly.  Most platforms will be detected several times.\n";
    print "This is deliberate.  To see an explanation of some of the more\n";
    print "obscure options, hit the question mark key.\n\n";
    findOSes(File::Spec->catdir(qw(lib Devel AssertOS)));
    opendir(T, 't');
    unlink File::Spec->catfile('t', $_) foreach(grep { /^XX/ } readdir(T));
    close(T);

    if(@notOSes) { # user told us we got it wrong
        foreach my $os (@notOSes) {
            (my $filename_os = $os) =~ s/::/-/g;
            my $test_file = File::Spec->catfile('t', "XX-autodetected-$^O-as-$filename_os.t");
            open(my $fh, '>', $test_file) || die("Couldn't write ".$test_file.": $!\n");
            print $fh 'print "1..1\\nnot ok 1\\n"';
            close($fh);
        }
    }
    if(!@notOSes && !@OSes) { # didn't detect anything!
        my $test_file = File::Spec->catfile('t', "XX-autodetected-$^O-as-nothing.t");
        open(my $fh, '>', $test_file) || die("Couldn't write ".$test_file.": $!\n");
        print $fh 'print "1..1\\nnot ok 1\\n"';
        close($fh);
    }
    if(@OSes) {
        foreach my $os (@OSes) {
            (my $filename_os = $os) =~ s/::/-/g;
            my $test_file = File::Spec->catfile('t', "XX-autodetected-$^O-as-$filename_os.t");
            open(my $fh, '>', $test_file) || die("Couldn't write ".$test_file.": $!\n");
            print $fh qq{
                use Devel::AssertOS::$os;
                print "1..1\\n";print "ok 1\\n";
            };
            close($fh);
        }
    }
}

WriteMakefile(
    NAME         => 'Devel::CheckOS',
    META_MERGE => {
        license => ["artistic_1", "artistic_2"],
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Devel-CheckOS',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Devel-CheckOS/issues'
        },
    },
    LICENSE      => "gpl_2",
    MIN_PERL_VERSION => "5.6.0",
    VERSION_FROM => 'lib/Devel/CheckOS.pm',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.64, # TEST_REQUIRES (CONFIGURE_REQUIRES is in 6.52; BUILD_REQUIRES in 6.56)
    },
    PREREQ_PM    => {
        'File::Find::Rule' => 0.28,
        'File::Temp'       => 0.19,
        'Test::More'       => 0.88, # done_testing
        'Test::Warnings'   => 0,    # listed here as well as in TEST_REQUIRES in case we've got a Ye Olde Toolchaine
                                    # and not even the CONFIGURE_REQUIRES above is understood
    },
    TEST_REQUIRES => {
        'Test::More'       => 0.88,
        'Test::Warnings'   => 0,
    },
    EXE_FILES    => [qw(
        bin/use-devel-assertos
    )],
    clean         => { FILES => 't/XX*' }
);

sub findOSes {
    my $dir = shift;
    opendir(LIBS, $dir) ||
    die("Can't read $dir. Your distribution is broken\n");
    my @dirents = File::Spec->no_upwards(readdir(LIBS));
    closedir(LIBS);
    foreach (grep { -d File::Spec->catdir($dir, $_) } @dirents) {
        findOSes(File::Spec->catdir($dir, $_));
    }
    foreach (map { s/\.pm$//; $_ } grep { /\.pm$/ } @dirents) {
        my $modname = join('::', File::Spec->splitdir($dir), $_);
        (my $classname = $modname) =~ s/^lib:://;
        (my $prompt_modname = $modname) =~ s/.*AssertOS:://;
        if (!eval "use $classname; ${classname}::os_is()") {
            next;
        }
        my $hasexpn = $classname->can('expn') ? '/?' : '';
   ASK: my $answer = prompt(
            "Are you using $prompt_modname? [Y/n$hasexpn]",
            "Y"
        );
        if($answer =~ /^y/i) {
            push @OSes, $prompt_modname;
        } elsif($answer =~ /^\?/) {
            if($hasexpn) {
                print "\n".$classname->expn()."\n\n";
            } else {
                print "\nYou need help for that!?!?\n\n";
            }
            goto ASK;
        } else {
            push @notOSes, $prompt_modname;
        }
    }
}
