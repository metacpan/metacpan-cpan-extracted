package LMDB_File;

use 5.010000;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our $VERSION = '0.12';
our $DEBUG = 0;

our @ISA = qw(Exporter);
our @CARP_NOT = qw(LMDB::Env LMDB::Txn LMDB::Cursor LMDB_File);

our @EXPORT = qw();
our %EXPORT_TAGS = (
    envflags => [qw(MDB_FIXEDMAP MDB_NOSUBDIR MDB_NOSYNC MDB_RDONLY MDB_NOMETASYNC
	MDB_NOMEMINIT MDB_WRITEMAP MDB_MAPASYNC MDB_NOTLS MDB_NOLOCK MDB_NORDAHEAD)],
    dbflags => [qw(MDB_REVERSEKEY MDB_DUPSORT MDB_INTEGERKEY MDB_DUPFIXED
	MDB_INTEGERDUP MDB_REVERSEDUP MDB_CREATE)],
    writeflags => [qw(MDB_NOOVERWRITE MDB_NODUPDATA MDB_CURRENT MDB_RESERVE
	MDB_APPEND MDB_APPENDDUP MDB_MULTIPLE)],
    cursor_op => [qw(MDB_FIRST MDB_FIRST_DUP MDB_GET_BOTH MDB_GET_BOTH_RANGE
	MDB_GET_CURRENT MDB_GET_MULTIPLE MDB_NEXT MDB_NEXT_DUP MDB_NEXT_MULTIPLE
	MDB_NEXT_NODUP MDB_PREV MDB_PREV_DUP MDB_PREV_NODUP MDB_LAST MDB_LAST_DUP
	MDB_SET MDB_SET_KEY MDB_SET_RANGE)],
    copyflags => [qw(MDB_CP_COMPACT)],
    error => [qw(MDB_SUCCESS MDB_KEYEXIST MDB_NOTFOUND MDB_PAGE_NOTFOUND MDB_CORRUPTED
	MDB_PANIC MDB_VERSION_MISMATCH MDB_INVALID MDB_MAP_FULL MDB_DBS_FULL
	MDB_READERS_FULL MDB_TLS_FULL MDB_TXN_FULL MDB_CURSOR_FULL MDB_PAGE_FULL
	MDB_MAP_RESIZED MDB_INCOMPATIBLE MDB_BAD_RSLOT MDB_BAD_TXN MDB_BAD_VALSIZE
	MDB_BAD_DBI MDB_LAST_ERRCODE)],
    version => [qw(MDB_VERSION_FULL MDB_VERSION_MAJOR MDB_VERSION_MINOR
	MDB_VERSION_PATCH MDB_VERSION_STRING MDB_VERSION_DATE)],
);
$EXPORT_TAGS{flags} = [
    @{$EXPORT_TAGS{envflags}}, @{$EXPORT_TAGS{dbflags}},
    @{$EXPORT_TAGS{writeflags}}, @{$EXPORT_TAGS{copyflags}}
];
{
    my %seen;
    push @{$EXPORT_TAGS{all}},
	grep {!$seen{$_}++} @{$EXPORT_TAGS{$_}} foreach keys %EXPORT_TAGS;
}
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

sub AUTOLOAD {
    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&LMDB_File::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('LMDB_File', $VERSION);

my $dbflmask = do {
    no strict 'refs';
    my $f = 0;
    $f |= &{"LMDB_File::$_"}() for @{$EXPORT_TAGS{dbflags}};
    $f;
};

package LMDB::Env;
use Scalar::Util ();
use Fcntl;

our %Envs;
sub new {
    my ($proto, $path, $eflags) = @_;
    create(my $self);
    return unless $self;
    $eflags = { flags => ($eflags || 0) } unless ref $eflags;
    $eflags->{mapsize} and $self->set_mapsize($eflags->{mapsize})
	and return;
    $eflags->{maxdbs} and $self->set_maxdbs($eflags->{maxdbs})
	and return;
    $eflags->{maxreaders} and $self->set_maxreaders($eflags->{maxreaders})
	and return;
    if($^O =~ /openbsd/) {
	# OpenBSD lacks an unified buffer cache (UBC) so LMDB only works
	# with MDB_WRITEMAP set when not in read-only mode
	$eflags->{flags} |= LMDB_File::MDB_WRITEMAP()
	    unless $eflags->{flags} & LMDB_File::MDB_RDONLY();
    }
    $self->open($path, $eflags->{flags}, $eflags->{mode} || 0600)
	and return;
    warn "Created LMDB::Env $$self\n" if $DEBUG;
    return $self;
}

sub Clean {
    my $self = shift;
    my $txl = $Envs{ $$self }[0] or return;
    if(@$txl) {
	Carp::carp("LMDB: Aborting $#$txl transactions in $$self.");
	$txl->[$#$txl]->abort;
    }
    $Envs{ $$self }[0] = [];
}

sub DESTROY {
    my $self = shift;
    my $txl = $Envs{ $$self } && $Envs{ $$self }[0];
    if($txl and @$txl and my $topTxn = $txl->[$#$txl]) {
	# As every Txn references its Env this is only possible at global destruction
        Carp::carp("LMDB: OOPS! Destroying an active environment!");
        warn("LMDB: Aborting $#$txl transactions in $$self.") if $DEBUG;
        $topTxn->abort;
    }
    $self->close;
    warn "Closed LMDB::Env $$self (remains @{[scalar keys %Envs]})\n"
	if $DEBUG;
}

sub BeginTxn {
    my $self = shift;
    $self->get_flags(my $eflags);
    my $tflags = shift || ($eflags & LMDB_File::MDB_RDONLY());
    my $txl = $Envs{ $$self }[0];
    warn "BeginTxn $$self($$), deep: ", scalar(@$txl), "\n" if $DEBUG;
    return $txl->[0]->SubTxn($tflags) if @$txl;
    LMDB::Txn->new($self, $tflags);
}

sub CLONE {
    # After a thread is created all Txns of parent thread are forgot
    $_->[0] = [] for values %Envs;
    _clone();
    1;
}

package LMDB::Txn;

our %Txns;
my %Cursors;

sub new {
    my ($parent, $env, $tflags) = @_;
    my $txl = $Envs{ $$env }[0];
    Carp::croak("Transaction active, should be subtransaction")
	if !ref($parent) && @$txl;
    _begin($env, ref($parent) && $parent, $tflags, my $self);
    return unless $self;
    $Txns{$$self} = {
	Active => 1,
	Env => $env, # A transaction references the environment
	RO  => $tflags & LMDB_File::MDB_RDONLY(),
    };
    unshift @$txl, $self;
    Scalar::Util::weaken($txl->[0]);
    warn "Created LMDB::Txn $$self in $$env\n" if $DEBUG;
    return $self;
}

sub SubTxn {
    my $self = shift;
    if($^O =~ /openbsd/) {
	# Needs MDB_WRITEMAP so
	Carp::croak("Subtransactions are unsupported in this OS");
    }
    my $tflags = shift || 0;
    return $self->new($self->env, $tflags);
}

sub DESTROY {
    my $self = shift;
    my $td = $Txns{ $$self } or return;
    if($td->{Active} && !$td->{RO} && $td->{AC}) {
	warn "LMDB: Destroying an active transaction, commiting $$self...\n"
	    if $DEBUG;
	$self->commit;
    } else {
	warn "LMDB: Destroying an active transaction, aborting $$self...\n"
	    if $DEBUG;
	$self->abort;
    }
}

sub _prune {
    my $self = shift;
    my $eid = shift;
    if(my $txl = $Envs{ $eid } && $Envs{ $eid }[0]) {
	while(my $rel = shift @$txl) {
	    my $td =  delete $Txns{ $$rel };
	    delete $Cursors{$_} for keys %{ $td->{Cursors} };
	    last if $$rel == $$self;
	}
	warn "LMDB::Txn: Txns list deep: @{[scalar @$txl]}\n" if $DEBUG > 2;
    }
    warn "LMDB::Txn: $$self($$) finalized in $eid\n" if $DEBUG > 1;
    $$self = 0;
}

sub abort {
    my $self = shift;
    unless($Txns{ $$self }) {
	Carp::carp("Terminated transaction");
	return;
    }
    my $eid = $self->_env;
    $self->_abort;
    warn "LMDB::Txn $$self aborted\n" if $DEBUG;
    $self->_prune($eid);
}

sub commit {
    my $self = shift;
    my $td = $Txns{ $$self } or Carp::croak("Terminated transaction");
    Carp::croak("Not an active transaction") unless $td->{Active};
    my $eid = $self->_env;
    $self->_commit;
    warn "LMDB::Txn $$self commited\n" if $DEBUG;
    $self->_prune($eid);
}

sub Flush {
    my $self = shift;
    my $td = $Txns{ $$self } or Carp::croak("Terminated transaction");
    Carp::croak("Not an active transaction") unless $td->{Active};
    $self->_commit;
    # This depends on malloc order, beware!
    _begin($td->{Env}, undef, $td->{RO}, my $ntxn);
    Carp::croak("Can't recreate Txn") unless $$ntxn == $$self;
    $$ntxn = 0;
}

sub reset {
    my $self = shift;
    my $td = $Txns{ $$self } or Carp::croak("Terminated transaction");
    Carp::croak("Not a read-only transaction") unless $td->{RO};
    $self->_reset if $td->{Active};
    $td->{Active} = 0;
}

sub renew {
    my $self = shift;
    my $td = $Txns{ $$self } or Carp::croak("Terminated transaction");
    $self->_reset if $td->{Active};
    $self->_renew;
    $td->{Active} = 1;
}

sub OpenDB {
    my ($self, $name, $flags) = @_;
    my $options = ref($name) eq 'HASH' ? $name : { dbname => $name, flags => $flags };
    LMDB_File->open($self, $options->{dbname}, $options->{flags});
}

sub env {
    my $self = shift;
    $Txns{$$self} && $Txns{$$self}{Env};
}

sub AutoCommit {
    my $self = shift;
    my $td = $Txns{ $$self } or Carp::croak("Terminated transaction");
    my $prev = $td->{AC};
    $td->{AC} = shift if(@_);
    $prev;
}

# Fast low-level dbi API
sub open {
    my($txn, $name, $flags) = @_;
     $flags ||= 0;
    Carp::croak("Not an alive transaction") unless $Txns{ $$txn };
    Carp::croak("Not the current child transaction")
	unless(${$Envs{ $txn->_env }[0][0]} == $$txn);
    _dbi_open($txn, $name, $flags & $dbflmask, my $dbi);
    warn "Opened dbi $dbi\n" if $dbi && $DEBUG;
    return $dbi;
}
*get = \&LMDB_File::_get;
*put = \&LMDB_File::_put;
*del = \&LMDB_File::_del;

sub CLONE_SKIP {
    # All LMDB Transactions are usable only in the thread that create it
    1;
}

package LMDB::Cursor;

sub get {
    LMDB_File::_chkalive($Cursors{${$_[0]}});
    goto &_get;
}

sub put {
    LMDB_File::_chkalive($Cursors{${$_[0]}});
    goto &_put;
}

sub del {
    LMDB_File::_chkalive($Cursors{${$_[0]}});
    goto &_del;
}

sub DESTROY {
    my $self = shift;
    return unless $Cursors{$$self};
    my $txnId = $self->txn;
    $self->close;
    delete $Txns{$txnId}{Cursors}{$$self};
    delete $Cursors{$$self};
}

package LMDB_File;
sub CLONE_SKIP { 1; }

our $die_on_err = 1;
our $last_err = 0;

sub new {
    my($proto, $txn, $dbi) = @_;
    Carp::croak("Need a Txn") unless $txn->isa('LMDB::Txn');
    bless [ $txn, $dbi ], ref($proto) || $proto;
}

sub open {
    my $proto = shift;
    my $class = ref $proto;
    my $txn = $class ? $proto->[0] : shift;
    Carp::croak("Need a Txn") unless $txn->isa('LMDB::Txn');
    my $dbi = $txn->open(@_) or return;
    bless [ $txn, $dbi ], $class || $proto;
}

sub DESTROY {
    my $self = shift;
}

sub _chkalive {
    my $self = shift;
    my $txn = $self->[0];
    Carp::croak("Not an active transaction")
	unless($txn && ($Txns{ $$txn } || undef $self->[0]) && $Txns{ $$txn }{Active} );
    # A parent transaction and its cursors may not issue any other operations than
    # mdb_txn_commit and mdb_txn_abort while it has active child transactions.
    Carp::croak("Not the current child transaction")
	unless(${$Envs{ $txn->_env }[0][0]} == $$txn);
    $txn, $self->[1];
}

sub Alive {
    my $self = shift;
    my $txn = $self->[0];
    $txn && (($Txns{ $$txn } && $self->[1]) || undef $self->[0]);
}

sub flags {
    my $self = shift;
    _dbi_flags(_chkalive($self), my $flags);
    $flags;
}

sub put {
    my $self = shift;
    warn "put: '$_[0]' => '$_[1]'\n" if $DEBUG > 2;
    _put(_chkalive($self), @_);
    $_[1];
}

sub get {
    warn "get: '$_[1]'\n" if $DEBUG > 2;
    my($txn, $dbi) = _chkalive($_[0]);
    return _get($txn, $dbi, $_[1], $_[2]) if @_ > 2;
    my($res, $data);
    {
	local $die_on_err = 0;
	$res = _get($txn, $dbi, $_[1], $data);
    }
    croak($@) if $res && $die_on_err && $res != MDB_NOTFOUND() or undef $@;
    $data;
}

sub Rget {
    warn "get: '$_[1]'\n" if $DEBUG > 2;
    local $die_on_err = 0;
    _get(_chkalive($_[0]), $_[1], my $data);
    return \$data;
}


sub del {
    _del(_chkalive($_[0]), $_[1], $_[2]);
}

sub stat {
    _stat(_chkalive($_[0]));
}

sub set_dupsort {
    my $self = shift;
    my $txn = $self->[0];
    $Envs{ $txn->_env }[1][ $self->[1] ] = shift;
}

sub set_compare {
    my $self = shift;
    my $txn = $self->[0];
    $Envs{ $txn->_env }[2][ $self->[1] ] = shift;
}

sub Cursor {
    my $DB = shift;
    my ($txn, $dbi) = _chkalive($DB);
    LMDB::Cursor::open($txn, $dbi, my $cursor);
    return unless $cursor;
    $Txns{$$txn}{Cursors}{$$cursor} = 1;
    $Cursors{$$cursor} = $DB;
    warn "Cursor opened for #$dbi\n" if $DEBUG;
    $cursor;
}

sub Txn : lvalue { $_[0][0]; }

sub dbi : lvalue { $_[0][1]; }

sub drop {
    _drop(_chkalive($_[0]), $_[1] || 0);
}

sub TIEHASH {
    my $proto = shift;
    return $proto if ref($proto) && _chkalive($proto); # Auto
    my $mux = shift;
    my $options = shift;
    $options = { flags => $options } unless ref $options; # DBM Compat
    my $txn;
    if(ref $mux eq 'LMDB::Txn') {
	$txn = $mux;
    } elsif(ref $mux eq 'LMDB::Env') {
	$txn = $mux->BeginTxn;
	$txn->AutoCommit(1);
    } else { # mux is dir
	$options->{mode} = shift if @_; # DBM Compat
	$txn = LMDB::Env->new($mux, $options)->BeginTxn;
	$txn->AutoCommit(1);
    }
    $txn->OpenDB($options);
}

sub FETCH {
    my($self, $key) = @_;
    my ($data, $res);
    {
	local $die_on_err = 0;
	$res = _get(_chkalive($self), $key, $data);
    }
    croak($@) if $res && $die_on_err && $res != MDB_NOTFOUND() or undef $@;
    $data;
}

*STORE = \&put;
*CLEAR = \&drop;

sub UNTIE {
    my $self = shift;
    my $txn = $self->[0];
    return unless($txn && ($Txns{ $$txn } || undef($self->[0])));
    delete $self->[2]; # Free cursor
}

sub SCALAR {
    return $_[0]->stat->{entries};
}

sub EXISTS {
    my($self, $key) = @_;
    local $die_on_err = 0;
    return !_get(_chkalive($self), $key, my $dummy);
}

sub DELETE {
    my($self, $key) = @_;
    my @self = _chkalive($self);
    my $data;
    local $die_on_err = 0;
    if(_get(@self, $key, $data) != MDB_NOTFOUND()) {
	_del(@self, $key, undef);
    }
    return $data;
}

sub FIRSTKEY {
    my $self = shift;
    $self->[2] = $self->Cursor;
    $self->NEXTKEY;
}

# I hop some day tie hashed are optimized
sub NEXTKEY {
    my($self, $key) = @_;
    my $op = defined($key) ? MDB_NEXT() : MDB_FIRST() ;
    local $die_on_err = 0;
    my $res = $self->[2]->get($key, my $data, $op);
    if($res == MDB_NOTFOUND()) {
	return;
    }
    return wantarray ? ($key, $data) : $key;
}

sub _mydbflags {
    my($envid, $dbi, $bit) = @_;
    my $cm = \vec($Envs{ $envid }[3], $dbi, LMDB_OFLAGN());
    my $om = $$cm;
    if(@_ > 3) {
	$$cm = $_[3] ? ($$cm | $bit) : ($$cm & ~$bit);
	_resetcurdbi();
    }
    return $om & $bit;
}

sub ReadMode {
    my $self = shift;
    my($txn, $dbi) = _chkalive($self);
    _mydbflags($txn->_env, $dbi, 1, @_);
}

sub UTF8 {
    my $self = shift;
    my($txn, $dbi) = _chkalive($self);
    _mydbflags($txn->_env, $dbi, 2, @_);
}

1;
__END__

=encoding utf-8

=head1 NAME

LMDB_File - Tie to LMDB (OpenLDAP's Lightning Memory-Mapped Database)

=head1 SYNOPSIS

  # Simple TIE interface, when you're in a rush
  use LMDB_File;

  $db = tie %hash, 'LMDB_File', $path;

  $hash{$key} = $value;
  $value = $hash{$key};
  each %hash;
  keys %hash;
  values %hash;
  ...


  # The full power
  use LMDB_File qw(:flags :cursor_op);

  $env = LMDB::Env->new($path, {
      mapsize => 100 * 1024 * 1024 * 1024, # Plenty space, don't worry
      maxdbs => 20, # Some databases
      mode   => 0600,
      # More options
  });

  $txn = $env->BeginTxn(); # Open a new transaction

  $DB = $txn->OpenDB( {    # Create a new database
      dbname => $dbname,
      flags => MDB_CREATE
  });

  $DB->put($key, $value);  # Simple put
  $value = $DB->get($key); # Simple get

  $DB->put($key, $value, MDB_NOOVERWITE); # Don't replace existing value

  # Work with cursors
  $cursor => $DB->Cursor;

  $cursor->get($key, $value, MDB_FIRST); # First key/value in DB
  $cursor->get($key, $value, MDB_NEXT);  # Next key/value in DB
  $cursor->get($key, $value, MDB_LAST);  # Last key/value in DB
  $cursor->get($key, $value, MDB_PREV);  # Previous key/value in DB

  $DB->set_compare( sub { lc($a) cmp lc($b) } ); # Use my own key comparison function


=head1 DESCRIPTION

B<NOTE: This document is still under construction. Expect it to be>
B<incomplete in places.>

LMDB_File is a Perl module which allows Perl programs to make use of the
facilities provided by OpenLDAP's Lightning Memory-Mapped Database "LMDB".

LMDB is a Btree-based database management library modeled loosely on the
BerkeleyDB API, but much simplified and extremely fast.

It is assumed that you have a copy of LMBD's documentation at hand when reading
this documentation. The interface defined here mirrors the C interface closely
but with an OO approach.

This is implemented with a number of Perl classes.

A LMDB's B<environment> handler (MDB_env* in C) will be wrapped in the
B<LMDB::Env> class.

A LMDB's B<transaction> handler (MDB_txn* in C) will be wrapped in the
B<LMDB::Txn> class.

A LMDB's B<cursor> handler (MDB_cursor* in C) will be wrapped in the
B<LMDB::Cursor> class.

A LMDB's B<Database> handler (MDB_dbi in C) will be exposed as a simple
integer, but because in LMDB all Database operations needs both a Transaction
and a Database handler, LMDB_File provides you a convenient L</LMDB_File>
object that encapsulates both and mimic the syntax of other *_File modules.


=head1 Error reporting

In the C API, most functions return 0 on success and an error code on failure.

In this module, when a function fails, the package variable B<$die_on_err> controls
the course of action. When B<$die_on_err> is set to TRUE, this causes LMDB_File to
C<die> with an error message that can be trapped by an C<eval { ... }> block.

When FALSE, the function will return the error code, in this case you should check
the return value of any function call.

By default B<$die_on_err> is TRUE.

Regardless of the value of B<$die_on_err>, the code of the last error can be found
in the package variable B<$last_err>.

=head1 LMDB::Env

This class wraps an opened LMDB B<environment>.

At construction time, the environment is created, if it does not exist, and opened.

When you are finished using it, in the C API you must call the C<mdb_env_close>
function to close it and free the memory allocated, but in Perl you simply
will let that the object get out of scope.

=head2 Constructor

$Env = LMDB::Env->new ( $path [, ENVOPTIONS ] )

Creates a new C<LMDB::Env> object and returns it. It encapsulates both LMDB's
C<mdb_env_create> and C<mdb_env_open> functions.

I<$path> is the directory in which the database files reside. This directory
must already exist and should be writable.

B<ENVOPTIONS>, if provided, must be a HASH Reference with any of the following
options:

=over

=item mapsize    => INT

The size of the memory map to use for this environment.

The size of the memory map is also the maximum size of the database.
The value should be chosen as large as possible, to accommodate future growth
of the database. The size should be a multiple of the OS page size.

The default is 1048576 bytes (1 MB).

=item maxreaders => INT

The maximum number of threads/reader slots for the environment.

This defines the number of slots in the lock table that is used to track readers
in the environment.

The default is 126.

=item maxdbs     => INT

The maximum number of named databases for the environment.

This option is only needed if multiple databases will be used in the
environment. Simpler applications that use the environment as a single
unnamed database can ignore this option.

The default is 0, i.e. no named databases allowed.

=item mode	 => INT

The UNIX permissions to set on created files. This parameter
is ignored on Windows. It defaults to 0600

=item flags      => ENVFLAGS

Set special options for this environment. This option, if provided,
can be specified by OR'ing the following flags:

=over

=item MDB_FIXEDMAP

Use a fixed address for the mmap region. This flag must be specified
when creating the environment, and is stored persistently in the environment.
If successful, the memory map will always reside at the same virtual address
and pointers used to reference data items in the database will be constant
across multiple invocations. This option may not always work, depending on
how the operating system has allocated memory to shared libraries and other uses.
The feature is highly experimental.

=item MDB_NOSUBDIR

By default, LMDB creates its environment in a directory whose
pathname is given in I<$path>, and creates its data and lock files
under that directory. With this option, I<$path> is used as-is for
the database main data file. The database lock file is the I<$path>
with "-lock" appended.

=item MDB_RDONLY

Open the environment in read-only mode. No write operations will be
allowed. LMDB will still modify the lock file - except on read-only
filesystems, where LMDB does not use locks.

=item MDB_WRITEMAP

Use a writeable memory map unless C<MDB_RDONLY> is set. This is faster
and uses fewer mallocs, but loses protection from application bugs
like wild pointer writes and other bad updates into the database.

Incompatible with nested transactions (also known as sub transactions).

=item MDB_NOMETASYNC

Flush system buffers to disk only once per transaction, omit the
metadata flush. Defer that until the system flushes files to disk,
or next non-MDB_RDONLY commit or C<< $Env->sync() >>. This optimization
maintains database integrity, but a system crash may undo the last
committed transaction. I.e. it preserves the ACI (atomicity,
consistency, isolation) but not D (durability) database property.

This flag may be changed at any time using C<< $Env->set_flags() >>.

=item  MDB_NOSYNC

Don't flush system buffers to disk when committing a transaction.
This optimization means a system crash can corrupt the database or
lose the last transactions if buffers are not yet flushed to disk.
The risk is governed by how often the system flushes dirty buffers
to disk and how often C<< $Env->sync() >> is called.  However, if the
filesystem preserves write order and the C<MDB_WRITEMAP> flag is not
used, transactions exhibit ACI (atomicity, consistency, isolation)
properties and only lose D (durability).  I.e. database integrity
is maintained, but a system crash may undo the final transactions.
Note that C<MDB_NOSYNC | MDB_WRITEMAP> leaves the system with no
hint for when to write transactions to disk, unless C<< $Env->sync() >>
is called. C<MDB_MAPASYNC | MDB_WRITEMAP>) may be preferable.

This flag may be changed at any time using C<< $Env->set_flags() >>.

=item MDB_MAPASYNC

When using C<MDB_WRITEMAP>, use asynchronous flushes to disk.
As with C<MDB_NOSYNC>, a system crash can then corrupt the
database or lose the last transactions. Calling C<< $Env->sync() >>
ensures on-disk database integrity until next commit.

This flag may be changed at any time using C<< $Env->set_flags() >>.

=item MDB_NOTLS

Don't use Thread-Local Storage. Tie reader locktable slots to
L</LMDB::Txn> objects instead of to threads. I.e. C<< $Txn->reset() >>
keeps the slot reserved for the L</LMDB::Txn> object. A thread may
use parallel read-only transactions. A read-only transaction may span
threads if the user synchronizes its use. Applications that multiplex many
user threads over individual OS threads need this option. Such an
application must also serialize the write transactions in an OS
thread, since LMDB's write locking is unaware of the user threads.

=back

=back

=head2 Class methods

=over

=item $Env->copy ( $path )

Copy an LMDB environment to the specified I<$path>

=item $Env->copyfd ( HANDLE )

Copy an LMDB environment to the specified B<HANDLE>.

=item $status = $Env->stat

Returns a HASH reference with statistics for the main, unnamed, database
in the environment, the HASH contains the following keys:

=over

=item B<psize> Size of a database page.

=item B<depth> Depth (height) of the B-Tree

=item B<branch_pages> Number of internal (non-leaf) pages

=item B<overflow_pages> Number of overflow pages

=item B<entries> Number of data items

=back

=item $info = $Env->info

Returns a HASH reference with information about the environment, I<$info>,
with the following keys:

=over

=item B<mapaddr> Address of map, if fixed

=item B<mapsize> Size of the data memory map

=item B<last_pgno> ID of the last used page

=item B<last_txnid> ID of the last committed transaction

=item B<maxreaders> Max reader slots in the environment

=item B<numreaders> Max reader slot used in the environment

=back

=item $Env->sync ( BOOL )

Flush the data buffers to disk.

Data is always written to disk when C<< $Txn->commit() >> is called,
but the operating system may keep it buffered. LMDB always flushes
the OS buffers upon commit as well, unless the environment was
opened with C<MDB_NOSYNC> or in part C<MDB_NOMETASYNC>.

If I<BOOL> is TRUE force a synchronous flush.  Otherwise if the
environment has the C<MDB_NOSYNC> flag set the flushes will be omitted,
and with C<MDB_MAPASYNC> they will be asynchronous.

=item $Env->set_flags ( BITMASK, BOOL )

As noted above, some environment flags can be changed at any time.

I<BITMASK> is the flags to change, bitwise OR'ed together.
I<BOOL> TRUE set the flags, FALSE clears them.

=item $Env->get_flags ( $flags )

Returns in I<$flags> the environment flags.

=item $Env->get_path ( $path )

Returns in I<$path> the path that was used in C<< LMDB::Env->new(...) >>

=item $Env->get_maxreaders ( $readers )

Returns in I<$readers> the maximum number of threads/reader slots for
the environment

=item $mks = $Env->get_maxkeysize

Returns the maximum size of a key for the environment.

=item $Txn = $Env->BeginTxn ( [ $tflags ] )

Returns a new Transaction. A simple wrapper over the constructor of
L</LMDB::Txn>.

If provided, $tflags will be passed to the constructor, if not provided,
this wrapper will propagate the environment's flag C<MDB_RDONLY>,
if set, to the transaction constructor.

=back

=head1 LMDB::Txn

In LMDB every operation (read or write) on a Database needs to be inside a
B<transaction>. This class wraps an LMDB transaction.

You must terminate the transaction by either the C<abort> or C<commit>
methods. After a transaction is terminated, you should not call any other method
on it, except C<env>.

If you let an object of this class get out of scope, by default the transaction
will be aborted.

=head2 Constructor

 $Txn = LMDB::Txn->new ( $Env [, $tflags ] )

Create a new B<transaction> for use in the B<environment>.

=head2 Class methods

=over

=item $Txn->abort

Abort the transaction, terminating the transaction.

=item $Txn->commit

Commit the transaction, terminating the transaction.

=item $Txn->reset

Reset a read-only transaction.

Abort the transaction like C<< $Txn->abort() >>, but keep the transaction
handle in the inactive state so C<< $Txn->renew() >> may reactivate the handle.

This saves allocation overhead if the process will start a new read-only
transaction soon, and also saves locking overhead if MDB_NOTLS is in use.

The reader table lock is released, but the table slot stays tied to its thread or
Transaction. Use C<< $Txn->abort() >> to discard a reseted handle, and to free
its lock table slot if MDB_NOTLS is in use.

=item $Txn->renew

Renew a read-only transaction.

This acquires a new reader lock for a transaction handle that had been
inactivated by C<< $Txn->reset() >>. It must be called before an inactive
(reseted) transaction may be used again.

In this Perl implementation if you call C<< $Txn->renew() >> in an active
Transaction the method internally calls C<< $Txn->reset() >> for you.

=item $Env = $Txn->env

Returns the environment (an LMDB::Env object) that created the transaction,
if it is still alive, or C<undef> if called on a terminated transaction.

=item $SubTxn = $Txn->SubTxn ( [ $tflags ] )

Creates and returns a sub transaction (also known as a nested transaction).

Nested transactions are useful for combining components that create and
commit transactions. No modifications are permanently stored until the
highest level "parent" transaction is committed. Nested transactions can
be aborted without aborting the parent transaction and only the changes
made in the nested transaction will be rolled-back.

Aborting the parent transaction will abort and terminate all outstanding
nested transactions. Committing the parent transaction will similarly
commit and terminate all outstanding nested transactions.

Unlike some other databases, in LMDB changes made inside nested transactions
are not visible to the parent transaction until the nested transaction is
committed. In other words, transactions are always isolated, even when they
are nested.

=item $Txn->AutoCommit ( [ BOOL ] )

When I<BOOL> is provided, it sets the behavior of the transaction when going
out of scope: I<BOOL> TRUE makes arrangements for the transaction to be auto
committed and I<BOOL> FALSE returns to the default behavior: to be aborted.

If you don't provide I<BOOL>, you are only interested in knowing the current
value of this option, which is returned in every case.

=item $DB = $Txn->OpenDB ( [ DBOPTIONS ] )

=item $DB = $Txn->OpenDB ( [ $dbname [, DBFLAGS ]] )

This method opens a Database in the environment and returns a L</LMDB_File> object
that encapsulates both the Transaction and the Database handler.

This is a convenience shortcut for C<< LMDB_File->new( $Txn, $Txn->open(...) ) >>
for use when you want to use the hi-level LMDB_File's OO approach.

B<DBOPTIONS>, if provided,  should be a HASH reference with any of the
following keys:

=over

=item B<dbname> => $dbname

=item B<flags> => DBFLAGS

=back

You can also call this method using its values, I<$dbname> and B<DBFLAGS>,
documented ahead.

=item $dbi = $Txn->open ( [ $dbname [, DBFLAGS ]] )

This method open a Database in the environment and returns the low level
Database handler, an integer.

If provided I<$dbname>, will be the name of a named Database in the environment,
if not provided (or if I<$dbname> is C<undef>), the opened Database will be
the unnamed (the default) one.

B<DBFLAGS>, if provided, will set special options for this Database and
can be specified by OR'ing the following flags:

=over

=item MDB_REVERSEKEY

Keys are strings to be compared in reverse order

=item MDB_DUPSORT

Duplicate keys may be used in the database. (Or, from another perspective,
keys may have multiple data items, stored in sorted order.) By default
keys must be unique and may have only a single data item.

=item MDB_INTEGERKEY

Keys are binary integers in native byte order.

=item MDB_DUPFIXED

This flag may only be used in combination with #MDB_DUPSORT. This option
tells the library that the data items for this database are all the same
size, which allows further optimizations in storage and retrieval. When
all data items are the same size, the #MDB_GET_MULTIPLE and #MDB_NEXT_MULTIPLE
cursor operations may be used to retrieve multiple items at once.

=item MDB_INTEGERDUP

This option specifies that duplicate data items are also integers, and
should be sorted as such.

=item MDB_REVERSEDUP

This option specifies that duplicate data items should be compared as
strings in reverse order.

=item MDB_CREATE

Create the named database if it doesn't exist. This option is not
allowed in a read-only transaction or a read-only environment.

After successfully commit the transaction that created the Database, it will remains
opened in the Environment so you can reuse I<$dbi> in other transactions.

=back

If you will need to use that Database handler in more than one transaction or want
to use a more traditional (in LMDB's point of view) approach, this the method you
should use.

To operate in the opened database with the returned I<$dbi> handler you can use the
methods described bellow or call C<< LMDB_File->new(...) >> to obtain
a L</LMDB_File> object to operate the database in a particular transaction.

=item $Txn->put ( $dbi, $key, $data [, WRITEFLAGS [, $length ] )

Store items into the database I<$dbi>

Provided for when your main concern is the raw speed.

For details of the other arguments, please see the method of the same name
in LMDB_File below.

=item $Txn->get ( $dbi, $key, $data )

Get items from the database I<$dbi>

Provided for when your main concern is the raw speed.

For details of the other arguments, please see the method of the same name
in LMDB_File below.

=item $Txn->id ()

Return the transaction's ID.
This returns the identifier associated with this transaction. For a
read-only transaction, this corresponds to the snapshot being read;
concurrent readers will frequently have the same transaction ID.

=back

=head1 LMDB_File

In the LMDB C API all Database operations need both an active Transaction
and a Database handler. To simplify those operations and be syntax compatible with
others *_File modules, this Perl API provides you a B<LMDB_File>
object that encapsulates both and implements some hi-level extensions.

LMDB_File's methods, in contrast to the LMDB::Txn's ones of the same name, perform some
checks before calling the low-level C API.

=head2 Constructors

=over

=item $DB = LMDB_File->new( $Txn, $dbi )

Associates a Transaction I<$Txn> with a previously opened Database handler I<$dbi>
to use this OO API

=item  $DB = LMDB_File->open ( $Txn [, $dbname [, DBFLAGS ] ] )

An alternative to C<< $Txn->OpenDB(...) >> for open a Database and associate it with
a Transaction in one call.

=back

=head2 Class methods

=over

=item $DB->put ( $key, $data [, WRITEFLAGS [, $length ] ] )

Store items into a database.

This function stores key/data pairs in the database. The default behavior
is to enter the new key/data pair, replacing any previously existing key
if duplicates are disallowed, or adding a duplicate data item if
duplicates are allowed

I<$key> is the key to store in the database and I<$data> the data to store.

B<WRITEFLAGS>, if provided, will set special options for this operation and
can be one of following flags:

=over

=item MDB_NODUPDATA

Enter the new key/data pair only if it does not	already appear in the database.
This flag may only be specified	if the database was opened with #MDB_DUPSORT.
The function will fail with MDB_KEYEXIST if the key/data pair already appears
in the database.

=item MDB_NOOVERWRITE

Enter the new key/data pair only if the key does not already appear in the
database.

The function will return MDB_KEYEXIST if the key already appears in the database,
even if	the database supports duplicates (#MDB_DUPSORT). The I<$data>
parameter will be set to the existing item.

=item MDB_RESERVE

Reserve space for data of the given size in I<$length>, but don't copy anything.
Instead, return in I<$data> a magical scalar with a pointer to the reserved space,
which the caller can fill in later, but before the next update operation
or the transaction ends. This saves an extra memcpy if the data is being generated
later.

In this particular case, you need to pass the extra I<$length> parameter to
specify how many bytes to reserve.

Please read about the C<< $DB->ReadMode >> method caveats bellow for details that
apply to the magical scalar returned in I<$data> in this case.

=item MDB_APPEND

Append the given key/data pair to the end of the database.

No key comparisons are performed. This option allows fast bulk loading when
keys are already known to be in the correct order.

B<NOTE:> Loading unsorted keys with this flag will cause data corruption.

=item MDB_APPENDDUP

As above, but for sorted duplicated data.

=back

=item $DB->get ( $key, $data )

=item $data = $DB->get ( $key )

Get items from a database.

This method retrieves key/data pairs from the database.

If the database supports duplicate keys (#MDB_DUPSORT) then the
first data item for the key will be returned. Retrieval of other
items requires the use of the C<< LMBD::Cursor->get() >> method.

The two-argument form, closer to the C API, returns in the provided argument
I<$data> the value associated with I<$key> in the database if it exists or reports
an error if not.

In the simpler, more "perlish" one-argument form, the method returns the value
associated with I<$key> in the database or C<undef> if no such value exists.

=item $DB->del ( $key [, $data ] )

Delete items from the database.

This function removes key/data pairs from the database.

If the database does not support sorted duplicate data items, (MDB_DUPSORT)
the I<$data> parameter is optional and is ignored.

If the database supports sorted duplicates and the I<$data> parameter
is C<undef> or not provided, all of the duplicate data items for the I<$key>
will be deleted. Otherwise, if the I<$data> parameter is provided
only the matching data item will be deleted.

=item $DB->set_compare ( CODE )

Set a custom key comparison function referenced by I<CODE> for a database.

I<CODE> should be a subroutine reference or an anonymous subroutine, that
like Perl's L<perlfunc/"sort">, will receive the values to compare in the
global variables C<$a> and C<$b>.

The comparison function is called whenever it is necessary to compare a
key specified by the application with a key currently stored in the database.
If no comparison function is specified, and no special key flags were
specified in C<< LMDB_File->open() >>, the keys are compared lexically,
with shorter keys collating before longer keys.

B<Warning:> This function must be called before any data access functions
are used, otherwise data corruption may occur. The same comparison function
must be used by every program accessing the database, every time the
database is used.

=item $flags = $DB->flags

Retrieve the DB flags for the associated database.

=item $status = $DB->stat

Returns a HASH reference with statistics for the associated database, the hash
will contain the following keys:

=over

=item B<psize> Size of a database page.

=item B<depth> Depth (height) of the B-Tree

=item B<branch_pages> Number of internal (non-leaf) pages

=item B<overflow_pages> Number of overflow pages

=item B<entries> Number of data items

=back

=item $DB->drop( [ REMOVE ] )

If I<REMOVE> isn't provided or FALSE, the database is emptied. If I<REMOVE> is TRUE
the database is closed and removed from the Environment.

=item $DB->Alive

Returns a TRUE value if the associated transaction is still alive, i.e.
not commited nor aborted yet, and FALSE otherwise.

=item $Cursor = $DB->Cursor

Creates a new LMDB::Cursor object to work in the database, see L</LMDB::Cursor>

=item $txn = $DB->Txn

Returns the transaction, an L</LMDB::Txn> object, associated with I<$DB>.

    $DB->Txn->commit; # Commit the current transaction.

If the method C<< $DB->Alive >> has returned FALSE before, this method will return
C<undef>.

You can use C<< $DB->Txn >> as an lvalue to change the associated Transaction,
but remember that, if C<$DB> is holding the last reference of the current
transaction, that transaction will be terminated.

    $DB->Txn->commit; # Commit current
    $DB->Alive;       # FALSE
    ...
    $DB->Txn = $Env->BeginTxn; # Start another, with same Database
    ...

=item $dbi = $DB->dbi

Returns the low level Database handler associated with I<$DB>

You can use C<< $DB->dbi >> as an lvalue to switch the associated Datbase hander:

  $DB->dbi = $other_dbi;

=item $DB->ReadMode ( [ MODE ] )

This method allows you to modify the behavior of "get" (read) operations on
the database.

The C documentation for the C<mdb_get> function states that:

  The memory pointed to by the returned values is owned by the
  database. The caller need not dispose of the memory, and may not
  modify it in any way. For values returned in a read-only transaction
  any modification attempts will cause a SIGSEGV.

So this module implements two modes of operation for its "get" methods
and you can select between them with this method.

When MODE is 0 (or any FALSE value) a default "safe" mode is used in which the
data value found in the database is copied to the scalar returned, so you can do
anything you want to that scalar without side effects.

But when MODE is 1 (or, in the current implementation, any TRUE value) a sort
of hack is used to avoid the memory copy and a magical scalar returned that hold only a
pointer to the data value found. This is much faster and uses less memory, especially
when used with large values.

In a environment opened with MDB_WRITEMAP and in a transaction without the MDB_RDONLY
flag, you are allowed to modify the returned scalar, and the modifications are
reflected to the associated memory block and preserved in the database when the
transaction is commited. Otherwise the magical scalar is marked READ-ONLY and any
attempt to modify it (other than reuse it in another C<< $DB->get >> ),
will cause perl to croak.

B<CAVEATS:> In a read-only transaction the value is valid only until the end of the
transaction, and in a read-write transaction the value is valid only until the next
write operation (because any write operation can potentially modify the in-memory
btree). In the current implementation, you are responsible for the proper timing
of usage.

B<NOTE:> In order to achieve the zero-copy behavior desired by setting L<ReadMode>
to TRUE, you must use the two-argument form of get (C<< $DB->get ( $key, $data ) >>),
use the new C<< $DB->Rget( $key ) >> or use the cursor get method described below.

=item $DB->UTF8 ( [ MODE ] )

Instructs LDMB_File to use the UTF-8 encoding for the associated database when I<MODE>
is 1 or revert to raw bytes when 0.

Returns the previous value.

By default, all values in LMDB are simple byte buffers of certain fixed length.

So if you are storing binary data in your database all works as expected: what
you put is what you get.

But when you need to store some arbitrary Unicode text value, remember that internally
perl stores your strings in either the native eight-bit character set or in UTF-8,
and to warrant a consistent encoding in your database you should do something like:

    use Encoding;
    ...

    $DB->put($key, Encode::encode($my_encoding, $characters));

    $characters = Encode::decode($my_encoding, $DB->get($key));


For any value of $my_encoding, see L<Encode> for the gory details.

But if you use for interchange the UTF-8 encoding, with this method you can avoid
all that typing.

When I<MODE> is 1, all values that you put in the Database will be encoded in UTF-8,
And all get calls will expect UTF-8 data and it will be verified and decoded.
In this mode, if malformed data is found, a warning will be emitted, the decode
attempt aborted and the raw bytes returned.

In this mode, a C<< $foo->get(...) >> call interacts with the L<bytes> pragma in a
special way: In the lexical scope under the effects of C<use bytes>, any get call
skips the decode step, returning the fetched encoded UTF-8 data as bytes, i.e. with
the internal perl UTF8 flag off, as expected by modules like JSON::XS.

=back

=head1 LMDB::Cursor

To construct a cursor you should call the C<Cursor> method of the C<LMDB_File>
class:

 $cursor = $DB->Cursor

=head2 Class methods

=over

=item $cursor->get($key, $data, CURSOR_OP)

This function retrieves key/data pairs from the database.

The variables I<$key> and I<$data> are used to return the values found.

B<CURSOR_OP> determines the key/data to be retrieved and must be one of the following:

=over

=item MDB_FIRST

Position at first key/data item.

=item MDB_FIRST_DUP

Position at first data item of current key. Only for C<MDB_DUPSORT>

=item MDB_GET_BOTH

Position at key/data pair. Only for C<MDB_DUPSORT>

=item MDB_GET_BOTH_RANGE

Position at key, nearest data. Only for C<MDB_DUPSORT>

=item MDB_GET_CURRENT

Return key/data at current cursor position.

=item MDB_GET_MULTIPLE

Return all the duplicate data items at the current cursor position.
Only for C<MDB_DUPFIXED>

=item MDB_LAST

Position at last key/data item.

=item MDB_LAST_DUP

Position at last data item of current key. Only for C<MDB_DUPSORT>

=item MDB_NEXT

Position at next data item.

=item MDB_NEXT_DUP

Position at next data item of current key.  Only for C<MDB_DUPSORT>

=item MDB_NEXT_MULTIPLE

Return all duplicate data items at the next cursor position. Only for C<MDB_DUPFIXED>

=item MDB_NEXT_NODUP

Position at first data item of next key.

=item MDB_PREV

Position at previous data item.

=item MDB_PREV_DUP

Position at previous data item of current key. Only for C<MDB_DUPSORT>

=item MDB_PREV_NODUP

Position at last data item of previous key.

=item MDB_SET

Position at specified key.

=item MDB_SET_KEY

Position at specified key, return key + data.

=item MDB_SET_RANGE

Position at first key greater than or equal to specified key.

=back

=item $cursor->put($key, $data, WRITEFLAGS)

This function stores key/data pairs into the database.

If the function succeeds and an item is inserted into the database,
the cursor is always positioned to refer to the newly inserted item.

If the function fails for any reason, the state of the cursor will undetermined.

B<NOTE:> Earlier documentation incorrectly said errors would leave the
state of the cursor unchanged.

=item $cursor->del( [ DELFLAGS ] )

This function deletes the key/data pair to which the cursor refers.

If the database was opened with C<MDB_DUPSORT>, the optional parameter I<DELFLAGS>
can be C<MDB_NODUPDATA> to deletes all of the data items for the current key.

=back

=head1 Exportable constants

At C<use> time you can import into your namespace the following constants,
grouped by their tags.

=head2 Environment flags C<:envflags>

 MDB_FIXEDMAP MDB_NOSUBDIR MDB_NOSYNC MDB_RDONLY MDB_NOMETASYNC
 MDB_WRITEMAP MDB_MAPASYNC MDB_NOTLS

=head2 Data base flags C<:dbflags>

 MDB_REVERSEKEY MDB_DUPSORT MDB_INTEGERKEY MDB_DUPFIXED
 MDB_INTEGERDUP MDB_REVERSEDUP MDB_CREATE

=head2 Write flags C<:writeflags>

 MDB_NOOVERWRITE MDB_NODUPDATA MDB_CURRENT MDB_RESERVE
 MDB_APPEND MDB_APPENDDUP MDB_MULTIPLE

=head2 All flags C<:flags>

All of C<:envflags>, C<:dbflags> and C<:writeflags>

=head2 Cursor operations C<:cursor_op>

 MDB_FIRST MDB_FIRST_DUP MDB_GET_BOTH MDB_GET_BOTH_RANGE
 MDB_GET_CURRENT MDB_GET_MULTIPLE MDB_NEXT MDB_NEXT_DUP MDB_NEXT_MULTIPLE
 MDB_NEXT_NODUP MDB_PREV MDB_PREV_DUP MDB_PREV_NODUP MDB_LAST MDB_LAST_DUP
 MDB_SET MDB_SET_KEY MDB_SET_RANGE

=head2 Error codes C<:error>

 MDB_SUCCESS MDB_KEYEXIST MDB_NOTFOUND MDB_PAGE_NOTFOUND MDB_CORRUPTED
 MDB_PANIC MDB_VERSION_MISMATCH MDB_INVALID MDB_MAP_FULL MDB_DBS_FULL
 MDB_READERS_FULL MDB_TLS_FULL MDB_TXN_FULL MDB_CURSOR_FULL MDB_PAGE_FULL
 MDB_MAP_RESIZED MDB_INCOMPATIBLE MDB_BAD_RSLOT MDB_LAST_ERRCODE

=head2 Version information C<:version>

 MDB_VERSION_FULL MDB_VERSION_MAJOR MDB_VERSION_MINOR
 MDB_VERSION_PATCH MDB_VERSION_STRING MDB_VERSION_DATE

=head1 TIE Interface

The simplest interface to LMDB is using L<perlfunc/tie>.

The TIE interface of LMDB_File can take several forms that depend on the
data at hand.

=over

=item tie %hash, 'LMDB_File', $path [, $options ]

The most simple form.

=item tie %hash, 'LMDB_File', $path, $flags, $mode

For compatibility with other DBM modules.

=item tie %hash, 'LMDB_File', $Txn [, DBOPTIONS ]

When you have a Transaction object I<$Txn> at hand.

=item tie %hash, 'LMDB_File', $Env [, DBOPTIONS ]

When you have an Environment object I<$Env> at hand.

=item tie %hash, $DB

When you have an opened Transaction encapsulated database.

=back

The first two forms will create and/or open the Environment at I<$path>,
create a new Transaction and open a Database in the Transaction.

If provided, I<$options> must be a HASH reference with options for both
the Environment and the database.

Valid keys for I<$option> are any described above for B<ENVOPTIONS>
and B<DBOPTIONS>.

In the case that you have already created a transaction or an environment,
you can provide a HASH reference in B<DBOPTIONS> for options exclusively
for the database.

In the forms that needs to create a Transaction, this is setted for
B<Autocommit> mode.

=head1 AUTHOR

Salvador Ortiz Garcia, E<lt>sortiz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

 Copyright (C) 2013-2014 by Salvador Ortiz García
 Copyright (C) 2013-2014 by Matías Software Group, S.A. de C.V.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0, see L<LICENSE>.

=cut
