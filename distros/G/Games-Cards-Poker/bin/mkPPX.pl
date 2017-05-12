#!/usr/bin/perl -w
# 46JDeWl - mkPPX.pl created by Pip Stuart <Pip@CPAN.Org>
#   to create a root Pip's Poker XML file (h.ppx) from all subdirectories.
# Should be totals of choo(50,3)*47*46*choo(45,2) = 41,951,448,000
# Search deeper to isolate where && why some are 41,949 instead =(
# This code is distributed under the GNU General Public License (version 2).

use strict;
use Games::Cards::Poker qw(:all);
use XML::XPath;
use XML::XPath::XMLParser;

my @holz = Holz(); my $ppxf = 'h.ppx'; my %data;

select((select(STDOUT), $|=1)[0]); # makes STDOUT hot handle (unbuffered)
print "Checking for existing data in: $ppxf";
if(-r $ppxf) {
  my $coun = 0;
  my $xpth = XML::XPath->new('filename' => $ppxf);
  foreach my $hole (@holz) {
    if($xpth->exists("/h/h$hole")) {
      my $valu = $xpth->findvalue("/h/h$hole/\@w"); # find wins attribute
      $data{$hole}{'w'}  = "$valu"; $data{'w'} += "$valu";
         $valu = $xpth->findvalue("/h/h$hole/\@t"); # find ties attribute
      $data{$hole}{'t'}  = "$valu"; $data{'t'} += "$valu";
         $valu = $xpth->findvalue("/h/h$hole/\@l"); # find loss attribute
      $data{$hole}{'l'}  = "$valu"; $data{'l'} += "$valu";
      my $summ = ($data{$hole}{'w'} + $data{$hole}{'t'} + $data{$hole}{'l'});
      unless($summ == 41949307620 || $summ == 41951448000) {
        printf("\n!*EROR*! hole:%-3s w:%13s t:%13s l:%13s\n  summ:%15s != 41949307620 || 41951448000!\n",
        $hole, $data{$hole}{'w'}, $data{$hole}{'t'}, $data{$hole}{'l'}, $summ);
        delete($data{$hole});
      }
    }
    print '.' unless(++$coun % 4);
  }
}
print "\nChecking for hole subdirectories...";
foreach my $hole (@holz) {
  if(!exists($data{$hole}) && -d "h$hole") {
    my $foun = 0;
    my $coun = 0;
    foreach(glob("h$hole/*.ppx")) {
      if(-e $_) {
        unless($foun) {
          print  "\n" if(%data || $hole eq 'AA');
          printf("h%-3s:", $hole);
          $foun = 1;
        }
        my $xpth = XML::XPath->new('filename' => $_);
        my $valu = $xpth->findvalue('/*/@w'); # find wins attribute
        $data{$hole}{'w'} += "$valu"; $data{'w'} += "$valu";
           $valu = $xpth->findvalue('/*/@t'); # find ties attribute
        $data{$hole}{'t'} += "$valu"; $data{'t'} += "$valu";
           $valu = $xpth->findvalue('/*/@l'); # find loss attribute
        $data{$hole}{'l'} += "$valu"; $data{'l'} += "$valu";
      }
      print '.' unless(++$coun % 10);
    }
    if(exists($data{$hole}) && exists($data{$hole}{'w'}) && $data{$hole}{'w'}) {
      my $summ = ($data{$hole}{'w'} + $data{$hole}{'t'} + $data{$hole}{'l'});
      unless($summ == 41949307620 || $summ == 41951448000) {
        printf("\n!*EROR*! hole:%-3s w:%13s t:%13s l:%13s\n  summ:%15s != 41949307620 || 41951448000!\n",
          $hole, $data{$hole}{'w'}, $data{$hole}{'t'}, $data{$hole}{'l'}, $summ);
        delete($data{$hole});
      }
    }
  }
}
print "\n";
if(%data) {
  open(PPXF, ">h.ppx");
  print  PPXF qq|<?xml version="1.0" encoding="utf-8"?>\n|;
  printf PPXF qq|<h      w=%15s t=%15s l=%15s >\n|, '"' . $data{'w'} . '"', '"' . $data{'t'} . '"', '"' . $data{'l'} . '"';
  my %swnz = ();
  foreach my $hole (@holz) {
    $swnz{$data{$hole}{'w'}} = $hole if(exists($data{$hole}));
  }
  foreach my $winz (reverse(sort(keys(%swnz)))) {
    printf PPXF qq|  <h%-3s w=%15s t=%15s l=%15s/>\n|, $swnz{$winz}, '"' . $winz . '"', '"' . $data{$swnz{$winz}}{'t'} . '"', '"' . $data{$swnz{$winz}}{'l'} . '"';
  }
  print PPXF qq|</h>|;
  close(PPXF);
}
