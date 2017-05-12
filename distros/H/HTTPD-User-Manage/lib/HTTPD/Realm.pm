package HTTPD::RealmDef;
use Carp;

use strict;
use HTTPD::RealmManager;
use vars qw($VERSION);

$VERSION = $HTTPD::Realm::VERSION = 1.52;

use overload '""'=>\&name;

sub new { 
    my ($class,$name) = @_;
    return bless { 'name' => $name },$class;
}

sub userdb {
    my $self = shift;
    return $self->{users} || $self->{userfile};
}

sub groupdb {
    my $self = shift;
    return $self->{groups} || $self->{groupfile};
}

# backwards compatability only
sub userfile { return &userdb; }
sub groupfile { return &groupdb; }

sub mode { 
    return shift->{mode} || 0644;
}

sub database {
    return shift->{database} || "www\@localhost";
}

#
# added by John Porter:
#
sub dblogin {
    return shift->{dblogin};
}
sub dbpassword {
    return shift->{dbpassword};
}

sub fields {
    return shift->{fields};
}

sub usertype {
    my $self = shift;
    return $self->{usertype} || $self->{type};
}

sub grouptype {
    my $self = shift;
    return $self->{grouptype} || $self->{type};
}

sub authentication {
    return shift->{'authentication'} || 'Basic';
}

sub driver {
    return shift->{'driver'} || 'mSQL';
}

sub server {
    return shift->{'server'} || 'apache';
}

sub crypt {
    my $self = shift;
    return $self->{'crypt'} if $self->{'crypt'};
    return 'crypt' if lc($self->authentication) eq 'basic';
    return 'MD5'   if lc($self->authentication) eq 'digest';
    return 'crypt';  # default currently
}

sub name {
    return shift->{'name'};
}

# return a pointer to an associative array with mSQL info.
# it will contain the keys:
# host                name of the database host
# database            name of the database
# dblogin
# dbpassword
# usertable           name of the table that user/passwd/other info is in
# grouptable          name of the table containing user/group pairs
# userfield           name of the user field (both tables)
# groupuserfield
# groupfield          name of the group field (group table only)
# passwdfield         name of the password field (user table only)
# userfield_len       length of the user field
# groupfield_len      length of the group field
# passwdfield_len     length of the password field
sub SQLdata {
    my $self = shift;
    return undef unless $self->usertype=~/sql/i;
    my ($u,$g) = ($self->split_parms($self->userdb),$self->split_parms($self->groupdb));
    my %result;
    @result{qw(database host)} = split('@',$self->database);
    $result{host}           ||= 'localhost';
#
# Do what Lincoln didn't:
    $result{dblogin}        = $self->dblogin;
    $result{dbpassword}     = $self->dbpassword;
#
    $result{usertable}      = $u->{table}  || 'users';
    $result{grouptable}     = $g->{table};  # no default
    $result{userfield}      = $u->{uid} || $g->{uid} ||  'users';
    $result{groupuserfield} = $g->{uid} || $u->{uid} || 'users';
    $result{groupfield}     = $g->{group};
    $result{passwdfield}    = $u->{password} || 'password';
    $result{userfield_len}  = $u->{uid_len} || $u->{user_len} || 12;
    $result{groupfield_len} = $g->{group_len} || 20;
    $result{passwdfield_len}= $u->{password_len} || 
	(lc($self->authentication) eq 'digest' ?  32 + 3 + length($self->name) + $result{userfield_len} : 13);
    return \%result;
}

sub connect {
    my $self = shift;
    my ($writable,$mode,$server) = rearrange([[qw(WRITABLE WRITE MODIFY)],qw(MODE SERVER)],@_);
    return new HTTPD::RealmManager(-realm   => $self,
				  -writable => $writable,
				  '-mode'     => $mode || $self->mode,
				  '-server'   => $server || $self->server || 'apache');
}

# A utility routine
sub split_parms {
    my($self,$j) = @_;
    my($junk,%p) = split(/\s*(\w+)=/,$j);
    foreach (keys %p) {
	$p{$_}=~s/^"//;
	$p{$_}=~s/"$//;
	if ($p{$_}=~/:[a-zA-Z]?(\d+)$/) {
	    $p{$_}=$`;
	    $p{"${_}_len"}=$1;
	}
    }
    \%p;
}

# ----------------------------------------------------------------------------------------
package HTTPD::Realm;

use strict;
use HTTPD::RealmManager;
use Carp;

*dbm = \&connect;

my %CACHE;

my %VALID_DIRECTIVES = (
'dblogin' =>1,
'dbpassword' =>1,
    'users'             =>1, # file or table of user/passwd info
    'groups'            =>1, # file or table of user/group info
    'database'          =>1, # database name (SQL only)
    'fields'            =>1, # other fields (SQL only)
    'type'              =>1, # db type (text|NDBM|DB|mSQL|SQL)
    'driver'            =>1, # SQL db driver type [mSQL]
    'usertype'          =>1, # override db type for users only
    'grouptype'         =>1, # override db type for groups only
    'default'           =>1, # set default realm
    'authentication'    =>1, # authentication scheme (Basic|Digest)
    'server'            =>1, # server type (Apache|NCSA|Netscape)
    'mode'              =>1, # mode for newly-created text & DBM files
    'crypt'             =>1, # override encryption, backward compatability only
    'userfile'          =>1, # synonyms for backward compatability only
    'groupfile'         =>1, # synonyms for backward compatability only
);

# Security realm parsing utility -- high level interface to Doug MacEachern's
# HTTPD utilities.

# Pass the location of the configuration file.
sub new {
    my $class = shift;
    my ($config_file) = rearrange([[qw(CONFIG CONFIG_FILE)]],@_);

    if ($CACHE{$config_file} && -C $config_file == $CACHE{$config_file}{ctime}) {
	return $CACHE{$config_file}{obj};
    }

    my $self = { config_file   => $config_file, };

    my($realm,$realm_name,$directive,$value,$default_realm,$first_realm);
    open(CONF,$config_file) || croak "Couldn't open $config_file: $!";
    while (<CONF>) {
	chomp;
	s/\#.*$//;			# get rid of all comments

	if (/<Realm\s*(\S*)\s*>/i) {
	    croak "Syntax error in $config_file, line $.: Missing </Realm> directive.\n"
		if $realm;
	    croak "Syntax error in $config_file, line $.: <Realm> directive without realm name.\n"
		unless $1;
	    $realm = new HTTPD::RealmDef($realm_name = $1);
	    $first_realm = $realm unless $first_realm;
	    next;
	}

	if (/<\/Realm\s*>/i) {
	    croak "Syntax error in $config_file, line $.: </Realm> seen without preceding <Realm> directive.\n"
		unless $realm;
	    croak "Incomplete definition for realm $realm.  Need Users and Type directives at line $.\n"
		unless $realm->userdb && $realm->usertype;
	    $self->{realms}->{$realm_name}=$realm;
	    undef $realm;
	    undef $realm_name;
	    next;
	}

	next unless ($directive,$value) = /(\w+)\s*(.*)/;
	croak "Syntax error in $config_file, line $.: $directive directive without preceding <Realm> tag.\n"
	    unless $realm;
	
	$directive=~tr/A-Z/a-z/;
	croak "Unknown directive \"$directive\" at line $.\n"
	    unless $VALID_DIRECTIVES{$directive};

	$realm->{$directive} = $directive =~ /file/ ? untaint($value) : $value;
	if ($directive eq 'default') {
	    croak "More than one Default directive defined at $config_file, line $.\n"
		if $default_realm;
	    $default_realm = $realm_name;
	}

    }
    close CONF;

    $self->{default_realm}=$default_realm || $first_realm;
    bless $self,$class;
    $CACHE{$config_file}{ctime} = -C $config_file;
    return $CACHE{$config_file}{obj} = $self;
}

sub connect {
    my $self = shift;
    my ($writable,$realm,$mode) = rearrange([[qw(WRITABLE WRITE MODIFY)],qw(REALM MODE)],@_);
    my $r = $self->realm($realm);
    die "Unknown realm $realm" unless ref($r);
    my(@p);
    push(@p,'-writable'=>$writable) if $writable;
    push(@p,'-mode'=>$mode) if $mode;
    return $r->connect(@p);
}

sub exists {
    my $self = shift;
    my ($realm) = rearrange(['REALM'],@_);
    return defined($self->{realms}->{$realm});
}

sub list {
    my $self = shift;
    return sort keys %{$self->{realms}};
}

sub realm {
    my $self = shift;
    my ($realm) = rearrange(['REALM'],@_);
    $realm ||= $self->{default_realm};
    return $self->{realms}->{$realm};
}

sub untaint {
    my $taint = shift;
    croak('Relative paths are not allowed in password and/or group file definitions')
	if $taint =~ /\.\./ or $taint !~ m|^/|;
    $taint =~ m!(/[a-zA-Z/0-9._-]+)!;
    return $1;
}

sub DESTROY {
  my $self = shift;
}


1;

__END__

=head1 NAME

HTTPD::Realm - Database of HTTPD Security Realms

=head1 SYNOPSIS

    use HTTPD::Realm;

    # pull out the definition of the "members" realm
    $realms = new HTTPD::Realm(-config_file=>'/home/httpd/conf/realms.conf');
    $def = $realms->realm(-realm=>'members');

    # show info about the realm
    print "realm name = ",     $def->name,"\n";
    print "user database = ",  $def->userdb,"\n";
    print "group database = ", $def->groupdb,"\n";
    print "user type = ",      $def->usertype,"\n";
    print "group type = ",     $def->grouptype,"\n";
    print "web server type = ",$def->server,"\n";
    print "cryptography = ",   $def->crypt,"\n";
    print "other fields = ",   $def->fields,"\n";

    # Connect to the database for the realm,
    # returning a HTTPD::RealmManager object.
    $database = $def->connect(-writable=>1);

=head1 DESCRIPTION

HTTPD::Realm defines high level security realms to be used in
conjunction with Apache, Netscape and NCSA Web servers.  You define
the realms in a central configuration file, and access their
underlying databases via this module and the HTTPD::RealmManager
library.  This allows automated tools to change user passwords, groups
and other information without regard to the underlying database
implementation.

B<Important note:> Do not use these modules to adjust the Unix
password or group files.  They do not have the same format as the Web
access databases.

=head1 CONFIGURATION FILE

A typical configuration file is shown below.  It is human readable and
similar in form to conventional Apache and NCSA HTTPD configuration
files.  Directives are separated from their arguments by white space
(tabs or spaces), and comments begin with hash marks (#).  By
convention, the standard configuration file is named "realms.conf",
but you can give it any name you prefer.

# realms.conf
<Realm main>
        Type            text
        Authentication  Basic
        Users           /home/httpd/security/passwd
        Groups          /home/httpd/security/group
</Realm>

<Realm development>
        Type            DBM
        Authentication  Basic
        Users           /home/httpd/security/devel.passwd
        Groups          /home/httpd/security/devel.group
</Realm>

<Realm members@capricorn.org>
        Type            text
        Authentication  Digest
        Users           /home/httpd/1.1/passwd
        Groups          /home/httpd/1.1/group
</Realm>

<Realm subscriptions>
        Type            MSQL
        Authentication  Basic
        Database        web_accounts@localhost
        Users           table=users uid=name passwd=pass
        Groups          table=groups group=group
	Fields          Name Age:i Paid:s1
</Realm>

realms.conf is made up of one or more <Realm> sections.  The
opening <Realm> tag must contain the realm's name, which can be
any set of non-whitespace characters.  Each section contains
directives that tells the module what type of
authentication to use for the realm, what type of database to use, and
where to find the files or database tables used for the realm.  The
users and groups defined in one realm are independent of those defined
in another, giving you a lot of flexibility in setting up access
control for your site.

The example shown here defines four different security realms.  The
first, named "main", uses human readable text files and the Basic
Authentication protocol.  The second, "development", also uses Basic
Authentication, but stores users and groups in DBM files rather than
in text files.  The realm named "members@capricorn.org" uses Digest
Authentication on top of textfiles.  By convention, Digest realms look
like e-mail addresses, but you don't have to follow this convention.
The last realm definition uses Basic Authentication on top of an mSQL
database.

The directives allowed within a <Realm> section are listed here:

B<Directive>    B<Example Param>        B<Description>
 Type           DBM               Database type
 Authentication Basic             Authentication scheme
 Users          /etc/httpd/passwd Path to user database
 Groups         /etc/httpd/group  Path to group database
 Database       www@capricorn.com Location of mSQL db
 Server         NCSA              Type of server
 Driver         mSQL              DBI driver
 Fields         name age paid     Additional user fields
 Mode           0644              Mode for new files
 Default                          Default realm

=over 4

=item Type

This directive specifies the database type.  It can be any of
"text," "DBM," "DB," or "SQL."  Although these are the only
databases currently recognized by Apache, other Unix DBM-like
formats, including "GDBM," and "SDBM" are recognized for future
compatibility.  You may use "MSQL" as an alias for "SQL."

=item Authentication

This directives specifies the type of authentication to use.  It
can be either "Basic" or "Digest."

=item Users

This is the path to the file or database table that holds user names
and passwords.  For everything but SQL databases, it's a physical path
to a file on your system.  If the database file doesn't exist (and the
process has sufficient privileges), it will be created.  For example:

  Users /home/httpd/security/passwd

For mSQL databases, the value of the directive should have the format:

   Users table=table_name uid=user_field password=password_field

The value of I<table> is the name of the table in which to look for
the user.  The value of I<uid> and I<password> are the fields in which
Apache will look for the user ID and password.  For lookup efficiency,
the uid field should be defined as the primary key field in mSQL.

You may optionally place a colon and field width after any of the
table names.  These field widths are used as hints by the user_manage
script to create a nicely-laid out fill-out form.  If not provided,
reasonable defaults are assumed

Here's an example of a valid directive in which the user ID field is
given a width of 40:

   Users table=Members uid=Name:40 password=Pass

mSQL tables are B<not> created automatically.  You have to define them
yourself (using the I<msql> application) before using them.

=item Groups

This is the path to the file or database table that holds group
assignments.  If you don't need groups, just leave the directive out.
For everything but MSQL databases, the argument physical path to a
file on your system.  If the database file doesn't exist (and the
process has sufficient privileges), it will be created.  For example:

  Groups /home/httpd/security/groups

For mSQL databases, the directive points to a
previously-defined table and field in the database in the format

  Groups table=table_name group=group_field

The value of I<table> is the name of the table in which to look up the
user.  The value of I<group> is the field in which Apache find the
group that the user belongs to.  Apache will look for the user name in
the same field as declared in the I<Users> directive, so don't declare
another I<uid> field here.  You can use the same table for both Users
and Groups, or use separate ones.  In the latter case, you can have
several records for each user, allowing the one user to belong to
multiple groups.

As for the User directive, you can provide an optional field width for
the group field when using mSQL databases.

=item Database

This directive is valid for SQL databases only and indicates where the
authentication database can be found.  It should be in the format
I<database>@I<host>.  If the hostname is omitted, "localhost" is
assumed.  For mSQL databases, performance will be much better if
database and Web server are on the same machine because in this case,
the client and server use a Unix socket to communicate rather than a
TCP/IP socket.

=item Server

Web servers differ slightly in the format of the users and groups
databases.  This directive indicates which server you are using.
Recognized values include "apache", "ncsa", "cern" and "netscape."
Example:

   Server cern

If no server is specified, "apache" is assumed.  If your server is not
on this list, try "ncsa".

=item Driver

For SQL databases only, this directive specifies what DBD (database
driver) module to use.  It defaults to "mSQL".  You can use any
database for which a DBD module is available.  You must also, of
course, compile and configure the Web server to correctly use the
driver.

=item Fields

This directive lists other fields that can be found in the user table.
These fields can then be read and set automatically by the user_manage
application.  Note that this works reliably in SQL databases only.
Large fields, or fields that contain the "=" character, will fail when
applied to text or DBM files.

This directive expects a list of field names in the format
I<name>[:I<type>][I<width>].  The field type and width are hints used
by the user_manage application to format the field values correctly.
The type can be one of "i", for an integer value, "s" for a string
value and "f" for a floating point number.  If not specified, the
field is assumed to be of type string.  The field value must be an
integer.  

In this example, we define three fields named "Name", "Age" and
"Paid".  The first is a string value of default length.  The second is
an integer.  The third is a string of length one (it's assumed to be a
"Y" or "N"):

  Fields	Name Age:i Paid:s1

Other fields may be present in the database.  The Fields directive
tells the user_manage script which fields should be made visible to
the user interface.

=item Mode

This directive sets the mode that Realm.pm will use to create the
database files, if it needs to.  The mode should be in octal form.
This value can be overriden with the -mode argument in the connect()
method.  The default is 0644 (-rw-r--r--).

=item Default

If this directive is present, the current realm becomes the default to
use when no realm is explicitly indicated.  If no section in the
configuration file contains this directive, the first defined realm
becomes the default.  It is a fatal error for Default to appear in
more than one section.

=back

=head1 CLASSES

There are two closely tied classes in Realm.pm.  HTTPD::Realm parses
the configuration file, maintains lists of realms, responds to
inquiries about realms, and opens up connections to realms'
underlying databases.  HTTPD::RealmDef defines the object that holds
information about a particular realm.

=head1 HTTPD::Realm METHODS

=over 4

=item new()

   $realms = HTTPD::Realm->new(-config=>'/path/to/config/file');

Create a new set of realm definitions from the given configuration
file.

=item exists()

   $exists = $realms->exists(-realm=>'subscribers');

Returns true if the named realm exists.  Otherwise returns undef.
Arguments:

   -realm    Name of the realm.

An alternative form is to use the name of the realm without the named
argument:

    $exists = $realms->exists('subscribers');

=item list()

    @realms = $realms->list();

Returns the list of realm names defined in the configuration file.

=item realm()

    $realmdef = $realms->realm(-realm=>'subscribers');

Returns the RealmDef object that defines the realm.  See the
discussion below for more details.  An alternative form is to use the
name of the realm alone:

    $realmdef = $realms->realm('subscribers');

=item connect()

   $database = $realms->connect(-realm=>'subscribers',
                                -writable=>1,
                                -mode=>0600);

Connect to the named realm, returning a database handle (actually, a
RealmManager object). Recognized named arguments are:

  -realm     Name of the realm.
  -mode      Mode with which to create file, if necessary.
  -writable  Whether this realm is to be writable.

By default, realms are opened read-only.  If you choose to open it for
writing, you can provide a mode for creting the file, overriding the
mode defined in the configuration file.  If the realm is not listed in
the configuration file, this routine returns undef.

=back

=head1 HTTPD::RealmDef METHODS

=over 4

=item new()

  $realmdef = HTTPD::RealmDef->new('subscribers');

Create a new RealmDef and assign it a name.  This method is usually
called internally.

=item name()

	$name = $realmdef->name();

Return the name of this realm.

=item userdb()

	$userdata = $realmdef->userdb();

Return the path to the user database defined in the configuration
file.  For non-SQL databases, this is the path to the database or text
file.  For SQL databases, this is the table and field definition line.
You can get a pre-parsed version of this information using SQLdata(),
see below.


=item groupdb()

        $groupdata = $realmdef->groupdb();

Return the path to the group database defined in the configuration
file.  For non-SQL databases, this is the path to the database or text
file.  For SQL databases, this is the table and field definition line.
You can get a pre-parsed version of this information using SQLdata(),

=item mode()

        $mode = $realmdef->mode();

Return the mode for creating the database file.

=item database()

        $database = $realmdef->database();

Return the database name and host (SQL databases only).

=item fields()

        $fields = $realmdef->fields();

Return the additional field definition line (SQL databases only).  No
additional parsing is performed.

=item usertype()

        $type = $realmdef->usertype();

Return the type of the user/password database, for example "NDBM".

=item grouptype()

        $type = $realmdef->grouptype();

Return the type of the group database, for example "NDBM".

=item authentication()

        $authentication = $realmdef->authentication();

Returns the authentication in use for this realm.  May be either
"Basic" or "Digest".

=item server()
    
        $server = $realmdef->server();

Return the type of Web server this realm is designed for.

=item crypt()

        $crypt = $realmdef->crypt();

Return the cryptography type for this realm, either "crypt" or "MD5".

=item SQLdata()

        $data = $realmdef->SQLdata();

For SQL databases only, return the parsed information from the Users
and Groups directives.  The value returned is an associative array
containing the following fields:

   database        name of the SQL database
   host            name of the SQL database host
dblogin
dbpassword
   usertable       name of the SQL table containing users & passwords
   grouptable      name of the SQL table containing groups
   userfield       name of the field containing the user ID
groupuserfield
   groupfield      name of the field containing the group name
   passwdfield     name of the field containing the encrypted password
   userfield_len   length of the user ID field
   groupfield_len  length of the group field
   passwdfield_len length of the password field

=item connect()

   $database = $realmdef->connect(-writable=>1,
                                  -mode=>0600,
                                  -server=>'ncsa');

Establish a connection to the realm database, returning a RealmManager
object.  You can open up a connection read-only or read-write.
Optional arguments allow you to the values of the Mode and Server
directives.

   -writable      Open read/write if true.
   -mode          Override file creation mode.
   -server        Override server type.

=back

=head1 SEE ALSO

HTTPD::RealmManager(3) HTTPD::UserAdmin(3) HTTPD::GroupAdmin(3), HTTPD::Authen(3)

=head1 AUTHOR

Lincoln Stein <lstein@cshl.org>

Copyright (c) 1997, Lincoln D. Stein

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

