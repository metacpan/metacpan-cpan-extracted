#
# Copyright (c) 2003, Stockholms Universitet
# (Stockholm University, Stockholm Sweden)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of the university nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# $Id$
#

package Heimdal::Kadm5;

use strict;
no strict qw(refs);

use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT_OK = qw(
		KADM5_ADMIN_SERVICE
		KADM5_API_VERSION_1
		KADM5_API_VERSION_2
		KADM5_ATTRIBUTES
		KADM5_AUX_ATTRIBUTES
		KADM5_CHANGEPW_SERVICE
		KADM5_CONFIG_ACL_FILE
		KADM5_CONFIG_ADBNAME
		KADM5_CONFIG_ADB_LOCKFILE
		KADM5_CONFIG_ADMIN_KEYTAB
		KADM5_CONFIG_ADMIN_SERVER
		KADM5_CONFIG_DBNAME
		KADM5_CONFIG_DICT_FILE
		KADM5_CONFIG_ENCTYPE
		KADM5_CONFIG_ENCTYPES
		KADM5_CONFIG_EXPIRATION
		KADM5_CONFIG_FLAGS
		KADM5_CONFIG_KADMIND_PORT
		KADM5_CONFIG_MAX_LIFE
		KADM5_CONFIG_MAX_RLIFE
		KADM5_CONFIG_MKEY_FROM_KEYBOARD
		KADM5_CONFIG_MKEY_NAME
		KADM5_CONFIG_PROFILE
		KADM5_CONFIG_REALM
		KADM5_CONFIG_STASH_FILE
		KADM5_FAIL_AUTH_COUNT
		KADM5_HIST_PRINCIPAL
		KADM5_KEY_DATA
		KADM5_KVNO
		KADM5_LAST_FAILED
		KADM5_LAST_PWD_CHANGE
		KADM5_LAST_SUCCESS
		KADM5_MAX_LIFE
		KADM5_MAX_RLIFE
		KADM5_MKVNO
		KADM5_MOD_NAME
		KADM5_MOD_TIME
		KADM5_POLICY
		KADM5_POLICY_CLR
		KADM5_POLICY_NORMAL_MASK
		KADM5_PRINCIPAL
		KADM5_PRINCIPAL_NORMAL_MASK
		KADM5_PRINC_EXPIRE_TIME
		KADM5_PRIV_ADD
		KADM5_PRIV_ALL
		KADM5_PRIV_CPW
		KADM5_PRIV_DELETE
		KADM5_PRIV_GET
		KADM5_PRIV_LIST
		KADM5_PRIV_MODIFY
		KADM5_PW_EXPIRATION
		KADM5_PW_HISTORY_NUM
		KADM5_PW_MAX_LIFE
		KADM5_PW_MIN_CLASSES
		KADM5_PW_MIN_LENGTH
		KADM5_PW_MIN_LIFE
		KADM5_REF_COUNT
		KADM5_STRUCT_VERSION
		KADM5_TL_DATA
		KRB5_KDB_DISALLOW_ALL_TIX
		KRB5_KDB_DISALLOW_DUP_SKEY
		KRB5_KDB_DISALLOW_FORWARDABLE
		KRB5_KDB_DISALLOW_POSTDATED
		KRB5_KDB_DISALLOW_PROXIABLE
		KRB5_KDB_DISALLOW_RENEWABLE
		KRB5_KDB_DISALLOW_SVR
		KRB5_KDB_DISALLOW_TGT_BASED
		KRB5_KDB_NEW_PRINC
		KRB5_KDB_PWCHANGE_SERVICE
		KRB5_KDB_REQUIRES_HW_AUTH
		KRB5_KDB_REQUIRES_PRE_AUTH
		KRB5_KDB_REQUIRES_PWCHANGE
		KRB5_KDB_SUPPORT_DESMD5
		USE_KADM5_API_VERSION
	       );

$VERSION = '0.08';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
		croak "Your vendor has not defined Heimdal::Kadm5 macro $constname";
	}
    }
    eval "sub $AUTOLOAD { $val } }";
    goto &$AUTOLOAD;
}

bootstrap Heimdal::Kadm5 $VERSION;

package Heimdal::Kadm5;

# Preloaded methods go here.

package Heimdal::Kadm5::Client;
@Heimdal::Kadm5::Client::ISA = qw(Heimdal::Kadm5);
use vars qw($KADMIN_SERVICE);

$KADMIN_SERVICE = 'kadmin/admin';

sub new
  {
    my $self = shift;
    my $class = ref $self || $self;
    
    my %opts = @_;
    my $me = bless \%opts,$class;

    my $client = $me->{'Principal'} or
          die "[Heimdal::Kadm5] Heimdal::Kadm5::Client::new missing required \'Principal\' parameter"; 
    my $keytab = $me->{'Keytab'} ? $me->{'Keytab'}   : '';
    my $password = $me->{'Password'} ? $me->{'Password'} : '';
    # warn %opts;
    eval
      {
	$me->{'_handle'} = Heimdal::Kadm5::SHandle->new(\%opts);
	if ($keytab)
	  {
	    $me->handle->c_init_with_skey($client,$keytab,$KADMIN_SERVICE,0,0);
	  }
	else 
	  {
	    $me->handle->c_init_with_password($client,$password,$KADMIN_SERVICE,0,0);
	  }
	$me->{'_privs'} = $me->handle->c_get_privs();
      };

    if ($@)
      {
	my $err = $@;
	if ($me->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to initialize a Heimdal::Kadm5::Client instance\n";
	return undef;
      }
    $me;
  }

sub privs { $_[0]->{'_privs'}; }

my %pnames = (
	      Heimdal::Kadm5::KADM5_PRIV_ADD()    => 'add',
	      Heimdal::Kadm5::KADM5_PRIV_CPW()    => 'cpw',
	      Heimdal::Kadm5::KADM5_PRIV_DELETE() => 'delete',
	      Heimdal::Kadm5::KADM5_PRIV_LIST()   => 'list',
	      Heimdal::Kadm5::KADM5_PRIV_GET()    => 'get',
	      Heimdal::Kadm5::KADM5_PRIV_MODIFY() => 'modify'
	     );

sub getPriviledges 
  { 
    my $mask = $_[0]->privs;
    my @p;
    
    foreach my $bit (keys %pnames) 
      {
	push(@p,$pnames{$bit}) if ($mask & $bit);
      }
    return (wantarray ? @p : join(', ',@p));
  }

sub handle { $_[0]->{'_handle'}; }

sub makePrincipal
  {
    my $principal = Heimdal::Kadm5::Principal->new(handle($_[0]));
    $principal->setPrincipal($_[1]);
    $principal;
  }

sub getPrincipals
  {
    my $self = shift;
    $self->handle->c_get_principals(@_);
  }

sub getPrincipal
  {
    my $self = shift;
    my $princ = shift;
    my $mask = shift;

    $mask = (Heimdal::Kadm5::KADM5_PRINCIPAL_NORMAL_MASK()|Heimdal::Kadm5::KADM5_KEY_DATA()|Heimdal::Kadm5::KADM5_TL_DATA()) unless $mask;
    $self->handle->c_get_principal($princ,$mask);
  }

sub disablePrincipal
  {
    my $self = shift;
    my $name = shift;

    die "[Heimdal::Kadm5] Disable whom" unless $name;
    
    eval
      {
	my $principal = $self->getPrincipal($name);
	my $attrs = $principal->getAttributes;
	$attrs |= Heimdal::Kadm5::KRB5_KDB_DISALLOW_ALL_TIX();
	$principal->setAttributes($attrs);
	
	$self->modifyPrincipal($principal);
      };
    if ($@)
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to disable $name\n";
	return undef;
      }
    1;
  }

sub enablePrincipal
  {
    my $self = shift;
    my $name = shift;

    die "[Heimdal::Kadm5] Enable whom" unless $name;

    eval
      {
	my $principal = $self->getPrincipal($name);
	my $attrs = $principal->getAttributes;
	$attrs &= (~Heimdal::Kadm5::KRB5_KDB_DISALLOW_ALL_TIX());
	$principal->setAttributes($attrs);
	
	$self->modifyPrincipal($principal);
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError})
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to enable $name\n";
	return undef;
      }
    1;
  }

sub modifyPrincipal
  {
    my ($self,$principal,$mask) = @_;
    
    $mask = 0 unless $mask;
    eval
      {
	$self->handle->c_modify_principal($principal,$mask);
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	my $name = $principal->getPrincipal;
	warn $err;
	warn "Unable to modify $name\n";
	return undef;
      }
    1;
  }

sub changePassword
  {
    my ($self,$name,$password) = @_;

    eval
      {
	$self->handle->c_chpass_principal($name,$password);
	undef $password;
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to change password for $name\n";
	return undef;
      }
    1;
  }

sub createPrincipal
  {
    my $self = shift;
    my $principal = shift;
    my $password = shift;
    my $mask = shift;
    
    my $name = $principal->getPrincipal;
    die "[Heimdal::Kadm5] Create whom?" unless $name;
    
    eval
      {
	$self->handle->c_create_principal($principal,$password,$mask);
	undef $password;
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to create $name\n";
	return undef;
      }
    1;
  }

sub renamePrincipal
  {
    my ($self,$source,$target) = @_;

    eval
      {
	$self->handle->c_rename_principal($source,$target);
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to rename $source to $target\n";
	return undef;
      }
    1;
  }

sub deletePrincipal
  {
    my ($self,$name) = @_;

    eval
      {
	$self->handle->c_delete_principal($name);
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to delete $name\n";
	return undef;
      }
    1;
  }

sub randKeyPrincipal
  {
    my ($self,$name) = @_;

    eval
      {
	$self->handle->c_randkey_principal($name);
      };
    if ($@) 
      {
	my $err = $@;
	if ($self->{RaiseError}) 
	  {
	    die $@;
	  }
	warn $err;
	warn "Unable to generate random key for $name\n";
	return undef;
      }
    1;
  }

sub extractKeytab
   {
     my $self = shift;
     my $principal = shift;
     my $keytab = shift;

     my $nkeys;
     eval
       {
	 $self->handle->c_ext_keytab($principal,$keytab);
       };
     if ($@)
       {
         my $err = $@;
	 if ($self->{RaiseError}) 
	   {
	     die $err;
	   }
	 warn $err;
	 warn "Unable to extract keytab $keytab\n";
	 return undef
       }
     1;
   }

package Heimdal::Kadm5::Principal;
# @Heimdal::Kadm5::Principal::ISA = qw(Heimdal::Kadm5::SPrincipal);

use POSIX qw(strftime);
use Time::Seconds;

sub _sec2date { $_[0] ? strftime "%Y-%m-%d %T UTC", gmtime($_[0]): 'never'; }

# Convert seconds into a days and weeks format for ticket lifetime and
# maximum lifetime.
# TODO: This assumes you have an even number of days, and will fail at
# anything like '25 hours'.  The handling should be improved.
sub _sec2days {
    my $seconds = shift;
    my $val = Time::Seconds->new($seconds);
    my $str = '';
    if ($val->weeks >= 1) {
	if ($val->weeks == 1) {
	    $str = $val->weeks . ' week';
	} else {
	    $str = $val->weeks . ' weeks';
	}
    }
    if ($val->days % 7 == 0) {
	return $str;
    } else {
	$str .= ', ' if $str;
	return $str . $val->days . ' day' if $val->days == 1;
	return $str . $val->days.' days';
    }
}

# Given a principal name, dump the information about that principal to a
# given filehandle, or STDOUT if none is given.  The format of the output
# should be identical to that of kadmin's 'get' command.
sub dump
  {
    my $sp = shift;
    my $io = (shift or \*STDOUT);
    
    printf $io "%21s: %s\n", 'Principal',$sp->getPrincipal;
    printf $io "%21s: %s\n", 'Principal expires',
               _sec2date($sp->getPrincExpireTime);
    printf $io "%21s: %s\n", 'Password expires',
               _sec2date($sp->getPwExpiration);
    printf $io "%21s: %s\n", 'Last password change',
               _sec2date($sp->getLastPwdChange);
    printf $io "%21s: %s\n", 'Max ticket life',
               _sec2days($sp->getMaxLife);
    printf $io "%21s: %s\n", 'Max renewable life',
               _sec2days($sp->getMaxRenewableLife);
    printf $io "%21s: %s\n", 'Kvno', $sp->getKvno;
    printf $io "%21s: %s\n", 'Mkvno', $sp->getMKvno;
    printf $io "%21s: %s\n", 'Last successful login', 
               _sec2date($sp->getLastSuccess);
    printf $io "%21s: %s\n", 'Last failed login', 
               _sec2date($sp->getLastFailed);
    printf $io "%21s: %d\n", 'Failed login count', $sp->getFailAuthCounts;
    printf $io "%21s: %s\n", 'Last modified', _sec2date($sp->getModDate);
    printf $io "%21s: %s\n", 'Modifier', $sp->getModName;
    printf $io "%21s: %s\n", 'Attributes',
               join (', ', sort $sp->getAttributeNames);
    my @keys;
    foreach my $kt (@{$sp->getKeytypes}) 
      {
	push(@keys,"$kt->[0]($kt->[1])");
      }
    printf $io "%21s: %s\n\n", 'Keytypes', join(', ',@keys);
  }

# A wrapper around getAttributes, which translates the bitmask into an array
# of attribute names and returns that array.
sub getAttributeNames
  {
    my $sp = shift;
    my $bitmask = $sp->getAttributes;
    my @attrs = ();
    my @possible = ('KRB5_KDB_DISALLOW_ALL_TIX',
		    'KRB5_KDB_DISALLOW_DUP_SKEY',
		    'KRB5_KDB_DISALLOW_FORWARDABLE',
		    'KRB5_KDB_DISALLOW_POSTDATED',
		    'KRB5_KDB_DISALLOW_PROXIABLE',
		    'KRB5_KDB_DISALLOW_RENEWABLE',
		    'KRB5_KDB_DISALLOW_SVR',
		    'KRB5_KDB_DISALLOW_TGT_BASED',
		    'KRB5_KDB_NEW_PRINC',
		    'KRB5_KDB_REQUIRES_HW_AUTH',
		    'KRB5_KDB_REQUIRES_PRE_AUTH',
		    'KRB5_KDB_REQUIRES_PWCHANGE',
		    'KRB5_KDB_PWCHANGE_SERVICE',
		    'KRB5_KDB_SUPPORT_DESMD5',
	);

    foreach my $test (@possible) 
      {
        if ($bitmask & &{"Heimdal::Kadm5::$test"}()) {
            my $cleaned = lc ($test);
            $cleaned =~ s#^krb5_kdb_##;
            $cleaned =~ s#_#-#g;
            push (@attrs, $cleaned);
        }
      }
    return @attrs;
  }

# Autoload methods go after =cut, and are processed by the autosplit program.

package Heimdal::Kadm5;

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Heimdal::Kadm5 - Perl extension for adminstration of Heimdal Kerberos servers (kadmin)

=head1 SYNOPSIS

use Heimdal::Kadm5;

$client = Heimdal::Kadm5::Client->new('Client'=>'you/admin@YOUR.REALM',
                         'Password'=>'eatmyshorts');
foreach my $name ($client->getPrincipals('*/admin'))
  {
     my $principal = $client->getPrincipal($name);
     $principal->dump;
  }

=head1 DESCRIPTION

Heimdal::Kadm5 is a basic XSUB perl glue to the Heimdal (http://www.pdc.kth.se/src/heimdal) kadm5clnt
library. Heimdal is a free, slightly less export challenged implementation of Kerberos5 by Assar
Westerlund and Johan Danielsson. Heimdal::Kadm5 allows you to perform more administration of your kdc
than you can usually pull off with the included kadmin program. Heimdal::Kadm5 should be considered
alpha-code and may consequently crash and burn but should not muck up your kdc any more than kadmin
itself does.

=head1 OBJECTS

C<Heimdal::Kadm5::Client> represents a client connection (the truly perverse may conspire to write a kadmin
servlet in perl and put that in C<Heimdal::Kadm5::Server>) to a kadmin server. The main object handled by
a kadmin server is a C<kadm5_principal_ent_t> (F<kadm5/admin.h>). This type corresponds to the perl class
C<Heimdal::Kadm5::Principal>. This object is returned by the C<getPrincipal> method of C<Heimdal::Kadm5::Client>
and can be created (when adding principals to the kdc) using the C<makePrincipal> method of C<Heimdal::Kadm5::Client>.
Note: B<Do not create Principals directly through C<Heimdal::Kadm5::Principal>>.
Principals in the traditional sense of the word (i.e things of type C<krb5_principal>) are passed around
as strings ('name/instance@REALM' or 'name@REALM');

=head1 METHODS

In what follows $principal denotes an instance of Heimdal::Kadm5::Principal, $name denotes a principal
name, $bitmask denotes an (you guessed it!) integer representing a bitmask, $seconds an integer
representing seconds since the epoch (time_t value), $client a Heimdal::Kadm5::Client instance. Other
variables should be even more obvious or are explained in the text.


=head2 Heimdal::Kadm5::Client

Minimal use:

my $client = 
   Heimdal::Kadm5::Client->new(Client=>'you');

This would connect using a password for 'you@DEFREALM'. The password is
prompted on the active tty.

A more complex example:

my $client = 
   Heimdal::Kadm5::Client->new(
                    RaiseErrors => 1,
                    Server => 'adm.somewhere.net',
                    Port   => '8899',
                    # Required: 
                    Client => 'you/admin',
                    Realm  => 'OTHER.REALM',
                    # --- Either ---
                    Password => 'very secret',
                    # --- Or ---
                    Keytab => '$HOME/mysecret.keytab'
                   );

Be very careful when using the Password parameter: it implies storing the password in the
script or reading it from commmand line arguments or through some other means. Only use
this on secured hosts, never from NFS mounted filesystems, and B<never> using principals
allowed to perform all operations on the kdc. In this case using a keytable (see 
L<ktutil(8)> for information on how to create keytabs) is a better way to go.

Normally both the Server, Port and Realm parameters are determined from the kerberos context
(configuration files, DNS etc etc) but you may need to override them. If you leave out the password
or set it to undef the client library will prompt you for a password. You must include the
Client parameter which is usually your admin or root -instance depending on your local
system of belief. If for some reason the client connection cannot be initialized undef is
returned and errors are sent to warn unless the RaiseError parameter is set in which case
all errors are propagated by die.

my @names = $client->getPrincipals($pattern);

The getPrincipals method returns a list of principals matching $pattern which is not a 
regular expression but rather a glob-like animal. For instance '*/admin@REALM' is an
ok pattern. The elements of the list are principal names which can be used to obtain
Heimdal::Kadm5::Principal object using

my $principal = $client->getPrincipal($name);

which returns a Heimdal::Kadm5::Principal object (see the next section for details).

my $principal = $client->makePrincipal($name);

The makePrincipal method takes a principal name and creates an empty Heimdal::Kadm5::Principal 
object. This is intended for adding principals to the kdc. After creating the principal
using makePrincipal use the accessor methods in Heimdal::Kadm5::Principal to set values
before adding the principal using

$client->createPrincipal($principal,$password,$mask);

If $mask is set this value is used to determine which elements of the principal to include 
in the creation. Normally this value is automatically determined by tracking the uses of 
the accessor methods in the Heimdal::Kadm5::Principal class.

Modifications to an existing principal is done using this method:

$client->createPrincipal($principal,$mask);

The $mask value works in the same way as described above for createPrincipal. It is sometimes 
useful to disable (lock) a principal, for instance when several operations must be performed. 
The following methods can be used:

$client->disablePrincipal($name);

$client->enablePrincipal($name);

Other methods which modify the kdc are and the use of which should be obvious:

$client->changePassword($name, $password);

$client->deletePrincipal($name);

$client->renamePrincipal($name, $newname);

$client->randKeyPrincipal($name);

This method creates a random set of keys for the principal named $name. This is typically
done for service principals. When creating a new service principal it is probably a good
idea to create the principal with some initial password, disable the principal, apply the
randKeyPrincipal method and then enable the principal.

$client->handle->c_flush();

This method flushes all modifications to the datastore. It is called automatically
when the client handle is DESTROYed if any modifications (password change, create,
rename or delete has been performed);

$client->extractKeytab($principal,$keytab);

This method extracts the keys belonging to the principal object to the keytab
(optionally) specified by the second argument. If the second argument is missing 
it defaults to the standard default keytab, typically F</etc/krb5.keytab>.

=head2 Heimdal::Kadm5::Principal 

$principal->dump($io);

Dumps a representation of $principal on the $io handle (which defaults to \*STDOUT). 
This is mostly usable for debugging or simple scripts.

my $name = $principal->getPrincipal();
$principal->setPrincipal($name);

Gets and sets the principal name.

my $seconds = $principal->getPrincExpireTime();
$principal->setPrincExpireTime($seconds);

Gets and sets the time this principal expires.

my $seconds = $principal->getLastPwdChange();

Returns the last time this principal's password was changed.

my $kvno = $principal->getKvno();

Returns the key version number of this principal's password.

my $mkvno = $principal->getMKvno();

Returns this principal's MKvno.

my $seconds = $principal->getPwExpiration();
$principal->setPwExpiration($seconds);

Gets and sets the password expriation time. 

my $seconds = $principal->getMaxLife();
$principal->setMaxLife($seconds);

Gets and sets the maximum lifetime of a ticket.

my $seconds = $principal->getMaxRenewableLife();
$principal->setMaxRenewableLife($seconds);

Gets and sets the maximum renewable ticket lifetime.

my $name = $principal->getModName();

Returns the principal name of the last modifier of the entry. Not currently
(as of heimdal 0.1g) supported by heimdal and contains undef.

my $seconds = $principal->getModDate();

Returns the date of last modification of the entry.

my $policyname = $principal->getPolicy(); 

getPolicy returns undef if no policy is set. Policies are not currently
supported (as of heimdal 0.1g) and always returns undef.

my $seconds = $principal->getLastSuccess();

Last time a successful authentication was done against this principal.

my $seconds= $principal->getLastFailed();

Last time a failed authentication was done against this principal.

my $nfailed = $principal->getFailAuthCounts();

How many failed login attempts was done against this principal.

my $bitmask = $principal->getAttributes();

The bitmask of attributes for this principal.

my @names = $principal->getAttributeNames();

The list of attribute names for this principal, expanded from the bitmask.

my $arrayref = $principal->getKeyTypes();

getKeyTypes returns an array reference consisting of a list of array
references with two elements each: [keytype,salt]. The keytype and
salt are strings which describe a key associated with the principal.
Note that this data may not be present depending on how the principal
was obtained.

my $password = $principal->getPassword();

getPassword returns the password if its saved in the Kerberos database.
Not the that principal object need to fetched with the bit KADM5_TL_DATA
set in the mask.


=head1 Exported constants

  KADM5_ADMIN_SERVICE
  KADM5_API_VERSION_1
  KADM5_API_VERSION_2
  KADM5_ATTRIBUTES
  KADM5_AUX_ATTRIBUTES
  KADM5_CHANGEPW_SERVICE
  KADM5_CONFIG_ACL_FILE
  KADM5_CONFIG_ADBNAME
  KADM5_CONFIG_ADB_LOCKFILE
  KADM5_CONFIG_ADMIN_KEYTAB
  KADM5_CONFIG_ADMIN_SERVER
  KADM5_CONFIG_DBNAME
  KADM5_CONFIG_DICT_FILE
  KADM5_CONFIG_ENCTYPE
  KADM5_CONFIG_ENCTYPES
  KADM5_CONFIG_EXPIRATION
  KADM5_CONFIG_FLAGS
  KADM5_CONFIG_KADMIND_PORT
  KADM5_CONFIG_MAX_LIFE
  KADM5_CONFIG_MAX_RLIFE
  KADM5_CONFIG_MKEY_FROM_KEYBOARD
  KADM5_CONFIG_MKEY_NAME
  KADM5_CONFIG_PROFILE
  KADM5_CONFIG_REALM
  KADM5_CONFIG_STASH_FILE
  KADM5_FAIL_AUTH_COUNT
  KADM5_HIST_PRINCIPAL
  KADM5_KEY_DATA
  KADM5_KVNO
  KADM5_LAST_FAILED
  KADM5_LAST_PWD_CHANGE
  KADM5_LAST_SUCCESS
  KADM5_MAX_LIFE
  KADM5_MAX_RLIFE
  KADM5_MKVNO
  KADM5_MOD_NAME
  KADM5_MOD_TIME
  KADM5_POLICY
  KADM5_POLICY_CLR
  KADM5_POLICY_NORMAL_MASK
  KADM5_PRINCIPAL
  KADM5_PRINCIPAL_NORMAL_MASK
  KADM5_PRINC_EXPIRE_TIME
  KADM5_PRIV_ADD
  KADM5_PRIV_ALL
  KADM5_PRIV_CPW
  KADM5_PRIV_DELETE
  KADM5_PRIV_GET
  KADM5_PRIV_LIST
  KADM5_PRIV_MODIFY
  KADM5_PW_EXPIRATION
  KADM5_PW_HISTORY_NUM
  KADM5_PW_MAX_LIFE
  KADM5_PW_MIN_CLASSES
  KADM5_PW_MIN_LENGTH
  KADM5_PW_MIN_LIFE
  KADM5_REF_COUNT
  KADM5_STRUCT_VERSION
  KADM5_TL_DATA
  KRB5_KDB_DISALLOW_ALL_TIX
  KRB5_KDB_DISALLOW_DUP_SKEY
  KRB5_KDB_DISALLOW_FORWARDABLE
  KRB5_KDB_DISALLOW_POSTDATED
  KRB5_KDB_DISALLOW_PROXIABLE
  KRB5_KDB_DISALLOW_RENEWABLE
  KRB5_KDB_DISALLOW_SVR
  KRB5_KDB_DISALLOW_TGT_BASED
  KRB5_KDB_NEW_PRINC
  KRB5_KDB_PWCHANGE_SERVICE
  KRB5_KDB_REQUIRES_HW_AUTH
  KRB5_KDB_REQUIRES_PRE_AUTH
  KRB5_KDB_REQUIRES_PWCHANGE
  KRB5_KDB_SUPPORT_DESMD5
  USE_KADM5_API_VERSION


=head1 AUTHOR

Leif Johansson, leifj@it.su.se

=head1 SEE ALSO

perl(1).

=cut
