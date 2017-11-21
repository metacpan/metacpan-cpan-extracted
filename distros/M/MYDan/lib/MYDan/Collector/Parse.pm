package MYDan::Collector::Parse;

use strict;
use warnings;

use MYDan::Util::Logger qw(debug verbose info warning error);

use POSIX;
use YAML::XS;
use Data::Dumper;
use List::MoreUtils qw(pairwise);

our %MAP =
(
    err           => '_parse_test_err',
    warn          => '_parse_test_warn',
    TEST          => '_parse_test',
    LOAD          => '_parse_pair',
    UPTIME        => '_parse_uptime',
    IO            => '_parse_pair',
    MEM           => '_parse_pair',
    FILE          => '_parse_pair',
    PAGE          => '_parse_pair',
    SWAP          => '_parse_pair',
    SOCK          => '_parse_pair',
    VERSION       => '_parse_pair',
    FILE          => '_parse_pair',
    CPU           => '_parse_pair',       #only get 'all'
    OTHER         => '_parse_pair',       #try parse pair
    IFACE         => '_parse_flatten',
    DF            => '_parse_flatten',
    PROC          => '_parse_flatten',
    BACKUP        => '_parse_flatten',
    INDEXINCSTATS => '_parse_pair',
    PING          => '_parse_pair',
    NGINXSTATUS   => '_parse_pair',
);

sub new
{
    my ($class, $raw, %hash) = splice @_, 0, 2;

    my $msg = ref $raw ? $raw : eval{ YAML::XS::Load $raw};
    $msg = [] unless $msg && ref $msg eq 'ARRAY';
    for(@$msg)
    {
        exists $_->[0] && exists $_->[0]->[0] or next;
        push @{ $hash{ $_->[0]->[0] } }, $_;
    }
    bless \%hash, $class;
}

sub parse_all
{
    my($this, %ret) = shift;
    for(keys %$this)
    {
        my $v = $this->parse($_, @_);
        $ret{$_} = $v if $v;
    }
    %ret;
}

sub _debug { my($this, $key) = @_; $this->{$key} }
sub parse
{
    my($this, $key, %opt) = @_;

    if($MAP{$key})
    {
        $MAP{$key}->( $key eq 'err' || $key eq 'warn' ? $this->{TEST} : $this->{$key} );

    }else{

        warn "parse $key not support";
        print Dumper $this->{$key} if $opt{debug};
        if($opt{force})
        {
            warn "try parse pair";
            $MAP{OTHER}->( $this->{$key} );
        };
    }
}


my %TEST_KEY =
(
   'cond'    =>  0 ,
   'stat'    =>  10,
   'group'   =>  11,
   'warning' =>  12,
   'info'    =>  13,
);
sub _parse_test
{
    my ($msg, %all) = shift;

    map
    {
        my $msg = $_;
        my %hash = map{ $_ => $msg->[ $TEST_KEY{$_} ] }keys %TEST_KEY;
        my ($cond, $stat, $group, $info) = map{ $msg->[ $TEST_KEY{$_} ] }qw(cond stat group info);
        push @{ $all{ $group }->{ $stat } }, $stat eq 'err' ? sprintf("%s (%s)", $cond, $info) : $cond;
    }
    grep{$_ && $_->[0] ne 'TEST'}map{@$_}@$msg;
    wantarray ? %all : \%all;
}

sub _parse_test_err{  _parse_test_stat(shift, 'err')  }
sub _parse_test_warn{ _parse_test_stat(shift, 'warn') }
sub _parse_test_stat
{
    my ($msg, $stat, %err) = splice @_, 0, 2;

    map
    {
        my $msg = $_;
        my ($cond, $group, $info, $warning) = map{ $msg->[ $TEST_KEY{$_} ] }qw(cond group info warning);
        push @{ $err{$group} }, sprintf "%s (%s)", $cond, $stat eq 'err' ? $info : $warning;
    }
    grep{$_->[ $TEST_KEY{'stat'} ] eq $stat}
    grep{$_ && $_->[0] ne 'TEST'}map{@$_}@$msg;

    wantarray ? %err : \%err;
}

sub _parse_uptime
{
    my ($msg, %time) = shift;
    my @msg = map{ @$_ }@$msg;
    for(0 .. @{$msg[0]}-1)
    {
        my($k, $v) = ($msg[0]->[$_], $msg[1]->[$_]);
        $time{$k} = $v;
    }
    delete $time{UPTIME};
    $time{human} = POSIX::strftime( "%Y-%m-%d %H:%M", localtime( $time{'time'} || time ) );
    wantarray ? %time : \%time;
}

sub _parse_flatten
{
    my ($msg, %ret, @ret) = shift;
    for(@$msg)
    {
        my(@colum, @head) = @$_;
        @head = @{ shift @colum }; shift @head;
        for(@colum)
        {
            my($face, @value) = @$_;
            pairwise{ $ret{$face}->{ $a } = $b }@head, @value;
        }
    }
    $ret{$_}->{class} = $_ for keys %ret;
    wantarray ? values %ret : [values %ret];
}
sub _parse_pair
{
    my ($msg, %ret) = shift;
    my (@msg, @ret) = grep{scalar @{$_->[1]} > 1}@$msg;

    @ret = @{ shift @msg };

    for(1 .. @{$ret[0]}-1)
    {
        my($k, $v) = ($ret[0]->[$_], $ret[1]->[$_]);
        $ret{$k} = $v;
    }
    wantarray ? %ret : \%ret;

}
1;
