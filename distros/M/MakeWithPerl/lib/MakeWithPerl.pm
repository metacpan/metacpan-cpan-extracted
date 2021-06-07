#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib  -I/home/phil/perl/cpan/JavaDoc/lib -I/home/phil/perl/cpan/DitaPCD/lib/ -I/home/phil/perl/cpan/DataEditXml/lib/ -I/home/phil/perl/cpan/GitHubCrud/lib/  -I/home/phil/perl/cpan/DataDFA/lib/ -I/home/phil/perl/cpan/DataNFA/lib/ -I//home/phil/perl/cpan/PreprocessOps/lib/
#-------------------------------------------------------------------------------
# Make with Perl
# Philip R Brenan at gmail dot com, Appa Apps Ltd, 2017
#-------------------------------------------------------------------------------
package MakeWithPerl;
our $VERSION = "20210534";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use Getopt::Long;
use utf8;

sub mwpl {qq(makeWithPerlLocally.pl)}                                           # Make with Perl locally

my $javaHome;                                                                   # Location of java files
my $cIncludes;                                                                  # C includes folder
my $compile;                                                                    # Compile
my $coverage;                                                                   # Get coverage of code
my $doc;                                                                        # Documentation
my $gccVersion;                                                                 # Alternate version of gcc is set.  Example: --gccVersion gcc-10
my $htmlToPdf;                                                                  # Convert html to pdf
my $run;                                                                        # Run
my $upload;                                                                     # Upload files
my $valgrind;                                                                   # Check C memory usage
my $xmlCatalog;                                                                 # Verify xml

sub makeWithPerl {                                                              # Make a file
GetOptions(
  'cIncludes=s' =>\$cIncludes,
  'compile'     =>\$compile,
  'coverage'    =>\$coverage,
  'doc'         =>\$doc,
  'gccVersion=s'=>\$gccVersion,
  'htmlToPdf'   =>\$htmlToPdf,
  'run'         =>\$run,
  'valgrind'    =>\$valgrind,
  'upload'      =>\$upload,
  'xmlCatalog=s'=>\$xmlCatalog,
 );

unless($compile or $run or $doc or $upload)                                     # Check action
 {confess "Specify --compile or --run or --doc or --upload";
 }

my $file = shift @ARGV // $0;                                                   # File to process

unless($file)                                                                   # Confirm we have a file
 {confess "Use %f to specify the file to process";
 }

if (! -e $file)                                                                 # No such file
 {confess "No such file:\n$file"
 }

if ($upload)                                                                    # Upload files to GitHub
 {my @d = split m{/}, $file;                                                    # Split file name
  pop @d;
  while(@d)                                                                     # Look for a folder that contains a push command
   {my $u = "/".fpe(@d, qw(pushToGitHub pl));
    if (-e $u)
     {say STDERR $u;
      qx(perl $u);
      exit;
     }
    pop @d;
   }
  confess "Unable to find pushToGitHub in folders down to $file";
 }

if ($doc)                                                                       # Documentation
 {if ($file =~ m((pl|pm)\Z)s)                                                   # Document perl
   {say STDERR "Document perl $file";
    updatePerlModuleDocumentation($file);
   }
  elsif ($file =~ m((java)\Z)s)                                                 # Document java
   {say STDERR "Document java $file";

    my %files;
    for(findFiles($javaHome))
     {next if m/Test\.java\Z/ or m(/java/z/);                                   # Exclude test files and /java/ sub folders
      $files{$_}++ if /\.java\Z/
     }
    confess;
    #my $j = Java::Doc::new;
    #$j->source = [sort keys %files];
    #$j->target = my $f = filePathExt($javaHome, qw(documentation html));
    #$j->indent = 20;
    #$j->colors = [map {"#$_"} qw(ccFFFF FFccFF FFFFcc CCccFF FFCCcc ccFFCC)];
    #$j->html;
    #qx(opera $f);
   }
  else
   {confess "Unable to document file $file";
   }
  exit
 }

if (-e mwpl and $run)                                                           # Make with Perl locally
 {my $p = join ' ', @ARGV;
  my $c = mwpl;
  print STDERR qx(perl -CSDA $c $p);
  exit;
 }

if ($file =~ m(\.p[lm]\Z))                                                      # Perl
 {if ($compile)                                                                 # Syntax check perl
   {print STDERR qx(perl -CSDA -cw "$file");
   }
  elsif ($run)                                                                  # Run perl
   {if ($file =~ m(.cgi\Z)s)                                                    # Run from web server
     {&cgiPerl($file);
     }
    else                                                                        # Run from command line
     {say STDERR qq(perl -CSDA -w  "$file");
      print STDERR qx(perl -CSDA -w  "$file");
     }
   }
  elsif ($doc)                                                                  # Document perl
   {say STDERR "Document perl $file";
    updatePerlModuleDocumentation($file);
   }
  exit;
 }

if ($file =~ m(\.(dita|ditamap|xml)\Z))                                         # Process xml
 {my $source = readFile($file);
  my $C = $xmlCatalog;
  my $c = qq(xmllint --noent --noout "$file" && echo "Parses OK!" && export XML_CATALOG_FILES=$C && xmllint --noent --noout --valid - < "$file" && echo Valid);
  say STDERR $c;
  say STDERR qx($c);
  exit;
 }

if ($file =~ m(\.asm\Z))                                                        # Process assembler
 {my $o = setFileExtension $file, q(o);
  my $e = setFileExtension $file;
  my $l = setFileExtension $file, q(txt);
  my $c = qq(nasm -f elf64 -g -l $l -o $o $file);
  if ($compile)
   {say STDERR $c;
    say STDERR qx($c; cat $l);
   }
  else
   {$c = "$c; ld -o $e $o; $e";
    say STDERR $c;
    say STDERR qx($c);
   }
  exit;
 }

if ($file =~ m(\.cp*\Z))                                                        # GCC
 {my $cp = join ' ', map {split /\s+/} grep {!/\A#/} split /\n/, <<END;         # Compiler options
-finput-charset=UTF-8 -fmax-errors=7 -rdynamic
-Wall -Wextra -Wno-unused-function
END

  my $gcc = $gccVersion // 'gcc';                                               # Gcc version 10
  if ($compile)
   {my $cmd = qq($gcc $cp -c "$file" -o /dev/null);                             # Syntax check
    say STDERR $cmd;
    print STDERR $_ for qx($cmd);
   }
  else
   {my $e = $file =~ s(\.cp?p?\Z) ()gsr;                                        # Execute
    my $o = fpe($e, q(o));                                                      # Object file
    unlink $e, $o;

    my  $c = qq($gcc $cp -o "$e" "$file" && $e);                                # Compile and run
    lll qq($c);
    lll qx($c);
    unlink $o;

    if ($valgrind)                                                              # Valgrind requested
     {my $c = qq(valgrind --leak-check=full --leak-resolution=high --show-leak-kinds=definite  --track-origins=yes $e 2>&1);
      lll qq($c);
      my $result = qx($c);
      lll $result;
      exit(1) unless $result =~ m(ERROR SUMMARY: 0 errors from 0 contexts);
      lll "SUCCESS: no memory leaks"
     }
   }
  exit;
 }

if ($file =~ m(\.js\Z))                                                         # Javascript
 {if ($compile)
   {say STDERR "Compile javascript $file";
    print STDERR qx(nodejs -c "$file");                                         # Syntax check javascript
   }
  else
   {my $c = qq(nodejs  --max_old_space_size=4096  "$file");                     # Run javascript
    say STDERR $c;
    print STDERR qx($c);
    say STDERR q();
   }
  exit;
 }

if ($file =~ m(\.sh\Z))                                                         # Bash script
 {if ($compile)
   {say STDERR "Test bash $file";
    print STDERR qx(bash -x "$file");                                           # Debug bash
   }
  else
   {print STDERR qx(bash "$file");                                              # Bash
   }
  exit;
 }

if ($file =~ m(\.adblog\Z))                                                     # Android log
 {my $adb = q(/home/phil/android/sdk/platform-tools/adb);
  my $c = qq($adb -e logcat "*:W" -d > $file && $adb -e logcat -c);
  say STDERR "Android log\n$c";
  print STDERR qx($c);
  exit;
 }

if ($file =~ m(\.java\Z))                                                       # Java
 {my ($name, undef, $ext) = fileparse($file, qw(.java));                        # Parse file name
  my $package = &getPackageNameFromFile($file);                                 # Get package name
  my $cp      = fpd($javaHome, qw(Classes));                                    # Folder containing java classes
  if ($compile)                                                                 # Compile
   {my $c = "javac -g -d $cp -cp $cp -Xlint -Xdiags:verbose $file -Xmaxerrs 99";# Syntax check Java
    say STDERR $c;
    print STDERR qx($c);
   }
  else                                                                          # Compile and run
   {my $class = $package ? "$package.$name" : $name;                            # Class location
    my $p = join ' ', @ARGV;                                                    # Collect the remaining parameters and pass them to the java application
    my $c = "javac -g -d $cp -cp $cp $file && java -ea -cp $cp $class $p";      # Run java
    say STDERR $c;
    print STDERR qx($c);
   }
  &removeClasses;
  exit;
 }

if ($file =~ m(\.(txt|htm)\Z))                                                  # Html
 {my $s = expandWellKnownUrlsInHtmlFormat
          expandWellKnownWordsAsUrlsInHtmlFormat
          readFile $file;
  my $o = setFileExtension $file, q(html);                                      # Output file
  my $f = owf $o, $s;

  if ($htmlToPdf)                                                               # Convert html to pdf if requested
   {my $p = setFileExtension($file, q(pdf));
    say STDERR qx(wkhtmltopdf $f $p);
   }
  else                                                                          # Show html in opera
   {my $c = qq(timeout 3m opera $o);
    say STDERR qq($c);
    say STDERR qx($c);
   }
 }

if ($file =~ m(\.py\Z))                                                         # Python
 {if ($compile)                                                                 # Syntax check
   {print STDERR qx(python3 -m py_compile "$file");
   }
  elsif ($run)                                                                  # Run
   {print STDERR qx(python3 "$file");
   }
  elsif ($doc)                                                                  # Document
   {say STDERR "Document perl $file";
    updatePerlModuleDocumentation($file);
   }
  exit;
 }

if ($file =~ m(\.(vala)\Z))                                                     # Vala
 {my $lib = "--pkg gtk+-3.0";                                                   # Libraries
   if ($compile)                                                                # Syntax check
   {print STDERR qx(valac -c "$file" $lib);
   }
  elsif ($run)                                                                  # Run
   {print STDERR qx(vala "$file" $lib);
   }
  elsif ($doc)                                                                  # Document
   {say STDERR "Document perl $file";
    updatePerlModuleDocumentation($file);
   }
  exit;
 }

sub removeClasses
 {unlink for fileList("*.class")
 }

sub getPackageNameFromFile($)                                                   # Get package name from java file
 {my ($file) = @_;                                                              # File to read
  my $s = readFile($file);
  my ($p) = $s =~ m/package\s+(\S+)\s*;/;
  $p
 }

sub cgiPerl($)                                                                  # Run perl on web server
 {my ($file) = @_;                                                              # File to read

  my $r = qx(perl -CSDA -cw "$file" 2>&1);
  if ($r !~ m(syntax OK))
   {say STDERR $r;
   }
  else
   {my $base = fne $file;
    my $target = fpf(q(/usr/lib/cgi-bin), $base);
    lll qx(echo 121212 | sudo -S cp $file $target);
    lll qx(echo 121212 | sudo chmod ugo+rx $target);
    lll qx(opera http://localhost/cgi-bin/$base &);
   }
 }
}

#d
#-------------------------------------------------------------------------------
# Export - eeee
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT       = qw();
@EXPORT_OK    = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

MakeWithPerl - Make with Perl

=head1 Synopsis

Integrated development environment for Geany or similar editor for compiling
running and documenting programs written in a number of languages.

=head2 Installation:

  sudo cpan install MakeWithPerl

=head2 Operation

Configure Geany as described at
L<README.md|https://github.com/philiprbrenan/MakeWithPerl>.

=head1 Description

Make with Perl


Version "20210533".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.




=head1 Index


=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install MakeWithPerl

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::Most;
use Time::HiRes qw(time);

bail_on_fail;

my $develop   = -e q(/home/phil/);                                              # Developing
my $localTest = ((caller(1))[0]//'MakeWithPerl') eq "MakeWithPerl";             # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i and $^V and $^V ge v5.26)                              # Supported systems
 {plan tests => 1;
 }
else
 {plan skip_all => qq(Not supported on: $^O);
 }

my $f = owf("zzz.pl", <<END);
#!/usr/bin/perl
say STDOUT 'Hello World';
END
my $c = qq($^X -Ilib -M"MakeWithPerl" -e"MakeWithPerl::makeWithPerl" -- --run $f 2>&1);
my $r = qx($c);
unlink $f;

ok $r =~ m(Hello World);

1;
