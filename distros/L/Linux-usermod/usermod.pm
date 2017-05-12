package Linux::usermod;

use strict;
use Carp;
use Fcntl ':flock';
use vars qw($VERSION);
$VERSION = 0.69;

our $file_passwd  = '/etc/passwd';
our $file_shadow  = '/etc/shadow';
our $file_group	  = '/etc/group';
our $file_gshadow = '/etc/gshadow';

my %field = (
	NAME     => 0,	#The user's name
	PPASSWORD=> 1,	#The "passwd" file password
	UID      => 2,	#The user's id
	GID      => 3,	#The user's group id 
	COMMENT  => 4,	#The comment about the user
	HOME     => 5,	#The user's home directory
	SHELL	 => 6,	#The user's shell
	SNAME	 => 7,	#The user's name in shadow file 
	PASSWORD => 8,	#The 13-character encrypted password
	LASTCHG  => 9, 	#The number of days since January 1, 1970 of the last password changed date
	MIN	 => 10, #The minimum number of days required between password changes
	MAX	 => 11,	#The maximum number of days the password is valid
	WARN	 => 12,	#The number of days before expiring the password that the user is warned
	INACTIVE => 13,	#The number of days of inactivity allowed for the user
	EXPIRE 	 => 14,	#The number of days since January 1, 1970 that account is disabled
	FLAG	 => 15	#Currently not used.	
);

my %gfield = (
	NAME	 => 0, #The group name
	PPASSWORD=> 1, #The group password
	GID	 => 2, #The group id number
	USERS	 => 3, #The group members (users)
	SNAME	 => 4, #The group name in gshadow file
	PASSWORD => 5, #The encrypted ggroup password
	GA	 => 6, #The group administrators
	GU	 => 7  #The group members (users)
);

sub fields { keys %field }

sub gfields { keys %gfield }

sub new {
	my $class = shift;
	my $user  = shift;
	my $flag  = shift;
	my @args;
	if ($flag){ 
		croak "no such group" unless _exists($user, $flag);
		@args = _read_grp($user);
		push @args, '__G__';
	}else{ 
		croak "no such user" unless _exists($user, $flag);
		@args = _read_user($user);
		push @args, '__U__';
	}
	return bless [ @args ], ref($class)||$class;
}

sub get {
	my $self = shift;
	my $what = shift;
	my $key;
	if($self->[-1] eq '__U__'){
		if($what =~ /^\d{1,2}$/){
			while(my($k, $v) = each %field){
				$v == $what and $key = $k 
			}
			return $self->[$field{$key}]
		}
		$what = uc $what;
		return $self->[$field{$what}]
	}
	elsif($self->[-1] eq '__G__'){
		if($what =~ /^\d{1,2}$/){
			while(my($k, $v) = each %gfield){
				$v == $what and $key = $k
			}
			return $self->[$gfield{$key}]
		}
		$what = uc $what;
		return $self->[$gfield{$what}]
	}		
}

sub set {
	my $self = shift;
	my $what = shift;
	my $newval = shift;
	$what = uc $what;
	return 0 unless exists($field{$what}) or exists($gfield{$what});
	return 0 if $newval =~ /:/ and ($field{$what} != 8 or $gfield{$what} != 4); 
	$newval = '' if $newval =~  /^undef$/i;
	if($self->[-1] eq '__U__'){
	 my $flag = shift || 0;
	 my $oldval = $self->[$field{$what}];
	 my $name = $self->[$field{NAME}];
	 _clean($name);
	 $self->[$field{$what}] = $newval;
	 if($field{$what} <= 6){
		my @file = _io("$file_passwd", '', 'r');
		my @user;
		push @user, $self->[$_] for 0..6;
		my $user = join ':', @user;
		for(@file){ s/.+/$user/ if /^\Q$name\E:/ }
		_io("$file_passwd", \@file, 'w');
		if($field{$what} == 0){
			croak "invalid name" if $newval !~ /^([A-Z]|[a-z]){1}\w{0,254}/;
			my %names;
			@file = @user = ();
			@file = _io("$file_shadow", '', 'r');
			map{ /^(.[^:]+):/ and $names{$1} = 1 }@file;
			croak "user name $newval already exists" if defined($names{$newval});	
			undef %names;
			push @user, $self->[$_] for 8..14;
			unshift @user, $self->[0];
			$user = join ':', @user;
			for(@file){ s/.+/$user/ if /^\Q$name\E:/ }
			_io("$file_shadow", \@file, 'w') and return 1
		}
		
	 }
	 if($field{$what} > 6){	
		my @file = _io("$file_shadow", '', 'r');
		$self->[9] = _get_1970_diff() if $field{$what} == 8;
		if($field{$what} == 8 && $newval){
			$oldval =~ /^!/ and my $lock = 1;
			$self->[8] = _gen_pass($self->[$field{$what}], $lock) unless $flag;
		}
		my @user;
		push @user, "$self->[$_]" for 7..15;
		my $user = join ':', @user;
		for(@file){ s/.+/$user/ if /^\Q$name\E:/ }
		_io("$file_shadow", \@file, 'w');
		if($field{$what} == 7){
			@file = @user = ();
			@file = _io("$file_passwd", '', 'r');
			push @user, $self->[$_] for 1..6;
			unshift @user, $self->[7];
			$user = join ':', @user;
			for(@file){ s/.+/$user/ if /^\Q$name\E:/ }
			_io("$file_passwd", \@file, 'w') and return 1
		}
	 }
	}
	elsif($self->[-1] eq '__G__'){
	 my $name = $self->[$gfield{NAME}];
	 my $oldval = $self->[$gfield{$what}];
	 $self->[$gfield{$what}] = $newval;
	 if($gfield{$what} == 0 or $gfield{$what} == 4){	
		croak "invalid name" if $newval !~ /^([A-Z]|[a-z]){1}\w{0,254}/;
	 	my @file = _io($file_group, '', 'r');
		my %names;
		map{ m#^(.[^:]+):# and $names{$1} }@file;
		croak "group name $newval already exists" if exists($names{$newval});
		undef %names;
		for(@file){
			/^$oldval:/ or next;
			my $newline = "$self->[0]:$self->[1]:$self->[2]:$self->[3]";
			s/.+/$newline/;
		}
		_io($file_group, \@file, 'w');
		@file = _io($file_gshadow, '', 'r');
		for(@file){
			/^$oldval:/ or next;
			$self->[4] = $newval;
			my $newline = "$self->[4]:$self->[5]:$self->[6]:$self->[7]";
			s/.+/$newline/;
		}
		_io($file_gshadow, \@file, 'w') and return 1
	 }
	 if($gfield{$what} == 3 or $gfield{$what} == 7){
		for(split /\s+/, $newval){
			croak "$_ does not exist" unless(_exists($_))
		}
		my $users = join ',', split /\s+/, "$newval";
		$self->[3] = $users;
		my @file = _io($file_group, '', 'r');
		for(@file){
			/^\Q$name\E:/ or next;
			my $newline = "$self->[0]:$self->[1]:$self->[2]:$self->[3]";
			s/.+/$newline/;
		}
		_io($file_group, \@file, 'w');
		@file = _io($file_gshadow, '', 'r');
		$self->[7] = $users;
		for(@file){
			/^\Q$name\E:/ or next;
			my $newline = "$self->[4]:$self->[5]:$self->[6]:$self->[3]";
			s/.+/$newline/;
		}
		_io($file_gshadow, \@file, 'w') and return 1
	 }
	 if($gfield{$what} == 2){	
	 	croak "wrong group id" if $newval < 1 or $newval > 65535;
		my %ids;
		my @file  = _io("$file_group", '', 'r');
		map { /^.+?:.*?:(.+):/ and $ids{$1} = 1 } @file;
		croak "group id $newval already exists" if $ids{$newval};
		for(@file){
			/^\Q$name\E:/ or next;
			my $newline = "$self->[0]:$self->[1]:$self->[2]:$self->[3]";
			s/.+/$newline/;
		}
		_io($file_group, \@file, 'w') and return 1
	 }
	 if($gfield{$what} == 6){
		croak "user $newval does not exist" unless(_exists($newval));
		$self->[6] = $newval;
		my @file = _io($file_gshadow, '', 'r');
		for(@file){
		        /^\Q$name\E:/ or next;
			my $newline = "$self->[4]:$self->[5]:$self->[6]:$self->[7]";
			s/.+/$newline/;
		}
		_io($file_gshadow, \@file, 'w') and return 1
	 }
	 if($gfield{$what} == 1 or $gfield{$what} == 5){
	 	no strict 'refs';
	 	my $salt = join '', ('a'..'z', 'A'..'Z', 0..9)[rand 26,rand 26,rand 26];
		my $newpass;
		if($newval)
			{ $newpass = crypt($newval, $salt) }
		else
			{ $newpass = '!' }
		my @file = _io($file_gshadow, '', 'r');
		$self->[1] = 'x';
		$self->[5] = $newpass;
		for(@file){
		        /^\Q$name\E:/ or next;
			my $newline = "$self->[4]:$self->[5]:$self->[6]:$self->[7]";
			s/.+/$newline/; 
		}
		_io($file_gshadow, \@file, 'w');
		@file = _io($file_group, '', 'r');
		for(@file){
		        /^\Q$name\E:/ or next;
			my $newline = "$self->[0]:$self->[1]:$self->[2]:$self->[3]";
			s/.+/$newline/;
		}
		_io($file_group, \@file, 'w') and return 1
	 }
	}
	return 0
}

sub _read_user {
	my $username = shift;
	my (@user, @tmp, @file);
	@file = _io($file_passwd, '', 'r');
	for(@file){
		/^\Q$username\E:/ or next;
		my $user = $_;
		for(1..7){
			$user =~ m#(.[^:]*){$_}#;
			my $ss = $1;
			$ss =~ s/(^:*|:*$)//;
			$tmp[$_ - 1] = $ss;
		} last
	}
	@user = @tmp;
	@tmp = ();
	@file = _io($file_shadow, '', 'r');
	for(@file){
		/^\Q$username\E:/ or next;
		my $user = $_;
		for(1..9){
			$user =~ m#(.[^:]*){$_}#;
			my $ss = $1;
			$ss =~ s/(^:*|:*$)//;
			$tmp[$_ - 1] = $ss;
		} last
	}
	@user = (@user, @tmp);
	return (@user);
}

sub _gen_pass {
	my $password = shift;
	my $flag = shift;
	$password or croak "no password given";
	my @rands = ( "A" .. "Z", "a" .. "z", 0 .. 9 );
	my $salt = join("", @rands[ map { rand @rands } ( 1 .. 8 ) ]);
	$password = ($flag)?'!'.crypt($password, q($1$)."$salt"):crypt($password, q($1$)."$salt");
	return $password
}

sub _exists {
	my $name	= shift;
	my $gflag	= shift; 
	my $file	= ($gflag) ? "$file_group" : "$file_passwd"; 
	my @file	= _io("$file", '', 'r');
	my $flag;
	/^\Q$name\E:/ and $flag = 1 for @file;
	return $flag ? 1 : 0
}

sub add {
	my $class = shift;
	my (%fields, $c, @args);
	push @args, $_ for @_;
	croak "no username given" if scalar @args == 0;
	croak "user $args[0] exists" if _exists($args[0]);
	for(@args){
		chomp($_);
		/^\s*$/ and $c++ and next;
		$c++;
		if($c == 1){
			croak "wrong username given" if /:/;
			croak "wrong username" unless /^([A-Z]|[a-z]){1}\w{0,254}/;
			$fields{username} = $_ || croak "no username given";
		}
		if($c == 2){
			croak "wrong password length" unless /^(.*){0,254}$/;
			$fields{password} = _gen_pass($_) if $_;
		}
		if($c == 3){
			$_ eq '' and $_ = 1000;
		 	croak "wrong uid" unless /^\d+$/;
			croak "wrong uid" if $_ > 65535 or $_ < 1;
			$fields{uid} = $_ || 1000;
		}
		if($c == 4){
			$_ eq '' and $_ = 1000;
			croak "wrong gid" unless /^\d+$/;
			if(/^\d+$/){ croak "wrong gid" if $_ > 65535 or $_ < 1 }
			$fields{gid} = $_ || $fields{uid};
		}
		if($c == 5){
			croak "wrong comment given" if /:/;
			$fields{comment} = $_;
		}
		if($c == 6){
			croak "wrong home given" if /:/;
			$fields{home} = $_;
		}
		if($c == 7){
			croak " wrong shell given" if /:/;
			$fields{shell} = $_;
		}
	}
	$fields{password} or $fields{password} = '!';
	my @file = _io("$file_passwd", '', 'r');
	my @ids;
	push @ids, (split /:/)[2] for @file;
	for (@ids){ 
		if ($fields{uid} == $_){
			$fields{uid} = 1000;
			last
		}
	}
	if($fields{uid} == 1000){
	   for(sort @ids){ 
		$_ < 1000 and next;
		$fields{uid} == $_ and $fields{uid}++;
	   }
	}
	$fields{gid} = $fields{uid} if !$fields{gid};
	my @newuser = ("$fields{username}:x:$fields{uid}:$fields{gid}:$fields{comment}:$fields{home}:$fields{shell}");
	_io("$file_passwd", \@newuser, 'a');
	my $time_1970 = _get_1970_diff();
	@newuser = ("$fields{username}:$fields{password}:$time_1970:0:99999:7:::");
	_io("$file_shadow", \@newuser, 'a');
	return 1
}

sub grpadd {
	my $class = shift;
	my $group = shift or croak "empty group name";
	my $gid = shift;
	my $users = shift;
	my (@tmp, %file, @newgroup);
	my @file  = _io("$file_group", '', 'r');
	croak "wrong group name" unless $group =~ /^([A-Z]|[a-z]){1}\w{0,254}/;
	map { @tmp = split /:/, $_ and $file{$tmp[0]} = $tmp[2] } @file;
	exists($file{$group}) and croak "group $group already exists";
	if(!$gid){
		$gid = 100;
		for(sort {$a <=> $b} values %file){ 
			next if $_ < 100; 
			$gid == $_ and $gid++ 
		}
	}
	my $userlist = join(',', split(/\s+/, $users));
	@newgroup = ("$group:x:$gid:$userlist");
	_io("$file_group", \@newgroup, 'a');
	@newgroup = ("$group:!!::$userlist");
	_io("$file_gshadow", \@newgroup, 'a');
}

sub del {
	my $class = shift;
	my $username = shift;
	_exists($username) or croak "user $username does not exist";
	my @old = _io("$file_passwd", '', 'r');
	my @new;
	/^\Q$username\E:/ or push @new, $_ for @old;
	_io("$file_passwd", \@new, 'w');
	@new = ();
	@old = _io("$file_shadow", '', 'r');
	/^\Q$username\E:/ or push @new, $_ for @old;
	_io("$file_shadow", \@new, 'w');
	return 1
}

sub grpdel {
	my $class = shift;
	my $group = shift or croak "empty group name/gid";
	my (@tmp, %file);
	my @file  = _io("$file_group", '', 'r');
	map { @tmp = split /:/, $_ and $file{$tmp[0]} = $tmp[2] } @file;
	exists($file{$group}) or croak "group $group does not exists";
	@tmp = ();
	/^$group/ or push @tmp, $_ for @file;
	_io("$file_group", \@tmp, 'w');
	@file = _io("$file_gshadow", '', 'r');
	@tmp = ();
	/^$group/ or push @tmp, $_ for @file;
	_io("$file_gshadow", \@tmp, 'w');
	
}

sub _read_grp {
	my $group = shift or croak "empty group name/gid";
	my (@tmp, @grp);
	my @file  = _io("$file_group", '', 'r');
	for(@file){
		/^$group:/ or next;
		my $user = $_;
		for(1..4){
			$user =~ /(.[^:]*){$_}/;
			my $ss = $1;
			$ss =~ s/(^:*|:*$)//;
			$tmp[$_ - 1] = $ss;
		} last 
	}
	@grp = @tmp;
	@file  = _io("$file_gshadow", '', 'r');
	for(@file){
		/^$group:/ or next;
		my $user = $_;
		for(1..4){
			$user =~ /(.[^:]*){$_}/;
			my $ss = $1;
			$ss =~ s/(^:*|:*$)//;
			$tmp[$_ - 1] = $ss;
		} last
	}
	@grp = (@grp, @tmp);
	return (@grp)
}

sub tobsd{
	my $self = shift;
	(my @file) = _io("$file_shadow", '', 'r');
	my $name = $self->get('name');
	my @user;
	for(@file){
		/^\Q$name\E:/ or next;
		push @user, $name, ':';
		push @user, $self->get('password'), ':';
		push @user, $self->get('uid'), ':';
		push @user, $self->get('gid'), ':';
		push @user, ':';
		push @user, $self->get('expire') || 0, ':';
		push @user, $self->get('expire') || 0, ':';
		push @user, $self->get('comment'), ':';
		push @user, $self->get('home'), ':';
		push @user, $self->get('shell');
		my $user = join '', @user;
		s/.*/$user/;
	}
	_io("$file_shadow", \@file, 'w');
	return 1
}

sub _io{
        my $file = shift;
	my $newvals = shift;
	my $flag = shift;
	my @file;
	croak $! unless -f $file;
	local *FH;
	die "posible flags: r/w/a" unless $flag =~ /^(r|w|a)$/;
	if($flag eq 'r'){
		open FH, $file or croak "can't open_r $file $!";
		flock FH, LOCK_SH or croak "can't lock_sh $file";
		@file = <FH>;
		close FH;
		map { s/\n// } @file;
		return @file;
	}
	if($flag eq 'w'){
		open FH, "> $file" or croak "can't open_w $file $!";
		flock FH, LOCK_EX or croak "can't lock_ex $file";
		print FH "$_\n" for @{$newvals};
		close FH;
		return 1
	}
	if($flag eq 'a'){
		open FH, ">> $file" or croak "can't open_a $file $!";
		flock FH, LOCK_EX or croak "can't lock_ex $file";
		print FH "$_\n" for @{$newvals};
		close FH;
		return 1
	}
}
	
sub users{
	my $class = shift;
	(my @file) = _io("$file_passwd", '', 'r');
	my (%users, @users);
	m#^(.[^:]+):# and push @users, $1 for @file;
	map{ $users{$_} = 1 }@users;
	return %users
}

sub grps{
	my $class = shift;
	(my @file) = _io("$file_group", '', 'r');
	my (%users, @users);
	m#^(.[^:]+):# and push @users, $1 for @file;
	map{ $users{$_} = 1 }@users;
	return %users
}
	
sub lock{
	my $self = shift;
	my $password = $self->get("password");
	return 1 if $password =~ /^\!/;
	$password =~ s/(.*)/!$1/;
	$self->set("password", $password, 1);
}

sub unlock{
        my $self = shift;
	my $password = $self->get("password");
	return if $password !~ /^\!/;
	$password =~ s/^\!//;
	$password ||= 'undef';
        $self->set("password", $password, 1);
}

sub _get_1970_diff{ return int time / (3600 * 24) }

sub _clean{
	my $specchars = \shift;
	my $special = qr#\$|\*|\@|\^|\+|\.|\?|\)|\(|\||\]|\[|\{|\}#;
	$$specchars =~ s/($special)/\\$1/g;
}

1

__END__

=head1 NAME

Linux::usermod - modify user and group accounts

=head1 SYNOPSIS

  use Linux::usermod;
  
  $user = Linux::usermod->new(username);
  $grp  = Linux::usermod->new(groupname, 1);
  
  $user->get(gid); # equal to $user->get(3);
  $user->get(uid); # equal to $user->get(2);
  $grp->get(gid);  # equal to $user->get(2);
  $grp->get(users);# equal to $user->get(3);
  
  #lock and unlock user account

  $user->lock();
  $user->unlock();

  #get password(passwd file)
  $user->get(ppassword);

  #get encoded password(shadow file)
  $user->get(password); 
  
  #set encoded password
  $user->set(password); 
  $grp->set(password);
  
  #set shell / group administrator
  $user->set(shell);
  $grp->set(ga);

  #set group users
  @users = qw(user1 user2);
  $grp->set(users, "@users");
  
  Linux::usermod->add(username);

  #or

  Linux::usermod->add(username, password, uid, gid, comment, home, shell);

  #where the password goes in shadow file and gid becomes 
  #equal to uid unless specified and uid is becoming the 
  #first unreserved number after 1000 unless specified
  
  #or
  
  @users = qw(user1 user2 user3);
  Linux::usermod->grpadd(groupname, gid, "@users")

  #where the password goes in gshadow file and gid becomes
  #equal to the second argument or the first unreserved number
  #after 100 

  #delete user/group
  Linux::usermod->del(username);
  Linux::usermod->grpdel(groupname);
  
  #all fields are returned from the class methods fields/gfields
  print $user->get($_) for (Linux::usermod->fields);
  print $grp->get($_) for (Linux::usermod->gfields);

  #set working passwd and shadow files

  #$Linux::usermod::file_passwd = "./my_passwd";
  #$Linux::usermod::file_shadow = "./my_shadow";
  #$Linux::usermod::file_group	= "./my_group";
  #$Linux::usermod::file_gshadow= "./my_gshadow";

=head1 DESCRIPTION

This module adds, removes and modify user and group accounts according to 
the passwd and shadow files syntax (like struct passwd from pwd.h). It is not necessary 
those accounts to be system as long as $Linux::usermod::file_passwd, $Linux::usermod::file_shadow,
$Linux::usermod::file_group, $Linux::usermod::file_gshadow are not in "/etc" directory.

=head1 METHODS

=over 8

=item new 

 Linux::usermod->new(username)
 Linux::usermod->new(grpname, 1)

If group object second 'true' argument must be given

=item add 

(username, ...)
Class method - add new user account; arguments are optional, except username;
they may be (username, password, uid, gid, comment, home, shell)

=item del 

(username)
Class method - removes user account

=item tobsd

converts user fields in shadow / master.passwd file to bsd style

=item get

if used with user object returns one of the following fields:

  'name'	or 0  The user's name
  'ppassword'	or 1  The "passwd" file password
  'uid'		or 2  The user's id
  'gid'		or 3  The user's group id
  'comment'	or 4  The comment about the user (real username)
  'home'	or 5  The user's home directory
  'shell'	or 6  The user's shell
  'sname'	or 7  The user's name in shadow file
  'password'	or 8  The 13-character encoded password
  'lastchg'	or 9  The number of days since January 1, 1970 of the last password changed date
  'min'		or 10 The minimum number of days required between password changes
  'max'		or 11 The maximum number of days the password is valid
  'warn'	or 12 The number of days before expiring the password that the user is warned
  'inactive'	or 13 The number of days of inactivity allowed for the user
  'expire'	or 14 The number of days since January 1, 1970 that account is disabled
  'flag'	or 15 Currently not used

if used with group object returns one of the following fields:

  'name'	or 0  The group name
  'ppassword'	or 1  The group password
  'gid'		or 2  The group id number
  'users'	or 3  The group members (users)
  'sname'	or 4  The group name in gshadow file (the same as 'name')
  'password'	or 5  The encrypted group password
  'ga'		or 6  The group administrators
  'gu'		or 7  The group members (users) (the same as 'users')

argument can be either string or number


=item set 

(field) 

set a field which must be string of characters:

  @user_fields = Linux::usermod->fields;	#user fields
  @group_fields = Linux::usermod->gfields;	#group fields

=item grpadd

(groupname)

=item grpdel

(groupname)

=item lock 

(username)
Lock user account (puts '!' at the beginning of the encoded password)

=item unlock 

(username)
Unlock user account (removes '!' from the beginning of the encoded password)

=item users

Class method - return hash which keys are all users, taken from $file_passwd

=item grps

Class method - return hash which keys are all groups, taken from $file_group

=back

=head1 FILES

/etc/passwd
/etc/shadow
/etc/group
/etc/gshadow 

unless given your own passwd, shadow, group, gshadow files 
which must be created

=head1 TO DO

Groups and user accounts consistency checks

=head1 SEE ALSO

getpwent(3), getpwnam(3), usermod(8), passwd(1), gpasswd(1)

=head1 BUGS

None known. Report any to author.

=head1 AUTHOR

Vidul Petrov, vidul@abv.bg

© 2004 Vidul Petrov. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
