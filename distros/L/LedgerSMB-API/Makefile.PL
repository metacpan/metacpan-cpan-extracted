use strict;
use warnings;
use ExtUtils::MakeMaker;
use Cwd;

print "==>  As we prepare for the first release,                         <==\n";
print "==>  our test suite shows new issues on a test bed                <==\n";
print "==>  It fails one of over a hundered tests,                       <==\n";
print "==>  and generates screen fulls of noise from the underlying      <==\n";
print "==>  LedgerSMB code base.                                         <==\n";
print "==>                                                               <==\n";
print "==>  Installation to your system libraries may require force      <==\n";
print "==>  But this is alpha code suitable for tests and                <==\n";
print "==>  we do not currently recommend that.                          <==\n";
print "==>                                                               <==\n";
print "==>  The test suite relies on the presence                        <==\n";
print "==>  of a LedgerSMB installation on the same server               <==\n";
print "==>  which hosts this module and any script which uses it.        <==\n";
print "==>  What is the path to your ledgerSMB installation?             <==\n";
my $LSMB_PATH = prompt('Path to LedgerSMB?','/usr/local/ledgersmb');
chomp($LSMB_PATH);

print "==>                                                               <==\n";
print "==>  The INSTALL file has full instructions, but essentially:     <==\n";
print "==>    psql> CREATE DATABASE lsmb_api_test ;                      <==\n";
print "==>    in broswer, at /ledgersmb/admin.pl                         <==\n";
print "==>    choose Pg_Database_Administration button                   <==\n";
print "==>    to populate your new database.                             <==\n";
print "==>      (The tests were written for the US_Service_Comnpany CoA) <==\n";
print "==>    Choose Add_User button to give a test user                 <==\n";
print "==>      access to your test database.                            <==\n";
print "==>                                                               <==\n";
print "==>  What lsmb user can connect to your Test LedgerSMB database?  <==\n";
my $LSMB_USER = prompt('LedgerSMB user with access to Test database?','lsmb_api_test');
chomp($LSMB_USER);

my $src = cwd() . '/t/conf/ledgersmb_path';
open('SRC','>',$src);
print SRC $LSMB_PATH;
close('SRC');

my $dst = '/etc/ledgersmb_path';
print "==>                                                               <==\n";
print "==>  For successful tests, you need to copy this configuration    <==\n";
print "==>  file into place, try:                                        <==\n";
print "==>  sudo cp $src $dst \n";

while(1){
  my $READY = prompt('Please type ready, when that has been done: ','No');
  if($READY =~ m/ready/i){ last; }
}

my $path_file = 't/conf/ledgersmb_path';
my $user_file = 't/conf/ledgersmb_test_user';

open('PATH','>',$path_file);
  print PATH $LSMB_PATH;
close PATH;

open('USER','>',$user_file);
  print USER $LSMB_USER;
close USER;

my @test_files = glob("t/tmpl/*.t");
foreach my $test_file (@test_files){
  $test_file =~ s/t\/tmpl\///;
  print "writing t/$test_file \n";
  open ('DST','>',"t/$test_file");
  open ('SRC',"t/tmpl/$test_file");
  while(<SRC>){
    if(m/LSMB_USER/){ $_ =~ s/LSMB_USER/$LSMB_USER/; }
    print DST $_;
  }
  close SRC;
  close DST;
}

WriteMakefile(
    NAME                => 'LedgerSMB::API',
    AUTHOR              => 'Nigel Titley and Hugh Esco <nigel@titley.com and hesco@campaignfoundations.com>',
    VERSION_FROM        => 'lib/LedgerSMB/API.pm',
    ABSTRACT_FROM       => 'lib/LedgerSMB/API.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'LedgerSMB-API-*' },
);

