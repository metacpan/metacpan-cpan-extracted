package Lemonldap::NG::Manager::2ndFA;

use strict;
use utf8;
use Mouse;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Common::Conf::ReConstants;

extends qw(
  Lemonldap::NG::Manager::Plugin
  Lemonldap::NG::Common::Session::REST
  Lemonldap::NG::Common::Conf::AccessLib
);

our $VERSION = '2.0.10';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => '2ndfa.html';

sub init {
    my ( $self, $conf ) = @_;

    # Remote Procedure are defined in Lemonldap::NG::Common::Session::REST
    # HTML template
    $self->addRoute( '2ndfa.html', 'sfaView', ['GET'] )

      ->addRoute(
        sfa => { ':sessionType' => 'sfa' },
        ['GET']
      )

      # DELETE 2FA DEVICE
      ->addRoute(
        sfa => { ':sessionType' => { ':sessionId' => 'del2F' } },
        ['DELETE']
      );

    $self->setTypes($conf);
    $self->{multiValuesSeparator} ||= '; ';
    $self->{hiddenAttributes} //= "_password";
    $self->{hiddenAttributes} .= ' _session_id'
      unless $conf->{displaySessionId};

    $self->{regSfaTypes} = [ (
            sort map { s/^Yubikey$/UBK/r } split /[\s,]+/,
            $conf->{available2FSelfRegistration}
        ),
        keys %{ $conf->{sfExtra} || {} },
    ];
    return 1;
}

###################
# II. 2FA METHODS #
###################

sub del2F {

    my ( $self, $req, $session, $skey ) = @_;

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, 'Bad mode', 400 );

    my $params = $req->parameters();
    my $type   = $params->{type}
      or return $self->sendError( $req, 'Missing "type" parameter', 400 );
    my $epoch = $params->{epoch}
      or return $self->sendError( $req, 'Missing "epoch" parameter', 400 );

    $self->logger->debug(
        "Call procedure delete2F with type=$type and epoch=$epoch");
    return $self->delete2F( $req, $session, $skey );
}

########################
# III. DISPLAY METHODS #
########################

sub sfa {
    my ( $self, $req, $session, $skey ) = @_;

    # Case 1: only one session is required
    if ($session) {
        return $self->session( $req, $session, $skey );
    }

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, 'Bad mode', 400 );
    my $params = $req->parameters();
    my $type   = delete $params->{sessionType};
    $type = ucfirst($type);
    my $res;

    # Case 2: list of sessions

    my $whatToTrace = Lemonldap::NG::Handler::PSGI::Main->tsv->{whatToTrace};

    # 2.1 Get fields to require
    my @fields = ( '_httpSessionType', $whatToTrace, '_2fDevices' );
    if ( my $groupBy = $params->{groupBy} ) {
        $groupBy =~ s/^substr\((\w+)(?:,\d+(?:,\d+)?)?\)$/$1/;
        $groupBy =~ s/^_whatToTrace$/$whatToTrace/o
          or push @fields, $groupBy;
    }
    else {
        push @fields, '_utime';
    }

    # 2.2 Restrict query if possible: search for filters (any query arg that is
    #     not a keyword)
    my $moduleOptions = $mod->{options};
    $moduleOptions->{backend} = $mod->{module};

    my @display_types = $params->get_all('type');
    $params->remove('type');

    my %filters = map {
        my $s = $_;
        $s =~ s/\b_whatToTrace\b/$whatToTrace/o;
        /^groupBy$/
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
        $filters{$k} =~ s/\./\\./g;
        $filters{$k} =~ s/\*/\.\*/g;
        foreach my $session ( keys %$res ) {
            if ( $res->{$session}->{$k} ) {
                delete $res->{$session}
                  unless ( $res->{$session}->{$k} =~ /^$filters{$k}$/ );
            }
        }
    }

    # Remove sessions without at least one 2F device(s)
    $self->logger->debug(
        "Removing sessions without at least one 2F device(s)...");
    foreach my $session ( keys %$res ) {
        delete $res->{$session}
          unless ( defined $res->{$session}->{_2fDevices}
            and $res->{$session}->{_2fDevices} =~ /"type"/s );
    }

    my $all = ( keys %$res );

    # Filter 2FA sessions if needed
    if (@display_types) {
        $self->logger->debug("Filtering 2F sessions...");
        foreach (@display_types) {
            foreach my $session ( keys %$res ) {
                delete $res->{$session}
                  unless ( defined $res->{$session}->{_2fDevices}
                    and $res->{$session}->{_2fDevices} =~ /"type":\s*"$_"/s );
            }
            $self->logger->debug(
                "Removing sessions unless a $_ device is registered");
        }
    }

    my $total = ( keys %$res );
    $self->logger->debug("2FA session(s) left : $total / $all");

    if ( my $group = $req->params('groupBy') ) {
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

    # Else, $res elements will be like:
    #   { session => <sessionId>, userId => <_session_uid> }
    else {
        $res = [
            sort  { $a->{date} <=> $b->{date} }
              map { { session => $_, userId => $res->{$_}->{_session_uid} } }
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

sub sfaView {
    my ( $self, $req ) = @_;
    return $self->p->sendHtml(
        $req, "2ndfa",
        params => {
            SFATYPES => [ map { { SFATYPE => $_ } } @{ $self->{regSfaTypes} } ],
        }
    );
}

1;
