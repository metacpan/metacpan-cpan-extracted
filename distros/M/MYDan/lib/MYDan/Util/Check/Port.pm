package MYDan::Util::Check::Port;
use strict;
use warnings;

$|++;

sub new
{
    my ( $class, $proto, @port ) = @_;

    die "not supported.\n" unless $proto && ( $proto eq 'tcp' || $proto eq 'udp' );
    die "port undef\n" unless @port;

    map{ die "port $_ format error.\n" unless $_ =~ /^\d+$/ }@port;

    bless +{ proto => $proto, port => \@port }, ref $class || $class;
}

sub check
{
    my ( $this, %run,  $error ) = @_;
    my ( $proto, $port ) = @$this{qw( proto port )};

    my %listen = map{ $_ => 1 } $proto eq 'tcp' ? _tcpport() : _udpport();
    map{ print "LISTEN $proto $_\n";} keys %listen if $run{debug};
    map{
        if( $listen{$_} )
        {
            print "$proto $_ listen\n";
        }
        else
        {
            print "[Error] $proto $_ not listen\n";
            $error ++;
        }
    }@$port;

    return $error;
}

sub _tcpport
{
    return _port( `ss -t -l -n` );
}

sub _udpport
{
    return _port( `ss -u -a -n` );
}

sub _port
{
    my ( @x, @port  )= @_;
    chomp @x; shift @x;

    for ( @x )
    {
        my @fields = split /\s+/, $_;
        my $fieldsLen = scalar @fields;

        die "format not supported.\n" if $fieldsLen != 4 && $fieldsLen != 5;

        my $index = $fieldsLen == 5 ? 3 : 2;
        push ( @port, $1 ) if $fields[$index] =~ /:(\d+)$/;
    }

    return @port;
}

1;
__END__
