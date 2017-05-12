###########################################
package HTML::Merge::Engine;
###########################################
# Modules #################################

use Carp;
use strict;
use vars qw(%cookies $suffix @objects @matrices @say
		$INTERNAL_DB $INTERNAL_DSN);

# My Modules ############################## 

use HTML::Merge::Error;

# Globals #################################

@objects = qw(user group subsite instance realm template say);

@matrices = qw(user_group user_realm group_realm
        realm_template template_subsite realm_subsite);

@say = qw(group join:part realm been_grant:been_revoke
        _realm protect:release subsite attach:detach);

$INTERNAL_DB='merge.db';

###########################################

sub Order (\$\$);
 
###########################################
sub AddSuffix 
{
	$suffix .= shift;
}
###########################################
sub DumpSuffix
{
	my ($template, $line_num) = @$HTML::Merge::context;

	eval '
	        if ($template =~ /\.$HTML::Merge::Ini::DEV_EXTENSION$/) 
		{
			print $suffix;
		}
	';

	&DumpCookies;
}
###########################################
sub DumpCookies 
{
	my $expire=$HTML::Merge::Ini::SESSION_TIMEOUT;
	my $t;
	my ($name, $val);

	while (($name, $val) = each %cookies) 
	{
		print "<META HTTP-EQUIV=\"Set-Cookie\" CONTENT=\"$name=$val\">\n";
	}
}
###########################################
sub new 
{
	my ($class) = @_;

	my $self = {};

	$self->{dbh} = undef;		# Application database			
	$self->{sys_dbh} = undef;	# System database handle
	$self->{sth} = undef;		# SQL statment handler	 
	$self->{dsn} = undef;		# The application dsn string 
	$self->{cred} = undef; 
	
	bless $self, $class;
}
###########################################
sub CreateObject 
{
	my $class = shift;
	my %array;

	tie %array, $class;

	return $array{""};
}
###########################################
sub TIEHASH 
{
	my ($class) = @_;
	my $this = {'storage' => {}};

	%cookies = ();
	$suffix = '';
	bless $this, $class;
}
###########################################
sub FETCH 
{
	my ($self, $key) = @_;

	$key ||= 0;
	my $class = ref($self);
	my $storage = $self->{'storage'};

	if (exists $storage->{$key} && &UNIVERSAL::isa($storage->{$key},
			$class)) 
	{
		return $storage->{$key};
	}
	
	$storage->{$key} = $class->new;
	$storage->{$key}->Preconnect;

	return $storage->{$key};
}				
###########################################
sub DELETE 
{
	my ($self, $key) = @_;
	my $storage = $self->{'storage'};

	delete $storage->{$key};
}
###########################################
sub DESTROY 
{
	my $self = shift;

	# Are we an item?
	my $sth = $self->{'sth'};
	if ($sth) 
	{
		eval { $sth->finish; };
		delete $self->{'sth'};
	}

	my $dbh = $self->{'dbh'};
	if ($dbh) 
	{
		$dbh->disconnect;
		delete $self->{'dbh'};
	}

	# Are we the tied hash?

	my $storage = $self->{'storage'};
	if ($storage) 
	{
		%$storage = ();
		delete $self->{'storage'};
	}
}
###########################################
sub CLEAR 
{
	my $self = shift;
	$self->{'storage'} = {};
}
###########################################
sub Preconnect 
{
	my ($self, $dbtype, $db, $dbhost, $user, $password) = @_;
	$dbtype ||= $HTML::Merge::Ini::DB_TYPE;
	$dbhost ||= $HTML::Merge::Ini::DB_HOST;
	$user ||= $HTML::Merge::Ini::DB_USER;
	$password ||= &Convert($HTML::Merge::Ini::DB_PASSWORD2)
			|| $HTML::Merge::Ini::DB_PASSWORD;
	$db ||= $HTML::Merge::Ini::DB_DATABASE;

	$self->{'dsn'} = ['dbi', $dbtype, $db, $dbhost];
	$self->{'cred'} = [$user, $password];
	$self->{'dbh'} = undef;
	$self->{'sth'} = undef;
}
###########################################
sub DoConnect 
{
	my $self = shift;
	return if $self->{'dbh'};

	require DBI;

	my $dsn = join(":", grep /./, @{$self->{'dsn'}});
	my ($user, $password) = @{$self->{'cred'}};
	my $dbh = DBI->connect($dsn, $user, $password, {'AutoCommit' =>
 		$HTML::Merge::Ini::AUTO_COMMIT}) || 
		HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);

	$self->{'dbh'} = $dbh;
	$self->{'sth'} = undef;
}
###########################################
sub Statement 
{
	my ($self, $sql) = @_;
	HTML::Merge::Error::HandleError('INFO', $sql, 'SQL');
	my $dbh = $self->DBH;

	$dbh->do($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
}
###########################################
sub Query 
{
	my ($self, $sql) = @_;
	HTML::Merge::Error::HandleError('INFO', $sql, 'SQL');
	$self->{'sth'} = undef;
	$self->{'fields'} = {};
	my $dbh = $self->DBH();
	my $sth = $dbh->prepare($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	$sth->execute ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	$self->{'sth'} = $sth;
	$self->{'fields'} = $sth->fetchrow_hashref;
	$self->{'fields'} ||= {};
	$self->{'empty'} = !%{$self->{'fields'}};
	$self->{'buffer'} = [$self->{'fields'}];
	$self->{'index'} = 0;
}
###########################################
sub HasQuery 
{
	my $self = shift;

	$self->{'sth'} ? 1 : 0;
}
###########################################
sub Empty 
{
	my $self = shift;

	$self->{'empty'};
}
###########################################
sub Fetch 
{
	my ($self, $explicit, $atrow) = @_;
	my $sth = $self->{'sth'};

	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') unless ($sth);
	$self->{'index'}++;
	if ($explicit) 
	{
		$self->{'buffer'} = undef;
		return !$self->{'empty'} if ($atrow == 1);
	}
	my $candidate = $self->{'buffer'};
	if ($candidate) 
	{
		$self->{'buffer'} = undef;
		$self->{'fields'} = $candidate->[0];
		return %{$self->{'fields'}} ? 1 : undef;
	}
	my $hash = $sth->fetchrow_hashref;

	unless ($hash) 
	{
		$self->{'index'}--;
#		$self->{'fields'} = {};
		return undef;
	}
	$self->{'fields'} = $hash;

	return 1;
}
###########################################
sub ReRun 
{
	my $self = shift;
	my $sth = $self->{'sth'};

	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') unless ($sth);
	$sth->execute;
	$self->{'fields'} = $sth->fetchrow_hashref;
	$self->{'fields'} ||= {};
	$self->{'buffer'} = [$self->{'fields'}];
	$self->{'index'} = 0;
}
###########################################
sub Var 
{
	my ($self, $key) = @_;

	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') && '' unless ($self->{'fields'});

	return HTML::Merge::Error::HandleError('WARN', 'NO_SQL_MATCH') && '' unless (exists $self->{'fields'}->{$key});
	
	return $self->{'fields'}->{$key};
}
###########################################
sub Columns 
{
	my $self = shift;

	return HTML::Merge::Error::HandleError('WARN', 'ILLEGAL_FETCH') && '' unless ($self->{'sth'});

	return @{$self->{'sth'}->{'NAME'}};
}
###########################################
sub Index 
{
	my $self = shift;

	$self->{'index'};
}
###########################################
sub GetPersistent
{
	my ($self, $var) = @_;
	my ($sql, $val);
	my $id;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $dbh = $self->SYS_DBH();

	$self->ValidatePersistent;
	$id = $self->{session_id};
	$sql = "SELECT vardata
                FROM $table
                WHERE session_id = '$id'
                AND varname = '$var'";
	($val) = $dbh->selectrow_array($sql);
	
	return (defined($val)) ? $val : ''; 
}
###########################################
sub SetPersistent
{
	my ($self, $var, $val) = @_;
	
	$self->ValidatePersistent;
	$self->SetField($var, $val);

	return "";
}
###########################################
sub ErasePersistent
{
	my $self = shift;

	$self->ValidatePersistent;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $id = $self->{session_id};
	my $sql = "DELETE FROM $table
                   WHERE session_id = '$id'";
	my $dbh = $self->SYS_DBH;
	$dbh->do($sql) || HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
}
###########################################
sub ValidatePersistent
{
	my $self = shift;

	my ($id, $sql, $sth, @other, $other);
	my $now = time;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $expire = YMD(time - 60 * $HTML::Merge::Ini::SESSION_TIMEOUT);
	$self->CheckSessionTable;
	$self->GetSessionID;
	$id = $self->{session_id};
	$self->SetField("", YMD(time));
	$sql = "SELECT session_id
                FROM $table
                WHERE varname = ''
                AND vardata < '$expire'";
	@other = $self->LoadArray($sql);
	return unless @other;
	$sql = "DELETE FROM $table WHERE session_id IN ('" .
		join("','", @other) . "')";
	my $dbh = $self->SYS_DBH();
	$dbh->do($sql);
}
###########################################
sub CreateSessionTable
{
	my $self = shift;

	my $dbh;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $ddl = "CREATE TABLE $table (
			session_id VARCHAR(20) NOT NULL,
			varname VARCHAR(30) NOT NULL,
			vardata VARCHAR(255) NOT NULL
		   )";
	# there is no relevance ro the value of the internal db because 
	# the program only need to know if we use mysql
	my $database = ($HTML::Merge::Ini::SESSION_DB)?lc($self->{dsn}->[1]):'';
	if ($database eq 'mysql') 
	{
		$ddl .= " TYPE=Heap";
	}
	
	$dbh = $self->SYS_DBH();
	$dbh->do($ddl) || croak $DBI::errstr;	
	
	$ddl = "CREATE UNIQUE INDEX ux_var 
                ON $table (session_id, varname)";
	eval { $dbh->do($ddl); };
}
###########################################
sub CheckSessionTable
{
	my $self = shift;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $sql = "SELECT Count(*) FROM $table";
	my $sth;

	return if ($self->{checked_session_table}++ > 1);

	$@ = undef;
	my $dbh = $self->SYS_DBH();
	eval {
		$sth = $dbh->prepare($sql) || 
			die $DBI::errstr; # Do NOT call HandleError
		$sth->execute ||
			die $DBI::errstr; # Do NOT call HandleError
	};
	$self->CreateSessionTable if $@;
}
###########################################
sub GenerateSessionID 
{
	my $self = shift;
	$self->{session_id} = substr($ENV{'REMOTE_ADDR'}, -8) . $$ . time % (3600 * 24);
	$self->{session_id} =~ tr/0-9//cd;
}
###########################################
sub GetSessionID 
{
	my $self = shift;
	my $created = $self->MakeSessionID;
	return if $created;
	my $id = $self->{session_id};
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $sql = "SELECT Count(*) 
		FROM $table
                WHERE session_id = '$id'
                AND varname = ''";
	my $dbh = $self->SYS_DBH();
	my ($valid) = $dbh->selectrow_array($sql);
	return if $valid;
	my $fh = select;
	select $fh->{'out'} if (tied($fh));
	$self->SetField("", YMD(time));
	&HTML::Merge::Error::TimeOut;
}
###########################################
sub MakeSessionID 
{
	my $self = shift;
	my ($key, $val);
	my $sql;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $expire=undef;

	return 0 if $self->{session_id};
	my $method = $HTML::Merge::Ini::SESSION_METHOD || 'C';
	if ($method eq 'I') 
	{
		$self->{session_id} = $ENV{'REMOTE_ADDR'};
		return 1;
	} 
	if ($method eq 'U') 
	{
		$self->{session_id} = $ENV{'PATH_INFO'};
		$self->{session_id} =~ s|/||g;
		return 0 if $self->{session_id};
		return 0 if $self->{'KLUDGE_NO_NEW_ID'};
		$self->GenerateSessionID;
		return 1;
	}
	if ($method eq 'C') 
	{
		$HTML::Merge::Ini::SESSION_COOKIE ||= 'RZCKMRGSSN';

		$self->{session_id} = $self->GetCookie($HTML::Merge::Ini::SESSION_COOKIE);
		return 0 if $self->{session_id};
		return 0 if $self->{'KLUDGE_NO_NEW_ID'};

		$self->GenerateSessionID;


		if ($HTML::Merge::Ini::STICKY_COOKIE) 
		{
			$expire=$HTML::Merge::Ini::SESSION_TIMEOUT;
		}

		SetCookie($HTML::Merge::Ini::SESSION_COOKIE, 
			$self->{session_id},
			$expire || "*");

		return 1;
	}
	die "Session method incorrect";
}
###########################################
sub SetField
{
	my ($self, $key, $val) = @_;

	my ($sql, $count, $sth);
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."sessions";
	my $id = $self->{session_id};
	
	$sql = "SELECT Count(*)
                FROM $table
                WHERE session_id = '$id'
		AND varname = '$key'";
	my $dbh = $self->SYS_DBH();
	($count) = $dbh->selectrow_array($sql);
	
	if ($count) 
	{
		$sql = "UPDATE $table 
                        SET vardata = ? 
        	        WHERE session_id = '$id'
			AND varname = '$key'";
	} 
	else 
	{
		$sql = "INSERT INTO $table (session_id, varname, vardata)
			VALUES ('$id', '$key', ?)";
	}
	
	$sth = $dbh->prepare($sql) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
	
	#$val ||= '';
	$val=(defined $val)?$val:''; 
	
	$sth->execute($val) ||
		return HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);
}
###########################################
sub State
{
	my $self=shift;

	$self->{sth} ? $self->{sth}->state : (
		$self->{'dbh'} ? $self->{'dbh'}->state : '');
}
###########################################
sub YMD 
{
	my @t = localtime(shift());

	return sprintf("%04d" . "%02d" x 5, $t[5] + 1900, $t[4] + 1, 
			$t[3], $t[2], $t[1], $t[0]);
}
###########################################
sub GetCookie 
{
	shift if (UNIVERSAL::isa($_[0], __PACKAGE__));
	my $name = shift;
	my $cookie = $ENV{HTTP_COOKIE};

	foreach (split(/;\s*/, $cookie)) 
	{
		my ($key, $val) = split(/=/, $_);
		return $val if ($key eq $name);
	}
}
###########################################
sub SetCookie 
{
	shift if (UNIVERSAL::isa($_[0], __PACKAGE__));

	my ($name, $value, $expire) = @_;
	my $extra;

	$cookies{$name} = "$value";

	unless ($expire) 
	{
		$cookies{$name} .= "; expires=Tue, 19 Jan 2038 03:14:07 GMT";
	} 
	else 
	{
		if ($expire =~ /^\d+$/)
		{
			#require HTTP::Date;
			my $t = time + $expire * 60;
			$cookies{$name} .= "; expires=" .  time2HTTPstr($t);
		}
	}

	# last add a default path
	$cookies{$name} .= "; path=$HTML::Merge::Ini::MERGE_PATH;";

	$ENV{'HTTP_COOKIE'} .= ';' if $ENV{'HTTP_COOKIE'};
	$ENV{'HTTP_COOKIE'} .= "$name=$value";
}
###########################################
sub ReadConfig 
{
	my $self = $0;
	$self =~ s/\.\w+$/.conf/;
	my @conf = ($self, "/etc/merge.conf", &GetHome . "/.merge");

	foreach my $f (@conf) 
	{
        	if (open(CFG, $f))
	 	{
			no strict;
			my $code = join("", <CFG>);
			close(CFG);
			eval $code;
			if ($@) 
			{
				print "Status: 501 Server error\n";
				print "Content-type: text/plain\n\n";
				print "$f caused error: $@";
				exit;
			}

			$HTML::Merge::config = $f;
        	        last;
	        }
	}

	$self =~ s/\.\w+$/.ext/;
	foreach my $ext (($self, "/etc/merge.ext")) 
	{
		if (-f $self) 
		{
			package HTML::Merge::Ext;
			eval 'require $self;';
			if ($@) 
			{
				print "Status: 501 Server error\n";
				print "Content-type: text/plain\n\n";
				print "$self caused error: $@";
				exit;
			}
		}
	}
}
###############################################################################
sub GetHome 
{
	return if ($^O =~ /Win/);

	my ($name,$passwd,$uid,$gid,
        $quota,$comment,$gcos,$dir,$shell,$expire) = getpwuid($>);

	return $dir;
}
###############################################################################
sub import 
{
	my (@param) = @_;

	$param[1] |= '';
	return if ($param[1] eq ':unconfig');

	&ReadConfig;
}
###########################################
sub Convert 
{
	my ($db_pass, $rev) = @_;

        my $from = pack("C*", map {hex($_)} ($HTML::Merge::Ini::S_FROM =~ /(..)/g));
        my $to = pack("C*", map {hex($_)} ($HTML::Merge::Ini::S_TO =~ /(..)/g));        $from =~ s/-/\\-/;
        $to =~ s/-/\\-/;
	($from, $to) = ($to, $from) if $rev;
        eval "\$db_pass =~ tr/$to/$from/;";
	$db_pass;
}
###########################################
sub DBH 
{
	my $self = shift;

	$self->DoConnect;

	return $self->{'dbh'};
}
###########################################
sub SYS_DBH
{
	my $self = shift;
	return $self->{'sys_dbh'} if $self->{'sys_dbh'} ;
	return $self->DBH() if $HTML::Merge::Ini::SESSION_DB;

	require DBI;

	$INTERNAL_DSN="dbi:SQLite:dbname=$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/$INTERNAL_DB";
	my $sys_dbh = DBI->connect($INTERNAL_DSN,"","")
 		|| HTML::Merge::Error::HandleError('ERROR', $DBI::errstr);

	$self->{'sys_dbh'} = $sys_dbh;
	$self->{'sth'} = undef;

	return $self->{'sys_dbh'};
}	
###########################################
sub AddUser 
{
	my ($self, $user, $password, $realname, $tag) = @_;
	croak "Invalid username: $user" unless ($user =~ /^\S{3,15}$/);
	croak "Invalid password length: $password" unless ($password =~ /^\S{3,15}$/);
	unless ($HTML::Merge::Ini::ALLOW_EASY_PASSWORDS) 
	{
		$@ = undef;
		eval{ require Data::Password; };

		unless($@)
		{
			my $reason = Data::Password::IsBadPassword($password);
			croak "Bad password $password: $reason" if $reason;
		}
	}

	croak "Can't change user $user"
		if ($user eq $HTML::Merge::Ini::ROOT_USER);

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."users_t";

	my $salt = pack("CC", rand(26) + 65 ,rand(26) + 65);
	my $cp = crypt($password, $salt);
	my $dbh = $self->SYS_DBH();
	my $sql = "SELECT Count(*) FROM $table WHERE username = '$user'";
	my ($exists) = $dbh->selectrow_array($sql);
	unless  ($exists) 
	{
		foreach (1 .. 10) # Lame concurrency handling
		{ 
			my $id = $self->GetNext($table);
			my $sql = "INSERT INTO $table (epitaph, id, username) VALUES (0, $id, '$user')";
			eval { $dbh->do($sql); };
			last unless $@;
			sleep 1;
		}
	}

	$sql = "UPDATE $table SET password = ?, epitaph = 0 
		WHERE username = '$user'";
	my $sth = $dbh->prepare($sql);
	$sth->execute($cp);
	if (defined($realname)) # May be an empty string
	{
		my $sql = "UPDATE $table SET realname = ? WHERE username = '$user'";
		my $sth = $dbh->prepare($sql);
		$sth->execute($realname);
	}
	if (defined($tag)) # May be an empty string
	{
                my $sql = "UPDATE $table SET tag = ? WHERE username = '$user'";
                my $sth = $dbh->prepare($sql);
                $sth->execute($tag);
        }
}
###########################################
sub DelUser 
{
	my ($self, $user) = @_;
	$self->Destruct('user' => $user);
}
###########################################
sub SetUser 
{
	my ($self, $user) = @_;
	$self->SetPersistent("__user", join(":", $user, 
		$self->GetInstance));
}
###########################################
sub GetUser 
{
	my $self = shift;
#	$self->{'KLUDGE_NO_NEW_ID'} = 1;
	$self->ValidatePersistent;
#	delete $self->{'KLUDGE_NO_NEW_ID'};
	return undef unless $self->{'session_id'};
	my ($u, $i) = split(/:/, $self->GetPersistent("__user"));
	$i == $self->GetInstance ? $u : undef;
}
###############################################################################
sub Login 
{
	my ($self, $user, $pass) = @_;

	my $dbh = $self->SYS_DBH();
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = "${db}users_t";
	my $sql = "SELECT password FROM $table WHERE username = '$user'";
	my ($cp) = $dbh->selectrow_array($sql);
	$cp = $HTML::Merge::Ini::ROOT_PASSWORD if ($user eq $HTML::Merge::Ini::ROOT_USER);
	return 0 unless defined($cp); # May be an empty password!
	my $candidate = crypt($pass, $cp);
	if ($candidate eq $cp) {
		$self->SetUser($user);
		return 1;
	}
	$self->SetUser('');
	return 0;
}
###########################################
sub ChangePassword 
{
	my ($self, $pass) = @_;
	my $user = $self->GetUser;
	HTML::Merge::Error::HandleError('ERROR',
		"Not logged in") unless $user;
	HTML::Merge::Error::HandleError('ERROR', "Can't change user $user")
		if ($user eq $HTML::Merge::Ini::ROOT_USER);
	$self->AddUser($user, $pass);
}
###########################################
sub HasKey 
{
	my ($self, $realm, $user) = @_;
	$user ||= $self->GetUser;
	return 0 unless $user;
	return 1 if ($user eq $HTML::Merge::Ini::ROOT_USER);
	my $make_sure_user_exists = $self->GetUserID($user);
	my %keys;
	my @keys = $self->Links('user' => $user, 'realm', $realm);
	return 1 if @keys;
	my @groups = $self->Links('user' => $user, 'group');
	@keys = $self->Links('group' => \@groups, 'realm', $realm);
	return 1 if @keys;
	undef;
}
###########################################
sub CanEnter 
{
	my ($self, $template, $user) = @_;
	unless ($template) 
	{
		$template = $HTML::Merge::context->[0];
		$template =~ s/^$HTML::Merge::Ini::TEMPLATE_PATH//;
	}

	my $default = 1;
	foreach ($self->Links('template' => $template, 'realm')) 
	{
		$user ||= $self->GetUser;
		return undef unless $user;
		return 1 if $self->HasKey($_, $user);
		$default = 0; # Some keys were requested - return 0 if none matched
	}
	my @subsites = $self->Links('template' => $template, 'subsite');
	foreach ($self->Links('subsite' => \@subsites, 'realm')) 
	{
		$user ||= $self->GetUser;
		return undef unless $user;
		return 1 if $self->HasKey($_, $user);
		$default = 0; # Some keys were requested - return 0 if none matched
	}
	return $default;
}
###########################################
sub GetNext 
{
	my ($self, $table) = @_;

	my $dbh = $self->SYS_DBH();
	my $sql = "SELECT Max(id) FROM $table";
	my ($max) = $dbh->selectrow_array($sql);

	return $max + 1;
}
###########################################
sub Required 
{
	my ($self, $template) = @_;

	my $tid = $self->GetTemplateID($template);
	my $dbh = $self->SYS_DBH();
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $sql = "SELECT B.realmname 
                        FROM ${db}realm_template_matrix A,
                                ${db}realms_t B
                        WHERE A.template_id = $tid
                                AND B.id = A.realm_id";

	$self->LoadArray($sql);
}
###########################################
sub Require 
{
	my ($self, $template, $realms) = @_;
	my @realms = split(/,\s*/, $realms);
	my $tid = $self->GetTemplateID($template);
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = $db."realm_template_matrix";
	my $iid = $self->GetInstance;
	
	my $dbh = $self->SYS_DBH();
	my $sql = "DELETE FROM $table WHERE template_id = $tid";
	$dbh->do($sql);

	foreach (@realms) 
	{
		$self->Request($_, $template);
	}
}
###########################################
sub InitDatabase 
{	
	my $self = shift;
	$self ||= __PACKAGE__->CreateObject();
	
	my $sysdata_file = "$HTML::Merge::Ini::MERGE_ABSOLUTE_PATH/private/sql/tbl.dat"; 

	$self->CreateMeta();
	# now let's create the meta data tables_internal 
	$self->CreateMetaDataTable();
	# populate default meta
	$self->LoadSysTableFromFile($sysdata_file);
	
	foreach (@objects) 
	{
		$self->CreateTable($_);
	}
	foreach (@matrices) 
	{
		$self->CreateMatrix($_);
	}
}
###########################################
sub CreateTable 
{
	my ($self, $table) = @_;

	print "Creating $table table...";

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH;
	my $ddl = <<DDL;
CREATE TABLE ${db}${table}s_t (
        id INT PRIMARY KEY NOT NULL,
        ${table}name VARCHAR(150),
        description VARCHAR(80),
        tag VARCHAR(255),
	epitaph INT NOT NULL
)
DDL
	if ($table eq 'template') 
	{
		$ddl =~ s/\)\n*$/, instance_id INT NOT NULL)/;
	}
	if ($table eq 'user') 
	{
	        $ddl =~ s/\)\n*$/, password VARCHAR(15))/;
	}

	$dbh->do($ddl);
	$ddl = "CREATE UNIQUE INDEX x_$table ON ${db}${table}s_t (${table}name)";
	if ($table eq 'template') 
	{
		$ddl =~ s/\)$/, instance_id)/;
	}
	$dbh->do($ddl);
	print "\n";
}
###########################################
sub GetSay 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my ($child, $parent, $how) = @_;
	Order($child, $parent);
	# Must search for first occurence@
	my ($str) = grep {$_ eq $parent || $_ eq "_$child"} @say;
	return unless $str;
	my %say = @say;
	my ($add, $del) = split(/:/, $say{$str});
	return ($add, $del) unless $how;
	$how = ucfirst(lc($how));
	my $proc = UNIVERSAL::can(__PACKAGE__, "Translate$how");
	return map {&$proc;} ($add, $del) if $proc;
	return ($add, $del);
}
###########################################
sub TranslateImperative 
{
	my @tokens = split(/_/, $_);
	$_ = ucfirst(lc($tokens[-1]));
}
###########################################
sub TranslatePast 
{
	s/_/ /;
	s/e$//;
	$_ .= 'ed';
}
###########################################
sub CreateMatrix 
{
	my ($self, $matrix) = @_;
	my ($child, $parent) = split(/_/, $matrix);

	print "Creating $child/$parent table...";

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH();

	my $table = "${matrix}_matrix";
	my $index_prefix;
	my ($add, $del) = GetSay($child, $parent);

	my $ddl = <<DDL;
CREATE TABLE ${db}$table (
	id INT PRIMARY KEY NOT NULL,
	${child}_id INT NOT NULL,
	${parent}_id INT NOT NULL
)
DDL
	$dbh->do($ddl);

	$index_prefix=$db;
	chop($index_prefix);
	$index_prefix .="_$matrix";
 
	foreach (($child, $parent)) {
		$ddl = "CREATE INDEX x_$index_prefix\_$_ ON $table (${_}_id)";
		$dbh->do($ddl);
	}
	$ddl = "CREATE UNIQUE INDEX ux_$index_prefix ON $table (${child}_id, ${parent}_id)";
	$dbh->do($ddl);

	my $sql = "INSERT INTO ${db}metadata (child, parent, stradd, strdel, tbl)
		VALUES ('$child', '$parent', '$add', '$del', '${matrix}_matrix')";
	$dbh->do($sql);
	print "\n";
}
###########################################
sub CreateMeta 
{
	my ($self) = @_;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH();
	my $object = "VARCHAR(25) NOT NULL";
	my $table = "${db}metadata";
	my $sql;
	my $ddl = <<DDL;
CREATE TABLE $table (
        child $object,
        parent $object,
        stradd $object,
        strdel $object,
        tbl VARCHAR(50) NOT NULL
)
DDL

	chop($db);	# take out the extra .
	$dbh->do("CREATE DATABASE $db") if $HTML::Merge::Ini::SESSION_DB; 
	$dbh->do($ddl);

	$ddl = "CREATE UNIQUE INDEX ux_metadata 
		ON $table (child, parent)";
	$dbh->do($ddl);

	$sql = "DELETE FROM $table";
	$dbh->do($sql);
}
###########################################
sub IsMatrix 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my ($child, $parent) = @_;
	my $cache = undef if undef;

	unless ($cache) 
	{
		my %cache;
		@cache{@matrices} = (1) x scalar(@matrices);
		$cache = \%cache;
	}

	return $cache->{"${child}_$parent"};
}
###########################################
sub Order (\$\$) 
{
	my ($a, $b) = @_;
	return if IsMatrix($$a, $$b);
	($$a, $$b) = ($$b, $$a);
}
###########################################
sub Assert 
{
	my ($self, $child, $childval, $parent, $parentval, $del) = @_;

	unless (IsMatrix($child, $parent)) 
	{
		($child, $childval, $parent, $parentval) =
			($parent, $parentval, $child, $childval);
	}

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH;
	my $matrix = "${db}${child}_${parent}_matrix";
	my $child_id = $self->GetIndex($child, $childval);
	my $parent_id = $self->GetIndex($parent, $parentval);
	my $where = "WHERE ${child}_id = $child_id 
		AND ${parent}_id = $parent_id";

	if ($del) 
	{
		my $sql = "DELETE FROM $matrix $where";
		$dbh->do($sql);
		return;
	}

	my $sql = "SELECT Count(*) FROM $matrix $where";
	my $already = $dbh->selectrow_array($sql);
	return if $already;

	my $id = $self->GetNext($matrix);
	$sql = "INSERT INTO $matrix (id, ${child}_id, ${parent}_id)
		VALUES ($id, $child_id, $parent_id)";
	$dbh->do($sql);
}
###########################################
sub GetIndex 
{
	my ($self, $tbl, $val) = @_;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH();
	my $where = "WHERE ${tbl}name = '$val'";
	my $fun = ucfirst($tbl);
	my $proc = UNIVERSAL::can($self, "Where$fun");
	$where .= ' AND ' . &$proc($self, $val) if $proc;
	my $table = "${db}${tbl}s_t";
	my $sql = "SELECT id, epitaph FROM $table $where";
	my ($id, $epitaph) = $dbh->selectrow_array($sql);

	if ($epitaph) 
	{
		my $sql = "UPDATE $table SET epitaph = 0
			WHERE id = $id";
		$dbh->do($sql);
	}
	return $id if $id;

	$proc = UNIVERSAL::can($self, "Bail$fun");
	return if ($proc && &$proc($self, $val));

	$id = $self->GetNext($table);
	$proc = UNIVERSAL::can($self, "Insert$fun");
	my $fields = "(epitaph, id, ${tbl}name)";
	my $values = "(0, $id, '$val')";
	&$proc($self, \$fields, \$values, $val) if $proc;
	$sql = "INSERT INTO $table $fields VALUES $values";
	$dbh->do($sql);

	return $id;
}
###########################################
sub GetDetails 
{
	my ($self, $tbl, $val) = @_;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH;
	my $where = "WHERE ${tbl}name = '$val'";
	my $fun = ucfirst($tbl);
	my $proc = UNIVERSAL::can($self, "Where$fun");
	$where .= ' AND ' . &$proc($self, $val) if $proc;
	my $table = "${db}${tbl}s_t";
	my $sql = "SELECT description, tag FROM $table $where";
	my ($name, $tag) = $dbh->selectrow_array($sql);
	return undef unless defined($name) || defined($tag);
	wantarray ? ($name, $tag) : $name;
}
###########################################
sub SetDBField 
{
	my ($self, $tbl, $val, $field, $col) = @_;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $dbh = $self->SYS_DBH;
	my $where = "WHERE ${tbl}name = '$val'";
	my $fun = ucfirst($tbl);
	my $proc = UNIVERSAL::can($self, "Where$fun");
	$where .= ' AND ' . &$proc($self, $val) if $proc;
	my $table = "${db}${tbl}s_t";
	my $sql = "UPDATE $table SET $field = '$col' $where";
	$dbh->do($sql);
}
###########################################
sub GetInstance 
{
	my $self = shift;
	$self->GetInstanceID($HTML::Merge::config);
}
###########################################
sub WhereTemplate 
{
	my $self = shift;
	my $instance = $self->GetInstance;

	return "instance_id = $instance";
}
###########################################
sub InsertTemplate 
{
	my $self = shift;

	my $instance = $self->GetInstance;

	${$_[0]} =~ s/\)/, instance_id)/;
	${$_[1]} =~ s/\)/, $instance)/;
}
###########################################
sub BailUser 
{
	my ($self, $user) = @_;

	croak "No user '$user'";
	return 1;
}
###########################################
sub Destruct 
{
	my ($self, $tbl, $val) = @_;

	my $id = $self->GetIndex($tbl, $val);
	return unless $id;

	my $dbh = $self->SYS_DBH;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $sql = "DELETE FROM ${db}${tbl}s_t WHERE id = $id";
	$dbh->do($sql);

	my @mats = Dependencies($tbl);

	foreach (@mats) 
	{
		my $sql = "DELETE FROM ${db}${_}_matrix
			WHERE ${tbl}_id = $id";
		$dbh->do($sql);
	}
}
###########################################
sub Dependencies 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);

	my $t = shift;
	map {s/_$t$//; s/^${t}_//; $_; } grep {/^${t}_/ || /_$t$/} 
		@{[@matrices]};
}
###########################################
sub Children 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my $t = shift;
	map {s/_$t$//; $_;} grep /_$t$/, @{[@matrices]};
}
###########################################
sub Parents 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my $t = shift;
	map {s/^${t}_//; $_; } grep /^${t}_/, @{[@matrices]};
}
###########################################
sub LoadArray 
{
	my ($self, $sql, @extra) = @_;
	my $dbh = $self->SYS_DBH();
	my $sth = $dbh->prepare($sql);
	$sth->execute(@extra) || confess($sql);
	my @vec;
	while (my ($item) = $sth->fetchrow_array) 
	{
		push(@vec, $item);
	}

	return wantarray ? @vec : \@vec;
}
###########################################
sub GetVector 
{
	my ($self, $tbl) = @_;

	my $fun = "Weed" . ucfirst($tbl) . 's';
	my $code = UNIVERSAL::can($self, $fun);
	&$code($self) if $code;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table ="${db}${tbl}s_t";
	my $sql = "SELECT ${tbl}name FROM $table 
		WHERE epitaph = 0 ORDER BY ${tbl}name";
	my $vec = $self->LoadArray($sql);

	return wantarray ? @$vec : $vec;
}
###########################################
sub WeedTemplates 
{
	my $self = shift;

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table ="${db}templates_t";
	my @weed;
	my $sql = "SELECT templatename FROM $table";
	my $vec = $self->LoadArray($sql);
	@weed = grep { ! -f "$HTML::Merge::Ini::TEMPLATE_PATH/$_" 
		|| -d "$HTML::Merge::Ini::TEMPLATE_PATH/$_" }
		@$vec;
	$sql = "UPDATE $table SET epitaph = 1 WHERE
		templatename in (" .
		join(", ", map {"'$_'"} @weed) . ")";
	my $dbh = $self->SYS_DBH;
	$dbh->do($sql);
	my @files;
	my $dir = $HTML::Merge::Ini::TEMPLATE_PATH;

	for (;;) 
	{
		$dir .= "/*";
		my @these = grep { ! -d $_ } glob($dir);
		last unless @these;
		push(@files, @these);
	}
	foreach (map {s|^$HTML::Merge::Ini::TEMPLATE_PATH/||; $_;}
			@files) 
	{
		$self->GetTemplateID($_);
	}
}
###########################################
sub GetHash 
{
	my ($self, $tbl) = @_;
	my $vec = $self->GetVector($tbl);
	my %hash;

	@hash{@$vec} = @$vec;

	return wantarray ? %hash : \%hash;
}
###########################################

#@matrices = qw(user_group user_realm group_realm
#        realm_template template_subsite realm_subsite);
my %mnemonics = qw(user_group JoinGroup:PartGroup
	user_realm GrantUser:RevokeUser 
	group_realm GrantGroup:RevokeGroup
	realm_template Request:Waive
	template_subsite Attach:Detach
	realm_subsite GrandRequest:GrandWaive);

foreach my $mat (keys %mnemonics) 
{
	my ($assert, $retract) = split(/:/, $mnemonics{$mat});
	my ($child, $parent) = split(/_/, $mat);
	
	my $code = <<CODE;
sub $assert 
{
	my (\$self, \$$child, \$$parent) = \@_;
	\$self->Assert('$child' => \$$child, '$parent' => \$$parent);
}

sub $retract 
{
	my (\$self, \$$child, \$$parent) = \@_;
	\$self->Assert('$child' => \$$child, '$parent' => \$$parent, 1);
}
CODE

	eval $code;
	die $@ if $@;
}

foreach (@objects) 
{
	my $tok = ucfirst($_);

	my $code = <<CODE;
sub Get${tok}ID 
{
	my (\$self, \$$tok) = \@_;
	\$self->GetIndex('$_', \$$tok);
}

sub GetAll${tok}s 
{
	my \$self = shift;
	\$self->GetHash('$_');
}

sub Get${tok}s 
{
	my \$self = shift;
	\$self->GetVector('$_');
}

sub Get${tok}Name 
{
	my (\$self, \$$tok) = \@_;
	\$$tok ||= \$self->Get$tok;
	\$self->GetDetails('$_' => \$$tok);
}
CODE
	eval $code;
	die $@ if $@;
}
###########################################
sub GetOneDrill 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my ($from, $to) = @_;
	my $hash = {};
	foreach (@matrices) {
		my ($child, $parent) = split(/_/);
		$hash->{$child} ||= {};
		$hash->{$child}->{$parent} = "${child}_${parent}";
	}
	my $ary = [];
	&Recur($from, $to, $ary, 0, $hash);
	&Recur($to, $from, $ary, 1, $hash);

	return $ary;
}
###########################################
sub Recur 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my ($from, $to, $ary, $opp, $hash, @way) = @_;

	if($from eq $to) 
	{
		@way = reverse @way if $opp;
		push(@$ary, \@way);
		return;
	}

	my $node = $hash->{$from};
	foreach (keys %$node) 
	{
		&Recur($_, $to, $ary, $opp, $hash, @way, $node->{$_});
	}
}
###############################################################################
sub GetDrill 
{
	shift if UNIVERSAL::isa($_[0], __PACKAGE__);
	my ($from, $to) = @_;
	my $cache = undef if undef;
	$cache ||= {};
	return $cache->{$from, $to} if exists $cache->{$from, $to};
	my $ref = GetOneDrill($from, $to);
	return $cache->{$from, $to} = $ref;	
}
###############################################################################
sub Links 
{
	my ($self, $child, $this, $parent, $only) = @_;

	my $sql;
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my ($check, $read) = ($child, $parent);
	Order($child, $parent);
	my $comp;
	unless (UNIVERSAL::isa($this, 'ARRAY')) 
	{
		$comp = "= '$this'";
	} 
	else 
	{
		return () unless $#$this >= 0;
		$comp = "IN (" . join(", ", map {"'$_'";} @$this) . ")";
	}

	my $extra;
	if ($only) 
	{
		$extra = " AND B.${read}name = '$only'";
	}

       	$sql = "SELECT B.${read}name
               	FROM ${db}${child}_${parent}_matrix A,
                ${db}${read}s_t B,
       	        ${db}${check}s_t C
               	WHERE C.${check}name $comp
                        AND C.id = A.${check}_id
	                AND B.id = A.${read}_id $extra
                ORDER BY B.${read}name";
	$self->LoadArray($sql);
}
###############################################################################
sub Linkers 
{
	my ($self, $child, $parent) = @_;
	my $sql;
	my ($check, $read) = ($parent, $child);
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	Order($child, $parent);
       	$sql = "SELECT DISTINCT B.${read}name
               	FROM ${db}${child}_${parent}_matrix A,
                ${db}${read}s_t B
               	WHERE B.id = A.${read}_id
                ORDER BY B.${read}name";

	$self->LoadArray($sql);
}
###############################################################################
sub time2str ($$) 
{
	my ($fmt, $time) = @_;
	my $s;

	eval { require POSIX; 
		$s = POSIX::strftime($fmt, localtime($time));
	};
	return $s if $s;

	eval { require Date::Format; 
		$s = Date::Format::time2str($time);
	};

	return $s;
}
###############################################################################
sub Force ($$) 
{
	my ($value, $flags) = @_;

	return unless $HTML::Merge::Ini::VALUE_CHECKING;

	if ($flags =~ /n/i) 
	{
		HTML::Merge::Error::HandleError('ERROR', "'$value' is not an integer")
			unless ($value eq ($value * 1));
	}
	if ($flags =~ /i/i) 
	{
		HTML::Merge::Error::HandleError('ERROR', "'$value' is not an integer")
			unless ($value eq ($value * 1) 
				&& $value == int($value));
	}
	if ($flags =~ /u/i) 
	{
		HTML::Merge::Error::HandleError('ERROR', "'$value' is negative")
			if $value < 0;
	}
}
###############################################################################
sub time2HTTPstr 
{
    	my $time = shift;

	my @day = qw(Sun Mon Tue Wed Thu Fri Sat);
	my @month = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
	
    	my ($sec, $min, $hour, $mday, $mon, $year, $wday);

    	$time = time unless defined $time;
    	($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
    
    	return sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
            		$day[$wday],
            		$mday, $month[$mon], $year+1900,
            		$hour, $min, $sec);
}                   
###########################################
sub CreateMetaDataTable
{
	my ($self) = @_;

	my $dbh = $self->SYS_DBH();

	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my $table = "${db}tbl";
	my $ddl = "CREATE TABLE $table (
			tbl VARCHAR(6),
			langug_code VARCHAR(6),
			code VARCHAR(6),
			name VARCHAR(50),
			number FLOAT,
			note VARCHAR(255),
			realm_id INTEGER
		   )";

	$dbh->do($ddl);	

	# create indexes
	$ddl = "CREATE UNIQUE INDEX ux_tbl 
                ON $table (tbl,langug_code,code)";
	eval { $dbh->do($ddl); };

	$ddl = "CREATE INDEX x_langug_code 
                ON $table (langug_code)";
	eval { $dbh->do($ddl); };
}
###########################################
sub LoadSysTableFromFile
{
	my ($self,$file) = @_;

	my $dbh = $self->SYS_DBH();
	my $db = ($HTML::Merge::Ini::SESSION_DB)?"$HTML::Merge::Ini::SESSION_DB.":'';
	my (@col,$col,$val);
	my $table = $db;
	my $sql;
	my $sth;

	$file ||='list';

	open(I,"$file") || die "can't open data file $file";

	# get first line
	$table .= <I>;

	chomp $table;

	# get the second line 
	$col=<I>;

	chomp $col;
	chop $col;

	# create the collumn line        
	$col=~ s/\|/\,/g;

	# create the val
	@col=split(/\,/,$col);
	$val= '?,' x ($#col+1);
	chop($val);

	# do the insert string
	$sql="INSERT INTO $table ($col) VALUES ($val)";
	$sth=$dbh->prepare($sql);

	# truncate the table
	$dbh->do("DELETE FROM $table");

	while(<I>)
	{
        	next if(/^#/ || !(/\|/));

        	@col=split(/\|/,$_);
        	pop(@col);

        	$sth->execute(@col) || die $dbh->errstr;
	}
}
###########################################
1;
###########################################
__END__

=head1 NAME

HTML::Merge::Engine - Run time Engine

=head1 FUNCTIONS


=head2 Order

Given two scalars (most likely names of tables), swaps the
values of the two if they don't make up a Matrix table.


=head2 IsMatrix(CHILD, PARENT)

Can be called both directly as a function call and as a method call
$self->IsMatrix

returns true if CHILD_PARENT is one of the "matrix"-like tables.


=head2 LoadArray(SQL, @EXTRA)

Received an SQL statement and optional values to be
parameters of the SQL statement (I have not seen this used)
Prepares and executes a query and return the array of the
first column (!) as either an array or an array ref depending
on the calling context.


=head2 Links



=head2 $self->HasKey(REALM, USERNAME)

Returns if the given user is connected to the REALM directly or 
through being a member of a group.

This is the translation of the $RAUTH directive.  
TODO -> test and update the docs of RAUTH 

If no username is given, the currently logged in user is used.

returns 0 if no user given and not logged in
returns 1 if the user is connected to the REALM
returns undef otherwise


=head2 $self->CanEnter(TEMPLATE, USERNAME)

Invoked from the main script of merge.cgi
this checks if the given user can access the given template.


=head2 Login(USERNAME, PASSWORD)


Checks if the given username/password pair is in the database
(or if the user is the admin user with the admin password in the conf file)


