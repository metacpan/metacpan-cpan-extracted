package IPTables::IPv4::Toplevel;

use IPTables::IPv4::TableTie;
use FileHandle;

sub TIEHASH {
	my($self) = @_;
	return bless {}, $self;
}

sub FETCH {
	my($self, $tablename) = @_;
	return $self->{$tablename}->{DATA} if exists $self->{$tablename};

	my $table = IPTables::IPv4::init($tablename) or warn $!;
	return undef unless $table;

	my %store;
	tie(%store, 'IPTables::IPv4::TableTie', $table);
	$self->{$tablename} = {'TABLE' => \$table, 'DATA' => \%store};
	return($self->{$tablename}->{DATA});
}

sub STORE {
	my($self, $key, $value) = @_;
	my $table = $self->FETCH($key);
	%{${$table}{$_}} = () foreach keys %{$value};
	%{${$table}{$_}} = %{${$value}{$_}} foreach keys %{$value};
}

sub DELETE {
	my($self, $key) = @_;
	%{$self->FETCH($key)} = ();
}

sub CLEAR {
	my($self) = @_;
	$self->DELETE($_) foreach keys %$self;
}

sub EXISTS {
	my($self, $key) = @_;
	return 1 if exists $self->{$key} or $self->FETCH($key);
	return 0;
}

sub FIRSTKEY {
	my($self) = @_;
	my $fh = new FileHandle("</proc/net/ip_tables_names");
	my @tnames = <$fh>;
	chop($_) foreach @tnames;
	close($fh);
	return($tnames[0]);
}

sub NEXTKEY {
	my($self, $prevkey) = @_;
	my $fh = new FileHandle("</proc/net/ip_tables_names");
	my @tnames = <$fh>;
	chop($_) foreach @tnames;
	close($fh);
	foreach my $i (0 .. $#tnames) {
		return $tnames[$i + 1] if $tnames[$i] eq $prevkey;
	}
}

1;
# vim: ts=4
