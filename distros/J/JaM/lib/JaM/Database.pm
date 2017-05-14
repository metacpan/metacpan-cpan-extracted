# $Id: Database.pm,v 1.5 2001/10/27 15:17:28 joern Exp $

package JaM::Database;

use strict;
use Carp;
use Data::Dumper;
use DBI 1.20;

sub dbi_source		{ my $s = shift; $s->{dbi_source}
		          = shift if @_; $s->{dbi_source}	}
sub dbi_username	{ my $s = shift; $s->{dbi_username}
		          = shift if @_; $s->{dbi_username}	}
sub dbi_password	{ my $s = shift; $s->{dbi_password}
		          = shift if @_; $s->{dbi_password}	}
sub filename		{ my $s = shift; $s->{filename}
		          = shift if @_; $s->{filename}		}
sub sql_code		{ my $s = shift; $s->{sql_code}
		          = shift if @_; $s->{sql_code}		}
sub database_version	{ my $s = shift; $s->{database_version}
		          = shift if @_; $s->{database_version}	}

sub scramble {
	my $self = shift;
	my ($text) = @_;
	$text =~  tr/n-za-mN-ZA-M0-45-9/a-zA-Z5-90-4/;
	return $text;
}

sub load {
	my $type = shift;

	# read connection configuration from ~/.JaMrc
	my $filename = $ENV{JAMRC};
	$filename ||= "$ENV{HOME}/.JaMrc";

	# if filename does not exist, return default object
	if ( not -f $filename ) {
		return bless {
			dbi_source => 'dbi:mysql:jam',
			dbi_username => '',
			dbi_password => '',
			filename     => $filename,
		}, $type;
	}
	
	# chmod 0600 due to security reasons
	my @stat = stat $filename;
	chmod 0600, $filename if $stat[2] != 0600;
	
	# read config
	my $config;
	eval { $config = do $filename };
	confess "Error reading $filename: $@" if $@;
	
	# return object
	return bless {
		filename     => $filename,
		dbi_source   => $config->{dbi_source},
		dbi_username => $config->{dbi_username},
		dbi_password => $type->scramble($config->{dbi_password})
	}, $type;
}

sub save {
	my $self = shift;
	
	my %config = (
		dbi_source   => $self->{dbi_source},
		dbi_username => $self->{dbi_username},
		dbi_password => $self->scramble($self->{dbi_password})
	);
	
	my $dump = Dumper(\%config);
	$dump =~ s/\$\w+\s*=\s*//;
	
	open (OUT, ">".$self->filename)
		or confess "can't write ".$self->filename;
	print OUT $dump;
	close OUT;

	1;
}

sub test {
	my $self = shift;
	
	my $dbh;
	eval {
		$dbh = DBI->connect (
			$self->dbi_source,
			$self->dbi_username,
			$self->dbi_password,
			{ RaiseError => 1,
			  PrintError => 0, }
		);
	};

	if ( not $dbh or $@ or $DBI::errstr ) {
		my $err = $DBI::errstr if $DBI::errstr;
		$err ||= $@ || "Fatal database error, can't get error message.";
		print "'$err'\n";
		if ( $err =~ /^Unknown database/ ) {
			$err = "Connection: Ok\nDatabase: missing\n";
		}
		return $err;
	}

	eval {
		$dbh->do ("select value from Config where name='foo'");
	};
	my $err = $@;
	
	$dbh->disconnect;

	return "Connection: Ok\nDatabase: Ok\nTables: missing\n" if $err;

	return "Connection: Ok\nDatabase: Ok\nTables: Ok\n";
}

sub connect {
	my $thing = shift;

	my $self;
	if ( ref $thing ) {
		$self = $thing;
	} else {
		$self = $thing->load;
	}

	my $dbh;
	eval {
		$dbh = DBI->connect (
			$self->dbi_source,
			$self->dbi_username,
			$self->dbi_password,
			{ RaiseError => 1,
			  PrintError => 0, }
		);
	};

	return if not $dbh or $@ or $DBI::errstr;
	return $dbh;
}

sub create {
	my $self = shift;

	my $dbi_source = $self->dbi_source;
	if ( $dbi_source !~ /^dbi:mysql:(.*)/ ) {
		return  "Database creation is supported on MySQL only.\n";
			"Please create database by hand and execute\n".
			"just 'Create Tables' here.";
	}

	my $db_name = $1;

	my $dbi_source_wo_db = "dbi:mysql:";
	$self->dbi_source($dbi_source_wo_db);

	my $dbh;
	eval {
		$dbh = $self->connect;
	};
	return  "Can't connect to database.\n".
		"Please test the configuration first!"
			if $@ or not $dbh;

	$self->dbi_source($dbi_source);

	eval {
		$dbh->do (
			"create database $db_name"
		);
	};
	my $err = $@;

	$dbh->disconnect;

	if ( $err ) {
		$err =~ s/at .*line\s+\d+.$//;
		return $err;
	}
	
	return "Database created.\n";
}

sub create_tables {
	my $self = shift;

	my $dbh;
	eval {
		$dbh = $self->connect;
	};
	return  "Can't connect to database.\n".
		"Please test the configuration first!"
			if $@;

	my $error = $self->execute_sql (
		dbh => $dbh,
		section => 'init'
	);

	$self->set_schema_version (
		dbh => $dbh,
		version => $self->init_version
	);

	$dbh->disconnect;
	
	return $error;
}

sub execute_sql {
	my $self = shift;
	my %par = @_;
	my ($dbh, $section) = @par{'dbh','section'};
	
	my $sql_code = $self->get_sql_section (
		section => $section
	);
	
	my $statement = "";
	my $error;
	my $nr = 1;
	my $line;
	while ( $sql_code =~ m!^(.*)$!mg ) {
		$line = $1;
		next if $line =~ /^\s*#/;
		$statement .= $line."\n";
		if ( $statement =~  s/;\s*$// ) {
			if ( $statement !~ /^\s*$/ ) {
				eval {
					$dbh->do ($statement);
				};
				if ( $@ ) {
					$error = $@;
					$error =~ s/at .*line\s+\d+.$/at line $nr/;
					last;
				}
			}
			$statement = "";
		}
		++$nr;
	}
	
	return $error;
}

sub get_sql_section {
	my $self = shift;
	my %par = @_;
	my ($section) = @par{'section'};
	
	my $sql_code = $self->load_sql_code;
	
	$sql_code =~ m!#<$section>#(.*?)#</$section>#!s;
	
	return $1;
}

sub load_sql_code {
	my $self = shift;
	my $sql_code = $self->sql_code;
	return $sql_code if $sql_code;

	my $filename = "lib/JaM/init.sql";
	open (IN, $filename) or confess "can't read $filename";
	$sql_code = join ('',<IN>);
	close IN;
	
	$self->sql_code($sql_code);
	
	return $sql_code;
}

sub init_version {
	my $self = shift;
	return $self->{init_version} if defined $self->{init_version};
	
	my $sql = $self->load_sql_code;

	my $init_version;
	while ( $sql =~ m/#\s*<\s*version\s*(\d+)\s*>\s*#/g ) {
		$init_version = $1;
	}

	$init_version ||= 1;

	$JaM::SCHEMA = $init_version;
	
	return $self->{init_version} = $init_version;
}

sub schema_ok {
	my $self = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};

	my $db_version;
	eval {
		($db_version) = $dbh->selectrow_array (
			"select value
			 from	Config
			 where  name='database_schema_version'"
		);
	};
	$db_version = 0 if $@;

	$self->database_version($db_version);
	my $init_version = $self->init_version;

	return $init_version <= $db_version;
}

sub set_schema_version {
	my $self = shift;
	my %par = @_;
	my ($dbh, $version) = @par{'dbh','version'};
	
	$dbh->do (
		"update Config set value=?
		 where name='database_schema_version'", {},
		$version
	);
	
	$self->database_version ($version);

	1;
}

#---------------------------------------------------------------------
# methods for database updates
#---------------------------------------------------------------------

sub db_update_version_4 {
	my $self = shift;
	my %par = @_;
	my ($dbh) = @par{'dbh'};

	require JaM::Filter::IO;
	
	# save all filters to get the folder_id column
	
	my $filters = JaM::Filter::IO->list (
		dbh => $dbh
	);
	
	my $filter;
	foreach my $entry ( @{$filters} ) {
		$filter = JaM::Filter::IO->load (
			dbh => $dbh,
			filter_id => $entry->{id}
		);
		$filter->save;
	}
	
	1;
}

1;
