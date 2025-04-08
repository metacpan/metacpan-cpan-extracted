package Lemonldap::NG::Common::Logger::MessageBroker;

use strict;

our $VERSION = '2.21.0';

sub new {
    my $self = bless {}, shift;
    my ( $conf, %args ) = @_;
    my $show = 1;
    die 'Missing conf->loggerBroker' unless $conf->{loggerBroker};
    $conf->{loggerBroker} =~ s/^::/Lemonldap::NG::Common::MessageBroker::/;
    my $brokerChannel =
      $args{user}
      ? ( $conf->{loggerUserBrokerChannel} || 'llng-userlogs' )
      : ( $conf->{loggerBrokerChannel} || 'llng-logs' );
    my $type = $args{user} ? 'logs' : 'userLogs';
    eval "use $conf->{loggerBroker}";
    die "Unable to load $conf->{loggerBroker}: $@" if $@;
    $self->{broker} = $conf->{loggerBroker}->new( $conf->{loggerBrokerOpts} )
      or die 'Unable to create message broker connector';

    foreach (qw(error warn notice info debug)) {
        if ($show) {
            eval qq'sub $_ {\$_[0]->{broker}->publish("$brokerChannel", {
                type => "$type",
                data => \$_[1],
                time => time,
                level => "$_",
              })}';
            die $@ if ($@);
        }
        else {
            eval qq'sub $_ {1}';
        }
        $show = 0 if ( $conf->{logLevel} eq $_ );
    }
    die "Unknown logLevel $conf->{logLevel}" if $show;
    return $self;
}

1;
