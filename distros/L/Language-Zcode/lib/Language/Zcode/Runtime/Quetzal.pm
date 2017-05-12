package Language::Zcode::Runtime::Quetzal;

use strict;
use warnings;

=head1 NAME

Language::Zcode::Runtime::Quetzal - Save/restore Z-machine state using the Quetzal standard

=cut

use constant QUETZAL_SUB_ID => "IFZS";
use constant QUETZAL_STACK => "Stks";
use constant QUETZAL_HEADER => "IFhd";
use constant QUETZAL_COMPRESSED_MEMORY => "CMem";
use constant QUETZAL_UNCOMPRESSED_MEMORY => "UMem";

sub parse_quetzal {
    my $st = shift; # string containing entire quetzal file
    my $pos = 0;  # position in $st

    # Stuff we'll be returning
    my ($memory_ref, @call_stack, %header);

    # Read very beginning of save file
    my $t = substr($st, 0, 4); die "Not an IFF file!\n" unless $t eq "FORM";
    $t = substr($st, 4, 4); 
    my $size = unpack "N", $t; print "size $size\n"; 
    die "Not a simple IFF file!\n" unless $size == length($st)-8;
    $t = substr($st, 8, 4); 
    die "Not a Quetzal save!" unless $t eq QUETZAL_SUB_ID;

    # Read a set of chunks and parse them
    $pos = 12;
    my $did_header = 0;
    my ($name, $data);
    while ($pos < $size) {
	# Read the chunk
	my $len;
	#print "Pos $pos\n";
	($name, $len) = unpack "A4 N", substr($st, $pos, 8); $pos += 8;
	my $data = substr($st, $pos, $len); $pos += $len;
    #    print "length $len - ",length $data," - ", length $st,"\n";
	if ($len % 2) { 
	    substr($st, $pos, 1) eq "\0" or die "expecting 0 at $pos!\n"; $pos++
	}
	print "$name, ",length($data),"\n";

	# Do stuff based on chunk
	# Quetzal Spec 5.4: Header info MUST come before Mem/Stacks
	if ($name eq QUETZAL_HEADER) {
	    %header = read_header($data);
	    $did_header = 1;

	} elsif ($name eq QUETZAL_STACK) {
	    die QUETZAL_HEADER . " chunk must come before stack chunk " .
		"in save file\n" unless $did_header;
	    @call_stack = read_stacks($data);

	} elsif ($name eq QUETZAL_COMPRESSED_MEMORY) {
	    die QUETZAL_HEADER . " chunk must come before memory chunk " .
		"in save file\n" unless $did_header;
	    $memory_ref = read_cmem($data);
	} elsif ($name eq QUETZAL_UNCOMPRESSED_MEMORY) {
	    die QUETZAL_HEADER . " chunk must come before memory chunk " .
		"in save file\n" unless $did_header;
	    $memory_ref = read_umem($data);
	} else { print "Ignoring $name chunk\n"; }
    }

    return ($memory_ref, \@call_stack, \%header);
} 

######################

sub read_header {
    my $data = shift;
    my ($release, $serial, $checksum, $PC1, $PC2) = unpack
	"n        A6       n          n     C", 
	substr($data, 0, 13);
    my $PC = 256 * $PC1 + $PC2;
    my %header = (
	release => $release, 
	serial => $serial,
        checksum => $checksum,
       	restore_PC => $PC,
    );
    return %header;
}

sub read_stacks {
    my $data = shift;
    my @call_stack = (); # stack of frames
#    print join " ", unpack "C*", $data;
    my $p = 0;
    while ($p < length $data) {
	my ($PC1, $PC2, $args, $stack_size, $store, $flags);
	($PC1, $PC2, $flags, $store, $args, $stack_size) = unpack
	    "n C     C       C       B8     n", 
	    substr($data, $p, 8); $p += 8;
	my @args = split//,$args;
	my $PC = 256 * $PC1 + $PC2;
	my $discard_result = int($flags >> 4); 
	my $num_locals = $flags & 0xf; # just last four bits
	die "Bad result-discard flag $discard_result" unless $discard_result<2;
	my @locv = unpack "n*", substr($data, $p, $num_locals*2);
	$p += $num_locals*2;
	my @stack = unpack "n*", substr($data, $p, $stack_size*2);
	$p += $stack_size*2;

	my $frame_ref = {
	    next_PC => $PC,
	    discard_bit => $discard_result,
	    store_var => $store,
	    args => join("",@args),
	    locals => \@locv,
	    eval_stack => \@stack,
	};
	push @call_stack, $frame_ref;
    }
    return @call_stack;
}

sub read_cmem {
    my $data = shift;
    # "0 n" means n PLUS ONE zeros
    (my $diff = $data) =~ s/(\0)(\C)/$1 . $1 x ord $2/ge;
    # bitwise xor with original memory 
    # ("" says they're really strings, not nums, so do char-by-char or'ing)
    my $dynamic_orig = pack "C*", @{&PlotzMemory::get_orig_dynamic_memory};
    my $memory = "$diff" ^ "$dynamic_orig";

#    $diff =~ s/\C/sprintf("%3d", ord $&)/ge;
#    print join "\n", $diff =~ /(.{48})/g,$',"";
    # Note: memory size may be smaller than dynamic memory read in.
    # In that case, Quetzal 3.4, the rest of @mem is all zeros
    my @mem = unpack "C*", $memory;

    return \@mem;
}

sub read_umem {
    my $data = shift;
    my @mem = unpack "C*", $data;
    return \@mem;
}

######################
# Input: header, stack, memory for quetzal
# Output: string that will be a quetzal file
sub build_quetzal {
    my ($href, $sref, $mref) = @_;
    my $collect = QUETZAL_SUB_ID;
    $collect .= write_header(QUETZAL_HEADER, $href);
    $collect .= write_memory(QUETZAL_COMPRESSED_MEMORY, $mref);
    $collect .= write_stacks(QUETZAL_STACK, $sref);

    #print "length collect is ",length $collect,"\n";
    # Add overall header, which includes the size of the rest of the file
    my $IFF = "FORM" . pack("N", length $collect);
    $IFF .= $collect;
    return $IFF;
}

sub write_chunk {
    my ($name, $data) = @_;
    my $len = length $data;
    #print "Pos $pos\n";
    my $str = pack "A4 N", $name, $len;
    $str .= $data;
    $str .= "\0" if $len % 2;
    return $str;
}

sub write_header {
    my ($name, $href) = @_;
    my %header = %$href;
    printf "Rel: %s, Ser#: %s, Check: %s, RestorePC: %s (%x)\n",
	@header{qw(release serial checksum restore_PC restore_PC)} 
	if $main::DEBUG;
    my ($release, $serial, $checksum, $PC) = 
	@header{qw(release serial checksum restore_PC)};
    my $PC1 = $PC >> 8;
    my $PC2 = $PC & 0xFF;
    my $data = pack
	"n        A6       n          n     C", 
        $release, $serial, $checksum, $PC1, $PC2;
    my $str = write_chunk($name, $data);
    return $str;
}

sub write_stacks {
    my ($name, $sref) = @_;
    my $data = "";
    foreach my $frame (@$sref) {
	my %f = %$frame;
	printf "PC %s (%x), call_*n? %s, store %s, args %s, %s locals, stack size %s
	    Locals @{$f{locals}}
	    Stack @{$f{eval_stack}}\n",
	    @f{qw(next_PC next_PC discard_bit store_var args)},
	    $#{$f{locals}} +1, $#{$f{eval_stack}} +1
	    if $main::DEBUG;

	my ($PC, $discard_bit, $store, $args, $locref, $stackref) =
	    @f{qw(next_PC discard_bit store_var args locals eval_stack)};
	die "Bad result-discard flag $discard_bit" unless $discard_bit<2;
	my @split_args = split//,$args; # we don't actually need this
	my @locv = @$locref;
	my @stack = @$stackref;

	my ($PC1, $PC2, $flags, $stack_size, $num_locals);
	$PC1 = $PC >> 8;
	$PC2 = $PC & 0xFF;
	$stack_size = @stack;
	$num_locals = @locv;
	die "Number of locals must be < 16" unless $num_locals < 16;
	$flags = ($discard_bit << 4) | $num_locals;

	my $frame_data = pack
	       "n C     C       C       B8     n", 
	    $PC1, $PC2, $flags, $store, $args, $stack_size;
	$frame_data .= pack "n*", @locv, @stack;
	$data .= $frame_data;
    }
    my $str = write_chunk($name, $data);
    return $str;
}

# write COMPRESSED memory
sub write_memory {
    my ($name, $mem_ref) = @_;
    # memory at time of save
    my $memory = pack "C*", @$mem_ref;
    # bitwise xor with original memory 
    # ("" to specify they're really strings, not nums)
    my $dynamic_orig = pack "C*", @{&PlotzMemory::get_orig_dynamic_memory};
    my $diff = "$memory" ^ "$dynamic_orig";
    # Remove trailing zeros (which show no change from orig memory 
    # beyond a certain point)
    $diff =~ s/\0+$//;

    # Compress
    (my $data = $diff) =~ s/\0{1,256}/"\0" . chr(length($&)-1)/ge;

#    $memory =~ s/\C/sprintf("%3d", ord $&)/ge;
#    print join "\n", $memory =~ /(.{48})/g,$',"";
#    for (my $i=0; $i < @mem; $i+=16) {
#	my $m = $i>@mem-16 ? $#mem : $i+15;
#	printf "%3d"x($m-$i +1) ."\n", @mem[$i..$m];
#    }
#    print "@mem\n";

    my $str = write_chunk($name, $data);
    return $str;
}

1;
