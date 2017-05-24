# This module implements all the methods that responds to '/confs/*' requests
# It contains 4 sections:
#  - initialization methods
#  - private methods (to access required conf)
#  - display methods
#  - upload method
package Lemonldap::NG::Manager::Conf;

use 5.10.0;
use utf8;
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Manager::Constants;
use Crypt::OpenSSL::RSA;
use Convert::PEM;
use URI::URL;

use feature 'state';

extends 'Lemonldap::NG::Manager::Lib';

our $VERSION = '1.9.7';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'manager.html';

sub addRoutes {
    my $self = shift;

    # HTML template
    $self->addRoute( 'manager.html', undef, ['GET'] )

      # READ
      # Special keys
      ->addRoute(
        confs => {
            ':cfgNum' => [
                qw(virtualHosts samlIDPMetaDataNodes samlSPMetaDataNodes
                  applicationList oidcOPMetaDataNodes oidcRPMetaDataNodes
                  authChoiceModules grantSessionRules)
            ]
        },
        ['GET']
      )

      # Other keys
      ->addRoute( confs => { ':cfgNum' => { '*' => 'getKey' } }, ['GET'] )

      # New key and conf save
      ->addRoute(
        confs =>
          { newRSAKey => 'newRSAKey', raw => 'newRawConf', '*' => 'newConf' },
        ['POST']
      )

      # Url loader
      ->addRoute( 'prx', undef, ['POST'] );
}

#######################
# II. PRIVATE METHODS #
#######################

## @method scalar getConfKey($req, $key)
# Return key value
#
# Return the value of $key key in current configuration. If cfgNum is set to
# `latest`, get before last configuration number.
#
# Errors: set an error in $req->error and return undef if:
#  * query does not have a cfgNum parameter (set by Common/PSGI/Router.pm)
#  * cfgNum is not a number
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param $key Key name
#@return keyvalue (string, int or hashref)
sub getConfKey {
    my ( $self, $req, $key, @args ) = @_;
    state $confAcc ||= $self->confAcc;
    $self->lmLog( "Search for $key in conf", 'debug' );

    # Verify that cfgNum has been asked
    unless ( defined $req->params('cfgNum') ) {
        $req->error("Missing configuration number");
        return undef;
    }
    $self->lmLog( "Cfgnum set to " . $req->params('cfgNum'), 'debug' );

    # when 'latest' => replace by last cfgNum
    if ( $req->params('cfgNum') eq 'latest' ) {
        my $tmp = $self->confAcc->lastCfg;
        $req->params( 'cfgNum', $tmp );
        if ($Lemonldap::NG::Common::Conf::msg) {
            $req->error($Lemonldap::NG::Common::Conf::msg);
            return undef;
        }
    }
    elsif ( $req->params('cfgNum') !~ /^\d+$/ ) {
        $req->error("cfgNum must be a number");
        return undef;
    }
    unless ( defined $self->getConfByNum( $req->params('cfgNum'), @args ) ) {
        $req->error( "Configuration "
              . $req->params('cfgNum')
              . " is not available ("
              . $Lemonldap::NG::Common::Conf::msg
              . ')' );
        return undef;
    }

    # TODO: insert default values
    # Set an error if key is not defined
    return $self->currentConf->{$key};
}

sub getConfByNum {
    my ( $self, $cfgNum, @args ) = @_;
    unless ( %{ $self->currentConf }
        and $cfgNum == $self->currentConf->{cfgNum} )
    {
        my $tmp;
        if ( $cfgNum == 0 ) {
            require Lemonldap::NG::Manager::Conf::Zero;
            $tmp = Lemonldap::NG::Manager::Conf::Zero::zeroConf();
        }
        else {
            $tmp =
              $self->confAcc->getConf(
                { cfgNum => $cfgNum, raw => 1, noCache => 1, @args } );
            return undef unless ( $tmp and ref($tmp) and %$tmp );
        }
        $self->currentConf($tmp);
    }
    return $cfgNum;
}

########################
# III. Display methods #
########################

# Values are send depending of the /path/info/. For example,
# /confs/1/portal to get portal value.

# This section contains several methods:
#  - complex nodes:
#    * complexNodesRoot() call for root queries (no subkeys) to display the list
#    * virtualHosts()
#    * _samlMetaDataNodes() is called by saml(IDP|RP)MetaDataNode
#    * _oidcMetaDataNodes() is called by oidc(OP|RP)MetaDataNodes
#  - other special nodes:
#    * authChoiceModules()
#    * grantSessionRules()
#    * openIdIDPList() (old OpenID)
#    * applicationList()
#  - root:
#    root query (/confs/latest for example) is redirected to metadatas()
#  - other requests:
#    they are managed by getKey()
#  - newRSAKey() returns a new RSA key pair if /confs/newRSAKey is called in a
#    POST request
#  - prx() load a request and return the content (for SAML/OIDC metadatas)

# 31 - Complex subnodes
#      ----------------

## @method PSGI-JSON-response complexNodesRoot($req, $query, $tpl)
# Respond to root requests for virtual hosts and SAMLmetadatas
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param $query Configuration root key
#@param $tpl Javascript template to use (see JS/JSON generator script)
#@return PSGI JSON response
sub complexNodesRoot {
    my ( $self, $req, $query, $tpl ) = @_;
    $self->lmLog( "Query for $query template keys", 'debug' );

    my $tmp = $self->getConfKey( $req, $query );
    return $self->sendError( $req, undef, 400 ) if ( $req->error );

    my @res;
    if ( ref($tmp) ) {
        foreach my $f ( sort keys %$tmp ) {
            push @res,
              {
                id       => "${tpl}s/$f",
                title    => $f,
                type     => $tpl,
                template => $tpl
              };
        }
    }
    return $self->sendJSONresponse( $req, \@res );
}

# 311 - Virtual hosts
#       -------------

## @method PSGI-JSON-response virtualHosts($req, @path)
# Respond to virtualhosts sub requests
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `virtualhosts`
#@return PSGI JSON response
sub virtualHosts {
    my ( $self, $req, @path ) = @_;

    return $self->complexNodesRoot( $req, 'locationRules', 'virtualHost' )
      unless (@path);

    my $vh = shift @path;
    my $query;
    unless ( $query = shift @path ) {
        return $self->sendError( $req,
            'Bad request: virtualHost query must ask for a key', 400 );
    }

    # Send setDefault for new vhosts
    return $self->sendError( $req, 'setDefault', 200 ) if ( $vh =~ /^new__/ );

    # Reject unknown vhosts
    return $self->sendError( $req, "Unknown virtualhost ($vh)", 400 )
      unless ( defined $self->getConfKey( $req, 'locationRules' )->{$vh} );

    if ( $query =~ /^(?:(?:exportedHeader|locationRule)s|post)$/ ) {
        my ( $id, $resp ) = ( 1, [] );
        my $vhk = eval { $self->getConfKey( $req, $query )->{$vh} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        $self->lmLog( "Query for $vh/$query keys", 'debug' );

        # Keys are ordered except 'default' which must be at the end
        foreach my $r (
            sort {
                $query eq 'locationRules'
                  ? (
                    $a eq 'default'
                    ? 1
                    : ( $b eq 'default' ? -1 : $a cmp $b )
                  )
                  : $a cmp $b
            } keys %$vhk
          )
        {
            my $res = {
                id    => "virtualHosts/$vh/$query/" . $id++,
                title => $r,
                data  => $vhk->{$r},
                type  => 'keyText',
            };

            # If rule contains a comment, split it
            if ( $query eq 'locationRules' ) {
                $res->{comment} = '';
                if ( $r =~ s/\(\?#(.*?)\)// ) {
                    $res->{title} = $res->{comment} = $1;
                }
                $res->{re}   = $r;
                $res->{type} = 'rule';
            }
            elsif ( $query eq 'post' ) {
                $res->{data} = $vhk->{$r};
                $res->{type} = 'post';
            }
            push @$resp, $res;
        }
        return $self->sendJSONresponse( $req, $resp );
    }
    elsif ( $query =~ /^vhost(?:(?:Aliase|Http)s|Maintenance|Port)$/ ) {
        $self->lmLog( "Query for $vh/$query key", 'debug' );

        # TODO: verify how this is done actually
        my $k1 = $self->getConfKey( $req, 'vhostOptions' );
        return $self->sendError( $req, undef, 400 ) if ( $req->error );

        # Default values are set by JS
        my $res = eval { $k1->{$vh}->{$query} } // undef;
        return $self->sendJSONresponse( $req, { value => $res } );
    }
    else {
        return $self->sendError( $req, "Unknown vhost subkey ($query)", 400 );
    }
}

# 312 - SAML
#       ----

## @method PSGI-JSON-response _samlMetaDataNode($type, $req, @path)
# Respond to SAML metadata subnodes
#
#@param $type `SP` or `IDP`
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `saml{IDP|SP}MetaDataNode`
#@return PSGI JSON response
sub _samlMetaDataNodes {
    my ( $self, $type, $req, @path ) = @_;

    return $self->complexNodesRoot( $req, "saml${type}MetaDataXML",
        "saml${type}MetaDataNode" )
      unless (@path);
    my $partner = shift @path;
    my $query   = shift @path;
    unless ($query) {
        return $self->sendError( $req,
            "Bad request: saml${type}MetaDataNode query must ask for a key",
            400 );
    }

    # setDefault response for new partners
    return $self->sendError( $req, 'setDefault', 200 )
      if ( $partner =~ /^new__/ );

    # Reject unknown partners
    return $self->sendError( $req, "Unknown SAML partner ($partner)", 400 )
      unless (
        defined eval {
            $self->getConfKey( $req, "saml${type}MetaDataXML" )->{$partner};
        }
      );

    my ( $id, $resp ) = ( 1, [] );

    # Return all exported attributes if asked
    if ( $query =~ /^saml${type}MetaDataExportedAttributes$/ ) {
        my $pk =
          eval { $self->getConfKey( $req, $query )->{$partner} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        foreach my $h ( sort keys %$pk ) {
            push @$resp,
              {
                id    => "saml${type}MetaDataNodes/$partner/$query/" . $id++,
                title => $h,
                data  => [ split /;/, $pk->{$h} ],
                type  => 'samlAttribute',
              };
        }
        return $self->sendJSONresponse( $req, $resp );
    }

    # Simple root keys
    elsif ( $query =~ /^saml${type}MetaDataXML$/ ) {
        my $value =
          eval { $self->getConfKey( $req, $query )->{$partner}->{$query}; }
          // undef;
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        return $self->sendJSONresponse( $req, { value => $value } );
    }

    # These regexps are generated by jsongenerator.pl and stored in
    # Lemonldap::NG::Manager::Constants
    elsif (
        $query =~ {
            IDP => qr/^$samlIDPMetaDataNodeKeys$/o,
            SP  => qr/^$samlSPMetaDataNodeKeys$/o
        }->{$type}
      )
    {
        my $value = eval {
            $self->getConfKey( $req, "saml${type}MetaDataOptions" )->{$partner}
              ->{$query};
        } // undef;

        # Note that types "samlService" and "samlAssertion" will be splitted by
        # manager.js in an array
        return $self->sendJSONresponse( $req, { value => $value } );
    }
    else {
        return $self->sendError( $req,
            "Bad key for saml${type}MetaDataNode ($query)", 400 );
    }
}

## @method PSGI-JSON-response samlIDPMetaDataNode($req, @path)
# Launch _samlMetaDataNode('IDP', @_)
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `samlIDPMetaDataNode`
#@return PSGI JSON response
sub samlIDPMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_samlMetaDataNodes( 'IDP', $req, @path );
}

## @method PSGI-JSON-response samlSPMetaDataNode($req, @path)
# Launch _samlMetaDataNode('SP', @_)
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `samlSPMetaDataNode`
#@return PSGI JSON response
sub samlSPMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_samlMetaDataNodes( 'SP', $req, @path );
}

# 313 - OpenID-Connect
#       --------------

## @method PSGI-JSON-response _oidcMetaDataNodes($type, $req, @path)
# Respond to OpenID-Connect metadata subnodes
#
#@param $type `OP` or `RP`
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `oidc{OP|RP}MetaDataNode`
#@return PSGI JSON response
sub _oidcMetaDataNodes {
    my ( $self, $type, $req, @path ) = @_;

    my $refKey =
      ( $type eq 'RP' ? 'oidcRPMetaDataOptions' : 'oidcOPMetaDataJSON' );
    return $self->complexNodesRoot( $req, $refKey, "oidc${type}MetaDataNode" )
      unless (@path);

    my $partner = shift @path;
    my $query   = shift @path;
    unless ($query) {
        return $self->sendError( $req,
            "Bad request: oidc${type}MetaDataNode query must ask for a key",
            400 );
    }

    # setDefault response for new partners
    return $self->sendError( $req, 'setDefault', 200 )
      if ( $partner =~ /^new__/ );

    # Reject unknown partners
    return $self->sendError( $req,
        "Unknown OpenID-Connect partner ($partner)", 400 )
      unless ( defined eval { $self->getConfKey( $req, $refKey )->{$partner}; }
      );

    my ( $id, $resp ) = ( 1, [] );

    # Return all exported attributes if asked
    if ( $query =~
        /^(?:oidc${type}MetaDataExportedVars|oidcRPMetaDataOptionsExtraClaims)$/
      )
    {
        my $pk = eval { $self->getConfKey( $req, $query )->{$partner} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        foreach my $h ( sort keys %$pk ) {
            push @$resp,
              {
                id    => "oidc${type}MetaDataNodes/$partner/$query/" . $id++,
                title => $h,
                data  => $pk->{$h},
                type  => 'keyText',
              };
        }
        return $self->sendJSONresponse( $req, $resp );
    }

    # Long text types (OP only)
    elsif ( $query =~ /^oidcOPMetaData(?:JSON|JWKS)$/ ) {
        my $value =
          eval { $self->getConfKey( $req, $query )->{$partner}; } // undef;
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        return $self->sendJSONresponse( $req, { value => $value } );
    }

    # Options
    elsif (
        $query =~ {
            OP => qr/^$oidcOPMetaDataNodeKeys$/o,
            RP => qr/^$oidcRPMetaDataNodeKeys$/o
        }->{$type}
      )
    {
        my $value = eval {
            $self->getConfKey( $req, "oidc${type}MetaDataOptions" )->{$partner}
              ->{$query};
        } // undef;
        return $self->sendJSONresponse( $req, { value => $value } );
    }
    else {
        return $self->sendError( $req,
            "Bad key for oidc${type}MetaDataNode ($query)", 400 );
    }
}

## @method PSGI-JSON-response oidcOPMetaDataNodes($req, @path)
# Launch _oidcMetaDataNodes('SP', @_)
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `oidcOPMetaDataNode`
#@return PSGI JSON response
sub oidcOPMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_oidcMetaDataNodes( 'OP', $req, @path );
}

## @method PSGI-JSON-response oidcRPMetaDataNodes($req, @path)
# Launch _oidcMetaDataNodes('SP', @_)
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @path words in path after `oidcRPMetaDataNode`
#@return PSGI JSON response
sub oidcRPMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_oidcMetaDataNodes( 'RP', $req, @path );
}

# 32 - Other special nodes
#      -------------------

# 321 - Choice authentication

## @method PSGI-JSON-response authChoiceModules($req,$key)
# Returns authChoiceModules keys splitted in arrays
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param key optional subkey
#@return PSGI JSON response
sub authChoiceModules {
    my ( $self, $req, $key ) = @_;
    my $value = $self->getConfKey( $req, 'authChoiceModules' );
    unless ($key) {
        my @res;
        foreach my $k ( sort keys %$value ) {
            push @res,
              {
                id    => "authChoiceModules/$k",
                title => "$k",
                data  => [ split /;/, $value->{$k} ],
                type  => 'authChoice'
              };
        }
        return $self->sendJSONresponse( $req, \@res );
    }
    else {
        my $r = $value->{$key} ? [ split( /[;\|]/, $value->{$key} ) ] : [];
        return $self->sendJSONresponse( $req, { value => $r } );
    }
}

# 322 - Rules to grant sessions

## @method PSGI-JSON-response grantSessionRules($req)
# Split grantSessionRules key=>value into 3 elements
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub grantSessionRules {
    my ( $self, $req, $key ) = @_;
    return $self->sendError( 'Subkeys forbidden for grantSessionRules', 400 )
      if ($key);
    my $value = $self->getConfKey( $req, 'grantSessionRules' );
    my @res;

    sub _sort {
        my $A = ( $a =~ /^.*?##(.*)$/ )[0];
        my $B = ( $b =~ /^.*?##(.*)$/ )[0];
        return !$A ? 1 : !$B ? -1 : $A cmp $B;
    }
    my $id = 0;
    foreach my $k ( sort _sort keys %$value ) {
        my $r = $k;
        my $c = ( $r =~ s/^(.*)?##(.*)$/$1/ ? $2 : '' );
        $id++;
        push @res,
          {
            id      => "grantSessionRules/$id",
            title   => $c || $r,
            re      => $r,
            comment => $c,
            data    => $value->{$k},
            type    => 'grant'
          };
    }
    return $self->sendJSONresponse( $req, \@res );
}

# 323 - (old)OpenID IDP black/white list

##method PSGI-JSON-response openIdIDPList($req)
# Split openIdIDPList parameter into 2 elements
sub openIdIDPList {
    my ( $self, $req, $key ) = @_;
    return $self->sendError( 'Subkeys forbidden for openIdIDPList', 400 )
      if ($key);
    my $value = $self->getConfKey( $req, 'openIdIDPList' );
    $value //= '0;';
    my ( $type, $v ) = split /;/, $value;
    $v //= '';
    return $self->sendJSONresponse( $req, { value => [ $type, $v ] } );
}

# 324 - Application for menu
#       --------------------

## @method PSGI-JSON-response applicationList($req, @other)
# Return the full menu tree
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param @other words in path after `applicationList`
#@return PSGI JSON response
sub applicationList {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req,
        'There is no subkey for applicationList', 400 )
      if (@other);
    my $apps = $self->getConfKey( $req, 'applicationList' );
    return $self->sendError( $req, undef, 400 ) if ( $req->error );
    $apps = {} unless ( ref($apps) eq 'HASH' );
    my $json = $self->_scanCatsAndApps( $apps, 'applicationList' );
    return $self->sendJSONresponse( $req, $json );
}

## @method arrayRef _scanCatsAndApps($apps)
# Recursive method used to build categories & applications menu
#
#@param $apps HashRef pointing to a subnode of catAndApps conf tree
#@return arrayRef
sub _scanCatsAndApps {
    my ( $self, $apps, $baseId ) = @_;
    my @res;

    foreach my $cat ( grep { not /^(?:catname|type)$/ } sort keys %$apps ) {
        my $item = { id => "$baseId/$cat" };
        if ( $apps->{$cat}->{type} eq 'category' ) {
            $item->{title} = $apps->{$cat}->{catname};
            $item->{type}  = 'menuCat';
            $item->{nodes} =
              $self->_scanCatsAndApps( $apps->{$cat}, "$baseId/$cat" );
        }
        else {
            $item->{title} = $apps->{$cat}->{options}->{name};
            $item->{type} = $apps->{$cat}->{type} = 'menuApp';
            foreach my $o (
                grep { not /^name$/ }
                keys %{ $apps->{$cat}->{options} }
              )
            {
                $item->{data}->{$o} = $apps->{$cat}->{options}->{$o};
            }
        }
        push @res, $item;
    }
    return \@res;
}

# 33 - Root queries
#      -----------

## @method PSGI-JSON-response metadatas($req)
# Respond to `/conf/:cfgNum` requests by sending configuration metadatas
#
# NB: if `full=1` is set in the query, configuration is returned directly in
#     JSON
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub metadatas {
    my ( $self, $req ) = @_;
    if ( $req->params('full') and $req->params('full') !~ $no ) {
        my $c = $self->getConfKey( $req, 'cfgNum' );
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        $self->userNotice( 'User '
              . $self->userId($req)
              . ' ask for full configuration '
              . $c );
        return $self->sendJSONresponse(
            $req,
            $self->currentConf,
            forceJSON => 1,
            headers   => [
                'Content-Disposition' => "Attachment; filename=lmConf-$c.json"
            ],
        );
    }
    else {
        my $res = {};
        $res->{cfgNum} = $self->getConfKey( $req, 'cfgNum' );
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        return $self->sendError( $req, "Configuration without cfgNum", 500 )
          unless ( defined $res->{cfgNum} );
        foreach my $key (qw(cfgAuthor cfgDate cfgAuthorIP cfgLog)) {
            $res->{$key} = $self->getConfKey( $req, $key );
        }

        # Find next and previous conf
        my @a  = $self->confAcc->available;
        my $id = -1;
        my ($ind) = map { $id++; $_ == $res->{cfgNum} ? ($id) : () } @a;
        if ($ind)         { $res->{prev} = $a[ $ind - 1 ]; }
        if ( $ind and $ind < $#a ) { $res->{next} = $a[ $ind + 1 ]; }
        $self->userNotice( 'User '
              . $self->userId($req)
              . ' ask for configuration metadatas ('
              . $res->{cfgNum}
              . ')' );
        return $self->sendJSONresponse( $req, $res );
    }
}

# 34 - Other values
#      ------------

## @method PSGI-JSON-response getKey($req, $key, $subkey)
# Return the value of a root key of current configuration
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param $key Name of key requested
#@param $subkey Subkey for hash values
#@return PSGI JSON response
sub getKey {
    my ( $self, $req, $key, $subkey ) = @_;
    unless ($key) {
        return $self->metadatas($req);
    }
    $self->userInfo( 'User ' . $self->userId($req) . " asks for key $key" );
    my $value = $self->getConfKey( $req, $key );
    return $self->sendError( $req, undef, 400 ) if ( $req->error );

    # When "hash"
    if ( $key =~ qr/^$simpleHashKeys$/o ) {
        return $self->sendError( $req, 'setDefault', 200 )
          unless defined($value);

        # If a hash key is asked return its value
        if ($subkey) {
            return $self->sendJSONresponse( $req,
                { value => $value->{$subkey} // undef, } );
        }

        # else return the list of keys
        my @res;
        foreach my $k ( sort keys %$value ) {
            push @res,
              {
                id    => "$key/$k",
                title => "$k",
                data  => $value->{$k},
                type  => 'keyText'
              };
        }
        return $self->sendJSONresponse( $req, \@res );
    }
    elsif ( $key =~ qr/^$doubleHashKeys$/o ) {
        my @res;
        $value ||= {};
        foreach my $host ( sort keys %$value ) {
            my @tmp;
            foreach my $k ( sort keys %{ $value->{$host} } ) {
                push @tmp, { k => $k, v => $value->{$host}->{$k} };
            }
            push @res, { k => $host, h => \@tmp };
        }
        return $self->sendJSONresponse( $req, { value => \@res } );
    }

    # When scalar
    return $self->sendError( $req, "Key $key is not a hash", 400 )
      if ($subkey);
    return $self->sendError( $req, 'setDefault', 200 ) unless defined($value);
    return $self->sendJSONresponse( $req, { value => $value } );

    # TODO authParam key
}

# 35 - New RSA key pair on demand
#      --------------------------

##@method public PSGI-JSON-response newRSAKey($req)
# Return a hashref containing private and public keys
# The posted datas must contain a JSON object containing
# {"password":"newpassword"}
#
#@param $req Lemonldap::NG::Common::PSGI::Request object
#@return PSGI JSON response
sub newRSAKey {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newRSAKey"', 400 )
      if (@others);
    my $query = $req->jsonBodyToObj;
    my $rsa   = Crypt::OpenSSL::RSA->generate_key(2048);
    my $keys  = {
        'private' => $rsa->get_private_key_string(),
        'public'  => $rsa->get_public_key_x509_string(),
    };
    if ( $query->{password} ) {
        my $pem = Convert::PEM->new(
            Name => 'RSA PRIVATE KEY',
            ASN  => q(
                RSAPrivateKey SEQUENCE {
                    version INTEGER,
                    n INTEGER,
                    e INTEGER,
                    d INTEGER,
                    p INTEGER,
                    q INTEGER,
                    dp INTEGER,
                    dq INTEGER,
                    iqmp INTEGER
    }
               )
        );
        $keys->{private} = $pem->encode(
            Content  => $pem->decode( Content => $keys->{private} ),
            Password => $query->{password},
        );
    }
    return $self->sendJSONresponse( $req, $keys );
}

# 36 - URL File loader
#      ---------------

##@method public PSGI-JSON-response prx()
# Load file using posted URL and return its content
#
#@return PSGI JSON response
sub prx {
    my ( $self, $req, @others ) = @_;
    return $self->sendError( $req, 'There is no subkey for "prx"', 400 )
      if (@others);
    my $query = $req->jsonBodyToObj;
    return $self->sendError( $req, 'Missing parameter', 400 )
      unless ( $query->{url} );
    return $self->sendError( $req, 'Bad parameter', 400 )
      unless ( $query->{url} =~ m#^(?:f|ht)tps?://\w# );
    require LWP::UserAgent;
    my $ua = new LWP::UserAgent();
    $ua->timeout(10);

    my $response = $ua->get( $query->{url} );
    unless ( $response->code == 200 ) {
        return $self->sendError( $req,
            $response->code . " (" . $response->message . ")", 400 );
    }
    unless ( $response->header('Content-Type') =~
        m#^(?:application/json|(?:application|text)/.*xml).*$# )
    {
        return $self->sendError( $req,
            'Content refused for security reason (neither XML or JSON)', 400 );
    }
    return $self->sendJSONresponse( $req, { content => $response->content } );
}

######################
# IV. Upload methods #
######################

# In this section, 3 methods:
#  - newConf()
#  - newRawConf(): restore a saved conf
#  - applyConf(): called by the 2 previous to prevent other servers that a new
#                 configuration is available

## @method PSGI-JSON-response newConf($req)
# Call Lemonldap::NG::Manager::Conf::Parser to parse new configuration and store
# it
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub newConf {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newConf"', 400 )
      if (@other);

    # Body must be json
    my $new = $req->jsonBodyToObj;
    unless ( defined($new) ) {
        return $self->sendError( $req, undef, 400 );
    }

    # Verify that cfgNum has been asked
    unless ( defined $req->params('cfgNum') ) {
        return $self->sendError( $req, "Missing configuration number", 400 );
    }

    # Set current conf to cfgNum
    unless ( defined $self->getConfByNum( $req->params('cfgNum') ) ) {
        return $self->sendError(
            $req,
            "Configuration "
              . $req->params('cfgNum')
              . " not available "
              . $Lemonldap::NG::Common::Conf::msg,
            400
        );
    }

    # Parse new conf
    require Lemonldap::NG::Manager::Conf::Parser;
    my $parser = Lemonldap::NG::Manager::Conf::Parser->new(
        { tree => $new, refConf => $self->currentConf, req => $req } );

    # If ref conf isn't last conf, consider conf changed
    my $cfgNum = $self->confAcc->lastCfg;
    unless ( defined $cfgNum ) {
        $req->error($Lemonldap::NG::Common::Conf::msg);
    }
    return $self->sendError( $req, undef, 400 ) if ( $req->error );

    if ( $cfgNum ne $req->params('cfgNum') ) { $parser->confChanged(1); }

    my $res = { result => $parser->check };

    # "message" fields: note that words enclosed by "__" (__word__) will be
    # translated
    $res->{message} = $parser->{message};
    foreach my $t (qw(errors warnings changes)) {
        $res->{details}->{ '__' . $t . '__' } = $parser->$t
          if ( @{ $parser->$t } );
    }
    if ( $res->{result} ) {
        if ( $self->{demoMode} ) {
            $res->{message} = '__demoModeOn__';
        }
        else {
            my %args;
            $args{force} = 1 if ( $req->params('force') );
            my $s = $self->confAcc->saveConf( $parser->newConf, %args );
            if ( $s > 0 ) {
                $self->userNotice(
                    'User ' . $self->userId($req) . " has stored conf $s" );
                $res->{result} = 1;
                $res->{cfgNum} = $s;
                if ( my $status = $self->applyConf( $parser->newConf ) ) {
                    push @{ $res->{details}->{__applyResult__} },
                      { message => "$_: $status->{$_}" }
                      foreach ( keys %$status );
                }
            }
            else {
                $self->userNotice(
                    'Saving attempt rejected, asking for confirmation to '
                      . $self->userId($req) );
                $res->{result} = 0;
                if ( $s == CONFIG_WAS_CHANGED ) {
                    $res->{needConfirm} = 1;
                    $res->{message} .= '__needConfirmation__';
                }
                else {
                    $res->{message} = $Lemonldap::NG::Common::Conf::msg;
                }
            }
        }
    }
    return $self->sendJSONresponse( $req, $res );
}

## @method PSGI-JSON-response newRawConf($req)
# Store directly raw configuration
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub newRawConf {
    my ( $self, $req, @other ) = @_;
    return $self->sendError( $req, 'There is no subkey for "newConf"', 400 )
      if (@other);

    # Body must be json
    my $new = $req->jsonBodyToObj;
    unless ( defined($new) ) {
        return $self->sendError( $req, undef, 400 );
    }

    my $res = {};
    if ( $self->{demoMode} ) {
        $res->{message} = '__demoModeOn__';
    }
    else {
        # When uploading a new conf, always force it since cfgNum has a few
        # chances to be equal to last config cfgNum
        my $s = $self->confAcc->saveConf( $new, force => 1 );
        if ( $s > 0 ) {
            $self->userNotice(
                'User ' . $self->userId($req) . " has stored (raw) conf $s" );
            $res->{result} = 1;
            $res->{cfgNum} = $s;
        }
        else {
            $self->userNotice(
                'Raw saving attempt rejected, asking for confirmation to '
                  . $self->userId($req) );
            $res->{result} = 0;
            $res->{needConfirm} = 1 if ( $s == CONFIG_WAS_CHANGED );
            $res->{message} .= '__needConfirmation__';
        }
    }
    return $self->sendJSONresponse( $req, $res );
}

## @method private applyConf()
# Try to prevent other servers declared in `reloadUrls` that a new
# configuration is available.
#
#@return reload status as boolean
sub applyConf {
    my ( $self, $newConf ) = @_;
    my $status;

    # Get apply section values
    my %reloadUrls =
      %{ $self->confAcc->getLocalConf( APPLYSECTION, undef, 0 ) };
    if ( !%reloadUrls && $newConf->{reloadUrls} ) {
        %reloadUrls = %{ $newConf->{reloadUrls} };
    }
    return {} unless (%reloadUrls);

    # Create user agent
    require LWP::UserAgent;
    my $ua = new LWP::UserAgent( requests_redirectable => [] );
    $ua->timeout(3);

    # Parse apply values
    while ( my ( $host, $request ) = each %reloadUrls ) {
        my $r = HTTP::Request->new( 'GET', "http://$host$request");
        if ($request =~ /^https?:\/\/[^\/]+.*$/) {
            my $url = URI::URL->new($request);
            my $targetUrl = $url->scheme."://".$host;
            $targetUrl .= ":".$url->port if defined ($url->port);
            $targetUrl .= $url->full_path;
            $r =
              HTTP::Request->new( 'GET', $targetUrl,
                HTTP::Headers->new( Host => $url->host ) );
            if (defined $url->userinfo && $url->userinfo =~/^([^:]+):(.*)$/) {
                $r->authorization_basic($1,$2);
            }
        }

        my $response = $ua->request($r);
        if ( $response->code != 200 ) {
            $status->{$host} =
              "Error " . $response->code . " (" . $response->message . ")";
            $self->userError( "Apply configuration for $host: error "
                  . $response->code . " ("
                  . $response->message
                  . ")" );
        }
        else {
            $status->{$host} = "OK";
            $self->userNotice("Apply configuration for $host: ok");
        }
    }

    return $status;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Conf - Configuration management part of
L<Lemonldap::NG::Manager>.

=head1 SYNOPSIS

See L<Lemonldap::NG::Manager>.

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

The Perl part of Lemonldap::NG::Manager is the REST server. Web interface is
written in Javascript, using AngularJS framework and can be found in `site`
directory. The REST API is described in REST-API.md file given in source tree.

Lemonldap::NG Manager::Conf provides the configuration management part.

=head1 ORGANIZATION

Lemonldap::NG::Manager configuration is managed by 2 files:

=over

=item This file

to display configuration metadatas and keys content, and to
save new configuration,

=item L<Lemonldap::NG::Manager::Conf::Parser>

used to check proposed configuration.

=back

=head1 OPERATION

The first Ajax request given by the manager web interface is generaly
`/confs/latest`, Lemonldap::NG::Manager::Conf returns the configuration
metadatas (author, data, log,...). Then for each key read by the user, web
interface launch an Ajax request to get the value.

At the end, when modifications are saved, a POST request is done to `/confs`.
Then Lemonldap::NG::Manager::Conf calls L<Lemonldap::NG::Manager::Conf::Parser>
to verify new configuration. If good, it tries to store it. Then it calls
applyConf() that tries to call other servers to explain them that configuration
has changed. Then it returns all errors, warnings in a JSON object that is
displayed by web interface.

=head1 SEE ALSO

L<Lemonldap::NG::Manager::Conf::Parser>, L<Lemonldap::NG::Manager>,
L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<http://jira.ow2.org>

=head1 DOWNLOAD

Lemonldap::NG is available at
L<http://forge.objectweb.org/project/showfiles.php?group_id=274>

=head1 COPYRIGHT AND LICENSE

=over

=item Copyright (C) 2015-2016 by Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Copyright (C) 2015-2016 by Clément Oudot, E<lt>clem.oudot@gmail.comE<gt>

=back

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
