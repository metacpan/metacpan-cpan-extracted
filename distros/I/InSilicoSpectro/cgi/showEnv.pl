#!/usr/bin/env perl
use strict;

=head1 COPYRIGHT

Copyright (C) 2004-2005  Geneva Bioinformatics www.genebio.com

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

Alexandre Masselot, www.genebio.com

=cut

$|=1;		        #  flush immediately;

BEGIN{
  use File::Basename;
  push @INC, basename($0);
}
BEGIN {
  use CGIUtils;
}
BEGIN{
  eval{
   require DefEnv;
   DefEnv::read();
  };
}

END{
}

use English;
use InSilicoSpectro;

my $text;
foreach (@ARGV){
  $text=1 if /\btext/i;
}

printHeader();

printSectionTitle("User");
printTableOpen();
my $login=(getlogin()||(getpwuid($<))[0]);
printTableLine('login', $login);
printTableClose();

printSectionTitle("Misc");
printTableOpen();
printTableLine('Perl version', sprintf("%vd", $PERL_VERSION));
printTableLine('osname', $^O);
printTableLine('@INC', join ' ', @INC);
printTableLine('', $1);
printTableLine('', $1);
printTableClose();

printSectionTitle("InSilicoSpectro module default environment");
my @tmp=InSilicoSpectro::getInSilicoDefFiles();
if($text){
  print "\$$InSilicoSpectro::DEF_FILENAME_ENV = $ENV{$InSilicoSpectro::DEF_FILENAME_ENV}\n";
  foreach (@tmp){
    print "\t$_\n";
  }
}else{
  
}

printSectionTitle("Environment variables");
printTableOpen();
foreach (sort keys %ENV){
  printTableLine($_, $ENV{$_});
}
printTableClose();

use ExtUtils::Installed;
my $instmod = ExtUtils::Installed->new();


#my @incssort=sort {length $b <=> length $a} @INC;
#my @tmp=$instmod->files("Perl", "prog");
#foreach my $f (@tmp){
#  next unless $f =~ s/\.pm$//;
#  foreach my $dirinc (@incssort){
#    if ($f =~ s/^$dirinc//){
#      $f=~s/^[\/\\]//;
#      $f=~s/[\/\\]/::/g;
#      my $v;
#      my $cmd="use $f;\$v=$f->VERSION();";
#      eval $cmd;
#      unless ($@){
#	print "$f\t$v\n";
#      }
#      last;
#    }
#  }
#}

printSectionTitle("Perl Modules");
printTableOpen();
foreach my $module ($instmod->modules()) {
  my $version = $instmod->version($module) || "???";
  printTableLine($module, $version);
}
printTableClose();

printSectionTitle("InSilicoSpectroy modules?");
eval{
  require InSilicoSpectro;
  print $InSilicoSpectro::VERSION."\n";
};
if ($@){
  print "<font color='red'><b>" unless $text;
  print "No InSilicoSpectro.pm installed\n";
  print "</b></font>" unless $text;
}

printFooter();

sub printHeader{
  if($text){
    print "$0\n";
  }else{
    print <<EOP;
Content-type: text/html

<html>
  <header>
    <tile>$0</title>
  </header>
  <body>
    <h1>$0</h1>
EOP
  }
}
sub printFooter{
  if($text){
  }else{
    print <<EOP;
  </body>
</html>
EOP
  }
}

sub printSectionTitle{
  my $s=shift;
  if($text){
    print "\n---- ".(uc $s)." ----\n";
  }else{
    print "    <h3>$s</h3>\n"
  }
}

sub printTableOpen{
  print "     <table border=1 cellspacing=0>\n" unless $text;
}
sub printTableLine{
  if($text){
    print "".(join "\t", @_)."\n";
  }else{
    print "       <tr><td>".(join "</td><td>", @_)."</td></tr>\n";
 }
}
sub printTableClose{
  print "     </table>\n" unless $text;
}

