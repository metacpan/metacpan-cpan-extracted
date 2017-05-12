use lib '../lib';
use IO::Socket::Socks;
use strict;

# connect to www.google.com via socks chain

my @chain = (
    {ProxyAddr => '10.0.0.1', ProxyPort => 1080, SocksVersion => 4, SocksDebug => 1},
    {ProxyAddr => '10.0.0.2', ProxyPort => 1080, SocksVersion => 4, SocksDebug => 1},
    {ProxyAddr => '10.0.0.3', ProxyPort => 1080, SocksVersion => 5, SocksDebug => 1},
    {ProxyAddr => '10.0.0.4', ProxyPort => 1080, SocksVersion => 4, SocksDebug => 1},
    {ProxyAddr => '10.0.0.5', ProxyPort => 1080, SocksVersion => 5, SocksDebug => 1},
    {ProxyAddr => '10.0.0.6', ProxyPort => 1080, SocksVersion => 4, SocksDebug => 1},
);

my $dst = {ConnectAddr => 'www.google.com', ConnectPort => 80};

my $sock;
my $len;

TRY:
while(@chain)
{
    for(my $i=0, $len = 0; $i<@chain; $i++)
    {
        unless($len)
        {
            $sock = IO::Socket::Socks->new(
                %{$chain[$i]}, Timeout => 10,
                $#chain != $i ? (ConnectAddr => $chain[$i+1]->{ProxyAddr}, ConnectPort => $chain[$i+1]->{ProxyPort})
                    : %$dst
            );
            
            if($sock)
            {
                $len++;
            }
            elsif($! != ESOCKSPROTO)
            { # connection to proxy failed
                shift @chain;
                next TRY;
            }
            else
            {
                splice @chain, 0, 2;
                next TRY;
            }
        }
        else
        {
            my $st = $sock->command(
                %{$chain[$i]},
                $#chain != $i ? (ConnectAddr => $chain[$i+1]->{ProxyAddr}, ConnectPort => $chain[$i+1]->{ProxyPort})
                    : %$dst
            );
            
            if($st)
            {
                $len++;
            }
            else
            { # on fail we don't know which of the two links broken
              # so, remove both from the chain
                splice @chain, $i, 2;
              # if one of the link in the chain is broken we should
              # try to build chain from the beginning
                next TRY;
            }
        }
    }
    
    last;
}

unless($sock)
{
    die('Bad chain');
}
else
{
    warn("chain length is $len");
}

$sock->syswrite (
    "GET / HTTP/1.0\015\012".
    "Host: www.google.com\015\012\015\012"
);

while($sock->sysread(my $buf, 1024))
{
    print $buf;
}
