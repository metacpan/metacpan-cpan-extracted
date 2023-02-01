package Lemonldap::NG::Common::Conf::RESTServer;

use strict;
use JSON 'from_json';
use Mouse;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::Conf::ReConstants;

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Common::Conf::AccessLib';

#######################
# I. PRIVATE METHODS #
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
    $self->logger->debug("Search for $key in conf");

    # Verify that cfgNum has been asked
    unless ( defined $req->params('cfgNum') ) {
        $req->error("Missing configuration number");
        return undef;
    }
    $self->logger->debug( "Cfgnum set to " . $req->params('cfgNum') );

    # when 'latest' => replace by last cfgNum
    if ( $req->params('cfgNum') eq 'latest' ) {
        my $tmp = $self->confAcc->lastCfg;
        $req->set_param( 'cfgNum', $tmp );
        unless ($tmp) {
            $req->error($Lemonldap::NG::Common::Conf::msg)
              if ($Lemonldap::NG::Common::Conf::msg);
            return undef;
        }
    }
    elsif ( $req->params('cfgNum') !~ /^\d+$/ ) {
        $req->error("cfgNum must be a number");
        return undef;
    }
    unless (
        defined $self->getConfByNum( scalar( $req->params('cfgNum') ), @args ) )
    {
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
    unless ($self->currentConf
        and %{ $self->currentConf }
        and $cfgNum == $self->currentConf->{cfgNum} )
    {
        my $tmp = $self->confAcc->getConf(
            { cfgNum => $cfgNum, raw => 1, noCache => 1, @args } );
        return undef unless ( $tmp and ref($tmp) and %$tmp );
        $self->currentConf($tmp);
    }
    return $cfgNum;
}

########################
# II. Display methods #
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
#    root query (/confs/latest for example) is redirected to metadata()
#  - other requests:
#    they are managed by getKey()
#  - newRSAKey() returns a new RSA key pair if /confs/newRSAKey is called in a
#    POST request
#  - prx() load a request and return the content (for SAML/OIDC metadata)

# 31 - Complex subnodes
#      ----------------

## @method PSGI-JSON-response complexNodesRoot($req, $query, $tpl)
# Respond to root requests for virtual hosts and SAMLmetadata
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@param $query Configuration root key
#@param $tpl Javascript template to use (see JS/JSON generator script)
#@return PSGI JSON response
sub complexNodesRoot {
    my ( $self, $req, $query, $tpl ) = @_;
    $self->logger->debug("Query for $query template keys");

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
        $self->logger->debug("Query for $vh/$query keys");

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

            # If rule contains a comment or an AuthLevel, split them
            if ( $query eq 'locationRules' ) {
                $res->{comment} = '';
                $res->{level}   = '';
                $res->{level}   = $1 if ( $r =~ s/\(\?#AuthnLevel=(-?\d+)\)// );
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
    elsif ( $query =~ qr/^$virtualHostKeys$/o ) {
        $self->logger->debug("Query for $vh/$query key");

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
    elsif ( $query eq "samlSPMetaDataMacros" ) {
        my $pk =
          eval { $self->getConfKey( $req, $query )->{$partner} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        foreach my $h ( sort keys %$pk ) {
            push @$resp,
              {
                id    => "saml${type}MetaDataNodes/$partner/$query/" . $id++,
                title => $h,
                data  => $pk->{$h},
                type  => 'keyText',
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
    # Lemonldap::NG::Common::Conf::ReConstants
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

    # Handle RP Attributes
    if ( $query eq "oidcRPMetaDataExportedVars" ) {
        my $pk = eval { $self->getConfKey( $req, $query )->{$partner} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        foreach my $h ( sort keys %$pk ) {

            # Set default values for type and array
            my $data = [ split /;/, $pk->{$h} ];
            unless ( $data->[1] ) {
                $data->[1] = "string";
            }
            unless ( $data->[2] ) {
                $data->[2] = "auto";
            }
            push @$resp,
              {
                id    => "oidc${type}MetaDataNodes/$partner/$query/" . $id++,
                title => $h,
                data  => $data,
                type  => 'oidcAttribute',
              };
        }
        return $self->sendJSONresponse( $req, $resp );
    }

    # Return all exported attributes if asked
    elsif ( $query =~
/^(?:oidc${type}MetaDataExportedVars|oidcRPMetaDataOptionsExtraClaims|oidcRPMetaDataMacros|oidcRPMetaDataScopeRules)$/
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

# 314 - CAS
#       ---

sub _casMetaDataNodes {
    my ( $self, $type, $req, @path ) = @_;
    my $refKey =
      ( $type eq 'App' ? 'casAppMetaDataOptions' : 'casSrvMetaDataOptions' );
    return $self->complexNodesRoot( $req, $refKey, "cas${type}MetaDataNode" )
      unless (@path);

    my $partner = shift @path;
    my $query   = shift @path;
    unless ($query) {
        return $self->sendError( $req,
            "Bad request: cas${type}MetaDataNode query must ask for a key",
            400 );
    }

    # setDefault response for new partners
    return $self->sendError( $req, 'setDefault', 200 )
      if ( $partner =~ /^new__/ );

    # Reject unknown partners
    return $self->sendError( $req, "Unknown CAS partner ($partner)", 400 )
      unless ( defined eval { $self->getConfKey( $req, $refKey )->{$partner}; }
      );

    my ( $id, $resp ) = ( 1, [] );

    # Return all exported attributes if asked
    if ( $query =~
/^(?:cas${type}MetaDataExportedVars|casSrvMetaDataOptionsProxiedServices|casAppMetaDataMacros)$/
      )
    {
        my $pk = eval { $self->getConfKey( $req, $query )->{$partner} } // {};
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        foreach my $h ( sort keys %$pk ) {
            push @$resp,
              {
                id    => "cas${type}MetaDataNodes/$partner/$query/" . $id++,
                title => $h,
                data  => $pk->{$h},
                type  => 'keyText',
              };
        }
        return $self->sendJSONresponse( $req, $resp );
    }

    # Options
    if (
        $query =~ {
            App => qr/^$casAppMetaDataNodeKeys$/o,
            Srv => qr/^$casSrvMetaDataNodeKeys$/o
        }->{$type}
      )
    {
        my $value = eval {
            $self->getConfKey( $req, "cas${type}MetaDataOptions" )->{$partner}
              ->{$query};
        } // undef;
        return $self->sendJSONresponse( $req, { value => $value } );
    }
    else {
        return $self->sendError( $req,
            "Bad key for cas${type}MetaDataNode ($query)", 400 );
    }
}

sub casSrvMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_casMetaDataNodes( 'Srv', $req, @path );
}

sub casAppMetaDataNodes {
    my ( $self, $req, @path ) = @_;
    return $self->_casMetaDataNodes( 'App', $req, @path );
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
            my $data = [ split /;/, $value->{$k} ];
            if ( $data->[5] ) {
                my $over;
                eval { $over = from_json( $data->[5] ) };
                if ($@) {
                    $self->logger->error(
                        "Bad value in choice over parameters, deleted ($@)");
                }
                else {
                    $data->[5] = [ map { [ $_, $over->{$_} ] } keys %{$over} ];
                }
            }
            push @res,
              {
                id    => "authChoiceModules/$k",
                title => "$k",
                data  => $data,
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
    return $self->sendError( $req, 'Subkeys forbidden for grantSessionRules',
        400 )
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
    return $self->sendError( $req, 'Subkeys forbidden for openIdIDPList', 400 )
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

    foreach my $cat (
        sort {
            ( $apps->{$a}->{order} || 0 ) <=> ( $apps->{$b}->{order} || 0 )
              or $a cmp $b
        }
        grep { not /^(?:catname|type|order)$/ } keys %$apps
      )
    {
        my $item = { id => "$baseId/$cat" };
        if ( $apps->{$cat}->{type} eq 'category' ) {
            $item->{title} = $apps->{$cat}->{catname};
            $item->{type}  = 'menuCat';
            $item->{nodes} =
              $self->_scanCatsAndApps( $apps->{$cat}, "$baseId/$cat" );
        }
        else {
            $item->{title} = $apps->{$cat}->{options}->{name};
            $item->{type}  = $apps->{$cat}->{type} = 'menuApp';
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

# 325 - Combination modules

# Returns raw value, just transform "over" key
sub combModules {
    my ( $self, $req, $key ) = @_;
    return $self->sendError( $req, 'Subkeys forbidden for combModules', 400 )
      if ($key);
    my $val = $self->getConfKey( $req, 'combModules' ) // {};
    my $res = [];
    foreach my $mod ( keys %$val ) {
        my $tmp;
        $tmp->{title}      = $mod;
        $tmp->{id}         = "combModules/$mod";
        $tmp->{type}       = 'cmbModule';
        $tmp->{data}->{$_} = $val->{$mod}->{$_} foreach (qw(type for));
        my $over = $val->{$mod}->{over} // {};
        $tmp->{data}->{over} = [ map { [ $_, $over->{$_} ] } keys %$over ];
        push @$res, $tmp;
    }
    return $self->sendJSONresponse( $req, $res );
}

sub sfExtra {
    my ( $self, $req, $key ) = @_;
    return $self->sendError( $req, 'Subkeys forbidden for sfExtra', 400 )
      if ($key);
    my $val = $self->getConfKey( $req, 'sfExtra' ) // {};
    my $res = [];
    foreach my $mod ( keys %$val ) {
        my $tmp;
        $tmp->{title}      = $mod;
        $tmp->{id}         = "sfExtra/$mod";
        $tmp->{type}       = 'sfExtra';
        $tmp->{data}->{$_} = $val->{$mod}->{$_}
          foreach (qw(type rule logo level label));
        $tmp->{data}->{register} = $val->{$mod}->{register} ? \1 : \0;
        my $over = $val->{$mod}->{over} // {};
        $tmp->{data}->{over} = [ map { [ $_, $over->{$_} ] } keys %$over ];
        push @$res, $tmp;
    }
    return $self->sendJSONresponse( $req, $res );
}

# 33 - Root queries
#      -----------

## @method PSGI-JSON-response metadata($req)
# Respond to `/conf/:cfgNum` requests by sending configuration metadata
#
# NB: if `full=1` is set in the query, configuration is returned directly in
#     JSON
#
#@param $req Lemonldap::NG::Common::PSGI::Request
#@return PSGI JSON response
sub metadata {
    my ( $self, $req ) = @_;
    if ( $req->params('full') and $req->params('full') !~ NO ) {
        my $c = $self->getConfKey( $req, 'cfgNum' );
        return $self->sendError( $req, undef, 400 ) if ( $req->error );
        if ( $self->can('userId') ) {
            $self->userLogger->notice( 'User '
                  . $self->userId($req)
                  . ' ask for full configuration '
                  . $c );
        }
        else {
            $self->logger->info("REST request to get full configuration $c");
        }
        return $self->sendJSONresponse(
            $req,
            $self->currentConf,
            pretty  => 1,
            headers => [
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
        foreach my $key (qw(cfgAuthor cfgDate cfgAuthorIP cfgLog cfgVersion)) {
            $res->{$key} = $self->getConfKey( $req, $key );
        }

        # Find next and previous conf
        my @a     = $self->confAcc->available;
        my $id    = -1;
        my ($ind) = map { $id++; $_ == $res->{cfgNum} ? ($id) : () } @a;
        if ($ind) { $res->{prev} = $a[ $ind - 1 ]; }
        if ( defined $ind and $ind < $#a ) {
            $res->{next} = $a[ $ind + 1 ];
        }
        if ( $self->can('userId') ) {
            $self->userLogger->info( 'User '
                  . $self->userId($req)
                  . ' ask for configuration metadata ('
                  . $res->{cfgNum}
                  . ')' );
        }
        else {
            $self->logger->info(
                "REST request to get configuration metadata ($res->{cfgNum})");
        }
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
        return $self->metadata($req);
    }
    if ( $self->can('userId') ) {
        $self->userLogger->info(
            'User ' . $self->userId($req) . " asks for key $key" );
    }
    else {
        $self->logger->info("REST request to get configuration key $key");
    }
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
    return $self->sendError( $req, 'setDefault', 200 )
      unless defined($value);
    return $self->sendJSONresponse( $req, { value => $value } );

    # TODO authParam key
}

1;
