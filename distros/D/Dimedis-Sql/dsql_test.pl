#!/usr/dim/bin/perl

#---------------------------------------------------------------------------
# SNYOPSIS:
#	dsql_test.pl DBI_DATA_SOURCE USER PW DB
#	dsql_test.pl utf8  DBI_DATA_SOURCE USER PW DB
#---------------------------------------------------------------------------

# $ENV{MYSQL_UNIX_PORT} = "/usr/dim/var/mysql4.sock";

use strict;
use lib 'lib';
use Test;
$| = 1;

# use a BEGIN block so we print our plan before MyModule is loaded
BEGIN { plan tests => 99 }

# load your module...
use Dimedis::Sql;

# main program with test calls
main: {
	my $utf8;
	if ( @ARGV[0] eq "utf8" ) {
		$utf8 = 1;
		shift @ARGV;
	}
	my $dsn = shift @ARGV;
	my $username = shift @ARGV;
	my $password = shift @ARGV;
	my $db_name = shift @ARGV;
	
	if ( not $dsn ) {
		print "\nusage: dsql_test.pl [utf8] dsn [ username [ password [ db_name ]]]\n\n";
		system ("cat dsql_test_conn.txt") if -f "dsql_test_conn.txt";
		exit;
	}

	my $t = new Dimedis::Sql::Test (
		dsn      => $dsn,
		username => $username,
		password => $password,
		db_name  => $db_name,
		utf8     => $utf8,
		debug    => 0,
	);

	$t->{sqlh}->{cache} = 1;
	
	$t->{dbh}->{AutoCommit} = 1;

	ok ( $t->test("drop_tables") );
	ok ( $t->test("create_tables") );

	ok ( $t->test("insert") );
	ok ( $t->test("insert_null") );
	ok ( $t->test("insert_utf8_latin") );
	ok ( $t->test("insert_serial_only") );
	ok ( $t->test("insert_memory_blob") );
	ok ( $t->test("insert_memory_clob") );
	ok ( $t->test("insert_file_blob") );
	ok ( $t->test("insert_file_clob") );
	ok ( $t->test("insert_utf8_latin_clob") );

	ok ( $t->test("update") );
	ok ( $t->test("update_utf8_latin") );
	ok ( $t->test("update_memory_blob") );
	ok ( $t->test("update_memory_clob") );
	ok ( $t->test("update_file_blob") );
	ok ( $t->test("update_file_clob") );
	ok ( $t->test("update_utf8_latin_clob") );

	ok ( $t->test("delete_file_blob") );

	ok ( $t->test("dump_table") );
	ok ( $t->test("outer_select_create_tables") );
	ok ( $t->test("outer_select_action") );

	ok ( $t->test("cmpi") );
#	ok ( $t->test("contains") );

	if ( $utf8 ) {
		ok ( $t->test("insert_utf8") );
		ok ( $t->test("insert_blob_mem_utf8") );
		ok ( $t->test("insert_clob_mem_utf8") );
		ok ( $t->test("insert_blob_file_utf8") );
		ok ( $t->test("insert_clob_file_utf8") );
		ok ( $t->test("insert_clob_fh_utf8") );
		ok ( $t->test("update_utf8") );
		ok ( $t->test("update_blob_mem_utf8") );
		ok ( $t->test("update_clob_mem_utf8") );
		ok ( $t->test("update_blob_file_utf8") );
		ok ( $t->test("update_clob_file_utf8") );
		ok ( $t->test("get_utf8_array") );
		ok ( $t->test("get_utf8_hash") );
		ok ( $t->test("cmpi_utf8") );
	}

}

# this is our Test class, which controls all the tests

package Dimedis::Sql::Test;

use DBI;
use Data::Dumper;
use FileHandle;

my %create_table;

sub new {
	my $type = shift;
	my %par  = @_;
	
	my $dsn      = $par{dsn};
	my $username = $par{username};
	my $password = $par{password};
	my $db_name  = $par{db_name};
	my $utf8     = $par{utf8};
	my $debug    = $par{debug};

	my ($db) = ( $dsn =~ /^dbi:(.*?):/ );
	
	my $dbh = DBI->connect (
		$dsn, $username, $password,
		{
			PrintError => 0,
			RaiseError => 0,
			AutoCommit => 1,
		}
	);
	die $DBI::errstr if $DBI::errstr;

	my $self = bless {
		dsn      => $dsn,
		username => $username,
		password => $password,
		db       => $db,
		dbh      => $dbh,
		utf8     => $utf8,
	}, $type;

	$self->init;

	my $sqlh = new Dimedis::Sql (
		dbh   => $dbh,
		type  => $self->{type_href},
		debug => $debug,
		cache => 0,
		utf8  => $utf8,
	);

	$self->{sqlh} = $sqlh;

	if ( $db_name ) {
		$sqlh->use_db ( db => $db_name );
	}

	$sqlh->install;
	
	return $self;
}

sub init {
	my $self = shift;

	# constant randomize, so random numbers are deterministic
	srand 42;
	
	my $mysql_charset_stuff = $self->{utf8} ?
		"default charset=utf8" :
		"default charset=latin1 collate=latin1_german1_ci";
	
	# Dimedis::Sql type definiton for our test table
	$self->{type_href} = {
	  'dsql_test' => {
		id		=> 'serial',
		test_case	=> 'varchar(80)',
		nr1		=> 'integer',
		nr2		=> 'integer',
		str_short	=> 'varchar(80)',
		str_long	=> 'varchar(4000)',
		chr		=> 'char(100)',
		datum   	=> 'date',
		blob_data	=> 'blob',
		clob_data	=> 'clob',
	  }
	};

	# DDL statements for our test table
	%create_table = (
	   "Oracle" => [ qq{
		create table dsql_test (
			id		int primary key not null,
			test_case	varchar2(80),
			nr1		integer,
			nr2		integer,	
			str_short	varchar2(80),
			str_short2	varchar2(80),
			str_long	varchar2(4000),
			chr		char(100),
			datum		varchar2(19),
			blob_data	blob,
			clob_data	clob
		)
	   } ],
	   "mysql" => [ qq{
		create table dsql_test (
			id		int primary key not null
					auto_increment,
			test_case	varchar(80),
			nr1		integer,
			nr2		integer,	
			str_short	varchar(80),
			str_short2	varchar(80),
			str_long	text,
			chr		char(100),
			datum		varchar(19),
			blob_data	mediumblob,
			clob_data	mediumblob
		) type = InnoDB $mysql_charset_stuff
	   } ],
	   "Pg" => [ qq{
		create table dsql_test (
			id		int primary key not null,
			test_case	varchar(80),
			nr1		integer,
			nr2		integer,	
			str_short	varchar(80),
			str_short2	varchar(80),
			str_long	text,
			chr		char(100),
			datum		varchar(19),
			blob_data	integer,
			clob_data	integer
		)
	   }, qq{
		create rule "dsql_test_blob_remove" as
			on delete to "dsql_test"
			do select lo_unlink(old.blob_data)
	   }, qq{
		create rule "dsql_test_clob_remove" as
			on delete to "dsql_test"
			do select lo_unlink(old.clob_data)
	   }, ],
	   "ASAny" => [ qq{
		create table dsql_test (
			id		int primary key not null,
			test_case	varchar(80),
			nr1		integer,
			nr2		integer,	
			str_short	varchar(80),
			str_short2	varchar(80),
			str_long	text,
			chr		char(100),
			datum		varchar(19),
			blob_data	long binary,
			clob_data	long varchar
		)
	   } ],
	   "Sybase" => [ qq{
		create table dsql_test (
			id    		integer primary key not null,
			test_case	varchar(80) null,
			nr1		integer null,
			nr2		integer null,	
			str_short	varchar(80) null,
			str_short2	varchar(80) null,
			str_long	text null,
			chr		char(100),
			datum		varchar(19) null,
			blob_data	integer null,
			clob_data	integer null
		)
	   } ],
	   "ODBC" => [ qq{
		create table dsql_test (
			id    		integer primary key not null,
			test_case	varchar(80) null,
			nr1		integer null,
			nr2		integer null,	
			str_short	varchar(80) null,
			str_short2	varchar(80) null,
			str_long	text null,
			chr		char(100),
			datum		varchar(19) null,
			blob_data	integer null,
			clob_data	integer null
		)
	   } ],
	);
}

sub DESTROY {
	my $self = shift;
	
	$self->{dbh}->disconnect if $self->{dbh};
}

sub test {
	my $self = shift;
	my ($method) = @_;
	
	my $rc = eval { $self->$method() };
	print STDERR $@ if $@;

	return $rc;
}

sub msg {
	my $self = shift;
	
	my $info;
	
	if ( not @_ ) {
		my @caller = caller(1);
		$caller[3] =~ /::([^:]+)$/;
		$info = $1;
	} else {
		$info =  join ("\n", @_);
	}

	my $line = "." x 32;
	substr($line,0,length($info)) = $info;
	
	print "$line ";

	1;
}

sub hash_compare {
	my $self = shift;
	
	my ($h1, $h2) = @_;

	my %h1 = %{$h1};
	my %h2 = %{$h2};

	my $result = 1;
	foreach my $k ( keys %{$h1} ) {
		$result = 0, last
			if ( defined   $h1->{$k} and  ! defined $h2->{$k} ) or
			   ( ! defined $h1->{$k} and    defined $h2->{$k} );
		$result = 0, last if ":".$h1->{$k}.":" ne ":".$h2->{$k}.":";
	}

	foreach my $k ( keys %{$h2} ) {
		$result = 0, last
			if ( defined   $h1->{$k} and  ! defined $h2->{$k} ) or
			   ( ! defined $h1->{$k} and    defined $h2->{$k} );
		$result = 0, last if ":".$h1->{$k}.":" ne ":".$h2->{$k}.":";
	}

	if ( not $result ) {
		my $dump = q[
			print STDERR "\n\nwritten:\n--------\n";
			my ($k,$v);
			foreach my $k ( sort keys %h1 ) {
				$v = $h1{$k};
				printf STDERR "col=%-15s utf8=%4s  data=%s\n",
					$k, (is_utf8($v)?"1":"0"), "'$v'";
			}
			print STDERR "\nread:\n-----\n";     
			foreach my $k ( sort keys %h2 ) {
				$v = $h2{$k};
				printf STDERR "col=%-15s utf8=%4s  data=%s\n",
					$k, (is_utf8($v)?"utf8":"    "), "'$v'";
			}
			print STDERR "\n";
		];
		if ( $self->{utf8} ) {
			$dump = "use bytes; use Encode 'is_utf8';\n.$dump\n";
		} else {
			$dump = "sub is_utf8 { 0 }\n$dump\n";
		}
		eval $dump;
	}
	
	return $result;
}
	
sub drop_tables {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	eval {
		$sqlh->do (
			sql => 'drop table dsql_test'
		);
	};

	eval {
		$sqlh->do (
			sql => 'drop sequence drop sequence dsql_test_seq'
		);
	};
	
	return 1;
}

sub create_tables {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	foreach my $sql ( @{ $create_table{$self->{db}} } ) {
		$sqlh->do ( sql => $sql );
	}

	return 1;
}

sub mem_to_file {
	my $self = shift;
	my %par = @_;
	my ($mem, $utf8) = @par{'mem','utf8'};

	my $file = "/tmp/dsql.mem.$$";
	my $fh = FileHandle->new;
	open ($fh, ">$file") or die "can't write $file";
	binmode $fh, ":utf8" if $utf8;
	print $fh $$mem;
	close $fh;

	return $file;
}

sub insert {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			id		=> undef,
			nr1		=> 42,
			nr2		=> 43,
			str_short	=> " little test string with: äüöÄÜÖß",
			datum           => "2002052212:13:14",
		},
		what => 'insert',
	);
}

sub insert_null {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $undef = undef;
	my $empty = "";

	return if not $self->insert_update_check (
		data => {
			id		=> undef,
			nr1		=> $undef,
			nr2		=> undef,
			str_short	=> '',
			str_long	=> '',
			datum           => undef,
			clob_data	=> \$empty,
		},
		what => 'insert',
	);
	
	return $self->insert_update_check (
		data => {
			id		=> undef,
			nr1		=> $undef,
			nr2		=> undef,
			str_short	=> undef,
			str_long	=> undef,
			datum           => undef,
		},
		what => 'insert',
	);
}

sub insert_utf8_latin {
        my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

        my $data = do { use utf8; "JÃ¶rn Reder, Ã„ÃœÃ–ÃŸ" };
        
	return $self->insert_update_check (
		data => {
			id		=> undef,
			str_short	=> $data,
			str_long	=> $data,
		},
		what => 'insert',
	);
}

sub insert_update_check {
	my $self = shift;
	my %par    = @_;
	my $data   = $par{data};
	my $what   = $par{what};
	my $where  = $par{where};
	my $params = $par{params};

	my $sqlh = $self->{sqlh};

	my @caller = caller(1);
	$caller[3] =~ /::([^:]+)$/;
	my $caller = $caller[3];

	$data->{test_case} = $caller;

	my %update_params;
	my $update_id_key = $caller;
	$update_id_key =~ s/update/insert/;
	$update_id_key = $self->{"id_$update_id_key"};

	if ( $what eq 'update' ) {
		if ( $where ) {
			%update_params = (
				where  => $where,
				params => $params,
			);
		} else {
			%update_params = (
				where => "id = ?",
				params => [ $update_id_key ]
			);
		}
	}

	my $rv = $sqlh->$what (
		table => 'dsql_test',
		data => $data,
		%update_params
	);

	my $id;
	if ( $what eq 'update' ) {
		$id = $update_id_key;
		if ( $rv == 0 ) {
			print STDERR "rv=$rv\n";
			return 0;
		}
	} else {
		$id = $rv;
	}

	$data->{id} = $id;
	$self->{"id_$caller"} = $id;

	my $fields = join (',', (grep !/lob_data$/, keys %{$data}));

	my $href = $sqlh->get (
		sql => "select $fields
			from   dsql_test
			where  id = ?",
		params => [ $id ]
	);

	foreach my $lob ( grep /lob_data$/, keys %{$data} ) {
		# lets get the blob into memory,
		# if not there already
		my $type = $lob =~ /clob/ ? "clob" : "blob";

		seek $data->{$lob}, 0, 0 if ref $data->{$lob} and
					    ref $data->{$lob} ne 'SCALAR';

		$data->{$lob} = ${$sqlh->blob2memory(
			$data->{$lob}, $lob, $type
		)};

		my $blob = $sqlh->blob_read (
			table => 'dsql_test',
			col   => $lob,
			where => "id = ?",
			params => [ $id ],
		);
		
		$href->{$lob} = $$blob;
	}

	# make empty non-blob-colums of the source data hash undef,
	# because Dimedis::Sql does this internally when inserting
	# to get the same behaviour for all databases.

	foreach my $key ( keys %{$data} ) {
		if ( $self->{type_href}->{dsql_test}->{$key} !~ /lob/ ) {
			$data->{$key} = undef if $data->{$key} eq '';
		}
	}

	return $self->hash_compare ( $data, $href );
}

sub insert_serial_only {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			id	=> undef,
		},
		what => 'insert',
	);
}

sub insert_memory_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $memory_blob = "das ist ein super CLOB äüö " x 2;

	return $self->insert_update_check (
		data => {
			id => undef,
			clob_data => \$memory_blob
		},
		what => 'insert',
	);
}

sub insert_file_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			id => undef,
			clob_data => "/etc/hosts",
		},
		what => 'insert',
	);
}

sub insert_memory_blob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $memory_blob = "das ist äüöÄÜÖß ein ".chr(250)." super BLOB\n" x 10;

	return $self->insert_update_check (
		data => {
			id => undef,
			clob_data => \$memory_blob
		},
		what => 'insert',
	);
}

sub insert_file_blob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			id => undef,
			clob_data => "/etc/group",
		},
		what => 'insert',
	);
}

sub insert_utf8_latin_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
        my $data = do { use utf8; "JÃ¶rn Reder, Ã„ÃœÃ–ÃŸ\n" };
	my $memory_blob = $data x 10;

	return $self->insert_update_check (
		data => {
			id        => undef,
			clob_data => \$memory_blob,
                        str_short => "utf8_latin_clob",
		},
		what => 'insert',
	);
}

sub delete_file_blob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $sqlh = $self->{sqlh};
	
	my $delete_id_key = $self->{"id_Dimedis::Sql::Test::insert_file_blob"};

	my $cnt = $sqlh->do (
		sql    => "delete from dsql_test where id=?",
		params => [ $delete_id_key ],
	);

	return $cnt == 1;
}


sub update {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			nr1		=> 1,
			nr2		=> 2,
			str_short	=> " updated test string",
		},
		what => 'update',
	);
}

sub update_utf8_latin {
        my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

        my $data      = do { use utf8; "ABC JÃ¶rn Reder, Ã„ÃœÃ–ÃŸ" };
        my $str_short = do { use utf8; "JÃ¶rn Reder, Ã„ÃœÃ–ÃŸ" };
        
	return $self->insert_update_check (
		data => {
                    str_short	=> $data,
                    str_long	=> $data,
		},
                where   => "str_short = ?",
                params  => [ $str_short ],
		what    => 'update',
	);
}

sub update_memory_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $memory_blob = "das äüöÄÜÖß ist ein anderer super CLOB\n" x 10;

	return $self->insert_update_check (
		data => {
			clob_data => \$memory_blob
		},
		what => 'update',
	);
}

sub update_file_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			clob_data => "/etc/passwd",
		},
		what => 'update',
	);
}

sub update_memory_blob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $memory_blob = "das äüöÄÜÖß ist ein anderer ".chr(250)." super BLOB\n" x 10;

	return $self->insert_update_check (
		data => {
			clob_data => \$memory_blob
		},
		what => 'update',
	);
}

sub update_file_blob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	return $self->insert_update_check (
		data => {
			clob_data => "/etc/fstab",
		},
		what => 'update',
	);
}

sub update_utf8_latin_clob {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
        my $data = do { use utf8; "JÃ¶rn Reder, Ã„ÃœÃ–ÃŸ\n" };
	my $memory_blob = $data x 10;

	return $self->insert_update_check (
		data => {
                    clob_data => \$memory_blob
		},
		what => 'update',
                where  => "str_short = ?",
                params => [ "utf8_latin_clob" ],
	);
}

sub cmpi {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $id = $sqlh->insert (
		table => "dsql_test",
		data => {
			id => undef,
			test_case => "cmpi",
			str_short => "BRA bra",
		}
	);
	
	my $cond = $sqlh->cmpi (
		col => "str_short",
		val => "bra bra",
		op  => "=",
	);
	
	my ($read_id) = $sqlh->get (
		sql => "select id
			from   dsql_test
			where  $cond",
	);

	return $read_id == $id;
}

sub contains {
	my $self = shift;
	my $sqlh = $self->{sqlh};

	return if not $sqlh->get_features->{contains};

	$self->msg;
	
	my $id = $sqlh->insert (
		table => "dsql_test",
		data => {
			id        => undef,
			test_case => "contains",
			str_short => "BRA contains foo schnackel baz",
		}
	);
	
	my $cond = $sqlh->contains (
		col       => "str_short",
		vals      => ['bra', 'baz'],
		logic_op  => "and",
		search_op => "sub",
	);
	
	my ($read_id) = $sqlh->get (
		sql => "select id
			from   dsql_test
			where  $cond",
	);

	return if $read_id != $id;
	
	$cond = $sqlh->contains (
		col       => "str_short",
		vals      => ['schnackel', 'FACKEL'],
		logic_op  => "or",
		search_op => "sub",
	);
	
	($read_id) = $sqlh->get (
		sql => "select id
			from   dsql_test
			where  $cond",
	);
	
	return $read_id == $id;
}

sub dump_table {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $dbh = $sqlh->{dbh};
	
	my $sth = $dbh->prepare (
		"select id, test_case, nr1, nr2, str_short,
		        str_long, datum
		 from   dsql_test
		 order  by test_case"
	);
	$sth->execute;
	
	my $dump;
	my $ar;
	my $id;
	my @ids;
	while ( $ar = $sth->fetchrow_arrayref ) {
		my @l = @{$ar};
		$id = $l[0];
		push @ids, $id;
		shift @l;
		$dump .= "\nrow($l[0]):\n";
		$dump .= join (",", @l);
		$dump .= "\n";
	}
	$sth->finish;

	foreach $id ( @ids ) {
		my $blob = $sqlh->blob_read (
			table => 'dsql_test',
			col   => 'clob_data',
			where => "id = $id",
		);
		$dump .= $$blob;

		$blob = $sqlh->blob_read (
			table => 'dsql_test',
			col   => 'blob_data',
			where => "id = $id",
		);
		$dump .= $$blob;
		$dump .= "\n\n";
	}

	my $fh = new FileHandle;
	my $file = "dsql_$self->{db}.dump";
	open ($fh, "> tmp/$file") or die "can't write tmp/$file";
	print $fh $dump;
	close $fh;

	return 1;
}

sub outer_select_create_tables {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
	my $mysql_charset_stuff = $self->{utf8} ?
		"default charset=utf8" :
		"default charset=latin1 collate=latin1_german1_ci";

	$mysql_charset_stuff = ""
		unless $sqlh->{dbh}->{Driver}->{Name} =~ /mysql/;

	# first create four tables
	foreach my $t ('A' .. 'D') {
		eval {
			$sqlh->do (
				sql => "drop table $t"
			);
		};
		$sqlh->do (
			sql => "create table $t (
				  id  integer,
				  foo varchar(2),
				  bar varchar(2)
				) $mysql_charset_stuff"
		);
	}

	# fill them with some data
	my $offset = 0;
	foreach my $t ('A' .. 'D') {
		for (my $i=$offset; $i < 14-$offset; ++$i) {
			$sqlh->insert (
				table => $t,
				data => {
					id => $i,
					foo => chr(65+$i-$offset)x2,
					bar => chr(80-$i)x2
				}
			);
		}
		$offset += 2;
	}
	
	return 1;
}

sub outer_select_action {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;
	
#	open (OUT, ">>foo");
	
	my ($from, $where);

	($from, $where) = $sqlh->left_outer_join (
		"A", [ "B" ], "A.id = B.id"
	);
	
	my $data = $self->do_outer_select(
		select => "A.id, A.foo, B.id, B.foo",
		from   => $from,
		where  => $where
	);

#	print OUT $data;

	($from, $where) = $sqlh->left_outer_join (
		"A", [ "B" ], "A.id = B.id ", [ "C" ], "A.foo = C.foo"
	);

	$data .= $self->do_outer_select(
		select => "A.id, A.foo, B.id, B.foo, C.id, C.foo",
		from   => $from,
		where  => $where
	);	

#	print OUT $data;

	($from, $where) = $sqlh->left_outer_join (
		"A", [ "B" ], "A.id = B.id and B.foo = 'EE'", [ "C" ], "A.foo = C.foo and C.foo = 'DD'"
	);
	
	$data .= $self->do_outer_select(
		select => "A.id, A.foo, B.id, B.foo, C.id, C.foo",
		from   => $from,
		where  => $where
	);	

#	print OUT $data;

	if ( $self->{db} ne 'Sybase' ) {
		$data .= "nested\n";
		($from, $where) = $sqlh->left_outer_join (
			"A", [ "B", ["C"], "B.foo = C.foo" ], "A.id = B.id"
		);

		$data .= $self->do_outer_select(
			select => "A.id, A.foo, B.id, B.foo, C.id, C.foo",
			from   => $from,
			where  => $where
		);	

	#	print OUT $data;

		($from, $where) = $sqlh->left_outer_join (
			"A", [ "B", ["C", ["D"], "D.bar = C.bar"], "B.foo = C.foo" ], "A.id = B.id"
		);

		$data .= $self->do_outer_select(
			select => "A.id, A.foo, B.id, B.foo, C.id, C.foo, C.bar, D.id, D.bar",
			from   => $from,
			where  => $where
		);	

	#	print OUT $data;

		($from, $where) = $sqlh->left_outer_join (
			"A", [ "B", ["C", ["D"], "D.bar = C.bar"], "B.foo = C.foo" ], "A.id = B.id and B.foo = 'II'"
		);

		$data .= $self->do_outer_select(
			select => "A.id, A.foo, B.id, B.foo, C.id, C.foo, C.bar, D.id, D.bar",
			from   => $from,
			where  => $where
		);	
	}

#	print OUT $data;
#	close OUT;
	
	open (IN, $0) or die "can't read $0";
	my $orig;
	my $in_data;
	while (<IN>) {
		$in_data = 1, next if /^__END__/;
		next if not $in_data;
		$orig .= $_;
	}
	close IN;
	
#	print "orig:\n$orig\n";
#	print "data.\n$data\n";
	
	return $orig eq $data;
}

sub do_outer_select {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	
	my %par = @_;
	my $select = $par{select};
	my $from   = $par{from};
	my $where  = $par{where};
	
	my $data;
	
	$where = "where $where" if $where;

	my $sth = $sqlh->{dbh}->prepare (qq{
		select $select
		from   $from
		$where
		order by $select
	}) or die $DBI::errstr;

	$sth->execute or die $DBI::errstr;

	$data .= join ("\t", map ({tr/A-Z/a-z/;$_;} @{$sth->{NAME}}))."\n";
	$data .= "-" x ($sth->{NUM_OF_FIELDS}*8)."\n";

	my @ar;
	my $i;
	while ( @ar = $sth->fetchrow_array ) {
		$data .= join ("\t", @ar)."\n";
		++$i;
	}
	
	$data .= "\n";
	$sth->finish;

	return $data;
}

sub foo {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	return 1;
}


sub insert_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	return $self->insert_update_check (
		data => {
			id		=> undef,
			nr1		=> 42,
			nr2		=> 43,
			str_short	=> "utf8 stuff: äüöÄÜÖß \x{263a}", # utf8 flag
			str_short2	=> "utf8 stuff: äüöÄÜÖß",	   # kein utf8 flag
			datum           => "2002052212:13:14",
		},
		what => 'insert',
		utf8 => 1,
	);
}

sub insert_blob_mem_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $blob = "Das sind Binärdaten: ÄÖÜ äöü ß\n" x 10; # kein utf8 flag

	return $self->insert_update_check (
		data => {
			id => undef,
			blob_data => \$blob,
			str_short => 'Ä1',
		},
		what => 'insert',
	);
}

sub insert_clob_mem_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $clob = "Das ist ein Text mit Umläuten: ÄÖÜ äöü ß\n" x 10; # kein utf8 flag

	return $self->insert_update_check (
		data => {
			id => undef,
			clob_data => \$clob,
			str_short => 'Ä2',
		},
		what => 'insert',
	);
}

sub insert_blob_file_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $blob = "Das sind Binärdaten: ÄÖÜ äöü ß\n" x 10; # kein utf8 flag

	my $file = $self->mem_to_file ( mem => \$blob, utf8 => 0 );

	my $rc = $self->insert_update_check (
		data => {
			id        => undef,
			blob_data => $file,
			str_short => 'Ä3',
		},
		what => 'insert',
	);
	
	unlink $file;
	
	return $rc;
}

sub insert_clob_file_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $clob = "Das ist ein Text mit Umläuten: ÄÖÜ äöü ß\n" x 10; # kein utf8 flag

	my $file = $self->mem_to_file ( mem => \$clob, utf8 => 1 );

	my $rc = $self->insert_update_check (
		data => {
			id => undef,
			clob_data => $file,
			str_short => 'Ä4',
		},
		what => 'insert',
	);
	
	unlink $file;
	
	return $rc;
}

sub insert_clob_fh_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $clob = "Das ist ein Text mit Umläuten: ÄÖÜ äöü ß\n" x 10; # kein utf8 flag

	my $file = $self->mem_to_file ( mem => \$clob, utf8 => 1 );

	my $fh = FileHandle->new;
	open($fh, $file) or die "can't read $file";

	my $rc = $self->insert_update_check (
		data => {
			id => undef,
			clob_data => $fh,
			str_short => 'Ä4',
		},
		what => 'insert',
	);

	close $fh;
	unlink $file;
	
	return $rc;
}

sub update_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	return $self->insert_update_check (
		data => {
			nr1		=> 44,
			nr2		=> 45,
			str_short	=> "utf8 stuff: äüöÄÜÖß \x{263a}", # mit utf8-flag
			str_short2	=> "utf8 stuff: äüöÄÜÖß",	   # ohne utf8-flag
		},
		what   => 'update',
		where  => "str_short = ?",
		params => [ "utf8 stuff: äüöÄÜÖß \x{263a}" ],
		
	);
}

sub update_blob_mem_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $blob = "Das sind neue Binärdaten: ÄÖÜ äöü ß\n" x 3; # kein utf8 flag

	my $rc = $self->insert_update_check (
		data => {
			blob_data => \$blob,
		},
		what   => 'update',
		where  => "str_short = ?",
		params => [ "Ä1" ],
	);
	
	return $rc;
}

sub update_clob_mem_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	# mit utf8-flag
	my $clob = "Das ist ein ßßß anderer Text mit Umläuten: \x{263a} ÄÖÜ äöü ß\n" x 10;

	return $self->insert_update_check (
		data => {
			clob_data => \$clob,
		},
		what   => 'update',
		where  => "str_short = ?",
		params => [ "Ä2" ],
	);
}

sub update_blob_file_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $blob = "Das sind neue Binärdaten: ÄÖÜ äöü ß\n" x 3; # kein utf8 flag

	my $file = $self->mem_to_file ( mem => \$blob, utf8 => 0 );

	my $rc = $self->insert_update_check (
		data => {
			blob_data => $file,
		},
		what   => 'update',
		where  => "str_short = ?",
		params => [ "Ä3" ],
	);
	
	unlink $file;
	
	return $rc;
}

sub update_clob_file_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	# mit utf8-flag
	my $clob = "Das ist ein ßßß anderer Text mit Umläuten: \x{263a} ÄÖÜ äöü ß\n" x 10;

	my $file = $self->mem_to_file ( mem => \$clob, utf8 => 1 );

	my $rc = $self->insert_update_check (
		data => {
			clob_data => $file,
		},
		what   => 'update',
		where  => "str_short = ?",
		params => [ "Ä4" ],
	);
	
	unlink $file;
	
	return $rc;
}

sub get_utf8_array {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $str_short   = "utf8 stuff: äüöÄÜÖß \x{263a}";
	my $str_short2	= "utf8 stuff: äüöÄÜÖß";

	my @array = $sqlh->get (
		sql    => "select str_short, str_short2
			   from   dsql_test
			   where  str_short = ? and str_short2 = ?",
		params => [ $str_short, $str_short2 ],
	);

	return $array[0] eq $str_short and $array[1] eq $str_short2;
}

sub get_utf8_hash {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $str_short   = "utf8 stuff: äüöÄÜÖß \x{263a}";
	my $str_short2	= "utf8 stuff: äüöÄÜÖß";

	my $href = $sqlh->get (
		sql    => "select str_short, str_short2
			   from   dsql_test
			   where  str_short = ? and str_short2 = ?",
		params => [ $str_short, $str_short2 ],
	);

	return $href->{str_short} eq $str_short and $href->{str_short2} eq $str_short2;
	return 1;
}

sub cmpi_utf8 {
	my $self = shift;
	my $sqlh = $self->{sqlh};
	$self->msg;

	my $id = $sqlh->insert (
		table => "dsql_test",
		data => {
			id => undef,
			test_case => "cmpi_utf8",
			str_short => "RIDEL RÖDEL RADEL",
		}
	);
	
	my $cond = $sqlh->cmpi (
		col => "str_short",
		val => "%rödel%",
		op  => "like",
	);
	
# { use bytes; use locale; print STDERR "\ncond=$cond\n", lc("cond=$cond\n") }

	my ($read_id) = $sqlh->get (
		sql => "select id
			from   dsql_test
			where  $cond",
	);

	return $read_id == $id;
}


1;

__END__
id	foo	id	foo
--------------------------------
0	AA		
1	BB		
2	CC	2	AA
3	DD	3	BB
4	EE	4	CC
5	FF	5	DD
6	GG	6	EE
7	HH	7	FF
8	II	8	GG
9	JJ	9	HH
10	KK	10	II
11	LL	11	JJ
12	MM		
13	NN		

id	foo	id	foo	id	foo
------------------------------------------------
0	AA			4	AA
1	BB			5	BB
2	CC	2	AA	6	CC
3	DD	3	BB	7	DD
4	EE	4	CC	8	EE
5	FF	5	DD	9	FF
6	GG	6	EE		
7	HH	7	FF		
8	II	8	GG		
9	JJ	9	HH		
10	KK	10	II		
11	LL	11	JJ		
12	MM				
13	NN				

id	foo	id	foo	id	foo
------------------------------------------------
0	AA				
1	BB				
2	CC				
3	DD			7	DD
4	EE				
5	FF				
6	GG	6	EE		
7	HH				
8	II				
9	JJ				
10	KK				
11	LL				
12	MM				
13	NN				

nested
id	foo	id	foo	id	foo
------------------------------------------------
0	AA				
1	BB				
2	CC	2	AA	4	AA
3	DD	3	BB	5	BB
4	EE	4	CC	6	CC
5	FF	5	DD	7	DD
6	GG	6	EE	8	EE
7	HH	7	FF	9	FF
8	II	8	GG		
9	JJ	9	HH		
10	KK	10	II		
11	LL	11	JJ		
12	MM				
13	NN				

id	foo	id	foo	id	foo	bar	id	bar
------------------------------------------------------------------------
0	AA							
1	BB							
2	CC	2	AA	4	AA	LL		
3	DD	3	BB	5	BB	KK		
4	EE	4	CC	6	CC	JJ	6	JJ
5	FF	5	DD	7	DD	II	7	II
6	GG	6	EE	8	EE	HH		
7	HH	7	FF	9	FF	GG		
8	II	8	GG					
9	JJ	9	HH					
10	KK	10	II					
11	LL	11	JJ					
12	MM							
13	NN							

id	foo	id	foo	id	foo	bar	id	bar
------------------------------------------------------------------------
0	AA							
1	BB							
2	CC							
3	DD							
4	EE							
5	FF							
6	GG							
7	HH							
8	II							
9	JJ							
10	KK	10	II					
11	LL							
12	MM							
13	NN							

