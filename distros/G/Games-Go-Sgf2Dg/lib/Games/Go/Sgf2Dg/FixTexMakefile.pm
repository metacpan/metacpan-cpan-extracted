#!/usr/bin/perl
#===============================================================================
#
#      PODNAME:  FixTexMakefile.pl
#     ABSTRACT:  modify the Makefile in the Games::Go:SGF2Tex/tex directory
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  10/26/2011 03:28:25 PM
#===============================================================================
#
#   This module is used only for finding TeX-related system
#   information during Sgf2Dg installation.

use 5.008;
use strict;
use warnings;

package Games::Go::Sgf2Dg::FixTexMakefile;

use POSIX;
use Config;
use File::Find;
use File::Slurp;
use ExtUtils::MakeMaker;    # for 'prompt' function

our $VERSION = '4.252'; # VERSION

my ($texmfRoot, $mfdir, $tfmdir, $texInputs, $kpsewhich, %pkFontHash, %wanted);
sub fix {
    # installing TeX stuff is a bit tricky - we don't know where it
    #   might be on this system.  try finding with 'kpsewhich' and 'locate':

    my $v;
    eval { $v = getVariables(); };      # try to find TEXMF variables
    if ($@) {
        print "\nUser Abort - TeX fonts and macros will not be installed during 'make install'.\n",
              "             However, you can still 'make install' for the rest of Sgf2Dg\n\n";
        exit(0);    # not an error
    }
    my $texmfRoot ='/usr/share/texmf';
    my $mfdir = "$texmfRoot/fonts/source/public/GOOE";
    my $tfmdir = "$texmfRoot/fonts/tfm/public/GOOE";
    my $texinputs = '/usr/share/texmf/tex/GOOE';
    my $pkfonts = join(' ', map { "$_/go*pk" } @{$v->{PKFONTS}});

    print "

Please check the variables below carefully.  They are currently
written into tex/Makefile, and will be used during 'make install'
as explained below.  You may edit tex/Makefile to make
corrections before you run 'make install'.\n";

    print "\n",
          "    MFDIR directory  : $v->{MFDIR}\n",
          "   TFMDIR directory  : $v->{TFMDIR}\n",
          "TEXINPUTS directory  : $v->{TEXINPUTS}\n",
          "  PKFONTS directories: ", join(",\n                       ",
                                        @{$v->{PKFONTS}}), "\n",
          ;
    print "
    MFDIR is where I will install the font files (tex/*.mf).
    TFMDIR is where I will install the font metric files
        (tex/*.tfm).
    TEXINPUTS is where I will install the TeX macro input files
        (tex/gooemacs.tex and tex/gotcmacs.tex).
    PKFONTS is where there might be old cached GOOE fonts (go*pk)
        that I will delete.\n\n";

    my $time = localtime;
    my $install = 'install -m 0644';
    my $mkdir   = 'mkdir';
    my $rm      = 'rm';
    my $rmdir   = 'rmdir';
    my $rm_rf   = 'rm -rf';
    if (($Config{osname} eq 'dos') or ($Config{osname} eq 'win32')) {     # bleh
        $install = 'copy';
        $mkdir   = 'md';
        $rm      = 'delete';
        $rmdir   = 'rd';
        $rm_rf   = 'deltree';
    }
    my $newText = "
# $time: 'perl Makefile.PL' determined the following install variables:

# where font (*.mf) files will go:
MFDIR = $v->{MFDIR}

# where font metric (*.tfm) files will go:
TFMDIR = $v->{TFMDIR}

# where TeX input files (gooemacs.tex and gotcmacs.tex) will go:
TEXINPUTS = $v->{TEXINPUTS}

# where cached fonts (GOOE/go*pk) might have been put (we need to
# remove cached fonts from previous installs):
PKFONTS = $pkfonts

# some command line command aliases
INSTALL = $install
MKDIR   = $mkdir
RM      = $rm
RMDIR   = $rmdir
RM_RF   = $rm_rf

";
    my $content = read_file('tex/Makefile');
    if ($content) {
        $content =~ s/^(\#\s*start\ perl\ Makefile.PL\ auto-edit[^\n]*\n)   # start marker
                    .*                                                      # stuff in between
                    ^(\#\s*end\ perl\ Makefile.PL\ auto-edit[^\n]*\n)       # end marker
                    /$1$newText$2/msx;
        write_file('tex/Makefile', $content);
    }
}

sub getVariables {

    get_TEXMF();        # try to find the TEXMF root directory
    myFind($texmfRoot); # build database of directory names below TEXMF root
    myFind('/var');     # add directories in /var
    get_PKFONTS();
    get_TEXINPUTS();
    get_MFDIR();
    get_TFMDIR();
    return { TEXMF => $texmfRoot,
             MFDIR => $mfdir,
             TFMDIR => $tfmdir,
             TEXINPUTS => $texInputs,
             PKFONTS => [keys(%pkFontHash)],
            };
}

sub get_TEXMF {

    print "try kpsewhich... ";
    `kpsewhich -expand-var \\\$TEXMF 2>/dev/null`; # try it
    $kpsewhich = WIFEXITED($?);     # normal exit?
    # $kpsewhich = 0;                 # prevent kpsewhich

    # try to find TEXMF root directory candidates
    my %tmfRootHash;
    kpsewhich_get(\%tmfRootHash, qw(TEXMF TEXMFLOCAL TEXMFMAIN VARTEXMF HOMETEXMF));
    locateRoot(\%tmfRootHash);      # try 'locate'
    foreach my $dir (keys(%tmfRootHash)) {
        delete($tmfRootHash{$dir}) if ($dir =~ m#^/var/#);    # /var should contain only variable stuff
    }
    print "\n";

    if (not keys(%tmfRootHash)) {
        print "\nHmmm, I can't find your root TEXMF directory.  I'll have to ask for\n",
              " your help.  You may find the INSTALL file has some useful hints.\n\n";
        $texmfRoot = enter_directory();
    }
    elsif (keys(%tmfRootHash) > 1) {
        print "Looks like the TEXMF root (install) directory is one of these:\n\n";
        $texmfRoot = selectDir(\%tmfRootHash);
    }
    else {
        $texmfRoot = (keys %tmfRootHash)[0]; # there's only one
    }
}


sub get_PKFONTS {
    # collect possible PKFONTS directories
    kpsewhich_get(\%pkFontHash, 'PKFONTS');       # get kpsewhich's idea of PKFONTS
    foreach my $dir (grep { m|$texmfRoot/.*\bGOOE$| } keys(%wanted)) {    # and do our own search as well
        $pkFontHash{$dir} = 'found';
    }
    foreach my $dir (grep { m|/texmf/.*\bpk/.*\bGOOE$| } keys(%wanted)) {  # and outside the root
        $pkFontHash{$dir} = 'found';
    }
    # remove PKFONTS directories that don't contain go*pk files
    foreach my $dir (keys(%pkFontHash)) {
        my @globs = glob("$dir/go*pk");
        delete ($pkFontHash{$dir}) unless (@globs > 0);
    }
}

sub get_TEXINPUTS {

    # collect possible TEXINPUTS directories
    my %texInputHash;
    kpsewhich_get(\%texInputHash, 'TEXINPUTS');   # get kpsewhich's idea of TEXINPUTS
    foreach my $dir (grep { m|$texmfRoot/tex$| } keys(%wanted)) {        # and do our own search as well
        $texInputHash{$dir} = 'found';
    }
    foreach my $dir (grep { m|/tex/.*\bGOOE$| } keys(%wanted)) {        # and do our own search as well
        $texInputHash{$dir} = 'found';
    }
    foreach my $dir (keys(%texInputHash)) {
        delete($texInputHash{$dir}) if ($dir =~ m#^/var/#);    # /var should contain only variable stuff
    }
    foreach my $dir (keys(%texInputHash)) {
        if ($dir =~ m#/GOOE\b#) {
            # if there are GOOEs already, those are the ones we want.
            # remove all the non-GOOE choices:
            foreach my $dir (keys(%texInputHash)) {
                if (not $dir =~ m#/GOOE\b#) {
                    delete $texInputHash{$dir};
                }
            }
            last;
        }
    }

    # if no TEXINPUT directories found, we have to ask for input
    if (not keys %texInputHash) {
        print "\nYour root TEXMF directory is $texmfRoot, but I can't find a TEXINPUTS\n",
              "  subdirectory under it.  Please see the INSTALL file for more information.\n",
              "\nPlease enter a directory for TEXINPUTS (it must already exist):\n\n";
        $texInputs = enter_directory();
    }
    elsif (keys %texInputHash > 1) {
        # multiple TEXINPUTS, ask user to select one
        print "Looks like the TEXINPUTS directory (for TeX macros) is one of these:\n\n";
        $texInputs = selectDir(\%texInputHash);
    } else {
        $texInputs = (keys %texInputHash)[0]; # there's only one
    }
}

sub get_MFDIR {

    # MFDIR is the path to the Metafont sources
    foreach my $dir ('fonts/source/public', 'fonts/source', '/metafont/misc') {
        if (-d "$texmfRoot/$dir") {
            $mfdir = "$texmfRoot/$dir";
            last;
        }
    }
    # if no mfdir directory yet, we have to ask for input
    unless(defined($mfdir)) {
        print "\nYour root TEXMF directory is $texmfRoot, but I can't find the right\n",
              "  place to put the font source (*.mf) files.\n",
              "\nPlease enter a directory for MFDIR, probably somewhere under $texmfRoot\n",
              "   (it must already exist, but I will add /GOOE to the end of what you enter):\n\n";
        $mfdir = enter_directory();
    }
    $mfdir =~ s#/GOOE$##;
    $mfdir .= '/GOOE';
}

sub get_TFMDIR {

    # TFMDIR is the path to the .tfm files.
    foreach my $dir ('fonts/tfm/public', 'fonts/tfm') {
        if (-d "$texmfRoot/$dir") {
            $tfmdir = "$texmfRoot/$dir";
            last;
        }
    }
    # if no mfdir directory yet, we have to ask for input
    unless(defined($tfmdir)) {
        print "\nYour root TEXMF directory is $texmfRoot, but I can't find the right\n",
              "  place to put the font metric (*.tfm) files.\n",
              "\nPlease enter a directory for TMFDIR, probably somewhere under $texmfRoot\n",
              "   (it must already exist, but I will add /GOOE to the end of what you enter):\n\n";
        $tfmdir = enter_directory();
    }
    $tfmdir =~ s#/GOOE$##;
    $tfmdir .= '/GOOE';
}

sub wanted {
    $wanted{$_} = 'wanted' if (-d $_);
}

sub myFind {
    my ($root) = @_;

    local $| = 1;   # make stdout unbuffered
    print "Scanning filesystem from $root...";
    no warnings;
    File::Find::find({wanted => \&wanted,
                      follow_fast => 1,
                      follow_skip => 2,
                      no_chdir => 1},
                      $root);
    print "done\n";
}

sub locateRoot {
    my $hash = shift;

    print "try locate...";
    my @locate = `locate texmf`;
    unless (WIFEXITED($?)) {
        # print "\$?=$?\n";
        return 0;
    }
    map( { m#(.*/texmf)/?$#             # everything with '/texmf' or '/texmf/' at the end
             and not $hash->{$1}        # if it's not already set
             and $hash->{$1} = 'locate'; } @locate);    # set it
    return 1;
}


sub kpsewhich_get {
    my $hash = shift;

    return unless($kpsewhich);
    foreach my $dir (@_) {
        my $str = `kpsewhich -expand-var \\\$$dir 2>/dev/null`;
        chomp $str;
        $str = `kpsewhich --expand-braces "$str"`;
        chomp $str;
        $str =~ s#//*#/#g;          # turn multiple // into /
        $str =~ s/([:^])!!/$1/g;    # eleminate prepended !!
        my @a = split(':', $str);
        foreach my $name (grep( { $_ ne '.' and -d $_} @a)) {
            $name =~ s#/*$##;   # remove any trailing slashes
            $hash->{$name} = 'kpsewhich';
        }
    }
}

sub selectDir {
    my ($dir_hash) = @_;

    my ($ii, $rsp);
    $ii = 1;
    my @dirs = sort keys %$dir_hash;
    do {
        for my $dir (@dirs) {
            print "    $ii. $dir ($dir_hash->{$dir})\n";
            $ii++;
        }
        print "    $ii. Select a different directory\n";
        print "    q. Quit\n";
        $rsp = ExtUtils::MakeMaker::prompt("\nPlease select one: ", 'q');
        chomp $rsp;
        die ("Quitting...\n") if (not $rsp or lc($rsp) eq 'q');
    } while(not $rsp or
            $rsp =~ m/\D/ or
            $rsp > $ii);
    if ($rsp == $ii) {
        return(enter_directory());
    }
    return $dirs[$rsp - 1];
}

sub enter_directory {

    my $rsp;
    do {
        $rsp = ExtUtils::MakeMaker::prompt("\nPlease enter directory name (or 'q' to quit): ", 'q');
        chomp $rsp;
        die ("Quitting...\n") if ((lc($rsp) eq 'q') or
                                  (lc($rsp) eq ''));
        unless (-d $rsp) {
            print "\n$rsp is not a directory"
        }
    } while(not defined($rsp) or
            (not -d $rsp));
    return $rsp;
}

1;
