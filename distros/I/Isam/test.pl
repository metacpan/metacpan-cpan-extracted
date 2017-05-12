#!/usr/local/bin/perl

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
use strict;
use Isam;
use eg::Person;
my $loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

Isam->iserase("person") or print "erreur " . Isam->iserrno . " iserase(person)\n";
my $fd ;
$fd =  Isam->isbuild("person",63,$Person::kd_nom_prenom, &ISINOUT+&ISEXCLLOCK)
	or die "erreur " . Isam->iserrno . " isbuild(person)\n";

$fd->isclose;
$fd = Isam->isopen("person", &ISINOUT+&ISEXCLLOCK)
	or die "erreur " . Isam->iserrno . " isopen(person)\n";

my $di; 
$di = $fd->isindexinfo(0);
print "di_nkeys    = " . $di->di_nkeys . "\n";
print "di_recsize  = " . $di->di_recsize . "\n";
print "di_idxsize  = " . $di->di_idxsize . "\n";
print "di_nrecords = " . $di->di_nrecords . "\n";

print "isaddindex(prenom,nom) -> ";
$fd->isaddindex($Person::kd_prenom_nom) or die "erreur isaddindex\n";
print "ok\n";
$di = $fd->isindexinfo(0);
print "di_nkeys    = " . $di->di_nkeys . "\n";
print "di_recsize  = " . $di->di_recsize . "\n";
print "di_idxsize  = " . $di->di_idxsize . "\n";
print "di_nrecords = " . $di->di_nrecords . "\n";

for my $ind (1..$di->di_nkeys) {
   my $kd = $fd->isindexinfo($ind);
   print "cle $ind flags " . $kd->k_flags . " nparts " . $kd->k_nparts . "\n";
   for my $ix (0..$kd->k_nparts-1) {
      print "\t" . join("\t",@{$kd->k_part($ix)}) . "\n";
   }
}

my $ps = new Person;

$fd->isstart($Person::kd_nom_prenom,0,$ps,&ISFIRST) or die "erreur $fd->iserrno isstart\n";

$ps->nom("chane");
$ps->prenom("phil");
$ps->tel("212107");
$fd->iswrite($ps) or die "echec iswrite($ps)\n";

$ps->nom("chane you kaye");
$ps->prenom("maria");
$ps->tel("212623");
$fd->iswrite($ps) or die "echec iswrite($ps)\n";

print "liste par index1\n";
$fd->isstart($Person::kd_nom_prenom,0,$ps,&ISFIRST);
while ($fd->isread($ps,&ISNEXT)) {
   print $ps->nom, $ps->prenom, $ps->tel, "\n";
}

print "liste par index2\n";
$fd->isstart($Person::kd_prenom_nom,0,$ps,&ISFIRST);
while ($fd->isread($ps,&ISNEXT)) {
   print $ps->nom, $ps->prenom, $ps->tel, "\n";
}

$ps->nom("chane you kaye");
$ps->prenom("maria");
$fd->isread($ps,&ISEQUAL) or die "erreur " . $fd->iserrno . " isread ";
$ps->tel("0262212107");
$fd->isrewrite($ps);

print "liste par index2\n";
$fd->isstart($Person::kd_prenom_nom,0,$ps,&ISFIRST);
while ($fd->isread($ps,&ISNEXT)) {
   print $ps->nom, $ps->prenom, $ps->tel, "\n";
}

$fd = $fd->iscluster($Person::kd_prenom_nom)
   or die "erreur " . Isam->iserrno . " iscluster(prenom_nom)";
$fd->isdelindex($Person::kd_prenom_nom) or die "erreur " . Isam->iserrno . " isdelindex\n";

END {print "not ok 1\n" unless $loaded;}
