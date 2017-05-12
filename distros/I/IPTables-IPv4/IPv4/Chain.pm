package IPTables::IPv4::Chain;

use IPTables::IPv4::RuleList;

sub TIEHASH {
	my($self, $th_r, $cn) = @_;
	return bless {'TABLE' => $th_r, 'CHAIN' => $cn}, $self;
}

sub FETCH {
	my($self, $key) = @_;
	
	if($key eq "rules") {
		my @data;
		tie(@data, 'IPTables::IPv4::RuleList', $self->{TABLE}, $self->{CHAIN});
		return(\@data);
	}
	elsif($self->{TABLE}->builtin($self->{CHAIN})) {
		my @polinfo = $self->{TABLE}->get_policy($self->{CHAIN});
		if($key eq "pcnt") { return $polinfo[1]; }
		elsif($key eq "bcnt") { return $polinfo[2]; }
		elsif($key eq "policy") { return $polinfo[0]; }
	}
	else {
		if($key eq "references") {
			return $self->{TABLE}->get_references($self->{CHAIN});
		}
	}
	return undef;
}

sub STORE {
	my($self, $key, $value) = @_;
	my @rules;

#	print(ref $self, "::STORE()\n");
#	print("table: ", $self->{TABLE}, ", chain: ", $self->{CHAIN}, "\n");
	if($key eq "rules") {
		return undef unless ref($value) eq "ARRAY";
		tie(@rules, 'IPTables::IPv4::RuleList', $self->{TABLE}, $self->{CHAIN});
		@rules = @$value;
	}
	elsif($self->{TABLE}->builtin($self->{CHAIN})) {
		my @polinfo = $self->{TABLE}->get_policy($self->{CHAIN});
		my $policy = $polinfo[0];
		my %counts = (pcnt => $polinfo[1], bcnt => $polinfo[2]);
		if($key eq "pcnt") {
			$counts{'pcnt'} = $value;
		}
		elsif($key eq "bcnt") {
			$counts{'bcnt'} = $value;
		}
		elsif($key eq "policy") {
			$policy = $value;
		}
		$self->{TABLE}->set_policy($self->{CHAIN}, $policy, \%counts);
	}
}

sub DELETE {
	my($self, $key) = @_;

	if($key eq "rules") {
		$self->{TABLE}->flush_entries($self->{CHAIN});
	}
	return undef;
}

sub CLEAR {
	my($self) = @_;
	$self->DELETE("rules");
	if($self->{TABLE}->builtin($self->{CHAIN})) {
		$self->{TABLE}->set_policy($self->{CHAIN}, "ACCEPT", {pcnt => 0,
				bcnt => 0});
	}

}

sub EXISTS {
	my($self, $key) = @_;

	if($key eq "rules") { return 1; }
	elsif($self->{TABLE}->builtin($self->{CHAIN})) {
		if($key eq "pcnt") { return 1; }
		elsif($key eq "bcnt") { return 1; }
		elsif($key eq "policy") { return 1; }
	}
	else {
		if($key eq "references") { return 1; }
	}
	return undef;
}

sub FIRSTKEY {
	my($self) = @_;
	my @keys = ("rules");

	if($self->{TABLE}->builtin($self->{CHAIN})) {
		push(@keys, "pcnt", "bcnt", "policy");
	}
	else {
		push(@keys, "references");
	}
	
	return $keys[0];
}

sub NEXTKEY {
	my($self, $prevkey) = @_;
	my @keys = ("rules");

	if($self->{TABLE}->builtin($self->{CHAIN})) {
		push(@keys, "pcnt", "bcnt", "policy");
	}
	else {
		push(@keys, "references");
	}
	for my $i (0 .. $#keys) {
		if($prevkey eq $keys[$i]) {
			return($keys[$i+1]);
		}
	}
	return($keys[0]);
}

1;
# vim: ts=4
