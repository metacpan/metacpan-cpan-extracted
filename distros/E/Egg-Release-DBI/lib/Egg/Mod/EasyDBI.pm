package Egg::Mod::EasyDBI;
#
# Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>
#
# $Id: EasyDBI.pm 353 2008-07-25 01:25:46Z lushe $
#
use strict;
use warnings;
use base qw/ Class::Accessor::Fast Class::Data::Inheritable /;
use Carp qw/croak/;

our $VERSION= '3.08';
our $AUTOLOAD;

__PACKAGE__->mk_accessors(qw/
  dbh sql_abstract commit_ok rollback_ok alias upgrade_ok clear_ok
  /);
__PACKAGE__->mk_classdata('config');

sub import {
	my $class= shift;
	my $opt= shift || {};
	no warnings 'redefine';
	*debug= $opt->{debug} ? CORE::do {
		ref($opt->{debug}) eq 'CODE' ? $opt->{debug}: sub {
			shift; my @ca= caller();
			print STDERR "EasyDBI>> "
			. (join(', ', @_) || 'N/A'). " at $ca[0] line $ca[2]\n";
		  };
	  }: sub {};
	if (my $abs= $opt->{sql_abstract}) {
		require SQL::Abstract;
		*sql_abstract= sub {
			$_[0]->{sql_abstract} ||= SQL::Abstract->new(%$abs);
		  };
	} else {
		*sql_abstract= sub {
			croak q{ 'sql_abstract' is unavailability. };
		  };
	}
	$opt->{upgrade_ok} ||= 0;
	$opt->{clear_ok}   ||= 0;
	$opt->{alias}      ||= {};
	$class->config($opt);
	$class;
}
sub new {
	my $class= shift;
	my $dbh= shift || croak q{ I want DBI context. };
	my $opt= {
	   %{$class->config},
	   %{$_[0] ? (ref($_[0]) eq 'HASH' ? $_[0]: {@_}): {}},
	   };
	if (my $trace= $opt->{trace})
	   { $dbh->trace( ref($trace) eq 'ARRAY' ? @$trace: $trace ) }
	bless { %{$opt},
	  dbh         => $dbh,
	  commit_ok   => 0,
	  rollback_ok => 0,
	  }, $class;
}
sub hashref {
	my $self= shift;
	my $sql = shift || croak q{ I want SQL statement. };
	$self->debug($sql);
	my %bind;
	my $sth= $self->dbh->prepare($sql);
	$sth->execute(ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_);
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	$sth->fetch || return CORE::do { $sth->finish; undef };
	$sth->finish;
	wantarray ? %bind: \%bind;
}
sub arrayref {
	my $self= shift;
	my $sql = shift || croak q{ I want SQL statement. };
	$self->debug($sql);
	my($args, $code)= __args(@_);
	$code ||= sub {
		my($array, %hash)= @_;
		push @$array, \%hash
	  };
	my(@array, %bind);
	my $sth= $self->dbh->prepare($sql);
	$sth->execute(@$args);
	$sth->bind_columns(\(@bind{map{$_}@{$sth->{NAME_lc}}}));
	while ($sth->fetch) { $code->(\@array, %bind) }
	$sth->finish;
	@array ? (wantarray ? @array: \@array): undef;
}
*list= \&arrayref;
sub scalarref {
	my $self= shift;
	my $sql = shift || croak q{ I want SQL statement. };
	$self->debug($sql);
	my $result;
	my $sth= $self->dbh->prepare($sql);
	$sth->execute(ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_);
	$sth->bind_columns(\$result);
	$sth->fetch; $sth->finish;
	defined($result) ? \$result: undef;
}
sub scalar {
	my $result= shift->scalarref(@_) || return (undef);
	$$result;
}
sub do {
	my $self= shift;
	my $sql = shift || croak q{ I want SQL statement. };
	$self->debug($sql);
	$self->dbh->do($sql, undef, (ref($_[0]) eq 'ARRAY' ? @{$_[0]}: @_));
}
sub db {
	my $self= shift;
	@_ ? Egg::Mod::EasyDBI::joindb->new($self, @_)
	   : ($self->{db} ||= Egg::Mod::EasyDBI::db->new($self));
}
sub close {
	my($self)= @_;
	my $dbh= $self->dbh || return 0;
	unless ($dbh->{AutoCommit}) {
		eval{
			if ($self->commit_ok and ! $self->rollback_ok) {
				$dbh->commit;
				$self->debug(__PACKAGE__. ' : commit.');
			} else {
				$dbh->rollback;
				$self->debug(__PACKAGE__. ' : rollback.');
			}
		  };
		$@ and warn $@;
	}
	$self->dbh(undef);
	$self;
}
sub __args {
	ref($_[0]) eq 'ARRAY' ? ($_[0], ($_[1] || 0)): (\@_, 0);
}
sub AUTOLOAD {
	my $self= shift;
	my($method)= $AUTOLOAD=~/([^\:]+)$/;
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	*{__PACKAGE__."::$method"}= sub { shift->dbh->$method(@_) };
	$self->$method(@_);
}
sub DESTROY {
	shift->close(@_);
}

package Egg::Mod::EasyDBI::db;
use strict;
use warnings;

our $AUTOLOAD;

sub new {
	bless [$_[1], {}], $_[0];
}
sub AUTOLOAD {
	my($self)= @_;
	my($dbname)= $AUTOLOAD=~/([^\:]+)$/;
	my $class= __PACKAGE__."::$dbname";
	no strict 'refs';  ## no critic
	no warnings 'redefine';
	@{"${class}::ISA"}= 'Egg::Mod::EasyDBI::table';
	*{__PACKAGE__."::$dbname"}= sub {
		my($proto)= @_;
		$proto->[1]{$dbname} ||= $class->new($proto->[0], $dbname);
	  };
	$self->$dbname;
}
sub DESTROY {}

package Egg::Mod::EasyDBI::table;
use strict;
use warnings;
use Carp qw/croak/;

my $argc= 'Egg::Mod::EasyDBI::args';

sub new {
	my($class, $es, $dbname)= @_;
	if (my $alias= $es->alias->{$dbname}) { $dbname= $alias }
	bless { es=> $es, dbname=> $dbname }, $class;
}
sub hashref {
	my $self= shift;
	my $a= $argc->_hashref(@_);
	$self->{es}->hashref
	("SELECT $a->{cols} FROM $self->{dbname} $a->{st}", $a->{ex});
}
sub arrayref {
	my $self= shift;
	my $a= $argc->_arrayref(@_);
	$self->{es}->arrayref
	("SELECT $a->{cols} FROM $self->{dbname} $a->{st}", $a->{ex}, $a->{cd});
}
*list= \&arrayref;
sub scalarref {
	my $self= shift;
	my $col = shift || croak q{ I want column. };
	   $col = $$col if ref($col) eq 'SCALAR';
	my $a= $argc->_scalarref(@_);
	$self->{es}->scalarref
	("SELECT $col FROM $self->{dbname} $a->{st}", $a->{ex});
}
sub scalar {
	my $result= shift->scalarref(@_) || return (undef);
	$$result;
}
sub insert {
	my $self= shift;
	my $a= $argc->_insert(@_);
	my $sql= qq{INSERT INTO $self->{dbname}}
	       . qq{ (}. join(', ', keys %$a). q{) VALUES}
	       . qq{ (}. join(', ', map{"?"}keys %$a). q{)};
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef, values %$a)
	> 0 ? 1: 0;
}
*in= \&insert;
sub update {
	my $self= shift;
	my $a= $argc->_update(@_);
	my $sql= qq{UPDATE $self->{dbname} SET }
	       . join(', ', keys %{$a->{up}}). qq{ WHERE $a->{st}};
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef, (values %{$a->{up}}), @{$a->{ex}})
	> 0 ? 1: 0;
}
*up= \&update;
sub update_insert {
	my $self= shift;
	return "0E0" if $self->update(@_);
	if (my $error= $self->{es}->dbh->errstr) { die $error }
	$self->insert(@_);
}
sub find_insert {
	my $self= shift;
	my $col = shift || croak q{ I want column name. };
	@_ || croak q{ I want argument. };
	my $hash= ref($_[0]) eq 'HASH'
	   ? $_[0] : CORE::do { (scalar(@_)% 2)== 0 ? {@_}: {$col, @_} };
	return "0E0" if $self->scalarref($col, "$col = ?",
	  (ref($hash->{$col}) eq 'ARRAY' ? $hash->{$col}->[0]: $hash->{$col}));
	$self->insert($hash);
}
sub for_update {
	my $self= shift;
	my $st  = shift || croak q{ I want column. };
	   $st  = $$st if ref($st) eq 'SCALAR';
	my $val = shift || croak q{ I want value. };
	my $sql = "SELECT * FROM $self->{dbname} WHERE $st = ? FOR UPDATE";
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef, $val) > 0 ? 1: 0;
}
sub delete {
	my $self= shift;
	my $st  = shift || die q{ I want argument. };
	   $st  = $$st if ref($st) eq 'SCALAR';
	my $ex  = ref($_[0]) eq 'ARRAY' ? $_[0]: [@_];
	my $sql = qq{DELETE FROM $self->{dbname} WHERE $st };
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef, @$ex) > 0 ? 1: 0;
}
sub upgrade {
	my $self= shift;
	$self->{es}->upgrade_ok
	|| croak q{ There is effectively no 'upgrade_ok'. };
	my $a= $argc->_upgrade(@_);
	my $sql= qq{UPDATE $self->{dbname} SET }. join(', ', keys %{$a->{up}});
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef, (values %{$a->{up}}))
	> 0 ? 1: 0;
}
sub clear {
	my $self= shift;
	$self->{es}->clear_ok
	|| croak q{ There is effectively no 'clear_ok'. };
	my $sql= qq{DELETE FROM $self->{dbname}};
	$self->{es}->debug($sql);
	$self->{es}->dbh->do($sql, undef) > 0 ? 1: 0;
}
sub abs_hashref {
	my $self= shift;
	$self->{es}->hashref
	  ($self->{es}->sql_abstract->select($self->{dbname}, @_));
}
sub abs_arrayref {
	my $self= shift;
	my $code= ref($_[$#{@_}]) eq 'CODE' ? pop(@_): undef;
	my($stmt, @bind)= $self->{es}->sql_abstract->select($self->{dbname}, @_);
	$self->{es}->arrayref($stmt, \@bind, $code);
}
*abs_list= \&abs_arrayref;
sub abs_scalarref {
	my $self= shift;
	$self->{es}->scalarref
	  ($self->{es}->sql_abstract->select($self->{dbname}, @_));
}
sub abs_scalar {
	my $self= shift;
	my $result= $self->abs_scalarref(@_) || return (undef);
	$$result;
}
sub abs_insert { shift->_abs_do('insert', @_) }
sub abs_update { shift->_abs_do('update', @_) }
sub abs_delete { shift->_abs_do('delete', @_) }
sub _abs_do {
	my($self, $method)= splice @_, 0, 2;
	my($stmt, @bind)= $self->{es}->sql_abstract->$method($self->{dbname}, @_);
	$self->{es}->debug($stmt);
	$self->{es}->dbh->do($stmt, undef, @bind) > 0 ? 1: 0;
}

package Egg::Mod::EasyDBI::joindb;
use strict;
use Tie::Hash::Indexed;
use Carp qw/croak/;

my %ixnames; {
	my @ixnames= ('a'..'z');
	tie %ixnames, 'Tie::Hash::Indexed';
	%ixnames= map{ $_=> $ixnames[$_] }(0..$#ixnames);
  };

my %jkey= (
  '='    => 'JOIN',
  '<'    => 'LEFT OUTER JOIN',
  '>'    => 'RIGHT OUTER JOIN',
  '@'    => 'FULL OUTER JOIN',
  '_'    => 'INNER JOIN',
  'join' => 'JOIN',
  'left' => 'LEFT OUTER JOIN',
  'right'=> 'RIGHT OUTER JOIN',
  'full' => 'FULL OUTER JOIN',
  'inner'=> 'INNER JOIN',
  );

sub new {
	my($class, $es)= splice @_, 0, 2;
	my $args = $_[0] ? (ref($_[0]) eq 'ARRAY' ? $_[0]: \@_)
	                 : croak q{ I want argument. };
	my $count= 0;
	my $from = shift(@$args). " $ixnames{$count++}";
	my $alias= $es->alias;
	while (1) {
		my $uni= shift || last;
		my $fro= shift || last;
		my $i= $ixnames{$count++};
		my($table, $on)= $fro=~m{^\s*(.+?)\s*\:\s*(.+)};
		if (my $name= $alias->{$table}) { $table= $name }
		my $j= $jkey{lc $uni} || croak q{ Format with bad argument. };
		$on=~s{\s*\=\s*} [ = ];
		$from.= " $j $table $i ON $on";
	}
	bless [$from, $es], $class;
}
sub hashref {
	my $self= shift;
	my $a= $argc->_hashref(@_);
	$self->[1]->hashref
	("SELECT $a->{cols} FROM $self->[0] $a->{st}", $a->{ex});
}
sub arrayref {
	my $self= shift;
	my $a= $argc->_arrayref(@_);
	$self->[1]->arrayref
	("SELECT $a->{cols} FROM $self->[0] $a->{st}", $a->{ex}, $a->{cd});
}
*list= \&arrayref;
sub scalarref {
	my $self= shift;
	my $col = shift || croak q{ I want column. };
	   $col = $$col if ref($col) eq 'SCALAR';
	my $a= $argc->_scalarref(@_);
	$self->[1]->scalarref
	("SELECT $col FROM $self->[0] $a->{st}", $a->{ex});
}
sub scalar {
	my $result= shift->scalarref(@_) || return (undef);
	$$result;
}

package Egg::Mod::EasyDBI::args;
use strict;
use Carp qw/croak/;
sub _hashref {
	my $class= shift;
	my @args = @_;
	@args || return { cols=> '*', st=> '', ex=> [] };
	my $cols= $class->_get_cols(\@args);
	$class->_get_st($cols, \@args);
}
sub _scalarref {
	my $class= shift;
	my @args = @_;
	$class->_get_st("", \@args);
}
sub _arrayref {
	my $class= shift;
	my @args = @_;
	@args || return { cols=> '*', st=> '', ex=> [], cd=> 0 };
	my $cols= $class->_get_cols(\@args);
	my $a= $class->_get_st($cols, \@args);
	my $code;
	(! $a->{cd} and $code= $args[$#args] and ref($code) eq 'CODE')
	   ? { %$a, cd=> $code }: $a;
}
sub _insert {
	my $class= shift;
	my @args = @_;
	shift(@args) if ref($args[0]) eq 'SCALAR';
	$args[0] || croak q{ I want argument. };
	my $hash= ref($args[0]) eq 'HASH' ? $args[0]: {@args};
	my %in;
	while (my($key, $v)= each %$hash) {
		next unless defined($v);
		if (my $type= ref($v)) {
			if ($type eq 'ARRAY') {
				next unless defined($v->[1]);
				$in{$key}= ref($v->[1]) eq 'SCALAR' ? ${$v->[1]}: $v->[1];
				next;
			} elsif ($type eq 'SCALAR') {
##				$in{$key}= $$v;
				next;
			}
		}
		$in{$key}= $v;
	}
	\%in;
}
sub _update {
	my $class= shift;
	my @args = @_;
	my($st, $ps)= $class->_parse_st(\@args);
	my($hash, $ignor)= $class->_get_hash(\@args);
	my(@ex, %n, %up);
	for (@$ps) {
		if (my $v= $hash->{$_}) {
			if (! ref($v)) {
				push @ex, $v;
			} elsif (ref($v) eq 'SCALAR') {
				push @ex, $v;
#				die qq{ '$_' is a scalar reference. };
			} elsif (defined($v->[0])) {
				if (ref($v->[0]) eq 'ARRAY') {
					my $N= $n{$_} || 0;
					push @ex, (defined($v->[0][$N]) ? $v->[0][$N]: undef);
					++$n{$_};
				} else {
					push @ex, $v->[0];
				}
			} else {
				push @ex, undef;
			}
		} else {
			push @ex, (defined($hash->{$_}) ? 0: undef);
		}
	}
	my $up= $class->_get_up($hash, $ignor);
	{ up=> $up, st=> $st, ex=> \@ex };
}
sub _upgrade {
	my $class= shift;
	my @args = @_;
	{ up=> $class->_get_up( $class->_get_hash(\@args) ) };
}
sub _parse_st {
	my $class= shift;
	my($a)= @_; $a->[0] || croak q{ I want argument. };
	return ("$a->[0] = ?", [$a->[0]]) unless ref($a->[0]) eq 'SCALAR';
	my $st= shift @$a;
	my @ps;
	while ($$st=~m{\"?([A-Za-z0-9_\-]+)\"?\s*(?:\!?\=|<|>|i?like)\s*\?}ig) {
		push @ps, $1;
	}
	($$st, \@ps);
}
sub _get_up {
	my $class= shift;
	my($hash, $ignor)= @_;
	my %up;
	while (my($key, $v)= each %$hash) {
		next if $ignor->{$key};
		defined($v) || do { $up{"$key = ?"}= undef; next };
		if (! ref($v)) {
			$up{"$key = ?"}= $v;
		} elsif (ref($v) eq 'SCALAR') {
			$up{"$key = $key + ?"}= $$v;
		} elsif (ref($v) eq 'ARRAY') {
			if (defined($v->[1])) {
				if (ref($v->[1]) eq 'SCALAR') {
					$up{"$key = $key + ?"}= ${$v->[1]};
				} else {
					next if ref($v->[1]) eq 'HASH';
					$up{"$key = ?"}= $v->[1];
				}
			} else {
##				$up{"$key = ?"}= undef;
warn __PACKAGE__. " : Reference not Sarported. [$key] => @{[ ref($v) ]}.";
			}
		}
	}
	\%up;
}
sub _get_hash {
	my $class= shift;
	my($a)= @_; $a->[0] || croak q{ I want argument. };
	ref($a->[0]) eq 'HASH' ? do {
		return ($a->[0], {}) unless $a->[1];
		my $hash= shift(@$a);
		my $igno= ref($a->[0]) eq 'ARRAY' ? $a->[0]: \@$a;
		($hash, { map{$_=> 1}@$igno });
	  }: ({@$a}, {});
}
sub _get_cols {
	my $class= shift;
	my($a)= @_;
	ref($a->[0]) eq 'SCALAR' ? do { my $tmp= shift(@$a); $$tmp }: '*';
}
sub _get_st {
	my $class= shift;
	my($cols, $a)= @_;
	$a->[0] || return { cols=> $cols, st=> '', ex=> [], cd=> 0 };
	my $st= ref($a->[0]) eq 'ARRAY'
	   ? (join(' ', @{(shift(@$a))}) || ""): 'WHERE '. shift(@$a);
	defined($a->[0]) || return { cols=> $cols, st=> $st, ex=> [], cd=> 0 };
	ref($a->[0]) eq 'ARRAY'
	  ? { cols=> $cols, st=> $st, ex=> $a->[0], cd=> 0 }: do {
		($a->[1] and ref($a->[1]) eq 'CODE')
		  ? { cols=> $cols, st=> $st, ex=> [$a->[0]], cd=> $a->[1] }
		  : { cols=> $cols, st=> $st, ex=> $a, cd=> 0 };
	  };
}

1;

__END__

=head1 NAME

Egg::Mod::EasyDBI - DBI is easily made available. 

=head1 SYNOPSIS

  use Egg::Mod::EasyDBI {
    debug      => 1,
    trace      => 1,
    upgrade_ok => 1,
    clear_ok   => 1,
    alias => {
      members => 'member_management_master',
      ...
      },
    sql_abstract=> {
      logic => 'and',
      ......
      },
    };
  use DBI;
  
  my $dbh= DBI->connect( ...... );
  my $es= Egg::Mod::EasyDBI->new($dbh);
  
  $ed->trace(1);
  my $db= $es->db;
  my $members= $db->members;
  
  # SELECT * FROM members WHERE id = ?
  my $hoge= $members->hashref('id = ?', $id)
         || die q{ Data is not found. };
  
  # SELECT * FROM members WHERE age > ?
  my $list= $members->arrayref('age > ?', 20)
         || die q{ Data is not found. };
  
  # SELECT id FROM members WHERE user = ?
  my $id= $members->scalar(\'id', 'user = ?', 'boo')
         || die q{ Data is not found. };
  
  # The processed list is acquired.
  my $list= $members->arrayref('age > ?', [20], sub {
       my($array, %hash)= @_;
       push @$array, "$hash{id} : $hash{user} : $hash{age}";
    }) || die q{ Data is not found. };
    
  # The data that can be immediately used is acquired.
  my $text;
  $members->arrayref('age > ?', [20], sub {
       my($array, %hash)= @_;
       $text.= <<END_DATA;
  ---------------------------
  ID   : $hash{id}
  NAME : $hash{user}
  AGE  : $hash{age}
  END_DATA
    }) || "";
    
  # INSERT INTO members (id, user, age) VALUES (?, ?, ?);
  $members->insert( id=> 1, user=> 'zoo', age=> 20 )
      || die q{ Fails in regist of data. };
  
  # UPDATE members SET other = ?, age = age + 1 WHERE id = ?
  $members->update( id=> 1, other=> 'gao', age=> \1 )
      || die q{ Fails in update of data. };
  or
  $members->update(\'id = ?', { id=> [1], other=> 'gao', age=> \1 })
      || die q{ Fails in update of data. };
  
  # The record is added when failing in the update.
  $members->update_insert( user=> 'zaza', age=> 22 );
  
  # It adds it if there is no record.
  $members->find_insert( user=> 'zaza', age=> 22 );
  
  # UPDATE members SET age = ?
  $members->upgrade( age=> 20 );
  
  # DELETE FROM members WHERE user = ?
  $members->delete('user = ?', 'zaza');
  
  # DELETE FROM members;
  $members->clear;
  
  # SQL statement is used as it is.
  my $hash  = $es->hashref(q{SELECT * FROM members WHERE id = ?}, $id);
  my $list  = $es->arrayref(q{SELECT * FROM members WHERE age > ?}, $age);
  my $scalar= $es->scalar(q{SELECT user FROM members WHERE id = ?}, $id);
  $es->do(q{INSERT INTO members (id, user, age) VALUES (?, ?, ?)}, $id, $user, $age);
  
  # [[SQL::Abstract]] support.
  my $hash = $members->abs_hashref(\@fields, \%where, \@order);
  my $array= $members->abs_arrayref(\@fields, \%where, \@order);
  $members->abs_insert(\%fieldvals || \@values);
  $members->abs_update(\%fieldvals, \%where);
  $members->abs_delete(\%where);
  
  # Table uniting.
  #
  # SELECT a.user, a.message, b.id, b.age, c.email_addr
  #   FROM messages a JOIN members b ON a.user = b.user
  #        LEFT JOIN profiles c ON b.id = c.id
  #   WHERE  a.message_id = ?
  #
  my $jdb= $es->db(qw/ messages = members:a.user=b.user < profiles:b.id=c.id /);
  my $list= $jdb->arrayref(
     \'a.user, a.message, b.id, b.age, c.email_addr',
     'a.message_id = ?', $msgid
     );
  
  # If you process the transaction
  # If commit_ok is undefined, it is always rollback.
  $es->commit_ok(1);
  $es->close;
  
  $dbh->disconnect;

=head1 DESCRIPTION

The processing of DBI by which the code tends to become complex is made available
by an easy code.

The use of L<SQL::Abstract> is enabled by the thing set to 'sql_abstract' by the
start option.

  use Egg::Mod::EasyDBI {
    sql_abstract => {
      logic => 'and',
      ......
      },
    };

This module doesn't correspond to CLOB of Oracle and bind_param to the BLOB field.

This module is not only for L<Egg>. It is possible to use it also with the unit.

=head1 OPTIONS

The start option can be defined by the HASH reference.

  use Egg::Mod::EasyDBI {
    debug => 1,
    ......
    };

=head2 debug => [BOOL]

Debug mode is made effective.

SQL sentence issued to STDERR is output when keeping effective.

=head2 trace => [TRACE_LEBEL] or [ [TRACE_LEBEL], [TRACE_FILE] ]

It passes it to the trace method of the data base handler.

To pass TRACE_FILE, it defines it by the ARRAY reference.

  trace => [3, '/path/to/trace_log'],

=head2 upgrade_ok => [BOOL]

The upgrade method can be used with the table object. When the upgrade method is
called, the exception is generated when this is invalid.

=head2 clear_ok => [BOOL]

The clear method can be used with the table object. When the clear method is
called, the exception is generated when this is invalid.

=head2 alias => [HASH_REF]

The alias to the table name is defined. 

Using it when a very long table name is used or multi byte character is used
for the table name is convenient.

  alias=> {
    members => 'member_management_master',
    profiles=> 'member_profile_master',
    },

The table object is used with a set key.

  my $table= $ed->db->profiles;

=head2 sql_abstract => [HASH_REF]

L<SQL::Abstract> can be used.

The content of HASH is an option to pass everything to L<SQL::Abstract>.

Especially, empty HASH is set if there is no option to specify.

 sql_abstract => {},

=head1 METHODS

=head2 new ([DBH], [OPTIONS])

Constructor.

The data base handler made beforehand is passed to DBH.
OPTIONS is accepted among the start options excluding debug, sql_abstract, and
alias. This OPTIONS overwrites a set value of the start option.

  my $dbh= DBI->connect( .... );
  my $es= Egg::Mod::EasyDBI->new($dbh); 

=head2 config

A set value of the start option is returned.

=head2 dbh

The data base handler passed to the constructor is returned.

When the method of no support with this object is called, the method of the data
base handler is called.

  $es->trace(1);
  $es->commit;
  $es->rollback;
    
  # The reference to the value of the data base handler is impossible.
  # The data base handler is seen directly.
  if ($es->dbh->{Active}) {
     .......
  }

=head2 db ([ARGS])

When ARGS is not passed, the object of Egg::Mod::EasyDBI::db is returned.
When ARGS is passed, the object of Egg::Mod::EasyDBI::joindb is returned.

  my $db= $es->db;

  my $jdb= $es->db(qw/ members = profiles:a.id=b.id /);

=head2 commit_ok ([BOOL])

When the close method is called, commit is done if this value is effective.
This is convenient to settle at the end of processing and to issue committing.

This method functions only when the transaction is effective.

  $es->commit_ok(1);

=head2 rollback_ok ([BOOL])

When the close method is called, rollback is done if this value is effective.
If it is not necessary to commit it, the method always does rollback.
Therefore, this method need not usually be considered.
It is good to make this method effective when the error etc. occur during 
processing.  Rollback is done regardless of the state of commit_ok when this
value is effective.

This method functions only when the transaction is effective.

 $es->rollback_ok(1);

=head2 alias

The alias data of the table set by the start option etc. is returned.

=head2 upgrade_ok ([BOOL])

The upgrade method can keep effective and be invalidated temporarily.
If the upgrade method is called when this value returns false, the exception is
generated.

  $es->upgrade_ok(1);

=head2 clear_ok ([BOOL])

The clear method can keep effective and be invalidated temporarily.
If the clear method is called when this value returns false, the exception is
generated.

  $es->clear_ok(1);

=head2 sql_abstract

If 'sql_abstract' is set by the start option, the object of L<SQL::Abstract> is
returned.  If 'sql_abstract' is invalid, the exception is generated.

  my $abs= $es->sql_abstract;

=head2 hashref ([SQL_STATEMENT], [EXECUTE_ARGS])

The result of SELECT is returned by the HASH reference.
Therefore, SQL_STATEMENT is SELECT always sentence.
Moreover, because it is data that is returned for one record, it is necessary to
make it to SQL_STATEMENT of corresponding.

When the result is not obtained, anything returns undefined.

There is no EXECUTE_ARGS needing if Prasfolda is not included in SQL_STATEMENT.

  if (my $hash= $es->hashref(q{SELECT * FROM members WHERE id = ?}, $id)) {
    .......
  } else {
    die q{ Data is not found };
  }

=head2 arrayref ([SQL_STATEMENT], [EXECUTE_ARGS], [CODE_REF])

The result of SELECT is returned by the ARRAY reference. Therefore, SQL_STATEMENT
is SELECT always sentence.

When the result is not obtained, anything returns undefined.

There is no EXECUTE_ARGS needing if Prasfolda is not included in SQL_STATEMENT.

CODE_REF executed at the same time by the loop in the method can be passed.
The list received by this is looped further and it comes do not to have to 
process it.  HASH with the ARRAY reference for the return value of the method
and the column of each record is passed to this CODE_REF.

  $es->arrayref('SELECT ...', [ ... ], sub {
    my($array, %hash)= @_;
    ........
    push @$array, \%hash;
    });

Undefined returns when nothing is put in $array.

Please pass EXECUTE_ARGS by the ARRAY reference when you pass CODE_REF.
An empty ARRAY reference is passed if there is no something given to EXECUTE_ARGS.

=over 4

=item * Alias = list 

=back

=head2 scalarref ([SQL_STATEMENT], [EXECUTE_ARGS])

The result of SELECT is returned by the SCALAR reference.
Therefore, SQL_STATEMENT is SELECT sentence that specifies one column received
without fail.

When the result is not obtained, anything returns undefined.

There is no EXECUTE_ARGS needing if Prasfolda is not included in SQL_STATEMENT.

  my $scalar_ref= $es->scalarref(q{SELECT user_name FROM ...... }, $id);

=head2 scalar ([SQL_STATEMENT], [EXECUTE_ARGS])

The result of the scalarref method is returned with usual scalar.

  my $scalar= $es->scalarref(q{SELECT user_name FROM ...... }, $id);

=head2 do ([SQL_STATEMENT], [EXECUTE_ARGS]);

SQL_STATEMENT that doesn't need the result is executed.

Please note that some hows to pass the argument are different from the do method
of the data base handler.

There is no EXECUTE_ARGS needing if Prasfolda is not included in SQL_STATEMENT.

  $es->do(q{INSERT INTO members (id, user, age) VALUES (1, 'user_name', 20)});

=head2 close

If the transaction is effective, commit or rollback is done.
And, it makes it to unavailability annulling the data base handler. 

Please disconnect is not done.

  $es->close;
  $dbh->disconnect;

I think it is good only to do disconnect if the transaction is invalid.

  $dbh->disconnect;

=head1 DB OBJECT METHODS

This object doesn't have the method that can be especially used.

A peculiar table object is returned considering the character string passed as
a method to be a table name.

  $members= $es->db->members;

=head2 new

Constructor. The Egg::Mod::EasyDBI::db object is returned.

  my $db= $es->db;

=head1 TABLE OBJECT METHODS

The method of this object becomes possible the shape succeeded to by the table
class generated with Egg::Mod::EasyDBI::db use.

=head2 new

Constructor. The Egg::Mod::EasyDBI::table object is returned.
When Egg::Mod::EasyDBI::db returns the table object, this constructor is called.
It is not necessary to call it from the application.

  my $table= $es->db->table_name;

=head2 hashref ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

The data for one acquired record is returned by the HASH reference.

Undefined returns when the record was not able to be acquired.

COLUMN is SCALAR reference for which the column that wants to be acquired is 
delimited by ','.

It is treated so that '*' is specified when COLUMN is omitted.
Moreover, please make STATEMENT the first argument when omitting it.

STATEMENT is SQL sentence following WHERE.
It ties by switching off the half angle space district when passing it by the ARRAY
reference if it doesn't want to insert 'WHERE' and it is treated as STATEMENT.

There is no EXECUTE_ARGS needing if Prasfolda is not included in STATEMENT.

  my $hash= $table->hashref(\'id, user, age', 'id = ?', $id);
  
  my $hash= $table->hashref('id = ?', $id);
  
  my $hash= $table->hashref(q{ user = '$user' });
  
  my $hash= $table->hashref([qw/ ORDER BY age OFFSET 0 LIMIT 1 /]);

=head2 arrayref ([COLUMN], [STATEMENT], [EXECUTE_ARGS], [CODE_REF])

The acquired data is returned by the ARRAY reference.

The way to give the argument is almost the same as the hashref method.

The treatment of CODE_REF is the same as arrayref of the L<Egg::Mod::EasyDBI>
object.

  my $list= $table->arrayref(\'id, user, age', 'age = ?', $age);
  
  my $list= $table->arrayref('age = ?', $age);
  
  my $list= $table->arrayref(qq{ age = $age });
  
  my $list= $table->arrayref([qw/ ORDER BY age DESC /]);
  
  my $list= $table->arrayref(\'id, user', [qw/ ORDER BY age DESC /], [], sub {
    my($array, %hash)= @_;
    push @$array, "ID=$hash{id}, USER=$hash{user}";
    });
  
  my $text;
  $table->arrayref('age > ?', [$age], sub {
    my($array, %hash)= @_;
    $test .= <<END_DATA;
  ---------------------------
  ID   : $hash{id}
  USER : $hash{user}
  AGE  : $hash{age}
  END_DATA
    });

=over 4

=item *  list

=back

=head2 scalarref ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

The acquired data is returned by the SCALAR reference.

It is necessary to specify one acquired column for COLUMN.

STATEMENT and EXECUTE_ARGS become hows to pass other similar methods.

When the result is not obtained, anything returns undefined.

  my $scalar_ref= $table->scalarref(\'count(id)');
  
  my $scalar_ref= $table->scalarref(\'id', 'user = ?', $user);

=head2 scalar ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

The result of the scalarref method is returned with usual SCALAR.

  my $scala= $table->scalarref(\'count(id)');
  
  my $scalar= $table->scalarref(\'id', 'user = ?', $user);

=head2 insert (HASH)

The record is added.

HASH cares about neither HASH reference nor usual HASH.

When failing in the addition, undefined is returned. 

  $table->insert( id=> 1, user=> 'hoge', age=> 20 );
  
  $table->insert({ id=> 1, user=> 'hoge', age=> 20 });

=over 4

=item * Alias = in

=back

=head2 update ([STATEMENT], [HASH])

It updates record.

STATEMENT is passed by the SCALAR reference in SQL sentence following WHERE.

The update data is passed to HASH by the HASH reference.

If Prasfolda is included in STATEMENT, the value of the key that HASH corresponds
is specified by the ARRAY reference.  The first element is passed and it is passed
that the value for the retrieval and the value of the second element for the update.
At this time, when the second element is omitted, it becomes data used only for the
retrieval.  If the same value as Prasfolda is referred, the first element is made
ARRAY reference further.  It sequentially extends to Prasfolda by this.

When STATEMENT is omitted, HASH is made the first argument and it passes it 
with usual HASH.  At this time, the column corresponding to the first key is
retrieved most.

The numerical value is passed to the value of HASH by the SCALAR reference at 
the update concerning the addition and subtraction of the numerical value.

  # UPDATE $table SET user = 'zoo', age = age + 1 WHERE user = 'hoge'
  $table->update(\'user = ?', { user=> [qw/ hoge zoo /], age=> \1 });
    or  
  $table->update( user=> [qw/ hoge zoo /], age=> \1 );
  
  # UPDATE $table SET age = age + 1 WHERE user = 'hoge'
  $table->update(\'user = ?', { user=> ['hoge'], age=> \1 });
    or
  $table->update( user=> ['hoge'], age=> \1 );
  
  # UPDATE $table SET age = age + -1 WHERE user = 'hoge' or user = 'zoo'
  $table->update(\'user = ? or user = ?', { user=> [[qw/ hoge zoo /]], age=> \"-1" });

=over 4

=item * Alias = up

=back

=head2 update_insert ([STATEMENT], [HASH])

The record is added if the update is tested and it fails.

When succeeding in the update, 0E0 is restored. Undefined returns when failing
in the addition.

The way to give STATEMENT and HASH is the same as update.
However, the data used to add and subtract the numerical value is excluded from
an additional object.
* A still clear specification is not decided about how to treat this numerical value.

  # UPDATE $table SET user = 'zoo', age = age + 1 WHERE user = 'hoge'
  # INSERT INTO $table (user) VALUES ('zoo')
  $table->update_insert(\'user = ?', { user=> [qw/ hoge zoo /], age=> \1 });
     or
  $table->update_insert( user=> [qw/ hoge zoo /], age=> \1 );
  
  # UPDATE $table SET user = 'zoo', age = 20 WHERE id = 1
  # INSERT INTO $table (user, age) VALUES ('zoo', 20)
  $table->update_insert(\'id => ?', { id=> [1], user=> 'zoo', age=> 20 });
     or
  $table->update_insert( id=> [1], user=> 'zoo', age=> 20 );

=head2 find_insert ([COLUMN], [HASH])

If the record doesn't exist, the record is added.

If the record already exists, 0E0 is restored.
Undefined returns when failing in the addition.

COLUMN specifies only one column used for the retrieval.
When the value of this column cannot be received from HASH, it becomes an error.

When COLUMN is omitted, HASH is made the first argument, and it passes it as
usual HASH. The first key to HASH is handled by this as a column for the retrieval.

Please omit the second element specifying the value for the retrieval of HASH by
the ARRAY reference when there is a column that doesn't want to be included when
adding it.

  # SELECT user FROM $table WHERE user = 'banban'
  # INSERT INTO $table (user, age) VALUES ('baban', 20)
  $table->find_insert(\'user', { user=> 'banban', age=> 20 });
    or
  $table->find_insert( user=> 'banban', age=> 20 );
  
  # SELECT id FROM $table WHERE id = 1
  # INSERT INTO $table (user, age) VALUES ('banban', 20)
  $table->find_insert(\'id', { id=> [1], user=> 'banban', age=> 20 });
    or
  $table->find_insert( id=> [1], user=> 'banban', age=> 20 );

=head2 for_update ([PRIMARY_KEY], [VALUE])

The record by FOR UPDATE is locked.

0 returns when failing.

  # SELECT * FROM $table WHERE id = ? FOR UPDATE
  $table->for_update( id=> 1 );

=head2 delete ([STATEMENT], [EXECUTE_ARGS])

The record is deleted.

  # DELETE FROM $table WHERE id = ?
  $table->delete('id = ?', $id);

=head2 upgrade ([HASH])

UPDATE is done to all the records.

If upgrade_ok is not effective, this method returns the exception.

  # UPDATE $table SET age = 20
  $table->upgrade( age => 20 );

=head2 clear

All the records are deleted.

If clear_ok is not effective, this method returns the exception. 

  # DELETE FROM $table
  $table->clear;

* I think that it is more efficient to do TRUNCATE by the do method.

=head2 abs_hashref ([FIELDS], [WHERE], [ORDER])

After SQL Statement is received from L<SQL::Abstract>, hashref is done. 

Please set 'sql_abstract' to enable this method use.

All the arguments extend to L<SQL::Abstract>. There is no table name needing.

Please see at the document of L<SQL::Abstract> of how to give the argument in
detail.

  # SELECT * FROM $table WHERE id = 1 AND user = 'hooo'
  my $hash= $table->abs_hashref({ id=> 1, user=> 'hooo' });

=head2 abs_arrayref ([FIELDS], [WHERE], [ORDER], [CODE_REF])

After SQL Statement is received from L<SQL::Abstract>, arrayref is done.

As for the argument, it is the same as abs_hashref accepting CODE_REF.

The treatment of CODE_REF is the same as arrayref.
Because it is picked up as CODE_REF if the last element of the argument is CODE
reference, the argument without the necessity need not be buried with undef etc.

  # SELECT * FROM $table WHERE age > 18
  my $list= $table->abs_arrayref({ age => { '>', 18 } });
  
  # SELECT * FROM $table WHERE age > 18
  my $list= $table->abs_arrayref({ age => { '>', 18 } }, sub {
    my($array, %hash)= @_;
    push @$array, "ID=$hash{id}, AGE=$hash{age}";
    });

=over 4

=item * Alias = abs_list 

=back

=head2 abs_scalarref ([FIELDS], [WHERE], [ORDER])

After SQL Statement is received from L<SQL::Abstract>, scalarref is done.

To acquire it only by one column, the argument gives all FIELDS without fail
though it is the same as hashref.

  # SELECT user FROM $table WHERE id = 1;
  my $scalar_ref= $table->abs_scalarref(['user'], { id=> 1 });

=head2 abs_scalar ([FIELDS], [WHERE], [ORDER]);

The result of abs_scalarref is returned with SCALAR receiving usual.

  # SELECT user FROM $table WHERE id = 1;
  my $scalar= $table->abs_scalar(['user'], { id=> 1 });

=head2 abs_insert ([FIELDS] || [VALUES])

After SQL Statement is received from L<SQL::Abstract>, insert is done.

The argument extends to the insert method of L<SQL::Abstract>.

  # INSERT INTO $table (id, user, age) VALUES (2, 'banban', 20)
  $table->abs_insert({ id=> 2, user=> 'banban', age=> 20 });

=head2 abs_update ([FIELDVALS], [WHERE])

After SQL Statement is received from L<SQL::Abstract>, update is done.

The argument extends to the update method of L<SQL::Abstract>.

  # UPDATE $table SET age = 22 WHERE user = 'banban'
  $table->abs_update({ age=> 22 }, { user=> 'banban' });

=head2 abs_delete ([WHERE])

After SQL Statement is received from L<SQL::Abstract>, delete is done.

The argument extends to the update method of L<SQL::Abstract>.

  # DELETE FROM $table WHERE user = 'banban'
  $table->delete({ user=> 'banban' });

=head1 JOIN DB OBJECT METHODS

This class supports the table uniting.

=head2 new (ARRAY)

Constructor.

When the argument is given to the db method of L<Egg::Mod::EasyDBI>, the constructor
here is called.

ARRAY is a list of the table name to unite tables.
It cares about neither usual ARRAY nor the ARRA reference.

The first element of this ARRAY is a table name of the main.
And, HASH is developed since the second element in this method.
The key to this HASH is handled by the following signs under the uniting 
condition.  * Do not pass the second element by the HASH reference.

  = or join  ..... JOIN 
  < or left  ..... LEFT OUTER JOIN 
  > or right ..... RIGHT OUTER JOIN 
  @ or full  ..... FULL OUTER JOIN 
  _ or inner ..... INNER JOIN 

The value of the key specifies the uniting table names, and and, the relation is
delimited by ':' and specified the condition.

The affixing character of the table name is sequentially allocated from the
table name of the main by a, b, c.., and the automatic operation.

Alias to which the table name is set by the start option is effective.

  # table1 a JOIN table2 b ON a.id = b.id LEFT OUTER JOIN table3 c ON b.id = c.id
  my $jdb= $es->db(qw/ table1 = table2:a.id=bid < table3:b.id=c.id /);
     or
  my $jdb= $es->db('table1',
     join=> 'table2 : a.id = bid',
     left=> 'table3 : b.id = c.id',
     );
  
  # table1 a RIGHT OUTER JOIN table2 b ON a.id = b.id
  my $jdb= $es->db(qw/ table1 > table2:a.id=b.id /);
     or
  my $jdb= $es->db('table1' right=> 'table2 : a.id = b.id');

=head2 hashref ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

It is functionally the same as hashref of 'TABLE OBJECT METHODS'.

It is necessary to put the affixing character of the table name in COLUMN and
STATEMENT.

  # SELECT a.id, a.user FROM members a JOIN profiles b ON a.id = b.id WHERE b.email = ?
  my $hash= $es->db(qw/ members = profiles:a.id=b.id /)
               ->hashref(\'a.id, a.user', 'b.email = ?', 'hoge@mydomain');

=head2 arrayref ([COLUMN], [STATEMENT], [EXECUTE_ARGS], [CODE_REF])

It is functionally the same as arrayref of 'TABLE OBJECT METHODS'.

It is necessary to put the affixing character of the table name in COLUMN and
STATEMENT.

  # SELECT a.id, a.user FROM members a JOIN profiles b ON a.id = b.id WHERE b.addr = ?
  my $hash= $es->db(qw/ members = profiles:a.id=b.id /)
               ->arrayref(\'a.id, a.user', 'b.addr = ?', 'Nagoya', sub {
       my($array, %hash)= @_;
       push @$array, "ID=$hash{id} USER=$hash{user}";
     });

=over 4

=item * Alias = list

=back

=head2 scalarref ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

It is functionally the same as scalarref of 'TABLE OBJECT METHODS'.

It is necessary to put the affixing character of the table name in COLUMN and 
STATEMENT.

  # SELECT count(a.id) FROM members a JOIN profiles b ON a.id = b.id WHERE b.addr = ?
  my $scalarref= $es->db(qw/ members = profiles:a.id=b.id /)
                    ->scalarref(\'count(a.id)', 'b.addr = ?', 'Nagoya');

=head2 scalar ([COLUMN], [STATEMENT], [EXECUTE_ARGS])

The result of scalarref is returned with usual SCALAR.

  # SELECT count(a.id) FROM members a JOIN profiles b ON a.id = b.id WHERE b.addr = ?
  my $scalar= $es->db(qw/ members = profiles:a.id=b.id /)
                 ->scalar(\'count(a.id)', 'b.addr = ?', 'Nagoya');

=head1 SEE ALSO

L<DBI>,
L<SQL::Abstract>,
L<Egg::Plugin::EasyDBI>,
L<Class::Accessor::Fast>,
L<Class::Data::Inheritable>,
L<Tie::Hash::Indexed>,

=head1 AUTHOR

Masatoshi Mizuno E<lt>lusheE<64>cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Bee Flag, Corp. E<lt>L<http://egg.bomcity.com/>E<gt>, All Rights Reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
