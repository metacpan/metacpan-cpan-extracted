require 5.006;
use ExtUtils::MakeMaker;

use File::Spec;

use strict;
use warnings;

use lib 'lib';

# one of these is not like the other
# this is really a sanity check that loading bogus modules doesn't Fuck Shit Up
use Devel::CheckOS;
Devel::CheckOS::list_family_members('Unix');
Devel::CheckOS::list_family_members('MicrosoftWindows');

my(@OSes, @notOSes, @extrafiles) = ();
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
        push @extrafiles, File::Spec->catfile('t', "XX-autodetected-$^O-as-".join('--', map { s/::/-/g; $_ } @notOSes).".t");
        open(FAIL, '>'.$extrafiles[-1]) ||
            die("Coulsn't write ".$extrafiles[-1].": $!\n");
        print FAIL 'print "1..1\\n";print "not ok 1\\n"';
        close(FAIL);
    } elsif(!@OSes && $ENV{AUTOMATED_TESTING}) { # didn't detect anything!
        push @extrafiles, File::Spec->catfile('t', "XX-autodetected-$^O-as-nothing.t");
        open(FAIL, '>'.$extrafiles[-1]);
        print FAIL 'print "1..1\\n";print "not ok 1\\n"';
        close(FAIL);
    } elsif(@OSes) {
        foreach my $os (@OSes) {
            (my $filename_os = $os) =~ s/::/-/g;
            push @extrafiles, File::Spec->catfile('t', "XX-autodetected-$^O-as-$filename_os.t");
            open(PASS, '>'.$extrafiles[-1]);
            print PASS qq{
                use Devel::AssertOS::$os;
                print "1..1\\n";print "ok 1\\n";
            };
            close(PASS);
        }
    }
}

WriteMakefile(
    NAME         => 'Devel::CheckOS',
    META_MERGE => {
        license => 'open_source',
        resources => {
            repository => 'https://github.com/DrHyde/perl-modules-Devel-CheckOS',
            bugtracker => 'https://github.com/DrHyde/perl-modules-Devel-CheckOS/issues'
        },
    },
    MIN_PERL_VERSION => "5.6.0",
    # FIXME have this look at all the modules, or summat
    VERSION_FROM => 'lib/Devel/CheckOS.pm',
    PREREQ_PM    => {
        'Test::More'       => '0.88', # done_testing
        'File::Find::Rule' => 0.28,
        'File::Temp'       => 0.19,
        'Data::Compare'    => 1.21,
        # 'Exporter' => 0 # core
    },
    EXE_FILES    => [qw(
        bin/use-devel-assertos
    )],
    clean         => { FILES => join(' ', @extrafiles) }
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
        eval "use $classname";
        next if($@);
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
            print "Eek!\n";
            push @notOSes, $prompt_modname;
        }
    }
}
