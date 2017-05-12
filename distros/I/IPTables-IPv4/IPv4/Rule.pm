package IPTables::IPv4::Rule;

sub TIEHASH {
	my($self, $th_r, $cn, $rn) = @_;
	return bless {'TABLE' => $th_r, 'CHAIN' => $cn, 'RULENUM' => $rn,
			'DATA' => ($th_r->list_rules($cn))[$rn]}, $self;
}

sub FETCH {
	my($self, $field) = @_;
	return $self->{DATA}->{$field};
}

sub STORE {
	my($self, $field, $value) = @_;
	$self->{DATA}->{$field} = $value;
	$self->{TABLE}->replace_entry($self->{CHAIN}, $self->{DATA},
			$self->{RULENUM}) or warn $!;
	$self->{DATA} = ($self->{TABLE}->list_rules($self->{CHAIN}))[$self->{RULENUM}];
}

sub DELETE {
	my($self, $field) = @_;
	delete $self->{DATA}->{$field};
	$self->{TABLE}->replace_entry($self->{CHAIN}, $self->{DATA},
			$self->{RULENUM}) or warn $!;
}

sub CLEAR {
	my($self) = @_;
	$self->{TABLE}->replace_entry($self->{CHAIN}, {}, $self->{RULENUM});

	$self->{DATA} = ($self->{TABLE}->list_rules($self->{CHAIN}))[$self->{RULENUM}];
}

sub EXISTS {
	my($self, $field) = @_;
	return exists $self->{DATA}->{$field};
}

sub FIRSTKEY {
	my($self) = @_;
	my $a = keys %{$self->{DATA}};
	return each %{$self->{DATA}};
}

sub NEXTKEY {
	my($self, $prevkey) = @_;
	return each %{$self->{DATA}};
}

1;
# vim: ts=4
