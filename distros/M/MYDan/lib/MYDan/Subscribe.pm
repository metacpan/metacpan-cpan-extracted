package MYDan::Subscribe;
use strict;
use warnings;
use Carp;
use YAML::XS;

use Data::Dumper;
use POSIX;

use MYDan::Util::OptConf;
use MYDan::Subscribe::Conf;
use File::Basename;
use MIME::Base64;
use Time::HiRes qw( gettimeofday );
use MYDan::Notify;

my %o; BEGIN{ %o = MYDan::Util::OptConf->load()->dump('subscribe');};

sub new
{
    my ( $class, %this ) = @_;
    $this{conf} = MYDan::Subscribe::Conf->new( path => "$o{conf}/subscribe" );
    $this{notify} = MYDan::Notify->new();
    bless \%this, ref $class || $class;
}

sub input
{
    my ( $this, $mesg, $name, $attr, $time ) = @_;

    my %param = ( mesg => $mesg, name => $name, attr => $attr, time => $time );
    map{ 
        $param{name} = 'unkown' unless $param{name} && $param{name} =~ /^[a-zA-Z0-9_\-\.]+$/ 
    }qw( name attr );

    $param{time} ||= POSIX::strftime( "%Y-%m-%d_%H:%M:%S", localtime );

    my @s = $this->{conf}->get( map{ $_ => $param{$_} }qw( name attr) );

    my $file = sprintf "$o{logs}/%s", join '.', gettimeofday;
    
    my %send;
    eval{
        YAML::XS::DumpFile $file, \%param;
        map{ $send{$_->[2]} = $_->[3] if ! $send{$_->[2]} || $send{$_->[2]} < $_->[3];}@s;

        $this->{notify}->notify( mesg => \%param, user => \%send );
    };

    warn "Subscribe fail: $@\n" if $@;
    YAML::XS::DumpFile sprintf( "$file.%s", $@ ? 'fail' : 'ok' ), \%send;
}

1;
