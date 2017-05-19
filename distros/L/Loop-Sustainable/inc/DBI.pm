#line 1
# $Id: DBI.pm 14568 2010-12-14 15:23:58Z mjevans $
# vim: ts=8:sw=4:et
#
# Copyright (c) 1994-2010  Tim Bunce  Ireland
#
# See COPYRIGHT section in pod text below for usage and distribution rights.
#

require 5.008_001;

BEGIN {
$DBI::VERSION = "1.616"; # ==> ALSO update the version in the pod text below!
}

#line 152

# The POD text continues at the end of the file.


package DBI;

use Carp();
use DynaLoader ();
use Exporter ();

BEGIN {
@ISA = qw(Exporter DynaLoader);

# Make some utility functions available if asked for
@EXPORT    = ();		    # we export nothing by default
@EXPORT_OK = qw(%DBI %DBI_methods hash); # also populated by export_ok_tags:
%EXPORT_TAGS = (
   sql_types => [ qw(
	SQL_GUID
	SQL_WLONGVARCHAR
	SQL_WVARCHAR
	SQL_WCHAR
	SQL_BIGINT
	SQL_BIT
	SQL_TINYINT
	SQL_LONGVARBINARY
	SQL_VARBINARY
	SQL_BINARY
	SQL_LONGVARCHAR
	SQL_UNKNOWN_TYPE
	SQL_ALL_TYPES
	SQL_CHAR
	SQL_NUMERIC
	SQL_DECIMAL
	SQL_INTEGER
	SQL_SMALLINT
	SQL_FLOAT
	SQL_REAL
	SQL_DOUBLE
	SQL_DATETIME
	SQL_DATE
	SQL_INTERVAL
	SQL_TIME
	SQL_TIMESTAMP
	SQL_VARCHAR
	SQL_BOOLEAN
	SQL_UDT
	SQL_UDT_LOCATOR
	SQL_ROW
	SQL_REF
	SQL_BLOB
	SQL_BLOB_LOCATOR
	SQL_CLOB
	SQL_CLOB_LOCATOR
	SQL_ARRAY
	SQL_ARRAY_LOCATOR
	SQL_MULTISET
	SQL_MULTISET_LOCATOR
	SQL_TYPE_DATE
	SQL_TYPE_TIME
	SQL_TYPE_TIMESTAMP
	SQL_TYPE_TIME_WITH_TIMEZONE
	SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
	SQL_INTERVAL_YEAR
	SQL_INTERVAL_MONTH
	SQL_INTERVAL_DAY
	SQL_INTERVAL_HOUR
	SQL_INTERVAL_MINUTE
	SQL_INTERVAL_SECOND
	SQL_INTERVAL_YEAR_TO_MONTH
	SQL_INTERVAL_DAY_TO_HOUR
	SQL_INTERVAL_DAY_TO_MINUTE
	SQL_INTERVAL_DAY_TO_SECOND
	SQL_INTERVAL_HOUR_TO_MINUTE
	SQL_INTERVAL_HOUR_TO_SECOND
	SQL_INTERVAL_MINUTE_TO_SECOND
	DBIstcf_DISCARD_STRING
	DBIstcf_STRICT
   ) ],
   sql_cursor_types => [ qw(
	 SQL_CURSOR_FORWARD_ONLY
	 SQL_CURSOR_KEYSET_DRIVEN
	 SQL_CURSOR_DYNAMIC
	 SQL_CURSOR_STATIC
	 SQL_CURSOR_TYPE_DEFAULT
   ) ], # for ODBC cursor types
   utils     => [ qw(
	neat neat_list $neat_maxlen dump_results looks_like_number
	data_string_diff data_string_desc data_diff sql_type_cast
   ) ],
   profile   => [ qw(
	dbi_profile dbi_profile_merge dbi_profile_merge_nodes dbi_time
   ) ], # notionally "in" DBI::Profile and normally imported from there
);

$DBI::dbi_debug = 0;
$DBI::neat_maxlen = 1000;
$DBI::stderr = 2_000_000_000; # a very round number below 2**31

# If you get an error here like "Can't find loadable object ..."
# then you haven't installed the DBI correctly. Read the README
# then install it again.
if ( $ENV{DBI_PUREPERL} ) {
    eval { bootstrap DBI } if       $ENV{DBI_PUREPERL} == 1;
    require DBI::PurePerl  if $@ or $ENV{DBI_PUREPERL} >= 2;
    $DBI::PurePerl ||= 0; # just to silence "only used once" warnings
}
else {
    bootstrap DBI;
}

$EXPORT_TAGS{preparse_flags} = [ grep { /^DBIpp_\w\w_/ } keys %{__PACKAGE__."::"} ];

Exporter::export_ok_tags(keys %EXPORT_TAGS);

}

# Alias some handle methods to also be DBI class methods
for (qw(trace_msg set_err parse_trace_flag parse_trace_flags)) {
  no strict;
  *$_ = \&{"DBD::_::common::$_"};
}

use strict;

DBI->trace(split /=/, $ENV{DBI_TRACE}, 2) if $ENV{DBI_TRACE};

$DBI::connect_via ||= "connect";

# check if user wants a persistent database connection ( Apache + mod_perl )
if ($INC{'Apache/DBI.pm'} && $ENV{MOD_PERL}) {
    $DBI::connect_via = "Apache::DBI::connect";
    DBI->trace_msg("DBI connect via $DBI::connect_via in $INC{'Apache/DBI.pm'}\n");
}

# check for weaken support, used by ChildHandles
my $HAS_WEAKEN = eval {
    require Scalar::Util;
    # this will croak() if this Scalar::Util doesn't have a working weaken().
    Scalar::Util::weaken( \my $test ); # same test as in t/72childhandles.t
    1;
};

%DBI::installed_drh = ();  # maps driver names to installed driver handles
sub installed_drivers { %DBI::installed_drh }
%DBI::installed_methods = (); # XXX undocumented, may change
sub installed_methods { %DBI::installed_methods }

# Setup special DBI dynamic variables. See DBI::var::FETCH for details.
# These are dynamically associated with the last handle used.
tie $DBI::err,    'DBI::var', '*err';    # special case: referenced via IHA list
tie $DBI::state,  'DBI::var', '"state';  # special case: referenced via IHA list
tie $DBI::lasth,  'DBI::var', '!lasth';  # special case: return boolean
tie $DBI::errstr, 'DBI::var', '&errstr'; # call &errstr in last used pkg
tie $DBI::rows,   'DBI::var', '&rows';   # call &rows   in last used pkg
sub DBI::var::TIESCALAR{ my $var = $_[1]; bless \$var, 'DBI::var'; }
sub DBI::var::STORE    { Carp::croak("Can't modify \$DBI::${$_[0]} special variable") }

{   # used to catch DBI->{Attrib} mistake
    sub DBI::DBI_tie::TIEHASH { bless {} }
    sub DBI::DBI_tie::STORE   { Carp::carp("DBI->{$_[1]} is invalid syntax (you probably want \$h->{$_[1]})");}
    *DBI::DBI_tie::FETCH = \&DBI::DBI_tie::STORE;
}
tie %DBI::DBI => 'DBI::DBI_tie';

# --- Driver Specific Prefix Registry ---

my $dbd_prefix_registry = {
  ad_      => { class => 'DBD::AnyData',	},
  ado_     => { class => 'DBD::ADO',		},
  amzn_    => { class => 'DBD::Amazon',		},
  best_    => { class => 'DBD::BestWins',	},
  csv_     => { class => 'DBD::CSV',		},
  db2_     => { class => 'DBD::DB2',		},
  dbi_     => { class => 'DBI',			},
  dbm_     => { class => 'DBD::DBM',		},
  df_      => { class => 'DBD::DF',		},
  f_       => { class => 'DBD::File',		},
  file_    => { class => 'DBD::TextFile',	},
  go_      => { class => 'DBD::Gofer',  	},
  ib_      => { class => 'DBD::InterBase',	},
  ing_     => { class => 'DBD::Ingres',		},
  ix_      => { class => 'DBD::Informix',	},
  jdbc_    => { class => 'DBD::JDBC',		},
  monetdb_ => { class => 'DBD::monetdb',	},
  msql_    => { class => 'DBD::mSQL',		},
  mvsftp_  => { class => 'DBD::MVS_FTPSQL',	},
  mysql_   => { class => 'DBD::mysql',		},
  mx_      => { class => 'DBD::Multiplex',	},
  nullp_   => { class => 'DBD::NullP',		},
  odbc_    => { class => 'DBD::ODBC',		},
  ora_     => { class => 'DBD::Oracle',		},
  pg_      => { class => 'DBD::Pg',		},
  pgpp_    => { class => 'DBD::PgPP',		},
  plb_     => { class => 'DBD::Plibdata',	},
  po_      => { class => 'DBD::PO',		},
  proxy_   => { class => 'DBD::Proxy',		},
  ram_     => { class => 'DBD::RAM',		},
  rdb_     => { class => 'DBD::RDB',		},
  sapdb_   => { class => 'DBD::SAP_DB',		},
  solid_   => { class => 'DBD::Solid',		},
  sponge_  => { class => 'DBD::Sponge',		},
  sql_     => { class => 'DBI::DBD::SqlEngine',	},
  sqlite_  => { class => 'DBD::SQLite',  	},
  syb_     => { class => 'DBD::Sybase',		},
  sys_     => { class => 'DBD::Sys',		},
  tdat_    => { class => 'DBD::Teradata',	},
  tmpl_    => { class => 'DBD::Template',	},
  tmplss_  => { class => 'DBD::TemplateSS',	},
  tuber_   => { class => 'DBD::Tuber',		},
  uni_     => { class => 'DBD::Unify',		},
  vt_      => { class => 'DBD::Vt',		},
  wmi_     => { class => 'DBD::WMI',		},
  x_       => { }, # for private use
  xbase_   => { class => 'DBD::XBase',		},
  xl_      => { class => 'DBD::Excel',		},
  yaswi_   => { class => 'DBD::Yaswi',		},
};

my %dbd_class_registry = map { $dbd_prefix_registry->{$_}->{class} => { prefix => $_ } }
			     grep { exists $dbd_prefix_registry->{$_}->{class} }
			     keys %{$dbd_prefix_registry};

sub dump_dbd_registry {
    require Data::Dumper;
    local $Data::Dumper::Sortkeys=1;
    local $Data::Dumper::Indent=1;
    print Data::Dumper->Dump([$dbd_prefix_registry], [qw($dbd_prefix_registry)]);
}

# --- Dynamically create the DBI Standard Interface

my $keeperr = { O=>0x0004 };

%DBI::DBI_methods = ( # Define the DBI interface methods per class:

    common => {		# Interface methods common to all DBI handle classes
	'DESTROY'	=> { O=>0x004|0x10000 },
	'CLEAR'  	=> $keeperr,
	'EXISTS' 	=> $keeperr,
	'FETCH'		=> { O=>0x0404 },
	'FETCH_many'	=> { O=>0x0404 },
	'FIRSTKEY'	=> $keeperr,
	'NEXTKEY'	=> $keeperr,
	'STORE'		=> { O=>0x0418 | 0x4 },
	_not_impl	=> undef,
	can		=> { O=>0x0100 }, # special case, see dispatch
	debug 	 	=> { U =>[1,2,'[$debug_level]'],	O=>0x0004 }, # old name for trace
	dump_handle 	=> { U =>[1,3,'[$message [, $level]]'],	O=>0x0004 },
	err		=> $keeperr,
	errstr		=> $keeperr,
	state		=> $keeperr,
	func	   	=> { O=>0x0006	},
	parse_trace_flag   => { U =>[2,2,'$name'],	O=>0x0404, T=>8 },
	parse_trace_flags  => { U =>[2,2,'$flags'],	O=>0x0404, T=>8 },
	private_data	=> { U =>[1,1],			O=>0x0004 },
	set_err		=> { U =>[3,6,'$err, $errmsg [, $state, $method, $rv]'], O=>0x0010 },
	trace		=> { U =>[1,3,'[$trace_level, [$filename]]'],	O=>0x0004 },
	trace_msg	=> { U =>[2,3,'$message_text [, $min_level ]' ],	O=>0x0004, T=>8 },
	swap_inner_handle => { U =>[2,3,'$h [, $allow_reparent ]'] },
        private_attribute_info => { },
        visit_child_handles => { U => [2,3,'$coderef [, $info ]'], O=>0x0404, T=>4 },
    },
    dr => {		# Database Driver Interface
	'connect'  =>	{ U =>[1,5,'[$db [,$user [,$passwd [,\%attr]]]]'], H=>3, O=>0x8000 },
	'connect_cached'=>{U=>[1,5,'[$db [,$user [,$passwd [,\%attr]]]]'], H=>3, O=>0x8000 },
	'disconnect_all'=>{ U =>[1,1], O=>0x0800 },
	data_sources => { U =>[1,2,'[\%attr]' ], O=>0x0800 },
	default_user => { U =>[3,4,'$user, $pass [, \%attr]' ] },
	dbixs_revision  => $keeperr,
    },
    db => {		# Database Session Class Interface
	data_sources	=> { U =>[1,2,'[\%attr]' ], O=>0x0200 },
	take_imp_data	=> { U =>[1,1], O=>0x10000 },
	clone   	=> { U =>[1,2,'[\%attr]'] },
	connected   	=> { U =>[1,0], O => 0x0004 },
	begin_work   	=> { U =>[1,2,'[ \%attr ]'], O=>0x0400 },
	commit     	=> { U =>[1,1], O=>0x0480|0x0800 },
	rollback   	=> { U =>[1,1], O=>0x0480|0x0800 },
	'do'       	=> { U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x3200 },
	last_insert_id	=> { U =>[5,6,'$catalog, $schema, $table_name, $field_name [, \%attr ]'], O=>0x2800 },
	preparse    	=> {  }, # XXX
	prepare    	=> { U =>[2,3,'$statement [, \%attr]'],                    O=>0xA200 },
	prepare_cached	=> { U =>[2,4,'$statement [, \%attr [, $if_active ] ]'],   O=>0xA200 },
	selectrow_array	=> { U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectrow_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectrow_hashref=>{ U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectall_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectall_hashref=>{ U =>[3,0,'$statement, $keyfield [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	selectcol_arrayref=>{U =>[2,0,'$statement [, \%attr [, @bind_params ] ]'], O=>0x2000 },
	ping       	=> { U =>[1,1], O=>0x0404 },
	disconnect 	=> { U =>[1,1], O=>0x0400|0x0800|0x10000 },
	quote      	=> { U =>[2,3, '$string [, $data_type ]' ], O=>0x0430 },
	quote_identifier=> { U =>[2,6, '$name [, ...] [, \%attr ]' ],    O=>0x0430 },
	rows       	=> $keeperr,

	tables          => { U =>[1,6,'$catalog, $schema, $table, $type [, \%attr ]' ], O=>0x2200 },
	table_info      => { U =>[1,6,'$catalog, $schema, $table, $type [, \%attr ]' ],	O=>0x2200|0x8800 },
	column_info     => { U =>[5,6,'$catalog, $schema, $table, $column [, \%attr ]'],O=>0x2200|0x8800 },
	primary_key_info=> { U =>[4,5,'$catalog, $schema, $table [, \%attr ]' ],	O=>0x2200|0x8800 },
	primary_key     => { U =>[4,5,'$catalog, $schema, $table [, \%attr ]' ],	O=>0x2200 },
	foreign_key_info=> { U =>[7,8,'$pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table [, \%attr ]' ], O=>0x2200|0x8800 },
	statistics_info => { U =>[6,7,'$catalog, $schema, $table, $unique_only, $quick, [, \%attr ]' ], O=>0x2200|0x8800 },
	type_info_all	=> { U =>[1,1], O=>0x2200|0x0800 },
	type_info	=> { U =>[1,2,'$data_type'], O=>0x2200 },
	get_info	=> { U =>[2,2,'$info_type'], O=>0x2200|0x0800 },
    },
    st => {		# Statement Class Interface
	bind_col	=> { U =>[3,4,'$column, \\$var [, \%attr]'] },
	bind_columns	=> { U =>[2,0,'\\$var1 [, \\$var2, ...]'] },
	bind_param	=> { U =>[3,4,'$parameter, $var [, \%attr]'] },
	bind_param_inout=> { U =>[4,5,'$parameter, \\$var, $maxlen, [, \%attr]'] },
	execute		=> { U =>[1,0,'[@args]'], O=>0x1040 },

	bind_param_array  => { U =>[3,4,'$parameter, $var [, \%attr]'] },
	bind_param_inout_array => { U =>[4,5,'$parameter, \\@var, $maxlen, [, \%attr]'] },
	execute_array     => { U =>[2,0,'\\%attribs [, @args]'],         O=>0x1040|0x4000 },
	execute_for_fetch => { U =>[2,3,'$fetch_sub [, $tuple_status]'], O=>0x1040|0x4000 },

	fetch    	  => undef, # alias for fetchrow_arrayref
	fetchrow_arrayref => undef,
	fetchrow_hashref  => undef,
	fetchrow_array    => undef,
	fetchrow   	  => undef, # old alias for fetchrow_array

	fetchall_arrayref => { U =>[1,3, '[ $slice [, $max_rows]]'] },
	fetchall_hashref  => { U =>[2,2,'$key_field'] },

	blob_read  =>	{ U =>[4,5,'$field, $offset, $len [, \\$buf [, $bufoffset]]'] },
	blob_copy_to_file => { U =>[3,3,'$field, $filename_or_handleref'] },
	dump_results => { U =>[1,5,'$maxfieldlen, $linesep, $fieldsep, $filehandle'] },
	more_results => { U =>[1,1] },
	finish     => 	{ U =>[1,1] },
	cancel     => 	{ U =>[1,1], O=>0x0800 },
	rows       =>	$keeperr,

	_get_fbav	=> undef,
	_set_fbav	=> { T=>6 },
    },
);

while ( my ($class, $meths) = each %DBI::DBI_methods ) {
    my $ima_trace = 0+($ENV{DBI_IMA_TRACE}||0);
    while ( my ($method, $info) = each %$meths ) {
	my $fullmeth = "DBI::${class}::$method";
	if ($DBI::dbi_debug >= 15) { # quick hack to list DBI methods
	    # and optionally filter by IMA flags
	    my $O = $info->{O}||0;
	    printf "0x%04x %-20s\n", $O, $fullmeth
	        unless $ima_trace && !($O & $ima_trace);
	}
	DBI->_install_method($fullmeth, 'DBI.pm', $info);
    }
}

{
    package DBI::common;
    @DBI::dr::ISA = ('DBI::common');
    @DBI::db::ISA = ('DBI::common');
    @DBI::st::ISA = ('DBI::common');
}

# End of init code


END {
    return unless defined &DBI::trace_msg; # return unless bootstrap'd ok
    local ($!,$?);
    DBI->trace_msg(sprintf("    -- DBI::END (\$\@: %s, \$!: %s)\n", $@||'', $!||''), 2);
    # Let drivers know why we are calling disconnect_all:
    $DBI::PERL_ENDING = $DBI::PERL_ENDING = 1;	# avoid typo warning
    DBI->disconnect_all() if %DBI::installed_drh;
}


sub CLONE {
    my $olddbis = $DBI::_dbistate;
    _clone_dbis() unless $DBI::PurePerl; # clone the DBIS structure
    DBI->trace_msg(sprintf "CLONE DBI for new thread %s\n",
	$DBI::PurePerl ? "" : sprintf("(dbis %x -> %x)",$olddbis, $DBI::_dbistate));
    while ( my ($driver, $drh) = each %DBI::installed_drh) {
	no strict 'refs';
	next if defined &{"DBD::${driver}::CLONE"};
	warn("$driver has no driver CLONE() function so is unsafe threaded\n");
    }
    %DBI::installed_drh = ();	# clear loaded drivers so they have a chance to reinitialize
}

sub parse_dsn {
    my ($class, $dsn) = @_;
    $dsn =~ s/^(dbi):(\w*?)(?:\((.*?)\))?://i or return;
    my ($scheme, $driver, $attr, $attr_hash) = (lc($1), $2, $3);
    $driver ||= $ENV{DBI_DRIVER} || '';
    $attr_hash = { split /\s*=>?\s*|\s*,\s*/, $attr, -1 } if $attr;
    return ($scheme, $driver, $attr, $attr_hash, $dsn);
}

sub visit_handles {
    my ($class, $code, $outer_info) = @_;
    $outer_info = {} if not defined $outer_info;
    my %drh = DBI->installed_drivers;
    for my $h (values %drh) {
	my $child_info = $code->($h, $outer_info)
	    or next;
	$h->visit_child_handles($code, $child_info);
    }
    return $outer_info;
}


# --- The DBI->connect Front Door methods

sub connect_cached {
    # For library code using connect_cached() with mod_perl
    # we redirect those calls to Apache::DBI::connect() as well
    my ($class, $dsn, $user, $pass, $attr) = @_;
    my $dbi_connect_method = ($DBI::connect_via eq "Apache::DBI::connect")
	    ? 'Apache::DBI::connect' : 'connect_cached';
    $attr = {
        $attr ? %$attr : (), # clone, don't modify callers data
        dbi_connect_method => $dbi_connect_method,
    };
    return $class->connect($dsn, $user, $pass, $attr);
}

sub connect {
    my $class = shift;
    my ($dsn, $user, $pass, $attr, $old_driver) = my @orig_args = @_;
    my $driver;

    if ($attr and !ref($attr)) { # switch $old_driver<->$attr if called in old style
	Carp::carp("DBI->connect using 'old-style' syntax is deprecated and will be an error in future versions");
        ($old_driver, $attr) = ($attr, $old_driver);
    }

    my $connect_meth = $attr->{dbi_connect_method};
    $connect_meth ||= $DBI::connect_via;	# fallback to default

    $dsn ||= $ENV{DBI_DSN} || $ENV{DBI_DBNAME} || '' unless $old_driver;

    if ($DBI::dbi_debug) {
	local $^W = 0;
	pop @_ if $connect_meth ne 'connect';
	my @args = @_; $args[2] = '****'; # hide password
	DBI->trace_msg("    -> $class->$connect_meth(".join(", ",@args).")\n");
    }
    Carp::croak('Usage: $class->connect([$dsn [,$user [,$passwd [,\%attr]]]])')
	if (ref $old_driver or ($attr and not ref $attr) or ref $pass);

    # extract dbi:driver prefix from $dsn into $1
    $dsn =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i
			or '' =~ /()/; # ensure $1 etc are empty if match fails
    my $driver_attrib_spec = $2 || '';

    # Set $driver. Old style driver, if specified, overrides new dsn style.
    $driver = $old_driver || $1 || $ENV{DBI_DRIVER}
	or Carp::croak("Can't connect to data source '$dsn' "
            ."because I can't work out what driver to use "
            ."(it doesn't seem to contain a 'dbi:driver:' prefix "
            ."and the DBI_DRIVER env var is not set)");

    my $proxy;
    if ($ENV{DBI_AUTOPROXY} && $driver ne 'Proxy' && $driver ne 'Sponge' && $driver ne 'Switch') {
	my $dbi_autoproxy = $ENV{DBI_AUTOPROXY};
	$proxy = 'Proxy';
	if ($dbi_autoproxy =~ s/^dbi:(\w*?)(?:\((.*?)\))?://i) {
	    $proxy = $1;
	    $driver_attrib_spec = join ",",
                ($driver_attrib_spec) ? $driver_attrib_spec : (),
                ($2                 ) ? $2                  : ();
	}
	$dsn = "$dbi_autoproxy;dsn=dbi:$driver:$dsn";
	$driver = $proxy;
	DBI->trace_msg("       DBI_AUTOPROXY: dbi:$driver($driver_attrib_spec):$dsn\n");
    }
    # avoid recursion if proxy calls DBI->connect itself
    local $ENV{DBI_AUTOPROXY} if $ENV{DBI_AUTOPROXY};

    my %attributes;	# take a copy we can delete from
    if ($old_driver) {
	%attributes = %$attr if $attr;
    }
    else {		# new-style connect so new default semantics
	%attributes = (
	    PrintError => 1,
	    AutoCommit => 1,
	    ref $attr           ? %$attr : (),
	    # attributes in DSN take precedence over \%attr connect parameter
	    $driver_attrib_spec ? (split /\s*=>?\s*|\s*,\s*/, $driver_attrib_spec, -1) : (),
	);
    }
    $attr = \%attributes; # now set $attr to refer to our local copy

    my $drh = $DBI::installed_drh{$driver} || $class->install_driver($driver)
	or die "panic: $class->install_driver($driver) failed";

    # attributes in DSN take precedence over \%attr connect parameter
    $user = $attr->{Username} if defined $attr->{Username};
    $pass = $attr->{Password} if defined $attr->{Password};
    delete $attr->{Password}; # always delete Password as closure stores it securely
    if ( !(defined $user && defined $pass) ) {
        ($user, $pass) = $drh->default_user($user, $pass, $attr);
    }
    $attr->{Username} = $user; # force the Username to be the actual one used

    my $connect_closure = sub {
	my ($old_dbh, $override_attr) = @_;

        #use Data::Dumper;
        #warn "connect_closure: ".Data::Dumper::Dumper([$attr,\%attributes, $override_attr]);

	my $dbh;
	unless ($dbh = $drh->$connect_meth($dsn, $user, $pass, $attr)) {
	    $user = '' if !defined $user;
	    $dsn = '' if !defined $dsn;
	    # $drh->errstr isn't safe here because $dbh->DESTROY may not have
	    # been called yet and so the dbh errstr would not have been copied
	    # up to the drh errstr. Certainly true for connect_cached!
	    my $errstr = $DBI::errstr;
            # Getting '(no error string)' here is a symptom of a ref loop
	    $errstr = '(no error string)' if !defined $errstr;
	    my $msg = "$class connect('$dsn','$user',...) failed: $errstr";
	    DBI->trace_msg("       $msg\n");
	    # XXX HandleWarn
	    unless ($attr->{HandleError} && $attr->{HandleError}->($msg, $drh, $dbh)) {
		Carp::croak($msg) if $attr->{RaiseError};
		Carp::carp ($msg) if $attr->{PrintError};
	    }
	    $! = 0; # for the daft people who do DBI->connect(...) || die "$!";
	    return $dbh; # normally undef, but HandleError could change it
	}

        # merge any attribute overrides but don't change $attr itself (for closure)
        my $apply = { ($override_attr) ? (%$attr, %$override_attr ) : %$attr };

        # handle basic RootClass subclassing:
        my $rebless_class = $apply->{RootClass} || ($class ne 'DBI' ? $class : '');
        if ($rebless_class) {
            no strict 'refs';
            if ($apply->{RootClass}) { # explicit attribute (ie not static methd call class)
                delete $apply->{RootClass};
                DBI::_load_class($rebless_class, 0);
            }
            unless (@{"$rebless_class\::db::ISA"} && @{"$rebless_class\::st::ISA"}) {
                Carp::carp("DBI subclasses '$rebless_class\::db' and ::st are not setup, RootClass ignored");
                $rebless_class = undef;
                $class = 'DBI';
            }
            else {
                $dbh->{RootClass} = $rebless_class; # $dbh->STORE called via plain DBI::db
                DBI::_set_isa([$rebless_class], 'DBI');     # sets up both '::db' and '::st'
                DBI::_rebless($dbh, $rebless_class);        # appends '::db'
            }
        }

	if (%$apply) {

            if ($apply->{DbTypeSubclass}) {
                my $DbTypeSubclass = delete $apply->{DbTypeSubclass};
                DBI::_rebless_dbtype_subclass($dbh, $rebless_class||$class, $DbTypeSubclass);
            }
	    my $a;
	    foreach $a (qw(Profile RaiseError PrintError AutoCommit)) { # do these first
		next unless  exists $apply->{$a};
		$dbh->{$a} = delete $apply->{$a};
	    }
	    while ( my ($a, $v) = each %$apply) {
		eval { $dbh->{$a} = $v }; # assign in void context to avoid re-FETCH
                warn $@ if $@;
	    }
	}

        # confirm to driver (ie if subclassed) that we've connected sucessfully
        # and finished the attribute setup. pass in the original arguments
	$dbh->connected(@orig_args); #if ref $dbh ne 'DBI::db' or $proxy;

	DBI->trace_msg("    <- connect= $dbh\n") if $DBI::dbi_debug;

	return $dbh;
    };

    my $dbh = &$connect_closure(undef, undef);

    $dbh->{dbi_connect_closure} = $connect_closure if $dbh;

    return $dbh;
}


sub disconnect_all {
    keys %DBI::installed_drh; # reset iterator
    while ( my ($name, $drh) = each %DBI::installed_drh ) {
	$drh->disconnect_all() if ref $drh;
    }
}


sub disconnect {		# a regular beginners bug
    Carp::croak("DBI->disconnect is not a DBI method (read the DBI manual)");
}


sub install_driver {		# croaks on failure
    my $class = shift;
    my($driver, $attr) = @_;
    my $drh;

    $driver ||= $ENV{DBI_DRIVER} || '';

    # allow driver to be specified as a 'dbi:driver:' string
    $driver = $1 if $driver =~ s/^DBI:(.*?)://i;

    Carp::croak("usage: $class->install_driver(\$driver [, \%attr])")
		unless ($driver and @_<=3);

    # already installed
    return $drh if $drh = $DBI::installed_drh{$driver};

    $class->trace_msg("    -> $class->install_driver($driver"
			.") for $^O perl=$] pid=$$ ruid=$< euid=$>\n")
	if $DBI::dbi_debug;

    # --- load the code
    my $driver_class = "DBD::$driver";
    eval qq{package			# hide from PAUSE
		DBI::_firesafe;		# just in case
	    require $driver_class;	# load the driver
    };
    if ($@) {
	my $err = $@;
	my $advice = "";
	if ($err =~ /Can't find loadable object/) {
	    $advice = "Perhaps DBD::$driver was statically linked into a new perl binary."
		 ."\nIn which case you need to use that new perl binary."
		 ."\nOr perhaps only the .pm file was installed but not the shared object file."
	}
	elsif ($err =~ /Can't locate.*?DBD\/$driver\.pm in \@INC/) {
	    my @drv = $class->available_drivers(1);
	    $advice = "Perhaps the DBD::$driver perl module hasn't been fully installed,\n"
		     ."or perhaps the capitalisation of '$driver' isn't right.\n"
		     ."Available drivers: ".join(", ", @drv).".";
	}
	elsif ($err =~ /Can't load .*? for module DBD::/) {
	    $advice = "Perhaps a required shared library or dll isn't installed where expected";
	}
	elsif ($err =~ /Can't locate .*? in \@INC/) {
	    $advice = "Perhaps a module that DBD::$driver requires hasn't been fully installed";
	}
	Carp::croak("install_driver($driver) failed: $err$advice\n");
    }
    if ($DBI::dbi_debug) {
	no strict 'refs';
	(my $driver_file = $driver_class) =~ s/::/\//g;
	my $dbd_ver = ${"$driver_class\::VERSION"} || "undef";
	$class->trace_msg("       install_driver: $driver_class version $dbd_ver"
		." loaded from $INC{qq($driver_file.pm)}\n");
    }

    # --- do some behind-the-scenes checks and setups on the driver
    $class->setup_driver($driver_class);

    # --- run the driver function
    $drh = eval { $driver_class->driver($attr || {}) };
    unless ($drh && ref $drh && !$@) {
	my $advice = "";
        $@ ||= "$driver_class->driver didn't return a handle";
	# catch people on case in-sensitive systems using the wrong case
	$advice = "\nPerhaps the capitalisation of DBD '$driver' isn't right."
		if $@ =~ /locate object method/;
	Carp::croak("$driver_class initialisation failed: $@$advice");
    }

    $DBI::installed_drh{$driver} = $drh;
    $class->trace_msg("    <- install_driver= $drh\n") if $DBI::dbi_debug;
    $drh;
}

*driver = \&install_driver;	# currently an alias, may change


sub setup_driver {
    my ($class, $driver_class) = @_;
    my $type;
    foreach $type (qw(dr db st)){
	my $class = $driver_class."::$type";
	no strict 'refs';
	push @{"${class}::ISA"},     "DBD::_::$type"
	    unless UNIVERSAL::isa($class, "DBD::_::$type");
	my $mem_class = "DBD::_mem::$type";
	push @{"${class}_mem::ISA"}, $mem_class
	    unless UNIVERSAL::isa("${class}_mem", $mem_class)
	    or $DBI::PurePerl;
    }
}


sub _rebless {
    my $dbh = shift;
    my ($outer, $inner) = DBI::_handles($dbh);
    my $class = shift(@_).'::db';
    bless $inner => $class;
    bless $outer => $class; # outer last for return
}


sub _set_isa {
    my ($classes, $topclass) = @_;
    my $trace = DBI->trace_msg("       _set_isa([@$classes])\n");
    foreach my $suffix ('::db','::st') {
	my $previous = $topclass || 'DBI'; # trees are rooted here
	foreach my $class (@$classes) {
	    my $base_class = $previous.$suffix;
	    my $sub_class  = $class.$suffix;
	    my $sub_class_isa  = "${sub_class}::ISA";
	    no strict 'refs';
	    if (@$sub_class_isa) {
		DBI->trace_msg("       $sub_class_isa skipped (already set to @$sub_class_isa)\n")
		    if $trace;
	    }
	    else {
		@$sub_class_isa = ($base_class) unless @$sub_class_isa;
		DBI->trace_msg("       $sub_class_isa = $base_class\n")
		    if $trace;
	    }
	    $previous = $class;
	}
    }
}


sub _rebless_dbtype_subclass {
    my ($dbh, $rootclass, $DbTypeSubclass) = @_;
    # determine the db type names for class hierarchy
    my @hierarchy = DBI::_dbtype_names($dbh, $DbTypeSubclass);
    # add the rootclass prefix to each ('DBI::' or 'MyDBI::' etc)
    $_ = $rootclass.'::'.$_ foreach (@hierarchy);
    # load the modules from the 'top down'
    DBI::_load_class($_, 1) foreach (reverse @hierarchy);
    # setup class hierarchy if needed, does both '::db' and '::st'
    DBI::_set_isa(\@hierarchy, $rootclass);
    # finally bless the handle into the subclass
    DBI::_rebless($dbh, $hierarchy[0]);
}


sub _dbtype_names { # list dbtypes for hierarchy, ie Informix=>ADO=>ODBC
    my ($dbh, $DbTypeSubclass) = @_;

    if ($DbTypeSubclass && $DbTypeSubclass ne '1' && ref $DbTypeSubclass ne 'CODE') {
	# treat $DbTypeSubclass as a comma separated list of names
	my @dbtypes = split /\s*,\s*/, $DbTypeSubclass;
	$dbh->trace_msg("    DbTypeSubclass($DbTypeSubclass)=@dbtypes (explicit)\n");
	return @dbtypes;
    }

    # XXX will call $dbh->get_info(17) (=SQL_DBMS_NAME) in future?

    my $driver = $dbh->{Driver}->{Name};
    if ( $driver eq 'Proxy' ) {
        # XXX Looking into the internals of DBD::Proxy is questionable!
        ($driver) = $dbh->{proxy_client}->{application} =~ /^DBI:(.+?):/i
		or die "Can't determine driver name from proxy";
    }

    my @dbtypes = (ucfirst($driver));
    if ($driver eq 'ODBC' || $driver eq 'ADO') {
	# XXX will move these out and make extensible later:
	my $_dbtype_name_regexp = 'Oracle'; # eg 'Oracle|Foo|Bar'
	my %_dbtype_name_map = (
	     'Microsoft SQL Server'	=> 'MSSQL',
	     'SQL Server'		=> 'Sybase',
	     'Adaptive Server Anywhere'	=> 'ASAny',
	     'ADABAS D'			=> 'AdabasD',
	);

        my $name;
	$name = $dbh->func(17, 'GetInfo') # SQL_DBMS_NAME
		if $driver eq 'ODBC';
	$name = $dbh->{ado_conn}->Properties->Item('DBMS Name')->Value
		if $driver eq 'ADO';
	die "Can't determine driver name! ($DBI::errstr)\n"
		unless $name;

	my $dbtype;
        if ($_dbtype_name_map{$name}) {
            $dbtype = $_dbtype_name_map{$name};
        }
	else {
	    if ($name =~ /($_dbtype_name_regexp)/) {
		$dbtype = lc($1);
	    }
	    else { # generic mangling for other names:
		$dbtype = lc($name);
	    }
	    $dbtype =~ s/\b(\w)/\U$1/g;
	    $dbtype =~ s/\W+/_/g;
	}
	# add ODBC 'behind' ADO
	push    @dbtypes, 'ODBC' if $driver eq 'ADO';
	# add discovered dbtype in front of ADO/ODBC
	unshift @dbtypes, $dbtype;
    }
    @dbtypes = &$DbTypeSubclass($dbh, \@dbtypes)
	if (ref $DbTypeSubclass eq 'CODE');
    $dbh->trace_msg("    DbTypeSubclass($DbTypeSubclass)=@dbtypes\n");
    return @dbtypes;
}

sub _load_class {
    my ($load_class, $missing_ok) = @_;
    DBI->trace_msg("    _load_class($load_class, $missing_ok)\n", 2);
    no strict 'refs';
    return 1 if @{"$load_class\::ISA"};	# already loaded/exists
    (my $module = $load_class) =~ s!::!/!g;
    DBI->trace_msg("    _load_class require $module\n", 2);
    eval { require "$module.pm"; };
    return 1 unless $@;
    return 0 if $missing_ok && $@ =~ /^Can't locate \Q$module.pm\E/;
    die $@;
}


sub init_rootclass {	# deprecated
    return 1;
}


*internal = \&DBD::Switch::dr::driver;

sub driver_prefix {
    my ($class, $driver) = @_;
    return $dbd_class_registry{$driver}->{prefix} if exists $dbd_class_registry{$driver};
    return;
}

sub available_drivers {
    my($quiet) = @_;
    my(@drivers, $d, $f);
    local(*DBI::DIR, $@);
    my(%seen_dir, %seen_dbd);
    my $haveFileSpec = eval { require File::Spec };
    foreach $d (@INC){
	chomp($d); # Perl 5 beta 3 bug in #!./perl -Ilib from Test::Harness
	my $dbd_dir =
	    ($haveFileSpec ? File::Spec->catdir($d, 'DBD') : "$d/DBD");
	next unless -d $dbd_dir;
	next if $seen_dir{$d};
	$seen_dir{$d} = 1;
	# XXX we have a problem here with case insensitive file systems
	# XXX since we can't tell what case must be used when loading.
	opendir(DBI::DIR, $dbd_dir) || Carp::carp "opendir $dbd_dir: $!\n";
	foreach $f (readdir(DBI::DIR)){
	    next unless $f =~ s/\.pm$//;
	    next if $f eq 'NullP';
	    if ($seen_dbd{$f}){
		Carp::carp "DBD::$f in $d is hidden by DBD::$f in $seen_dbd{$f}\n"
		    unless $quiet;
            } else {
		push(@drivers, $f);
	    }
	    $seen_dbd{$f} = $d;
	}
	closedir(DBI::DIR);
    }

    # "return sort @drivers" will not DWIM in scalar context.
    return wantarray ? sort @drivers : @drivers;
}

sub installed_versions {
    my ($class, $quiet) = @_;
    my %error;
    my %version = ( DBI => $DBI::VERSION );
    $version{"DBI::PurePerl"} = $DBI::PurePerl::VERSION
	if $DBI::PurePerl;
    for my $driver ($class->available_drivers($quiet)) {
	next if $DBI::PurePerl && grep { -d "$_/auto/DBD/$driver" } @INC;
	my $drh = eval {
	    local $SIG{__WARN__} = sub {};
	    $class->install_driver($driver);
	};
	($error{"DBD::$driver"}=$@),next if $@;
	no strict 'refs';
	my $vers = ${"DBD::$driver" . '::VERSION'};
	$version{"DBD::$driver"} = $vers || '?';
    }
    if (wantarray) {
       return map { m/^DBD::(\w+)/ ? ($1) : () } sort keys %version;
    }
    if (!defined wantarray) {	# void context
	require Config;		# add more detail
	$version{OS}   = "$^O\t($Config::Config{osvers})";
	$version{Perl} = "$]\t($Config::Config{archname})";
	$version{$_}   = (($error{$_} =~ s/ \(\@INC.*//s),$error{$_})
	    for keys %error;
	printf "  %-16s: %s\n",$_,$version{$_}
	    for reverse sort keys %version;
    }
    return \%version;
}


sub data_sources {
    my ($class, $driver, @other) = @_;
    my $drh = $class->install_driver($driver);
    my @ds = $drh->data_sources(@other);
    return @ds;
}


sub neat_list {
    my ($listref, $maxlen, $sep) = @_;
    $maxlen = 0 unless defined $maxlen;	# 0 == use internal default
    $sep = ", " unless defined $sep;
    join($sep, map { neat($_,$maxlen) } @$listref);
}


sub dump_results {	# also aliased as a method in DBD::_::st
    my ($sth, $maxlen, $lsep, $fsep, $fh) = @_;
    return 0 unless $sth;
    $maxlen ||= 35;
    $lsep   ||= "\n";
    $fh ||= \*STDOUT;
    my $rows = 0;
    my $ref;
    while($ref = $sth->fetch) {
	print $fh $lsep if $rows++ and $lsep;
	my $str = neat_list($ref,$maxlen,$fsep);
	print $fh $str;	# done on two lines to avoid 5.003 errors
    }
    print $fh "\n$rows rows".($DBI::err ? " ($DBI::err: $DBI::errstr)" : "")."\n";
    $rows;
}


sub data_diff {
    my ($a, $b, $logical) = @_;

    my $diff   = data_string_diff($a, $b);
    return "" if $logical and !$diff;

    my $a_desc = data_string_desc($a);
    my $b_desc = data_string_desc($b);
    return "" if !$diff and $a_desc eq $b_desc;

    $diff ||= "Strings contain the same sequence of characters"
    	if length($a);
    $diff .= "\n" if $diff;
    return "a: $a_desc\nb: $b_desc\n$diff";
}


sub data_string_diff {
    # Compares 'logical' characters, not bytes, so a latin1 string and an
    # an equivalent Unicode string will compare as equal even though their
    # byte encodings are different.
    my ($a, $b) = @_;
    unless (defined $a and defined $b) {             # one undef
	return ""
		if !defined $a and !defined $b;
	return "String a is undef, string b has ".length($b)." characters"
		if !defined $a;
	return "String b is undef, string a has ".length($a)." characters"
		if !defined $b;
    }

    require utf8;
    # hack to cater for perl 5.6
    *utf8::is_utf8 = sub { (DBI::neat(shift)=~/^"/) } unless defined &utf8::is_utf8;

    my @a_chars = (utf8::is_utf8($a)) ? unpack("U*", $a) : unpack("C*", $a);
    my @b_chars = (utf8::is_utf8($b)) ? unpack("U*", $b) : unpack("C*", $b);
    my $i = 0;
    while (@a_chars && @b_chars) {
	++$i, shift(@a_chars), shift(@b_chars), next
	    if $a_chars[0] == $b_chars[0];# compare ordinal values
	my @desc = map {
	    $_ > 255 ?                    # if wide character...
	      sprintf("\\x{%04X}", $_) :  # \x{...}
	      chr($_) =~ /[[:cntrl:]]/ ?  # else if control character ...
	      sprintf("\\x%02X", $_) :    # \x..
	      chr($_)                     # else as themselves
	} ($a_chars[0], $b_chars[0]);
	# highlight probable double-encoding?
        foreach my $c ( @desc ) {
	    next unless $c =~ m/\\x\{08(..)}/;
	    $c .= "='" .chr(hex($1)) ."'"
	}
	return sprintf "Strings differ at index $i: a[$i]=$desc[0], b[$i]=$desc[1]";
    }
    return "String a truncated after $i characters" if @b_chars;
    return "String b truncated after $i characters" if @a_chars;
    return "";
}


sub data_string_desc {	# describe a data string
    my ($a) = @_;
    require bytes;
    require utf8;

    # hacks to cater for perl 5.6
    *utf8::is_utf8 = sub { (DBI::neat(shift)=~/^"/) } unless defined &utf8::is_utf8;
    *utf8::valid   = sub {                        1 } unless defined &utf8::valid;

    # Give sufficient info to help diagnose at least these kinds of situations:
    # - valid UTF8 byte sequence but UTF8 flag not set
    #   (might be ascii so also need to check for hibit to make it worthwhile)
    # - UTF8 flag set but invalid UTF8 byte sequence
    # could do better here, but this'll do for now
    my $utf8 = sprintf "UTF8 %s%s",
	utf8::is_utf8($a) ? "on" : "off",
	utf8::valid($a||'') ? "" : " but INVALID encoding";
    return "$utf8, undef" unless defined $a;
    my $is_ascii = $a =~ m/^[\000-\177]*$/;
    return sprintf "%s, %s, %d characters %d bytes",
	$utf8, $is_ascii ? "ASCII" : "non-ASCII",
	length($a), bytes::length($a);
}


sub connect_test_perf {
    my($class, $dsn,$dbuser,$dbpass, $attr) = @_;
	Carp::croak("connect_test_perf needs hash ref as fourth arg") unless ref $attr;
    # these are non standard attributes just for this special method
    my $loops ||= $attr->{dbi_loops} || 5;
    my $par   ||= $attr->{dbi_par}   || 1;	# parallelism
    my $verb  ||= $attr->{dbi_verb}  || 1;
    my $meth  ||= $attr->{dbi_meth}  || 'connect';
    print "$dsn: testing $loops sets of $par connections:\n";
    require "FileHandle.pm";	# don't let toke.c create empty FileHandle package
    local $| = 1;
    my $drh = $class->install_driver($dsn) or Carp::croak("Can't install $dsn driver\n");
    # test the connection and warm up caches etc
    $drh->connect($dsn,$dbuser,$dbpass) or Carp::croak("connect failed: $DBI::errstr");
    my $t1 = dbi_time();
    my $loop;
    for $loop (1..$loops) {
	my @cons;
	print "Connecting... " if $verb;
	for (1..$par) {
	    print "$_ ";
	    push @cons, ($drh->connect($dsn,$dbuser,$dbpass)
		    or Carp::croak("connect failed: $DBI::errstr\n"));
	}
	print "\nDisconnecting...\n" if $verb;
	for (@cons) {
	    $_->disconnect or warn "disconnect failed: $DBI::errstr"
	}
    }
    my $t2 = dbi_time();
    my $td = $t2 - $t1;
    printf "$meth %d and disconnect them, %d times: %.4fs / %d = %.4fs\n",
        $par, $loops, $td, $loops*$par, $td/($loops*$par);
    return $td;
}


# Help people doing DBI->errstr, might even document it one day
# XXX probably best moved to cheaper XS code if this gets documented
sub err    { $DBI::err    }
sub errstr { $DBI::errstr }


# --- Private Internal Function for Creating New DBI Handles

# XXX move to PurePerl?
*DBI::dr::TIEHASH = \&DBI::st::TIEHASH;
*DBI::db::TIEHASH = \&DBI::st::TIEHASH;


# These three special constructors are called by the drivers
# The way they are called is likely to change.

our $shared_profile;

sub _new_drh {	# called by DBD::<drivername>::driver()
    my ($class, $initial_attr, $imp_data) = @_;
    # Provide default storage for State,Err and Errstr.
    # Note that these are shared by all child handles by default! XXX
    # State must be undef to get automatic faking in DBI::var::FETCH
    my ($h_state_store, $h_err_store, $h_errstr_store) = (undef, 0, '');
    my $attr = {
	# these attributes get copied down to child handles by default
	'State'		=> \$h_state_store,  # Holder for DBI::state
	'Err'		=> \$h_err_store,    # Holder for DBI::err
	'Errstr'	=> \$h_errstr_store, # Holder for DBI::errstr
	'TraceLevel' 	=> 0,
	FetchHashKeyName=> 'NAME',
	%$initial_attr,
    };
    my ($h, $i) = _new_handle('DBI::dr', '', $attr, $imp_data, $class);

    # XXX DBI_PROFILE unless DBI::PurePerl because for some reason
    # it kills the t/zz_*_pp.t tests (they silently exit early)
    if (($ENV{DBI_PROFILE} && !$DBI::PurePerl) || $shared_profile) {
	# The profile object created here when the first driver is loaded
	# is shared by all drivers so we end up with just one set of profile
	# data and thus the 'total time in DBI' is really the true total.
	if (!$shared_profile) {	# first time
	    $h->{Profile} = $ENV{DBI_PROFILE}; # write string
	    $shared_profile = $h->{Profile};   # read and record object
	}
	else {
	    $h->{Profile} = $shared_profile;
	}
    }
    return $h unless wantarray;
    ($h, $i);
}

sub _new_dbh {	# called by DBD::<drivername>::dr::connect()
    my ($drh, $attr, $imp_data) = @_;
    my $imp_class = $drh->{ImplementorClass}
	or Carp::croak("DBI _new_dbh: $drh has no ImplementorClass");
    substr($imp_class,-4,4) = '::db';
    my $app_class = ref $drh;
    substr($app_class,-4,4) = '::db';
    $attr->{Err}    ||= \my $err;
    $attr->{Errstr} ||= \my $errstr;
    $attr->{State}  ||= \my $state;
    _new_handle($app_class, $drh, $attr, $imp_data, $imp_class);
}

sub _new_sth {	# called by DBD::<drivername>::db::prepare)
    my ($dbh, $attr, $imp_data) = @_;
    my $imp_class = $dbh->{ImplementorClass}
	or Carp::croak("DBI _new_sth: $dbh has no ImplementorClass");
    substr($imp_class,-4,4) = '::st';
    my $app_class = ref $dbh;
    substr($app_class,-4,4) = '::st';
    _new_handle($app_class, $dbh, $attr, $imp_data, $imp_class);
}


# end of DBI package



# --------------------------------------------------------------------
# === The internal DBI Switch pseudo 'driver' class ===

{   package	# hide from PAUSE
	DBD::Switch::dr;
    DBI->setup_driver('DBD::Switch');	# sets up @ISA

    $DBD::Switch::dr::imp_data_size = 0;
    $DBD::Switch::dr::imp_data_size = 0;	# avoid typo warning
    my $drh;

    sub driver {
	return $drh if $drh;	# a package global

	my $inner;
	($drh, $inner) = DBI::_new_drh('DBD::Switch::dr', {
		'Name'    => 'Switch',
		'Version' => $DBI::VERSION,
		'Attribution' => "DBI $DBI::VERSION by Tim Bunce",
	    });
	Carp::croak("DBD::Switch init failed!") unless ($drh && $inner);
	return $drh;
    }
    sub CLONE {
	undef $drh;
    }

    sub FETCH {
	my($drh, $key) = @_;
	return DBI->trace if $key eq 'DebugDispatch';
	return undef if $key eq 'DebugLog';	# not worth fetching, sorry
	return $drh->DBD::_::dr::FETCH($key);
	undef;
    }
    sub STORE {
	my($drh, $key, $value) = @_;
	if ($key eq 'DebugDispatch') {
	    DBI->trace($value);
	} elsif ($key eq 'DebugLog') {
	    DBI->trace(-1, $value);
	} else {
	    $drh->DBD::_::dr::STORE($key, $value);
	}
    }
}


# --------------------------------------------------------------------
# === OPTIONAL MINIMAL BASE CLASSES FOR DBI SUBCLASSES ===

# We only define default methods for harmless functions.
# We don't, for example, define a DBD::_::st::prepare()

{   package		# hide from PAUSE
	DBD::_::common; # ====== Common base class methods ======
    use strict;

    # methods common to all handle types:

    sub _not_impl {
	my ($h, $method) = @_;
	$h->trace_msg("Driver does not implement the $method method.\n");
	return;	# empty list / undef
    }

    # generic TIEHASH default methods:
    sub FIRSTKEY { }
    sub NEXTKEY  { }
    sub EXISTS   { defined($_[0]->FETCH($_[1])) } # XXX undef?
    sub CLEAR    { Carp::carp "Can't CLEAR $_[0] (DBI)" }

    sub FETCH_many {    # XXX should move to C one day
        my $h = shift;
        # scalar is needed to workaround drivers that return an empty list
        # for some attributes
        return map { scalar $h->FETCH($_) } @_;
    }

    *dump_handle = \&DBI::dump_handle;

    sub install_method {
	# special class method called directly by apps and/or drivers
	# to install new methods into the DBI dispatcher
	# DBD::Foo::db->install_method("foo_mumble", { usage => [...], options => '...' });
	my ($class, $method, $attr) = @_;
	Carp::croak("Class '$class' must begin with DBD:: and end with ::db or ::st")
	    unless $class =~ /^DBD::(\w+)::(dr|db|st)$/;
	my ($driver, $subtype) = ($1, $2);
	Carp::croak("invalid method name '$method'")
	    unless $method =~ m/^([a-z]+_)\w+$/;
	my $prefix = $1;
	my $reg_info = $dbd_prefix_registry->{$prefix};
	Carp::carp("method name prefix '$prefix' is not associated with a registered driver") unless $reg_info;

	my $full_method = "DBI::${subtype}::$method";
	$DBI::installed_methods{$full_method} = $attr;

	my (undef, $filename, $line) = caller;
	# XXX reformat $attr as needed for _install_method
	my %attr = %{$attr||{}}; # copy so we can edit
	DBI->_install_method("DBI::${subtype}::$method", "$filename at line $line", \%attr);
    }

    sub parse_trace_flags {
	my ($h, $spec) = @_;
	my $level = 0;
	my $flags = 0;
	my @unknown;
	for my $word (split /\s*[|&,]\s*/, $spec) {
	    if (DBI::looks_like_number($word) && $word <= 0xF && $word >= 0) {
		$level = $word;
	    } elsif ($word eq 'ALL') {
		$flags = 0x7FFFFFFF; # XXX last bit causes negative headaches
		last;
	    } elsif (my $flag = $h->parse_trace_flag($word)) {
		$flags |= $flag;
	    }
	    else {
		push @unknown, $word;
	    }
	}
	if (@unknown && (ref $h ? $h->FETCH('Warn') : 1)) {
	    Carp::carp("$h->parse_trace_flags($spec) ignored unknown trace flags: ".
		join(" ", map { DBI::neat($_) } @unknown));
	}
	$flags |= $level;
	return $flags;
    }

    sub parse_trace_flag {
	my ($h, $name) = @_;
	#      0xddDDDDrL (driver, DBI, reserved, Level)
	return 0x00000100 if $name eq 'SQL';
	return;
    }

    sub private_attribute_info {
        return undef;
    }

    sub visit_child_handles {
	my ($h, $code, $info) = @_;
	$info = {} if not defined $info;
	for my $ch (@{ $h->{ChildHandles} || []}) {
	    next unless $ch;
	    my $child_info = $code->($ch, $info)
		or next;
	    $ch->visit_child_handles($code, $child_info);
	}
	return $info;
    }
}


{   package		# hide from PAUSE
	DBD::_::dr;	# ====== DRIVER ======
    @DBD::_::dr::ISA = qw(DBD::_::common);
    use strict;

    sub default_user {
	my ($drh, $user, $pass, $attr) = @_;
	$user = $ENV{DBI_USER} unless defined $user;
	$pass = $ENV{DBI_PASS} unless defined $pass;
	return ($user, $pass);
    }

    sub connect { # normally overridden, but a handy default
	my ($drh, $dsn, $user, $auth) = @_;
	my ($this) = DBI::_new_dbh($drh, {
	    'Name' => $dsn,
	});
	# XXX debatable as there's no "server side" here
	# (and now many uses would trigger warnings on DESTROY)
	# $this->STORE(Active => 1);
        # so drivers should set it in their own connect
	$this;
    }


    sub connect_cached {
        my $drh = shift;
	my ($dsn, $user, $auth, $attr) = @_;

	my $cache = $drh->{CachedKids} ||= {};
	my $key = do { local $^W;
	    join "!\001", $dsn, $user, $auth, DBI::_concat_hash_sorted($attr, "=\001", ",\001", 0, 0)
	};
	my $dbh = $cache->{$key};
        $drh->trace_msg(sprintf("    connect_cached: key '$key', cached dbh $dbh\n", DBI::neat($key), DBI::neat($dbh)))
            if $DBI::dbi_debug >= 4;

        my $cb = $attr->{Callbacks}; # take care not to autovivify
	if ($dbh && $dbh->FETCH('Active') && eval { $dbh->ping }) {
            # If the caller has provided a callback then call it
            if ($cb and $cb = $cb->{"connect_cached.reused"}) {
		local $_ = "connect_cached.reused";
		$cb->($dbh, $dsn, $user, $auth, $attr);
            }
	    return $dbh;
	}

	# If the caller has provided a callback then call it
	if ($cb and $cb = $cb->{"connect_cached.new"}) {
	    local $_ = "connect_cached.new";
	    $cb->($dbh, $dsn, $user, $auth, $attr);
	}

	$dbh = $drh->connect(@_);
	$cache->{$key} = $dbh;	# replace prev entry, even if connect failed
	return $dbh;
    }

}


{   package		# hide from PAUSE
	DBD::_::db;	# ====== DATABASE ======
    @DBD::_::db::ISA = qw(DBD::_::common);
    use strict;

    sub clone {
	my ($old_dbh, $attr) = @_;
	my $closure = $old_dbh->{dbi_connect_closure} or return;
	unless ($attr) {
	    # copy attributes visible in the attribute cache
	    keys %$old_dbh;	# reset iterator
	    while ( my ($k, $v) = each %$old_dbh ) {
		# ignore non-code refs, i.e., caches, handles, Err etc
		next if ref $v && ref $v ne 'CODE'; # HandleError etc
		$attr->{$k} = $v;
	    }
	    # explicitly set attributes which are unlikely to be in the
	    # attribute cache, i.e., boolean's and some others
	    $attr->{$_} = $old_dbh->FETCH($_) for (qw(
		AutoCommit ChopBlanks InactiveDestroy AutoInactiveDestroy
		LongTruncOk PrintError PrintWarn Profile RaiseError
		ShowErrorStatement TaintIn TaintOut
	    ));
	}
	# use Data::Dumper; warn Dumper([$old_dbh, $attr]);
	my $new_dbh = &$closure($old_dbh, $attr);
	unless ($new_dbh) {
	    # need to copy err/errstr from driver back into $old_dbh
	    my $drh = $old_dbh->{Driver};
	    return $old_dbh->set_err($drh->err, $drh->errstr, $drh->state);
	}
	return $new_dbh;
    }

    sub quote_identifier {
	my ($dbh, @id) = @_;
	my $attr = (@id > 3 && ref($id[-1])) ? pop @id : undef;

	my $info = $dbh->{dbi_quote_identifier_cache} ||= [
	    $dbh->get_info(29)  || '"',	# SQL_IDENTIFIER_QUOTE_CHAR
	    $dbh->get_info(41)  || '.',	# SQL_CATALOG_NAME_SEPARATOR
	    $dbh->get_info(114) ||   1,	# SQL_CATALOG_LOCATION
	];

	my $quote = $info->[0];
	foreach (@id) {			# quote the elements
	    next unless defined;
	    s/$quote/$quote$quote/g;	# escape embedded quotes
	    $_ = qq{$quote$_$quote};
	}

	# strip out catalog if present for special handling
	my $catalog = (@id >= 3) ? shift @id : undef;

	# join the dots, ignoring any null/undef elements (ie schema)
	my $quoted_id = join '.', grep { defined } @id;

	if ($catalog) {			# add catalog correctly
	    $quoted_id = ($info->[2] == 2)	# SQL_CL_END
		    ? $quoted_id . $info->[1] . $catalog
		    : $catalog   . $info->[1] . $quoted_id;
	}
	return $quoted_id;
    }

    sub quote {
	my ($dbh, $str, $data_type) = @_;

	return "NULL" unless defined $str;
	unless ($data_type) {
	    $str =~ s/'/''/g;		# ISO SQL2
	    return "'$str'";
	}

	my $dbi_literal_quote_cache = $dbh->{'dbi_literal_quote_cache'} ||= [ {} , {} ];
	my ($prefixes, $suffixes) = @$dbi_literal_quote_cache;

	my $lp = $prefixes->{$data_type};
	my $ls = $suffixes->{$data_type};

	if ( ! defined $lp || ! defined $ls ) {
	    my $ti = $dbh->type_info($data_type);
	    $lp = $prefixes->{$data_type} = $ti ? $ti->{LITERAL_PREFIX} || "" : "'";
	    $ls = $suffixes->{$data_type} = $ti ? $ti->{LITERAL_SUFFIX} || "" : "'";
	}
	return $str unless $lp || $ls; # no quoting required

	# XXX don't know what the standard says about escaping
	# in the 'general case' (where $lp != "'").
	# So we just do this and hope:
	$str =~ s/$lp/$lp$lp/g
		if $lp && $lp eq $ls && ($lp eq "'" || $lp eq '"');
	return "$lp$str$ls";
    }

    sub rows { -1 }	# here so $DBI::rows 'works' after using $dbh

    sub do {
	my($dbh, $statement, $attr, @params) = @_;
	my $sth = $dbh->prepare($statement, $attr) or return undef;
	$sth->execute(@params) or return undef;
	my $rows = $sth->rows;
	($rows == 0) ? "0E0" : $rows;
    }

    sub _do_selectrow {
	my ($method, $dbh, $stmt, $attr, @bind) = @_;
	my $sth = ((ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr))
	    or return;
	$sth->execute(@bind)
	    or return;
	my $row = $sth->$method()
	    and $sth->finish;
	return $row;
    }

    sub selectrow_hashref {  return _do_selectrow('fetchrow_hashref',  @_); }

    # XXX selectrow_array/ref also have C implementations in Driver.xst
    sub selectrow_arrayref { return _do_selectrow('fetchrow_arrayref', @_); }
    sub selectrow_array {
	my $row = _do_selectrow('fetchrow_arrayref', @_) or return;
	return $row->[0] unless wantarray;
	return @$row;
    }

    # XXX selectall_arrayref also has C implementation in Driver.xst
    # which fallsback to this if a slice is given
    sub selectall_arrayref {
	my ($dbh, $stmt, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr)
	    or return;
	$sth->execute(@bind) || return;
	my $slice = $attr->{Slice}; # typically undef, else hash or array ref
	if (!$slice and $slice=$attr->{Columns}) {
	    if (ref $slice eq 'ARRAY') { # map col idx to perl array idx
		$slice = [ @{$attr->{Columns}} ];	# take a copy
		for (@$slice) { $_-- }
	    }
	}
	my $rows = $sth->fetchall_arrayref($slice, my $MaxRows = $attr->{MaxRows});
	$sth->finish if defined $MaxRows;
	return $rows;
    }

    sub selectall_hashref {
	my ($dbh, $stmt, $key_field, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr);
	return unless $sth;
	$sth->execute(@bind) || return;
	return $sth->fetchall_hashref($key_field);
    }

    sub selectcol_arrayref {
	my ($dbh, $stmt, $attr, @bind) = @_;
	my $sth = (ref $stmt) ? $stmt : $dbh->prepare($stmt, $attr);
	return unless $sth;
	$sth->execute(@bind) || return;
	my @columns = ($attr->{Columns}) ? @{$attr->{Columns}} : (1);
	my @values  = (undef) x @columns;
	my $idx = 0;
	for (@columns) {
	    $sth->bind_col($_, \$values[$idx++]) || return;
	}
	my @col;
	if (my $max = $attr->{MaxRows}) {
	    push @col, @values while 0 < $max-- && $sth->fetch;
	}
	else {
	    push @col, @values while $sth->fetch;
	}
	return \@col;
    }

    sub prepare_cached {
	my ($dbh, $statement, $attr, $if_active) = @_;

	# Needs support at dbh level to clear cache before complaining about
	# active children. The XS template code does this. Drivers not using
	# the template must handle clearing the cache themselves.
	my $cache = $dbh->{CachedKids} ||= {};
	my $key = do { local $^W;
	    join "!\001", $statement, DBI::_concat_hash_sorted($attr, "=\001", ",\001", 0, 0)
	};
	my $sth = $cache->{$key};

	if ($sth) {
	    return $sth unless $sth->FETCH('Active');
	    Carp::carp("prepare_cached($statement) statement handle $sth still Active")
		unless ($if_active ||= 0);
	    $sth->finish if $if_active <= 1;
	    return $sth  if $if_active <= 2;
	}

	$sth = $dbh->prepare($statement, $attr);
	$cache->{$key} = $sth if $sth;

	return $sth;
    }

    sub ping {
	my $dbh = shift;
	$dbh->_not_impl('ping');
	# "0 but true" is a special kind of true 0 that is used here so
	# applications can check if the ping was a real ping or not
	($dbh->FETCH('Active')) ?  "0 but true" : 0;
    }

    sub begin_work {
	my $dbh = shift;
	return $dbh->set_err($DBI::stderr, "Already in a transaction")
		unless $dbh->FETCH('AutoCommit');
	$dbh->STORE('AutoCommit', 0); # will croak if driver doesn't support it
	$dbh->STORE('BegunWork',  1); # trigger post commit/rollback action
	return 1;
    }

    sub primary_key {
	my ($dbh, @args) = @_;
	my $sth = $dbh->primary_key_info(@args) or return;
	my ($row, @col);
	push @col, $row->[3] while ($row = $sth->fetch);
	Carp::croak("primary_key method not called in list context")
		unless wantarray; # leave us some elbow room
	return @col;
    }

    sub tables {
	my ($dbh, @args) = @_;
	my $sth    = $dbh->table_info(@args[0,1,2,3,4]) or return;
	my $tables = $sth->fetchall_arrayref or return;
	my @tables;
	if ($dbh->get_info(29)) { # SQL_IDENTIFIER_QUOTE_CHAR
	    @tables = map { $dbh->quote_identifier( @{$_}[0,1,2] ) } @$tables;
	}
	else {		# temporary old style hack (yeach)
	    @tables = map {
		my $name = $_->[2];
		if ($_->[1]) {
		    my $schema = $_->[1];
		    # a sad hack (mostly for Informix I recall)
		    my $quote = ($schema eq uc($schema)) ? '' : '"';
		    $name = "$quote$schema$quote.$name"
		}
		$name;
	    } @$tables;
	}
	return @tables;
    }

    sub type_info {	# this should be sufficient for all drivers
	my ($dbh, $data_type) = @_;
	my $idx_hash;
	my $tia = $dbh->{dbi_type_info_row_cache};
	if ($tia) {
	    $idx_hash = $dbh->{dbi_type_info_idx_cache};
	}
	else {
	    my $temp = $dbh->type_info_all;
	    return unless $temp && @$temp;
	    # we cache here because type_info_all may be expensive to call
	    # (and we take a copy so the following shift can't corrupt
	    # the data that may be returned by future calls to type_info_all)
	    $tia      = $dbh->{dbi_type_info_row_cache} = [ @$temp ];
	    $idx_hash = $dbh->{dbi_type_info_idx_cache} = shift @$tia;
	}

	my $dt_idx   = $idx_hash->{DATA_TYPE} || $idx_hash->{data_type};
	Carp::croak("type_info_all returned non-standard DATA_TYPE index value ($dt_idx != 1)")
	    if $dt_idx && $dt_idx != 1;

	# --- simple DATA_TYPE match filter
	my @ti;
	my @data_type_list = (ref $data_type) ? @$data_type : ($data_type);
	foreach $data_type (@data_type_list) {
	    if (defined($data_type) && $data_type != DBI::SQL_ALL_TYPES()) {
		push @ti, grep { $_->[$dt_idx] == $data_type } @$tia;
	    }
	    else {	# SQL_ALL_TYPES
		push @ti, @$tia;
	    }
	    last if @ti;	# found at least one match
	}

	# --- format results into list of hash refs
	my $idx_fields = keys %$idx_hash;
	my @idx_names  = map { uc($_) } keys %$idx_hash;
	my @idx_values = values %$idx_hash;
	Carp::croak "type_info_all result has $idx_fields keys but ".(@{$ti[0]})." fields"
		if @ti && @{$ti[0]} != $idx_fields;
	my @out = map {
	    my %h; @h{@idx_names} = @{$_}[ @idx_values ]; \%h;
	} @ti;
	return $out[0] unless wantarray;
	return @out;
    }

    sub data_sources {
	my ($dbh, @other) = @_;
	my $drh = $dbh->{Driver}; # XXX proxy issues?
	return $drh->data_sources(@other);
    }

}


{   package		# hide from PAUSE
	DBD::_::st;	# ====== STATEMENT ======
    @DBD::_::st::ISA = qw(DBD::_::common);
    use strict;

    sub bind_param { Carp::croak("Can't bind_param, not implement by driver") }

#
# ********************************************************
#
#	BEGIN ARRAY BINDING
#
#	Array binding support for drivers which don't support
#	array binding, but have sufficient interfaces to fake it.
#	NOTE: mixing scalars and arrayrefs requires using bind_param_array
#	for *all* params...unless we modify bind_param for the default
#	case...
#
#	2002-Apr-10	D. Arnold

    sub bind_param_array {
	my $sth = shift;
	my ($p_id, $value_array, $attr) = @_;

	return $sth->set_err($DBI::stderr, "Value for parameter $p_id must be a scalar or an arrayref, not a ".ref($value_array))
	    if defined $value_array and ref $value_array and ref $value_array ne 'ARRAY';

	return $sth->set_err($DBI::stderr, "Can't use named placeholder '$p_id' for non-driver supported bind_param_array")
	    unless DBI::looks_like_number($p_id); # because we rely on execute(@ary) here

	return $sth->set_err($DBI::stderr, "Placeholder '$p_id' is out of range")
	    if $p_id <= 0; # can't easily/reliably test for too big

	# get/create arrayref to hold params
	my $hash_of_arrays = $sth->{ParamArrays} ||= { };

	# If the bind has attribs then we rely on the driver conforming to
	# the DBI spec in that a single bind_param() call with those attribs
	# makes them 'sticky' and apply to all later execute(@values) calls.
	# Since we only call bind_param() if we're given attribs then
	# applications using drivers that don't support bind_param can still
	# use bind_param_array() so long as they don't pass any attribs.

	$$hash_of_arrays{$p_id} = $value_array;
	return $sth->bind_param($p_id, undef, $attr)
		if $attr;
	1;
    }

    sub bind_param_inout_array {
	my $sth = shift;
	# XXX not supported so we just call bind_param_array instead
	# and then return an error
	my ($p_num, $value_array, $attr) = @_;
	$sth->bind_param_array($p_num, $value_array, $attr);
	return $sth->set_err($DBI::stderr, "bind_param_inout_array not supported");
    }

    sub bind_columns {
	my $sth = shift;
	my $fields = $sth->FETCH('NUM_OF_FIELDS') || 0;
	if ($fields <= 0 && !$sth->{Active}) {
	    return $sth->set_err($DBI::stderr, "Statement has no result columns to bind"
		    ." (perhaps you need to successfully call execute first)");
	}
	# Backwards compatibility for old-style call with attribute hash
	# ref as first arg. Skip arg if undef or a hash ref.
	my $attr;
	$attr = shift if !defined $_[0] or ref($_[0]) eq 'HASH';

	my $idx = 0;
	$sth->bind_col(++$idx, shift, $attr) or return
	    while (@_ and $idx < $fields);

	return $sth->set_err($DBI::stderr, "bind_columns called with ".($idx+@_)." values but $fields are needed")
	    if @_ or $idx != $fields;

	return 1;
    }

    sub execute_array {
	my $sth = shift;
	my ($attr, @array_of_arrays) = @_;
	my $NUM_OF_PARAMS = $sth->FETCH('NUM_OF_PARAMS'); # may be undef at this point

	# get tuple status array or hash attribute
	my $tuple_sts = $attr->{ArrayTupleStatus};
	return $sth->set_err($DBI::stderr, "ArrayTupleStatus attribute must be an arrayref")
		if $tuple_sts and ref $tuple_sts ne 'ARRAY';

	# bind all supplied arrays
	if (@array_of_arrays) {
	    $sth->{ParamArrays} = { };	# clear out old params
	    return $sth->set_err($DBI::stderr,
		    @array_of_arrays." bind values supplied but $NUM_OF_PARAMS expected")
		if defined ($NUM_OF_PARAMS) && @array_of_arrays != $NUM_OF_PARAMS;
	    $sth->bind_param_array($_, $array_of_arrays[$_-1]) or return
		foreach (1..@array_of_arrays);
	}

	my $fetch_tuple_sub;

	if ($fetch_tuple_sub = $attr->{ArrayTupleFetch}) {	# fetch on demand

	    return $sth->set_err($DBI::stderr,
		    "Can't use both ArrayTupleFetch and explicit bind values")
		if @array_of_arrays; # previous bind_param_array calls will simply be ignored

	    if (UNIVERSAL::isa($fetch_tuple_sub,'DBI::st')) {
		my $fetch_sth = $fetch_tuple_sub;
		return $sth->set_err($DBI::stderr,
			"ArrayTupleFetch sth is not Active, need to execute() it first")
		    unless $fetch_sth->{Active};
		# check column count match to give more friendly message
		my $NUM_OF_FIELDS = $fetch_sth->{NUM_OF_FIELDS};
		return $sth->set_err($DBI::stderr,
			"$NUM_OF_FIELDS columns from ArrayTupleFetch sth but $NUM_OF_PARAMS expected")
		    if defined($NUM_OF_FIELDS) && defined($NUM_OF_PARAMS)
		    && $NUM_OF_FIELDS != $NUM_OF_PARAMS;
		$fetch_tuple_sub = sub { $fetch_sth->fetchrow_arrayref };
	    }
	    elsif (!UNIVERSAL::isa($fetch_tuple_sub,'CODE')) {
		return $sth->set_err($DBI::stderr, "ArrayTupleFetch '$fetch_tuple_sub' is not a code ref or statement handle");
	    }

	}
	else {
	    my $NUM_OF_PARAMS_given = keys %{ $sth->{ParamArrays} || {} };
	    return $sth->set_err($DBI::stderr,
		    "$NUM_OF_PARAMS_given bind values supplied but $NUM_OF_PARAMS expected")
		if defined($NUM_OF_PARAMS) && $NUM_OF_PARAMS != $NUM_OF_PARAMS_given;

	    # get the length of a bound array
	    my $maxlen;
	    my %hash_of_arrays = %{$sth->{ParamArrays}};
	    foreach (keys(%hash_of_arrays)) {
		my $ary = $hash_of_arrays{$_};
		next unless ref $ary eq 'ARRAY';
		$maxlen = @$ary if !$maxlen || @$ary > $maxlen;
	    }
	    # if there are no arrays then execute scalars once
	    $maxlen = 1 unless defined $maxlen;
	    my @bind_ids = 1..keys(%hash_of_arrays);

	    my $tuple_idx = 0;
	    $fetch_tuple_sub = sub {
		return if $tuple_idx >= $maxlen;
		my @tuple = map {
		    my $a = $hash_of_arrays{$_};
		    ref($a) ? $a->[$tuple_idx] : $a
		} @bind_ids;
		++$tuple_idx;
		return \@tuple;
	    };
	}
	# pass thru the callers scalar or list context
	return $sth->execute_for_fetch($fetch_tuple_sub, $tuple_sts);
    }

    sub execute_for_fetch {
	my ($sth, $fetch_tuple_sub, $tuple_status) = @_;
	# start with empty status array
	($tuple_status) ? @$tuple_status = () : $tuple_status = [];

        my $rc_total = 0;
	my $err_count;
	while ( my $tuple = &$fetch_tuple_sub() ) {
	    if ( my $rc = $sth->execute(@$tuple) ) {
		push @$tuple_status, $rc;
		$rc_total = ($rc >= 0 && $rc_total >= 0) ? $rc_total + $rc : -1;
	    }
	    else {
		$err_count++;
		push @$tuple_status, [ $sth->err, $sth->errstr, $sth->state ];
                # XXX drivers implementing execute_for_fetch could opt to "last;" here
                # if they know the error code means no further executes will work.
	    }
	}
        my $tuples = @$tuple_status;
        return $sth->set_err($DBI::stderr, "executing $tuples generated $err_count errors")
            if $err_count;
	$tuples ||= "0E0";
	return $tuples unless wantarray;
	return ($tuples, $rc_total);
    }


    sub fetchall_arrayref {	# ALSO IN Driver.xst
	my ($sth, $slice, $max_rows) = @_;

        # when batch fetching with $max_rows were very likely to try to
        # fetch the 'next batch' after the previous batch returned
        # <=$max_rows. So don't treat that as an error.
        return undef if $max_rows and not $sth->FETCH('Active');

	my $mode = ref($slice) || 'ARRAY';
	my @rows;
	my $row;
	if ($mode eq 'ARRAY') {
	    # we copy the array here because fetch (currently) always
	    # returns the same array ref. XXX
	    if ($slice && @$slice) {
                $max_rows = -1 unless defined $max_rows;
		push @rows, [ @{$row}[ @$slice] ]
		    while($max_rows-- and $row = $sth->fetch);
	    }
	    elsif (defined $max_rows) {
		push @rows, [ @$row ]
		    while($max_rows-- and $row = $sth->fetch);
	    }
	    else {
		push @rows, [ @$row ] while($row = $sth->fetch);
	    }
	}
	elsif ($mode eq 'HASH') {
	    $max_rows = -1 unless defined $max_rows;
	    if (keys %$slice) {
		my @o_keys = keys %$slice;
		my @i_keys = map { lc } keys %$slice;
                # XXX this could be made faster by pre-binding a local hash
                # using bind_columns and then copying it per row
		while ($max_rows-- and $row = $sth->fetchrow_hashref('NAME_lc')) {
		    my %hash;
		    @hash{@o_keys} = @{$row}{@i_keys};
		    push @rows, \%hash;
		}
	    }
	    else {
		# XXX assumes new ref each fetchhash
		push @rows, $row
		    while ($max_rows-- and $row = $sth->fetchrow_hashref());
	    }
	}
	else { Carp::croak("fetchall_arrayref($mode) invalid") }
	return \@rows;
    }

    sub fetchall_hashref {
	my ($sth, $key_field) = @_;

        my $hash_key_name = $sth->{FetchHashKeyName} || 'NAME';
        my $names_hash = $sth->FETCH("${hash_key_name}_hash");
        my @key_fields = (ref $key_field) ? @$key_field : ($key_field);
        my @key_indexes;
        my $num_of_fields = $sth->FETCH('NUM_OF_FIELDS');
        foreach (@key_fields) {
           my $index = $names_hash->{$_};  # perl index not column
           $index = $_ - 1 if !defined $index && DBI::looks_like_number($_) && $_>=1 && $_ <= $num_of_fields;
           return $sth->set_err($DBI::stderr, "Field '$_' does not exist (not one of @{[keys %$names_hash]})")
                unless defined $index;
           push @key_indexes, $index;
        }
        my $rows = {};
        my $NAME = $sth->FETCH($hash_key_name);
        my @row = (undef) x $num_of_fields;
        $sth->bind_columns(\(@row));
        while ($sth->fetch) {
            my $ref = $rows;
            $ref = $ref->{$row[$_]} ||= {} for @key_indexes;
            @{$ref}{@$NAME} = @row;
        }
        return $rows;
    }

    *dump_results = \&DBI::dump_results;

    sub blob_copy_to_file {	# returns length or undef on error
	my($self, $field, $filename_or_handleref, $blocksize) = @_;
	my $fh = $filename_or_handleref;
	my($len, $buf) = (0, "");
	$blocksize ||= 512;	# not too ambitious
	local(*FH);
	unless(ref $fh) {
	    open(FH, ">$fh") || return undef;
	    $fh = \*FH;
	}
	while(defined($self->blob_read($field, $len, $blocksize, \$buf))) {
	    print $fh $buf;
	    $len += length $buf;
	}
	close(FH);
	$len;
    }

    sub more_results {
	shift->{syb_more_results};	# handy grandfathering
    }

}

unless ($DBI::PurePerl) {   # See install_driver
    { @DBD::_mem::dr::ISA = qw(DBD::_mem::common);	}
    { @DBD::_mem::db::ISA = qw(DBD::_mem::common);	}
    { @DBD::_mem::st::ISA = qw(DBD::_mem::common);	}
    # DBD::_mem::common::DESTROY is implemented in DBI.xs
}

1;
__END__

#line 8282

#  LocalWords:  DBI
