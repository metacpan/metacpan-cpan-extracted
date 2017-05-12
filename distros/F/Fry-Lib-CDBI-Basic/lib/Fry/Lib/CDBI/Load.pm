package Fry::Lib::CDBI::Load;
	use strict qw/subs vars/;
	our @ISA;
	#local data
	my %db_driver = (qw/mysql dbi:mysql: postgres dbi:Pg:dbname= sqlite
		dbi:SQLite:dbname=/);
	our $cdbi_class = "Class::DBI";
	our $regex_operator;
#methods
	sub _default_data {
		return {
			vars=>{
				qw/user bozo
				pwd bozo
				db postgres
				dbname useful/,
				table=>'junk',
				columns=>'',
				action_columns=>'',
				set_db_opts=>{AutoCommit=>1},
				db_default=>{
					postgres=>{
						regex=>'~',
					},	
					mysql=>{
						regex=>'REGEXP',
					},
					sqlite=>{
					},

				},
				table_class=>'My::CDBI',
				#flags
				CDBI_Loader=>1,
				get_columns=>1,
			},
			opts=>{
				table=>{qw/a t type var noreset 1 default junk/,
					action=>sub {shift->Var('cmd_class')->newTable($_[0])} },
				action_columns=>{qw/a C type var noreset 1/,
					action=> sub {$_[0]->setVar(action_columns=>[$_[0]->sub->parseNum($_[1],@{$_[0]->Var('columns')})])}
				}
			},
			class=>'Class::DBI',
		}	
	}
	sub _initLib {
		my $cls = shift;
		no strict 'refs';

		#should be done by tags=class attribute
		my $table_class = $cls->Var('table_class');
		$cls->sub->_require ($cdbi_class);
		push (@{"$table_class\::ISA"},$cdbi_class);

		$regex_operator = $cls->_regex_operator;

		$cls->setupCdbi;
	}

#Setup subs
	sub setupCdbi {
		my $cls = shift;
		
		my $table_class = $cls->Var('table_class');
		my ($dbname,$db,$user,$pwd,$set_db_opts) = $cls->varMany(qw/dbname db user pwd set_db_opts/);
		warn("Database $db doesn't have a dsn entry and thus set_db was not set up correctly")
			if (! exists $db_driver{$db});

		eval "use Class::DBI::Loader ";
		if ($Class::DBI::Loader::VERSION < 0.07) {
			$cls->view("Need at least version 0.07 for Class::DBI::Loader");
			$cls->setFlag('CDBI_Loader'=>0);

		}
		if ($@ or ! $cls->Flag('CDBI_Loader')) {

			$table_class->set_db('Main',$db_driver{$db}.$dbname,$user,$pwd,$set_db_opts);
		       	$cls->newCdbiTable; 
		}
		else { $cls->initCdbiLoader }
	}
	sub newTable {
		my ($cls,$table) = @_;
		eval "require Class::DBI::Loader";
		if ($@ or ! $cls->Flag('CDBI_Loader')) {
			$cls->setVar(table=>$table);
		       	$cls->newCdbiTable; 
		}
		else { $cls->initCdbiLoader(table=>$table) }
	}
	sub newCdbiTable {
		#new table info coming from var
		my $cls = shift;
		my $table_class = $cls->Var('table_class');
		$table_class->table($cls->Var('table'));

		#td: only works for 3 databases
		$cls->init_columns;

		$table_class->columns(All => @{$cls->Var('columns')});

		#td: set sequences for any db
		$table_class->sequence($cls->Var('table').'_'.$cls->Var('columns')->[0].'_seq')
			if ($cls->Var('db') eq "postgres");
	}
	sub initCdbiLoader {
		my ($cls,%arg) = @_;
		my %set = %arg;

		for (qw/pwd user db dbname table set_db_opts/) {
			$arg{$_} = $arg{$_} || $cls->Var($_) 
		}
	
		my $loader = Class::DBI::Loader->new(
			dsn => $db_driver{$arg{db}}.$arg{dbname},
			user => $arg{user},
			password => $arg{pwd},
			options=>$arg{set_db_opts},
			#tables=>[$arg{table}],
			constraint=>"^$arg{table}\$",
			namespace => ucfirst($arg{db}),
		) or die "new CDBIL object failed: $@";

		#if new definition has been successful
		$cls->setVar(%set);

		#subclass latest shell and its fns into $tableclass
		my $table_class = $loader->find_class($arg{table});
		$cls->setVar(table_class=>$table_class);

		#hack: each Class::DBI::* loaded table first has cdbi subclass + then class::db::*
		#as parents
		{ no strict 'refs';
		my $tc = $cls->Var('table_class');
		unshift(@{"$tc\::ISA"},'My::CDBI');
		}

		#hack: don't pass existing columns b/c they're out of order
		$cls->init_columns;  #(columns=>[map {$_->name} $table_class->columns('All')]);
	}
#Internal subs	
	sub _regex_operator {
		$_[0]->Var('db_default')->{$_[0]->Var('db')}->{regex} || "LIKE" 
	}
	sub dbiSource {
		my $cls = shift;
		my ($db,$dbname,$user,$pwd) = $cls->varMany(qw/db dbname user pwd/);
		return ($db_driver{$db}.$dbname,$user,$pwd);
	}
	sub init_columns { 
		#d: initializes column data dependent &columns
		my ($cls,%arg) = @_;
		my $db = $arg{db} || $cls->Var('db');
		my $table = $arg{table} || $cls->Var('table');
		my $table_class = $cls->Var('table_class');

		#set &columns
		if (exists $arg{columns}) {
			$cls->setVar(columns=>$arg{columns})
		}
		#create columns
		elsif ($cls->Flag('get_columns')) {
			my $method = "getcol_$db";
			if ($table_class->can($method)){
				$cls->setVar(columns=>[$table_class->$method($table)]);
			}
			#fall back on defined columns from Class::DBI, whose order isn't dependable :(
			elsif (my @columns = map {$_->name} $table_class->columns('All') > 0) {
				$cls->setVar(columns=>[@columns]);
			}
			else { warn "Columns aren't loaded for this table" }
		}

		#sync &action_columns with &columns
		$cls->setVar(action_columns=>$cls->Var('columns'));
	}

	package My::CDBI;

	sub search_regex { 
		my $cls = shift;
		$cls->_do_search($regex_operator=> @_);
	}
	#subclass of Class::DBI b/c these functions expect it
	#h: the rest of the functions have been copied from their Class::DBI::*
	#all the getcol* does is return the columns of a table in order
	sub getcol_postgres {
		my ($class,$table) = @_;
		my @columns;
		eval {require DBD::Pg};

		my $catalog = ($class->pg_version >= 7.3) ? "pg_catalog." : "";
		my $sth = $class->db_Main->prepare("SELECT a.attname, a.attnum FROM ${catalog}pg_class c, ${catalog}pg_attribute a
	WHERE c.relname = ?  AND a.attnum > 0 AND a.attrelid = c.oid ORDER BY a.attnum");
		$sth->execute($table);
		my $columns = $sth->fetchall_arrayref;
		$sth->finish;

		foreach my $col(@$columns) {
			# skip dropped column.
			next if $col->[0] =~ /^\.+pg\.dropped\.\d+\.+$/;
			push @columns, $col->[0];
		}
		return @columns;
	}
	sub getcol_sqlite {
		my ($class,$table) = @_;
		my $sth = $class->db_Main->prepare("PRAGMA table_info(?)");
		$sth->execute($table);
		my @columns;
		while (my $row = $sth->fetchrow_hashref) {
			push @columns,$row->{name};
	    }
	    $sth->finish;
		return @columns;
	}
	sub getcol_mysql {
		#d:get columns of tb
		#t:mysql
		my $class = shift;
		my (@columns, @pri);

		$class->set_sql(desc_table => 'DESCRIBE __TABLE__');
		(my $sth = $class->sql_desc_table)->execute;

		while (my $hash = $sth->fetch_hash) {
			my ($col) = $hash->{field} =~ /(\w+)/;
			push @columns, $col;
			push @pri, $col if $hash->{key} eq "PRI";
		}
		#$class->_croak("$table has no primary key") unless @pri;
		return @columns
	}
	#used by getcol_postgres
	sub pg_version {
		my $class = shift;
		my $dbh = $class->db_Main;
		my $sth = $dbh->prepare("SELECT version()");
		$sth->execute;
		my($ver_str) = $sth->fetchrow_array;
		$sth->finish;
		my($ver) = $ver_str =~ m/^PostgreSQL ([\d\.]{3})/;
		return $ver;
	}
	1;

__END__	
		#if ($loader eq '') {
			#or database has changed
			#use lib '/home/bozo/bin/perl/';
			#use Fry::CDBIL;
			#$loader = Fry::CDBIL->new(
			#$class->setVar(_loader=>$loader,_table_class=>$class);
			#}	
			#else {	$loader->_load_classes($arg{table}) }	

=head1 NAME

Fry::Lib::CDBI::Load - Sets up a Class::DBI connection and basic variables expected
by any Class::DBI library.

=head1 DESCRIPTION

This module sets up a Class::DBI connection either using Class::DBI::Loader or
with an explicit &set_db call. When the flag CDBI_Loader is set, this class
sets up via Class::DBI::Loader. Both paths have the following in common:

	The class variable $cdbi_class allows you to specify your own subclass.
	My::CDBI subclasses $cdbi_class and is the calling class for Class::DBI methods.
		
Since Class::DBI doesn't currently return columns in their table's order,
the column orders are fetched every time a new table is defined
unless the flag get_columns isn't set. My::CDBI contains the methods for
getting the correct column orders for three databases: postgres,mysql and
sqlite. If you'd like your database to have correct column_orders, send me an
email with the method to do so.

My::CDBI also contains &search_regex which searches with a regex operator
(only for mysql and postgresql).

=head1 PUBLIC METHODS

	setupCdbi(): Decides to setup Class::DBI through Class::DBI::Loader or normally
	init_columns(%arg): Initializes the variables columns and action_columns
	initCdbiLoader(%arg): Sets up a Class::DBI connection via
		Class::DBI::Loader. The keys to arguments can be pwd, user,db,dbname,
		table and set_db_opts which mean the same as the Library variables.
	newCdbiTable(): Initializes Class::DBI methods for a new connection.
	newTable($table): Called every time a class changes. 

=head1 Library Variables

	user($): database user
	pwd($): database password
	db($): database management system (dbms) ie mysql,postgres,sqlite
	dbname($): database name	
	table($): table name
	columns(\@): column names
	action_columns(\@): columns selected for an action such as printing columns, replacing or updating
	set_db_opts(\%): options passed as hashref to Class::DBI's &set_db
	db_default(\%): defaults specific to dbms
	table_class($): Class::DBI class for current table, is My::CDBI for normal
		connections or an automatic name generated from Class::DBI::Loader

=head1 OPTIONS

=head2 Setting Columns with Option C

This option quickly specifes which columns to view by column numbers.
Columns are numbered in their order in a table. To view a numbered list of the
current table's columns type 'print_columns'. For a table with
columns (id,name,author,book,year): 

	-c=1-3  : specifies columns id,name,author
	-c=1,4  : specifies columns id,book  
	-c=1-2,5 : specifies columns id,name,year

=head2 Setting Table with Option t

Since a Class::DBI class maps to one table, Class::DBI methods and most
commands act on that table. To change the implicit table used by most
commands use the option t.

	`-t=animals s type=hairy smells=decent`

=head1	TO DO

An easier and more universal DBI or SQL way of obtaining a table's columns.

=head1 AUTHOR

Me. Gabriel that is. If you want to bug me with a bug: cldwalker@chwhat.com
If you like using perl,linux,vim and databases to make your life easier (not lazier ;) check out my website
at www.chwhat.com.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.
