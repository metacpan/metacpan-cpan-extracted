package HTTPD::RealmManager;
use strict;

require Exporter;
use vars qw(@ISA @EXPORT $VERSION $ERROR);

@ISA = 'Exporter';
@EXPORT = qw(rearrange);
$ERROR  = '';
$VERSION = 1.33;

use Carp;
require HTTPD::Realm;

sub open {
    my $class = shift;
    my ($realm,$config,$rest) = rearrange([ 'REALM',['CONFIG_FILE','CONFIG']],@_);
    croak "Must provide the path to a config file" unless -r $config;
    my $realms = new HTTPD::Realm(-config_file=>$config,%$rest);
    return undef unless $realms;
    my $r = $realms->realm($realm);
    return undef unless $r;
    return $realms->dbm(-realm=>$r,%$rest);
}

sub new {
    my $class = shift;
    my ($realm,$mode,$writable,$server) = rearrange([ 'REALM', 'MODE', ['WRITE','WRITABLE'], 'SERVER' ],@_);
    croak "Must provide a valid realm object" unless $realm && ref($realm);
    my $self = {
	'realm'=>$realm,
	'mode'=>$mode || 0644,
	'writable'=>$writable,
	'server'=>$server,
    };
    bless $self,$class;
    return undef unless $self->open_passwd;
    return undef unless $self->open_group;
    return $self;
}

sub open_passwd {
    my $self = shift;
    my $realm = $self->{realm};

    # Create the right kind of HTTPD::UserAdmin and HTTPD::GroupAdmin objects.
    my %params;
    $params{DB} = $realm->userdb;
    $params{Encrypt} = $realm->crypt;
    $params{Server} = $self->{server};
    $params{Flags} = $self->{writable} ? 'rwc' : 'r';
    $params{Mode} = $self->{mode};
    $params{Locking} = $self->{writable};
    if ($realm->crypt() =~ /MD5/) {
	$params{Encrypt} = 'MD5';
	$self->{digest}++;
    }

    my $userType = $realm->usertype;
  CASE: {
      do { $params{DBType} = 'Text'; next; }    if $userType=~/text|file/i;
      do { $params{DBType} = 'DBM'; 
	   $params{DBMF} = "\U$userType\E"; 
	   $params{DBMF} = 'NDBM' if $params{DBMF} eq 'DBM';
	   next; }                              if $userType =~ /^(NDBM|GDBM|DB|DBM|SDBM|ODBM)$/;
      do { 
	   my $p = $realm->SQLdata;
	   $params{DB} = $p->{database};
	   $params{Host} = $p->{host} eq 'localhost' ? '' : $p->{host};
	   $params{DBType} = 'SQL';
	   $params{Driver} = $realm->driver;
#
# do what Lincoln didn't:
           $params{User} = $p->{dblogin};
           $params{Auth} = $p->{dbpassword};
           $params{DEBUG} = 0;
#
	   $params{UserTable} = $p->{usertable};
	   $params{NameField} = $p->{userfield};
	   $params{PasswordField} = $p->{passwdfield};
	   next; }                              if $userType=~/sql/i;
  }

    my $return = eval <<'END';
    use HTTPD::UserAdmin 1.50;
    $self->{userDB} = new HTTPD::UserAdmin(%params);
END
    ;
    $ERROR = $@ unless $return;
    return $return;
}

sub errstr {
    return $ERROR;
}

sub open_group {
    my $self = shift;
    my $realm = $self->{realm};
    return 1 unless $realm->groupdb;

    my %params;
    $params{DB} = $realm->groupdb;
    $params{Server} = $self->{server};
    $params{Flags} = $self->{writable} ? 'rwc' : 'r';
    $params{Mode} = $self->{mode};
    $params{Locking} = $self->{writable};
    my $groupType = $realm->grouptype;

  CASE: {
      do { $params{DBType} = 'Text'; next }    if $groupType=~/text|file/i;
      do {
	  $params{DBType} = 'DBM';
	  $params{DBMF} = "\U$groupType\E";
	  $params{DBMF} = 'NDBM' if $params{DBMF} eq 'DBM';
	  next }                              if $groupType =~ /^(NDBM|GDBM|DB|DBM|SDBM|ODBM)$/;
      do { 
	  my $p = $realm->SQLdata;
	  $params{DB} = $p->{database};
	   $params{Host} = $p->{host} eq 'localhost' ? '' : $p->{host};
	  $params{DBType} = 'SQL';
	  $params{Driver} = $realm->driver;
#
# do what Lincoln didn't:
           $params{User} = $p->{dblogin};
           $params{Auth} = $p->{dbpassword};
           $params{DEBUG} = 0;
#
	  $params{GroupTable} = $p->{grouptable};
	  $params{NameField} = $p->{groupuserfield} || $p->{userfield};
	  $params{GroupField} = $p->{groupfield};
	  $params{UserTable} = $p->{usertable};  # needed for obscure reasons
	  next; }                              if $groupType=~/sql/i;
  }
    my $return = eval<<'END';
    use HTTPD::GroupAdmin 1.50;
    $self->{groupDB} = new HTTPD::GroupAdmin(%params);
END
    ;
    $ERROR = $@ unless $return;
    return $return;
}


sub users {
    my $self = shift;
    return $self->{userDB}->list();
}

# Return true if a user is in a particular group
sub match_group {
    my $self = shift;
    my ($user,$group) = rearrange([['USER','NAME'],['GROUP','GRP']],@_);
    croak "Must provide a user name" unless $user;
    croak "Must provide a group name" unless $group;
    return undef unless $self->{groupDB};

    # Slightly different if we're using a DBM file.
    # Result of inconsistencies in HTTPD::GroupAdmin
    my %users;
    grep ($users{$_}++,$self->{groupDB}->list($group));
    return $users{$user};
}

sub open_writable {
    my $self = shift;
    return 1 if $self->{writable};
    $self->{writable}++;
    if ($self->{userDB}) {
	$self->{userDB}->commit();
	$self->{userDB}->close();
	unless ($self->open_passwd()) {
	    $ERROR = "Unable to open user file for writing";
	    return undef;
	}
    }
    if ($self->{groupDB}) {
	$self->{groupDB}->commit();
	$self->{groupDB}->close();
	unless ( $self->open_group() ) {
	    $ERROR = "Unable to open group file for writing";
	    return undef;
	}
    }
    1;
}

sub set_passwd {
    my $self = shift;
    my ($user,$passwd,$otherfields) = rearrange([[qw(USER NAME)],[qw(PASSWORD PASSWD)],[qw(OTHER GCOS FIELDS VALUES)] ],@_);
    croak "Must provide a user ID" unless $user;
    croak "Must provide a password or field values" unless $passwd || $otherfields;
    return undef unless $self->{userDB};

    # reopen if necessary
    return undef unless $self->open_writable();

    #special passwords for the digest method
    $passwd = "$user:$self->{realm}:$passwd" if $passwd && $self->{digest};

    my @other = ();
    my $result;
    if (defined($otherfields)) {
	@other = ref($otherfields) eq 'ARRAY' ? @$otherfields : ($otherfields) ;
    }

    if ($self->{userDB}->exists($user)) {

	# nasty hack here to avoid problems in the way that UserAdmin does its 
        # updates (first it deletes, then it adds!)
	my($crypt) = '';
	unless ($passwd) {
	    ($crypt,$self->{userDB}->{ENCRYPT}) = ($self->{userDB}->{ENCRYPT},'none');
	    $passwd = $self->passwd($user);
	}

	@other = $self->get_fields($user) unless @other;
	($result,$ERROR) = $self->{userDB}->update($user,$passwd,@other);
	$self->{userDB}->{ENCRYPT} = $crypt if $crypt;
	return $result unless $result;
 
   } else {

	($result,$ERROR) = $self->{userDB}->add($user,$passwd,@other);
	return $result unless $result;

    }
    ($result,$ERROR) = $self->{userDB}->commit();
    return $result;
}

sub set_password { &set_passwd; }

sub set_fields {
    my $self = shift;
    my ($user,$fields) = rearrange([[qw(USER NAME)],[qw(OTHER GCOS FIELD FIELDS VALUES)] ],@_);
    croak "Must provide a user ID" unless $user;
    croak "Must provide field values" unless $fields;
    my $current = $self->get_fields(-user=>$user);
    foreach (keys %$fields) {
	$current->{$_} = $fields->{$_};
    }
    return $self->set_passwd(-user=>$user,-fields=>$current);
}

# return true if passwords match
sub match_passwd {
    my $self = shift;
    my ($user,$passwd) = rearrange([[qw(USER NAME)],[qw(PASSWD PASSWORD)]],@_);
    croak "Must provide a user ID" unless $user;
    croak "Must provide a password" unless $passwd;
    return undef unless $self->{userDB}->exists($user);
    $passwd = "$user:$self->{realm}:$passwd" if $self->{digest};
    my $stored_passwd = $self->{userDB}->password($user);
    if ($self->{userDB}->{ENCRYPT} eq 'crypt') {
	return crypt($passwd,$stored_passwd) eq $stored_passwd;
    } else {
	return $self->{userDB}->encrypt($passwd) eq $stored_passwd;
    }
}

# shortcut for match_passwd
sub match { &match_passwd; }

sub passwd {
    my $self = shift;
    my ($user,$passwd) = rearrange([[qw(USER NAME)],[qw(PASSWORD PASSWD)]],@_);
    croak "Must provide a user ID" unless $user;
    if ($passwd) { return $self->match_passwd('-user'=>$user,'-passwd'=>$passwd) };
    return undef unless $self->{userDB}->exists($user);
    my (@pw) = split(/:/,$self->{userDB}->password($user));
    return $pw[1] if $self->{digest};
    return $pw[0];
}

sub password { &passwd; }

sub delete_user {
    my $self = shift;
    my ($user) = rearrange([[qw(USER NAME)]],@_);
    croak "Must provide a user ID" unless $user;
    return undef unless $self->open_writable();

    $self->{userDB}->delete($user) if $self->{userDB};    
    return unless $self->{groupDB};

    my $group;
    foreach $group ($self->{groupDB}->list) {
	$self->{groupDB}->delete($user,$group);
    }
    my $result;
    ($result,$ERROR) = $self->{groupDB}->commit();
    return $result unless $result;
    ($result,$ERROR) = $self->{userDB}->commit();
    return $result;
}

# With one argument returns the groups that the user is in.
# With two arguments returns true if user is in the group
sub group {
    my $self = shift;
    my ($user,$group) = rearrange([[qw(USER NAME)],[qw(GROUP GRP)]],@_);
    croak "Must provide a user ID" unless $user;
    if ($group) { return $self->match_group('-user'=>$user,'-group'=>$group) };
    return () unless my $db = $self->{groupDB};

    # Shortcut to avoid doing and undoing unnecessary work.
    if (ref($db)=~/DBM::apache/) {
      # check for Apache's weird combined user/group database format
      return $self->{groupDB}->{DB} eq $self->{userDB}->{DB}
	 ? split(',',(split(':',$db->{'_HASH'}->{$user}))[1])
	   : split(',',$db->{'_HASH'}->{$user});
    }

    my ($g,%groups);
    foreach $g ($self->{groupDB}->list) {
	my %user;
	grep($user{$_}++,$self->{groupDB}->list($g));
	$groups{$g}++ if $user{$user};
    }
    return keys %groups;
}

sub groups {
    my $self = shift;
    return () unless $self->{groupDB};
    return $self->{groupDB}->list();
}

sub members {
    my $self = shift;
    my ($group) = rearrange([[qw(GROUP GRP)]],@_);
    $group || croak "Must provide a group name";
    return () unless $self->{groupDB};
    return $self->{groupDB}->list($group);
}

sub set_group {
    my $self = shift;
    my ($user,$groups) = rearrange([[qw(USER NAME)],[qw(GROUP GRP)]],@_);
    croak "Must provide a user ID" unless $user;
    my $db;

    # reopen if necessary
    return undef unless $self->open_writable();

    return unless $db = $self->{groupDB};
    my (@groups) = ref($groups) ? @$groups : ($groups);

    # Shortcut to avoid doing and undoing work.
    if (ref($db)=~/DBM::apache/) {
	$db->{'_HASH'}->{$user}=join(',',@groups);
	$self->remove_dangling_groups();
	return 1;
    }

    # otherwise we do it the "correct" way
    my (%current,%new);
    grep ($current{$_}++,$self->group($user));
    grep ($new{$_}++,@groups);

    my (@to_remove) = grep (!$new{$_},keys %current);
    my (@to_add) = grep (!$current{$_},keys %new);
    foreach (@to_remove) {
	$db->delete($user,$_);
    }
    foreach (@to_add) {
	$db->add($user,$_);
    }

    $self->remove_dangling_groups();
    my $result;
    ($result,$ERROR) = $db->commit();
    return $result;
}

sub delete_group {
    my $self = shift;
    my ($group) = rearrange([[qw(GROUP GRP)]],@_);
    $group || croak "Must provide a group name";
    return 1 unless $self->{groupDB};
    return undef unless $self->open_writable();

    $self->{groupDB}->remove($group);
    my $result;
    ($result,$ERROR) = $self->{groupDB}->commit();
    return $result;
}

sub remove_dangling_groups {
    my $self = shift;
    my $grp;
    foreach $grp ($self->groups) {
	next unless $grp;
	$self->delete_group($grp) 
	    unless $self->members('-group'=>$grp);
    }
}

# Fetch field names from a SQL database.
# Only those fields that are returned by fields() are accessible.
# The return value is an associative array in which the keys are the
# field names and the values are the field types (s=string, i=integer, f=real).
sub fields {
    my $realm = shift->{realm};
    my $fields;
    return () unless $fields = $realm->fields;
    my @f = split(/\s+/,$fields);
    my %f;
    foreach (@f) {
	my($name,$type) = split(':',$_,2);
	$f{$name} = $type || 's';  # string by default
    }
    return %f;
}

# Fetch the named fields from an SQL database.
# Input is a user ID and a reference to a list of field names.  All fields will be
# returned if no list specified.
# The return value is a hash of the fields, or a reference to the hash in a scalar
# context. 
sub get_fields {
    my $self = shift;
    my ($user,$fields) = rearrange([[qw(USER NAME)],[qw(FIELDS FIELD VALUE VALUES)]],@_);
    croak "Must provide a user ID" unless $user;

    my (%ok) = $self->fields;
    my (@fields);
    if (defined($fields)) {
	@fields = grep ($ok{$_},@$fields);
    } else {
	@fields = keys %ok;
    }
    $self->{userDB}->fetch($user,@fields);
}

sub error {
    return $ERROR;
}

sub close {
  my $self = shift;
  do { $self->{userDB}->commit; $self->{userDB}->close() }   if $self->{userDB};
  do { $self->{groupDB}->commit; $self->{groupDB}->close() } if $self->{groupDB};

}

sub DESTROY {
    my $self = shift;
    $self->close;
}

# -------- exported utility routine ----------
sub rearrange {
    my($order,@param) = @_;
    return () unless @param;

    return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');

    my $i;
    for ($i=0;$i<@param;$i+=2) {
	$param[$i]=~s/^\-//;     # get rid of initial - if present
	$param[$i]=~tr/a-z/A-Z/; # parameters are upper case
    }

    # make sure param has even number of elements
    push(@param,'')  if ((@param) && ($#param % 2 == 0));

    my(%param) = @param;                # convert into associative array
    my(@return_array);

    local($^W) = 0;
    my($key)='';
    foreach $key (@$order) {
	my($value);
	if (ref($key) eq 'ARRAY') {
	    foreach (@$key) {
		last if defined($value);
		$value = $param{$_};
		delete $param{$_};
	    }
	} else {
	    $value = $param{$key};
	    delete $param{$key};
	}
	push(@return_array,$value);
    }
    push (@return_array,{%param}) if %param;
    return (@return_array);
}

sub realm {
    return shift->{realm};
}

1;


__END__
=head1 NAME

HTTPD::RealmManager - Manage HTTPD server security realms

=head1 SYNOPSIS

    use HTTPD::RealmManager;

    # open up the database (could also use HTTPD::Realm::connect())
    $database = HTTPD::RealmManager->open(-config_file=>'/home/httpd/conf/realms.conf',
                                          -realm=>'members',
                                          -writable=>1);

    # List functions
    @users = $database->users();
    @groups = $database->groups();

    # Information about users and groups:
    print "Lincoln's groups are @group\n"
        if @group = $database->group(-user=>'lincoln');

    print "Lincoln is a subscriber\n" 
        if $database->match_group(-user=>'lincoln',-group=>'subscribers');

    print "Lincoln's password is $pass\n"
        if $pass = $database->passwd(-user=>'lincoln');

    print "Intruder alert.\n"
        unless $database->match_passwd(-user=>'lincoln',
                                       -password=>'xyzzy');

    $lincoln_info = $database->get_fields(-user=>'lincoln');
    print "Lincoln's full name is $lincoln_info->{Name}\n";

    print "The subscribers are @members.\n"
        if @members = $database->members(-group=>'subscribers');

    # Database updates
    print "Added Fred.\n"
        if $database->set_passwd(-user=>'fred',
                                 -password=>'sssh!',
                                 -fields=>{Name=>'Fred Smith',
                                           Nationality=>'French'});

    print "Assigned Fred to 'subscribers' and 'VIPs'\n"
	if $database->set_group(-user=>'fred',
                                -group=>['subscribers','VIPs']);

   print "Changed Fred's nationality.\n"
        if $database->set_fields(-user=>'fred',
                                 -fields=>{Nationality=>'German'});

    print "Fred is now gone.\n"
        if $database->delete_user(-user=>'fred');

    print "VIP group is now gone.\n"
        if $database->delete_group(-group=>'VIPs');

    print "Uh oh.  An error occurred: ",$database->errstr,"\n"
        if $database->errstr;

=head1 DESCRIPTION

HTTPD::RealmManager provides a high-level, unified view onto the many
access control databases used by Apache, Netscape, NCSA httpd, CERN
and other Web servers.  It works hand-in-hand with HTTPD::Realm, which
provides access to a standard configuration file for describing
security database setups.  Internally, HTTPD::Realm uses Doug
MacEachern's HTTPD-Tools modules for database access and locking.


B<Important note:> Do not use these modules to adjust the Unix
password or group files.  They do not have the same format as the Web
access databases.

=head1 METHODS

HTTPD::RealmManager provides the following class and instance methods.

=over 4

=item new()

   $db = HTTPD::RealmManager->new(-realm    => $realm_def,
                                  -writable => 1,
                                  -mode     => 0644,
                                  -server   => 'ncsa');

The new() class method creates a new connection to the database
indicated by the indicated HTTPD::RealmDef object.  Ordinarily it will
be more convenient to use the open() method (below) or
HTTPD::RealmDef::connect().  Only the -realm argument is mandatory.
The others are optional and will default to reasonable values.

If successful, the function result is an HTTPD::RealmManager object,
which you can treat as a handle to the database.

Arguments:

   -realm      Realm definition.  See HTTPD::Realm(3).
   -writable   If true, open database for writing.
   -mode       Override file creation mode.
   -server     Override server type.

=item open()

   $db = HTTPD::RealmManager->open(-realm       => 'subscribers',
                                   -config_file => '/home/httpd/conf/realms.conf',
                                   -writable => 1,
                                   -mode     => 0644,
                                   -server   => 'ncsa');

The open() class method creates a new connection to the database
given the indicated configuration file and realm name.  Internally it
first creates an HTTPD::Realm object, then queries it for the named
realm, passing this result to new().  This is probably the easiest way
to create a new connection. 

Only the -realm and -config_file arguments are mandatory.  The others
are optional and will default to reasonable values.

If successful, the function result is an HTTPD::RealmManager object,
which you can treat as a handle to the database.

Arguments:

   -config_file Path to realm configuration file. See HTTPD::Realm(3).
   -realm       Realm name.
   -writable    If true, open database for writing.
   -config      An alias for -config_file.
   -mode        Override file creation mode.
   -server      Override server type.

=item close()

  $db->close()

When you are done with the database you should close() it.  This will
commit changes and tidy up.

=item users()

   @users = $db->users();

Return all users known to this database as a (potentially very long)
list.

=item groups()

   @groups = $db->groups()

Return all groups known to this database as a (potentially very long)
list.

=item group()

   @groups = $db->group(-user=>'username');
   $boolean = $db->group(-user=>'username',-group=>'groupname');

This method returns information about the groups that a user belongs
to.  Called with the name of the user only, it returns a list of all
the groups the user is a member of.  Called with both a user and a
group name, it returns a boolean value indicating whether the user
belongs to the group.

Arguments:

   -user     Name of the user
   -group    Name of the group
   -name     An alias for -user
   -grp      An alias for -group

You can also call this method with the positional parameters
(user,group), as in:

   @groups = $db->group('username');

=item match_group()

   $boolean = $db->match_group(-user=>'username',-group=>'groupname');

This method is identical to the group() function, except that it
requires a group name to be provided.

=item passwd()

   $password = $db->passwd(-user=>'username');
   $boolean = $db->passwd(-user=>'username',-password=>'password');

Called with a user name this method returns his B<encrypted> password.
Called with a user name and an B<unencrypted> password, this routine
returns a boolean indicating whether this password matches the stored
password.

Arguments:

   -user      Name of the user
   -password  Password to check against (optional)
   -name      Alias for -user
   -passwd    Alias for -password

You can also call this routine using positional arguments, where the
first argument is the user name and the second is the password to try:

    print "You're OK" if $db->password('Fred','Open sesame');

=item password()

   $password = $db->password(-user=>'username');
   $boolean = $db->password(-user=>'username',-password=>'password');

An alias for passwd(), just to make things interesting.

=item match_passwd()

   $boolean = $db->match_passwd(-user=>'username',-password=>'password');

This method is identical to the two-argument form of passwd(), except
that it requires a trial password to be provided.

=item match()

   $boolean = $db->match(-user=>'username',-password=>'password');

This method is an alias for match_passwd(), just to make things
interesting.

=item get_fields()

   $fields = $db->get_fields(-user=>'username',
                             -fields=>\@list_of_fields);

The user database can contain additional information about the user in
the form of name/value pairs.  This method provides access to these
"additional fields."  

get_fields() accepts a user name and optionally a list of the fields
to retrieve.  If no field list is provided, it will retrieve all
fields defined in the security realm configuration file (see
HTTPD::Realm (3)).  In practice, it is rarely necessary to limit the
fields that are retrieved unless you are accessing a SQL database
table containing an unusually large number of fields.

Arguments:

   -user    Name of user
   -fields  List reference to fields to retrieve (optional)
   -name    Alias for -user
   -field   Alias for -fields

The return value is a hash reference.  You can retrieve the actual
values like this:

   $fields = $db->get_fields(-user=>'fred');
   print $fields->{'Full_Name'};

=item set_passwd()

   $resultcode = $db->set_passwd(-user=>'username',
                                 -password=>'password',
                                 -fields=>\%extra_fields);

set_passwd() sets the user's password and/or additional field
information.  If the user does not already exist in the database, he
is created.  The method requires the username and one or more of the
new password and a hash reference to additional user fields.  If
either the password or the additional fields are absent, they will be
unchanged.

When setting field values, the old and new values are merged.  To
delete a previous field value, you must explicitly set it to undef in
the hash reference.  Otherwise the previous value will be retained.

A result code of true indicates a successful update.  The method will
fail unless the database is opened for writing.

Arguments:

    -user      Name of the user to update
    -password  New password
    -fields    Hash ref to the fields to update
    -name      Alias for -user
    -passwd    Alias for -password
    -gcos      Alias for -fields

=item set_password()

   $resultcode = $db->set_password(-user=>'username',
                                   -password=>'password',
                                   -fields=>\%extra_fields);

This is an alias for set_passwd(), just to make life interesting.

=item set_fields()

   $resultcode = $db->set_fields(-user=>'username',
                                 -fields=>\%extra_fields);

set_fields() allows you to adjust the extra field information about
the designated user.  Its functionality is identical to set_passwd(),
but the name is a little more appropriate.  This method requires a
user name and a hash reference containing new field values.

When setting field values, the old and new values are merged.  To
delete a previous field value, you must explicitly set it to undef in
the hash reference.  Otherwise the previous value will be retained.

Arguments:

    -user      Name of the user to update
    -fields    Hash ref to the fields to update
    -name      Alias for -user
    -gcos      Alias for -fields

A true result code indicates that the database was successfully
updated.  The database must be writable for this method to succeed.

=item set_group()

   $resultcode = $db->set_group(-user=>'username',
                                -group=>\@list_of_groups);

This method allows you to set the list of groups that a user belongs
to without changing any other information about him or her.  It
expects a user name and a list reference pointing to the groups to
assign the user to.  The user will be removed from any groups he
previously participated in.

Arguments:

    -user      Name of the user to update
    -group     List of groups to assign user to
    -name      Alias for -user
    -grp       Alias for -group

A true result code indicates that the database was successfully
updated.  The database must be writable for this method to succeed.

=item delete_user()

   $resultcode = $db->delete_user(-user=>'username');

Delete the user and all his associated information from the database.
If there are any empty groups after this deletion, they are removed as
well.  This operation is irreversible.

Arguments:

    -user      Name of the user to remove
    -name      Alias for -user

A true result code indicates that the database was successfully
updated.  The database must be writable for this method to succeed.

You may also call this method with a single positional
argument:

   $resultcode = $db->delete_user('username');

=item delete_group()

   $resultcode = $db->delete_group(-group=>'groupname');

Delete the group from the database.  Users who participate in the
deleted group are B<not> deleted.  However, they may find themselves
orphaned (not participating in any groups).

Arguments:

    -group      Name of the user to remove
    -grp        Alias for -group

A true result code indicates that the database was successfully
updated.  The database must be writable for this method to succeed.

You may also call this method with a single positional argument:

   $resultcode = $db->delete_group('groupname');

=item errstr()

   $error = $db->errstr();

This method returns a string describing the last error encountered by
RealmManager.pm.  It is not reset by successful function calls, so its
contents are only valid after a method returns a false result code.

=back

=head1 SEE ALSO

HTTPD::Realm(3) HTTPD::UserAdmin(3) HTTPD::GroupAdmin(3), HTTPD::Authen(3)

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

Copyright (c) 1997, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

