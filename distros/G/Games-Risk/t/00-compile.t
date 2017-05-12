use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.039

use Test::More  tests => 35 + ($ENV{AUTHOR_TESTING} ? 1 : 0);



my @module_files = (
    'Games/Risk.pm',
    'Games/Risk/AI.pm',
    'Games/Risk/AI/Blitzkrieg.pm',
    'Games/Risk/AI/Dumb.pm',
    'Games/Risk/AI/Hegemon.pm',
    'Games/Risk/App.pm',
    'Games/Risk/App/Command.pm',
    'Games/Risk/App/Command/import.pm',
    'Games/Risk/App/Command/play.pm',
    'Games/Risk/Card.pm',
    'Games/Risk/Config.pm',
    'Games/Risk/Continent.pm',
    'Games/Risk/Controller.pm',
    'Games/Risk/Country.pm',
    'Games/Risk/Deck.pm',
    'Games/Risk/ExtraMaps.pm',
    'Games/Risk/GUI.pm',
    'Games/Risk/GUI/MoveArmies.pm',
    'Games/Risk/GUI/Startup.pm',
    'Games/Risk/I18n.pm',
    'Games/Risk/Logger.pm',
    'Games/Risk/Map.pm',
    'Games/Risk/Map/Risk.pm',
    'Games/Risk/Player.pm',
    'Games/Risk/Point.pm',
    'Games/Risk/Resources.pm',
    'Games/Risk/Tk/About.pm',
    'Games/Risk/Tk/Cards.pm',
    'Games/Risk/Tk/Continents.pm',
    'Games/Risk/Tk/GameOver.pm',
    'Games/Risk/Tk/Help.pm',
    'Games/Risk/Tk/Main.pm',
    'Games/Risk/Types.pm',
    'Games/Risk/Utils.pm'
);

my @scripts = (
    'bin/prisk'
);

# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;
    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!.*?\bperl\b\s*(.*)$/;

    my @flags = $1 ? split(/\s+/, $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

   # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found') if $ENV{AUTHOR_TESTING};


