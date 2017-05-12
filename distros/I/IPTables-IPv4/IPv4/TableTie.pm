package IPTables::IPv4::TableTie;

use IPTables::IPv4::Chain;

sub TIEHASH {
	my($self, $th_r) = @_;
	return bless {'TABLE' => \$th_r}, $self;
}

sub FETCH {
	my($self, $chainname) = @_;
	unless(${$self->{TABLE}}->is_chain($chainname)) {
		return undef;
	}
	my %data;
	tie(%data, 'IPTables::IPv4::Chain', ${$self->{TABLE}}, $chainname);
	return(\%data);
}

sub STORE {
	my($self, $chainname, $value) = @_;
	my %chain;

	return undef unless ref($value) eq "HASH";
	${$self->{TABLE}}->create_chain($chainname) unless
			${$self->{TABLE}}->is_chain($chainname);
	tie(%chain, 'IPTables::IPv4::Chain', ${$self->{TABLE}}, $chainname);
	%chain = %$value;
}

sub DELETE {
	my($self, $chainname) = @_;
	${$self->{TABLE}}->flush_entries($chainname);
	${$self->{TABLE}}->delete_chain($chainname)
			unless ${$self->{TABLE}}->builtin($chainname);
}

sub CLEAR {
	my($self) = @_;
	$self->DELETE($_) foreach ${$self->{TABLE}}->list_chains();
}

sub EXISTS {
	my($self, $chainname) = @_;
	return ${$self->{TABLE}}->is_chain($chainname);
}

sub FIRSTKEY {
	my($self) = @_;
	return (${$self->{TABLE}}->list_chains())[0];
}

sub NEXTKEY {
	my($self, $prevkey) = @_;
	my @chains = ${$self->{TABLE}}->list_chains();
	for(my $i = 0; $i <= $#chains; $i++) {
		return $chains[$i+1] if $chains[$i] eq $prevkey;
	}
	return $chains[0];
}

sub DESTROY {
	my($self) = @_;
	${$self->{TABLE}}->commit();
}

1;
# vim: ts=4
