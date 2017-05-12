package IPTables::IPv4::RuleList;

use IPTables::IPv4::Rule;

sub TIEARRAY {
	my($self, $th_r, $cn) = @_;
	return bless {'TABLE' => $th_r, 'CHAIN' => $cn}, $self;
}

sub FETCH {
	my($self, $index) = @_;
	my %rule;
	tie(%rule, 'IPTables::IPv4::Rule', $self->{TABLE}, $self->{CHAIN}, $index);
	return(\%rule);
}

sub STORE {
	my($self, $index, $rule) = @_;

	warn(ref $self, "::STORE: value must be a hash reference") and
			return undef unless ref($rule) eq "HASH";

#	$self->EXTEND($index + 1) if $index + 1 > $self->FETCHSIZE();
#	$self->SPLICE($index, 1, $rule);
#	print(ref $self, "::STORE()\n");
#	print("table: ", $self->{TABLE}, ", chain: ", $self->{CHAIN}, "\n");
	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
#	foreach(@rules) {
#		print("keys for rule: ", join(", ", keys(%$_)), "\n");
#	}
#	print("rule count: ", scalar(@rules), "\n");
	if($#rules >= $index) {
		$self->{TABLE}->replace_entry($self->{CHAIN}, $rule, $index)
				or warn $!;
	} else {
		$self->{TABLE}->append_entry($self->{CHAIN}, {})
				foreach $#rules .. $index - 2;
		$self->{TABLE}->append_entry($self->{CHAIN}, $rule) or warn $!;
	}
}

sub FETCHSIZE {
	my($self) = @_;
	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
	return scalar @rules;
}

sub STORESIZE {
	my($self, $size) = @_;

	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
	$self->{TABLE}->delete_num_entry($self->{CHAIN}, $size)
			or warn $! foreach $size .. scalar(@rules) - 1;
	$self->{TABLE}->append_entry($self->{CHAIN}, {})
			foreach scalar(@rules) .. $size - 1;
}

sub EXTEND {
	my($self, $count) = @_;
	$self->STORESIZE($count);
}

sub EXISTS {
	my($self, $index) = @_;
	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
	return exists $rules[$index];
}

sub DELETE {
	my($self, $index) = @_;
	$self->{TABLE}->delete_num_entry($self->{CHAIN}, int($index))
			or warn $!;
}

sub CLEAR {
	my($self) = @_;
	$self->{TABLE}->flush_entries($self->{CHAIN});
}

sub PUSH {
	my($self, @items) = @_;
	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
	return $self->SPLICE(scalar @rules, 0, @items);
}

sub POP {
	my($self) = shift;
	return $self->SPLICE(-1);
}

sub SHIFT {
	my($self) = shift;
	return $self->SPLICE(0, 1);
}

sub UNSHIFT {
	my($self, @items) = @_;
	return $self->SPLICE(0, 0, @items);
}

sub SPLICE {
	my($self, $offset, $length, @items) = @_;
	my @rules = $self->{TABLE}->list_rules($self->{CHAIN});
	my @ret;
	$offset = 0 if !defined $offset;
	$offset = scalar(@rules) + $offset if $offset < 0;
	$length = scalar(@rules) - $offset if !defined $length;
	@ret = @rules[$offset .. $offset + $length - 1];
	$self->{TABLE}->delete_num_entry($self->{CHAIN}, $offset)
			or warn $! foreach 0 .. ($length < 0 ? -$length - 1 : -1);
	$self->{TABLE}->insert_entry($self->{CHAIN}, $items[$_],
			$_ + $offset) or warn $!
			foreach 0 .. (($length > 0 and $length < $#items) ?
				$length - 1 : $#items);
	return(@ret);
}

1;
# vim: ts=4
