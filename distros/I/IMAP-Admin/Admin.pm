# IMAP::Admin - perl module for helping ease the administration of imap servers

package IMAP::Admin;

use strict;
use Carp;
use IO::Select;
use IO::Socket;
#use IO::Socket::INET;
use Cwd;

use vars qw($VERSION);

$VERSION = '1.6.8';

sub new {
  my $class = shift;
  my $self = {};
  my @defaults = (
                  'Port' => 143,
                  'Separator' => '.',
                  'CRAM' => 0,
                  );

  bless $self, $class;
  if ((scalar(@_) % 2) != 0) {
    croak "$class called with incorrect number of arguments";
  }
  unshift @_, @defaults;
  %{$self} = @_; # set up parameters;
  $self->{'CLASS'} = $class;
  $self->_initialize;
  return $self;
}

sub _initialize {
  my $self = shift;

  if (!defined($self->{'Server'})) {
    croak "$self->{'CLASS'} not initialized properly : Server parameter missing";
  }
  if (!defined($self->{'Login'})) {
    croak "$self->{'CLASS'} not initialized properly : Login parameter missing";
  }
  if (!defined($self->{'Password'})) {
    croak "$self->{'CLASS'} not initialized properly : Password parameter missing";
  }
  if ($self->{'CRAM'} != 0) {
      my $cram_try = "use Digest::HMAC; use Digest::MD5; use MIME::Base64;";
      eval $cram_try;
  }
  if (defined($self->{'SSL'})) { # attempt SSL connection instead
    # construct array of ssl options
    my $cwd = cwd;
    my %ssl_defaults = (
                        'SSL_use_cert' => 0,
                        'SSL_verify_mode' => 0x00,
                        'SSL_key_file' => $cwd."/certs/client-key.pem",
                        'SSL_cert_file' => $cwd."/certs/client-cert.pem",
                        'SSL_ca_path' => $cwd."/certs",
                        'SSL_ca_file' => $cwd."/certs/ca-cert.pem",
                        );
    my @ssl_options;
    my $ssl_key;
    my $key;
    foreach $ssl_key (keys(%ssl_defaults)) {
	    if (!defined($self->{$ssl_key})) {
        $self->{$ssl_key} = $ssl_defaults{$ssl_key};
	    }
    }
    foreach $ssl_key (keys(%{$self})) {
	    if ($ssl_key =~ /^SSL_/) {
        push @ssl_options, $ssl_key, $self->{$ssl_key};
	    }
    }
    my $SSL_try = "use IO::Socket::SSL";

    eval $SSL_try;
#	$IO::Socket::SSL::DEBUG = 1;
    if (!eval {
	    $self->{'Socket'} =
      IO::Socket::SSL->new(PeerAddr => $self->{'Server'},
                           PeerPort => $self->{'Port'},
                           Proto => 'tcp',
                           Reuse => 1,
                           Timeout => 5,
                           @ssl_options); }) {
	    $self->_error("initialize", "couldn't establish SSL connection to",
                    $self->{'Server'}, "[$!]");
	    delete $self->{'Socket'};
	    return;
    }
  } else {
    if ($self->{'Server'} =~ /^\//) {
        if (!eval {
            $self->{'Socket'} =
        IO::Socket::UNIX->new(Peer => $self->{'Server'}); })
        {
            delete $self->{'Socket'};
            $self->_error("initialize", "couldn't establish connection to",
                        $self->{'Server'});
            return;
        }
      } else {
          if (!eval {
              $self->{'Socket'} =
          IO::Socket::INET->new(PeerAddr => $self->{'Server'},
                                  PeerPort => $self->{'Port'},
                                  Proto => 'tcp',
                                  Reuse => 1,
                                  Timeout => 5); })
          {
              delete $self->{'Socket'};
              $self->_error("initialize", "couldn't establish connection to",
                          $self->{'Server'});
              return;
          }
      }
  }
  my $fh = $self->{'Socket'};
  my $try = $self->_read; # get Banner
  if ($try !~ /\* OK/) {
    $self->close;
    $self->_error("initialize", "bad response from", $self->{'Server'},
                  "[", $try, "]");
    return;
  }
  # this section was changed to accomodate motd's
  print $fh "try CAPABILITY\n";
  $try = $self->_read;
  while ($try !~ /^\* CAPABILITY/) { # we have a potential lockup, should alarm this
    $try = $self->_read;
  }
  $self->{'Capability'} = $try;
  $try = $self->_read;
  if ($try !~ /^try OK/) {
    $self->close;
    $self->_error("initialize", "Couldn't do a capabilites check [",
                  $try, "]");
    return;
  }
  if ($self->{'CRAM'} > 0) {
    if ($self->{'Capability'} =~ /CRAM-MD5/) {
      _do_cram_login($self);
    } else {
      if ($self->{'CRAM'} > 1) {
        print $fh qq{try LOGIN "$self->{'Login'}" "$self->{'Password'}"\n};
      } else {
        $self->close;
        $self->_error("initialize","CRAM not reported in Capability check and fallback to PLAIN not selected", $self->{'Server'}, "[", $self->{'Capability'}, "]");
        return;
      }
    }
  } else {
    print $fh qq{try LOGIN "$self->{'Login'}" "$self->{'Password'}"\n};
  }
  $try = $self->_read;
  if ($try !~ /^try OK/) { # should tr this response
    $self->close;
    $self->_error("initialize", $try);
    return;
  } else { 
    $self->{'Error'} = "No Errors";
    return;
  }
  # fall thru, can it be hit ?
  $self->{'Error'} = "No Errors";
  return;
}

# this routine uses evals to prevent errors regarding missing modules
sub _do_cram_login {
  my $self = shift;
  my $fh = $self->{'Socket'};
  my $ans;

  print $fh "try AUTHENTICATE CRAM-MD5\n";
  my $try = $self->_read; # gets back the postal string
  ($ans) = (split(' ', $try, 2))[1];
  my $cram_eval = "
   my \$hmac = Digest::HMAC->new(\$self->{'Password'}, 'Digest::MD5');
   \$hmac->add(decode_base64(\$ans));
   \$ans = encode_base64(\$self->{'Login'}.' '.\$hmac->hexdigest, '');
  ";
  eval $cram_eval;
  print $fh "$ans\n";
  return;
}

sub _error {
  my $self = shift;
  my $func = shift;
  my @error = @_;

  $self->{'Error'} = join(" ",$self->{'CLASS'}, "[", $func, "]:", @error);
  return;
}

sub error {
  my $self = shift;
  return $self->{'Error'};
}

sub _read {
  my $self = shift;
  my $buffer = "";
  my $char = "";
  my $bytes = 1;
  while ($bytes == 1) {
    $bytes = sysread $self->{'Socket'}, $char, 1;
    if ($bytes == 0) {
      if (length ($buffer) != 0) {
        return $buffer;
      } else {
        return;
      }
    } else {
      if (($char eq "\n") or ($char eq "\r")) {
        if (length($buffer) == 0) {
          # cr or nl left over, just eat it
        } else {
          return $buffer;
        }
      } else {
#		print "got char [$char]\n";
        $buffer .= $char;
      }
    }
  }
}

sub close {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 0;
  }
  my $fh = $self->{'Socket'};
  print $fh "try logout\n";
  my $try = $self->_read;
  close($self->{'Socket'});
  delete $self->{'Socket'};
  return 0;
}

sub create {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if ((scalar(@_) != 1) && (scalar(@_) != 2)) {
    $self->_error("create", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  if (scalar(@_) == 1) { # a partition exists
    print $fh qq{try CREATE "$mailbox" $_[0]\n};
  } else {
    print $fh qq{try CREATE "$mailbox"\n};
  }
  my $try = $self->_read;
  if ($try =~ /^try OK/) {
    $self->{'Error'} = 'No Errors';
    return 0;
  } else {
    $self->_error("create", "couldn't create", $mailbox, ":", $try);
    return 1;
  }
}

sub rename {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if ((scalar(@_) != 2) && (scalar(@_) != 3)) {
    $self->_error("rename", "incorrect number of arguments");
    return 1;
  }
  my $old_name = shift;
  my $new_name = shift;
  my $partition = shift;

  my $fh = $self->{'Socket'};
  if (defined $partition) {
    print $fh qq{try RENAME "$old_name" "$new_name" $partition\n};
  } else {
    print $fh qq{try RENAME "$old_name" "$new_name"\n};
  }
  my $try = $self->_read;
  if (($try =~ /^try OK/) || ($try =~ /^\* OK/)) {
    $self->{'Error'} = 'No Errors';
    return 0;
  } else {
    $self->_error("rename", "couldn't rename", $old_name, "to", $new_name,
                  ":", $try);
    return 1;
  }
}

sub delete {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("delete", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try DELETE "$mailbox"\n};
  my $try = $self->_read;
  if ($try =~ /^try OK/) {
    $self->{'Error'} = 'No Errors';
    return 0;
  } else {
    $self->_error("delete", "couldn't delete", $mailbox, ":", $try);
    return 1;
  }
}

sub h_delete {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("h_delete", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  # first get a list of all sub boxes then nuke them, accumulate errors
  # then do something intelligent with them (hmmmmm)
  my $box = join($self->{'Separator'}, $mailbox, "*");
  my @sub_boxes = $self->list($box);
  push @sub_boxes, $mailbox;
  # uncomment following line if you are sanity checking h_delete
  # print "h_delete: got this list of sub boxes [@sub_boxes]\n";
  foreach $box (@sub_boxes) {
    print $fh qq{try DELETE "$box"\n};
    my $try = $self->_read;
    if ($try =~ /^try OK/) {
      $self->{'Error'} = 'No Errors';
    } else {
       $self->_error("h_delete", "couldn't delete",
                     $mailbox, ":", $try);
       return 1; # or just return on the first encountered error ?
    }
  }
  return 0;
}

sub get_quotaroot { # returns an array or undef
  my $self = shift;
  my (@quota, @info);

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (!($self->{'Capability'} =~ /QUOTA/)) {
    $self->_error("get_quotaroot", "QUOTA not listed in server's capabilities");
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("get_quotaroot", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try GETQUOTAROOT "$mailbox"\n};
  my $try = $self->_read;
  while ($try =~ /^\* QUOTA/) {
    if ($try !~ /QUOTAROOT/) { # some imap servers give this extra line
      @info = ($try =~ /QUOTA\s(.*?)\s\(STORAGE\s(\d+)\s(\d+)/);
      push @quota, @info;
    }
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @quota;
  } else {
    $self->_error("get_quotaroot", "couldn't get quota for", $mailbox, ":", $try);
    return;
  }
}

sub get_quota { # returns an array or undef
  my $self = shift;
  my (@quota, @info);

  if (!defined($self->{'Socket'})) {
    return;
  }
  if (!($self->{'Capability'} =~ /QUOTA/)) {
    $self->_error("get_quota",
                  "QUOTA not listed in server's capabilities");
    return;
  }
  if (scalar(@_) != 1) {
    $self->_error("get_quota", "incorrect number of arguments");
    return;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try GETQUOTA "$mailbox"\n};
  my $try = $self->_read;
  while ($try =~ /^\* QUOTA/) {
    @info = ($try =~ /QUOTA\s(.*?)\s\(STORAGE\s(\d+)\s(\d+)/);
    push @quota, @info;
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @quota;
  } else {
    $self->_error("get_quota", "couldn't get quota for", $mailbox, ":", $try);
    return;
  }
}

sub set_quota {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (!($self->{'Capability'} =~ /QUOTA/)) {
    $self->_error("set_quota", "QUOTA not listed in server's capabilities");
    return 1;
  }
  if (scalar(@_) != 2) {
    $self->_error("set_quota", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $quota = shift;
  my $fh = $self->{'Socket'};
  if ($quota eq "none") {
    print $fh qq{try SETQUOTA "$mailbox" ()\n};
  } else {
    print $fh qq{try SETQUOTA "$mailbox" (STORAGE $quota)\n};
  }
  my $try = $self->_read;
  if ($try =~ /^try OK/) {
    $self->{'Error'} = "No Errors";
    return 0;
  } else {
    $self->_error("set_quota", "couldn't set quota for", $mailbox, ":", $try);
    return 1;
  }
}

sub subscribe {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("subscribe", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try SUBSCRIBE "$mailbox"\n};
  my $try = $self->_read;
  if ($try !~ /^try OK/) {
    $self->_error("subscribe", "couldn't suscribe ", $mailbox, ":",
                  $try);
    return 1;
  }
  $self->{'Error'} = 'No Errors';
  return 0;
}

sub unsubscribe {
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("unsubscribe", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try UNSUBSCRIBE "$mailbox"\n};
  my $try = $self->_read;
  if ($try !~ /^try OK/) {
    $self->_error("unsubscribe", "couldn't unsuscribe ", $mailbox, ":",
                  $try);
    return 1;
  }
  $self->{'Error'} = 'No Errors';
  return 0;
}

sub select { # returns an array or undef
  my $self = shift;
  my @info;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 1) {
    $self->_error("select", "incorrect number of arguments");
    return;
  }

  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try SELECT "$mailbox"\n};
  my $try = $self->_read;
  while ($try =~ /^\* (.*)/) { # danger danger (could lock up needs timeout)
    push @info, $1;
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @info;
  } else {
    $self->_error("select", "couldn't select", $mailbox, ":", $try);
    return;
  }
}

sub expunge { # returns an array or undef
  my $self = shift;
  my @info;

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (scalar(@_) != 0) {
    $self->_error("expunge", "incorrect number of arguments");
    return;
  }

  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try EXPUNGE\n};
  my $try = $self->_read;
  while ($try =~ /^\* (.*)/) { # danger danger (could lock up needs timeout)
    push @info, $1;
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @info;
  } else {
    $self->_error("expunge", "couldn't expunge", $mailbox, ":", $try);
    return;
  }
}

sub get_acl { # returns an array or undef
  my $self = shift;

  if (!defined($self->{'Socket'})) {
    return;
  }
  if (!($self->{'Capability'} =~ /ACL/)) {
    $self->_error("get_acl", "ACL not listed in server's capabilities");
    return;
  }
  if (scalar(@_) != 1) {
    $self->_error("get_acl", "incorrect number of arguments");
    return;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try GETACL "$mailbox"\n};
  delete $self->{'acl'};
  my $try = $self->_read;
  while ($try =~ /^\*\s+ACL\s+/) {
    my $acls = ($try =~ /^\* ACL\s+(?:\".*?\"|\S*)\s+(.*)/)[0]; # separate out the acls
    my @acls = ($acls =~ /(\".*?\"|\S+)\s*/g); # split up over ws, unless quoted
    push @{$self->{'acl'}}, @acls;
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @{$self->{'acl'}};
  } else {
    $self->_error("get_acl", "couldn't get acl for", $mailbox, ":", $try);
    return;
  }
}

sub set_acl {
  my $self = shift;
  my ($id, $acl);

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (!($self->{'Capability'} =~ /ACL/)) {
    $self->_error("set_acl", "ACL not listed in server's capabilities");
    return 1;
  }
  if (scalar(@_) < 2) {
    $self->_error("set_acl", "too few arguments");
    return 1;
  }
  if ((scalar(@_) % 2) == 0) {
    $self->_error("set_acl", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  while(@_) {
    $id = shift;
    $acl = shift;
    print $fh qq{try SETACL "$mailbox" "$id" "$acl"\n};
    my $try = $self->_read;
    if ($try !~ /^try OK/) {
      $self->_error("set_acl", "couldn't set acl for", $mailbox, $id,
                    $acl, ":", $try);
      return 1;
    }
  }
  $self->{'Error'} = 'No Errors';
  return 0;
}

sub delete_acl {
  my $self = shift;
  my ($id, $acl);

  if (!defined($self->{'Socket'})) {
    return 1;
  }
  if (!($self->{'Capability'} =~ /ACL/)) {
    $self->_error("delete_acl", "ACL not listed in server's capabilities");
    return 1;
  }
  if (scalar(@_) < 1) {
    $self->_error("delete_acl", "incorrect number of arguments");
    return 1;
  }
  my $mailbox = shift;
  my $fh = $self->{'Socket'};
  while(@_) {
    $id = shift;
    print $fh qq{try DELETEACL "$mailbox" "$id"\n};
    my $try = $self->_read;
    if ($try !~ /^try OK/) {
      $self->_error("delete_acl", "couldn't delete acl for", $mailbox,
                    $id, $acl, ":", $try);
      return 1;
    }
  }
  return 0;
}

sub list { # wild cards are allowed, returns array or undef
  my $self = shift;
  my (@info, @mail);

  if (!defined($self->{'Socket'})) {
    return;
  }
  if (scalar(@_) != 1) {
    $self->_error("list", "incorrect number of arguments");
    return;
  }
  my $list = shift;
  my $fh = $self->{'Socket'};
  print $fh qq{try LIST "" "$list"\n};
  my $try = $self->_read;
  while ($try =~ /^\* LIST.*?\) \".\" \"*(.*?)\"*$/) { # danger danger (could lock up needs timeout) " <- this quote makes emacs happy
    push @mail, $1;
    $try = $self->_read;
  }
  if ($try =~ /^try OK/) {
    return @mail;
  } else {
    $self->_error("list", "couldn't get list for", $list, ":", $try);
    return;
  }
}


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

IMAP::Admin - Perl module for basic IMAP server administration

=head1 SYNOPSIS

  use IMAP::Admin;

  $imap = IMAP::Admin->new('Server' => 'name.of.server.com',
                           'Login' => 'login_of_imap_administrator',
                           'Password' => 'password_of_imap_adminstrator',
                           'Port' => port# (143 is default),
                           'Separator' => ".", # default is a period
                           'CRAM' => 1, # off by default, can be 0,1,2
                           'SSL' => 1, # off by default
                           # and any of the SSL_ options from IO::Socket::SSL
                           );

  $err = $imap->create("user.bob");
  if ($err != 0) {
    print "$imap->{'Error'}\n";
  }
  if ($err != 0) {
    print $imap->error;
  }
  $err = $imap->create("user.bob", "green");
  $err = $imap->delete("user.bob");
  $err = $imap->h_delete("user.bob");

  $err = $imap->subscribe("user.bob");
  $err = $imap->unsubscribe("user.bob");

  $err = $imap->rename("bboard", "newbboard");
  $err = $imap->rename("bboard", "newbboard", "partition");

  @quota = $imap->get_quotaroot("user.bob");
  @quota = $imap->get_quota("user.bob");
  $err = $imap->set_quota("user.bob", 10000);

  @acl = $imap->get_acl("user.bob");
  %acl = $imap->get_acl("user.bob");
  $err = $imap->set_acl("user.bob", "admin", "lrswipdca", "joe", "lrs");
  $err = $imap->delete_acl("user.bob", "joe", "admin");

  @list = $imap->list("user.bob");
  @list = $imap->list("user.b*");

  $imap->{'Capability'} # this contains the Capabilities reply from the IMAP server

  $imap->close; # close open imap connection

=head1 DESCRIPTION

IMAP::Admin provides basic IMAP server adminstration.  It provides functions for creating and deleting mailboxes and setting various information such as quotas and access rights.

It's interface should, in theory, work with any RFC compliant IMAP server, but I currently have only tested it against Carnegie Mellon University's Cyrus IMAP and Mirapoint's IMAP servers.  It does a CAPABILITY check for specific extensions to see if they are supported.

Operationally it opens a socket connection to the IMAP server and logs in with the supplied login and password.  You then can call any of the functions to perform their associated operation.

Separator on the new call is the hiearchical separator used by the imap server.  It is defaulted to a period ("/" might be another popular one).

CRAM on the new call will attempt to use CRAM-MD5 as the login type of choice.  A value of 0 means off, 1 means on, 2 means on with fallback to login.  *Note* this options requires these perl modules: Digest::MD5, Digest::HMAC, MIME::Base64

SSL on the new call will attempt to make an SSL connection to the imap server.  It does not fallback to a regular connection if it fails.  It is off by default.  IO::Socket::SSL requires a ca certificate, a client certificate, and a client private key. By default these are in current_directory/certs, respectively named ca-cert.pem, client-cert.pem, and client-key.pem.  The location of this can be overridden by setting SSL_ca_file, SSL_cert_file, and SSL_key_file (you'll probably want to also set SSL_ca_path).

If you start the name of the server with a / instead of using tcp/ip it'll attempt to use a unix socket.

I generated my ca cert and ca key with openssl:
 openssl req -x509 -newkey rsa:1024 -keyout ca-key.pem -out ca-cert.pem

I generated my client key and cert with openssl:
 openssl req -new -newkey rsa:1024 -keyout client-key.pem -out req.pem -nodes
 openssl x509 -CA ca-cert.pem -CAkey ca-key.pem -req -in req.pem -out client-cert.pem -addtrust clientAuth -days 600

Setting up SSL Cyrus IMAP v 2.x (completely unofficial, but it worked for me)
 add these to your /etc/imapd.conf (remember to change /usr/local/cyrus/tls to wherever yours is)
  tls_ca_path: /usr/local/cyrus/tls
  tls_ca_file: /usr/local/cyrus/tls/ca-cert.pem
  tls_key_file: /usr/local/cyrus/tls/serv-key.pem
  tls_cert_file: /usr/local/cyrus/tls/serv-cert.pem

For my server key I used a self signed certificate:
 openssl req -x509 -newkey rsa:1024 -keyout serv-key.pem -out serv-cert.pem -nodes -extensions usr_cert (in openssl.cnf I have nsCertType set to server)

I also added this to my /etc/cyrus.conf, it shouldn't strictly be necessary as clients that are RFC2595 compliant can issue a STARTTLS to initiate the secure layer, but currently IMAP::Admin doesn't issue this command (in SERVICES section):
  imap2  cmd="imapd -s" listen="simap" prefork=0

where simap in /etc/services is:
  simap  993/tcp   # IMAP over SSL

=head2 MAILBOX FUNCTIONS

RFC2060 commands.  These should work with any RFC2060 compliant IMAP mail servers.

create makes new mailboxes.  Cyrus IMAP, for normal mailboxes, has the user. prefix.
create returns a 0 on success or a 1 on failure.  An error message is placed in the object->{'Error'} variable on failure. create takes an optional second argument that is the partition to create the mailbox in (I don't know if partition is rfc or not, but it is supported by Cyrus IMAP and Mirapoint).

delete destroys mailboxes.
The action delete takes varies from server to server depending on it's implementation.  On some servers this is a hierarchical delete and on others this will delete only the mailbox specified and only if it has no subfolders that are marked \Noselect.  If you wish to insure a hierarchical delete use the h_delete command as it deletes starting with the subfolders and back up to the specified mailbox.  delete returns a 0 on success or a 1 on failure.  An error message is placed in the object->{'Error'} variable on failure.

h_delete hierarchical delete (I don't believe this is RFC anything)
deletes a mailbox and all sub-mailboxes/subfolders that belong to it.  It basically gets a subfolder list and does multiple delete calls.  It returns 0 on sucess or a 1 on failure with the error message from delete being put into the object->{'Error'} variable.  Don't forget to set your Separator if it's not a period.

list lists mailboxes.  list accepts wildcard matching

subscribe/unsubscribe does this action on given mailbox.

rename renames a mailbox.  IMAP servers seem to be peculiar about how they implement this, so I wouldn't necessarily expect it to do what you think it should. The Cyrus IMAP server will move a renamed mailbox to the default partition unless a partition is given. You can optionally supply a partition name as an extra argument to this function.

select selects a mailbox to work on. You need the 'r' acl to select a mailbox.
This command selects a mailbox that mailbox related commands will be performed on.  This is not a recursive command so sub-mailboxes/folders will not be affected unless for some bizarre reason the IMAP server has it implemented as recursive.  It returns an error or an array that contains information about the mailbox.  For example:
FLAGS (\Answered \Flagged \Draft \Deleted \Seen $Forwarded $MDNSent NonJunk Junk $Label7)
OK [PERMANENTFLAGS (\Deleted)]
2285 EXISTS
2285 RECENT
OK [UNSEEN 1]
OK [UIDVALIDITY 1019141395]
OK [UIDNEXT 293665]
OK [READ-WRITE] Completed

expunge permanently removes messages flagged with \Deleted out of the current selected mailbox.
It returns a list of message sequence numbers that it deleted.  You need to select a mailbox before you expunge. You need to read section 7.4.1 of RFC2060 to interpret the output.  Essentially each time a message is deleted the sequence numbers all get decremented so you can see the same message sequence number several times in the list of deleted messages.  In the following example (taken from the RFC) messages 3, 4, 7, and 11 were deleted:
* 3 EXPUNGE
* 3 EXPUNGE
* 5 EXPUNGE
* 8 EXPUNGE
. OK EXPUNGE completed


=head2 QUOTA FUNCTIONS

RFC2087 imap extensions.  These are supported by Cyrus IMAP and Mirapoint.

get_quotaroot and get_quota retrieve quota information.  They return an array on success and undef on failure.  In the event of a failure the error is place in the object->{'Error'} variable.  The array has three elements for each item in the quota.
$quota[0] <- mailbox name
$quota[1] <- quota amount used in kbytes
$quota[2] <- quota in kbytes

set_quota sets the quota.  The number is in kilobytes so 10000 is approximately 10Meg.
set_quota returns a 0 on success or a 1 on failure.  An error message is placed in the object->{'Error'} variable on failure.

To delete a quota do a set_quota($mailbox, "none");


=head2 ACCESS CONTROL FUNCTIONS

RFC2086 imap extensions.  These are supported by Cyrus IMAP, Mirapoint and probably many others.

get_acl retrieves acl information.  It returns an array on success and under on failure.  In the event of a failure the error is placed in the object->{'Error'} variable. The array contains a pair for each person who has an acl on this mailbox
$acl[0] user who has acl information
$acl[1] acl information
$acl[2] next user ...

You could also treat the return from get_acl as a hash, in which case the user is the key and the acl information is the value.

set_acl set acl information for a single mailbox.  You can specify more the one user's rights on the same set call.  It returns a 0 on success or a 1 on failure.  An error message is placed in the object->{'Error'} variable on failure.

delete_acl removes acl information on a single mailbox for the given users.  You can specify more the one users rights to be removed in the same delete_acl call.  It returns a 0 on success or a 1 on failure.  An error message is placed int the object->{'Error'} variable on failure.

standard rights (rfc2086):
 l - lookup (mailbox is visible to LIST/LSUB commands)
 r - read (SELECT the mailbox, perform CHECK, FETCH, PARTIAL, SEARCH, and COPY)
 s - keep seen/unssen information across sessions (STORE SEEN flag)
 w - write (STORE flags other then SEEN and DELETED)
 i - insert (perform APPEND and COPY into mailbox)
 p - post (send mail to submission address for mailbox)
 c - create (CREATE new sub-mailboxes) (*note* allows for delete of sub mailboxes as well)
 d - delete (STORE DELETED flag, perform EXPUNGE)
 a - administer (perform SETACL)

The access control information is from Cyrus IMAP.
  read   = "lrs"
  post   = "lrsp"
  append = "lrsip"
  write  = "lrswipcd"
  all    = "lrswipcda"

=head1 KNOWN BUGS

Currently all the of the socket traffic is handled via prints and _read.  This means that some of the calls could hang if the socket connection is broken.  Eventually the will be properly selected and timed.

=head1 LICENSE

This is licensed under the Artistic license (same as perl).  A copy of the license is included in this package.  The file is called Artistic.  If you use this in a product or distribution drop me a line, 'cause I am always curious about that...

=head1 AUTHOR

Eric Estabrooks, eric@urbanrage.com

=head1 SEE ALSO

perl(1).

=cut
