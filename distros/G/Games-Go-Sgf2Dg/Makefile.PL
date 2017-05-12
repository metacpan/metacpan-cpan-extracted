
use strict;
use warnings;

use 5.008;

use ExtUtils::MakeMaker 6.30;

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




my %WriteMakefileArgs = (
  "ABSTRACT" => "Sgf2Dg.pm",
  "AUTHOR" => "Reid Augustin <reid\@hellosix.com>",
  "BUILD_REQUIRES" => {
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Games-Go-Sgf2Dg",
  %makeMakerOpts,
  "LICENSE" => "perl",
  "NAME" => "Games::Go::Sgf2Dg",
  "PREREQ_PM" => {
    "Carp" => 0,
    "Config" => 0,
    "Exporter" => 0,
    "ExtUtils::MakeMaker" => 0,
    "File::Find" => 0,
    "File::Slurp" => 0,
    "File::Spec" => 0,
    "IO::File" => 0,
    "PDF::Create" => 0,
    "POSIX" => 0,
    "PostScript::File" => 0,
    "Tk" => 0,
    "Tk::Canvas" => 0,
    "Tk::NoteBook" => 0,
    "constant" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.252",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




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
