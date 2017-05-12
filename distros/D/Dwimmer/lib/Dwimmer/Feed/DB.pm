package Dwimmer::Feed::DB;
use Moose;

use Carp ();
use Data::Dumper qw(Dumper);
use DateTime;
use DBI;

our $VERSION = '0.32';

has 'store' => (is => 'ro', isa => 'Str', required => 1);
has 'dbh'   => (is => 'rw', isa => 'DBI::db');


sub connect {
	my ($self) = @_;

	if (not $self->dbh) {
		my $dbh = DBI->connect("dbi:SQLite:dbname=" . $self->store, "", "", {
			FetchHashKeyName => 'NAME_lc',
			RaiseError       => 1,
			PrintError       => 0,
		});
		$self->dbh( $dbh );
	}

	return $self->dbh;
}

sub add_source {
	my ($self, $e) = @_;

	my @fields = qw(title url feed comment status twitter site_id);
	my $fields = join ', ', @fields;
	my $placeholders = join ', ', (('?') x scalar @fields);
	$self->dbh->do("INSERT INTO sources ($fields) VALUES($placeholders)",
		{},
		@$e{@fields});
	return $self->dbh->last_insert_id('', '', '', '');
}

sub get_all_entries {
	my ($self) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM entries ORDER BY issued DESC');
	$sth->execute;
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}

	return \@results;
}

sub find {
	my ($self, %args) = @_;

	my $ref = $self->dbh->selectrow_hashref('SELECT * FROM entries WHERE link LIKE ?', {}, $args{link});

	return $ref;
}

sub add_entry {
	my ($self, %args) = @_;

	my @fields = grep {defined $args{$_}} qw(id source_id link author issued title summary content tags site_id);
	my $f = join ',', @fields;
	my $p = join ',', (('?') x scalar @fields);

	my $issued = $args{issued};
	$args{issued} = $issued->ymd . ' ' . $issued->hms;

	my $sql = "INSERT INTO entries ($f) VALUES($p)";
	#main::LOG("SQL: $sql");
	$self->dbh->do($sql, {}, @args{@fields});
	my $id = $self->dbh->last_insert_id('', '', '', '');
	main::LOG("   ID: $id");

	# only deliver new things
	my $NOT_TOO_OLD = 60*60*24;
	if ($issued->epoch > time - $NOT_TOO_OLD) {
		$self->dbh->do(q{INSERT INTO delivery_queue (channel, entry, site_id) VALUES ('mail', ?, ?)},
			{}, $id, $args{site_id});
	}

	return;
}

sub get_queue {
	my ($self, $channel) = @_;

	my $sth = $self->dbh->prepare('SELECT * FROM entries, delivery_queue WHERE entries.id=delivery_queue.entry AND channel = ?');
	$sth->execute($channel);
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}
	return \@results;
}

sub delete_from_queue {
	my ($self, $channel, $id) = @_;

	$self->dbh->do('DELETE FROM delivery_queue WHERE channel=? AND entry=?', {}, $channel, $id);

	return;
}

sub get_sources {
	my ( $self, %opt ) = @_;

	my $sql = 'SELECT * FROM sources';
	my @fields = sort keys %opt;
	if (%opt) {
		$sql .= ' WHERE ';
		$sql .= join ' AND ', map { "$_=?" } @fields;
	}
	my $sth = $self->dbh->prepare($sql);
	$sth->execute(@opt{@fields});
	my @r;
	while (my $h = $sth->fetchrow_hashref) {
		push @r, $h;
	}

	return \@r;
}

sub get_source_by_id {
	my ( $self, $id ) = @_;

	my $sources = $self->get_sources;
	my ($s) = grep { $_->{id} eq $id }  @$sources;
	return $s;
}

sub update_last_fetch {
	my ($self, $source_id, $status, $error) = @_;
	my $sql = qq{UPDATE sources SET last_fetch_time=?, last_fetch_status=?, last_fetch_error=? WHERE id=?};
	$self->dbh->do($sql, undef, time(), $status, $error, $source_id);

	return;
}


sub update {
	my ($self, $id, $field, $value) = @_;

	Carp::croak("Invalid field '$field'")
		if $field !~ m{^(feed|comment|twitter|status|title|url)$};
	Carp::croak("Invalid value for status '$value'")
		if $field eq 'status' and $value !~ m{^(enabled|disabled)$};

	my $sql = qq{UPDATE sources SET $field = ? WHERE id=?};
	$self->dbh->do($sql, undef, $value, $id);
}

sub set_config {
	my ($self, %args) = @_;
	foreach my $field (qw(key value site_id)) {
		die "Missing $field" if not defined $args{$field};
	}
	$self->delete_config( %args );
	$self->dbh->do('INSERT INTO config (key, value, site_id) VALUES (?, ?, ?)',
		undef,
		$args{key}, $args{value}, $args{site_id});
	return;
}

sub delete_config {
	my ($self, %args) = @_;
	foreach my $field (qw(key site_id)) {
		die "Missing $field" if not defined $args{$field};
	}
	$self->dbh->do('DELETE FROM config WHERE key=? AND site_id=?', undef, $args{key}, $args{site_id});
	return;
}

sub get_config {
	my ($self, %args) = @_;

	my $sql = 'SELECT * FROM config ';
	if (defined $args{site_id}) {
		$sql .= 'WHERE site_id=?';
	}
	$sql .= ' ORDER BY key DESC';
	my $sth = $self->dbh->prepare($sql);
	defined $args{site_id} ? $sth->execute($args{site_id}) : $sth->execute();;
	my @results;
	while (my $h = $sth->fetchrow_hashref) {
		push @results, $h;
	}

	return \@results;
}
sub get_config_hash {
	my ($self, %args) = @_;

	my $sql = 'SELECT * FROM config ';
	if (defined $args{site_id}) {
		$sql .= 'WHERE site_id=?';
	}
	$sql .= ' ORDER BY key DESC';

	my $sth = $self->dbh->prepare($sql);
	defined $args{site_id} ? $sth->execute($args{site_id}) : $sth->execute();
	my %config;
	while (my $h = $sth->fetchrow_hashref) {
		$config{ $h->{key} } = $h->{value};
	}

	return \%config;
}

sub addsite {
	my ($self, %args) = @_;

	return $self->dbh->do(q{INSERT INTO sites (name) VALUES (?)}, {}, $args{name});
}

sub get_site_id {
	my ($self, $name) = @_;

	my $ref = $self->dbh->selectrow_hashref('SELECT id FROM sites WHERE name = ?', {}, $name);
	return $ref->{id};
}

sub get_site_by_id {
	my ($self, $id) = @_;

	my $ref = $self->dbh->selectrow_hashref('SELECT * FROM sites WHERE id = ?', {}, $id);
	return $ref;
}

sub get_sites {
	my ($self) = @_;

	my $sql = 'SELECT * FROM sites';
	my $sth = $self->dbh->prepare($sql);
	$sth->execute;
	my @r;
	while (my $h = $sth->fetchrow_hashref) {
		push @r, $h;
	}

	return \@r;
}

1;

