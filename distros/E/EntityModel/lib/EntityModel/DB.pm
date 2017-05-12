package EntityModel::DB;
{
  $EntityModel::DB::VERSION = '0.102';
}
# ABSTRACT: Database manager for entity handling
use EntityModel::Class {
	user			=> { type => 'string' },
	password		=> { type => 'string' },
	host			=> { type => 'string' },
	port			=> { type => 'string' },
	dbname			=> { type => 'string' },
	service			=> { type => 'string' },
	pid			=> { type => 'int' },
	transactionLevel	=> { type => 'int', default => 0 },
};
no if $] >= 5.017011, warnings => "experimental::smartmatch";

=head1 NAME

EntityModel::DB - database management

=head1 VERSION

version 0.102

=head1 DESCRIPTION

Manages database connections and transactions.

=cut

use EntityModel::Query;

# Current database entry when in transaction
our $ACTIVE_DB;

=head2 new

Create a new L<EntityModel::DB> object.

Does not attempt to connect any database handles, but prepares the context ready for the first
request.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->pid($$);
	return $self;
}

=head2 dbh

Returns a database handle.

Can only be called within a transaction.

=cut

sub dbh {
	my $self = shift;
	my $name = shift // 'main';
	$self->_fork_guard;

	return $self->{dbh}->{$name} if $self->{dbh}->{$name};

	logDebug("Connecting to database with DSN [%s]", $self->dsn);
	# FIXME All this should go, it's supposed to be handled entirely by the backend
	# storage engine.
	require DBI;
	my $dbh = $self->{dbh}->{$name} = DBI->connect(
		$self->dsn,
		$self->user,
		$self->password, {
			AutoCommit		=> 0,
			RaiseError		=> 1,
			PrintError		=> 0,
			PrintWarn		=> 0,
# Turn off server-side prepare statements, since we want to support pgbouncer's transaction mode
			pg_server_prepare	=> 0,
			private_pid		=> $self->pid
		}
	);
	return $dbh;
}

=head2 dsn

Data Source string used for connecting to the database.

Currently hardcodes the dbi:Pg: prefix.

=cut

sub dsn {
	my $self = shift;
	my $dsn = "dbi:Pg:";
	$dsn .= join(";", map { "$_=" . $self->$_ } grep { $self->$_ } qw{dbname host port service});
	return $dsn;
}

=head2 transaction

Call code within a transaction.

Note that this does not map exactly onto a single database transaction. Nested transactions are supported, using
savepoints, and a transaction may cover several active database handles.

=cut

sub transaction {
	my $self = shift;
	my $sub = shift;
	$self->_fork_guard;

# Record then increment current transaction level
	my $level = $self->transactionLevel;
	$self->transactionLevel($level + 1);

# If we're already in a transaction, use a savepoint
	if($level) {
		logDebug("Savepoint %d", $level);
		$self->dbh->do("savepoint tran_" . $self->transactionLevel);
	}

# Run the query, if this fails $status will be false
	return try {
		local $ACTIVE_DB = $self;
		$sub->($self, @_);
		die "Fork within transaction is not recommended" unless $self->pid ~~ $$;

		if($level) {
			logDebug("Commit to level %d", $level);
			$self->dbh->do("release tran_" . $self->transactionLevel);
		} else {
			logDebug("Commit");
			$self->dbh->do("commit");
		}
# Restore previous transaction level
		$self->transactionLevel($level);
		$self;
	} catch {
# And for failure, do a rollback to previous level
		if($level) {
			logDebug("Rollback to level %d", $level);
			$self->dbh->do("rollback to tran_" . $self->transactionLevel);
		} else {
			logDebug("Rollback");
			$self->dbh->do("rollback");
		}
# Restore previous transaction level
		$self->transactionLevel($level);
		logStack($_);
		die $_;
	};
}

=head2 update

Update information

=cut

sub update {
	my $self = shift;
	my %args = @_;
	$self->_fork_guard;

	my $sql = $args{sql};
	my $dbh = $self->dbh;
	my $sth = $dbh->prepare($sql);
	$sth->execute(@{$args{param}});
	$args{on_complete}->($sth) if $args{on_complete};
	return $sth;
}

=head2 select

Run a select query against the database and return the results as an orderly hash.

=cut

sub select : method {
	my $self = shift;
	my $sql = shift;
	my $param = shift;
	my %args = (
		sql	=> $sql,
		param	=> $param
	);
	my ($sth, $rslt) = $self->_run_query(%args);

	my @names = @{ $sth->{ NAME_lc } };
	my @data;
	foreach (@$rslt) {
		my @row = @$_;
		push @data, {
			map {
				$_ => shift(@row)
			} @names
		};
	}
	return \@data;
}

=head2 select_iterator

Run a select query against the database and return the results as an orderly hash.

=cut

sub select_iterator {
	my $self = shift;
	my %args = @_;
	die "No method supplied" unless $args{method};

# Set up the statement handle so we can read data
	my ($sth, $rslt) = $self->_run_query(@_);

	my @names = @{ $sth->{ NAME_lc } };
	my @data;
	foreach (@$rslt) {
		my @row = @$_;
		my %data = map { $_ => shift(@row) } @names;
		$args{method}->(\%data);
	}
	return 1;
}

=head2 active_db

Returns the currently active database handle.

=cut

sub active_db {
	my $class = shift;
	return $ACTIVE_DB;
}

=head1 INTERNAL METHODS

=cut

=head2 _run_query

Run the given query.

=cut

sub _run_query {
	my $self = shift;
	my %args = @_;
	$self->_fork_guard;

	my $sql = $args{sql};
	my $dbh = $self->dbh;
	my $sth = try {
		my $sth = $dbh->prepare($sql);
		$sth->execute(@{$args{param}});
		$sth;
	} catch {
		warn "$_\n";
		die $_ // 'unknown error';
	};
	my $rslt;
	$rslt = $sth->fetchall_arrayref if $sth->{Active};
	return unless $rslt;
	return ($sth, $rslt);
}

=head2 _fork_guard

Internal method used to check whether we've forked recently and if so reset the internal state
so that we don't try to reuse existing handles.

=cut

sub _fork_guard {
	my $self = shift;
	return $self if $self->pid ~~ $$;
	logError("Fork inside a transaction (level %d), old pid %d, new pid %d", $self->transactionLevel, $self->pid, $$) if $self->transactionLevel;

	logDebug("Clean up after fork");
	delete $self->{dbh};
	$self->transactionLevel(0);
	$self->pid($$);
	return $self;
}

sub DESTROY {
	my $self = shift;
	$self->_fork_guard;
	$_->rollback foreach values %{$self->{dbh}};
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2008-2011. Licensed under the same terms as Perl itself.
