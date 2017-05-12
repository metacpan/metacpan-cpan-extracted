#!/usr/bin/perl -w
use strict;

  use GPG;

    my ($passphrase,$key_id) = ("1234567890123456",'');

  my $gpg = new GPG(homedir  => './test'); # Creation

  die     $gpg->error() if $gpg->error();    # Error ?
  warning $gpg->warn()  if $gpg->warning();  # Warning ?

  my ($pubring,$secring) = $gpg->gen_key(key_size => "512",
                                        real_name  => "Joe Test",
                                        email      => 'nobody@yahoo.com',
                                        comment    => "",
                                        passphrase => $passphrase);

  my $pubkey = $gpg->list_packets($pubring);
  my $seckey = $gpg->list_packets($secring);
     $key_id = $pubkey->[0]{'key_id'};

  # After creating a public/secret key pair, you *MUST* import them
  # if you want to use this key...
  $gpg->import_keys($secring);
  $gpg->import_keys($pubring);


  # encrypt & sign operations

  my $signed           = $gpg->clearsign($key_id,$passphrase,"TEST_TEXT");
  my $encrypted        = $gpg->encrypt("TEST_TEXT",$key_id);
  my $signed_encrypted = $gpg->sign_encrypt($key_id,$passphrase,"TEST_TEXT",$key_id);

  # decrypt * verify operations
  # $checked->{'ok'}
  # $checked->{'key_user'}
  # $checked->{'key_id'}
  # $checked->{'sig_date'}
  # $checked->{'clr_text'}
  #
  # ATTENTION - depending on operation not all variables are set!

  my $verify         = $gpg->verify($signed);
  my $decrypt        = $gpg->decrypt($passphrase,$encrypted);
  my $decrypt_verify = $gpg->decrypt_verify($passphrase,$signed_encrypted);


# End.
