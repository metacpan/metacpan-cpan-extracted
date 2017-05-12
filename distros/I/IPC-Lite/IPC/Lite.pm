package IPC::Lite;

# Combination of vars.pm, Tie::DBI, and IPC
# Wanted to called it "shared" .... ie: "use shared qw($var)"
# but shared memory is sketchy at best, whereas SQLite works
# on most platforms

our $VERSION = '0.5.' . [qw$Revision: 40 $]->[1];

use warnings::register;
use strict;

#use strict qw(vars subs);

use DBI;
use DBD::SQLite;

# Can set this directly if desired

our %DEFAULT_PATH;
our %DEFAULT_TTL;
our %DEFAULT_KEY;
our $DEBUG;

my %DBS;

#$SIG{__DIE__} = \&fatalerror;

# this code from vars.pm, since we can't adjust the "callpack"
sub import {
#hereiam();
    my $callpack = caller;
    my ($pack, @imports) = @_;
    my ($sym, $ch, $sym_n);
    my %opts;
   
    my $imps;
 
    my $i = -1;
    foreach (@imports) {
	++$i;
        if (($ch, $sym) = /^([\$\@\%])(.+)/) {
	    no strict 'refs';
	    no warnings 'uninitialized';
	    if ($sym =~ /\W/) {
		# time for a more-detailed check-up
		if ($sym =~ /^\w+[[{].*[]}]$/) {
		    require Carp;
		    Carp::croak("Can't declare individual elements of hash or array");
		} elsif (warnings::enabled() and length($sym) == 1 and $sym !~ tr/a-zA-Z//) {
		    warnings::warn("No need to declare built-in vars");
		} elsif  (($^H &= strict::bits('vars'))) {
		    require Carp;
		    Carp::croak("'$_' is not a valid variable name under strict vars");
		}
	    }
	    # don't put "main::" on every table entry, too ugly
	    $sym_n = $sym;
	    $sym = "${callpack}::$sym" unless $sym =~ /::/;
	    $sym_n = $sym unless $callpack eq 'main';		
	    *$sym =
		(  $ch eq "\$" ? \$$sym
		 : $ch eq "\@" ? \@$sym
		 : $ch eq "\%" ? \%$sym
		 : do {
		     require Carp;
		     Carp::croak("'$_' is not a valid variable name");
		 });
	    eval("tie ${ch}$sym, '$pack', \%opts, sym=>'$sym_n';");
	    if ($@) {
                    require Carp;
                    Carp::croak("'$_' problem with tie: $@");
	    }
	    ++$imps;
	} else {
	    if ($_ =~ /^(ttl|timeout)$/i) {
		$opts{ttl} = splice @imports, $i+1, 1;
		$opts{ttl} = $1 if $opts{ttl} =~ s/\s*\b(\d+)(s|\s*seconds)\b\s*//;
		$opts{ttl} = 86400 * $1 + ($opts{ttl} ? $opts{ttl} : 0) if $opts{ttl} =~ s/\s*\b(\d+)(d|\s*days)\b\s*//;
		next;
	    }
            if ($_ =~ /^path$/i) {
                $opts{path} = splice @imports, $i+1, 1;
                next;
            }
            if ($_ =~ /^key$/i) {
                $opts{key} = splice @imports, $i+1, 1;
                next;
            }
	    require Carp;
	    Carp::croak("'$_' is not a valid variable name for $pack");
	}
    }

    # assume user wanted to set global defaults instead
    if (!$imps) {
    	$DEFAULT_PATH{$callpack} = $opts{path} if $opts{path};
    	$DEFAULT_TTL{$callpack} = $opts{ttl} if $opts{ttl};
    	$DEFAULT_KEY{$callpack} = $opts{key} if $opts{key};
    }
};


#### public methods

sub path {
	return $_[0]->{path};
}

sub db {
        return $_[0]->{db};
}

#### create tables

sub create_vars_table {
	my ($db) = @_;
	create_table($db, "vars",  "(styp text, sym text int, exp int, primary key (styp, sym))");
}

sub create_scalar_table {
        my ($db) = @_;
        create_table($db, "scalar","(sym text primary key, val text, vtyp text)");
}

sub create_array_table {
        my ($db) = @_;
        create_table($db, "array", "(sym text, ind int, val text, vtyp text, primary key (sym, ind));")
}

sub create_hash_table {
        my ($db) = @_;
        create_table($db, "hash" , "(sym text, key text, val text, vtyp text, primary key (sym, key));");
}

sub create_hash_subtable {
        my ($db, $name) = @_;
        create_table($db, $name,   "(key text primary key, val text, vtyp text);");
}

sub create_array_subtable {
        my ($db, $name) = @_;
        create_table($db, $name,   "(ind text primary key, val text, vtyp text);");
}


sub create_table {
        my ($db, $name, $fds) = @_;
	$db->do("create table if not exists $name $fds");
	return 1;
}

## connect to db

sub open_pathdb {
	my ($self) = @_;
	my $path = $self->{path};
	my $db = {};
	my $tid = threadid();
	if (!($db = $DBS{$tid}{$path})) {
		my $connstr;
		$db = DBI->connect("dbi:SQLite:dbname=$path", "", "", {PrintError=>0, AutoCommit=>1});
		if ($db) {
			$db->{PrintError} = 0;
		} else {
			require Carp;
		    	Carp::croak("Can't create db at $path: " . DBI->errstr);
		}
		$db->{RaiseError} = 1;
		$DBS{$tid}{$path} = $db;
	}
	$self->{tid} = $tid;
	$self->{db} = $db;
}

# get caller's package... ignoring IPC::Lite

sub getcallpack {
	my $self = shift;
        my ($callpack, $callframe) = ('', 2);

        while (($callpack = scalar caller($callframe)) eq ref($self)) {
                ++$callframe;
        }
	return $callpack;
}

# generic tie_var, called by TIESCALAR, TIEHASH, TIEARRAY

sub tie_var {
	my $type = shift;
        my $pack = shift;

        my $self = {};

	my %opts = @_;
	for (keys(%opts)) {
		$self->{lc($_)} = $opts{$_};
	}

        bless $self, $pack;
	$self->{type} = $type;

	my $callpack;

	# get package defaults

	if (!defined($self->{ttl})) {
		$callpack = $self->getcallpack() unless $callpack;
		$self->{ttl} = $DEFAULT_TTL{$callpack};
	}

	# if there's no path or key, check for default key
        if (!$self->{path} && !$self->{key}) {
		$callpack = $self->getcallpack() unless $callpack;
		$self->{key} = $DEFAULT_KEY{$callpack};
	}

	if ($self->{key}) {
		$self->{path} = nametopath($self->{key});
		delete $self->{key};	# don't inherit
	}

	# still no path, get default path
        if (!$self->{path}) {
		$callpack = $self->getcallpack() unless $callpack;
                $self->{path} = $self->defaultpath($callpack);
        };

        $self->open_pathdb();

	if ($self->{sym}) {
		print "tie: '$self->{sym}' styp '$self->{type}'\n" if $DEBUG;
		if ($self->{ttl}) {
			create_vars_table($self->{db});
			my $exp = time() + $self->{ttl};
			my $up = $self->dbexec('refincr', "update vars set exp=? where sym=? and styp=?",
					$exp, $self->{sym}, $self->{type});
			if ($up == 0) {
				$self->dbexec('refins', "insert into vars (sym, styp, exp) values (?, ?, ?);",
					$self->{sym}, $self->{type}, $exp);	
			}
		}
	} elsif ($self->{table}) {
		if ($self->{type} eq '$') {
			require Carp;
			croak("Won't bind scalar to its own table");
		}
		print "tie: '$self->{table}' styp '$self->{type}'\n" if $DEBUG;
	} else {
		require Carp;
		Carp::croak("Need sym or table for IPC::Lite");
	}

	return $self;
}

sub cleanup {
	for my $tid_dbs (values(%DBS)) {
	for my $db (values(%$tid_dbs)) {
		my $st = dbexec($db, 'cleanup1', "select sym, styp from vars where exp > 0 and exp < ?", time());
		while (my $row=$st->fetchrow_arrayref()) {
			my ($sym, $styp) = @$row;
			print "cleanup: $sym, $styp\n" if $DEBUG;
			if ($styp eq '$') {
				dbexec($db, 'clearscalar', "delete from scalar where sym=?", $sym);
			} elsif ($styp eq '%') {
				dbexec($db, 'clearhash', "delete from hash where sym=?", $sym);
			} elsif ($styp eq '@') {
				dbexec($db, 'cleararray', "delete from array where sym=?", $sym);
			}
		}
	}
	}
}

sub TIESCALAR {
#hereiam();
	my $self = tie_var('$', @_);
        create_scalar_table($self->{db});
	return $self;
}

sub TIEHASH {
#hereiam();
	my $self = tie_var('%', @_);
	if ($self->{sym}) {
        	create_hash_table($self->{db});
	} elsif ($self->{table}) {
	        create_hash_subtable($self->{db}, $self->{table});
	} else {
		require Carp;
		Carp::croak("Need table or sym for explicit tie");
	}
        return $self;
}

sub TIEARRAY {
#hereiam();
        my $self = tie_var('@', @_);
        if ($self->{sym}) {
                create_array_table($self->{db});
	} elsif ($self->{table}) {
                create_array_subtable($self->{db}, $self->{table});
        } else {
		require Carp;
		Carp::croak("Need table or sym for explicit tie");
        }
        return $self;
}


sub canonical {
#hereiam();
	my ($self, $key) = @_;
	$self->checkdb();
	my $canon;

	if ($self->{sym}) {
		$canon = '$' . $self->{sym};
	} else {
		$canon = '#' . $self->{table};
	}

	if ($self->{type} eq '%') {
		$canon .= '{' . $key . '}';
	} elsif ($self->{type} eq '@') {
		$canon .= '[' . $key . ']';
	}

	return $canon;
}

sub FIRSTKEY {
#hereiam();
	my ($self) = @_;
	$self->checkdb();
	if ($self->{sym}) {
	        $self->{keyst} = $self->dbexec('enumkey', "select key, val, vtyp from hash where sym=?", $self->{sym});
	} else {
	        $self->{keyst} = $self->dbexec('', "select key, val, vtyp from $self->{table}");
	}
	return $self->NEXTKEY();
}

sub NEXTKEY {
#hereiam();
        my ($self) = @_;
	$self->checkdb();
	my $row = $self->{keyst}->fetchrow_arrayref();
	if (!$row) {
		$self->{keyst} = undef;
		return ();
	}

        my ($key, $val, $vtyp) = @{$row}; 
	if (wantarray) {
		return ($key, tiesubrefs($self, $key, $val, $vtyp));
	} else {	
        	return $key;
	}
}

sub CLEAR {
#hereiam();
        my ($self) = @_;
	$self->checkdb();
	if ($self->{sym}) {
		if ($self->{type} eq '%') {
			$self->dbexec('clearhash', "delete from hash where sym=?", $self->{sym});
		} elsif ($self->{type} eq '@') {
			$self->dbexec('cleararray', "delete from array where sym=?", $self->{sym});
		}
	} else {
                $self->dbexec('', "delete from $self->{table}");
	}
}

sub SPLICE {
#hereiam();
        my ($self, $offset, $length, @new) = @_;
	$self->checkdb();
        $offset = 0 unless defined $offset;
        $length = $self->FETCHSIZE() - $offset unless defined $length;

	my @ret;

	$self->{db}->begin_work();

	my $n = 0;
	while (@new && $length > 0) {
		# replace
		push @ret, $self->FETCH($offset);
		$self->STORE($offset, $new[$n]);
		$offset += 1; 	
		$length -= 1;
		++$n;
	}

	# either new was more or length was more
	if ($n <= $#new) {
		for (my $i=($self->FETCHSIZE-1); $i >= $offset; --$i) {
		    # constraints prevent us from doing this in 1 call to the db, consider turning them off for speed?
		    if ($self->{sym}) {
			$self->dbexec('arrayind', "update array set ind=ind+? where sym=? and ind = ?", scalar @new, $self->{sym}, $i);
		    } else {
			$self->dbexec('arrayind.' . $self->{table}, "update $self->{table} set ind=ind+? where ind = ?", scalar @new, $i);
		    }
		}
		for (; $n <= $#new; ++$n) {
			$self->STORE($n + $offset, $new[$n]);
		}
	} elsif ($length > 0) {
		for ( my $i = $offset ; $i < ( $offset + $length ) ; ++$i ) {
			push @ret, $self->FETCH($i);
		}
		if ($self->{sym}) {
			$self->dbexec('delarrayrange', "delete from array where sym=? and ind>=? and ind < ?", 
					$self->{sym}, $offset, $offset + $length);
		} else {
			$self->dbexec('', "delete from $self->{table} where ind>=? and ind < ?",
					$offset, $offset + $length);
		}
                # shift indexes down in storage
		for (my $i = $offset+1; $i < $self->FETCHSIZE; ++$i) {
			if ($self->{sym}) {
				$self->dbexec('indarray', "update array set ind=ind-? where sym=? and ind=?", 
					$length, $self->{sym}, $i);
			} else {
				$self->dbexec('indarray.' . $self->{table}, "update $self->{table} set ind=ind-? where ind=?", 
					$length, $i);
			}
		}
	}

	$self->{db}->commit();

	return wantarray ? @ret : $ret[@ret];
}

sub SHIFT {
    my ($self) = @_;
    my @val = $self->SPLICE( 0, 1 );
    return $val[0];
}

sub DELETE {
        my ($self, $key) = @_;
	$self->checkdb();
	if ($self->{type} eq '%') {
		if ($self->{sym}) {
			$self->dbexec('delhash', "delete from hash where sym=? and key=?", $self->{sym}, $key);
		} else {
			$self->dbexec('', "delete from $self->{table} where key=?", $key);
		}
	} else {
		$self->store($key, undef);
	}
}

sub FETCHSIZE {
        my ($self) = @_;
	$self->checkdb();
	my $st;
        if ($self->{sym}) {
                $st = $self->dbexec('arraysize', "select max(ind) from array where sym=?", $self->{sym});
        } else {
                $st = $self->dbexec('', "select max(ind) from $self->{table}");
        }
	my ($ind) = $st->fetchrow_array();
	return defined $ind ? ($ind+1) : 0;
}

sub EXTEND {
#hereiam();
	my ($self, $count) = @_;
	$self->checkdb();
	if ($count >= 0) {
        if ($self->{sym}) {
                $self->dbexec('extarray', "delete from array where sym=? and ind >= ?", $self->{sym}, $count);
        } else {
                $self->dbexec('', "delete from $self->{table} where ind >= ?", $count);
        }
	}
}

sub POP {
        my ($self) = @_;
	$self->checkdb();
	$self->{db}->begin_work();
	my $ind = $self->FETCHSIZE()-1;
	my $val = $self->FETCH($ind);
	if ($self->{sym}) {
		$self->dbexec('arraypop', "delete from array where sym=? and ind = ?", $self->{sym}, $ind);
	} else {
		$self->dbexec('', "delete from $self->{table} where ind = ?", $ind);
	}
	$self->{db}->commit();
	return $val;
}

sub PUSH {
	my ($self, @list) = @_;
	$self->checkdb();
	$self->{db}->begin_work();
	for (@list) {
		my $st;
		if ($self->{sym}) {
			$self->dbexec('arraypush', "insert into array (sym, ind) values (?, (select 1+coalesce(max(ind),-1) from array where sym=?))", $self->{sym}, $self->{sym});
			$st = $self->dbexec('maxind', "select max(ind) from array where sym=?", $self->{sym});
		} else {
			$self->dbexec('arraypush.' . $self->{table}, "insert into $self->{table} (ind) values ((select 1+coalesce(max(ind),-1) from $self->{table}))");
			$st = $self->dbexec('maxind.' . $self->{table}, "select max(ind) from $self->{table}");
		}
		my ($key) = $st->fetchrow_array();
		$self->STORE($key, $_);
	}
	$self->{db}->commit();
	return $self->FETCHSIZE();
}

sub UNSHIFT {
        my ($self, @list) = @_;
        $self->checkdb();
        return $self->SPLICE(0, 0, @list);
}


sub EXISTS {
	my ($self, $key) = @_;
	return $self->FETCH($key, 'EXISTS');
}

sub FETCH {
	my ($self, $key, $act) = @_;
	$self->checkdb();

	my $st;

	if ($self->{type} eq '$') {
		$st = $self->dbexec('fetchscalar', "select val, vtyp from scalar where sym=?", $self->{sym});
	} elsif ($self->{type} eq '%') {
		if ($self->{sym}) {
			$st = $self->dbexec('fetchhash',  "select val, vtyp from hash where sym=? and key=?", 
				$self->{sym}, $key);
		} else {
			$st = $self->dbexec('',  "select val, vtyp from $self->{table} where key=?", $key);
		}
	} elsif ($self->{type} eq '@') {
		if ($self->{sym}) {
			$st = $self->dbexec('fetcharray', "select val, vtyp from array where sym=? and ind=?", 
				$self->{sym}, $key);
		} else {
			$st = $self->dbexec('',  "select val, vtyp from $self->{table} where ind=?", $key);
		}
	} else {
		die;
	}
		
	my ($val, $vtyp) = $st->fetchrow_array();

	if (defined $act && $act eq 'EXISTS') {
		return defined $vtyp;
	}

	return tiesubrefs($self, $key, $val, $vtyp);
}

sub tiesubrefs {
#hereiam();
	my ($self, $key, $val, $vtyp) = @_;

        return undef if ! defined $vtyp;

	if ($vtyp eq '$') {
		return $val;
	}

	if ($vtyp eq '*') {
		$key = '' if !defined $key;
		if ($self->{ref}{$key}) {
			# already tied my ref
			return $self->{ref}{$key};
		} else {
			# create a new ref
			my $canon = canonical($self, $key);
			if ($val eq '$') {
				my $var;
				my $sub = tie $var, ref($self), %{$self}, sym=>$canon;
				$val = \$var;
			} elsif ($val eq '%') {
				my %var;
				my $sub = tie %var, ref($self), %{$self}, sym=>$canon;
				$val = \%var;
                        } elsif ($val eq '@') {
				my @var;
				my $sub = tie @var, ref($self), %{$self}, sym=>$canon;
				$val = \@var;
                        } else {
				require Carp;
		    		Carp::croak("Unknown reference type '$val' in $canon");
			}
		}
		die unless ref($val);
		return $self->{ref}{$key}=$val;
        }
	return undef;
}

sub STORE {
#hereiam();
	my $self = shift;
	$self->checkdb();

	my ($key, $val);

	if ($self->{type} eq '$') {
		($val) = @_;
	} else {
		($key, $val) = @_;
	}

	my $vtyp;

	if (ref($val)) {
		$key = '' if !defined $key;
		my $canon = canonical($self, $key);
		$self->{ref}{$key} = $val;
		$vtyp = '*';
		my $sub;
		if (ref($val) eq 'SCALAR') {
			my $sav = ${$val}; 
			tie ${$val}, ref($self), %{$self}, sym=>$canon;
			${$val} = $sav if defined $sav;
			$val = '$';
		} elsif (ref($val) eq 'HASH') {
			my %sav = %{$val}; 
                        tie %{$val}, ref($self), %{$self}, sym=>$canon;
			%{$val} = %sav if %sav;
                        $val = '%';
		} elsif (ref($val) eq 'ARRAY') {
			my @sav = @{$val}; 
                        $sub = tie @{$val}, ref($self), %{$self}, sym=>$canon;
			@{$val} = @sav if @sav;
                        $val = '@';
                } else {
			require Carp;
		    	Carp::croak("Can't store reference to " . ref($val) . " in $canon, try Data::Dumper instead");
		}
	} else {
		$vtyp = '$';
	}

	if ($DEBUG) {
		require Carp;
		Carp::cluck "store: $self->{type}:$self->{sym}($key) = $vtyp:$val\n" 
	}

	if ($self->{ttl}) {
		my $exp = time() + $self->{ttl};
		my $up = $self->dbexec('updateexp',    "update vars set exp=? where sym=? and styp=?",
				$exp, $self->{sym}, $self->{type});
	}

	if ($self->{type} eq '$') {
		if (!defined ($val)) {
        		$self->dbexec('delscalar', "delete from scalar where sym=?", $self->{sym});
		} else {
			my $up = $self->dbexec('updatescalar', "update scalar set val=?,vtyp=? where sym=?", 
					$val, $vtyp, $self->{sym});
			if ($up == 0) {
				$self->dbexec('insertscalar',  "insert into scalar (sym, val, vtyp) values (?, ?, ?)",
					$self->{sym}, $val, $vtyp);
			}
		}
        } elsif ($self->{type} eq '%') {
		if ($self->{sym}) {
		    if (!defined ($val)) {
        		$self->dbexec('delscalar', "delete from hash where sym=? and key=?", $self->{sym}, $key);
		    } else {
                	my $up = $self->dbexec('updatehash', "update hash set val=?,vtyp=? where sym=? and key=?",
				$val, $vtyp, $self->{sym}, $key);
                	if ($up == 0) {
                		$self->dbexec('inserthash', "insert into hash (sym, key, val, vtyp) values (?, ?, ?, ?)",
					$self->{sym}, $key, $val, $vtyp);
                	}
		    }
		} else {
		    if (!defined ($val)) {
        		$self->dbexec('', "delete from $self->{table} where key=?", $key);
		    } else {
                	my $up = $self->dbexec('', "update $self->{table} set val=?,vtyp=? where key=?", $val, $vtyp, $key);
                	if ($up == 0) {
                		$self->dbexec('', "insert into $self->{table} (key, val, vtyp) values (?, ?, ?)",
					$key, $val, $vtyp);
                	}
		    }
		}
        } elsif ($self->{type} eq '@') {
                if ($self->{sym}) {
			my $up = $self->dbexec('updatearray', "update array set val=?,vtyp=? where sym=? and ind=?",
					$val, $vtyp, $self->{sym}, $key);
			if ($up == 0) {
				$self->dbexec('insertarray', "insert into array (sym, ind, val, vtyp) values (?, ?, ?, ?)",
					$self->{sym}, $key, $val, $vtyp);
			}
                } else {
                        my $up = $self->dbexec('', "update $self->{table} set val=?,vtyp=? where ind=?", $val, $vtyp, $key);
                        if ($up == 0) {
                                $self->dbexec('', "insert into $self->{table} (ind, val, vtyp) values (?, ?, ?)",
                                        $key, $val, $vtyp);
                        }
		}
	} else {
		die "Unknown type $self->{type}\n";
	}

	return $val;
}

sub dbexec {
	my ($self, $name, $sql, @args) = @_;
	my $db = $self->{db} ? $self->{db} : $self;
	my $st;
	if ($name) {
		if (!($st = ($db->{private_ipc_lite_prep}||{})->{$name})) {
			$st = $db->{private_ipc_lite_prep}->{$name} = $db->prepare($sql);
		}
	} else {
		$st = $db->prepare($sql);
	}
	my $ok = $st->execute(@args);
	if ($ok && $st->{NUM_OF_FIELDS}) {
		return $st;
	} else {
		return $ok;
	}
}

sub END {
	# no refs to statement handles
	for my $tid_dbs (values(%DBS)) {
	for (values(%{$tid_dbs})) {
		$_->{private_ipc_lite_prep} = undef;
	}
	}
}

sub defaultpath {
	my ($self, $callpack) = @_;

        if (!$DEFAULT_PATH{$callpack}) {
		require Cwd;
                my $prog = Cwd::abs_path($0);
		#my $prog = $0;
		#require File::Spec;
		#$prog = (File::Spec->splitpath($prog))[2];
		$DEFAULT_PATH{$callpack} = nametopath($prog);
	}
	return $DEFAULT_PATH{$callpack};
}

sub nametopath {
	my ($name) = @_;
        $name =~ s/[\/\\\:\!\&\*]/_/g;
        require File::Spec;
        my $tmp = File::Spec->tmpdir;
        $tmp = File::Spec->catfile($tmp, "$name.ipclitedb");
        return $tmp;
}


sub fatalerror
{
    $SIG{__DIE__} = undef;
    require Carp;
    Carp::confess();
}

sub checkdb {
	my $self = shift;
	my $tid = threadid();
	if ($tid != $self->{tid}) {
	        $self->open_pathdb();
	}	
}

sub threadid {
	my $tid = 0;

	# todo add more methods
	
	$tid = eval {
		require threads;
		threads->self->tid();
	};

	if (!$tid && $^O =~ /win32/i) {
	$tid = eval {
		require Win32;
		Win32::GetCurrentThreadId();
	};
	}

	if (!$tid) {
		#this fixes forking issues on older perls
		$tid = $$;
	}
	
	return $tid;
}

sub hereiam {
	my ($package, $filename, $line, $subroutine) = caller(1);
	print "$package $line: $subroutine (";
	($package, $filename, $line, $subroutine) = caller(2);
	print "$package $line: $subroutine)\n";
}

1;

__END__

=head1 NAME

IPC::Lite - Share variables between processes

=head1 SYNOPSIS

Simple example creates package global shared variables named "count" and "stack".

 use IPC::Lite qw($count, @stack);

Example of a shared variable "temp", with a 5 second timeout.  
Uses 'globaltemp-v1' as the program key, so other programs with this key  
will also be able to access $temp.

 use IPC::Lite Key=>'globaltemp-v1', Timeout=>5, qw($temp);

 $temp = $ARGV[0] if $ARGV[0];

 print "temp is: $temp\n";

This example shows the power of using this module for IPC:

 use IPC::Lite qw($c);
 $c = undef;

 my $pid = fork;

 if ($pid) {
        wait;
	print "Child told me $c\n";
 } else {
	$c = "hello!";
 }

=head1 METHODS

=over 4

=item use IPC::Lite [opt1=>value1[, opt2=>value2 ...],] qw(var1[ var2]...);

Possible options are:

        Key=>NAME - Unique name of your data store, if not set then one is created for you
	Timeout=>VALUE - Specifies timeout in seconds or in days if "d[ays]" is appended to the VALUE
	Ttl=>VALUE - Alias for timeout
	Path=>PATH - Path to the data store used.  IPC will fail if the path cannot be written to

Option names are case insensitive.

If no "vars" are specified, the options are saved as package-level defaults.

If "vars" are specified, then the options are used for *those vars only*, and are not saved as defaults.

For example, this creates 2 package-global variables with different timeouts:

 use IPC::Lite Key=>'myuniquekey', 
	       Timeout=>5, qw($fleeting), 
	       Timeout=>'10d', qw($lasting);

=item tie $var, 'IPC::Lite', %options

Makes the variable shared as above, but the variable can be a proper lexical.  Uses package defaults if any are set.

Same options described in "use" above, but must also chose one of these two required binding methods:

	Sym=>SYMBOL - Name of the symbol tied to (valid for any variable)
	Table=>NAME - Name of the table to store the variable in (valid ONLY for hash or array).

NOTE:

The "use" method above merely calls the "tie" method (here) with the Sym option set to the 
name of the symbol passed in.  The caller's package is added to the symbol name for storage only if the caller's 
package is not "main".  You shouldn't need to know this.

=item path()

Prints the path of the data store.

 tied($var)->path();

=item db()

Returns the active database handle.  Probably shouldn't use it to mess with internals, unless that's your intention.

 tied($var)->db();

=back

=head1 SEE ALSO

L<DBD::SQLite>

=head1 AUTHOR

Erik Aronesty C<earonesty@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html> or the included LICENSE file.

=cut

