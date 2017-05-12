=head 1 NAME

GnaData::Read::Tsv - Base object for GNA Data Load subsystem

=cut

package GnaData::Read::Tsv;

sub new {
    my $proto = shift;
    my $inref = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless ($self, $class);
    return $self;
}

sub open {
    my $self = shift;
    my $inref = shift;
    if ($inref->{'handle'} ne "") {
	$self->{'handle'} = $inref->{'handle'};
    }
    my($header) = $self->{'handle'}->getline();
    chop ($header);
    $header =~ s/\r//gi;
    my ($field);
    my(@header_fields);
   
    foreach $field (split(/\s*\t\s*/, $header)) {
	$field =~ s/^\"//;
	$field =~ s/\"$//;
	push(@header_fields, $field);
    }
    $self->{'fields'} = \@header_fields;
    $self->{'first_line'} = 1;
}

sub read {
    my ($self) = shift;
    my ($fref) = shift;
    my ($line, $quotes);
    %{$fref} = ();

    while (1) {
	if ($self->eof()) {
	    return 0;
	}
	$line = "";
	$quotes = 0;
	do {
	    $line .= $self->{'handle'}->getline();
	    if ($self->{'first_line'} && $line =~ /^[\-\s]+$/) {
		$line = $self->{'handle'}->getline();
	    }
	    $self->{'first_line'} = 0;
	    $line =~ s/\r//gi;
	    $quotes =  ($line =~ tr/\"//);
	} until $quotes % 2 == 0 || $self->eof();
	$line =~ s/\"//g;
	
	if ($line !~ /^\s*$/) {
	    last;
	}
    }

    chop $line;
    $line =~ s/\n/ /gi;
    $line =~ s/\r//gi;
    @{$fref}{@{$self->{'fields'}}} = split("\t", $line);
    return 1;
}

sub close {
}

sub write {
}

sub eof {
    my ($self) = shift;
    return $self->{'handle'}->eof();
}
    

sub fields {
    my ($self) = shift;
    return @{$self->{'fields'}};
}
1;
