#!/usr/bin/perl -w

use strict;

use constant QUETZAL_SUB_ID => "IFZS";
# Byte in Zfile header that stores dynamic memory size
use constant DYNAMIC_MEMORY_SIZE => 0xE;
use constant QUETZAL_STACK => "Stks";
use constant QUETZAL_HEADER => "IFhd";
use constant QUETZAL_COMPRESSED_MEMORY => "CMem";
use constant QUETZAL_UNCOMPRESSED_MEMORY => "UMem";

die "Usage: $0 save_file z_file" unless @ARGV == 2;

# read save file
my $save_file = shift;
open F, $save_file or die "$save_file: $!\n"; binmode F;
my $st;
my $pos = 0;
{ local $/; undef $/; $st = <F>; }
close F;

# read dynamic memory
my $zfile = shift;
open Z, $zfile or die "$zfile: $!\n";
seek Z, DYNAMIC_MEMORY_SIZE, 0 or die "seek: $!\n";
my $dsize;
read Z, $dsize, 2 or die "read dynamic memory size: $!\n";;
$dsize = unpack "n", $dsize;
print "Dynamic memory size is $dsize\n";
seek Z, 0, 0 or die "seek: $!";
my $dynamic_memory;
read Z, $dynamic_memory, $dsize or die "read dynamic memory: $!\n";
close Z;

$_ = substr($st, 0, 4); die "Not an IFF file!\n" unless $_ eq "FORM";
$_ = substr($st, 4, 4); 
my $size = unpack "N", $_; print "size $size\n"; 
die "Not a simple IFF file!\n" unless $size == length($st)-8;# eq (-s $save_file)-8;
$_ = substr($st, 8, 4); die "Not a Quetzal save!" unless $_ eq QUETZAL_SUB_ID;

$pos = 12;
my $did_header = 0;
my ($memory_ref, @Save_Stack, %header);
while ($pos < $size) {
    my ($name, $data) = read_chunk(); # changes $pos
    print "$name, ",length($data),"\n";
    # Quetzal Spec 5.4: Header info MUST come before Mem/Stacks
    if ($name eq QUETZAL_HEADER) {
	%header = read_header($data);
	$did_header = 1;

    } elsif ($name eq QUETZAL_STACK) {
	die QUETZAL_HEADER . " chunk must come before stack chunk " .
	    "in save file\n" unless $did_header;
	@Save_Stack = read_stacks($data);

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

my $collect = QUETZAL_SUB_ID;
$collect .= write_header(QUETZAL_HEADER, %header);
$collect .= write_memory(QUETZAL_COMPRESSED_MEMORY, $memory_ref);
$collect .= write_stacks(QUETZAL_STACK, @Save_Stack);

print "length collect is ",length $collect,"\n";
# Add overall header, which includes the size of the rest of the file
my $IFF = "FORM" . pack("N", length $collect);

open FOO, ">zzz.sav";
print FOO "$IFF$collect";
close FOO;

exit;

######################

sub read_chunk {
    #print "Pos $pos\n";
    my ($name, $len) = unpack "A4 N", substr($st, $pos, 8); $pos += 8;
    my $data = substr($st, $pos, $len); $pos += $len;
#    print "length $len - ",length $data," - ", length $st,"\n";
    if ($len % 2) { 
	substr($st, $pos, 1) eq "\0" or die "expecting 0 at $pos!\n"; $pos++
    }
    return $name, $data;
}

sub read_header {
    my $data = shift;
    my ($release, $serial, $checksum, $PC1, $PC2) = unpack
	"n        A6       n          n     C", 
	substr($data, 0, 13);
    my $PC = sprintf('%x',256 * $PC1 + $PC2);
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
    my @Save_Stack = (); # stack of frames
#    print join " ", unpack "C*", $data;
    my $p = 0;
    while ($p < length $data) {
	my ($PC1, $PC2, $args, $stack_size, $store, $flags);
	($PC1, $PC2, $flags, $store, $args, $stack_size) = unpack
	    "n C     C       C       B8     n", 
	    substr($data, $p, 8); $p += 8;
	my @args = split//,$args;
	#my $PC = 256 * $PC1 + $PC2;
	my $PC = sprintf('%x',256 * $PC1 + $PC2);
	my $discard_result = int($flags >> 4); 
	my $num_locals = $flags & 0xf; # just last four bits
	die "Bad result-discard flag $discard_result" unless $discard_result<2;
	my @locv = unpack "n*", substr($data, $p, $num_locals*2);
	$p += $num_locals*2;
	my @stack = unpack "n*", substr($data, $p, $stack_size*2);
	$p += $stack_size*2;

	my $frame_ref = {
	    PC =>$PC,
	    discard_bit => $discard_result,
	    store_var => $store,
	    args => join("",@args),
	    locals => \@locv,
	    eval_stack => \@stack,
	};
	push @Save_Stack, $frame_ref;
    }
    return @Save_Stack;
}

sub read_cmem {
    my $data = shift;
    # "0 n" means n PLUS ONE zeros
    (my $diff = $data) =~ s/(\0)(\C)/$1 . $1 x ord $2/ge;
    # bitwise xor with original memory 
    # ("" to specify they're really strings, not nums)
    my $memory = "$diff" ^ "$dynamic_memory";

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
    my ($name, %header) = @_;
    printf "Rel: %s, Ser#: %s, Check: %s, RestorePC: %s\n",
	@header{qw(release serial checksum restore_PC)};
    my ($release, $serial, $checksum, $PC) = 
	@header{qw(release serial checksum restore_PC)};
    $PC = hex $PC;
    my $PC1 = $PC >> 8;
    my $PC2 = $PC & 0xFF;
    my $data = pack
	"n        A6       n          n     C", 
        $release, $serial, $checksum, $PC1, $PC2;
    my $str = write_chunk($name, $data);
    return $str;
}

sub write_stacks {
    my ($name, @Save_Stack) = @_;
    my $data = "";
    foreach my $frame (@Save_Stack) {
	my %f = %$frame; my $z = hex $f{PC};
	printf "PC %s ($z), ignore result? %s, store %s, args %s, %s locals, stack size %s
	    Locals @{$f{locals}}
	    Stack @{$f{eval_stack}}\n",
	    @f{qw(PC discard_bit store_var args)},
	    $#{$f{locals}} +1, $#{$f{eval_stack}} +1;

	my ($PC, $discard_bit, $store, $args, $locref, $stackref) =
	    @f{qw(PC discard_bit store_var args locals eval_stack)};
	die "Bad result-ignore flag $discard_bit" unless $discard_bit<2;
	my @split_args = split//,$args; # we don't actually need this
	my @locv = @$locref;
	my @stack = @$stackref;

	my ($PC1, $PC2, $flags, $stack_size, $num_locals);
	$PC = hex $PC;
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
    my $diff = "$memory" ^ "$dynamic_memory";
    # Remove trailing zeros (which show no change from orig memory 
    # beyond a certain point)
    $diff =~ s/\0+$//;

    # Compress
    (my $data = $diff) =~ s/\0{1,256}/"\0" . chr(length($&)-1)/ge;

    $memory =~ s/\C/sprintf("%3d", ord $&)/ge;
#    print join "\n", $memory =~ /(.{48})/g,$',"";
#    for (my $i=0; $i < @mem; $i+=16) {
#	my $m = $i>@mem-16 ? $#mem : $i+15;
#	printf "%3d"x($m-$i +1) ."\n", @mem[$i..$m];
#    }
#    print "@mem\n";

    my $str = write_chunk($name, $data);
    return $str;
}
