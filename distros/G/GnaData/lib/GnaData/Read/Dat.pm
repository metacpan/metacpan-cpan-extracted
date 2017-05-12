=head 1 NAME

GnaData::Load::Dat - Base object for GNA Data Load subsystem

=cut

package GnaData::Loader;
use IO::File;
use IO::Handle;
use Text::Wrapper;
use strict;

sub new {
    my $proto = shift;
    my $inref = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    my $self->{'WRAPPER'} =
      Text::Wrapper->new(columns=>72, body_start=>'   ');
    bless ($self, $class);
    return $self;
}

sub open {
    my ($self, $hashref) = @_;
    if ($hashref->{'mode'} eq "write") {
    }
}

sub read {
}

sub close {
}

sub write {
}




sub open_handles {
    my($filename) = @_;
    my($inh, $outh);
    if ($filename eq "") {
	$inh = new IO::Handle;
	$outh = new IO::Handle;
	$inh->fdopen(fileno(STDIN),"r");
	$outh->fdopen(fileno(STDOUT),"w");
	return ($inh, $outh);
    } else {
	my ($abort_func) = sub {
	    rename "$filename.bak", $filename;
	    die "Aborting program\n";
	};
	rename $filename, "$filename.bak";
	$SIG{'INT'} = $abort_func;
	$SIG{'HUP'} = $abort_func;
	$SIG{'TERM'} = $abort_func;
	$inh = IO::File->new("$filename.bak");
	$outh = IO::File->new(">$filename");
	return ($inh,$outh);
    }
}

sub open_logfile {
    my ($filename, $suffix) = @_;
    if ($suffix eq "") {
	$suffix = "aux";
    }
    my ($logfile) = $filename;
    if ($logfile =~ /\.dat/) {
        $logfile =~ s/\.dat/\.$suffix/;
    } else {
        $logfile .= "." . $suffix;
    }
    my($logfileh) = IO::File->new(">$logfile");
    return $logfileh;
}

sub read_dat {
    my($fh, $fref, $entry_ref, $orderref) = @_;
    my($in_blank) = 1;
    my ($field);
    %{$fref} = ();
    ${$entry_ref} = "";
if ($orderref ne undef) {
    @{$orderref} = ();
}
    while (<$fh>) {
	s/\r//g;
	$$entry_ref .= $_;
	if (/^\s*$/ && !$in_blank) {
	    return 1;
	}
	if (/^(\S+)\s+(.*)\s*$/) {
	    $field = $1;
	    if ($orderref ne undef) {
		push (@{$orderref}, $field);
	    }
	    if ($fref->{$field} ne "") {
		$fref->{$field} .= '\0' . $2;
	    } else {
		$fref->{$field} = $2;
	    }
	    $in_blank=0;
	    next;
	}
	if (/^\s+(.*)\s*$/ && $field ne "") {
	    my ($result) = $1;
	    if ($fref->{$field} !~ /^\s*$/) {
		$fref->{$field} .= " " . $result;
	    } else {
		$fref->{$field} = $result;
	    }
	    next;
	}
    }
if (!$in_blank) {
    return 1;			# 
} else {
    return 0;
}
}

sub write_dat {
    my ($fh, $fref, $orderref) = @_;
    my (%field_used) = ();
    my(@order);
    if ($orderref ne undef) {
	foreach (@{$orderref}) {
	    $fh->print($wrapper->wrap($_ . "   " . $fref->{$_}));
	    $field_used{$_} = 1;
	}
    }
    
    foreach (sort keys %{$fref}) {
	if (!$field_used{$_}) {
	    $fh->print($wrapper->wrap($_ . "   " . $fref->{$_}));
	}
    }
    $fh->print("\n\n");
    $fh->flush();
}

1;


