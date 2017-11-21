package MYDan::Util::Sync;
use strict;
use warnings;
use Carp;
use MYDan;

sub new
{
    my ( $class, $conf ) = @_;
    die "conf undef" unless $conf;
    bless $conf, ref $class || $class;
}

sub sync
{
    my ( $this, @name ) = @_;

    die "addr nofind" unless my $addr = $this->{api}{addr};

    my %sync = (
        'node.cache' =>  +{ path => $this->{range}{cache},    source => 'node.cache', private => 0 },
         hosts        => +{ path => "$MYDan::PATH/etc/hosts", source => 'hosts', private => 1 },
        'util.proxy' => +{ path => "$MYDan::PATH/etc/util/conf/proxy", source => 'util.proxy', private => 1 },
        'go' =>         +{ path => "$MYDan::PATH/etc/util/conf/go", source => 'go', private => 1 },
        'gateway' =>    +{ path => "$MYDan::PATH/etc/util/conf/gateway", source => 'gateway', private => 1 },
        'pass' =>       +{ path => "$MYDan::PATH/etc/util/conf/pass", source => 'pass', private => 1 },
    );

    @name = keys %sync unless @name;
    printf "sync: %s\n", join ',', @name;

    for my $k ( @name )
    {
	next unless my $v = $sync{$k};
        warn "sync $k ...\n";

	die "sync $k fail: path undef\n" unless $v->{path};

        my ( $path, $tmp, $private, $lock ) = map{ "$v->{path}$_"}( '', '.tmp','.private', '.lock' );

        next if -e $lock && warn "sync $k skip.\n";

	unlink $tmp if -e $tmp;

        die "sync $k fail.\n" if system "wget -O '$tmp' $addr/download/sync/$v->{source}";

        die "add $k.private fail" if $v->{private} && -e $private && system "cat '$private' >> '$tmp'";

        die "rename $k fail.\n" if system "mv '$tmp' '$path'";
    }
}

1;
__END__
