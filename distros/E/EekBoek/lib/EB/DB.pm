#! perl --			-*- coding: utf-8 -*-

use utf8;

# Author          : Johan Vromans
# Created On      : Sat May  7 09:18:15 2005
# Last Modified By: Johan Vromans
# Last Modified On: Thu Aug 31 10:01:13 2017
# Update Count    : 457
# Status          : Unknown, Use with caution!

################ Common stuff ################

package main;

our $cfg;

package EB::DB;

use strict;
use warnings;

use EB;
use DBI;

my $dbh;			# singleton for DB

my $verbose = 0;
my $trace = 0;

################ high level ################

sub check_db {
    my ($self) = @_;

    my $fail = 0;

    # Check the existence of the required tables.
    my %tables = map { $_, 1 } @{$self->tablesdb};

    foreach my $table ( qw(constants standaardrekeningen verdichtingen accounts
			   relaties accounts boekstukken boekstukregels
			   btwtabel journal metadata) ) {
	next if $tables{$table};
	$fail++;
	 warn("?".__x("Tabel {table} ontbreekt in database {db}",
		      table => $table, db => $dbh->{Name}) . "\n");
    }
    warn(join(" ", sort keys %tables)."\n") if $fail;
    die("?".__x("Ongeldige EekBoek database: {db}.",
		db => $dbh->{Name}) . " " .
	_T("Wellicht is de database nog niet geïnitialiseerd?")."\n") if $fail;

    # Check version, and try automatic upgrade.
    my ($maj, $min, $rev)
      = @{$self->do("SELECT adm_scm_majversion, adm_scm_minversion, adm_scm_revision".
		    " FROM Metadata")};
    while ( !($maj == SCM_MAJVERSION &&
	      sprintf("%03d%03d", $min, $rev) eq sprintf("%03d%03d", SCM_MINVERSION, SCM_REVISION)) ) {
	# Basically, this will migrate to the highest possibly version, and then retry.
	my $cur = sprintf("%03d%03d%03d", $maj, $min, $rev);
	my $tmpl = libfile("migrate/$cur?????????.*l");
	my @a = reverse sort glob($tmpl);
	last unless @a == 1;

	if ( $a[0] =~ /\.sql$/ && open(my $fh, "<:encoding(utf-8)", $a[0])) {
	    warn("!"._T("De database wordt aangepast aan de nieuwere versie")."\n");

	    local($/);		# slurp mode
	    my $sql = <$fh>;	# slurp
	    close($fh);

	    require EB::Tools::SQLEngine;
	    eval {
		EB::Tools::SQLEngine->new(dbh => $self, trace => $trace)->process($sql);
	    };
	    warn("?".$@) if $@;
	    $dbh->rollback if $@;

	}
	elsif ( $a[0] =~ /\.pl$/ ) {
	    warn("!"._T("De database wordt aangepast aan de nieuwere versie")."\n");
	    my $sd = $::dbh;
	    $::dbh = $self;
	    eval { require $a[0] };
	    $::dbh = $sd;
	    warn("?".$@) if $@;
	}
	($maj, $min, $rev)
	  = @{$self->do("SELECT adm_scm_majversion, adm_scm_minversion, adm_scm_revision".
			" FROM Metadata")};
	die("?"._T("De migratie is mislukt. Gelieve de documentatie te raadplegen.")."\n")
	  if $cur eq sprintf("%03d%03d%03d", $maj, $min, $rev);
    }
    die("?".__x("Ongeldige EekBoek database: {db} versie {ver}.".
		" Benodigde versie is {req}.",
		db => $dbh->{Name}, ver => "$maj.$min.$rev",
		req => join(".", SCM_MAJVERSION, SCM_MINVERSION, SCM_REVISION)) . "\n")
      unless $maj == SCM_MAJVERSION &&
	sprintf("%03d%03d", $min, $rev) eq sprintf("%03d%03d", SCM_MINVERSION, SCM_REVISION);

    # Verify koppelingen.
    for ( $self->std_acc("deb", undef) ) {
	next unless defined;
	my $rr = $self->do("SELECT acc_debcrd, acc_balres FROM Accounts where acc_id = ?", $_);
	$fail++, warn("?".__x("Geen grootboekrekening voor {dc} ({acct})",
			      dc => _T("Debiteuren"), acct => $_)."\n")
	  unless $rr;
	# $fail++,
	warn("?".__x("Foutieve grootboekrekening voor {dc} ({acct})",
		     dc => _T("Debiteuren"), acct => $_)."\n")
	  unless $rr->[0] && $rr->[1];
    }

    for ( $self->std_acc("crd", undef) ) {
	next unless defined;
	my $rr = $self->do("SELECT acc_debcrd, acc_balres FROM Accounts where acc_id = ?", $_);
	$fail++, warn("?".__x("Geen grootboekrekening voor {dc} ({acct})",
			      dc => _T("Crediteuren"), acct => $_)."\n")
	  unless $rr;
	# $fail++,
	warn("?".__x("Foutieve grootboekrekening voor {dc} ({acct})",
		     dc => _T("Crediteuren"), acct => $_)."\n")
	  if $rr->[0] || !$rr->[1];
    }

    for ( $self->std_acc("btw_ok", undef) ) {
	next unless defined;
	my $rr = $self->do("SELECT acc_balres FROM Accounts where acc_id = ?", $_);
	$fail++, warn("?".__x("Geen grootboekrekening voor {dc} ({acct})",
			      dc => _T("BTW betaald"), acct => $_)."\n")
	  unless $rr;
	warn("?".__x("Foutieve grootboekrekening voor {dc} ({acct})",
		     dc => _T("BTW betaald"), acct => $_)."\n")
	  unless $rr->[0];
    }

    for ( $self->std_acc("winst") ) {
	my $rr = $self->do("SELECT acc_balres FROM Accounts where acc_id = ?", $_);
	$fail++, warn("?".__x("Geen grootboekrekening voor {dc} ({acct})",
			      dc => _T("overboeking winst"), acct => $_)."\n")
	  unless $rr;
	warn("?".__x("Foutieve grootboekrekening voor {dc} ({acct})",
		     dc => _T("overboeking winst"), acct => $_)."\n")
	  unless $rr->[0];
    }

    die("?"._T("CONSISTENTIE-VERIFICATIE STANDAARDREKENINGEN MISLUKT")."\n") if $fail;

    $self->setup;
}

sub setup {
    my ($self) = @_;

    $dbh->begin_work;

    setupdb();

    # Create temp table for account mangling.
    # This table has the purpose of copying the data from Accounts, so that
    # data from already completed financial years can be corrected when
    # creating overviews, such as Balance statements and Result accounts.
    # This way no backdated calculations need to be made when transitions
    # to previous financial years are involved.
    my $sql = "SELECT * INTO TEMP TAccounts FROM Accounts WHERE acc_id = 0";
    $sql = $self->feature("filter")->($sql) if $self->feature("filter");
    $dbh->do($sql) if $sql;

    # Make it semi-permanent (this connection only).
    $dbh->commit;
}

#### UNUSED
sub upd_account {
    my ($self, $acc, $amt) = @_;
    my $op = '+';		# perfectionism
    if ( $amt < 0 ) {
	$amt = -$amt;
	$op = '-';
    }
    $self->sql_exec("UPDATE Accounts".
		    " SET acc_balance = acc_balance $op ?".
		    " WHERE acc_id = ?",
		    $amt, $acc);
}

sub store_journal {
    my ($self, $jnl) = @_;
    foreach ( @$jnl ) {
	$self->sql_insert("Journal",
			  [qw(jnl_date jnl_dbk_id jnl_bsk_id jnl_bsr_date jnl_bsr_seq jnl_seq
			      jnl_type jnl_acc_id jnl_amount
			      jnl_damount jnl_desc jnl_rel jnl_rel_dbk  jnl_bsk_ref)],
			  @$_);
    }
}

sub bskid {
    my ($self, $nr, $bky) = @_;
    return $nr if $nr =~ /^\d+$/ && !wantarray;

    # Formats:
    #   NNN
    #   DBK:NNN
    #   DBK:BKY:NNN
    #   REL:REF
    #   REL:BKY:REF

    my $rr;
    $bky = $self->adm("bky") unless defined($bky);

    if ( $nr =~ /^([[:alpha:]][^:]+)(?::([^:]+))?:(.*?\D.*)$/
	 and
	 $rr = $self->do("SELECT rel_code, rel_desc".
			 " FROM Relaties".
			 " WHERE upper(rel_code) = ?", uc($1)) ) {
	my ($rel_id, $rel_desc) = @$rr;
	if ( defined($2) ) {
	    unless ( defined $self->lookup($2, qw(Boekjaren bky_code bky_code)) ) {
		return wantarray ? (undef, undef, __x("Onbekend boekjaar: {bky}", bky => $2)) : undef;
	    }
	    $bky = $2;
	}
	$rr = $self->do("SELECT bsk_id, bsk_dbk_id".
			" FROM Boekstukken, Boekstukregels".
			" WHERE bsr_rel_code = ?".
			" AND bsr_bsk_id = bsk_id".
			" AND upper(bsk_ref) = ?".
			" AND bsk_bky = ?", $rel_id, uc($3), $bky);
	unless ( $rr ) {
	    return wantarray ? (undef, undef, __x("Onbekend boekstuk {ref} voor relatie {rel} ({desc})",
						  rel => $rel_id, desc => $rel_desc, ref => $3)) : undef;
	}
	$bky = $bky eq $self->adm("bky") ? "" : ":$bky";
	return wantarray ? ($rr->[0], $self->lookup($rr->[1], qw(Dagboeken dbk_id dbk_desc))."$bky:$3", undef) : $rr->[0];
    }

    if ( $nr =~ /^([[:alpha:]][^:]+)(?::([^:]+))?:(\d+)$/ ) {
	$rr = $self->do("SELECT dbk_id, dbk_desc".
			" FROM Dagboeken".
			" WHERE upper(dbk_desc) LIKE ?", uc($1));
	unless ( $rr ) {
	    return wantarray ? (undef, undef, __x("Onbekend dagboek: {dbk}", dbk => $1)) : undef;
	}
	my ($dbk_id, $dbk_desc) = @$rr;
	if ( defined($2) ) {
	    unless ( defined $self->lookup($2, qw(Boekjaren bky_code bky_code)) ) {
		return wantarray ? (undef, undef, __x("Onbekend boekjaar: {bky}", bky => $2)) : undef;
	    }
	    $bky = $2;
	}
	$rr = $self->do("SELECT bsk_id".
			" FROM Boekstukken".
			" WHERE bsk_nr = ?".
			" AND bsk_bky = ?".
			" AND bsk_dbk_id = ?", $3, $bky, $dbk_id);
	unless ( $rr ) {
	    return wantarray ? (undef, undef, __x("Onbekend boekstuk {bsk} in dagboek {dbk}",
						  dbk => $dbk_desc, bsk => $3)) : undef;
	}
	$bky = $bky eq $self->adm("bky") ? "" : ":$bky";
	return wantarray ? ($rr->[0], "$dbk_desc$bky:$3", undef) : $rr->[0];
    }

    if ( $nr =~ /^(\d+)$/ ) {

	$rr = $self->do("SELECT bsk_nr, dbk_id, dbk_desc, bsk_bky".
			" FROM Boekstukken, Dagboeken".
			" WHERE bsk_dbk_id = dbk_id".
			" AND bsk_id = ?", $nr);
	unless ( $rr ) {
	    return wantarray ? (undef, undef, __x("Onbekend boekstuk: {bsk}",
						  bsk => $nr)) : undef;
	}
	my ($bsk_nr, $dbk_id, $dbk_desc, $bsk_bky) = @$rr;
	$bsk_nr =~ s/\s+$//;
	$bky = $bsk_bky eq $self->adm("bky") ? "" : ":$bsk_bky";
	return wantarray ? ($nr, "$dbk_desc$bky:$bsk_nr", undef) : $nr;
    }

    die("?".__x("Ongeldige boekstukaanduiding: {bsk}", bsk => $nr)."\n");
}

################ low level ################

sub new {
    my ($pkg, %atts) = @_;
    $pkg = ref($pkg) || $pkg;

    $verbose = delete($atts{verbose}) || 0;
    $trace   = delete($atts{trace}) || 0;

    my $self = {};
    bless $self, $pkg;
    $self->_init;
    $self;
}

sub _init {
    my ($self) = @_;
}

my %adm;
sub adm {
    my ($self, $name, $value, $notx) = @_;
    if ( $name eq "" ) {
	%adm = ();
	return;
    }
    unless ( %adm ) {
	$self->connectdb;
	my $sth = $self->sql_exec("SELECT *".
				  " FROM Metadata, Boekjaren".
				  " WHERE adm_bky = bky_code");
	my $rr = $sth->fetchrow_hashref;
	$sth->finish;
	while ( my($k,$v) = each(%$rr) ) {
	    my $k1 = $k;
	    $k =~ s/^(adm|bky)_//;
	    $adm{lc($k)} = [$k1, $v];
	}
    }
    exists $adm{lc($name)} || die("?".__x("Niet-bestaande administratie-eigenschap: {adm}",
					  adm => $name)."\n");
    $name = lc($name);

    if ( @_ >= 3 ) {
	$self->begin_work unless $notx;
	$self->sql_exec("UPDATE Metadata".
			" SET ".$adm{$name}->[0]." = ?", $value)->finish;
	$self->commit unless $notx;
	$adm{$name}->[1] = $value;
    }
    else {
	defined $adm{$name} ? $adm{$name}->[1] : "";
    }
}

sub dbver {
    my ($self) = @_;
    sprintf("%03d%03d%03d", $self->adm("scm_majversion"),
	    $self->adm("scm_minversion")||0, $self->adm("scm_revision"));

}

my %std_acc;
my @std_acc;
sub std_acc {
    my ($self, $name, $def) = @_;
    if ( $name eq "" ) {
	%std_acc = ();
	@std_acc = ();
	return;
    }
    $self->std_accs unless %std_acc;
    return $std_acc{lc($name)} if defined($std_acc{lc($name)});
    return $def if @_ > 2;
    die("?".__x("Niet-bestaande standaardrekening: {std}", std => $name)."\n");
}

sub std_accs {
    my ($self) = @_;
    unless ( @std_acc ) {
	$self->connectdb;
	my $sth = $self->sql_exec("SELECT * FROM Standaardrekeningen");
	my $rr = $sth->fetchrow_hashref;
	$sth->finish;
	while ( my($k,$v) = each(%$rr) ) {
	    next unless defined $v;
	    $k =~ s/^std_acc_//;
	    $std_acc{lc($k)} = $v;
	}
	@std_acc = sort(keys(%std_acc));
    }
    \@std_acc;
}

my $accts;
sub accts {
    my ($self, $sel) = @_;
    $sel = $sel ? " WHERE $sel" : "";
    return $accts->{$sel} if $accts->{$sel};
    my $sth = $self->sql_exec("SELECT acc_id,acc_desc".
			      " FROM Accounts".
			      $sel.
			      " ORDER BY acc_id");
    my $rr;
    while ( $rr = $sth->fetchrow_arrayref ) {
	$accts->{$sel}->{$rr->[0]} = $rr->[1];
    }
    $accts->{$sel};
}

sub acc_inuse {
    my ($dbh, $acc) = @_;

    my $rr;
    $rr = $dbh->do("SELECT jnl_acc_id FROM Journal".
		   " WHERE jnl_acc_id = ?".
		   " LIMIT 1", $acc);
    return 1 if $rr && $rr->[0];

    $rr = $dbh->do("SELECT dbk_acc_id FROM Dagboeken".
		   " WHERE dbk_acc_id = ?".
		   " LIMIT 1", $acc);
    return 1 if $rr && $rr->[0];

    $rr = $dbh->do("SELECT rel_acc_id FROM Relaties".
		   " WHERE rel_acc_id = ?".
		   " LIMIT 1", $acc);
    return 1 if $rr && $rr->[0];

    $rr = $dbh->do("SELECT bkb_acc_id FROM Boekjaarbalans".
		   " WHERE bkb_acc_id = ?",
		   $acc);
    return 1 if $rr && $rr->[0];

    if ( $rr = $dbh->do("SELECT * FROM Standaardrekeningen") ) {
	for ( @$rr ) {
	    return 1 if defined($_) && $_ == $acc;
	}
    }

    return;
}

sub dbh{
    $dbh;
}

sub adm_open {
    my ($self) = @_;
    $self->connectdb;
    $self->adm("bky") ne BKY_PREVIOUS;
}

sub adm_busy {
    my ($self) = @_;
    $self->connectdb;
    $self->do("SELECT COUNT(*) FROM Journal")->[0];
}

sub does_btw {
    my ($self) = @_;
    $self->connectdb;
    return defined($self->adm("btwbegin")) if $self->adm_open;
    $self->do("SELECT COUNT(*)".
	      " FROM BTWTabel".
	      " WHERE btw_tariefgroep != 0")->[0];
}

################ API calls for simple applications ################

sub connect {
    my $dataset = $cfg->val(qw(database name));
    if ( !$dataset ) {
	die(_T("Geen dataset opgegeven.".
	       " Specificeer een dataset in de configuratiefile.").
	    "\n");
    }
    $::dbh = EB::DB::->new();
}

sub disconnect {
    $::dbh->disconnectdb;
    undef $::dbh;
}

################ API calls for database backend ################

my $tx;

my $dbpkg;

sub connectdb {
    my ($self, $nocheck) = @_;

    return $dbh if $dbh;
    my $pkg = $dbpkg || $self->_loaddbbackend;
    my $dbname = $cfg->val(qw(database name));
    croak("?INTERNAL ERROR: No database name") unless defined $dbname;
    eval {
	$dbh = $pkg->connect($dbname)
	  or die("?".__x("Database verbindingsprobleem: {err}",
			 err => $DBI::errstr)."\n");
    };
    die($@) if $@;
    $dbpkg = $pkg;
    $dbh->{RaiseError} = 1;
    #$dbh->{AutoCommit} = 0;
    $dbh->{ChopBlanks} = 1;
    $self->check_db unless $nocheck;
    $tx = 0;
    $dbh;
}

sub disconnectdb {
    my ($self) = shift;
    return unless $dbpkg;
    return unless $dbh;
    resetdbcache($self);
    $dbpkg->disconnect;
    $tx = 0;
    undef $dbh;
}

sub feature {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->feature(@_);
}

sub setupdb {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->setup;
}

sub listdb {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->list;
}

sub tablesdb {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->get_tables;
}

sub cleardb {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $self->resetdbcache;
    $dbpkg->clear;
}

sub createdb {
    my ($self, $dbname) = @_;
    $dbpkg ||= $self->_loaddbbackend;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    $self->resetdbcache;
    $dbpkg->create($dbname);
}

sub driverdb {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->type;
}

sub isql {
    my ($self) = shift;
    $dbpkg ||= $self->_loaddbbackend;
    $dbpkg->isql(@_);
}

sub get_sequence {
    my ($self) = shift;
    warn("=> GET-SEQUENCE ", $_[0], "\n") if $trace;
    $self->connectdb;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    Carp::croak("INTERNAL ERROR: get_sequence takes only one argument") if @_ != 1;
    $dbpkg->get_sequence(@_);
}

sub set_sequence {
    my ($self) = shift;
    warn("=> SET-SEQUENCE ", $_[0], " TO ", $_[1], "\n") if $trace;
    $self->connectdb;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    $dbpkg->set_sequence(@_);
}

sub store_attachment {
    my ($self) = shift;
    warn("=> STORE-ATTACHMENT ", $_[0], "\n") if $trace;
    $self->connectdb;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    Carp::croak("INTERNAL ERROR: store_attachment takes one argument") if @_ != 1;
    $dbpkg->store_attachment(@_);
}

sub get_attachment {
    my ($self) = shift;
    warn("=> GET-ATTACHMENT ", $_[0], "\n") if $trace;
    $self->connectdb;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    Carp::croak("INTERNAL ERROR: get_attachment takes one or two arguments") if @_ < 1 || @_ > 2;
    $dbpkg->get_attachment(@_);
}

sub drop_attachment {
    my ($self) = shift;
    warn("=> DROP-ATTACHMENT ", $_[0], "\n") if $trace;
    $self->connectdb;
    Carp::confess("DB backend setup failed") unless $dbpkg;
    Carp::croak("INTERNAL ERROR: get_attachment takes only one argument") if @_ != 1;
    $dbpkg->drop_attachment(@_);
}

sub _loaddbbackend {
    my ($self) = @_;
    my $dbtype = $cfg->val(qw(database driver), "sqlite");

    # Trim whitespace for stupid users.
    for ( $dbtype ) {
	s/^\s+//;
	s/\s+$//;
    }

    my $pkg = __PACKAGE__ . "::" . ucfirst(lc($dbtype));
    my $pkgfile = __PACKAGE__ . "::" . ucfirst(lc($dbtype)) . ".pm";
    $pkgfile =~ s/::/\//g;
    eval { require $pkgfile };
    die("?".__x("Geen ondersteuning voor database type {db}",
		db => $dbtype)."\n$@") if $@;
    #Carp::cluck("Returning: $pkg");
    return $pkg;
}

################ End API calls for database backend ################

sub trace {
    my ($self, $value) = @_;
    my $cur = $trace;
    $trace = !$trace, return $cur unless defined $value;
    $trace = $value;
    $cur;
}

sub sql_insert {
    my ($self, $table, $columns, @args) = @_;
    $self->sql_exec("INSERT INTO $table ".
		    "(" . join(",", @$columns) . ") ".
		    "VALUES (" . join(",", ("?") x @$columns) . ")",
		    @args);
}

my %sth;
my $sql_prep_cache_hits;
my $sql_prep_cache_miss;
sub sql_prep {
    my ($self, $sql) = @_;
    $dbh ||= $self->connectdb();
    $sql = $self->feature("filter")->($sql) if $self->feature("filter");
    return $dbh->prepare($sql) unless $self->feature("prepcache");
    if ( defined($sth{$sql}) ) {
	$sql_prep_cache_hits++;
	return $sth{$sql};
    }
    $sql_prep_cache_miss++;
    $sth{$sql} = $dbh->prepare($sql);
}

sub prepstats {
    warn("SQL Prep Cache: number of hits = ",
	 $sql_prep_cache_hits || 0, ", misses = ",
	 $sql_prep_cache_miss || 0, "\n")
      if %sth && $cfg->val("internal sql", qw(prepstats), 0);
}

sub resetdbcache {
    my ($self) = @_;
    %sth = ();
    return unless $self;
    $self->std_acc("");
    $self->adm("");
}

sub show_sql($$@) {
    my ($self, $sql, @args) = @_;
    my @a = map {
	!defined($_) ? "NULL" :
	  /^[0-9]+$/ ? $_ : $dbh->quote($_)
      } @args;
    $sql =~ s/\?/shift(@a)/eg;
    warn("=> $sql;\n");
}

sub sql_exec {
    my ($self, $sql, @args) = @_;
    $dbh ||= $self->connectdb();
    $self->show_sql($sql, @args) if $trace;
    checktx($sql);
    my $sth = $self->sql_prep($sql);
    $sth->execute(@args);
    $sth;
}

sub lookup($$$$$;$) {
    my ($self, $value, $table, $arg, $res, $op) = @_;
    $op ||= "=";
    my $sth = $self->sql_exec("SELECT $res FROM $table".
			      " WHERE $arg $op ?", $value);
    my $rr = $sth->fetchrow_arrayref;
    $sth->finish;

    return ($rr && defined($rr->[0]) ? $rr->[0] : undef);

}

sub get_value {
    my ($self, $column, $table) = @_;
    my $sth = $self->sql_exec("SELECT $column FROM $table");
    my $rr = $sth->fetchrow_arrayref;
    $sth->finish;

    return ($rr && defined($rr->[0]) ? $rr->[0] : undef);
}

sub do {
    my $self = shift;
    my $sql = shift;
    my $atts = ref($_[0]) eq 'HASH' ? shift : undef;
    my @args = @_;
    my $sth = $self->sql_exec($sql, @args);
    my $rr = $sth->fetchrow_arrayref;
    $sth->finish;
    $rr;
}

sub da {			# do_all
    my $self = shift;
    my $sql = shift;
    my $atts = ref($_[0]) eq 'HASH' ? shift : undef;
    my @args = @_;
    my $sth = $self->sql_exec($sql, @args);
    my $res;
    while ( my $rr = $sth->fetchrow_arrayref ) {
	push( @$res, [@$rr] );
    }
    $sth->finish;
    $res;
}

sub errstr {
    $dbh->errstr;
}

sub in_transaction {
    my $self = shift;
    $tx;
}

sub checktx {
    my ($sql, $allow) = @_;
    return if $tx;
    $sql =~ /^\s*(\w+)\s+(\S+)/i;
    my $cmd = $1 ? uc($1) : die("?INTERNAL ERROR: Invalid SQL command: $sql\n");
    return if $cmd eq "SELECT";
    my $msg = "INTERNAL ERROR: $cmd $2 while not in transaction";
    $allow ? warn("!$msg\n") : die("?$msg\n");
}

#
# http://en.wikipedia.org/wiki/Database_transaction#In_SQL 

sub begin_work {
    my ($self) = @_;
    warn("=> BEGIN WORK;", $dbh ? "" : " (ignored)", "\n") if $trace;
    return unless $dbh;
    die("?INTERNAL ERROR: BEGIN WORK while in transaction\n") if $tx++;
    $dbh->begin_work;
}

sub commit {
    my ($self) = @_;
    warn("=> COMMIT WORK;", $dbh ? "" : " (ignored)", "\n") if $trace;
    return unless $dbh;
    die("?INTERNAL ERROR: COMMIT while not in transaction\n") unless $tx;
    $tx = 0;
    $dbh->commit;
}

sub rollback {
    my ($self) = @_;
    warn("=> ROLLBACK WORK;", $dbh ? "" : " (ignored)", "\n") if $trace;
    return unless $dbh;
    die("?INTERNAL ERROR: ROLLBACK while not in transaction\n") unless $tx;
    $tx = 0;
    $dbh->rollback
}

END {
    prepstats();
    disconnectdb();
}

1;
