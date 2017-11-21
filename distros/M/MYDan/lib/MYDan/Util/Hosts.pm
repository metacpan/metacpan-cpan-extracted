package MYDan::Util::Hosts;

use strict;
use warnings;
use Carp;

use Tie::File;
use Fcntl 'O_RDONLY';

use MYDan;

sub new
{
    my ( $class, $path, %host ) = splice @_, 0, 2;

    $path ||= "$MYDan::PATH/etc/hosts";

    if( -f $path )
    {
        die "tie fail: $!" unless tie my @host, 'Tie::File', $path, mode => O_RDONLY, recsep => "\n";

        for my $host ( @host )
        {
            next unless $host =~ /^\s*(\d+\.\d+\.\d+\.\d+)\s+([0-9a-zA-Z][\w\s\.\-]+)/;
            map{$host{$_} = $1 }split /\s+/, $2;
        }
    }

    bless \%host, ref $class || $class;
}

sub match
{
    my $this = shift;
    map{ $_ => $this->{$_} || $_ }@_;
}

sub hosts
{
    my $this = shift;
    return keys %$this;
}

sub dump
{
    my $this = shift;
    return %$this;
}

1;
__END__
