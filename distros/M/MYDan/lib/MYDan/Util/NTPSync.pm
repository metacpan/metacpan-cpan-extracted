package MYDan::Util::NTPSync;

=head1 NAME

MYDan::Util::NTPSync

=head1 SYNOPSIS

 use MYDan::Util::NTPSync;

=cut

use strict;
use warnings;

use YAML::XS;
use Sys::Hostname;
use Carp;
use MYDan::Util::Alias;

our $NTPDATE;

BEGIN{
    my $alias = MYDan::Util::Alias->new();
    $NTPDATE = $alias->alias( 'ntpdate' ) || 'ntpdate';
};

sub new
{
    my ( $class, %self ) = @_;
    confess "no ntpsync conf" unless exists $self{conf};
    my $conf = eval{ YAML::XS::LoadFile( $self{conf} ) };
    confess "$self{conf}: $@\n" if $@;
    confess "conf is not hash"  if ref $conf ne 'HASH';

    my $hostname = Sys::Hostname::hostname;
    map { push @{ $self{ntp} }, @{ $conf->{$_} } if $hostname =~ /$_/ }
        sort { length($b) <=> length($a) } keys %$conf;
    confess "no match ntpserver" unless exists $self{ntp};

    bless \%self, ref $class || $class;
}

sub run
{
    my $self = shift;

    my ( @ntp, $ok ) = @{ $self->{ntp} };
    do
    {
        system '/etc/init.d/ntpd stop > /dev/null 2>&1';

        for my $ntp (@ntp)
        {
            map {
                unless ( system "$NTPDATE $ntp" ) { $ok = 1; last; }
            } 1 .. $self->{try};
            warn "Failed to sync with $ntp\n";
        }

        warn sprintf "sync %s.\n", $ok ? 'ok' : 'fail';
    } while $self->{daemon} && sleep $self->{interval};

}

1;
