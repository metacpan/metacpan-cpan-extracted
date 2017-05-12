# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Livelink-DAV.t'

#########################
#change 'no_plan' to tests=>23, and add done_testing();
# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests=>62;
use Data::Dumper;
use MIME::Base64 ();
#use Test::More tests=>9;
#test number 1-3
BEGIN { use_ok('Livelink::DAV') };
BEGIN { use_ok('CopyTree::VendorProof') };
BEGIN { use_ok('Term::ReadKey') };
my %config;
#default configuration
$config{livelinkdav} ||='webdav_dir';
$config{livelinksite} ||='http://www.yourlivelinksite.org';
$config{domuser} ||='username';
$config{pass} ||='y';

open my $config_fh, "<", "test.config" or die "Could not open test configuration!";
while(<$config_fh>) {
  chomp;
  my ($key, $value) = split /\s+/, $_, 2;
   $config{$key} = $value;
}
close $config_fh;
SKIP:{

skip 'skipping online tests', 59 if (!$config{'live_tests'});


   my $cpobj = CopyTree::VendorProof->new;
   isa_ok ($cpobj, "CopyTree::VendorProof", 'cpobj is a correct obj');

   my $livelink_inst = Livelink::DAV->new;
   isa_ok ($livelink_inst, "Livelink::DAV", 'connector_inst is a correct Livelink::DAV obj');
   my ($u, $p, $creds_dom, $livelinkdav,$livelinkperm, $no_https_proxy);
      print STDERR "\n";
      print STDERR "========================================================================\n";
      print STDERR "|      We need to connect to your livelink site                        |\n";
      print STDERR "|      Please enter your livelink username:                            |\n";
      print STDERR "|                                                                      |\n";
      print STDERR "=======================================================================|\n";
      print STDERR "username [".$config{domuser}."]: ";
      chomp($u = <STDIN>);
      $config{domuser}=$u if $u;
		$config{livelinkperm} ||='~'.$config{domuser};
      print STDERR "\n";
      print STDERR "========================================================================\n";
      print STDERR "|      Now please enter your password for livelink  :                  |\n";
      print STDERR "=======================================================================|\n";
      print STDERR "password (will not echo on screen): ";
      Term::ReadKey::ReadMode('noecho');
      chomp ($p=<STDIN>);
      print STDERR "\n";
      Term::ReadKey::ReadMode(0);
      print STDERR "========================================================================\n";
      print STDERR "|      enter your livelink site as such:                               |\n";
      print STDERR "|      http://www.livelinksite.org/                                    |\n";
      print STDERR "|                                                                      |\n";
      print STDERR "=======================================================================|\n";
      print STDERR "livelinksite [".$config{livelinksite}."]: ";
      chomp ($creds_dom=<STDIN>);
      $config{livelinksite}=$creds_dom if $creds_dom;
      print STDERR "\n";
      print STDERR "========================================================================\n";
      print STDERR "|      enter your dav folder name, for example, if your dav is at      |\n";
      print STDERR "|      http://www.livelinksite.org/somedir/webdav/                     |\n";
      print STDERR "|      then type:                                                      |\n";
      print STDERR "|      somedir/webdav                                                  |\n";
      print STDERR "=======================================================================|\n";
      print STDERR "webdavfolder [".$config{livelinkdav}."]: ";
      chomp ($livelinkdav=<STDIN>);
      $config{livelinkdav}=$livelinkdav if $livelinkdav;
      print STDERR "\n";
      print STDERR "========================================================================\n";
      print STDERR "|      enter the dav folder under webdav where you have write perm,    |\n";
      print STDERR "|      for example, if your test folder is at                          |\n";
      print STDERR "|      http://www.livelinksite.org/somedir/webdav/~".$config{'domuser'}."                    |\n";
      print STDERR "|      then type:                                                      |\n";
      print STDERR "|      ~".$config{'domuser'}."                                                               |\n";
      print STDERR "=======================================================================|\n";
      print STDERR "writable test folder [".$config{livelinkperm}."]: ";
      chomp ($livelinkperm=<STDIN>);
		$livelinkperm =~s/\/$// if $livelinkperm;
      $config{livelinkperm}=$livelinkperm if $livelinkperm;
		$livelinkperm=$config{livelinkperm};
		
		
		
  #    print STDERR "\n";
  #    print STDERR "========================================================================\n";
  #    print STDERR "|      do you normally use a proxy server, but want to AVOID           |\n";
  #    print STDERR "|      using it for your https connection? (y/n)                       |\n";
  #    print STDERR "|        [that is, enter 'y' to avoid proxy, or 'n' to use it]         |\n";
  #    print STDERR "|      your config could be:                                           |\n";
  #    print STDERR "|      you don't know what a proxy is --> type 'n'                     |\n";
  #    print STDERR "|      your livelink is outside your proxy --> type 'n'                |\n";
  #    print STDERR "|      your livelink is inside your proxy --> type 'y'                 |\n";
  #    print STDERR "|                                                                      |\n";
  #    print STDERR "=======================================================================|\n";
  #    print STDERR "no_https_proxy [".$config{no_proxies}. "]: ";
  #    chomp ($no_https_proxy=<STDIN>);
  #    $config{no_proxies}=$no_https_proxy if $no_https_proxy;
#   if ($config{no_proxies} eq 'y'){
#      delete $ENV{'https_proxy'};
#      delete $ENV{'http_proxy'};
#   }
   print STDERR "\n";
   #save config
   open $config_fh, ">", "test.config";
   for my $key (keys %config) {
   #   print "$key ".$config{$key} ."\n";
      print $config_fh "$key ".$config{$key} ."\n";
   }

   print "*******************************\n";
   isnt ($config{domuser}, '', 'has a sp username');
   isnt ($p, '', 'has a sp password');
   isnt ($config{livelinksite}, '', 'has a sp_creds_domain');
   isnt ($config{livelinkdav}, '', 'has a sp_authrized_root');
   isnt ($config{livelinkperm}, '','has a modifiable folder');


	$livelink_inst->lldsite($config{'livelinksite'});
   $livelink_inst ->lldusern($config{'domuser'});
   $livelink_inst ->llduserp($p);
   $livelink_inst ->llddav($config{'livelinkdav'});
	my $davobjtest= $livelink_inst->enodav();
   isa_ok ($davobjtest, "HTTP::DAV", 'enodav returns HTTP::DAV');

	diag ("\n**cust_rmdir / cust_mkdir tests**\n");
	

	$livelink_inst->cust_rmdir ($livelinkperm."/testdir");
	#test number 9  (in skip block)
	is ($livelink_inst->cust_rmdir ($livelinkperm."/testdir"),'',"cust_rmdir returns nothing even if dir does not exist");


	
	diag ("\n**is_fd method checks, more or less includes cust_mkdir checks**\n");



	isnt ($livelink_inst->is_fd($livelinkperm."/testdir"), 'd', "make sure testdir under $livelinkperm does not exist");
	$livelink_inst ->cust_mkdir($config{livelinkperm}."/testdir");
	is ($livelink_inst->is_fd($livelinkperm."/testdir"), 'd', "created testdir under $livelinkperm\n");
	
	is ($livelink_inst->is_fd($livelinkperm."/testdir/level2"), 'pd', "testdir does not have anything in it, so file check on testdir/level 2 returns pd\n");
	$livelink_inst ->cust_mkdir($config{livelinkperm}."/testdir/level2");
	is ($livelink_inst->is_fd($livelinkperm."/testdir/level2"), 'd', "created testdir/level2, shoudl return 'd' \n");
	is ($livelink_inst->is_fd($livelinkperm."/testdir/level20/phantom1"), '0', "non-exisiting with no valid parent should return 0 \n");
	#makes sure that this does not overwrite prev content, fdls later should show all above items
	$livelink_inst ->cust_mkdir($config{livelinkperm}."/testdir");



	diag ("\n***write_from_mem / read_from_mem, txt mode***\n");


	
	my $testroot=$config{livelinkperm}."/testdir";
	my $content = "some test content\n2nd line\n";
	$livelink_inst ->write_from_memory(\$content, $livelinkperm."/testdir/test_write_from_memory");
	#test number 15 (in skip block)
	is ($livelink_inst->is_fd($livelinkperm."/testdir/test_write_from_memory"), 'f', "wrote a fle from memory to site $livelinkperm/testdir/test_write_from_memory\n");
	my $content2 = "another test content\n2nd line\n";
	$livelink_inst ->write_from_memory(\$content2, $livelinkperm."/testdir/test_write_from_memory2.txt");
	is ($livelink_inst->is_fd($livelinkperm."/testdir/test_write_from_memory2.txt"), 'f', "wrote a windows safe file (.txt) from memory to site $livelinkperm/testdir/test_write_from_memory2.txt\n");
	
	is (${ $livelink_inst -> read_into_memory($livelinkperm."/testdir/test_write_from_memory") }, $content, "read from $livelinkperm/testdir/test_write_from_memory\n");
#added test
	is (${ $livelink_inst -> read_into_memory ( $livelinkperm."/testdir/test_write_from_memory2.txt") }, $content2, "read from $livelinkperm/testdir/test_write_from_memory2.txt\n");
	


	diag ("\n***copy_local_files tests, includes overwrite tests\n");



	#set up or copy_local_file test, should overwrite files if exists
	$livelink_inst ->copy_local_files("$testroot/test_write_from_memory2.txt", "$testroot/test_write_from_memory3.txt");
#added test
	is ($livelink_inst->is_fd("$testroot/test_write_from_memory3.txt"),'f', 'confirm creattion of memory 3 file');
#set up for overwrite test, put original content into write_from_memroy2
	$livelink_inst ->write_from_memory(\$content, $livelinkperm."/testdir/test_write_from_memory2.txt");
#added test
	is (${ $livelink_inst -> read_into_memory($livelinkperm."/testdir/test_write_from_memory2.txt") }, $content, "read from overwritten $livelinkperm/testdir/test_write_from_memory2\n");
#copy original mem2 content from mem3, using local file, should restore "another"
	$livelink_inst ->copy_local_files("$testroot/test_write_from_memory3.txt", "$testroot/test_write_from_memory2.txt");
#added test
	is (${ $livelink_inst -> read_into_memory($livelinkperm."/testdir/test_write_from_memory2.txt") }, $content2, "$livelinkperm/testdir/test_write_from_memory2.txt should change because copy_local_file overwrites\n");


#set up for write_from_memory test to write to exisiting dir, should not proceed

	$livelink_inst ->cust_mkdir($testroot."/nocontent");
#added test
	is( $livelink_inst->is_fd("$testroot/nocontent"), 'd', "confirmed created a empty dir where there should be no content added\n");
	$livelink_inst ->write_from_memory(\$content, $testroot."/nocontent");
	my @nocontent= $livelink_inst->fdls('', "$testroot/nocontent");
#added test
	is (scalar(@nocontent), "0", "write_from_memory did not proceed since dest is dir\n");
#do the same test for copy_local_files, should not proceed with dest being dir

	$livelink_inst ->copy_local_files("$testroot/test_write_from_memory3.txt", "$testroot/nocontent");
	@nocontent= $livelink_inst->fdls('', "$testroot/nocontent");
#added test
	is (scalar(@nocontent), "0", "copy_local_files did not proceed since dest is dir\n");
#cleans up memory3, or it will mess up subsequent tests
	$livelink_inst ->cust_rmdir("$testroot/test_write_from_memory3.txt");
##added test
	is( $livelink_inst->is_fd("$testroot/test_write_from_memory3.txt"), 'f', "cust_rmdir does not del files\n");
	$livelink_inst ->cust_rmfile("$testroot/test_write_from_memory3.txt");
##added test
	isnt( $livelink_inst->is_fd("$testroot/test_write_from_memory3.txt"), 'f', "cust_rmfile del files\n");
#this should show nothing
	diag "\n\n\nDumper output";
	diag Dumper ($livelink_inst->fdls('',"$testroot/nocontent"));
	diag "\nEnd Dumper output\n\n";
	$livelink_inst ->cust_rmdir("$testroot/nocontent");
##added test
	is( $livelink_inst->is_fd("$testroot/nocontent"), 'pd', "successful delete of nocontent dir");


	
	diag ("\n***write_from_mem / read_from_mem, bin mode***\n");

	my $bin=MIME::Base64::decode_base64(&base64bin);
	$livelink_inst ->write_from_memory(\$bin, $livelinkperm."/testdir/test_write_bin");
	my $ret_bin= $livelink_inst ->read_into_memory( $livelinkperm."/testdir/test_write_bin");
	my $base64retenc=MIME::Base64::encode_base64($$ret_bin);
	is (&base64bin, $base64retenc, 'test bin file upload and download stays the same');
	
	diag ("\n***fdls test***\n");
	my @files=$livelink_inst->fdls('f',"$livelinkperm/testdir/");
	my @dirs=$livelink_inst->fdls('d',"$livelinkperm/testdir/");
	my @fdarrayrefs=$livelink_inst->fdls('fdarrayrefs',"$livelinkperm/testdir/");
	my @fds=$livelink_inst->fdls('',"$livelinkperm/testdir/");
	
	is ($files[0], "$livelinkperm/testdir/test_write_bin",'fdls f test, f0');
	is ($files[1], "$livelinkperm/testdir/test_write_from_memory",'fdls f test, f1');
	is ($files[2], "$livelinkperm/testdir/test_write_from_memory2.txt",'fdls f test, f2');
	is ($dirs[0], "$livelinkperm/testdir/level2",'fdls d test, d0');
	is ($fdarrayrefs[0][0], 	"$livelinkperm/testdir/test_write_bin", 'fdls fdarrayref test, f0');
	is ($fdarrayrefs[0][1], 	"$livelinkperm/testdir/test_write_from_memory", 'fdls fdarrayref test, f1');
	is ($fdarrayrefs[0][2], 	"$livelinkperm/testdir/test_write_from_memory2.txt", 'fdls fdarrayref test,f2');
	is ($fdarrayrefs[1][0], 	"$livelinkperm/testdir/level2", 'fdls fdarrayref test,d0');

	is ($fds[0], "$livelinkperm/testdir/test_write_bin", 'fdls concat array f0');
	is ($fds[1], "$livelinkperm/testdir/test_write_from_memory",'fdls concat array f1');
	is ($fds[2], "$livelinkperm/testdir/test_write_from_memory2.txt",'fdls concat array f2');
	is ($fds[3], "$livelinkperm/testdir/level2",'fdls concat array d0');
	
	diag ("\n***copy_local_files test***\n");

	isnt ($livelink_inst->is_fd("$livelinkperm/testdir_copied"), 'd', 'testdir_copied should not exist at this point');
	
	$livelink_inst->copy_local_files("$livelinkperm/testdir", "$livelinkperm/testdir_copied");
	isnt ($livelink_inst->is_fd("$livelinkperm/testdir_copied"), 'd', 'copy_local_files should not create dirs');
	$livelink_inst->cust_mkdir ("$livelinkperm/testdir_copied");
	is($livelink_inst->is_fd("$livelinkperm/testdir_copied"), 'd', 'cust_mkdir creates testdir_copied');

	$livelink_inst->copy_local_files("$livelinkperm/testdir/test_write_from_memory2.txt", "$livelinkperm/testdir_copied/test_write_from_memory2.txt");
	$livelink_inst->copy_local_files("$livelinkperm/testdir/test_write_from_memory2.txt", "$livelinkperm/testdir_copied/test_write_from_memory3.txt");
	$livelink_inst->copy_local_files("$livelinkperm/testdir/test_write_from_memory2.txt", "$livelinkperm/testdir_phantom/test_write_from_memory2.txt");
	$livelink_inst->copy_local_files("$livelinkperm/testdir/test_write_from_memory2.txt", "test_write_from_memory2.txt");
	is ($livelink_inst->is_fd("$livelinkperm/testdir_copied/test_write_from_memory3.txt"), "f","copy single file local");
	$livelink_inst->cust_rmfile("$livelinkperm/testdir_copied/test_write_from_memory3.txt", "deleting file (in testdir_copied) test_write_from_memory3.txt");
	is ($livelink_inst->is_fd("$livelinkperm/testdir_copied/test_write_from_memory3.txt"),"pd","copy single file local");

	$livelink_inst->cust_mkdir("$livelinkperm/testdir2");
	$cpobj->src("$livelinkperm/testdir", $livelink_inst);
	$cpobj ->dst("$livelinkperm/testdir2", $livelink_inst);
	$cpobj ->cp;
	$cpobj ->reset;


	$livelink_inst->cust_rmdir("$livelinkperm/testdir");
	isnt($livelink_inst->is_fd("$livelinkperm/testdir"), "d", "deleted first test dir");

	$cpobj->src("$livelinkperm/testdir2/testdir", $livelink_inst);
	$cpobj ->dst("$livelinkperm", $livelink_inst);
	$cpobj ->cp;
	$livelink_inst->cust_rmdir("$livelinkperm/testdir2");
	#validate entire tree has been copied back:
	@files=();
	@dirs=();
	@fdarrayrefs=();
	@fds=();

	@files=$livelink_inst->fdls('f',"$livelinkperm/testdir/");
	@dirs=$livelink_inst->fdls('d',"$livelinkperm/testdir/");
	@fdarrayrefs=$livelink_inst->fdls('fdarrayrefs',"$livelinkperm/testdir/");
	@fds=$livelink_inst->fdls('',"$livelinkperm/testdir/");
	
	is ($files[0], "$livelinkperm/testdir/test_write_bin",'fdls f test, f0');
	is ($files[1], "$livelinkperm/testdir/test_write_from_memory",'fdls f test, f1');
	is ($files[2], "$livelinkperm/testdir/test_write_from_memory2.txt",'fdls f test, f2');
	is ($dirs[0], "$livelinkperm/testdir/level2",'fdls d test, d0');
	is ($fdarrayrefs[0][0], 	"$livelinkperm/testdir/test_write_bin", 'fdls fdarrayref test, f0');
	is ($fdarrayrefs[0][1], 	"$livelinkperm/testdir/test_write_from_memory", 'fdls fdarrayref test, f1');
	is ($fdarrayrefs[0][2], 	"$livelinkperm/testdir/test_write_from_memory2.txt", 'fdls fdarrayref test,f2');
	is ($fdarrayrefs[1][0], 	"$livelinkperm/testdir/level2", 'fdls fdarrayref test,d0');

	is ($fds[0], "$livelinkperm/testdir/test_write_bin", 'fdls concat array f0');
	is ($fds[1], "$livelinkperm/testdir/test_write_from_memory",'fdls concat array f1');
	is ($fds[2], "$livelinkperm/testdir/test_write_from_memory2.txt",'fdls concat array f2');
	is ($fds[3], "$livelinkperm/testdir/level2",'fdls concat array d0');


	diag ("\n\n cleaning up...\n\n");


	$livelink_inst->cust_rmdir("$livelinkperm/testdir_copied");
	isnt($livelink_inst->is_fd("$livelinkperm/testdir_copied"), "d", "deleted second test dir");

	
	
#    my $path='Shared Documents/script_qc/somepath';
#    $livelink_inst -> write_from_memory(\$content, $path);
#    isa_ok (ref $cpobj ->src ($path,$livelink_inst), 'CopyTree::VendorProof', 'src returns self');
#    is (ref $cpobj ->{'source'}{$path}, 'Livelink::DAV', 'src stores connector_inst with path as key');
#    my @testpath= keys %{$cpobj ->{'source'}};
#    is ($testpath[0], $path, 'src stores actual path key');
#    #dst is getter and setter, does not return self
#    $path ='Shared Documents/script_qc/someotherpath';
#    $cpobj ->dst ($path,$livelink_inst); #setter
#    is (ref $cpobj ->{'destination'}{$path}, 'Livelink::DAV', 'dst stores path and connector_inst');
#    my ($returnpath, $returninst) = $cpobj ->dst ();
#    is ($returnpath, $path,'first part of dst() returns path');
#    is (ref $returninst,'Livelink::DAV' ,'second part of dst() returns connector_inst');
#    my $newcpobj = CopyTree::VendorProof->new;
#    eval {$newcpobj ->cp;};
#    like ($@, qr"^dest file is not defined\.", 'no dst object/file');
#    $newcpobj = CopyTree::VendorProof->new;
#    $newcpobj -> dst ('', $livelink_inst);
#    eval {$newcpobj ->cp;};
#    like ($@, qr"^dest file is not defined\.", 'dst obj, no fd_ls meth, no path. no path fails first');
#    $newcpobj = CopyTree::VendorProof->new;
#    $newcpobj -> dst ('Shared Documents/script_qc/someotherpath', $livelink_inst);
#    eval {$newcpobj ->cp;};
#    like ($@, qr/you don't have a source/, 'copy local to local, somepath to someotherpath, no src declair');
#    $newcpobj ->src ('Shared Documents/script_qc/somepath', 'nobj');
#    eval {$newcpobj ->cp;};
#    like ($@, qr/Can't locate object method "is_fd"/, 'copy local to local, somepath to someotherpath, src inst no methods');
#    $newcpobj = CopyTree::VendorProof->new;
#    $newcpobj -> dst ('Shared Documents/script_qc/someotherpath', $livelink_inst);
#    $newcpobj ->src ('Shared Documents/script_qc/somepath', $livelink_inst);
#    eval {$newcpobj ->cp;};
#    is ($@, '', 'copy local to local, somepath to someotherpath');
#    is ($livelink_inst -> is_fd ('Shared Documents/script_qc/somepath') , 'f', 'file test f on src');
#    is ($livelink_inst -> is_fd ('Shared Documents/script_qc/someotherpath') , 'f', 'file test f on src');
#    #use base qw/CopyTree::VendorProof/;
#    my @files;
#    @files = $livelink_inst ->fdls ('f', '.');
#    isnt ($files[0], '', 'fdls f, . shoudld get somepath and someotherpath');
#    $livelink_inst->cust_mkdir("Shared Documents/script_qc/testdir");
#    my @dirs = $livelink_inst ->fdls ('d', 'Shared Documents/script_qc/testdir/../');
#    isnt ($dirs[0], '', 'fdls f, ../ use of .. and ending slash auto removed');
#    is ($livelink_inst -> is_fd ("Shared Documents/script_qc/testdir"), 'd', "is_fd returns 'd' on dir");
#    $newcpobj ->reset;
#    $newcpobj ->src ('Shared Documents/script_qc/someotherpath', $livelink_inst);
#    $newcpobj ->dst ('Shared Documents/script_qc/testdir', $livelink_inst);
#    $newcpobj ->cp;
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir/someotherpath'), 'f','cp file to dir');
# 
#    $newcpobj ->reset;
#    $newcpobj ->src ('Shared Documents/script_qc/someotherpath', $livelink_inst);
#    $newcpobj ->dst ('Shared Documents/script_qc/testdir/diffname', $livelink_inst);
#    $newcpobj ->cp;
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir/diffname'), 'f','cp file to different file name');
#    $newcpobj ->reset;
#    $newcpobj ->src ('Shared Documents/script_qc/testdir', $livelink_inst);
#    $newcpobj ->dst ('Shared Documents/script_qc/testdir2', $livelink_inst);
#    eval {$newcpobj ->cp;};
#    like ($@, qr/you cannot copy a dir \[Shared Documents\/script_qc\/testdir] into a non \/ non-existing dir \[Shared Documents\/script_qc\/testdir2]/,'cp dir to dir copy, check non existing dest dir copy shoudl fail' );
# 
#    $livelink_inst ->cust_mkdir ('Shared Documents/script_qc/testdir2');
#    $newcpobj ->cp;
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir2/testdir'), 'd','cp dir to dir copy, check source dir inside dest');
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir2/testdir/diffname'), 'f','cp dir to dir copy, check source dir, file inside dest');
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir2/testdir/someotherpath'), 'f','cp dir to dir copy, check source dir, file inside dest');
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/nonexist/bsfile'), 0,'cp dir to dir copy, check source dir, file inside dest');
#    $livelink_inst ->write_from_memory($livelink_inst->read_into_memory('Shared Documents/script_qc/testdir2/testdir/diffname'), 'Shared Documents/script_qc/testdir2/written');
#    $livelink_inst ->copy_local_files('Shared Documents/script_qc/testdir2/testdir/diffname',  'Shared Documents/script_qc/testdir2/written_local');
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir2/written'), 'f','write_from_memory, read_into_memory test');
#    is ($livelink_inst->is_fd('Shared Documents/script_qc/testdir2/written_local'), 'f','copy_local_files test');
#    my ($arrf, $arrd) = $livelink_inst ->fdls ('fdarrayrefs', '.');
#    is (ref $arrf, 'ARRAY', 'fdarrayrefs test');
#    is (ref $arrd, 'ARRAY', 'fdarrayrefs test');
# 
#    eval{$livelink_inst -> cust_rmdir ('non-existingdir');};
#    like ($@,qr/wait\. you told me to delete something that's not a dir\. I'll stop for your protection/, 'removing an non existing dir dies');
#    $livelink_inst->cust_rmdir ("Shared Documents/script_qc/testdir");
#    $livelink_inst->cust_rmdir ("Shared Documents/script_qc/testdir2");
#    $livelink_inst->cust_rmfile ('Shared Documents/script_qc/somepath');
#    is ($livelink_inst -> is_fd('Shared Documents/script_qc/somepath'), 'pd', 'successful single file delete');
# 
#    #kinda afraid to test these:
#    #eval {$livelink_inst->cust_rmdir ("/");};
#    #like ($@, qr'should not be rmdiring a root', 'do not rmdir / no matter what you say test');
#    #eval {$livelink_inst->cust_mkdir ("/");};
#    #like ($@, qr'should not be mkdiring a root', 'do not mkdir / no matter what you say test');
#    is ($livelink_inst -> is_fd ("Shared Documents/script_qc/testdir"), 'pd', "is_fd returns 'pd' on non-existing");
# 
#    $livelink_inst->cust_rmdir ("Shared Documents/script_qc");
# 
#    is ($livelink_inst -> is_fd ("Shared Documents/script_qc"), 'pd', "is_fd returns 'pd' on non-existing");
}



#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.
sub base64bin{
my $b=<<'EOLZ';
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
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA//////////8AAAAAAAAAAP//////////
AAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAEAAAAAAAAAAMAAAAAAAAAMgDQAAAAAAADQAAAAAAAADo
BUAAAAAAAPX+/28AAAAAmAJAAAAAAAAFAAAAAAAAABgDQAAAAAAABgAAAAAAAAC4AkAAAAAAAAoA
AAAAAAAAPQAAAAAAAAALAAAAAAAAABgAAAAAAAAAFQAAAAAAAAAAAAAAAAAAAAMAAAAAAAAA6A9g
AAAAAAACAAAAAAAAADAAAAAAAAAAFAAAAAAAAAAHAAAAAAAAABcAAAAAAAAAmANAAAAAAAAHAAAA
AAAAAIADQAAAAAAACAAAAAAAAAAYAAAAAAAAAAkAAAAAAAAAGAAAAAAAAAD+//9vAAAAAGADQAAA
AAAA////bwAAAAABAAAAAAAAAPD//28AAAAAVgNAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFAOYAAAAAAAAAAAAAAAAAAAAAAAAAAAAPYDQAAAAAAA
BgRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAR0NDOiAoVWJ1bnR1L0xpbmFybyA0LjYuMy0xdWJ1bnR1
NSkgNC42LjMAAC5zeW10YWIALnN0cnRhYgAuc2hzdHJ0YWIALmludGVycAAubm90ZS5BQkktdGFn
AC5ub3RlLmdudS5idWlsZC1pZAAuZ251Lmhhc2gALmR5bnN5bQAuZHluc3RyAC5nbnUudmVyc2lv
bgAuZ251LnZlcnNpb25fcgAucmVsYS5keW4ALnJlbGEucGx0AC5pbml0AC50ZXh0AC5maW5pAC5y
b2RhdGEALmVoX2ZyYW1lX2hkcgAuZWhfZnJhbWUALmN0b3JzAC5kdG9ycwAuamNyAC5keW5hbWlj
AC5nb3QALmdvdC5wbHQALmRhdGEALmJzcwAuY29tbWVudAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAGwAAAAEAAAACAAAAAAAA
ADgCQAAAAAAAOAIAAAAAAAAcAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAACMAAAAHAAAA
AgAAAAAAAABUAkAAAAAAAFQCAAAAAAAAIAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAAAx
AAAABwAAAAIAAAAAAAAAdAJAAAAAAAB0AgAAAAAAACQAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAA
AAAAAAAARAAAAPb//28CAAAAAAAAAJgCQAAAAAAAmAIAAAAAAAAcAAAAAAAAAAUAAAAAAAAACAAA
AAAAAAAAAAAAAAAAAE4AAAALAAAAAgAAAAAAAAC4AkAAAAAAALgCAAAAAAAAYAAAAAAAAAAGAAAA
AQAAAAgAAAAAAAAAGAAAAAAAAABWAAAAAwAAAAIAAAAAAAAAGANAAAAAAAAYAwAAAAAAAD0AAAAA
AAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAAXgAAAP///28CAAAAAAAAAFYDQAAAAAAAVgMAAAAA
AAAIAAAAAAAAAAUAAAAAAAAAAgAAAAAAAAACAAAAAAAAAGsAAAD+//9vAgAAAAAAAABgA0AAAAAA
AGADAAAAAAAAIAAAAAAAAAAGAAAAAQAAAAgAAAAAAAAAAAAAAAAAAAB6AAAABAAAAAIAAAAAAAAA
gANAAAAAAACAAwAAAAAAABgAAAAAAAAABQAAAAAAAAAIAAAAAAAAABgAAAAAAAAAhAAAAAQAAAAC
AAAAAAAAAJgDQAAAAAAAmAMAAAAAAAAwAAAAAAAAAAUAAAAMAAAACAAAAAAAAAAYAAAAAAAAAI4A
AAABAAAABgAAAAAAAADIA0AAAAAAAMgDAAAAAAAAGAAAAAAAAAAAAAAAAAAAAAQAAAAAAAAAAAAA
AAAAAACJAAAAAQAAAAYAAAAAAAAA4ANAAAAAAADgAwAAAAAAADAAAAAAAAAAAAAAAAAAAAAQAAAA
AAAAABAAAAAAAAAAlAAAAAEAAAAGAAAAAAAAABAEQAAAAAAAEAQAAAAAAADYAQAAAAAAAAAAAAAA
AAAAEAAAAAAAAAAAAAAAAAAAAJoAAAABAAAABgAAAAAAAADoBUAAAAAAAOgFAAAAAAAADgAAAAAA
AAAAAAAAAAAAAAQAAAAAAAAAAAAAAAAAAACgAAAAAQAAAAIAAAAAAAAA+AVAAAAAAAD4BQAAAAAA
ABAAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAAAAAAAqAAAAAEAAAACAAAAAAAAAAgGQAAAAAAA
CAYAAAAAAAAsAAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAAAAAALYAAAABAAAAAgAAAAAAAAA4
BkAAAAAAADgGAAAAAAAApAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAAAAAAAAAAAADAAAAAAQAAAAMA
AAAAAAAAKA5gAAAAAAAoDgAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAAxwAA
AAEAAAADAAAAAAAAADgOYAAAAAAAOA4AAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAA
AAAAAM4AAAABAAAAAwAAAAAAAABIDmAAAAAAAEgOAAAAAAAACAAAAAAAAAAAAAAAAAAAAAgAAAAA
AAAAAAAAAAAAAADTAAAABgAAAAMAAAAAAAAAUA5gAAAAAABQDgAAAAAAAJABAAAAAAAABgAAAAAA
AAAIAAAAAAAAABAAAAAAAAAA3AAAAAEAAAADAAAAAAAAAOAPYAAAAAAA4A8AAAAAAAAIAAAAAAAA
AAAAAAAAAAAACAAAAAAAAAAIAAAAAAAAAOEAAAABAAAAAwAAAAAAAADoD2AAAAAAAOgPAAAAAAAA
KAAAAAAAAAAAAAAAAAAAAAgAAAAAAAAACAAAAAAAAADqAAAAAQAAAAMAAAAAAAAAEBBgAAAAAAAQ
EAAAAAAAABAAAAAAAAAAAAAAAAAAAAAIAAAAAAAAAAAAAAAAAAAA8AAAAAgAAAADAAAAAAAAACAQ
YAAAAAAAIBAAAAAAAAAQAAAAAAAAAAAAAAAAAAAACAAAAAAAAAAAAAAAAAAAAPUAAAABAAAAMAAA
AAAAAAAAAAAAAAAAACAQAAAAAAAAKgAAAAAAAAAAAAAAAAAAAAEAAAAAAAAAAQAAAAAAAAARAAAA
AwAAAAAAAAAAAAAAAAAAAAAAAABKEAAAAAAAAP4AAAAAAAAAAAAAAAAAAAABAAAAAAAAAAAAAAAA
AAAAAQAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAyBgAAAAAAAAABgAAAAAAAB0AAAAuAAAACAAAAAAA
AAAYAAAAAAAAAAkAAAADAAAAAAAAAAAAAAAAAAAAAAAAAMgeAAAAAAAA8QEAAAAAAAAAAAAAAAAA
AAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAwABADgCQAAAAAAA
AAAAAAAAAAAAAAAAAwACAFQCQAAAAAAAAAAAAAAAAAAAAAAAAwADAHQCQAAAAAAAAAAAAAAAAAAA
AAAAAwAEAJgCQAAAAAAAAAAAAAAAAAAAAAAAAwAFALgCQAAAAAAAAAAAAAAAAAAAAAAAAwAGABgD
QAAAAAAAAAAAAAAAAAAAAAAAAwAHAFYDQAAAAAAAAAAAAAAAAAAAAAAAAwAIAGADQAAAAAAAAAAA
AAAAAAAAAAAAAwAJAIADQAAAAAAAAAAAAAAAAAAAAAAAAwAKAJgDQAAAAAAAAAAAAAAAAAAAAAAA
AwALAMgDQAAAAAAAAAAAAAAAAAAAAAAAAwAMAOADQAAAAAAAAAAAAAAAAAAAAAAAAwANABAEQAAA
AAAAAAAAAAAAAAAAAAAAAwAOAOgFQAAAAAAAAAAAAAAAAAAAAAAAAwAPAPgFQAAAAAAAAAAAAAAA
AAAAAAAAAwAQAAgGQAAAAAAAAAAAAAAAAAAAAAAAAwARADgGQAAAAAAAAAAAAAAAAAAAAAAAAwAS
ACgOYAAAAAAAAAAAAAAAAAAAAAAAAwATADgOYAAAAAAAAAAAAAAAAAAAAAAAAwAUAEgOYAAAAAAA
AAAAAAAAAAAAAAAAAwAVAFAOYAAAAAAAAAAAAAAAAAAAAAAAAwAWAOAPYAAAAAAAAAAAAAAAAAAA
AAAAAwAXAOgPYAAAAAAAAAAAAAAAAAAAAAAAAwAYABAQYAAAAAAAAAAAAAAAAAAAAAAAAwAZACAQ
YAAAAAAAAAAAAAAAAAAAAAAAAwAaAAAAAAAAAAAAAAAAAAAAAAABAAAAAgANADwEQAAAAAAAAAAA
AAAAAAARAAAABADx/wAAAAAAAAAAAAAAAAAAAAAcAAAAAQASACgOYAAAAAAAAAAAAAAAAAAqAAAA
AQATADgOYAAAAAAAAAAAAAAAAAA4AAAAAQAUAEgOYAAAAAAAAAAAAAAAAABFAAAAAgANAGAEQAAA
AAAAAAAAAAAAAABbAAAAAQAZACAQYAAAAAAAAQAAAAAAAABqAAAAAQAZACgQYAAAAAAACAAAAAAA
AAB4AAAAAgANANAEQAAAAAAAAAAAAAAAAAARAAAABADx/wAAAAAAAAAAAAAAAAAAAACEAAAAAQAS
ADAOYAAAAAAAAAAAAAAAAACRAAAAAQARANgGQAAAAAAAAAAAAAAAAACfAAAAAQAUAEgOYAAAAAAA
AAAAAAAAAACrAAAAAgANALAFQAAAAAAAAAAAAAAAAADBAAAABADx/wAAAAAAAAAAAAAAAAAAAADJ
AAAAAAASACQOYAAAAAAAAAAAAAAAAADaAAAAAQAVAFAOYAAAAAAAAAAAAAAAAADjAAAAAAASACQO
YAAAAAAAAAAAAAAAAAD2AAAAAQAXAOgPYAAAAAAAAAAAAAAAAAAMAQAAEgANAKAFQAAAAAAAAgAA
AAAAAAAcAQAAIAAYABAQYAAAAAAAAAAAAAAAAAAnAQAAEgAAAAAAAAAAAAAAAAAAAAAAAAA5AQAA
EADx/yAQYAAAAAAAAAAAAAAAAABAAQAAEgAOAOgFQAAAAAAAAAAAAAAAAABGAQAAEQITAEAOYAAA
AAAAAAAAAAAAAABTAQAAEgAAAAAAAAAAAAAAAAAAAAAAAAByAQAAEAAYABAQYAAAAAAAAAAAAAAA
AAB/AQAAIAAAAAAAAAAAAAAAAAAAAAAAAACOAQAAEQIYABgQYAAAAAAAAAAAAAAAAACbAQAAEQAP
APgFQAAAAAAABAAAAAAAAACqAQAAEgANABAFQAAAAAAAiQAAAAAAAAC6AQAAEADx/zAQYAAAAAAA
AAAAAAAAAAC/AQAAEgANABAEQAAAAAAAAAAAAAAAAADGAQAAEADx/yAQYAAAAAAAAAAAAAAAAADS
AQAAEgANAPQEQAAAAAAAEAAAAAAAAADXAQAAIAAAAAAAAAAAAAAAAAAAAAAAAADrAQAAEgALAMgD
QAAAAAAAAAAAAAAAAAAAY2FsbF9nbW9uX3N0YXJ0AGNydHN0dWZmLmMAX19DVE9SX0xJU1RfXwBf
X0RUT1JfTElTVF9fAF9fSkNSX0xJU1RfXwBfX2RvX2dsb2JhbF9kdG9yc19hdXgAY29tcGxldGVk
LjY1MzEAZHRvcl9pZHguNjUzMwBmcmFtZV9kdW1teQBfX0NUT1JfRU5EX18AX19GUkFNRV9FTkRf
XwBfX0pDUl9FTkRfXwBfX2RvX2dsb2JhbF9jdG9yc19hdXgAaGVsbG8uYwBfX2luaXRfYXJyYXlf
ZW5kAF9EWU5BTUlDAF9faW5pdF9hcnJheV9zdGFydABfR0xPQkFMX09GRlNFVF9UQUJMRV8AX19s
aWJjX2NzdV9maW5pAGRhdGFfc3RhcnQAcHV0c0BAR0xJQkNfMi4yLjUAX2VkYXRhAF9maW5pAF9f
RFRPUl9FTkRfXwBfX2xpYmNfc3RhcnRfbWFpbkBAR0xJQkNfMi4yLjUAX19kYXRhX3N0YXJ0AF9f
Z21vbl9zdGFydF9fAF9fZHNvX2hhbmRsZQBfSU9fc3RkaW5fdXNlZABfX2xpYmNfY3N1X2luaXQA
X2VuZABfc3RhcnQAX19ic3Nfc3RhcnQAbWFpbgBfSnZfUmVnaXN0ZXJDbGFzc2VzAF9pbml0AA==
EOLZ
return $b;
}

done_testing();
