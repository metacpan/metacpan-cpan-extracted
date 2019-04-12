package Lemonldap::NG::Manager::Viewer;

use 5.10.0;
use utf8;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::UserAgent;
use URI::URL;

use feature 'state';

extends 'Lemonldap::NG::Manager::Conf';

our $VERSION = '2.0.3';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'viewer.html';

has ua => ( is => 'rw' );

sub addRoutes {
    my ( $self, $conf ) = @_;
    $self->ua( Lemonldap::NG::Common::UserAgent->new($conf) );

    my $hiddenPK = '';
    $hiddenPK = $self->{viewerHiddenKeys} || $conf->{viewerHiddenKeys};
    my @enabledPK = ();
    my @keys      = qw(virtualHosts samlIDPMetaDataNodes samlSPMetaDataNodes
      applicationList oidcOPMetaDataNodes oidcRPMetaDataNodes
      casSrvMetaDataNodes casAppMetaDataNodes
      authChoiceModules grantSessionRules combModules
      openIdIDPList);

    foreach (@keys) {

        # Ignore hidden ConfTree Primary Keys
        push @enabledPK, $_
          unless ( $hiddenPK =~ /\b$_\b/ );
    }

    # HTML template
    $self->addRoute( 'viewer.html', undef, ['GET'] )

      # READ
      # Special keys
      ->addRoute(
        view => {
            ':cfgNum' => \@enabledPK
        },
        ['GET']
      );

    foreach ( split /\s+/, $hiddenPK ) {
        $self->addRoute(
            view => { ':cfgNum' => { $_ => 'rejectKey' } },
            ['GET']
        );
    }

    # Difference between confs
    if ( $self->{viewerAllowDiff} ) {
        $self->addRoute(
            view => { diff => { ':conf1' => { ':conf2' => 'viewDiff' } } } )
          ->addRoute( 'viewDiff.html', undef, ['GET'] );
    }
    unless ( $self->{viewerAllowBrowser} ) {
        $self->addRoute(
            view => { ':cfgNum' => 'rejectKey' },
            ['GET']
        );
    }

    # Other keys
    else {
        $self->addRoute( view => { ':cfgNum' => { '*' => 'getKey' } }, ['GET'] );
    }
}

sub getConfByNum {
    my ( $self, $cfgNum, @args ) = @_;
    $self->SUPER::getConfByNum( $cfgNum, @args );
}

sub viewDiff {
    my ( $self, $req, @path ) = @_;
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
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse( $req, { 'value' => '_Hidden_' } );
}

1;
