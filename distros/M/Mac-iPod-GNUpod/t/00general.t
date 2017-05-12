#!/usr/bin/perl

# Test script for general tasks

#use warnings; # Testing
no warnings;  # Production
use Test::More tests => 24;
use File::Spec; # tests must also be file-system independent

# Use
BEGIN {
    use_ok 'Mac::iPod::GNUpod';
}

my $fakepod = File::Spec->catdir('t', 'fakepod');
my $ipdb = File::Spec->catfile($fakepod, 'iPod_Control', 'iTunes', 'iTunesDB');
my $gpdb = File::Spec->catfile($fakepod, 'iPod_Control', '.gnupod', 'GNUtunesDB');
mkdir $fakepod;

# Constructor, style 1
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);
    ok $ipod, 'Init giving mountpoint';

    ok(($ipod->mountpoint eq $fakepod), 'Location of mountpoint');
    ok(($ipod->itunes_db eq $ipdb), 'Location of iTunesDB');
    ok(($ipod->gnupod_db eq $gpdb), 'Location of GNUpodDB');
}

# Constructor, style 2
{
    my $ipod = Mac::iPod::GNUpod->new(
        itunes_db => $ipdb,
        gnupod_db => $gpdb
    );
    ok $ipod, 'Init giving iTunes and GNUpod';

    ok((not $ipod->mountpoint), 'Mountpoint unset');
    ok(($ipod->itunes_db eq $ipdb), "Location of iTunesDB");
    ok(($ipod->gnupod_db eq $gpdb), "Location of GNUpodDB");
}

# Test flags and other get/sets
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);

    # Test defaults
    my %expect = (
        mountpoint => $fakepod,
        itunes_db  => $ipdb,
        gnupod_db  => $gpdb,
        allow_dup  => 0,
        move_files => 1
    );

    for (keys %expect) {
        ok(($ipod->$_ eq $expect{$_}), "Got correct default for $_");

        $ipod->$_('foo');
        ok(($ipod->$_ eq 'foo'), "Set $_");
    }
}

# Test init()
{
    my $ipod = Mac::iPod::GNUpod->new(mountpoint => $fakepod);

    # Nuke that mofo
    my @list;
    push @list, glob(File::Spec->catfile($fakepod, '*', '*', '*'));
    push @list, glob(File::Spec->catfile($fakepod, '*', '*'));
    push @list, glob(File::Spec->catfile($fakepod, '*'));
    for(@list) {
        if (-d) { rmdir; }
        else { unlink; }
    }

    ok $ipod->init, 'Init successful';

    # Check directories
    my $prob;
    for ('Calendars', 'Contacts', 'Notes', 'iPod_Control', File::Spec->catdir('iPod_Control', 'Device'), File::Spec->catdir('iPod_Control', 'Music'), File::Spec->catdir('iPod_Control', 'iTunes'), File::Spec->catdir('iPod_Control', '.gnupod')) {
        $prob = $_ unless -e File::Spec->catdir($fakepod, $_);
        last if $prob;
    }
    ok((not $prob), "Directory structure check (problem with " . ($prob || 'none') . ')');

    # Check music directories
    undef $prob;
    for (0 .. 19) {
        $prob = $_ unless -e File::Spec->catdir($fakepod, 'iPod_Control', 'Music', 'f'.sprintf('%02d', $_));
        last if $prob;
    }
    ok((not $prob), "Music directory check (problem with " . ($prob || 'none') . ')');

    # Check db files
    ok((-e $ipod->gnupod_db), 'GNUpodDB exists');
    ok((-e $ipod->itunes_db), 'iTunesDB exists');
}

# Test restore()
# Actually not, since I can't think of any lightweight way to do it for now.

