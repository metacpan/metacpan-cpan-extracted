#!/usr/bin/perl
#===============================================================================
#
#  DESCRIPTION:  Modify Makefile.PL after Dist::Zilla is finished
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/28/2011 03:40:36 PM
#===============================================================================

use strict;
use warnings;
use File::Slurp;
use File::Spec;

my $dir = $ARGV[0] or die "Need build directory";

fix_makefile($dir);
fix_Sgf2Dg($dir);
exit 0;

sub fix_makefile {
    my ($dir) = @_;
    my $filename = File::Spec->catfile($dir, 'Makefile.PL');

    my $content = read_file($filename);

    my $add = q{
use Config;
use File::Slurp;
use lib 'lib';        # to find FixTeXMakefile.pm
use Games::Go::Sgf2Dg::FixTexMakefile;

eval { require PDF::Create; };   # is this module available?
if ($@) {
    print "\nPDF::Create not available\n",
          "  I'll install Games::Go::Sgf2Dg, but the PDF converter (Dg2PDF) needs PDF::Create.\n",
          "  You can find PDF::Create in the same repository where you found\n",
          "  Games::Go::Sgf2Dg, or from http://search.cpan.org/\n\n";

} else {
    my $v = ($PDF::Create::VERSION =~ m/(^\d*\.\d*)/)[0];
    if (not defined($v)) {
        print("\n\n  Hmm, can't extract package version from \$PDF::Create::VERSION.\n" .
                  "  There may be a more recent version at:\n\n" .
                  "      http://www.sourceforge.net/projects/perl-pdf.\n\n");
    } elsif ($v < 0.06) {
        print("\n\n  Note: your PDF::Create package is version $v.\n" .
                  "  You might want to pick up a more recent version from:\n\n" .
                  "      http://www.sourceforge.net/projects/perl-pdf.\n\n");
    }
}

eval { require PostScript::File; };   # is this module available?
if ($@) {
    print "\nPostScript::File not available\n",
          "  I'll install Games::Go::Sgf2Dg, but the PostScript converter (Dg2Ps) needs\n",
          "  PostScript::File.\n",
          "  You can find PostScript::File in the same repository where you found\n",
          "  Games::Go::Sgf2Dg, or from http://search.cpan.org/\n\n";

}

my %makeMakerOpts = (
    EXE_FILES   => [ 'bin/sgf2dg' ],
    MAN1PODS    => { 'bin/sgf2dg' => "\$(INST_MAN1DIR)/sgf2dg.1" },
);

if (($Config{osname} eq 'dos') or ($Config{osname} eq 'win32')) {     # punt
    print "\nI'm sorry, but since this is a DOS platform, if you need sgfsplit, you'll\n",
          "  need to compile it yourself.  If you've got all the right tools, you may\n",
          "  be able to type 'make sgfsplit.exe'.\n\n";
} else {
    push @{$makeMakerOpts{EXE_FILES}}, 'sgfsplit';
    $makeMakerOpts{OBJECT} = ('sgfsplit.o');
    $makeMakerOpts{MAN1PODS}{'sgfsplit.c'} = '$(INST_MAN1DIR)/sgfsplit.1';
}
};

    # insert all that stuff above near the top of Makefile.PL
    $content =~ s/^(use ExtUtils::MakeMaker[^\n]*)/$1\n$add/sm;

    # replace EXE_FILES option with %makeMakerOpts
    $content =~ s/^(\s*)"EXE_FILES"[^\]]*]/$1%makeMakerOpts/sm;

    # tack this onto the end of Makefile.PL
    $content .= q{
# no dynamic targets for this package:
sub MY::dynamic {
    return '';
}

# add install_tex and fonts rules in the postamble
sub MY::postamble {
    return q{

# how to make a manual.tex file into a manual.dvi
manual.dvi : manual.tex
	tex $<

# how to install tex portion of Sgf2Dg
install_tex : 
	cd tex; ${MAKE} install

# how to make fonts
fonts :
	cd tex; ${MAKE} fonts
};

}

# modify the Makefile slightly
my $content = read_file('Makefile');

# add install_tex target to install tex subdirectory
$content =~ s/^(install\b[^\n]*)/$1 install_tex manual.dvi/m;

# remove all references to after_build.pl
$content =~ s/\S*after_build.pl//g;

# remove all references to FixTexMakefile.pm
$content =~ s/\S*FixTexMakefile.pm//g;

write_file('Makefile', $content);

# Find TeX stuff on the system and modify tex/Makefile accordingly
Games::Go::Sgf2Dg::FixTexMakefile::fix();
};

    # write modified content back out to Makefile.PL
    write_file($filename, $content);
}

# Sgf2Dg.pm needs a valid $VERSION as well as the # VERSION
# line for Dist::Zilla::Plugin::OurPkgVersion.  After dzil
# build, it ends up with two $VERSION definitions.  Delete
# the extra one here
sub fix_Sgf2Dg {
    my ($dir) = @_;
    my $filename = File::Spec->catfile($dir, 'lib', 'Games', 'Go', 'Sgf2Dg.pm');

    my $content = read_file($filename);

    $content =~ s/^[^\n]*delete this line after build[^\n]*\n//g;

    write_file($filename, $content);
}


