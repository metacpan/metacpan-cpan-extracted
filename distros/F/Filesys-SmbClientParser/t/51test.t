#!/usr/bin/env perl -w

$ENV{PATH}='';
$ENV{ENV}='';
use Test::More;
use Filesys::SmbClientParser;
use POSIX;
use strict;
my @zz;
END {
  chdir "tmpsmb";
  unlink @zz;
  chdir "..";
  rmdir("tmpsmb") or print "Can't unlink tmpsmb:$!\n";
  unlink("credits");
}
my @lc =
  (
   # repertoire fichier
   ["toto",    "test_file_for_samba"],
   ["toto(tot","test(file"],
   ["toERRto","tlERRtl"] # tks to Jason Sloderbeck for report
  );


if (! -e ".m") {
  plan skip_all => 'no smbclient tests defined with perl Makefile.PL';
} else {
 plan tests => (16 * ($#lc+1)) + 3;
}

open(F,".m") || die "Can't read .m\n";
my $l = <F>; chomp($l); 
my @l = split(/\t/, $l);
my $sha = $l[1];

foreach my $ref (@lc) {
  my ($file, $dir) = @{$ref};
  push @zz, $file;
  # create a test file
  open(FILE,">$file") || die "can't create $file:$!\n";
  print FILE "some data";
  close(FILE);

  my $smb = new Filesys::SmbClientParser
    (
     undef,
     (
      user       => $l[3],
      password   => $l[4],
      workgroup  => $l[2],
      host       => $l[0],
      share      => $l[1]
     )
    );
  #$smb->Debug(10);

  # Create a directory
  ok( $smb->mkdir($dir) , "Create directory $dir");

  # Try to recreate it
  ok(!$smb->mkdir($dir), "Create existant directory $dir");

  # Chdir this dir
  ok($smb->cd($dir) , "Chdir directory $dir");

  # Control current directory
  ok($smb->pwd eq '\\'.$sha.'\\'.$dir.'\\', "Pwd $dir");

  # Put a file
  ok( $smb->put($file) , "Put file $file on $dir");

  # List content of directory
  my @l2 = $smb->dir;
  ok( @l2 && $#l2 ==2, "List file on $dir");

  # Rename a file
  ok ($smb->rename($file,$file."_2") , "Rename file $file");

  # Get a file
  ok ($smb->get($file."_2") , "Get file $file");

  # Du the directory
  ok ($smb->du =~m!^0.0087!, "du $dir");

  # Unlink a file
  ok ($smb->del($file.'_2'), "Unlink file $file");

  # Erase this directory
  $smb->cd("..");
  ok ($smb->rmdir($dir), "Rm directory $dir");

  # Control current directory
  ok ($smb->pwd eq '\\'.$sha.'\\' , "Pwd");

  # Erase unexistant directory
  ok (! $smb->rmdir($dir.$dir),"Rm unexistant directory $dir$dir");

  # Unlink unexistant file
  ok (! $smb->del($file.$file),"Rm unexistant file $file$file");

  # Chdir unexistant directory
  ok(! $smb->cd($dir.$dir), "Chdir unexistant directory $dir$dir");

  # Get a unexistant file
  ok(! $smb->get($file.$file), "Get unexistant file $file$file");

  unlink($file.'_2');
  unlink($file) if (-e $file);
}

my $smb = new Filesys::SmbClientParser
  (
   undef,
     (
      workgroup  => $l[2],
      host       => $l[0],
      share      => $l[1],
     )
    );
open(F,">credits");
print F "username=$l[3]
password=$l[4]
";
close(F);
$smb->Auth("credits");
mkdir "tmpsmb",0755 or die "Can't create tmpsmb:$!\n";
chdir "tmpsmb";
# create some files
foreach my $ref (@lc) {
  my ($file, $dir) = @{$ref};
  # create a test file
  open(FILE,">$file") || die "can't create $file:$!\n";
  print FILE "some data";
  close(FILE);
}
chdir "..";

# mput
ok( $smb->mput("tmpsmb", 1) ,"mput") or diag($smb->{LAST_ERR});
#ok(! $smb->mput("tmpsmb2", 1) );

# mget
chdir "tmpsmb";
unlink @zz;
chdir "..";
rmdir("tmpsmb") or print "Can't unlink tmpsmb:$!\n";
ok( $smb->mget("tmpsmb", 1), "mget") or diag($smb->{LAST_ERR});
ok(! $smb->mget("tmpsmb2", 1), "mget non existant") or diag($smb->{LAST_ERR});

print "WORKGROUP:\n\tWg\tMaster\n";
foreach ($smb->GetGroups) {print "\t",$_->{name},"\t",$_->{master},"\n";}
print "HOSTS:\n\tName\t\tComment\n";
  foreach ($smb->GetHosts)  {print "\t",$_->{name},"\t\t",$_->{comment},"\n";}
print "ON ",$smb->Host," i've found SHARE:\n\tName\n";
foreach ($smb->GetShr)    {print "\t",$_->{name},"\n";}


print "There is a .m file in this directory with info about your params \n",
  "for you SMB server test. Think to remove it if you have finish \n",
  "with test.\n\nHere a dump of what I found on your smb network:\n",
  "(It can change with your smb server security level.)\n";

