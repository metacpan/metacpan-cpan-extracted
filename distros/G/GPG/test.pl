#!/usr/bin/perl -w
use strict;
use Data::Dumper;

  use GPG;

  my $VERBOSE = 0;
  my $DEBUG   = 0;

  my @test = qw/ new gen_key list_packets 
                 import_keys fast_import update_trustdb
                 fingerprint export_key export_secret_key
                 clearsign detach_sign verify verify_files
                 encrypt decrypt
                 sign_encrypt decrypt_verify 
                 list_keys list_sig /;
               #  sign_key lsign_key : gpg: can't do that in batchmode
               #  delete_secret_key delete_key /; can *not* be implemented - read the doc please

  my $gpg;
  my ($pubring,$secring,$signed) = ('','');
  my $passphrase = '1234567890123456';
  my $key_id     = '';
  my $TEST_TEXT  = "this is a text to encrypt/decrypt/sign/etc.\nand a second line...";

  test();

######################################################

  sub verbose { my ($msg) = @_;
    print "\n\n$msg\n------------------------------------------\n" if $VERBOSE;
  }

  sub test {
    my ($count,$failed) = (0,0);
    local $| = 1;
    for my $i (@test) {
      no strict 'refs';
      print "test ",sprintf("%2d",$count)," $i",substr("....................",0,(20-length($i)));
      eval { &$i };
      if($@) { 
        chomp($@);
        print " NOT ok -- $@\n";
        $failed++;
      }
      else {
        print " ok.\n";
      }
      $count++;
    }
    if ($failed == 0) {
      print "All $count test passed successfully.\n";
    }
    else {
      printf "Failed $failed test on $count (%2.2d \%).\n", 100 / $count * $failed;
    }
  }


######################################################

  sub new {
    $gpg = new GPG(homedir => './test',
                   armor   => '1',
                   debug   => $DEBUG);
    die $gpg->error() if $gpg->error();
    verbose("New GPG object successfully created");
  }

  sub gen_key {
    ($pubring,$secring) = $gpg->gen_key(key_size   => "512",
                                        real_name  => "Joe Test",
                                        email      => 'nobody@yahoo.com',
                                        comment    => "",
                                        passphrase => $passphrase);
    die $gpg->error() if $gpg->error();
    verbose("----> pubring:\n$pubring\n----> secring:\n$secring");
  }

  sub list_packets {
    my $packet = $gpg->list_packets($pubring.$secring);
    
    die $gpg->error() if $gpg->error();
    $key_id = $packet->[0]{'key_id'};
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$packet]);
      verbose($dump->Dump);
    }
  }

  sub import_keys {
    my $imported = $gpg->import_keys($pubring.$secring);
    die $gpg->error() if $gpg->error();
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$imported]);
      verbose("Keys imported :\n".$dump->Dump);
    }
  }

  sub fast_import {
    my $fast_import = $gpg->fast_import($pubring."\n".$secring);
    die $gpg->error() if $gpg->error();
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$fast_import]);
      verbose("Keys imported :\n".$dump->Dump);
    }
  }

  sub update_trustdb {
    my $updated = $gpg->update_trustdb();
    die $gpg->error() if $gpg->error();
    verbose("Ok: $updated key(s) updated into trustdb.");
  }

  sub fingerprint {
    my $fingerprint = $gpg->fingerprint($key_id);
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$fingerprint]);
      verbose("Fingerprint :\n".$dump->Dump);
    }
  }

  sub sign_key {
    my $sign = $gpg->sign_key($key_id,$passphrase,$key_id);
    verbose("signed key :\n$sign");
  }

  sub lsign_key {
    ; # not yet implemented
  }

  sub export_key {
    my $export_public = $gpg->export_key($key_id);
    verbose("Exported public key :\n$export_public");
  }

  sub export_secret_key {
    my $export_secret = $gpg->export_secret_key($key_id);
    verbose("Exported secret key :\n$export_secret");
  }

  sub clearsign { 
    $signed = $gpg->clearsign($key_id,$passphrase,$TEST_TEXT);
    verbose("signed text :\n$signed");
  }

  sub detach_sign  { 
    my $sign = $gpg->detach_sign($key_id,$passphrase,$TEST_TEXT);
    verbose("detached signature :\n$sign");
  }

  sub verify {
    my $verify = $gpg->verify($signed);
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$verify]);
      verbose($dump->Dump);
    }
  }

  sub verify_files {
    my $wrong_signature = substr($signed,0,60).'xx'.substr($signed,60);
    my $verify = $gpg->verify_files($signed);
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$verify]);
      verbose($dump->Dump);
    }
  }

  sub encrypt {
    $TEST_TEXT = $gpg->encrypt($TEST_TEXT,$key_id);
    verbose("encrypted text :\n$TEST_TEXT");
  }

  sub decrypt {
    $TEST_TEXT = $gpg->decrypt($passphrase,$TEST_TEXT);
    verbose("decrypted text :\n$TEST_TEXT");
  }

  sub sign_encrypt {
    $TEST_TEXT = $gpg->sign_encrypt($key_id,$passphrase,$TEST_TEXT,$key_id);
    verbose("signed and encrypted text :\n$TEST_TEXT");
  }

  sub decrypt_verify {
    my $decrypt_verify = $gpg->decrypt_verify($passphrase,$TEST_TEXT);
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$decrypt_verify]);
      verbose($dump->Dump);
    }
  }

  sub list_keys {
    my $list_keys = $gpg->list_keys();
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$list_keys]);
      verbose($dump->Dump);
    }
  }

  sub list_sig {
    my $list_sig = $gpg->list_sig();
    if ($VERBOSE) {
      my $dump = Data::Dumper->new([$list_sig]);
      verbose($dump->Dump);
    }
  }

  sub delete_secret_key {
    $gpg->delete_secret_key($key_id);
    verbose("secret key removed from key_ring");
  }

  sub delete_key {
    $gpg->delete_key($key_id);
    verbose("public key removed from key_ring");
  }


# End of 'test.pl'.
