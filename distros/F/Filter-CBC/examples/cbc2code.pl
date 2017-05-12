#!/usr/bin/perl

# CBC2CODE
# This small script will decrypt your Filter::CBC'ed code back to your
# plain code by reading the algorithm and the key.

# This script is part of Filter::CBC. Same license rules apply.

use strict;
use Crypt::CBC;

my $blank = "This space is left blank intentionally";
my %Algorithms =
("RIJNDAEL"=>"Rijndael",
 "DES"=>"DES",
 "IDEA"=>"IDEA",
 "BLOWFISH"=>"Blowfish",
 "GOST"=>"GOST",
 "DES_EDE3"=>"DES_EDE3",
 "TWOFISH"=>"Twofish",
 "NULL"=>"NULL",
 "TEA"=>"TEA");

if (!@ARGV)
{ print "Enter Filename with encrypted code : ";
  my $file = <STDIN>;
  chomp $file;
  push(@ARGV,$file);
}

while(@ARGV) { 
 my $file = shift;

 die "File $file does not exist !" unless -e $file;
 die "File $file is a directory !" unless !-d $file;
 
 open(F,"<$file") || die $!;
 my ($past_use,$key,$algorithm,$found);
 $found = 0;
 my @code = ();
 while(<F>)
 { if (/^\# $blank/) { $found++; }
   if (!$past_use)
   { ($algorithm,$key) = /use Filter\:\:CBC\s*[\'\"](\w*)[\'\"]\s*\,\s*[\'\"]([^\'\"]*)[\'\"].*?/; }
   if (defined $algorithm && defined $key && !$past_use) { $past_use++; push(@code ,$_); next;}
   if ($past_use && defined $key && defined $algorithm && $_ ne $/ && $found)
   { my (@foo) = <F>; 
     unshift (@foo,$_);
     my $code = join("",@foo);
     $algorithm ||= "Rijndael";
     $algorithm = $Algorithms{uc $algorithm} || $algorithm;
     $key ||= $blank;
     my $cipher = new Crypt::CBC($key,$algorithm);
     $code = $cipher->decrypt($code);
     open(OUTFILE,">$file.out") || die $!;
     print OUTFILE @code,$code;
     close(OUTFILE);
   } 
   else { push(@code,$_); }
 }
 close(F);
}