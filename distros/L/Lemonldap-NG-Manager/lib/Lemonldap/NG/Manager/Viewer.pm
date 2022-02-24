package Lemonldap::NG::Manager::Viewer;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::UserAgent;
use URI::URL;

extends 'Lemonldap::NG::Manager::Conf';

has diffRule => ( is => 'rw', default => sub { 0 } );
has brwRule  => ( is => 'rw', default => sub { 0 } );

our $VERSION = '2.0.14';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'viewer.html';

has ua => ( is => 'rw' );

sub init {
    my ( $self, $conf ) = @_;
    $self->ua( Lemonldap::NG::Common::UserAgent->new($conf) );
    my $hd = "Lemonldap::NG::Handler::PSGI::Main";

    # Parse Diff activation rule
    $conf->{viewerAllowDiff} //= 0;
    $self->logger->debug(
        "Diff activation rule -> " . ( $conf->{viewerAllowDiff} ) );
    my $rule = $hd->buildSub( $hd->substitute( $conf->{viewerAllowDiff} ) );
    unless ($rule) {
        $self->logger->error(
            "Bad Diff activation rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->diffRule($rule);

    # Parse Browser activation rule
    $conf->{viewerAllowBrowser} //= 0;
    $self->logger->debug(
        "Browser activation rule -> " . ( $conf->{viewerAllowBrowser} ) );
    $rule = $hd->buildSub( $hd->substitute( $conf->{viewerAllowBrowser} ) );
    unless ($rule) {
        $self->logger->error(
            "Bad Browser activation rule -> " . $hd->tsv->{jail}->error );
        return 0;
    }
    $self->brwRule($rule);

    my $hiddenKeys  = $conf->{viewerHiddenKeys} || '';
    my @enabledKeys = ();
    my @keys        = qw(virtualHosts samlIDPMetaDataNodes samlSPMetaDataNodes
      applicationList oidcOPMetaDataNodes oidcRPMetaDataNodes
      casSrvMetaDataNodes casAppMetaDataNodes sfExtra
      authChoiceModules grantSessionRules combModules
      openIdIDPList);

    foreach (@keys) {

        # Ignore hidden ConfTree Primary Keys
        push @enabledKeys, $_
          unless ( $hiddenKeys =~ /\b$_\b/ );
    }

    # Forbid hidden keys
    foreach ( split /[,\s]+/, $hiddenKeys ) {
        $self->addRoute(
            view => { ':cfgNum' => { $_ => 'rejectKey' } },
            ['GET']
        );
    }

    # HTML templates
    $self->addRoute( 'viewer.html', undef, ['GET'] )
      ->addRoute( 'viewDiff.html', undef, ['GET'] )

      # READ
      # Special keys
      ->addRoute(
        view => {
            ':cfgNum' => \@enabledKeys
        },
        ['GET']
      )

      # Difference between confs
      ->addRoute(
        view => { diff => { ':conf1' => { ':conf2' => 'viewDiff' } } } )

      # Other keys
      ->addRoute( view => { ':cfgNum' => { '*' => 'viewKey' } }, ['GET'] );
    return 1;
}

sub getConfByNum {
    my ( $self, $cfgNum, @args ) = @_;
    $self->SUPER::getConfByNum( $cfgNum, @args );
}

sub viewDiff {
    my ( $self, $req, @path ) = @_;

    # Check Diff activation rule
    unless ( $self->diffRule->( $req, $req->{userData} ) ) {
        my $user = $req->{userData}->{_whatToTrace} || 'anonymous';
        $self->userLogger->warn(
            "$user is not authorized to compare configurations");
        return $self->sendJSONresponse( $req, { 'value' => '_Hidden_' } );
    }

    return $self->sendError( $req, 'to many arguments in path info', 400 )
      if (@path);
    my @cfgNum =
      ( scalar( $req->param('conf1') ), scalar( $req->param('conf2') ) );
    my @conf;
    $self->logger->debug(" Loading confs");

    # Load the 2 configurations
    for ( my $i = 0 ; $i < 2 ; $i++ ) {
        if ( %{ $self->currentConf }
            and $cfgNum[$i] == $self->currentConf->{cfgNum} )
        {
            $conf[$i] = $self->currentConf;
        }
        else {
            $conf[$i] = $self->confAcc->getConf(
                { cfgNum => $cfgNum[$i], raw => 1, noCache => 1 } );
            return $self->sendError(
                $req,
"Configuration $cfgNum[$i] not available $Lemonldap::NG::Common::Conf::msg",
                400
            ) unless ( $conf[$i] );
        }
    }
    require Lemonldap::NG::Manager::Conf::Diff;
    my @res =
      $self->Lemonldap::NG::Manager::Conf::Diff::diff( $conf[0], $conf[1] );
    my $hiddenKeys = $self->{viewerHiddenKeys} || '';
    $self->logger->debug("Deleting hidden Conf keys...");
    foreach ( split /\s+/, $hiddenKeys ) {
        $self->logger->debug("-> Delete $_");
        delete $res[0]->{$_};
        delete $res[1]->{$_};
    }
    return $self->sendJSONresponse( $req, [@res] );
}

sub rejectKey {
    my ( $self, $req, @args ) = @_;
    return $self->sendJSONresponse( $req, { 'value' => '_Hidden_' } );
}

sub viewKey {
    my ( $self, $req, @args ) = @_;
    $self->logger->debug("Viewer requested URI -> $req->{env}->{REQUEST_URI}");

    # Check Browser activation rule
    if ( $self->brwRule->( $req, $req->{userData} ) ) {
        $self->logger->debug(" No restriction");
        $self->SUPER::getKey( $req, @args );
    }
    else {
        if ( $req->{env}->{REQUEST_URI} =~ m%/view/(?:latest|\d+/\w+)$% ) {
            $self->logger->debug(" $req->{env}->{REQUEST_URI} -> URI allowed");
            $self->SUPER::getKey( $req, @args );
        }
        else {
            $self->logger->debug(
                " $req->{env}->{REQUEST_URI} -> URI FORBIDDEN");
            my $user = $req->{userData}->{_whatToTrace} || 'anonymous';
            $self->userLogger->warn(
                "$user is not authorized to browse configurations");
            $self->rejectKey( $req, @args );
        }
    }
}

1;
