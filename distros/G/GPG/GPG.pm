package GPG;
use strict;

  use vars qw/$VERSION/;
  $VERSION = "0.05";

  use IO::Handle;
  use IPC::Open3;

  my $GNUPG_PATH = '/usr/local/bin';

  sub new ($%) { my ($this,%params) = @_;
    my $class = ref($this) || $this;
    my $self  = {};
       $self->{'gnupg_path'}  = $params{'gnupg_path'}  || $GNUPG_PATH;
       $self->{'homedir'}     = $params{'homedir'}     || $ENV{'HOME'}.'/.gnupg';
       $self->{'config'}      = $params{'config'}      || '';
       $self->{'armor'}       = $params{'armor'}       || '1'; # Default IS armored !
       $self->{'debug'}       = $params{'debug'}       || '';

       $self->{'COMMAND'}  = "$self->{'gnupg_path'}/gpg";
       $self->{'COMMAND'} .= " -a"                           if $self->{'armor'};
       $self->{'COMMAND'} .= " --config  $self->{'config'}"  if $self->{'config'};
       $self->{'COMMAND'} .= " --homedir $self->{'homedir'}" if $self->{'homedir'};
       $self->{'COMMAND'} .= " --batch";
       $self->{'COMMAND'} .= " --no-comment";
       $self->{'COMMAND'} .= " --no-version";
       $self->{'COMMAND'} .= ' '; # so i dont forget the spaces later :-)

      if ($self->{'debug'}) {
        print "\n********************************************************************\n";
        print "COMMAND : $self->{'COMMAND'}\n";
        print "\$self->{'homedir'} : $self->{'homedir'}\n";
        print "\$self->{'config'} :  $self->{'config'}\n";
        print "\$self->{'armor'} :   $self->{'armor'}\n";
        print "\$self->{'debug'} :   $self->{'debug'}\n";
        print "********************************************************************\n";
      }

    $self->{'warning'} = '';

    bless $self, $class;
    return $self;
  }

  sub gnupg_path { my ($this,$value) = @_; $this->{gnupg_path} = $value; }
  sub homedir    { my ($this,$value) = @_; $this->{homedir}    = $value; }
  sub config     { my ($this,$value) = @_; $this->{config}     = $value; }
  sub armor      { my ($this,$value) = @_; $this->{armor}      = $value; }
  sub debug      { my ($this,$value) = @_; $this->{debug}      = $value; }

    # error() : get/set errors
    sub error { my ($this,$string) = @_;
      if ($string) {
        $this->{'error'} = $this->{'error'} ? "$this->{'error'}\n$string" : $string;
      }
      else {
        return $this->{'error'} || '';
      }
    }

    # warning() : same code as for error(), but otherwise :-)
    sub warning { my ($this,$string) = @_;
      $string 
      ? $this->{'warning'} 
        ? $this->{'warning'} .= "\n$string"
        : $this->{'warning'}  = "$string"
      : return $this->{'warning'} || '';
    }

    sub start_gpg { my ($this,$command,$input) = @_;
      my ($stdin,$stdout,$stderr) = (IO::Handle->new(),IO::Handle->new(),IO::Handle->new());
      my $pid = open3($stdin,$stdout,$stderr, $command);
      if (!$pid) {
        $this->error("Cannot fork [COMMAND: '$command'].");
        return (0);
      }

      print $stdin $input;
      close $stdin;

      my $output = join('',<$stdout>);
      close $stdout;

      my $error = join('',<$stderr>);
      close $stderr;

      wait();

      if ($error =~ /Warning/m) {
        $this->{'warning'} .= "Warning: using insecure memory!";
        $error =~ s/\n?.*using insecure memory.*\n?\s*//m;
        # add new warning messages from gnupg here...
      }


      if ($this->{'debug'}) {
        print "\n********************************************************************\n";
        print "COMMAND : \n$command [PID $pid]\n";
        print "STDIN  :  \n$input\n";
        print "STDOUT :  \n$output\n";
        print "WARNING : \n$this->{'warning'}\n";
        print "STDERR :  \n$error\n";
        print "\n********************************************************************\n";
      }

      return($pid,$output,$error);
    }


### gen_key #####################################################

  sub gen_key($%) { my ($this,%params) = @_;
    my $key_size   = $params{'key_size'};
    $this->error("no key_size defined !")   and return if !$key_size;
    my $real_name  = $params{'real_name'};
    $this->error("no real_name defined !")  and return if !$real_name;
    my $email      = $params{'email'};
    $this->error("no email defined !")      and return if !$email;
    my $comment    = $params{'comment'} || '';
    my $passphrase = $params{'passphrase'};
    $this->error("no passphrase defined !") and return if !$passphrase;

    srand();
    my $tmp_filename = $this->{homedir}."/tmp_".sprintf("%08d",int(rand()*100000000));

    my $pubring    = "$tmp_filename.pub";
    my $secring    = "$tmp_filename.sec";

    my $script = '';
       $script .= "Key-Type: 20\n";
       $script .= "Key-Length: $key_size\n";
       $script .= "Name-Real: $real_name\n";
       $script .= "Name-Comment: $comment\n" if $comment;
       $script .= "Name-Email: $email\n";
       $script .= "Expire-Date: 0\n";
       $script .= "Passphrase: $passphrase\n";
       $script .= "\%pubring $pubring\n";
       $script .= "\%secring $secring\n";
       $script .= "\%commit\n";

    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.' --gen-key', $script);
    return if !$pid;

    # output of "gen_key" comes on stderr, we cannot stop here...
    #$this->error($error) and return if $error;

    open(*PUBRING,"$pubring");
    my @pubring = <PUBRING>;
    close PUBRING;
    unlink "$pubring" || die "cannot unlink '$pubring'";
    open(*SECRING,"$secring");
    my @secring= <SECRING>;
    close SECRING;
    unlink "$secring" || die "cannot unlink '$secring'";;

    return(join('',@pubring),join('',@secring));
  }


### list_packets ################################################

  sub list_packets {  my ($this,$string) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.' --list-packets', $string);
    return if !$pid;

    return [] if $output !~ /^\s*\:\S+ key packet\:/; # no key found.

    $output =~ s/^\s*\:\S+ key packet\:\s*//;
    my @pubkeys = split(/\s*\n\:\S+ key packet\:\s*/,$output);
    my $res = [];
    for my $i (@pubkeys) { # for each keys found...
      my $hash = {};
      my @part = split(/\s*\n\:signature packet\:\s*/,$i);
      my $key  = shift @part;
      $key               =~ / created (\d+)/;
      $hash->{created}   =  $1 if $1;
      $key               =~ /\:user ID packet\: \"(.*)\"/;
      $hash->{user_id}   =  $1 if $1;
      $hash->{user_name} =  $hash->{user_id};
      $hash->{user_name} =~ s/\s[\(\<].*$//;
      $hash->{user_id}   =~ /\s\<(.*)\>$/;
      $hash->{user_mail} =  $1 if $1;
      $hash->{sig}       =  [];
      $key               =~ /\s(\w)key\[0\]\: \[(\d+) bits\]\s+/;
      $hash->{key_type}  =  'public' if $1 and $1 eq 'p';
      $hash->{key_type}  =  'secret' if $1 and $1 eq 's';
      $hash->{key_size}  =  $2 if $2;
      for my $j (@part) { # for all key_sig...
        my $sub_hash = {};
        $j                   =~ / keyid (\S*)\s/;
        $sub_hash->{key_id}  =  $1 if $1;
        $j                   =~ / created (\d*)\s/;
        $sub_hash->{created} =  $1 if $1;
        push @{$hash->{sig}},$sub_hash;
      }
      $hash->{key_id} = $hash->{sig}[0]{key_id};
      push @$res, $hash;
    }
    return $res;
  }


### import #################################################

    sub read_import_key_result { my ($msg) = @_;
      my $ret = {};
         $ret->{total_ok}    = 0;
         $ret->{total_found} = 0;
         $ret->{secret}      = [];
         $ret->{public}      = [];

      my @secret = grep(/secret key imported/,$msg);
      for my $i (@secret) {
        $i =~ /.*\skey\s(\w+)\:\ssecret key imported/;
        push @{$ret->{secret}}, $1 and $ret->{total_ok}++ if $1;
        
      }

      my @public = grep(/public key imported/,$msg);
      for my $i (@public) {
        $i =~ /.*\skey\s(\w+)\:\spublic key imported/;
        push @{$ret->{public}}, $1 and $ret->{total_ok}++ if $1;
      }

      $msg =~ /Total number processed\:\s+(\d+)\s/;
      $ret->{total_found} = $1 if $1;

      return $ret;
    }

  # import is a Perl reserved keyword, sorry...
  sub import_keys { my ($this,$import) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.' --import', $import);
    return if !$pid;

    my $res = read_import_key_result($error);
    #$this->error($error) and return if !$res;

    return $res;
  }

  sub fast_import { my ($this,$import) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.' --fast-import', $import);
    return if !$pid;

    my $res = read_import_key_result($error);
    #$this->error($error) and return if !$res;

    return $res;
  }

  sub update_trustdb { my ($this) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.' --update-trustdb', '');
    return if !$pid;

    $error =~ s/^gpg: (\d+) keys processed\s*//;
    my $number_processed = $1 || '0';

    $this->error($error) and return if $error;
    return $number_processed;
  }

### fingerprint ############################################

  sub fingerprint { my ($this,$key_id) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--fingerprint $key_id", "");
    return if !$pid;
    $this->error($error) and return if $error;

    my $fingerprint = [];
    my @text = split(/\s*\n/,$output);

    for(my $i = 0; $i < $#text; $i++) {
      if ($text[$i] =~ /^pub\s+.*\/(\w+)\s+\S+\s+(.*)\s*$/) {
        my $hash = {};
        $hash->{'key_id'}   =  $1 if $1;
        $hash->{'key_name'} =  $2 if $2;

        $text[$i+1]            =~ /^\s+Key fingerprint = (.*)\s*$/m;
        $hash->{'fingerprint'} =  $1 if $1;
        push @$fingerprint, $hash;
        $i++;
      }
    }

    return $fingerprint;
  }


### sign_key ###############################################

  sub sign_key { my ($this,$key_id,$passphrase,$key_to_sign) = @_;
    return "gpg: can't do that in batchmode (thanks gnupg...)";
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0 --default-key $key_id --sign-key $key_to_sign","$passphrase");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }

  sub lsign_key { my ($this,$key_id) = @_;
    return "gpg: can't do that in batchmode (thanks gnupg...)";
  }


### export_key #############################################

  sub export_key { my ($this,$key_id) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--export-all $key_id", "");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }

  sub export_secret_key { my ($this,$key_id) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--export-secret-key $key_id", "");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### clearsign ##############################################

  sub clearsign { my ($this,$key_id,$passphrase,$text) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0 --default-key $key_id --clearsign", "$passphrase\n$text");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### detach_sign ############################################

  sub detach_sign { my ($this,$key_id,$passphrase,$text) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0 --default-key $key_id --detach-sign", "$passphrase\n$text");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### verify #################################################

    sub check_verify_result { my ($text) = @_;
      my $verify = [];
      my @text = split(/\s*\n/,$text);
      for(my $i = 0; $i < $#text; $i++) {
        if ($text[$i] =~ /\sSignature made (.*) using (\w+) key ID (\w+)\s*/) {
          my $hash = {};
          $hash->{'sig_date'} =  $1 if $1;
          $hash->{'algo'}     =  $2 if $2;
          $hash->{'key_id'}   =  $3 if $3;

          $hash->{'ok'}       =  $text[$i+1] =~ /\sGood signature from \"/m ? 1 : 0;
          $text[$i+1]         =~ / signature from \"(.*)\"\s*/m;
          $hash->{'key_user'} =  $1 if $1;
          push @$verify, $hash;
          $i++;
        }
      }

      return $verify;
    }

  sub verify { my ($this,$string) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--verify", "$string");
    return if !$pid;

    return check_verify_result($error);
  }

### verify_files ###########################################

  sub verify_files { my ($this,$string) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--verify", "$string");
    return if !$pid;

    return check_verify_result($error);
  }


### encrypt ################################################

  sub encrypt { my ($this,$text,@dest) = @_;
    my $dest = '-r '.join(' -r ',@dest);
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "$dest --encrypt", "$text");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### decrypt ################################################

  sub decrypt { my ($this,$passphrase,$text) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0 --decrypt", "$passphrase\n$text");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### sign_encrypt ###########################################

  sub sign_encrypt { my ($this,$key_id,$passphrase,$text,@dest) = @_;
    my $dest = '-r '.join(' -r ',@dest);
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0 $dest --default-key $key_id -se", "$passphrase\n$text");
    return if !$pid;

    $this->error($error) and return if $error;
    return $output;
  }


### decrypt_verify #########################################

  sub decrypt_verify { my ($this,$passphrase,$text) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0", "$passphrase\n$text");
    return if !$pid;

    my $verify = {};
    $verify->{'ok'}       =  $error =~ /\sGood signature from \"/m ? 1 : 0;
    $error                =~ / signature from \"(.*)\"\s/m;
    $verify->{'key_user'} =  $1 if $1;
    $error                =~ /\susing \w+ key ID (\w+)\s/m;
    $verify->{'key_id'}   =  $1 if $1;
    $error                =~ /\sSignature made (.*) using\s/m;
    $verify->{'sig_date'} =  $1 if $1;

    $verify->{'text'}     = $output;

    return $verify;
  }

### list_keys ##############################################

    sub build_list_keys { my ($text) = @_;
      my $list = [];
      my $last_key_sig = [];
      for my $i (split(/\n/,$text)) {
        my @line = split(/\:/,$i);
        next if @line < 3; # not a descriptor line...

        my $hash = {};
        $hash->{'type'}       = $line[0];
        $hash->{'trust'}      = $line[1];
        $hash->{'key_size'}   = $line[2];
        $hash->{'algo'}       = $line[3];
        $hash->{'key_id'}     = $line[4];
        $hash->{'created'}    = $line[5];
        $hash->{'expiration'} = $line[6];
        $hash->{'local_id'}   = $line[7];
        $hash->{'ownertrust'} = $line[8];
        $hash->{'user_id'}    = $line[9];

        $hash->{'trust'} = 0 if !$line[1] || ($line[1] ne 'm' && $line[1] ne 'f' && $line[1] ne 'u'); # no trust
        $hash->{'sig'}   = []  and $last_key_sig = $hash->{'sig'} if $hash->{'type'} ne 'sig';
        push @$last_key_sig,$hash and next if $hash->{'type'} eq 'sig';
        
        push @$list,$hash;
      }
      return $list;
    }

  sub list_keys { my ($this) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--with-colons --list-keys", "");
    return if !$pid;
    $this->error($error) and return if $error;

    return build_list_keys($output);
  }


### list_sig ##############################################

  sub list_sig { my ($this) = @_;
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--with-colons --list-sig", "");
    return if !$pid;
    $this->error($error) and return if $error;
    return build_list_keys($output);
  }


### PROTOTYPE ##############################################

  sub prototype { my ($this) = @_;
    return; # XXX 'prototype' : only as example if you would add new function
    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--passphrase-fd 0", "passphrase here...");
    return if !$pid;
    $this->error($error) and return if $error;

    return $output;
  }


### delete_key #############################################

  sub delete_key { my ($this,$key_id) = @_;
    CORE::warn "Not yet implemented - read the doc please." and return;

    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--delete-key $key_id", "y\n");
    return if !$pid;

    $this->error($error) and return if $error;
  }


### delete_secret_key ######################################

  sub delete_secret_key { my ($this,$key_id) = @_;
    CORE::warn "Not yet implemented - read the doc please." and return;

    my ($pid,$output,$error) = start_gpg($this,$this->{'COMMAND'}.
         "--delete-secret-key $key_id", "y\n");
    return if !$pid;

    $this->error($error) and return if $error;
  }


=head1 NAME

GPG - a Perl2GnuPG interface

=head1 DESCRIPTION

GPG.pm is a Perl5 interface for using GnuPG. GPG works with $scalar (string), 
as opposed to the existing Perl5 modules (GnuPG.pm and GnuPG::Interface, which
communicate with gnupg through filehandles or filenames)


=head1 SYNOPSIS

  use GPG;

    my ($passphrase,$key_id) = ("1234567890123456",'');

  my $gpg = new GPG(homedir  => './test'); # Creation

  die $gpg->error() if $gpg->error(); # Error handling

  my ($pubring,$secring) = $gpg->gen_key(key_size => "512",
                                        real_name  => "Joe Test",
                                        email      => 'nobody@yahoo.com',
                                        comment    => "",
                                        passphrase => $passphrase);

  my $pubkey = $gpg->list_packets($pubring);
  my $seckey = $gpg->list_packets($secring);
  $key_id = $pubkey->[0]{'key_id'};


  $gpg->import_keys($secring);
  $gpg->import_keys($pubring);

  my $signed = $gpg->clearsign($key_id,$passphrase,"TEST_TEXT");
  my $verify = $gpg->verify($signed);

  my $TEST_TEXT = $gpg->encrypt("TEST_TEXT",$key_id);
     $TEST_TEXT = $gpg->decrypt($passphrase,$TEST_TEXT);

     $TEST_TEXT = $gpg->sign_encrypt($key_id,$passphrase,$TEST_TEXT,$key_id);
  my $decrypt_verify = $gpg->decrypt_verify($passphrase,$TEST_TEXT);

  my $keys = $gpg->list_keys();
  my $sigd = $gpg->list_sig();


=head1 INSTALLATION

 % perl Makefile.PL
 % make
 % make test
 % make install

  Tips :
  - if you want secure memory, do not forget :
    % chown root /usr/local/bin/gpg ; chmod 4755 /usr/local/bin/gpg

=head1 METHODS

Look at the "test.pl" and "quick_test.pl" for examples and futher explanations.

You can set "VERBOSE" in "test.pl" to "1"  and restart the test, to see more extensive output.

=over 4

=item I<new %params>

 Parameters are :
 - gnupg_path (most of time, 'gpg' stand inside /usr/local/bin)
 - homedir (gnupg homedir, default is $HOME/.gnupg)
 - config (gnupg config file)
 - armor (armored if 1, DEFAULT IS *1* !)
 - debug (1 for debugging, default is 0)

=item I<gen_key %params>

 Parameters are :
 - key_size (see gnupg doc)
 - real_name (usually first name and last name, must not be empty)
 - email (email address, must not be empty)
 - comment (may be empty)
 - passphrase (*SHOULD* be at least 16 chars long...)

Please note that the keys are not imported after creation, please read "test.pl" for an example,
or read the description of the "list_packets" method.

=item I<list_packets $packet>

Output a packet description for public and secret keys, run "test.pl"
with "VERBOSE=1" for a better description.

=item I<import_keys $key>

Import the key(s) into the current keyring.

=item I<clearsign $key_id, $passphrase, $text>

Clearsign the current text.

=item I<detach_sign $key_id, $passphrase, $text>

Make a detached signature of the current text.

=item I<verify $signed_text>

Verify a signature.

=item I<verify_files $signed_text>

Verify signature of a all files from stdin, faster than verify() method.

=item I<encrypt $text, ($dest_1, ...)>

Encrypt.

=item I<decrypt $passphrase, $text>

Decrypt (yes, really).

=item I<sign_encrypt $key_id, $passphrase, $text, ($dest_1, ...)>

Sign and Encrypt.

=item I<decrypt_verify $passphrase, $text>

Decrypt and verify signature.

=item I<list_keys()>

List all keys from your standard pubring

=item I<list_sig()>

List all keys and signatures from your standard pubring

=item I<delete_secret_key $key_id>

No yet implemented, gnupg doesn't accpt this in batch mode.

=item I<delete_key $key_id>

No yet implemented, gnupg doesn't accept this in batch mode.

=back

=head1 FAQ

 Q: How does it work ?
 A: it uses IPC::Open3 to connect the 'gpg' program. 
IPC::Open3 is executing the fork and managing the filehandles for you.

  Q: How secure is GPG ?
  A: As secure as you want... Be carefull. First, GPG is no 
more securer than 'gpg'. 
Second, all passphrases are stored in non-secure memory, unless
you "chown root" and "chmod 4755" your script first. Third, your
script probably store passpharses somewhere on the disk, and 
this is *not* secure.

  Q: Why using GPG, and not GnuPG or GnuPG::Interface ??
  A: Because of their input/output facilities, 
GnuPG.pm only works on filenames. 
GnuPG::Interface works with fileshandles, but is hard to use - all filehandle
management is left up to the user. GPG is working with $scalar only for both
input and output. Since I am developing for a web interface, I don't want to
write new files each time I need to communicate with gnupg.


=head1 KNOWN BUGS

Currently known bugs are caused by gnupg (www.gnupg.org) and *not* by GPG.pm :

 - the methods "delete_key" and "delete_secret_key" do not work, 
   Not because of a bug but because gnupg cannot do that in batch mode.
 - sign_key() and lsign_key() : "gpg: can't do that in batchmode"
 - verify() and verify_files() output only the wrong file, even only one has
   a wrong signature. Other files are ignored.

I hope a later version of gnupg will correct this issues...

=head1 TODO

 see CHANGES.txt.

 most of awaiting changes cannot be done until gnupg itself
 get an extented batch mode (currently very limited)

=head1 SUPPORT

Feel free to send me your questions and comments.

Feedback is ALWAYS welcome !

Commercial support on demand, but for most problems read the "Support" section
on http://www.gnupg.org.

=head1 DOWNLOAD

CPAN : ${CPAN}/authors/id/M/MI/MILES/

sourceforge : https://sourceforge.net/project/filelist.php?group_id=8630

developpers info at https://sourceforge.net/projects/gpg

doc and home-page at http://gpg.sourceforge.net/ (this document)

=head1 DEVELOPPEMENT

 CVS access :
 
 look at http://acity.sourceforge.net/devel.html
 ... and replace "agora" or "acity" by "gpg".


=head1 SEE ALSO

 GnuPG            - http://www.gnupg.org
 GnuPG.pm         - input/output only through file_names
 GnuPG::Interface - input/output only through file_handles
                    see http://GnuPG-Interface.sourceforge.net/ or CPAN
 IPC::Open3       - communication with 'gpg', see "perldoc perlipc"

=head1 AUTHOR

 miles@_REMOVE_THIS_users.sourceforge.net, pf@_REMOVE_THIS_spin.ch
 extra thanks to tpo_at_spin

=cut
1; # End.
