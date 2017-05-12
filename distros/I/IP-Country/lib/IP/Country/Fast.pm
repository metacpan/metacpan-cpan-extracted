package IP::Country::Fast;
use strict;
use warnings;
use Socket qw ( inet_aton );

use vars qw ( $VERSION );
$VERSION = '604.001'; # APR 2006, version 001

my $singleton = undef;
my $ip_db;
my $null = substr(pack('N',0),0,1);
my $nullnullnull = $null . $null . $null;
my %cc;
my $tld_match = qr/\.([a-zA-Z][a-zA-Z])$/o;
my $ip_match = qr/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/o;

my $bit0;
my $bit1;
my @mask;
my @dtoc;
{
    $bit0 = substr(pack('N',2 ** 31),0,1);
    $bit1 = substr(pack('N',2 ** 30),0,1);

    for (my $i = 0; $i <= 31; $i++){
	$mask[$i] = pack('N',2 ** (31 - $i));
    }

    for (my $i = 0; $i <= 255; $i++){
	$dtoc[$i] = substr(pack('N',$i),3,1);
    }
    (my $module_dir = __FILE__) =~ s/\.pm$//;

    local $/;   # set it so <> reads all the file at once

    open (CC, "< $module_dir/cc.gif")
	or die ("couldn't read country database: $!");
    binmode CC;
    my $cc_ultra = <CC>;  # read in the file
    close CC;
    my $cc_num = (length $cc_ultra) / 3;
    for (my $i = 0; $i < $cc_num; $i++){
	my $cc = substr($cc_ultra,3 * $i + 1,2);
	$cc = undef if ($cc eq '--');
	$cc{substr($cc_ultra,3 * $i,1)} = $cc;
    }

    open (IP, "< $module_dir/ip.gif")
	or die ("couldn't read IP database: $!");
    binmode IP;
    $ip_db = <IP>;
    close IP;
}

sub new ()
{
    my $caller = shift;
    unless (defined $singleton){
        my $class = ref($caller) || $caller;
	$singleton = bless {}, $class;
    }
    return $singleton;
}

sub db_time
{
    return unpack("N",substr($ip_db,0,4));
}

sub inet_atocc
{
    my $inet_a = $_[1];
    if ($inet_a =~ $ip_match){
	return inet_ntocc($dtoc[$1].$dtoc[$2].$dtoc[$3].$dtoc[$4]);
    } else {
	if (defined (my $n = inet_aton($inet_a))){
	    return inet_ntocc($n);
	} else {
	    return undef;
	}
    }
}

sub inet_ntocc
{
    # FORMATTING OF EACH NODE IN $ip_db
    # bit0 - true if this is a country code, false if this
    #        is a jump to the next node
    #
    # country codes:
    #   bit1 - true if the country code is stored in bits 2-7
    #          of this byte, false if the country code is
    #          stored in bits 0-7 of the next byte
    #   bits 2-7 or bits 0-7 of next byte contain country code
    #
    # jumps:
    #   bytes 0-3 jump distance (only first byte used if
    #          distance < 64)

    my $inet_n = $_[1] || $_[0];

    my $pos = 4;
    my $byte_zero = substr($ip_db,$pos,1);
    # loop through bits of IP address
    for (my $i = 0; $i <= 31; $i++){

	if (($inet_n & $mask[$i]) eq $mask[$i]){
	    # bit[$i] is set [binary one]
	    # - jump to next node
	    # (start of child[1] node)
	    if (($byte_zero & $bit1) eq $bit1){
		$pos = $pos + 1 + unpack('N', $nullnullnull . ($byte_zero ^ $bit1));
	    } else {
		$pos = $pos + 3 + unpack('N', $null . substr($ip_db,$pos,3));
	    }
	} else {
	    # bit[$i] is unset [binary zero]
	    # jump to end of this node
	    # (start of child[0] node)
	    if (($byte_zero & $bit1) eq $bit1){
		$pos = $pos + 1;
	    } else {
		$pos = $pos + 3;
	    }
	}
	
	# all terminal nodes of the tree start with zeroth bit 
	# set to zero. the first bit can then be used to indicate
	# whether we're using the first or second byte to store the
	# country code
	$byte_zero = substr($ip_db,$pos,1);
	if (($byte_zero & $bit0) eq $bit0){ # country code
	    if (($byte_zero & $bit1) eq $bit1){
		# unpopular country code - stored in second byte
		return $cc{substr($ip_db,$pos+1,1)};
	    } else {
		# popular country code - stored in bits 2-7
		# (we already know that bit 1 is not set, so
		# just need to unset bit 1)
		return $cc{$byte_zero ^ $bit0};
	    }
	}
    }
}

1;
__END__

=head1 NAME

IP::Country::Fast - fast lookup of country codes by IP address

=head1 SYNOPSIS

  use IP::Country::Fast;

=head1 DESCRIPTION

See documentation for IP::Country.

=cut
