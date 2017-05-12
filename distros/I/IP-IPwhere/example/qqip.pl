use 5.008;
use warnings;
use strict;
use Carp;
use Encode;

my %cache;
my $ip_start;
my $tmp;
my $DEBUG=0;

my $FD=set_db('QQWry.Dat');

print db_version($FD),"\n";

print map{query($FD,$_)."\n"} validIP(@ARGV);

sub validIP {

my $re=qr([0-9]|[0-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5]);
my @ip=grep{/^($re\.){3}$re$/} @_;
return @ip;

}

sub gbk2utf {

  my $str=shift;
  return encode("utf-8", decode("gbk", $str));
  return;

}
sub set_db {
    my ($db) = @_;
    my $FD;
    if ( $db && -r $db ) {
        open $FD, '<', $db or croak "how can this happen? $!";
        return $FD;
    }
    carp 'set_db failed';
    return;
}

sub init_db {
    my $FD = shift;
    seek $FD,0,0;
    read $FD, $tmp, 4;
    my $first_index= unpack 'V', $tmp;
    read $FD, $tmp, 4;
    my $last_index = unpack 'V', $tmp;
    print "DEBUG\::init_dab\::OUT $first_index $last_index\n" if $DEBUG;
   return ($first_index,$last_index);
}


sub query {
    my ( $FD, $input ) = @_;
    print "DEBUG\::query\::IN $FD $input\n" if $DEBUG;
    unless ( $FD ) {
        carp 'database is not provided';
        return;
    }
    
    my $ip = convert_input($input);
    
    if ($ip) {
        $cache{$ip} = [ result($FD,$ip) ] unless cached($ip);
        return wantarray ? @{ $cache{$ip} } : join '', @{ $cache{$ip} };
    }
    return;
}

sub convert_input {
    my ( $input ) = @_;
    print "DEBUG\::convert_input\::IN $input\n" if $DEBUG;
    if ( $input =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/ ) {
        return $1 * 256**3 + $2 * 256**2 + $3 * 256 + $4;
    }
    elsif ( $input =~ /(\d+)/ ) {
        return $1;
    }
    else {
        return;
    }
}

sub cached {
    my ($input ) = @_;
   print "DEBUG\::cached\::IN $input\n" if $DEBUG;
    my $ip = convert_input($input);
    return $cache{$ip} ? 1 : 0;
}

sub clear {
   
    my ($ip ) = @_;
   print "DEBUG\::clear\::IN $ip\n" if $DEBUG;
    if ($ip) {
        undef $cache{$ip};
    }
    else {
        undef %cache;
    }
}

sub db_version {
     my $FD= shift;
    print "DEBUG\::db_version\::IN $FD\n" if $DEBUG;
    return query($FD,'255.255.255.0');
}


sub result {
    my ( $FD, $ip ) = @_;
    print "DEBUG\::result\::IN 1 $FD 2 $ip\n" if $DEBUG;
    my $index = Lindex($FD,$ip);
    return unless $index; 

    my ( $base, $ext ) = (q{}) x 2;

    seek $FD, $index + 4, 0;
    read $FD, $tmp, 3;

    my $offset = unpack 'V', $tmp . chr 0;
    seek $FD, $offset + 4, 0;
    read $FD, $tmp, 1;

    my $mode = ord $tmp;

    if ( $mode == 1 ) {
        Lseek($FD);
        $offset = tell $FD;
        read $FD, $tmp, 1;
        $mode = ord $tmp;
        if ( $mode == 2 ) {
            Lseek($FD);
            $base = str($FD);
            seek $FD, $offset + 4, 0;
            $ext = ext($FD);
        }
        else {
            seek $FD, -1, 1;
            $base = str($FD);
            $ext  = ext($FD);
        }
    }
    elsif ( $mode == 2 ) {
        Lseek($FD);
        $base = str($FD);
        seek $FD, $offset + 8, 0;
        $ext = ext($FD);
    }
    else {
        seek $FD, -1, 1;
        $base =str($FD);
        $ext  =ext($FD);
    }

    $base = '' if $base =~ /CZ88\.NET/;
    $ext = '' if $ext =~ /CZ88\.NET/;
    return ( $base, $ext );
}

sub Lindex {

    my ( $FD, $ip ) = @_;
   print "DEBUG\::Lindex\::IN 1 $FD, 2 $ip\n" if $DEBUG; 
    my $low = 0;
    my ($first_index,$last_index)=init_db($FD);
    my $up  = ( $last_index - $first_index) / 7;
    my ( $mid, $ip_start, $ip_end );

    # 二分法查找索引
    while ( $low <= $up ) {
        $mid = int( ( $low + $up ) / 2 );
        seek $FD, $first_index + $mid * 7, 0;
        read $FD, $tmp, 4;
        $ip_start = unpack 'V', $tmp;

        if ( $ip < $ip_start ) {
            $up = $mid - 1;
        }
        else {
            read $FD, $tmp, 3;
            $tmp = unpack 'V', $tmp . chr 0;
            seek $FD, $tmp, 0;
            read $FD, $tmp, 4;
            $ip_end = unpack 'V', $tmp;

            if ( $ip > $ip_end ) {
                $low = $mid + 1;
            }
            else {
                return $first_index + $mid * 7;
            }
        }
    }

    return;
}

sub Lseek {
  
    my $FD = shift;
    print "DEBUG\::Lseek\::IN $FD\n" if $DEBUG;
    read $FD, $tmp, 3;
    my $offset = unpack 'V', $tmp . chr 0;
    seek $FD, $offset, 0;
}


sub str {
    #my $FD = shift;
    print "DEBUG\::str\::IN $FD\n" if $DEBUG;
    my $str;

    read $FD, $tmp, 1;
    while ( ord $tmp > 0 ) {
        $str .= $tmp;
        read $FD, $tmp, 1;
    }
    my $sstr=gbk2utf($str);
    print "DEBUG\::str\::OUT $sstr\n" if $DEBUG;
    return $sstr;
}
sub strc {
    #my $FD = shift;
    print "DEBUG\::strc\::IN $FD\n" if $DEBUG;
    my $str;

    read $FD, $tmp, 1;
    while ( ord $tmp > 0 ) {
        $str .= $tmp;
        read $FD, $tmp, 1;
    }
    print "DEBUG\::strc\::OUT $str\n" if $DEBUG;
    return $str;
}


sub ext {
    #my $FD = shift;
    print "DEBUG\::ext\::IN $FD\n" if $DEBUG;
    read $FD, $tmp, 1;
    my $mode = ord $tmp;

    if ( $mode == 1 || $mode == 2 ) {
        Lseek($FD);
        return str($FD);
        print "DEBUG\::ext1\::OUT str($FD)\n" if $DEBUG;
    }
    else {
        my $str=gbk2utf(chr($mode) . strc($FD));
        print "DEBUG\::ext2\::OUT $str\n" if $DEBUG; 
        return $str;
    }
}

