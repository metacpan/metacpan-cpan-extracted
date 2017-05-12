#!/usr/bin/perl -w
use strict;
$^W = 1;
use Socket qw (inet_aton inet_ntoa);

my $DEBUG = 0;

my %range;
my $range_count = 0;

my $log2 = log(2);
my @mask;
my @mask_packed;
my %mask_decimal;
for (my $i=0; $i<=31; $i++){
    $mask[$i] = pack('B32', ('1'x(32-$i)).('0'x$i));
    $mask_packed[$i] = pack('C',$i);
    $mask_decimal{pack('C',$i)} = $i;
}

my $ip_match = qr/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/o;
my $reg_dir = './';

# 'SPECIAL' IP RANGES (all from RFC3330)
# a double asterix '**' indicates a local (non-public) IP ranges,
# whereas a double dash '--' indicates some other IANA range

# 'Blanket' coverage, with high handicap (ensure complete coverage)
# note that the handicap is less than the default, to ensure that
# no part is overwritten by RIPE database, which contains IANA ranges
insert_raw(unpack('N',inet_aton('0.0.0.0')),2**32,'--',2**31);

# "This" Network [RFC1700, page 4]
insert_raw(unpack('N',inet_aton('0.0.0.0')),2**24,'IA',2**24);

# Private-Use Networks [RFC1918]
insert_raw(unpack('N',inet_aton('10.0.0.0')),2**24,'IA',2**24);

# Public Data Networks [RFC1700, page 181]
insert_raw(unpack('N',inet_aton('14.0.0.0')),2**24,'IA',2**24);

# Loopback [RFC1700, page 5]
insert_raw(unpack('N',inet_aton('127.0.0.0')),2**24,'IA',2**24);

# Link Local
insert_raw(unpack('N',inet_aton('169.254.0.0')),2**16,'IA',2**16);

# Private-Use Networks [RFC1918]
insert_raw(unpack('N',inet_aton('172.16.0.0')),2**20,'IA',2**20);

# Test-Net
insert_raw(unpack('N',inet_aton('192.0.2.0')),2**8,'IA',2**8);

# 6to4 Relay Anycast [RFC3068]
insert_raw(unpack('N',inet_aton('192.88.99.0')),2**8,'IA',2**8);

# Private-Use Networks [RFC1918]
insert_raw(unpack('N',inet_aton('192.168.0.0')),2**16,'IA',2**16);

# Network Interconnect Device Benchmark Testing [RFC2544]
insert_raw(unpack('N',inet_aton('198.18.0.0')),2**17,'IA',2**17);

# Multicast [RFC3171]
insert_raw(unpack('N',inet_aton('224.0.0.0')),2**28,'IA',2**28);

# Reserved for Future Use [RFC1700, page 4]
insert_raw(unpack('N',inet_aton('240.0.0.0')),2**28,'IA',2**28);

read_reg('delegated-afrinic-latest');
read_reg('delegated-lacnic-latest');
read_reg('delegated-apnic-latest');
read_ripe();
read_reg('delegated-arin-latest');

join_neighbours();
punch_holes();
optimize();
output();


sub output
{
    open(OUTFILE,"> sorted_authorities.txt") or die ($!);
    foreach my $key (sort keys %range){
	print OUTFILE inet_ntoa(substr($key,0,4)) . '|';
	print OUTFILE 2 ** unpack('C',substr($key,4,1)) .'|';
	print OUTFILE $range{$key}->{cc} ."\n";
    }
    close OUTFILE;
}


sub formatRange
{
    my ($start,$end,$cc) = @_;
    my $ip = pack('N',$start);
    my $size = ($end - $start) + 1;

    while (1){
        my $mask = int(log($size)/log(2));
        my $max_mask = get_max_mask($ip);
        if ($max_mask < $mask){
            $mask = $max_mask;
        }
        print OUTFILE inet_ntoa($ip).'|'. 2 ** $mask .'|'. $cc ."\n";
        $size = $size - (2 ** $mask);
        return unless ($size > 0);
        $ip = pack('N',(unpack('N',$ip) + 2 ** $mask));
    }
}



sub optimize
{
    print STDERR "performing final optimizations\n";
    my $repeat = 1;
    while ($repeat){
	$repeat = 0;
	my @key = sort keys %range;
	my $one = $key[0];
	for (my $i = 1; $i<=$#key; $i++){
	    my $two = $key[$i];
	    if (exists $range{$one}){
		my $one_mask_decimal = $mask_decimal{substr($one,4,1)};
		my $two_mask_decimal = $mask_decimal{substr($two,4,1)};
		if (($one_mask_decimal == $two_mask_decimal) && 
		    ($range{$one}->{cc} eq $range{$two}->{cc})){
		    my $one_ip_packed = substr($one,0,4);
		    my $two_ip_packed = substr($two,0,4);
		    
		    if (($one_ip_packed & $mask[$one_mask_decimal + 1]) eq ($two_ip_packed & $mask[$two_mask_decimal + 1])){
			my $one_ip_decimal = unpack('N',substr($one,0,4));
			my $two_ip_decimal = unpack('N',substr($two,0,4));
			insert_raw($one_ip_decimal, 2 ** ($one_mask_decimal + 1), $range{$one}->{cc}, $range{$one}->{handicap});
			delete $range{$one};
			delete $range{$two};
			$repeat++;
		    }
		}
	    }
	    $one = $two;
	}
	print STDERR "  repeating ($repeat joins)\n" if $repeat;
    }
}

sub join_neighbours
{
    print STDERR "optimizing by joining neighbouring ranges\n";
    my $repeat = 1;
    while ($repeat){
	$repeat = 0;
	my @key = sort keys %range;
	my $one = $key[0];
	for (my $i = 1; $i<=$#key; $i++){
	    my $two = $key[$i];
	    if (exists $range{$one}){
		my $one_mask_decimal = $mask_decimal{substr($one,4,1)};
		my $two_mask_decimal = $mask_decimal{substr($two,4,1)};
		if (($one_mask_decimal == $two_mask_decimal) && 
		    ($range{$one}->{cc} eq $range{$two}->{cc}) &&
		    ($range{$one}->{handicap} eq $range{$two}->{handicap})){
		    my $one_ip_packed = substr($one,0,4);
		    my $two_ip_packed = substr($two,0,4);
		    
		    if (($one_ip_packed & $mask[$one_mask_decimal + 1]) eq ($two_ip_packed & $mask[$two_mask_decimal + 1])){
			my $one_ip_decimal = unpack('N',substr($one,0,4));
			my $two_ip_decimal = unpack('N',substr($two,0,4));
			insert_raw($one_ip_decimal, 2 ** ($one_mask_decimal + 1), $range{$one}->{cc}, $range{$one}->{handicap});
			delete $range{$one};
			delete $range{$two};
			$repeat++;
		    }
		}
	    }
	    $one = $two;
	}
	print STDERR "  repeating ($repeat joins)\n" if $repeat;
    }
}

sub punch_holes
{
    print STDERR "removing overlapping ranges\n";
    my $repeat = 1;
    while ($repeat) {
	$repeat = 0;
	foreach my $one (keys %range){
	    next unless (exists $range{$one}); # we're deleting, so need to be careful
	    if (defined (my $two = get_existing_range($one))){
		$repeat++;
		if ($DEBUG){
		    print STDERR ">>>>MATCH: ". inet_ntoa(substr($one,0,4)).'/'.unpack('C',substr($one,4,1));
		    print STDERR " and ". inet_ntoa(substr($two,0,4)).'/'.unpack('C',substr($two,4,1));
		    print STDERR "\n";
		}
		my $one_mask_decimal = $mask_decimal{substr($one,4,1)};
		my $two_mask_decimal = $mask_decimal{substr($two,4,1)};
		if ($one_mask_decimal > $two_mask_decimal){
		    punch_hole($one,$two);
		} else {
		    punch_hole($two,$one);
		}
	    }
	}
	print STDERR "  repeating ($repeat overlapping ranges)\n" if $repeat;
    }
}

sub punch_hole
{
    my ($larger,$smaller) = @_;
    my $larger_mask_decimal = $mask_decimal{substr($larger,4,1)};
    my $smaller_mask_decimal = $mask_decimal{substr($smaller,4,1)};
    my $larger_handicap = $range{$larger}->{handicap};
    my $smaller_handicap = $range{$smaller}->{handicap};
    if ($larger_handicap <= $smaller_handicap){
	# $larger is less handicapped, therefore $smaller
	# is deleted
	if ($DEBUG){
	    print STDERR ">>>>removing ". inet_ntoa(substr($smaller,0,4)).'/'.unpack('C',substr($smaller,4,1));
	    print STDERR " in favour of ". inet_ntoa(substr($larger,0,4)).'/'.unpack('C',substr($larger,4,1));
	    print STDERR "\n";
	}
	delete $range{$smaller};
	$range_count--;
	
    } else {
	# $smaller is less handicapped, therefore a hole
	# should be cut for it in $larger
	my $larger_cc = $range{$larger}->{cc};
	if ($DEBUG){
	    print STDERR ">>>>deleting: ". inet_ntoa(substr($larger,0,4)).'/'.unpack('C',substr($larger,4,1));
	    print STDERR "\n";
	}
	delete $range{$larger};
	$range_count--;
	
	my $larger_ip_packed = substr($larger,0,4);
	my $larger_ip_decimal_start = unpack('N',$larger_ip_packed);
	my $smaller_ip_packed = substr($smaller,0,4);
	my $smaller_ip_decimal_start = unpack('N',$smaller_ip_packed);
	
	if ($larger_ip_decimal_start < $smaller_ip_decimal_start){
	    if ($DEBUG){
		print STDERR ">>>>creating: ". inet_ntoa(pack('N',$larger_ip_decimal_start)).'/'.
		    int(log($smaller_ip_decimal_start-$larger_ip_decimal_start)/$log2);
		print STDERR "\n";
	    }
	    insert_raw($larger_ip_decimal_start,$smaller_ip_decimal_start-$larger_ip_decimal_start,$larger_cc,$larger_handicap);
	}
	
	my $larger_ip_decimal_end = $larger_ip_decimal_start + (2 ** $larger_mask_decimal) - 1;
	my $smaller_ip_decimal_end = $smaller_ip_decimal_start + (2 ** $smaller_mask_decimal) - 1;
	
	if ($larger_ip_decimal_end > $smaller_ip_decimal_end){
	    if ($DEBUG){
		print STDERR ">>>>creating: ". inet_ntoa(pack('N',$smaller_ip_decimal_end+1)).'/'.
		    int(log($larger_ip_decimal_end-$smaller_ip_decimal_end)/$log2);
		print STDERR "\n";
	    }
	    insert_raw($smaller_ip_decimal_end+1,$larger_ip_decimal_end-$smaller_ip_decimal_end,$larger_cc,$larger_handicap);
	}
    }
}

sub get_existing_range
{
    my $key = shift;
    my $ip_packed = substr($key,0,4);
    for (my $i = 31; $i>=0; $i--){
	my $existing_key = ($ip_packed & $mask[$i]) . $mask_packed[$i];
	next if $existing_key eq $key;
	if (exists $range{$existing_key}){
	    return $existing_key;
	}
    }
    return undef;
}

sub insert_raw
{
    my ($ip_decimal,$size,$cc,$handicap) = @_;
    while ($size > 0){
	my $ip_packed = pack('N',$ip_decimal);
	my $max_mask = get_max_mask($ip_packed);
	if ((2 ** $max_mask) > $size){
	    $max_mask = int(log($size)/$log2);
	}
	add_range($ip_packed,$mask_packed[$max_mask],$cc,$handicap);
	$ip_decimal += (2 ** $max_mask);
	$size -= (2 ** $max_mask);
    }
}

sub add_range
{
    my ($ip_packed, $mask_packed, $cc, $handicap) = @_;
    my $key = $ip_packed . $mask_packed;
    if (exists $range{$key}){
	my $existing = $range{$key};
	if ($existing->{handicap} > $handicap){
	    $range{$ip_packed . $mask_packed} = {cc => $cc, handicap => $handicap};
	    $range_count++;
	}
    } else {
	$range{$ip_packed . $mask_packed} = {cc => $cc, handicap => $handicap};
	$range_count++;
    }
}

sub get_max_mask
{
    my $ip_packed = shift;
    for (my $i = 31; $i>=0; $i--){
	return $i
	    if (($ip_packed | $mask[$i]) eq $mask[$i]);
    }
    die("strange IP: ". inet_ntoa($ip_packed));
}

sub read_ripe
{
    print STDERR "loading data from ripe.db.inetnum\n";
    my $ripe_inet_line = qr/^inetnum:\s+(\S+)\s*-\s*(\S+)/o;
    my $ripe_cc_line = qr/^country:\s+(\S\S)/o;
    open (REG,"< $reg_dir/ripe.db.inetnum") or die("can't open $reg_dir/ripe.db.inetnum: $!");
    binmode REG, ':crlf';
    {
	my $start;
	my $end;
	my $cc;
	my $status;
	while (my $line = <REG>){
	    if (defined $start){
		next unless $line =~ $ripe_cc_line;

		$cc = 'RI';
		insert_raw($start,$end-$start+1,$cc,$end-$start+1);
		$start = undef;
		$end = undef;
	    } elsif ($line =~ $ripe_inet_line){
		my ($a_start,$a_end) = ($1,$2);
		if ($a_start =~ $ip_match){
		    $start = ($1 * 16777216) + ($2 * 65536) + ($3 * 256) + $4;
		}
		if ($a_end =~ $ip_match){
		    $end = ($1 * 16777216) + ($2 * 65536) + ($3 * 256) + $4;
		}
		die($line) unless ((defined $start) && (defined $end));
	    } else {
	    }
	}
    }
    close REG || warn("can't close $reg_dir/ripe.db.inetnum, but continuing: $!");
}

sub read_reg
{
    my $path = shift;
    open (REG, "< $reg_dir/$path") || die("can't open $reg_dir/$path: $!");
    binmode REG, ':crlf';
    print STDERR "loading data from $path\n";
    
    my $stat_line = qr/^([^\|]+)\|(..)\|ipv4\|([^\|]+)\|(\d+)\|/o;
    while (my $line = <REG>){
	chomp $line;
	next unless $line =~ $stat_line;
	my ($auth,$cc,$ip,$size) = ($1,undef,$3,$4);
	next unless ($ip =~ $ip_match);
	my $start = ($1 * 16777216) + ($2 * 65536) + ($3 * 256) + $4;
	$cc = 'AP' if ($auth eq 'apnic');
	$cc = 'AR' if ($auth eq 'arin');
	$cc = 'IA' if ($auth eq 'iana');
	$cc = 'LA' if ($auth eq 'lacnic');
	$cc = 'AF' if ($auth eq 'afrinic');
	$cc = 'RI' if ($auth eq 'ripencc');
	die ('no authrority: '.$auth) unless defined $cc;
	insert_raw($start,$size,$cc,$size);
    }
    close REG || warn("can't close $reg_dir/$path, but continuing: $!");
}
