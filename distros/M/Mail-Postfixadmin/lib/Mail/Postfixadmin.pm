#! /usr/bin/perl


package Mail::Postfixadmin;

use strict;
use 5.010;
use DBI;		# libdbi-perl
use Crypt::PasswdMD5;	# libcrypt-passwdmd5-perl
use Carp;
use Data::Dumper;

our $VERSION;
$VERSION = "0.20130624";

=pod

=head1 NAME

Mail::Postfixadmin - Interferes with a Postfix/MySQL virtual mailbox system

=head1 SYNOPSIS

Mail::Postfixadmin is an attempt to provide a bunch of functions that wrap
around the tedious SQL involved in interfering with a Postfix/Dovecot/MySQL 
virtual mailbox mail system.

This is also completely not an object-orientated interface to the 
Postfix/Dovecot mailer, since it doesn't actually represent anything sensibly 
as objects. At best, it's an object-considering means of configuring it.

    use Mail::Postfixadmin;
    
    my $pfa = Mail::Postfixadmin->new();
    $pfa->createDomain(
        domain        => 'example.org',
        description   => 'an example',
        num_mailboxes => '0',
    );
    
    $pfa->createUser(
        username       => 'avi@example.com',
        password_plain => 'password',
        name           => 'avi',
    );
    
    my %dominfo = $pfa->getDomainInfo();
    
    my %userinfo = $pfa->getUserInfo();
    
    $pfa->changePassword('avi@example.com', 'complexpass');


=head1 CONSTRUCTOR AND STARTUP

=head2 new()

Creates and returns a new Mail::Postfixadmin object; will parse a Postfixadmin 
c<config.inc.php> file to get all the configuration. It will check some common 
locations for this file (c</var/www/postfixadmin>, c</etc/postfixadmin>) and you
may specify the file to parse by passing c<postfixAdminConfigFile>:

  my $v = Mail::Postfixadmin->new(
  	PostfixAdminConfigFile => '/home/alice/public_html/postfixadmin/config.inc.php';
  )


);


=cut


sub new() {
	my $class = shift;
	my %defaults = (
	);
	my %params = @_;
	my %conf = (%defaults, %params);
	my $self = {};

	my %_tables = _tables();
	$self->{'_tables'} = _tables();
	$self->{'_fields'} = _fields();
	$self->{'_postfixAdminConfig'} = _parsePostfixAdminConfigFile($conf{'postfixAdminConfigFile'});

	#As much config as possible comes from PostfixAdmin's config file:
	foreach(qw/database_password database_host database_prefix database_name database_type database_user/){
		$conf{$_} = $self->{'_postfixAdminConfig'}->{$_} unless exists($conf{$_});
	}

	$self->{'_dbi'} = _createDBI(\%conf);

	bless($self,$class);
	return $self;
}



=head1 METHODS

=head3 getDomains() 

Returns an array of domains on the system. This is all domains for
which the system will accept mail, including aliases.

Accepts a pattern as an argument, which causes it to return only 
domains whose names match that pattern:

  @domains = $getDomains('com$');

=cut

sub getDomains(){
	my $self = shift;
	my $regex = shift;
	my @results;
	@results = $self->_dbSelect(
		table => 'domain',
		fields => [ "domain" ],
	);
	if($regex){
		@results = grep (/$regex/, @results);
	}
	my @domains = map ($_->{'domain'}, @results);
	return @domains;
}

=head3 getDomainsAndAliases()

Returns a hash describing all domains on the system. Keys are domain names
and values are the domain for which the key is an alias, where appropirate.

As with getDomains, accepts a regex pattern as an argument.

  %domains = getDomainsAndAliases('org$');
  foreach(keys(%domains)){
	if($domains{$_} =~ /.+/){
		print "$_ is an alias of $domains{$_}\n";
	}else{
		print "$_ is a real domain\n";
	}
  }

=cut

sub getDomainsAndAliases(){
	my $self = shift;
	my $regex = shift;
	my @domains = $self->getDomains($regex);
	# prepend a null string so that we definitely get a domain every odd-
	# numbered element of the list map returns, else the hash looks a bit
	# weird
	my %domainsWithAliases = map {$_ => "".$self->getAliasDomainTarget($_)} @domains;
	return %domainsWithAliases;
}

=head3 getUsers()

Returns a list of all users. If a domain is passed, only returns users on that domain.

  @users = getUsers('example.org');

=cut

sub getUsers(){
	my $self = shift;
	my $domain = shift;
	my (@users,@aliases);
	@users = $self->getRealUsers($domain), $self->getAliasUsers($domain);
	return @users;
}

=head3  getUsersAndAliases()

Returns a hash describing all users on the system. Keys are users and values are
their targets.

as with C<getUsers>, accepts a pattern to match.

  %users = getUsersAndAliases('example.org');
  foreach(keys(%users)){
	if($users{$_} =~ /.+/){
		print "$_ is an alias of $users{$_}\n";
	}else{
		print "$_ is a real mailbox\n";
	}
  }
=cut

sub getUsersAndAliases(){
	my $self = shift;
	my $regex = shift;
	my @users = $self->getUsers($regex);
	# prepend a zero-length string so that we definitely have a domain at 
	# every odd-numbered element returned by the map else the hash looks a bit
	# weird
	my %usersWithAliases = map {$_ => "".$self->getAliasUserTarget($_)} @users;
	return %usersWithAliases;
}

=head3 getRealUsers() 

Returns a list of real users (i.e. those that are not aliases). If a domain is
passed, returns only users on that domain, else returns a list of all real 
users on the system.

  @realUsers = getRealUsers('example.org');

=cut

sub getRealUsers(){
	my $self = shift;
	my $domain = shift;
	my $query;
	my @results;
	if ($domain =~ /.+/){
		@results = $self->_dbSelect(
			table  => 'mailbox',
			fields => [ 'username' ],
			equals => [ 'domain', $domain],
		);
	}else{
		@results = $self->_dbSelect(
			table  => 'alias',
			fields => [ 'address' ],
			equals => [ 'goto', ''],
		);
	}
	my @users;
	@users = map ($_->{'username'}, @results);
	return @users;
}

=head3 getAliasUsers()

Returns a list of alias users on the system or, if a domain is passed as an argument, 
the domain.

  my @aliasUsers = $p->getAliasUsers('example.org');

=cut

#TODO: getAliasUsers to return a hash of Alias=>Target

sub getAliasUsers() {
	my $self = shift;
	my $domain = shift;
	my @results;
	if ( $domain ){
		my $like = '%'.$domain; 
		@results = $self->_dbSelect(
			table  => 'alias',
			fields => ['address'],
			like   => [ 'goto' , $like ] ,
		);
	}else{
		@results = $self->_dbSelect(
			table => 'alias',
			fields => ['address'],
		);
	}
	my @aliases = map ($_->{'address'}, @results);
	return @aliases;
}

=head3 domainExists()

Check for the existence of a domain. Returns the number found with that name if
positive, undef if none are found.

  if($p->$domainExists('example.org')){
  	print "example.org exists!\n";
  }	

=cut

sub domainExists(){
	my $self = shift;
	my $domain = shift;
	my $regex = shift;
	if ($domain eq ''){
		_error("No domain passed to domainExists");
	}
	if($self->domainIsAlias($domain) > 0){
		return $self->domainIsAlias($domain);
	}
	my $query = "select count(*) from $self->{'_tables'}->{domain} where $self->{'_fields'}->{domain}->{domain} = \'$domain\'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	my $count = ($sth->fetchrow_array())[0];
	$self->{infostr} = $query;
	if ($count > 0){
		return $count;
	}else{
		return;
	}
}

=head3 userExists()

Check for the existence of a user. Returns the number found with that name if
positive, undef if none are found.

  if($p->userExists('user@example.com')){
  	print "user@example.com exists!\n";
  }


=cut 

sub userExists(){
	my $self = shift;
	my $user = shift;

	if ($user eq ''){
		_error("No username passed to userExists");
	}

	if ($self->userIsAlias($user)){
		return $self->userIsAlias($user);
	}
	my $query = "select count(*) from $self->{'_tables'}->{mailbox} where $self->{'_fields'}->{mailbox}->{username} = '$user'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	my $count = ($sth->fetchrow_array())[0];
	$self->{infostr} = $query;
	if ($count > 0){
		return $count;
	}else{
		return;
	}
}

=head3 domainIsAlias()

Check whether a domain is an alias. Returns the number of 'targets' a domain has if
that's a positive number, else undef.

  if($p->domainIsAlias('example.net'){
      print 'Mail for example.net is forwarded to ". getAliasDomainTarget('example.net');
  }

=cut

sub domainIsAlias(){
	my $self = shift;
	my $domain = shift;

	_error("No domain passed to domainIsAlias") if $domain eq '';

	my $query = "select count(*) from $self->{'_tables'}->{alias_domain} where $self->{'_fields'}->{alias_domain}->{alias_domain} = '$domain'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	my $count = ($sth->fetchrow_array())[0];
	$self->{infostr} = $query;
	if ($count > 0){
		return $count;
	}else{
		return;
	}
}

=head3 getAliasDomainTarget()

Returns the target of a domain if it's an alias, undef otherwise.

  if($p->domainIsAlias('example.net'){
      print 'Mail for example.net is forwarded to ". getAliasDomainTarget('example.net');
  }

=cut

sub getAliasDomainTarget(){
	my $self = shift;
	my $domain = shift;
	if ($domain eq ''){
		_error("No domain passed to getAliasDomainTarget");
	}
	unless ( $self->domainIsAlias($domain) ){
		return;
	}
	my @output = $self->_dbSelect(
		table  => 'alias_domain',
		fields => [ 'target_domain' ],
		equals => [ 'alias_domain', $domain ],
	);
	my %result = %{$output[0]};
	return $result{'target_domain'};
}
		

=head3 userIsAlias()

Checks whether a user is an alias to another address.

  if($p->userIsAlias('user@example.net'){
      print 'Mail for user@example.net is forwarded to ". getAliasUserTarget('user@example.net');
  }

=cut

sub userIsAlias{
	my $self = shift;
	my $user = shift;
	if ($user eq ''){ _error("No user passed to userIsAlias");}
	my $query = "select count(*) from $self->{'_tables'}->{alias} where $self->{'_fields'}->{alias}->{address} = '$user'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	my $count = ($sth->fetchrow_array())[0];
	$self->{infostr} = $query;
	if ($count > 0){
		return $count;
	}else{
		return;
	}
}

=head3 getAliasUserTargets()

Returns an array of addresses for which the current user is an alias.
  
 my @targets = $p->getAliasUserTargets($user);

  if($p->domainIsAlias('user@example.net'){
      print 'Mail for example.net is forwarded to ". join(", ", getAliasDomainTarget('user@example.net'));
  }


=cut 

sub getAliasUserTargets{
	my $self = shift;
	my $user = shift;
	if ($user eq ''){ _error("No user passed to getAliasUserTargetArray");}

	my @gotos = $self->_dbSelect(
		table	=> 'alias',
		fields	=> ['goto'],
		equals	=> [ 'address', $user ],
	);
	return split(/,/, $gotos[0]->{'goto'});
}

=head3 getUserInfo()

Returns a hash containing info about the user:

  username   Username. Should be an email address.
  password   The crypted password of the user
  name       The human name associated with the username
  domain     The domain the user is associated with
  local_part The local part of the email address
  maildir    The path to the maildir *relative to the maildir root 
             configured in Postfix/Dovecot*
  active     Whether or not the user is active
  created    Creation date
  modified   Last modified data

Returns undef if the user doesn't exist.

=cut

sub getUserInfo(){
	my $self = shift;
	my $user = shift;
	_error("No user passed to getUserInfo") if $user eq '';
	return unless $self->userExists($user);
	my %userinfo;
	my @results = $self->_dbSelect(
		table  => 'mailbox',
		fields => ['*'],
		equals => ['username', $user]
	);
	return $results[0];
}

=head3 getDomainInfo()

Returns a hash containing info about a domain. Keys:

  domain          The domain name
  description     Content of the description field
  quota           Mailbox size quota
  transport       Postfix transport (usually 'virtua')
  active          Whether the domain is active or not (0 or 1)
  backupmx        Whether this is a  backup MX for the domain (0 or 1)
  mailboxes       Array of mailbox names associated with the domain 
                  (note: the full username, not just the local part)
  modified        last modified date as returned by the DB
  num_mailboxes   Count of the mailboxes (effectively, the length of the 
                  array in `mailboxes`)
  created         Creation date
  aliases         Alias quota for the domain
  maxquota        Mailbox quota for the domain

Returns undef if the domain doesn't exist.

=cut

sub getDomainInfo(){
	my $self = shift;
	my $domain = shift;

	_error("No domain passed to getDomainInfo") if $domain eq '';
	return unless $self->domainExists($domain);

	my $query = "select * from `$self->{'_tables'}->{domain}` where $self->{'_fields'}->{domain}->{domain} = '$domain'";
	my $domaininfo = $self->{'_dbi'}->selectrow_hashref($query);
	
	# This is exactly the same data acrobatics as getUserInfo() above, to get consistent
	# output:
	my %return;
	my %domainhash = %{$self->{'_fields'}->{domain}};
	my ($k,$v);
	while ( ($k,$v) = each ( %{$self->{'_fields'}->{domain}} ) ){
		my $myname = $k;
		my $theirname = $v;
		my $info = $$domaininfo{$theirname};
		$return{$myname} = $info;
	}
	$self->{infostr} = $query;
	$query = "select username from `$self->{'_tables'}->{mailbox}` where $self->{'_fields'}->{mailbox}->{domain} = '$domain'";
	$self->{infostr}.=";".$query;
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	my @mailboxes;
	while (my @rows = $sth->fetchrow()){
		push(@mailboxes,$rows[0]);
	}
	
	$return{mailboxes} = \@mailboxes;
	$return{num_mailboxes} = scalar @mailboxes;
	
	return %return;
}

=head2 Passwords

=head3 cryptPassword()

This probably has no real use, except for where other functions use it, but
it will always be the currently-favoured Dovecot encrytion scheme. Takes the
cleartext as its argument, returns the crypt.

=cut

sub cryptPassword(){
	my $self = shift;
	my $password = shift;
	my $cryptedPassword = Crypt::PasswdMD5::unix_md5_crypt($password);
	return $cryptedPassword;
}

=head3 changePassword() 

Changes the password of a user. Expects two arguments, a username and a new
password:

	$p->changePassword("user@domain.com", "password");

The salt is picked at pseudo-random; successive runs will (should) produce 
different results.

=cut

sub changePassword(){
	my $self = shift;
	my $user = shift;
	my $password = shift;
	if ($user eq ''){
		_error("No user passed to changePassword");
	}
	my $cryptedPassword = $self->cryptPassword($password);
	$self->changeCryptedPassword($user,$cryptedPassword,$password);
	return $cryptedPassword;
}

=head3 changeCryptedPassword()

changeCryptedPassword operates in exactly the same way as changePassword, but it 
expects to be passed an already-encrypted password, rather than a clear text 
one. It does no processing at all of its arguments, just writes it into the 
database.

=cut

sub changeCryptedPassword(){
	my $self = shift;
	my $user = shift;;

	if ($user eq ''){
		_error("No user passed to changeCryptedPassword");
	}
	my $cryptedPassword = shift;
	my $clearPassword = shift;

	my $query = "update $self->{'_tables'}->{'mailbox'} set ";
	$query.="`$self->{'_fields'}->{'mailbox'}->{'password'}`= '$cryptedPassword'";
	if($self->{'storeCleartextPassword'} > 0){
		$query.= ", `$self->{'_fields'}->{'mailbox'}->{'password_clear'}` = '$clearPassword'";
	}
	if($self->{'storeGPGPassword'} > 0){
		my $gpgPassword = $self->cryptPasswordGPG($clearPassword);
		$query.= ", `$self->{'_fields'}->{'mailbox'}->{'password_gpg'}` = '$gpgPassword'";
	}
	$query.="where `$self->{'_fields'}->{'mailbox'}->{'username'}` = '$user'";

	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute();

	return $cryptedPassword;
}

=head2 Creating things

=head3 createDomain()

Expects to be passed a hash of options, with the keys being the same as those 
output by C<getDomainInfo()>. None are necessary except C<domain>.

Defaults are set as follows:

  domain       None; required.
  description  ""
  quota        MySQL's default
  transport    'virtual'
  active       1 (active)
  backupmx0    MySQL's default
  modified     now
  created      now
  aliases      MySQL's default
  maxquota     MySQL's default

Defaults are only set on keys that haven't been instantiated. If you set a key 
to an empty string, it will not be set to the default - null will be passed to 
the DB and it may set its own default.

On both success and failure the function will return a hash containing the 
options used to configure the domain - you can inspect this to see which 
defaults were used if you like.

If the domain already exists, it will not alter it, instead it will return '2' 
rather than a hash.

=cut

sub createDomain(){
	my $self = shift;
	my %opts = @_;
	my $fields;
	my $values;
	my $domain = $opts{'domain'};

	_error("No domain passed to createDomain") if $domain !~ /.+/;

	if($domain eq ''){
		_error("No domain passed to createDomain");
	}

	if ($self->domainExists($domain)){
		$self->{infostr} = "Domain '$domain' already exists";
		return 2;
	}

	$opts{modified} = $self->_mysqlNow unless exists($opts{modified});
	$opts{created} = $self->_mysqlNow unless exists($opts{created});
	$opts{active} = '1' unless exists($opts{active});
	$opts{transport} = 'virtual' unless exists($opts{quota});
	foreach(keys(%opts)){
		$fields.= $self->{'_fields'}->{domain}->{$_}.", ";
		$values.= "'$opts{$_}', ";;
	}
	$fields =~ s/, $//;
	$values =~ s/, $//;
	my $query = "insert into `$self->{'_tables'}->{domain}` ";
	$query.= " ( $fields ) values ( $values )";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute();	
	$self->{infostr} = $query;
	if($self->domainExists($domain)){
		return %opts;
	}else{
		$self->{errstr} = "Everything appeared to succeed, but the domain doesn't exist";
		return;
	}
}

=head3 createUser()

Expects to be passed a hash of options, with the keys being the same as those 
output by C<getUserInfo()>. None are necessary except C<username>.

If both C<password_plain> and <password_crypt> are in the passed hash, 
C<password_crypt> will be used. If only password_plain is passed it will be 
crypted with C<cryptPasswd()> and then used.

Defaults are mostly sane where values aren't explicitly passed:

 username    required; no default
 password    null
 name        null
 maildir     deduced from PostfixAdmin config. 
 quota       MySQL default (normally zero, which represents infinite)
 local_part  the part of the username to the left of the first '@'
 domain      the part of the username to the right of the last '@'
 created     now
 modified    now
 active      MySQL's default


On success, returns a hash describing the user. You can inspect this to see 
which defaults were set if you like.

This will not alter existing users. Instead, it returns '2' rather than a hash.

=cut

sub createUser(){
	my $self = shift;
	my %opts = @_;
	my $fields;
	my $values;

	_error("no username passed to createUser") if $opts{"username"} eq '';
	
	my $user = $opts{"username"};

	if($self->userExists($user)){
		$self->{infostr} = "User already exists ($user)";
		return 2;
	}
	if($opts{password_crypt}){
		$opts{password} = $opts{password_crypt};
	}elsif($opts{password_clear}){
		$opts{password} = $self->cryptPassword($opts{password_clear});
	}

	unless(exists $opts{maildir}){
		$opts{maildir} = $self->_createMailboxPath($user);
	}
	unless(exists $opts{local_part}){
		if($opts{username} =~ /^(.+)\@/){
			$opts{local_part} = $1;
		}
	}
	unless(exists $opts{domain}){
		if($opts{username} =~ /\@(.+)$/){
			$opts{domain} = $1;
		}
	}
	unless(exists $opts{created}){
		$opts{created} = $self->_mysqlNow;
	}
	unless(exists $opts{modified}){
		$opts{modified} = $self->_mysqlNow;
	}
	foreach(keys(%opts)){
		unless( /_(clear|cryp)$/){
			$fields.= $self->{'_fields'}->{mailbox}->{$_}.", ";
			$values.= "'$opts{$_}', ";
		}
	}
	if ($opts{username} eq ''){
		_error("No user passed to createUser");
	}
	$values =~ s/, $//;
	$fields =~ s/, $//;
	my $query = "insert into `$self->{'_tables'}->{mailbox}` ";
	$query.= " ( $fields ) values ( $values )";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute();	
	$self->{infostr} = $query;
	$self->createAliasUser(
		target => $user,
		alias  => $user,
	);
	if($self->userExists($user)){
		return %opts;
	}else{
		$self->{errstr} = "Everything appeared to succeed, but the user doesn't exist";
		return;
	}
}

=head3 createAliasDomain()

Creates an alias domain:

  $p->createAliasDomain( 
    target => 'target.com',
    alias  => 'alias.com'
 );

Will cause mail sent to any address at alias.com to be forwarded on to the same
left-hand-side at target.com

You can pass three other keys in the hash, though only C<target> and C<alias> 
are required:
 created  'created' date. Is passed verbatim to the db so should be in a 
           format it understands.
 modified  Ditto but for the modified date
 active    The status of the domain. Again, passed verbatim to the db, 
           but probably should be a '1' or a '0'.

=cut


sub createAliasDomain {
	my $self = shift;
	my %opts = @_;
	my $domain = $opts{'alias'};
	my $target = $opts{'target'};

	_error("No alias passed to createAliasDomain") if $domain !~ /.+/;
	_error("No target passed to createAliasDomain") if $target !~ /.+/;

	if($self->domainIsAlias($domain)){
		$self->{errstr} = "Domain $domain is already an alias";
		##TODO: createAliasDomain return current target if the domain is already an alias
		return;
	}
	unless($self->domainExists("domain" => $domain)){
		$self->createDomain( "domain" => $domain);
	}
	my $fields = "$self->{'_fields'}->{alias_domain}->{alias_domain}, $self->{'_fields'}->{alias_domain}->{target_domain}";
	my $values = " '$domain', '$opts{target}'";

	$fields.=", $self->{'_fields'}->{alias_domain}->{created}";
	if(exists($opts{'created'})){
		$values.=", '$opts{'created'}'";
	}else{
		$values.=", '".$self->_mysqlNow."'";
	}

	$fields.=", $self->{'_fields'}->{alias_domain}->{modified}";
	if(exists($opts{'modified'})){
		$values.=", '$opts{'modified'}'";
	}else{
		$values.=", '".$self->_mysqlNow."'";
	}
	if(exists($opts{'active'})){
		$fields.=", $self->{'_fields'}->{alias_domain}->{active}";
		$values.=", '$opts{'active'}'";
	}
	my $query = "insert into $self->{'_tables'}->{alias_domain} ( $fields ) values ( $values )";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	if($self->domainExists($domain)){
		$self->{infostr} = $query;
		return %opts;

	}else{
		$self->{infostr} = $query;
		$self->{errstr} = "Everything appeared to succeed but the domain doesn't exist";
		return;
	}
}

=head3 createAliasUser()

Creates an alias user:

  $p->createAliasUser( 
    target => 'target@example.org');
    alias  => 'alias@example.net
  );

will cause all mail sent to alias@example.com to be delivered to target@example.net. 

You may forward to more than one address by passing a comma-separated string:

 $p->createAliasDomain( 
 	target => 'target@example.org, target@example.net',
 	alias  => 'alias@example.net',
 );

The domain is stored separately in the db. If you pass a C<domain> key in the hash, 
this is used. If not a regex is applied to the username ( C</\@(.+)$/> ). If that 
doesn't match, it Croaks.

You may pass three other keys in the hash, though only C<target> and C<alias> are required:

 created   'created' date. Is passed verbatim to the db so should be in a format it understands.
 modified  Ditto but for the modified date
 active    The status of the domain. Again, passed verbatim to the db, but probably should be a '1' or a '0'.

In full:

 $p->createAliasUser(
		source   => 'someone@example.org',
		target	 => "target@example.org, target@example.net",
		domain	 => 'example.org',
		modified => $p->now;
		created	 => $p->now;
		active   => 1
 );

On success a hash of the arguments is returned, with an addtional key: scalarTarget. This is the 
value of C<target> as it was actually inserted into the DB. It will either be exactly the same as 
C<target> if you've passed a scalar, or the array passed joined on a comma.

=cut


sub createAliasUser {
	my $self = shift;
	my %opts = @_;
	my $user = $opts{"alias"};
	if ($user eq ''){
		_error("No alias key in hash passed to createAliasUser");
	}
	unless(exists($opts{'target'})){
		_error("No target key in hash passed to createAliasUser");
	}
# The PFA web ui creates an alias for each user (with itself as the target)
# and so we must either be able to create aliases for users that already
# exist, or have some special case. I can't see a reason for this to be a
# special case so I'm removing the check, but leaving a relic of it to remind 
# me that it did once look like a good idea.
#	if($self->userExists($user)){
#		_error("User $user already exists (passed as alias to createAliasUser)");
#	}
	if($self->userIsAlias($user)){
		_error("User $user is already an alias (passed to createAliasUser)");
	}
	unless(exists($opts{domain})){
		if($user =~ /\@(.+)$/){
			$opts{domain} = $1;
		}else{
			_error("Error determining domain from user '$user' in createAliasUser");
		}
	}
	#TODO: createAliasUser should accept an array of targets
	$opts{scalarTarget} = $opts{target};

	my $fields = "$self->{'_fields'}->{alias}->{address}, $self->{'_fields'}->{alias}->{goto}, $self->{'_fields'}->{alias}->{domain}";
	my $values = "\'$opts{alias}\', \'$opts{scalarTarget}\', \'$opts{domain}\'";
	
	$fields.=", $self->{'_fields'}->{alias_domain}->{created}";
	if(exists($opts{'created'})){
		$values.=", '$opts{'created'}'";
	}else{
		$values.=", '".$self->_mysqlNow."'";
	}

	$fields.=", $self->{'_fields'}->{alias_domain}->{modified}";
	if(exists($opts{'modified'})){
		$values.=", $opts{'modified'}";
	}else{
		$values.=",  '".$self->_mysqlNow."'";
	}

	if(exists($opts{'active'})){
		$fields.=", $self->{'_fields'}->{alias_domain}->{active}";
		$values.=", '$opts{'active'}'";
	}
	my $query = "insert into $self->{'_tables'}->{alias} ( $fields ) values ( $values )";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	
	if($self->userIsAlias($user)){
		return %opts;
	}else{
		return;
	}

}

=head2 Deleting things

=head3 removeUser();

Removes the passed user;

Returns 1 on successful removal of a user, 2 if the user didn't exist to start with.

=cut

##Todo: Accept a hash of field=>MySQL regex with which to define users to delete
sub removeUser(){
	my $self = shift;
	my $user = shift;
	if($user eq ''){
		_error("No user passed to removeUser");
	}
	if (!$self->userExists($user)){
		$self->{infostr} = "User doesn't exist ($user) ";
		return 2;
	}
	my $query = "delete from $self->{'_tables'}->{mailbox} where $self->{'_fields'}->{mailbox}->{username} = '$user'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute();
	$self->{infostr} = $query;
	$self->removeAliasUser($user);
	if ($self->userExists($user)){
		$self->{errstr} = "Everything appeared successful but user $user still exists";
		return;
	}else{
		return 1;
	}
}	
	

=head3 removeDomain()

Removes the passed domain, and all of its attached users (using C<removeUser()> on each).  

Returns 1 on successful removal of a user, 2 if the user didn't exist to start with.

=cut

sub removeDomain(){
	my $self = shift;
	my $domain = shift;
	_error("No domain passed to removeDomain") if $domain eq '';
	
	unless ($self->domainExists($domain) >  0){
		$self->{errstr} = "Domain doesn't exist";
		return 2;
	}
	my @users = $self->getUsers($domain);
	foreach my $user (@users){
		$self->removeUser($user);
	}
	if($self->domainIsAlias($domain)){
		$self->removeAliasDomain($domain);
	}
	my $query = "delete from $self->{'_tables'}->{domain} where $self->{'_fields'}->{domain}->{domain} = '$domain'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	if ($self->domainExists($domain)){
		$self->{errstr} = "Everything appeared successful but domain $domain still exists";
		$self->{infostr} = $query;
		return;
	}else{
		$self->{infostr} = $query;
		return 2;
	}

}

=head3 removeAliasDomain()

Removes the alias property of a domain. An alias domain is just a normal domain which happens to be listed 
in a table matching it with a target. This simply removes that row out of that table; you probably want 
C<removeDomain> if you want to neatly remove an alias domain.

=cut

sub removeAliasDomain{
	my $self = shift;
	my $domain = shift;
	if ($domain eq ''){
		_error("No domain passed to removeAliasDomain");
	}
	if ( !$self->domainIsAlias($domain) ){
		$self->{infostr} = "Domain is not an alias ($domain)";
		return 3;
	}
	my $query = "delete from $self->{'_tables'}->{alias_domain} where $self->{'_fields'}->{alias_domain}->{alias_domain} = '$domain'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
}

=head3 removeAliasUser()

Removes the alias property of a user. An alias user is just a normal user which happens to be listed 
in a table matching it with a target. This simply removes that row out of that table; you probably want 
C<removeUser> if you want to neatly remove an alias user.

=cut
sub removeAliasUser{
	my $self = shift;
	my $user = shift;
	if ($user eq ''){
		_error("No user passed to removeAliasUser");
	}
	if (!$self->userIsAlias($user)){
		$self->{infoStr} = "user is not an alias ($user)";
		return 3;
	}
	my $query = "delete from $self->{'_tables'}->{alias} where $self->{'_fields'}->{alias}->{address} = '$user'";
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute;
	return 1;
}

=head2 Admin Users

=head3 getAdminUsers()

Returns a hash describing admin users, with usernames as the keys, and 
an arrayref of domains as values. Accepts a a domain as an optional 
argument, when that is supplied will only return users who are admins 
of that domain, and each user's array will be a single value (that domain).

  my %admins = $pfa->getAdminUsers();
  foreach my $username (keys(%admins)){
    print "$username is an admin of ", join(" ", @{$admins{$username}}), "\n";
  }

=cut

sub getAdminUsers {
	my $self = shift;
	my $domain = shift;
	my $query;
	my @results;
	if ($domain =~ /.+/){
		@results = $self->_dbSelect(
			table  => 'domain_admins',
			fields => [ 'username', 'domain' ],
			equals => [
				['domain', $domain],
				['domain', 'ALL'],
			],
			equals_andor => 'or',
		);
	}else{
		@results = $self->_dbSelect(
			table  => 'domain_admins',
			fields => [ 'username', 'domain' ],
		);
	}
	my %return;
	foreach(@results){
		if($_->{'domain'} =~ /^ALL$/){
			foreach my $domain ($self->getDomains()){
				push(@{$return{$_->{'username'}}}, $domain) unless $domain =~ /^ALL$/;
			}
		}else{
			push(@{$return{$_->{'username'}}}, $_->{'domain'});
		}
	}
	return %return;
}

=head3 createAdminUser()

Creates an admin user:

$pfa->createAdminUser(
	username       => 'someone@somedomain.net',
	domains        => [ "example.net", "example.com", "example.mil" ],
	password_clear => 'password',
);

Alternatively, create an admin of a single domain:

$pfa->createAdminUser(
	username       => 'someone@somedomain.net',
	domain         => 'example.org',
	password_clear => 'password',
);

If domain is set to 'ALL' then the user is set as an admin of all domains. 

Creating an admin user involves both adding a username and password to the admin
table, and then a domain/user pairing to domain_admins. 
The former is only attempted if you pass a password to this function; calling this
with only a username and a domain simply adds that pair to the domain_admin table.

If you call this with a password and a username that already exists, the row in the 
admin table will remain unchanged, and a warning will be raised. The user/domain 
pairing will still be written to the domain_admins table.

=cut 

sub createAdminUser{
	my $self = shift;
	my %opts = @_;
	_error("No username passed to createAdminUser") unless $opts{'username'};
	_error("No domain passed to createAdminUser") unless $opts{'domain'};
	if($opts{'password_crypt'}){
		$opts{'password'} = $opts{'password_crypt'};
	}elsif($opts{'password_clear'}){
		$opts{'password'} = $self->cryptPassword($opts{'password_clear'});
	}
	
	my @domains;
	if(exists($opts{'domains'})){
		@domains = @{$opts{'domains'}};
	};
	if(exists($opts{'domain'})){
		push(@domains, $opts{'domain'});
	}
	# Only insert a username and password if there's not already
	# that username:
	if($opts{'password'}){
		my @usernameIsAlreadyAdmin = $self->_dbSelect(
		     table  => 'admin',
		     count  => 1,
		     equals => [ 'username', $opts{'username'} ],
		) ;
		
#	say "============================";
#	say Dumper(@usernameIsAlreadyAdmin);
#	say "============================";
		if(@usernameIsAlreadyAdmin[0] > 0){
			$self->_warn("Admin '$opts{'username'}' already exists; not adding to admin table");
		}else{
			$self->_dbInsert(
				data => {
					username => $opts{'username'},
					password => $opts{'password'},
				},
				table => 'admin',
			);
		}
	}
	foreach my $domain(@domains){
		$self->_dbInsert(
			data => {
				username => $opts{'username'},
				domain   => $domain,
			},
			table => 'domain_admins'
		)
	}
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
 # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

#=head2 Utilities
#
#=head3 generatePassword()
#
#Generates a password. It's what all the internal things that offer to
#generate passwords use.
#
#=cut

sub generatePassword() {
	my $self = shift;
	my $length = shift;
	_error("generatePassword() called with no arguments (length required)") if $length =~ /^$/;
	_error("generatePassword() called with non-numeric argument (length expected)") if $length !~ /^\s*\d+\.?\d*\s*$/;
	my @characters = qw/a b c d e f g h i j k l m n o p q r s t u v w x y z
			    A B C D E F G H I J K L M N O P Q R S T U V W X Y Z 
			    1 2 3 4 5 6 7 8 9 0 - =
			    ! " $ % ^ & * ( ) _ +
			    [ ] ; # , . : @ ~ < > ?
			  /;
	my $password;
	for( my $i = 0; $i<$length; $i++ ){
		$password .= $characters[rand($#characters)];
	}
	return $password;
}
#=head3 getOptions()
#
#Returns a hash of the options passed to the constructor plus whatever defaults 
#were set, in the form that the constructor expects.
#
#=cut

sub getOptions{
	my $self = shift;
	my %params = %{$self->{_params}};
	return %params;
}
#=head3 getTables getFields setTables setFields
#
#C<get>ters return a hash defining the table and field names respectively, the
#C<set>ters accept hashes in the same format for redefining the table layout.
#
#Note that this is a representation of what the object assumes the db to be - 
#there's no guessing at all as to what shape the db is so you'll need to tell
#the object through these if you want to change them.
#
#=cut

sub getTables(){
	my $self = shift;
	return $self->{'_tables'}
}
sub getFields(){
	my $self = shift;
	return $self->{'_fields'}
}

sub setTables(){
	my $self = shift;
	$self->{'_tables'} = @_;
	return $self->{'_tables'};
}

sub setFields(){
	my $self = shift;
	$self->{'_fields'} = @_;
	return $self->{'_fields'};
}


=head3 version()

Returns the version string

=cut;

sub version{
	my $self = shift;
	return $VERSION
}


=head2 Private Methods

If you use these and they eat your cat feel free to tell me, but don't expect me to fix it.

=head3 _createMailboxPath()

Deals with the 'mailboxes' bit of the config, the 'canonical' version of which can be found
about halfway down the create-mailbox.php shipped with Postfixadmin:

  // Mailboxes
  // If you want to store the mailboxes per domain set this to 'YES'.
  // Examples:
  //   YES: /usr/local/virtual/domain.tld/username@domain.tld
  //   NO:  /usr/local/virtual/username@domain.tld
  $CONF['domain_path'] = 'YES';
  // If you don't want to have the domain in your mailbox set this to 'NO'.
  // Examples: 
  //   YES: /usr/local/virtual/domain.tld/username@domain.tld
  //   NO:  /usr/local/virtual/domain.tld/username
  // Note: If $CONF['domain_path'] is set to NO, this setting will be forced to YES.
  $CONF['domain_in_mailbox'] = 'NO';
  // If you want to define your own function to generate a maildir path set this to the name of the function.
  // Notes: 
  //   - this configuration directive will override both domain_path and domain_in_mailbox
  //   - the maildir_name_hook() function example is present below, commented out
  //   - if the function does not exist the program will default to the above domain_path and domain_in_mailbox settings
  $CONF['maildir_name_hook'] = 'NO';

"/usr/local/virtual/" is assumed to be configured in Dovecot; the path stored in
the db is concatenated onto the relevant base in Dovecot's own SQL.

=cut 

sub _createMailboxPath(){
	my $self = shift;
	my $mailbox = shift;
	my $p = $self->{'_postfixAdminConfig'};
	my ($user,$domain) = split('@', $mailbox);
	my $maildir;

	if(exists($p->{'maildir_name_hook'}) && ($p->{'maildir_name_hook'} !~ /NO/)){
		$self->_warn("'maildir_name_hook' not yet inplemented in Mail::Postfixadmin");
	}elsif($p->{'domain_path'} eq "YES"){
		if($p->{'domain_in_mailbox'} eq "YES"){
			$maildir = $domain."/".$mailbox."/";
		}else{
			$maildir = $domain."/".$user."/";
		}
	}else{
		$maildir = $mailbox;
	}
	return $maildir;			
}


=head3 _findPostfixAdminConfigFile()

Tries to find a PostfixAdmin config file, checks /var/www/postfixadmin/config.inc.php 
and /etc/phpmyadmin/config.inc.php. Called by C<_parsePostfixAdminConfigFile()> unless
it's passed a path

=cut

sub _findPostfixAdminConfigFile{
	my $file = shift;
	my @candidates = qw# /var/www/postfixadmin/config.inc.php /etc/phpmyadmin/config.inc.php#;
	unshift(@candidates, $file);
	reverse(@candidates);
	foreach my $file (@candidates){
		return $file if -r $file;
	}
}

=head3 _parsePostfixAdminConfigFile()

Returns a hash reference that's an approximation of the $CONF associative array used
by PostfixAdmin for its configuration.

=cut
sub _parsePostfixAdminConfigFile{
#	my $self = shift;
	my $arg = shift ;
	my $file = _findPostfixAdminConfigFile($arg);
	_error("Couldn't find PostfixAdmin config file") unless $file;
	open(my $fh, "<", $file) or _warn("Error parsing PostfixAdmin config file '$file' : $!");
	my %pfaConf;
	while(<$fh>){
		if(/^\s*\$CONF\['([^']+)'\]\s*=\s*'?([^']*)'?\s*;\s*$/){
			$pfaConf{$1} = $2;
		}
	}
	return \%pfaConf;
}

=cut

sub dbCanStoreCleartextPasswords(){
	my $self = shift;
	my @fields = $self->{'_dbi'}->selectrow_array("show columns from $self->{'_tables'}->{mailbox}");
	if (grep(/($self->{'_fields'}->{mailbox}->{password_cleartext})/, @fields)){
		return $1;
	}else{
		return
	}
}

#=head3 now()
#
#Returns the current time in a format suitable for passing straight to the database. Currently is just in MySQL 
#datetime format (YYYY-MM-DD HH-MM-SS).
#
#This shouldn't need to exist, really.
#
#=cut

sub now{
	return _mysqlNow();
}


=head3 _tables()

Returns a hashref describing the default tablee schema. The keys are the names as used in this
module and the values should be the names of the tables themselves.

=cut

sub _tables(){
	my %tables = ( 
	        'admin'         => 'admin',
	        'alias'         => 'alias',
	        'alias_domain'  => 'alias_domain',
	        'config'        => 'config',
	        'domain'        => 'domain',
	        'domain_admins' => 'domain_admins',
	        'fetchmail'     => 'fetchmail',
	        'log'           => 'log',
	        'mailbox'       => 'mailbox',
	        'quota'         => 'quota',
	        'quota2'        => 'quota2',
	        'vacation'      => 'vacation',
	        'vacation_notification' => 'vacation_notification'
	);
	return \%tables;
}

=head3 _fields()

Returns a hashref describing the default field names. The keys are the names as used in this
module and the values should be the names of the fields themselves.

=cut

sub _fields(){
	my %fields;
	$fields{'admin'} = { 
	                        'domain'        => 'domain',
	                        'username'	=> 'username',
				'password'	=> 'password',
				'created'	=> 'created',
				'modified'	=> 'modified',
				'active'	=> 'active'
	};
	$fields{'alias'} = {
				'address'	=> 'address',
				'goto'		=> 'goto',	# Really should have been called 'target'
				'domain'	=> 'domain',
				'created'	=> 'created',
				'modified'	=> 'modified',
				'active'	=> 'active'

	};
	$fields{'domain'} = { 
	                        'domain'        => 'domain',
				'description'	=> 'description',
	                        'aliases'       => 'aliases',
	                        'mailboxes'     => 'mailboxes',
	                        'maxquota'      => 'maxquota',
	                        'quota'         => 'quota',
	                        'transport'     => 'transport',
	                        'backupmx'      => 'backupmx',
	                        'created'       => 'created',
	                        'modified'      => 'modified',
	                        'active'        => 'active'
	};
	$fields{'mailbox'} = { 
	                        'username'      => 'username',
				'password'	=> 'password',
				'name'		=> 'name',
				'maildir'	=> 'maildir',
				'quota'		=> 'quota',
				'local_part'	=> 'local_part',
				'domain'	=> 'domain',
				'created'	=> 'created',
				'modified'	=> 'modified',
				'active'	=> 'active',
				'password_clear'=> 'password_clear',
				'password_gpg'  => 'password_gpg',
	};
	$fields{'domain_admins'} = {
	                        'domain'        => 'domain',
	                        'username'      => 'username'
	};
	$fields{'alias_domain'} = {
				'alias_domain'	=> 'alias_domain',
				'target_domain' => 'target_domain',
				'created'	=> 'created',
				'modified'	=> 'modified',
				'active'	=> 'active'
	};
	return \%fields;
}


=head3 _dbCanStoreCleartestPasswords()

Attempts to ascertain whether the DB can store cleartext passwords. Basically
checks that whatever C<_fields()> reckons is the name of the field for storing
cleartext passwords in is the name of a column that exists in the db.

=cut

sub _dbCanStoreCleartextPasswords{
	my $self = shift;
	my $dbName = (split(/:/, $self->{'_params'}->{'_dbi'}))[2];
	my $tableName = $self->{'_tables'}->{'mailbox'};
	my $fieldName = $self->{'_fields'}->{'mailbox'}->{'password_clear'};
	if(_fieldExists($self->{'_dbi'}, $dbName, $tableName, $fieldName)){
		return;
	}
	return 1;
}

=head3 _createDBI()

Creates a DBI object. Called by the constructor and passed a reference
to the C<%conf> hash, containing the configuration and contructor
options.

=cut

sub _createDBI{
	my $conf = shift;
	my $dataSource = "DBI:".$conf->{'database_type'}.":".$conf->{'database_name'};
	my $username   = $conf->{'database_user'};
	my $password   = $conf->{'database_password'};
	my $dbi = DBI->connect($dataSource, $username, $password);	
	if (!$dbi){
		_warn("No dbi object created");
		return;
	}else{
		return $dbi;
	}
}

=head3 _dbInsert()

A generic sub to pawn all db inserts off onto:

	_dbInsert(
		data => (
			field1 => value1,
			field2 => value2,
			field3 => value3,
		);
		table  => 'table name',
	)
=cut

sub _dbInsert {
	my $self = shift;
	my %opts = @_;
	_error("_dbInsert called with no table name (this is probably a bug in the module)") unless $opts{'table'};
	my $table = $self->_tables->{$opts{'table'}};
	_error ("_dbInsert couldn't resolve passed table ($opts{'table'}) name into a proper table name") unless $table;

	_error("_dbInsert called with no data to insert") unless $opts{'data'};

	my(@fields, @values);
	foreach(keys(%{$opts{'data'}})){
		push(@fields, $_);
		push(@values, $opts{'data'}->{$_});
	}

	my $query = "insert into `$table` ";
	$query.="(`";
	$query.=join("`, `", @fields);
	$query.="`) ";

	$query.= "values (";
	foreach(@values){
		$query.="?, ";
	}
	$query =~ s/, $//;
	$query.=")";

	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute(@values) or _error ("_dbInsert execute failed: $!\nQuery: $query");
	return $?;

}

=head3 _dbSelect()

Hopefully, a generic sub to pawn all db lookups off onto

	_dbSelect(
		table     => 'table',
		fields    => [ field1, field2, field2],
		equals	  => ["field", "What it equals"],
		like      => ["field", "what it's like"],
		orderby   => 'field4 desc'
		count     => something
	}

If count *exists*, a count is returned. If not, it isn't. More 
than one pair of 'equals' may be passed by passing an array of 
arrays. In this case you can specify whether these are an 'and' 
or an 'or' with the 'equalsandor' param:

	_dbSelect(
		table	     => 'table',
		fields	     => ['field1', 'field2'],
		equals       => [
					['field2', "something"],
					['field7', "something else"],
			        ],
		equals_or => "or";
	);
If this is set to anything other than 'or' it is an 'and' search.

Returns an array of hashes, each hash representing a row from
the db with keys as field names.

=cut

sub _dbSelect{
	my $self = shift;
	my %opts = @_;
	my $table = $opts{'table'};
	my @return;
	my @fields;

	if(exists($self->{'_tables'}->{$table})){
		$table = $self->{'_tables'}->{$table};
	}else{
		_error("Table '$table' not defined in %_tables");
	}

	foreach my $field (@{$opts{'fields'}}){
		if($field =~ /^\*$/){
			push(@fields, $field);
		}else{
			unless(exists($self->{'_fields'}->{$table}->{$field})){
				_error("Field $self->{'_fields'}->{$table}->{$field} in table $table not defined in %_fields");
			}
			push (@fields, $self->{'_fields'}->{$table}->{$field});
		}
	}
	my $query = "select ";
	if (exists($opts{count})){
		$query .= "count(*) ";
	}else{
		$query .= join(", ", @fields);
	}

	$query .= " from $table ";
	if ($opts{'equals'} > 0){
		$query.="where ";
		my $andor;
		if($opts{'equals_andor'} =~ /^or$/i){
			$andor = "or";
		}else{
			$andor = "and";
		}
		# We may be passed one of two things to 'equals'; an array of 
		# two elements (element 1 must equal element 2) or an array of 
		# arrays, each of which is of that form. Here, if we're passed a
		# one-dimensional array, we move it to being the first element of
		# a two-dimensional one:
		if(ref($opts{'equals'}->[0]) eq ''){
			my $equals = $opts{'equals'};
			delete($opts{'equals'});
			push(@{$opts{'equals'}}, $equals);
		}
		foreach my $equals (@{$opts{'equals'}}){
			my ($field,$value) = @{$equals};
			if (exists($self->{'_fields'}->{$table}->{$field})){
				$field = $self->{'_fields'}->{$table}->{$field};
			}else{
				_error("Field $field in table $table (used in SQL conditional) not defined");
			}
			$query .= " $field = '$value' $andor ";
		}
		$query =~ s/$andor $//;
	}elsif ($opts{'like'} > 0){
		my ($field,$value) = @{$opts{'like'}};
		if (exists($self->{'_fields'}->{$table}->{$field})){
			$field = $self->{'_fields'}->{$table}->{$field};
		}else{
			_error("Field $field in table $table (used in SQL conditional) not defined");
		}
		$field = $self->{'_fields'}->{$table}->{$field};
		$query .= " where $field like '$value'";
	}
	my $dbi = $self->{'_dbi'};
	my $sth = $self->{'_dbi'}->prepare($query);
	$sth->execute() or _error("execute failed: $!");
	while(my $row = $sth->fetchrow_hashref){
		push(@return, $row);
	}
	return @return;
}

#=head3 _mysqlNow()
#
# Returns a timestamp of its time of execution in a format ready for inserting into MySQL
# (YYYY-MM-DD hh:mm:ss)
#
#=cut

sub _mysqlNow() {
	
	my ($y,$m,$d,$hr,$mi,$se)=(localtime(time))[5,4,3,2,1,0];
	my $date = $y + 1900 ."-".sprintf("%02d",$m)."-$d";
	my $time = "$hr:$mi:$se";
	return "$date $time";
}


#=head3 _fieldExists()
#
#Checks whether a field exists in the db. Must exist in the _field hash.
#
#=cut

sub _fieldExists() {
	my ($dbi,$dbName,$tableName,$fieldName) = @_;
	my $query = "select count(*) from information_schema.COLUMNS where ";
	   $query.= "TABLE_SCHEMA='$dbName' and TABLE_NAME='$tableName' and ";
	   $query.= "COLUMN_NAME='$fieldName'";
	my $sth = $dbi->prepare($query);
	$sth->execute;
	my $count = ($sth->fetchrow_array())[0];
	return($count) if ($count > 0);
	return;
}

#=head3 _warn() and _error()
#
#Handy wrappers for when I want to simply warn or spit out an error.
#
#=cut

sub _warn{
	my $message = pop;
	chomp $message;
	Carp::carp($message);
}
sub _error{
	my $message = shift;
	chomp $message;
	Carp::croak($message."\n");
}	

#=head1 CLASS VARIABLES
#
#=cut


#=head3 dbi
#
#C<dbi> is the dbi object used by the rest of the module, having guessed/set the appropriate credentials. 
#You can use it as you would the return directly from a $dbi->connect:
#
#  my $sth = $p->{'_dbi'}->prepare($query);
#  $sth->execute;
#
#=head3 params
#
#C<params> is the hash passed to the constructor, including any interpreting it does. If you've chosen to authenticate by passing
#the path to a main.cf file, for example, you can use the database credentials keys (C<dbuser, dbpass and dbi>) to initiate your 
#own connection to the db (though you may as well use dbi, above). 
#
#Other variables are likely to be put here as I decide I'd like to use them :)
#
#=head1 DIAGNOSTICS
#
#Functions generally return:
#
#=over
#
#=item * null on failure
#
#=item * 1 on success
#
#=item * 2 where there was nothing to do (as if their job had already been performed)
#
#=back
#
#See C<errstr> and C<infostr> for better diagnostics.
#
#=head2 The DB schema
#
#Internally, the db schema is stored in two hashes. 
#
#C<%_tables> is a hash storing the names of the tables. The keys are the values used internally to refer to the 
#tables, and the values are the names of the tables in the db.
#
#C<%_fields> is a hash of hashes. The 'top' hash has as keys the internal names for the tables (as found in 
#C<getTables()>), with the values being hashes representing the tables. Here, the key is the name as used internally, 
#and the value the names of those fields in the SQL.
#
#Currently, the assumptions made of the database schema are very small. We asssume four tables, 'mailbox', 'domain', 
#'alias' and 'alias domain':
#
# mysql> describe mailbox;
# +------------+--------------+------+-----+---------------------+-------+
# | Field      | Type         | Null | Key | Default             | Extra |
# +------------+--------------+------+-----+---------------------+-------+
# | username   | varchar(255) | NO   | PRI | NULL                |       |
# | password   | varchar(255) | NO   |     | NULL                |       |
# | name       | varchar(255) | NO   |     | NULL                |       |
# | maildir    | varchar(255) | NO   |     | NULL                |       |
# | quota      | bigint(20)   | NO   |     | 0                   |       |
# | local_part | varchar(255) | NO   |     | NULL                |       |
# | domain     | varchar(255) | NO   | MUL | NULL                |       |
# | created    | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | modified   | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | active     | tinyint(1)   | NO   |     | 1                   |       |
# +------------+--------------+------+-----+---------------------+-------+
# 10 rows in set (0.00 sec)
#   
# mysql> describe domain;
# +-------------+--------------+------+-----+---------------------+-------+
# | Field       | Type         | Null | Key | Default             | Extra |
# +-------------+--------------+------+-----+---------------------+-------+
# | domain      | varchar(255) | NO   | PRI | NULL                |       |
# | description | varchar(255) | NO   |     | NULL                |       |
# | aliases     | int(10)      | NO   |     | 0                   |       |
# | mailboxes   | int(10)      | NO   |     | 0                   |       |
# | maxquota    | bigint(20)   | NO   |     | 0                   |       |
# | quota       | bigint(20)   | NO   |     | 0                   |       |
# | transport   | varchar(255) | NO   |     | NULL                |       |
# | backupmx    | tinyint(1)   | NO   |     | 0                   |       |
# | created     | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | modified    | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | active      | tinyint(1)   | NO   |     | 1                   |       |
# +-------------+--------------+------+-----+---------------------+-------+
# 11 rows in set (0.00 sec)
#
# mysql> describe alias_domain;
# +---------------+--------------+------+-----+---------------------+-------+
# | Field         | Type         | Null | Key | Default             | Extra |
# +---------------+--------------+------+-----+---------------------+-------+
# | alias_domain  | varchar(255) | NO   | PRI | NULL                |       |
# | target_domain | varchar(255) | NO   | MUL | NULL                |       |
# | created       | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | modified      | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | active        | tinyint(1)   | NO   | MUL | 1                   |       |
# +---------------+--------------+------+-----+---------------------+-------+
# 5 rows in set (0.00 sec)
#
# mysql> describe alias;
# +----------+--------------+------+-----+---------------------+-------+
# | Field    | Type         | Null | Key | Default             | Extra |
# +----------+--------------+------+-----+---------------------+-------+
# | address  | varchar(255) | NO   | PRI | NULL                |       |
# | goto     | text         | NO   |     | NULL                |       |
# | domain   | varchar(255) | NO   | MUL | NULL                |       |
# | created  | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | modified | datetime     | NO   |     | 0000-00-00 00:00:00 |       |
# | active   | tinyint(1)   | NO   |     | 1                   |       |
# +----------+--------------+------+-----+---------------------+-------+
# 6 rows in set (0.00 sec)
#
#And, er, that's it. If you wish to store cleartext passwords (by passing a value greater than 0 for 'storeCleartextPassword'
#to the constructor) you'll need a 'password_cleartext' column on the mailbox field. 
#
#C<getFields> returns C<%_fields>, C<getTables %_tables>. C<setFields> and C<setTables> resets them to the hash passed as an 
#argument. It does not merge the two hashes.
#
#This is the only way you should be interfering with those hashes.
#
#Since the module does no guesswork as to the db schema (yet), you might need to use these to get it to load 
#yours. Even when it does do that, it might guess wrongly.



=head1 REQUIRES

=over 

=item * Perl 5.10

=item * Crypt::PasswdMD5 

=item * Carp

=item * DBI

=back

Crypt::PasswdMD5 is C<libcyrpt-passwdmd5-perl> in Debian, 
DBI is C<libdbi-perl>

=cut

1
