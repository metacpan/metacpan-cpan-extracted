package Lemonldap::NG::Common::Cli;

use strict;
use Mouse;
use Lemonldap::NG::Common::Conf;
use Lemonldap::NG::Common::EmailTransport;

our $VERSION = '2.0.8';

extends 'Lemonldap::NG::Common::PSGI::Cli::Lib';

has confAccess => (
    is      => 'rw',
    builder => sub {
        my $res = Lemonldap::NG::Common::Conf->new( { (
                    ref $_[0] && $_[0]->{iniFile}
                    ? ( confFile => $_[0]->{iniFile} )
                    : ()
                )
            }
        );
        die $Lemonldap::NG::Common::Conf::msg unless ($res);
        return $res;
    },
);

has cfgNum => (
    is  => 'rw',
    isa => 'Int',
);

sub info {
    my ($self) = @_;
    my $conf =
      $self->confAccess->getConf( { cfgNum => $self->cfgNum, raw => 1 } )
      or die $Lemonldap::NG::Common::Conf::msg;
    $conf->{cfgAuthorIP} ||= "No IP provided";
    $conf->{cfgDate}     ||= 0;
    $conf->{cfgLog}      ||= "No log provided";
    print qq{
Num      : $conf->{cfgNum}
Author   : $conf->{cfgAuthor}
Author IP: $conf->{cfgAuthorIP}
Date     : } . localtime( $conf->{cfgDate} ) . qq{
Version  : $conf->{cfgVersion}
Log      : $conf->{cfgLog}
};
}

sub updateCache {
    my $self = shift;
    my $conf = $self->confAccess->getConf( { noCache => 2 } );
    die "Must not be launched as root" unless ($>);
    print STDERR
      qq{Cache updated to configuration $conf->{cfgNum} for user $>\n};
}

sub testEmail {
    my $self = shift;
    my $dest = shift;
    die "Must specify destination" unless ($dest);
    my $conf = $self->confAccess->getConf();
    eval {
        Lemonldap::NG::Common::EmailTransport::sendTestMail( $conf, $dest );
    };
    my $error = $@;
    if ($error) {
        die $error;
    }
    else {
        print STDERR "Test email successfully sent to $dest\n";
    }
}

sub run {
    my $self = shift;

    # Options simply call corresponding accessor
    my $args = {};
    while ( $_[0] =~ s/^--?// ) {
        my $k = shift;
        my $v = shift;
        if ( ref $self ) {
            eval { $self->$k($v) };
            if ($@) {
                die "Unknown option -$k or bad value ($@)";
            }
        }
        else {
            $args->{$k} = $v;
        }
    }
    unless ( ref $self ) {
        $self = $self->new($args);
    }
    unless (@_) {
        die 'nothing to do, aborting';
    }
    $self->confAccess()->lastCfg() unless ( $self->cfgNum );
    my $action = shift;
    unless ( $action =~ /^(?:info|update-cache|test-email)$/ ) {
        die "unknown action $action. Only info or update are accepted";
    }
    $action =~ s/\-([a-z])/uc($1)/e;
    $self->$action(@_);
}

1;
