# check version of Perl
BEGIN {
  eval { require v5.6.1; }
    or die <<EOD;
###############################################################################
###
### This module requires Perl 5.6.1 or later.  Please upgrade your Perl.
###
###############################################################################
EOD
}

use ExtUtils::MakeMaker;
use File::Copy;
use strict;
use warnings;

# check version of Guile and extract include path to guile headers
my $include_dir;
BEGIN {
  open(CONF, "guile-config --version 2>&1 |") or die <<EOD;
###############################################################################
###
### Could not run guile-config --version : $!
###
### This module requires Guile version 1.5.0.  You do not appear to have 
### Guile on your system at all!  Please download the latest Guile from:
###
###    http://www.gnu.org/software/guile/guile.html
###
###############################################################################
EOD

  my $line = join('',<CONF>);
  my ($major, $minor, $micro) = $line =~ /version (\d+)\.(\d+)\.(\d+)/i;
  $major = 0 unless defined $major;
  $minor = 0 unless defined $minor;
  $micro = 0 unless defined $micro;
  unless ($major >= 1 and $minor >= 5 and $micro >= 0) {
    die <<EOD;
###############################################################################
###
### This module requires Guile version 1.5.0.  You appear to have an older
### version.  Please download a more recent version of Guile from:
###
###    http://www.gnu.org/software/guile/guile.html
###
###############################################################################
EOD
  }
  close(CONF);
  
  open(CONF, "guile-config compile|") or die "You have a broken guile-config - it ran \"guile-config --version\" just fine but won't do \"guile-config compile\" : $!";
  $line = <CONF>;
  close CONF;
  if (defined $line) {
    while($line =~ /\G-I(\S+)/g) {
      my $dir = $1;
      next unless -e "$dir/libguile.h" and -d "$dir/libguile";
      $include_dir = $dir;
    }
  }
  if (not defined $include_dir && -f '/etc/ld.so.conf') {
    open LDCONF, '/etc/ld.so.conf';
    while (my $dir = <LDCONF>) {
      chomp($dir);
      $dir =~ s/\/lib/\/include/;
      next unless -e "$dir/libguile.h" and -d "$dir/libguile";
      $include_dir = $dir;
    }
    close LDCONF;
  }
  if (not defined $include_dir) {
    my $dir = '/usr/include';
    next unless -e "$dir/libguile.h" and -d "$dir/libguile";
    $include_dir = $dir;
  }
  if (not defined $include_dir) {
    die "Unable to find libguile.h and libguile/*.h.  I checked all the directories mentioned by your \"guile-config\" to no avail.  Giving up!\n";
  }
}

# open headers dir and get list of *.h files without the .h
my @headers = ("gh");
opendir(DIR, "$include_dir/libguile") or die "Unable to open dir $include_dir/libguile : $!";
push(@headers, sort map { substr($_, 0, length($_) - 2) } 
     grep { /\.h$/ } readdir(DIR));
closedir DIR;

# weed out known-useless headers
@headers = grep { not /^(debug-malloc|deprecation|regex-posix)$/ } @headers;

# @headers = ('gh');

# create a sub-module for each header
my %seen;
my %names;
foreach my $header (@headers) {
  # - not kosher in directory names
  my $old_header = $header;
  $header =~ tr/-/_/;  

  print STDERR "Writing Makefile.PL for $header..\n";

  mkdir("$header", 0700) or die "Unable to make directory $header : $!"
    unless (-d $header);

  # create Makefile.PL
  open(MAKE, ">$header/Makefile.PL") 
    or die "Unable to open $header/Makefile.PL : $!";

  print MAKE <<END;
use ExtUtils::MakeMaker;
WriteMakefile(NAME         => 'Guile::$header', 
              VERSION_FROM => '$header.pm',
              LIBS         => ['-lguile'],
              CCFLAGS      => '-Wall -Werror',
              OPTIMIZE     => "-g",
              INC          => "-I$include_dir"
             );
END
  close MAKE;
  
  # generate xs
  print STDERR "Writing $header.xs for $header..\n";

  # open header
  if ($header eq 'gh') {
    open(H, "$include_dir/guile/gh.h") or die "Unable to open $header.h : $!";
  } else {
    open(H, "$include_dir/libguile/$old_header.h") or die "Unable to open $header.h : $!";
  }

  # open output file
  open(XS, ">$header/$header.xs") or die "Unable to open $header.xs : $!";

  # print XS header
print XS <<END;
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "libguile.h"
END

  if ($header eq 'gh') {
    print XS <<END;
#include "guile/gh.h"
#include "../guile_wrap.c"

MODULE = Guile::$header    PACKAGE = Guile::$header   PREFIX=gh_
PROTOTYPES: DISABLE
END
  } else {
    print XS <<END;
#include "libguile/$header.h"
#include "../guile_wrap.c"

MODULE = Guile::$header    PACKAGE = Guile::$header   PREFIX=scm_
PROTOTYPES: DISABLE
END
  }
  
  # look for declarations
  my $in_debug = 0;
  while (<H>) {
    chomp;
    next if /^\s*$/;     # skip blank lines
    next if /\s*\/\//;   # skip single-line comments
    
    # does it start an #ifdef GUILE_DEBUG of some sort?
    if (/^#\s*ifdef\s+GUILE_DEBUG/ or 
        /^#\s*if\s+defined\s+\(?\s*GUILE_DEBUG/ or
        /^#if\s+\(?\s*SCM_DEBUG_CELL_ACCESSES/ or
        /^#if\s+0/ or
        /^#ifdef\s+GUILE_ISELECT/ or 
        /^#ifdef\s+USE_COOP_THREADS/
       ) {
      $in_debug++;
      #print STDERR "$header.h : $. : START GUILE_DEBUG\n";
    } elsif ($in_debug and /^#\s*ifdef\s/) {
      # count enclosed #ifdefs 
      $in_debug++;
    } elsif ($in_debug and /^#endif/) {
      $in_debug--;
      #print STDERR "$header.h : $. : END GUILE_DEBUG\n" if $in_debug == 0;
    }

    # skip in_debug sections
    next if $in_debug;
    
    # remove irrelivent modifiers
    s/^\s*extern\s*//;
    s/([\s\(])const([\s\)])/$1$2/;

    # does this look like a function declaration for something
    # returning SCM or void with only SCMs for params?
    if (/(
         (?:
          (?:SCM    \s+    )|
          (?:SCM    \s+ \* )|
          (?:int    \s+    )|
          (?:long   \s+    )|
          (?:float  \s+    )|
          (?:double \s+    )|
          (?:char   \s+ \* )|
          (?:void   \s+    )
         )                              # return type
         \s*
         (?:scm|gh)_(\w+)               # $2 -> function name
         \s*
         (?:                            #  parameter list
         \(
           (?:
             (?:
             \s*
             (?:
                 (?:
                  (?:SCM    \s+   )|
                  (?:SCM    \s+ \*)|
                  (?:int    \s+   )|
                  (?:long   \s+   )|
                  (?:float  \s+   )|
                  (?:double \s+   )|
                  (?:char   \s+ \*)
                 )     # type
                 \s*
                 \w+   # name
                 \s*
                 ,?
                 \s*
             )+
             )
             |
             (?:
             \s*
             void
             \s*
             )
           )
         \)
         )
         \s*
         ;
         \s*
       )
       $/x) {
      my ($signature, $fname) = ($1, $2);
      
      # skip names already taken
      next if exists $seen{$fname};
      $seen{$fname} = 1;
      
      # XS doesn't like "void foo (void)"
      $signature =~ s/\(\s*void\s*\)/\(\)/;

      # every file has an init function that shouldn't be wrapped
      next if $fname eq "init_$header";
      
      # add Perl prototype to name
      $fname .= '(';
      if ($signature !~ /^void/) {
        $fname .= '$;';
      }
      if ($signature !~ /\(\)/) {
        if ($signature =~ /,/) {
          my $count = 1;
          while ($signature =~ /,/g) {
            $count++;
          }
          $fname .= '$' x $count;
        } else {
          $fname .= '$';
        }
      }
      $fname .= ')';
      
      # autouse doesn't like a () prototype
      $fname =~ s/\(\)$//;

      print XS $signature, "\n\n";
      push(@{$names{$header}}, $fname);
    }
  }

  close H;
  close XS;

  # create module stub
  open(PM, ">$header/$header.pm") or die "Unable to open $header.pm : $!";

  if ($names{$header}) {
    my $names = join(' ', @{$names{$header}});
    $names =~ s/\([\$;]+\)//g;

    print PM <<END;
package Guile::$header;

use 5.6.0;
use strict;
use warnings;

our \$VERSION = '0.01';
require DynaLoader;
require Exporter;
our \@ISA = qw(DynaLoader Exporter);
our \@EXPORT = qw($names);

DynaLoader::bootstrap('Guile::$header', \$VERSION);

1;
END
  } else {
    print PM <<END;
package Guile::$header;
our \$VERSION = '0.01';
# empty module - no methods available

1;
END
    
    # delete .xs file for empty module
    unlink("$header/$header.xs");
  }

  close PM;
}

# initialize @functions with symbols in the manually created Guile.xs
my @functions;

# insert import lines into Guile.pm
open(PM, "Guile.pm") or die "Unable to open Guile.pm : $!";
open(TMP, ">Guile.pm.tmp") or die "Unable to open Guile.pm.tmp: $!";
my $printing = 1;
while(<PM>) {
  print TMP $_
    if $printing;
  if (/^# AUTO IMPORT START/) {
    for (@headers) {
      # get names
      push(@functions, @{$names{$_}})
        if ($names{$_});
      print TMP "use Guile::$_;\n";
    }
    $printing = 0;
  }
  if (/^# AUTO IMPORT END/) {
    $printing = 1;
    print TMP $_;
  }

  # fill in FUNCTION LIST
  if (/^=head2 FUNCTION LIST/) {
    print TMP "\n";
    
    # sort according to function name (sans prototype)
    my ($a_name, $b_name);
    @functions = sort { 
      ($a_name = $a) =~ s!\(.*?\)!!;
      ($b_name = $b) =~ s!\(.*?\)!!;
      $a_name cmp $b_name;
    } @functions;

    for (@functions) {
      print TMP "   $_\n";
    }
    print TMP "\n";
    $printing = 0;    
  }

  if (!$printing and /^=cut/) {
    $printing = 1;
    print TMP $_;
  }
}
close TMP;
close PM;

# swap .tmp for .pm
unlink "Guile.pm" or die "Unable to unlink Guile.pm : $!";
copy("Guile.pm.tmp", "Guile.pm");
unlink "Guile.pm.tmp" or die "Unable to unlink Guile.pm.tmp : $!";

# write main Guile.pm Makefile
WriteMakefile(
              'NAME'         => 'Guile',
              'VERSION_FROM' => 'Guile.pm',
              'PREREQ_PM'    => {},
              'ABSTRACT_FROM'=> 'Guile.pm',
              'AUTHOR'       => 'Sam Tregar <sam@tregar.com>',
              'LIBS'	     => ['-lguile'],
              'DEFINE'       => '',
              'INC'	     => "-I$include_dir",
              'OBJECT'       => 'Guile.o guile_wrap.o',
              'CCFLAGS'      => "-Wall -Werror",
              'OPTIMIZE'     => "-g",
              # 'OPTIMIZE'     => "-O2",
              'DIR'          => \@headers,
              depend => { 'Guile.c' => 'typemap' },
             );

# avoid PERL_DL_NONLAZY.  libguile is missing symbols and it's not my
# job to fix...  Also, remove cd lines - there are no tests in the
# sub-modules themselves and it obscures my test results to have them
# there.
sub MY::test { 
    my $self = shift;
    package MY;
    my $result = $self->SUPER::test(@_);
    $result =~ s/PERL_DL_NONLAZY=1//g;
    $result =~ s/\s+\@cd.*?\n//g;
    return $result;
}

#<<END;
#
#TEST_VERBOSE=0
#TEST_TYPE=test_\$(LINKTYPE)
#TEST_FILE = 
#TEST_FILES = t/*.t
#TESTDB_SW = -d

#testdb :: testdb_\$(LINKTYPE)

#test :: \$(TEST_TYPE)

#test_dynamic :: pure_all
#	\$(FULLPERL) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE)

#testdb_dynamic :: pure_all
#	\$(FULLPERL) \$(TESTDB_SW) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE)
#
#test_ : test_dynamic

#test_static :: pure_all \$(MAP_TARGET)
#	./\$(MAP_TARGET) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE)
#
#testdb_static :: pure_all \$(MAP_TARGET)
#	./\$(MAP_TARGET) \$(TESTDB_SW) -I\$(INST_ARCHLIB) -I\$(INST_LIB) -I\$(PERL_ARCHLIB) -I\$(PERL_LIB) \$(TEST_FILE)

#END

#}

# delete generated subdirectories instead of traversing them
sub MY::clean {
    my $self = shift;
    package MY;
    my $result = $self->SUPER::clean(@_);
    foreach my $header (@headers) {
        $result =~ s/-cd\s$header\s.*/-rm -rf $header/;
    }

    $result;
}
