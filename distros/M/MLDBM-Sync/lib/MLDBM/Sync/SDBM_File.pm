
package MLDBM::Sync::SDBM_File;
$VERSION = .17;

use SDBM_File;
use strict;
use vars qw(@ISA  $MaxSegments $MaxSegmentLength %KEYS $Zlib $VERSION);

@ISA = qw(SDBM_File);
$MaxSegments   = 8192; # to a 1M limit
# leave room for key index pad
$MaxSegmentLength = 128;
eval "use Compress::Zlib";
$Zlib = $@ ? 0 : 1;

sub FETCH {
    my($self, $key) = @_;
    my $segment_length = $MaxSegmentLength;

    my $total_rv;
    for(my $index = 0; $index < $MaxSegments; $index++) {
	my $rv = $self->SUPER::FETCH(_index_key($key, $index));
	if(defined $rv) {
	    $total_rv ||= '';
	    $total_rv .= $rv;
	    last if length($rv) < $segment_length;
	} else {
	    last;
	}
    }

    if(defined $total_rv) {
	$total_rv =~ s/^(..)//s;
	my $type = $1;
	if($type eq 'G}') {
	    $total_rv = uncompress($total_rv);
	} elsif ($type eq 'N}') {
	    # nothing
	} else {
	    # old SDBM_File ?
	    $total_rv = $type . $total_rv;
	}
    }

    $total_rv;
}

sub STORE {
    my($self, $key, $value) = @_;
    my $segment_length = $MaxSegmentLength;

    # DELETE KEYS FIRST
    for(my $index = 0; $index < $MaxSegments; $index++) {
	my $index_key = _index_key($key, $index);
	my $rv = $self->SUPER::FETCH($index_key);
	if(defined $rv) {
	    $self->SUPER::DELETE($index_key);
	} else {
	    last;
	}
	last if length($rv) < $segment_length;
    }

    # G - Gzip compression
    # N - No compression
    #
    my $old_value = $value;
    $value = ($Zlib && (length($value) >= $segment_length/2)) ? "G}".compress($value) : "N}".$value;

    my($total_rv, $last_index);
    for(my $index = 0; $index < $MaxSegments; $index++) {
	if($index == $MaxSegments) {
	    die("can't store more than $MaxSegments segments of $MaxSegmentLength bytes per key in ".__PACKAGE__);
	}
	$value =~ s/^(.{0,$segment_length})//so;
	my $segment = $1;
	
	last if length($segment) == 0;
#	print "STORING "._index_key($key, $index)." $segment\n";
	my $rv = $self->SUPER::STORE(_index_key($key, $index), $segment);
	$total_rv .= $segment;
	$last_index = $index;
    }

#    use Time::HiRes;
#    print "[".&Time::HiRes::time()."] STORED ".($last_index+1)." segments for length ".
#      length($total_rv)." bytes for value ".length($old_value)."\n";

    $old_value;
}

sub DELETE {
    my($self, $key) = @_;
    my $segment_length = $MaxSegmentLength;

    my $total_rv;
    for(my $index = 0; $index < $MaxSegments; $index++) {
	my $index_key = _index_key($key, $index);
	my $rv = $self->SUPER::FETCH($index_key) || '';
	$self->SUPER::DELETE($index_key);
	$total_rv ||= '';
	$total_rv .= $rv;
	last if length($rv) < $segment_length;
    }

    $total_rv =~ s/^(..)//s;
    my $type = $1;
    if($type eq 'G}') {
	$total_rv = uncompress($total_rv);
    } elsif ($type eq 'N}') {
	# normal
    } else {
	# old SDBM_File
	$total_rv = $type.$total_rv;
    }

    $total_rv;
}

sub FIRSTKEY {
    my $self = shift;

    my $key = $self->SUPER::FIRSTKEY();
    my @keys = ();
    if (defined $key) {
	do {
	    if($key !~ /\*\*\d+$/s) {
		if(my $new_key = _decode_key($key)) {
		    push(@keys, $new_key);
		}
	    }
	} while($key = $self->SUPER::NEXTKEY($key));
    }
    $KEYS{$self} = \@keys;

    $self->NEXTKEY;
}

sub NEXTKEY {
    my $self = shift;
    shift(@{$KEYS{$self}});
}

sub _index_key {
    my($key, $index) = @_;
    $key =~ s/([\%\*])/uc sprintf("%%%02x",ord($1))/esg;
    $index ? $key.'**'.$index : $key;
}

sub _decode_key {
    my $key = shift;
    $key =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    $key;
}

1;

