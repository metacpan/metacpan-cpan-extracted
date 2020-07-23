use strict;
use warnings;

use Test::More;
use File::Path;
use File::Temp qw[tempdir];

use FindBin;
use Cwd qw(getcwd);

my $tmpdir = tempdir( CLEANUP => 1 );
my $cwd = getcwd();
END { chdir $cwd if defined $cwd }    # so File::Temp can cleanup

eval {
  chdir $tmpdir;

  { # generate Makefile.PL
    open my $fh, '>', "Makefile.PL" or die;
    print $fh <<'MK_END';
      use strict;
      use warnings;

      use lib "";

      use ExtUtils::MakeMaker::PPPort;
      print "# EUMM version: ", $ExtUtils::MakeMaker::VERSION, "\n";
      WriteMakefile(
        NAME => 'Test::EUMM::PPPort',
        AUTHOR => 'Test',
        # The following should not let EUMM warn even if it's old
        LICENSE => 'perl',
        MIN_PERL_VERSION => '5.008001', # Lancaster consensus
        META_ADD => {},
        META_MERGE => {},
        CONFIGURE_REQUIRES => {},
        BUILD_REQUIRES => {},
        TEST_REQUIRES => {},
      );
MK_END
  }

  if ( "$]" > 5.010 ) {
    eval q[     
      local $/; 
      open my $fh, '<', "Makefile.PL"; 
      note "Makefile.PL:\n", <$fh>;
      1
    ] or diag $@;
  }

  { # generate .pm file
    open my $fh, '>', "Test.pm" or die;
    print $fh "package #\n", "Test::EUMM::PPPort;\n", "1;\n";
  }

};

plan skip_all => "failed to set up a test distribution" if $@;

ok !system($^X, '-I../lib', "Makefile.PL"), "ran Makefile.PL";
ok -f "Makefile", "generated Makefile";

my $makefile = do { local $/; open my $fh, '<', "Makefile"; <$fh> };

die unless defined $makefile;

like $makefile, qr{^\.PHONY: ppport ppport_version ppport_clean}m, 'PHONY';
like $makefile, qr{^ppport\s*:}m, 'ppport target';
like $makefile, qr{^ppport_version\s*:}m, 'ppport_version target';
like $makefile, qr{^ppport_clean\s*:}m, 'ppport_clean target';
like $makefile, qr{^ppport\.h\s*:}m, 'ppport.h target';

like $makefile, qr{^clean\ss*::\s*ppport_clean}m, 'ppport_clean added to clean target';
like $makefile, qr{^pure_all\ss*::\s*ppport}m, 'ppport added to pure_all target';
like $makefile, qr{^dynamic\ss*::\s*ppport}m, 'ppport added to dynamic target';

SKIP: {
  qx{which make};
  skip "cannot find a make for testing ppport.h", 3 unless $? == 0;

  ok !-e 'ppport.h', "no ppport.h";
  qx{make ppport.h};
  ok -e 'ppport.h', 'ppport.h was generated';
  open( my $fh, '<', 'ppport.h' ) or die;
  my $content;
  {
    local $/;
    $content = <$fh>
  }
  like $content, qr{_P_P_PORTABILITY_H_}, "ppport.h contains _P_P_PORTABILITY_H_";
}

done_testing;

