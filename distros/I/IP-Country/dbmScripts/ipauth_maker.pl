#!/usr/bin/perl -w
use strict;
$^W = 1;
use Socket qw ( inet_aton inet_ntoa );
use IO::File;
print "Building registry... this will take a moment...\n";

my %log2;
for (my $i=0; $i<=31; $i++){
    $log2{2 ** $i} = $i;
}

# this is our fast stash
my $tree = IPTree->new();

# and this is our pre-generated list of ranges
my $reg_file = 'sorted_authorities.txt';

open (REG, "< $reg_file") || die("can't open $reg_file: $!");
while (my $line = <REG>){
    chomp $line;
    next unless $line =~ /^([^\|]+)\|([^\|]+)\|(..)$/;
    my ($ip,$size,$cc) = ($1,$2,$3);
    $cc = 'UK' if ($cc eq 'GB');
    my $packed_ip = inet_aton($ip);
    my $packed_range = substr(pack('N',$log2{$size}),3,1);
    $tree->add($packed_ip,$packed_range,$cc);
}
close REG || warn("can't close $reg_file, but continuing: $!");


print "Saving ultralite IP registry to disk\n";
my $ip = new IO::File "> ../lib/IP/Authority/ipauth.gif";
if (defined $ip) {
    binmode $ip;
    print $ip pack("N",time()); # returned by $obj->db_time()
    $tree->printTree($ip);
    $ip->close();
} else {
    die "couldn't write IP registry:$!\n";
}


print "Saving ultralite country database to disk\n";

open (CC, "> ../lib/IP/Authority/auth.gif")
    or die ("couldn't create authority database: $!");
binmode CC;
foreach my $country (sort $tree->get_countries()){
    print CC substr(pack('N',$tree->get_cc_as_num($country)),3,1).$country;
}
close(CC);
print "Finished.\n";



package IPTree;
use strict;
use Socket qw ( inet_aton inet_ntoa );
$^W = 1;

my @mask;
my %ctod;
my @dtoc;
my $bit0;
my $bit1;
my $bits12;
my $null;
BEGIN {
    $bit0 = substr(pack('N',2 ** 31),0,1);
    $bit1 = substr(pack('N',2 ** 30),0,1);
    $bits12 = substr(pack('N',2 ** 30 + 2 ** 29),0,1);
    $null = substr(pack('N',0),0,1);
    for (my $i = 1; $i <= 32; $i++){
	$mask[$i] = pack('N',2 ** (32 - $i));
    }
    
    for (my $i=0; $i<=255; $i++){
	$ctod{substr(pack('N',$i),3,1)} = $i;
	$dtoc[$i] = substr(pack('N',$i),3,1);
    }
}

sub new ()
{
    return bless {
	countries => {}
    }, 'IPTree';
}

sub add ($$$$)
{
    my ($tree,$ip,$packed_range,$cc) = @_;
    $tree->_ccPlusPlus($cc);
    my $netmask = 32 - $ctod{$packed_range};
    for (my $i = 1; $i <= $netmask; $i++){
	if (($ip & $mask[$i]) eq $mask[$i]){
	    unless (exists $tree->{1}){
		$tree->{1} = {};
	    }
	    $tree = $tree->{1};
	} else {
	    unless (exists $tree->{0}){
		$tree->{0} = {};
	    }
	    $tree = $tree->{0};
	}
    }
    $tree->{cc} = $cc;
}

sub get_cc_as_num ($)
{
    my ($self,$cc) = @_;
    unless (exists $self->{sorted_cc}){
	$self->{sorted_cc} = {};
	my $i = 0;
	foreach my $c (sort { $self->{countries}->{$b} <=> $self->{countries}->{$a} }
		       keys %{$self->{countries}})
	{
	    $self->{sorted_cc}->{$c} = $i;
	    $i++;
	}
    }
    unless (exists $self->{sorted_cc}->{$cc}){
	die("couldn't find $cc in country database");
    }
    return $self->{sorted_cc}->{$cc};
}

sub get_countries ()
{
    my ($self) = @_;
    unless (exists $self->{sorted_cc}){
	$self->get_cc_as_num('UK');
    }
    return sort keys %{$self->{sorted_cc}};
}

sub _ccPlusPlus ($)
{
    my ($self,$cc) = @_;
    if (exists $self->{countries}->{$cc}){
	$self->{countries}->{$cc}++;
    } else {
	$self->{countries}->{$cc} = 1;
    }
}

sub printTree ($)
{
    my ($self,$fh) = @_;
    _printSize($self,$self,$fh);
}

sub _printSize
{
    my ($self,$node,$fh) = @_;
    if (exists $node->{cc}){
	# country codes are one or two bytes - 
	# popular codes being stored in one byte
	my $cc = $self->get_cc_as_num($node->{cc});
	$cc = _encode_cc($cc);
	print $fh $cc;
    } else {
	# jump distances are three bytes - might also be shrunk later
	my $jump = _findSize($self,$node->{0});
	my $binary_jump = _encode_size($jump);
	print $fh $binary_jump;

	_printSize($self,$node->{0},$fh);
	_printSize($self,$node->{1},$fh);
    }
}

sub _encode_cc
{
    my $cc = shift;
    if ($cc < 64){
	return $dtoc[$cc] | $bit0;
    } else {
	return $dtoc[255] . $dtoc[$cc];
    }
}

sub _encode_size
{
    my $size = shift;
    if ($size < 64){
	return substr(pack('N',$size),3,1) | $bit1;
    } else {
	die ($size) if ($size >= 2**29);
	return substr(pack('N',$size),1,3);
    }
}

sub _findSize
{
    my ($self,$node) = @_;
    my $size = 0;
    if (exists $node->{cc}){
	my $cc = $self->get_cc_as_num($node->{cc});
	$size = length(_encode_cc($cc));
    } else {
	my $node_zero_size = $self->_findSize($node->{0});
	my $node_one_size = $self->_findSize($node->{1});
	$size = length(_encode_size($node_zero_size)) + $node_zero_size + $node_one_size;
    }
    return $size;
}

1;
