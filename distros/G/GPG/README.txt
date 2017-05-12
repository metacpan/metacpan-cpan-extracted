NAME
    GPG - a Perl2GnuPG interface

DESCRIPTION
    GPG.pm is a Perl5 interface for using GnuPG. GPG works with
    $scalar (string), as opposed to the existing Perl5 modules
    (GnuPG.pm and GnuPG::Interface, which communicate with gnupg
    through filehandles or filenames)

SYNOPSIS
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

INSTALLATION
     % perl Makefile.PL
     % make
     % make test
     % make install

      Tips :
      - if you want secure memory, do not forget :
        % chown root /usr/local/bin/gpg ; chmod 4755 /usr/local/bin/gpg

METHODS
    Look at the "test.pl" and "quick_test.pl" for examples and
    futher explanations.

    You can set "VERBOSE" in "test.pl" to "1" and restart the test,
    to see more extensive output.

    *new %params*
         Parameters are :
         - gnupg_path (most of time, 'gpg' stand inside /usr/local/bin)
         - homedir (gnupg homedir, default is $HOME/.gnupg)
         - config (gnupg config file)
         - armor (armored if 1, DEFAULT IS *1* !)
         - debug (1 for debugging, default is 0)

    *gen_key %params*
         Parameters are :
         - key_size (see gnupg doc)
         - real_name (usually first name and last name, must not be empty)
         - email (email address, must not be empty)
         - comment (may be empty)
         - passphrase (*SHOULD* be at least 16 chars long...)

        Please note that the keys are not imported after creation,
        please read "test.pl" for an example, or read the
        description of the "list_packets" method.

    *list_packets $packet*
        Output a packet description for public and secret keys, run
        "test.pl" with "VERBOSE=1" for a better description.

    *import_keys $key*
        Import the key(s) into the current keyring.

    *clearsign $key_id, $passphrase, $text*
        Clearsign the current text.

    *detach_sign $key_id, $passphrase, $text*
        Make a detached signature of the current text.

    *verify $signed_text*
        Verify a signature.

    *verify_files $signed_text*
        Verify signature of a all files from stdin, faster than
        verify() method.

    *encrypt $text, ($dest_1, ...)*
        Encrypt.

    *decrypt $passphrase, $text*
        Decrypt (yes, really).

    *sign_encrypt $key_id, $passphrase, $text, ($dest_1, ...)*
        Sign and Encrypt.

    *decrypt_verify $passphrase, $text*
        Decrypt and verify signature.

    *list_keys()*
        List all keys from your standard pubring

    *list_sig()*
        List all keys and signatures from your standard pubring

    *delete_secret_key $key_id*
        No yet implemented, gnupg doesn't accpt this in batch mode.

    *delete_key $key_id*
        No yet implemented, gnupg doesn't accept this in batch mode.

FAQ
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

KNOWN BUGS
    Currently known bugs are caused by gnupg (www.gnupg.org) and
    *not* by GPG.pm :

     - the methods "delete_key" and "delete_secret_key" do not work, 
       Not because of a bug but because gnupg cannot do that in batch mode.
     - sign_key() and lsign_key() : "gpg: can't do that in batchmode"
     - verify() and verify_files() output only the wrong file, even only one has
       a wrong signature. Other files are ignored.

    I hope a later version of gnupg will correct this issues...

TODO
     see CHANGES.txt.

     most of awaiting changes cannot be done until gnupg itself
     get an extented batch mode (currently very limited)

SUPPORT
    Feel free to send me your questions and comments.

    Feedback is ALWAYS welcome !

    Commercial support on demand, but for most problems read the
    "Support" section on http://www.gnupg.org.

DOWNLOAD
    CPAN : ${CPAN}/authors/id/M/MI/MILES/

    sourceforge :
    https://sourceforge.net/project/filelist.php?group_id=8630

    developpers info at https://sourceforge.net/projects/gpg

    doc and home-page at http://gpg.sourceforge.net/ (this document)

DEVELOPPEMENT
     CVS access :
     
     look at http://acity.sourceforge.net/devel.html
     ... and replace "agora" or "acity" by "gpg".

SEE ALSO
     GnuPG            - http://www.gnupg.org
     GnuPG.pm         - input/output only through file_names
     GnuPG::Interface - input/output only through file_handles
                        see http://GnuPG-Interface.sourceforge.net/ or CPAN
     IPC::Open3       - communication with 'gpg', see "perldoc perlipc"

AUTHOR
     miles@_REMOVE_THIS_users.sourceforge.net, pf@_REMOVE_THIS_spin.ch
     extra thanks to tpo_at_spin

