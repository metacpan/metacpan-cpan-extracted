package GnaData::Conform::Hash;

sub new {
    my $proto = shift;
    my $inref = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    $self->{'myhash'} = {};
    $self->{'delete_blank'} = 1;
    return $self;
}

sub load {
    my ($self, $inhash) = @_;
    my ($field);
    foreach $field (keys %$inhash) {
	$self->{'myhash'}->{lc($field)} = $inhash->{$field};
    }
}

sub load_reverse {
    my ($self, $inhash) = @_;
    my ($field);
    foreach $field (keys %$inhash) {
	my($result) = lc($inhash->{$field});
	$self->{'myhash'}->{$result} = $field;
    }
}

sub delete_blank {
    my ($self, $value) = @_;
    if (defined($value)) {
	$self->{'delete_blank'} = $value;
    }
    return $self->{'delete_blank'};
}

sub conform {
    my ($self, $inhash) = @_;
    my (%outhash);
    foreach $key (keys %{$inhash}) {
	my ($keyval) = "";
	my ($keylc) = lc ($key);
	if (!defined ($self->{'myhash'}->{$keylc})) {
	    $keyval = $key;
	} elsif ($self->{'myhash'}->{$keylc} ne "") {
	    $keyval = $self->{'myhash'}->{$keylc};
	} else {
	    $keyval = "";
	}
	if ($keyval ne "" 
	    && $inhash->{$key} ne "" 
	    || $self->{'delete_blank'} == 0) {
	    $outhash{$keyval} =
		$inhash->{$key};
	}
    }
    %{$inhash} = %outhash;
}

sub deconform {
}

1;
