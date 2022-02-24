package Lemonldap::NG::Manager::Sessions;

use strict;
use utf8;
use Mouse;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::Conf::ReConstants;
use Lemonldap::NG::Common::IPv6;

#use feature 'state';

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Session::REST
  Lemonldap::NG::Common::Conf::AccessLib
);

our $VERSION = '2.0.10';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'sessions.html';

sub init {
    my ( $self, $conf ) = @_;

    # HTML template
    $self->addRoute( 'sessions.html', undef, ['GET'] )

      # READ
      ->addRoute( sessions => { ':sessionType' => 'sessions' }, ['GET'] )

      # DELETE
      ->addRoute(
        sessions => { ':sessionType' => { ':sessionId' => 'delSession' } },
        ['DELETE']
      )

      # DELETE OIDC CONSENT
      ->addRoute(
        sessions => {
            OIDCConsent =>
              { ':sessionType' => { ':sessionId' => 'delOIDCConsent' } }
        },
        ['DELETE']
      );

    $self->setTypes($conf);

    $self->{ipField}              ||= 'ipAddr';
    $self->{multiValuesSeparator} ||= '; ';
    $self->{impersonationPrefix} = $conf->{impersonationPrefix} || 'real_';
    $self->{hiddenAttributes} //= '_password';
    $self->{hiddenAttributes} .= ' _session_id'
      unless $conf->{displaySessionId};
    return 1;
}

#######################
# II. CONSENT METHODS #
#######################

sub delOIDCConsent {

    my ( $self, $req ) = @_;

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );

    my $params = $req->parameters();
    my $epoch  = $params->{epoch};
    my $rp     = $params->{rp};

    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );

    $req->parameters->set( 'sessionId', $self->_maybeDecryptSessionId($id) );

    if ( $rp =~ /\b[\w-]+\b/ and defined $epoch ) {
        $self->logger->debug(
            "Call procedure deleteOIDCConsent with RP=$rp and epoch=$epoch");
        return $self->deleteOIDCConsent($req);
    }
    else {
        return $self->sendError( $req, undef, 400 );
    }
}

########################
# III. DISPLAY METHODS #
########################

sub sessions {
    my ( $self, $req, $session, $skey ) = @_;

    # Case 1: only one session is required
    if ($session) {
        return $self->session( $req, $session, $skey );
    }

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $params = $req->parameters();
    my $type   = delete $params->{sessionType};
    $type = $type eq 'global'  ? 'SSO'   : ucfirst($type);
    $type = $type eq 'Offline' ? 'OIDCI' : ucfirst($type);

    my $res;

    # Case 2: list of sessions

    my $whatToTrace = Lemonldap::NG::Handler::Main->tsv->{whatToTrace};

    # 2.1 Get fields to require
    my @fields = ( '_httpSessionType', $self->{ipField}, $whatToTrace );
    if ( my $groupBy = $params->{groupBy} ) {
        $groupBy =~ s/^substr\((\w+)(?:,\d+(?:,\d+)?)?\)$/$1/
          or $groupBy =~ s/^net(?:4|6|)\(([\w:]+),\d+(?:,\d+)?\)$/$1/;
        $groupBy =~ s/^_whatToTrace$/$whatToTrace/o
          or push @fields, $groupBy;
    }
    elsif ( my $order = $params->{orderBy} ) {
        $order =~ s/^net(?:4|6|)\(([\w:]+)\)$/$1/;
        $order =~ s/^_whatToTrace$/$whatToTrace/o
          or push @fields, split( /, /, $order );
    }
    else {
        push @fields, '_utime';
    }

    # 2.2 Restrict query if possible: search for filters (any query arg that is
    #     not a keyword)
    my $moduleOptions = $mod->{options};
    $moduleOptions->{backend} = $mod->{module};
    my %filters = map {
        my $s = $_;
        $s =~ s/\b_whatToTrace\b/$whatToTrace/o;
        /^(?:(?:group|order)By|doubleIp)$/
          ? ()
          : ( $s => $params->{$_} );
    } keys %$params;
    $filters{_session_kind} = $type;
    push @fields, keys(%filters);
    {
        my %seen;
        @fields = grep { !$seen{$_}++ } @fields;
    }

    # For now, only one argument can be passed to
    # Lemonldap::NG::Common::Apache::Session so just the first filter is
    # used
    my ($firstFilter) = sort {
            $filters{$a} =~ m#^[\w:]+/\d+\*?$# ? 1
          : $filters{$b} =~ m#^[\w:]+/\d+\*?$# ? -1
          : $a eq '_session_kind'              ? 1
          : $b eq '_session_kind'              ? -1
          : $a cmp $b
    } keys %filters;

    # Check if a '*' is required
    my $function = 'searchOn';
    $function = 'searchOnExpr'
      if ( grep { /\*/ and not m#^[\w:]+/\d+\*?$# }
        ( $filters{$firstFilter} ) );
    $self->logger->debug(
        "First filter: $firstFilter = $filters{$firstFilter} ($function)");

    $res =
      Lemonldap::NG::Common::Apache::Session->$function( $moduleOptions,
        $firstFilter, $filters{$firstFilter}, @fields );

    return $self->sendJSONresponse(
        $req,
        {
            result => 1,
            count  => 0,
            total  => 0,
            values => []
        }
    ) unless ( $res and %$res );

    delete $filters{$firstFilter}
      unless ( grep { /\*/ and not m#^[\w:]+/\d+\*?$# }
        ( $filters{$firstFilter} ) );
    foreach my $k ( keys %filters ) {
        $self->logger->debug("Removing unless $k =~ /^$filters{$k}\$/");
        if ( $filters{$k} =~ m#^([\w:]+)/(\d+)\*?$# ) {
            my ( $net, $bits ) = ( $1, $2 );
            foreach my $session ( keys %$res ) {
                delete $res->{$session}
                  unless ( net6( $res->{$session}->{$k}, $bits ) eq $net );
            }
        }
        else {
            $filters{$k} =~ s/\./\\./g;
            $filters{$k} =~ s/\*/\.\*/g;
            foreach my $session ( keys %$res ) {
                if ( $res->{$session}->{$k} ) {
                    delete $res->{$session}
                      unless ( $res->{$session}->{$k} =~ /^$filters{$k}$/ );
                }
            }
        }
    }

    my $total = ( keys %$res );

    # 2.4 Special case doubleIp (users connected from more than 1 IP)
    if ( defined $params->{doubleIp} ) {
        my %r;

        # 2.4.1 Store user IP addresses in %r
        foreach my $id ( keys %$res ) {
            my $entry = $res->{$id};
            next if ( $entry->{_httpSessionType} );
            $r{ $entry->{$whatToTrace} }->{ $entry->{ $self->{ipField} } }++;
        }

   # 2.4.2 Store sessions owned by users that has more than one IP address in $r
        my $r;
        $total = 0;
        foreach my $k ( keys %$res ) {
            my @tmp = keys %{ $r{ $res->{$k}->{$whatToTrace} } };
            if ( @tmp > 1 ) {
                $total += 1;
                $res->{$k}->{_sessionId} = $k;
                push @{ $r->{ $res->{$k}->{$whatToTrace} } }, $res->{$k};
            }
        }

        # 2.4.3 Store these session in an array. Array elements are :
        #       {
        #           uid      => whatToTraceFieldValue,
        #           sessions => [
        #               { session => <session-id-1>, date => <_utime> },
        #               { session => <session-id-2>, date => <_utime> },
        #           ]
        #       }
        $res = [];
        foreach my $uid ( sort keys %$r ) {
            push @$res, {
                value    => $uid,
                count    => scalar( @{ $r->{$uid} } ),
                sessions => [
                    map {
                        {
                            session =>
                              $self->_maybeEncryptSessionId( $_->{_sessionId} ),
                            date => $_->{_utime}
                        }
                    } @{ $r->{$uid} }
                ]
            };
        }
    }

 # 2.4 Order and group by
 # $res will become an array ref here (except for doubleIp, already done below).

    # If "groupBy" is asked, elements will be like:
    #   { uid => 'foo.bar', count => 3 }
    elsif ( my $group = $req->params('groupBy') ) {
        my $r;
        $group =~ s/\b_whatToTrace\b/$whatToTrace/o;

        # Substrings
        if ( $group =~ /^substr\((\w+)(?:,(\d+)(?:,(\d+))?)?\)$/ ) {
            my ( $field, $length, $start ) = ( $1, $2, $3 );
            $start ||= 0;
            $length = 1 if ( $length < 1 );
            foreach my $k ( keys %$res ) {
                $r->{ substr $res->{$k}->{$field}, $start, $length }++
                  if ( $res->{$k}->{$field} );
            }
            $group = $field;
        }

        # Subnets IPv4
        elsif ( $group =~ /^net4\((\w+),(\d)\)$/ ) {
            my $field = $1;
            my $nb    = $2 - 1;
            foreach my $k ( keys %$res ) {
                if ( $res->{$k}->{$field} =~ /^((((\d+)\.\d+)\.\d+)\.\d+)$/ ) {
                    my @d = ( $4, $3, $2, $1 );
                    $r->{ $d[$nb] }++;
                }
            }
            $group = $field;
        }

        # Subnets IPv6
        elsif ( $group =~ /^net6\(([\w:]+),(\d)\)$/ ) {
            my $field = $1;
            my $bits  = $2;
            foreach my $k ( keys %$res ) {
                $r->{ net6( $res->{$k}->{$field}, $bits ) . "/$bits" }++
                  if ( isIPv6( $res->{$k}->{$field} ) );
            }
        }

        # Both IPv4 and IPv6
        elsif ( $group =~ /^net\(([\w:]+),(\d+),(\d+)\)$/ ) {
            my $field = $1;
            my $bits  = $2;
            my $nb    = $3 - 1;
            foreach my $k ( keys %$res ) {
                if ( isIPv6( $res->{$k}->{$field} ) ) {
                    $r->{ net6( $res->{$k}->{$field}, $bits ) . "/$bits" }++;
                }
                elsif ( $res->{$k}->{$field} =~ /^((((\d+)\.\d+)\.\d+)\.\d+)$/ )
                {
                    my @d = ( $4, $3, $2, $1 );
                    $r->{ $d[$nb] }++;
                }
            }
        }

        # Simple field groupBy query
        elsif ( $group =~ /^\w+$/ ) {
            eval {
                foreach my $k ( keys %$res ) {
                    $r->{ $res->{$k}->{$group} }++;
                }
            };
            return $self->sendError(
                $req,
qq{Use of an uninitialized attribute "$group" to group sessions},
                400
            ) if ($@);
        }
        else {
            return $self->sendError( $req, 'Syntax error in groupBy', 400 );
        }

        # Build result
        $res = [
            sort {
                my @a = ( $a->{value} =~ /^(\d+)(?:\.(\d+))*$/ );
                my @b = ( $b->{value} =~ /^(\d+)(?:\.(\d+))*$/ );
                ( @a and @b )
                  ? ( $a[0] <=> $b[0]
                      or $a[1] <=> $b[1]
                      or $a[2] <=> $b[2]
                      or $a[3] <=> $b[3] )
                  : $a->{value} cmp $b->{value}
              }
              map { { value => $_, count => $r->{$_} } } keys %$r
        ];
    }

    # Else if "orderBy" is asked, $res elements will be like:
    #   { uid => 'foo.bar', session => <sessionId> }
    elsif ( my $f = $req->params('orderBy') ) {
        my @fields = split /,/, $f;
        my @r      = map {
            my $tmp = { session => $self->_maybeEncryptSessionId($_) };
            foreach my $f (@fields) {
                my $s = $f;
                $s =~ s/^net(?:4|6|)\(([\w:]+)\)$/$1/;
                $tmp->{$s} = $res->{$_}->{$s};
            }
            $tmp
        } keys %$res;
        while ( my $f = pop @fields ) {
            if ( $f =~ s/^net4\((\w+)\)$/$1/ ) {
                @r = sort { cmpIPv4( $a->{$f}, $b->{$f} ); } @r;
            }
            elsif ( $f =~ s/^net6\(([:\w]+)\)$/$1/ ) {
                @r = sort { expand6( $a->{$f} ) cmp expand6( $b->{$f} ); } @r;
            }
            elsif ( $f =~ s/^net\(([:\w]+)\)$/$1/ ) {
                @r = sort {
                    my $ip1 = $a->{$f};
                    my $ip2 = $b->{$f};
                    isIPv6($ip1)
                      ? (
                          isIPv6($ip2)
                        ? expand6($ip1) cmp expand6($ip2)
                        : -1
                      )
                      : isIPv6($ip2) ? 1
                      :                cmpIPv4( $ip1, $ip2 );
                } @r;
            }
            else {
                @r = sort { $a->{$f} cmp $b->{$f} } @r;
            }
        }
        $res = [@r];
    }

    # Else, $res elements will be like:
    #   { session => <sessionId>, date => <timestamp> }
    else {
        $res = [
            sort { $a->{date} <=> $b->{date} }
              map {
                {
                    session => $self->_maybeEncryptSessionId($_),
                    date    => $res->{$_}->{_utime}
                }
              }
              keys %$res
        ];
    }

    return $self->sendJSONresponse(
        $req,
        {
            result => 1,
            count  => scalar(@$res),
            total  => $total,
            values => $res
        }
    );
}

sub session {
    my ( $self, $req, $session, $skey ) = @_;

    $session = $self->_maybeDecryptSessionId($session);
    return $self->SUPER::session( $req, $session, $skey );
}

sub _maybeDecryptSessionId {
    my ( $self, $session ) = @_;

    if ( $self->{hiddenAttributes} =~ /\b_session_id\b/ ) {
        $session =
          Lemonldap::NG::Handler::Main->tsv->{cipher}->decryptHex($session);
    }

    return $session;
}

sub _maybeEncryptSessionId {
    my ( $self, $session ) = @_;

    if ( $self->{hiddenAttributes} =~ /\b_session_id\b/ ) {
        $session =
          Lemonldap::NG::Handler::Main->tsv->{cipher}->encryptHex($session);
    }

    return $session;
}

sub delSession {
    my ( $self, $req ) = @_;
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );

    $req->parameters->set( 'sessionId', $self->_maybeDecryptSessionId($id) );

    return $self->SUPER::delSession($req);
}

sub cmpIPv4 {
    my @a   = split /\./, $_[0];
    my @b   = split /\./, $_[1];
    my $cmp = 0;
  F: for ( my $i = 0 ; $i < 4 ; $i++ ) {
        if ( $a[$i] != $b[$i] ) {
            $cmp = $a[$i] <=> $b[$i];
            last F;
        }
    }
    $cmp;
}

1;
