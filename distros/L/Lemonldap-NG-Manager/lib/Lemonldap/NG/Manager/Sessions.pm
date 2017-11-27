package Lemonldap::NG::Manager::Sessions;

use 5.10.0;
use utf8;
use strict;
use Mouse;

use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::Conf::Constants;
use Lemonldap::NG::Common::Session;
use Lemonldap::NG::Common::PSGI::Constants;
use Lemonldap::NG::Manager::Constants;
use Lemonldap::NG::Handler::Main qw(:tsv);

use feature 'state';

extends 'Lemonldap::NG::Manager::Lib';

has conf => ( is => 'rw', isa => 'HashRef', default => sub { {} } );

our $VERSION = '1.9.9';

#############################
# I. INITIALIZATION METHODS #
#############################

use constant defaultRoute => 'sessions.html';

sub addRoutes {
    my $self = shift;

    # HTML template
    $self->addRoute( 'sessions.html', undef, ['GET'] )

      # READ
      ->addRoute( sessions => { ':sessionType' => 'sessions' }, ['GET'] )

      # DELETE
      ->addRoute(
        sessions => { ':sessionType' => { ':sessionId' => 'delSession' } },
        ['DELETE']
      );

    #TODO: transfer this in Manager.pm ?
    if ( my $localConf = $self->confAcc->getLocalConf(SESSIONSEXPLORERSECTION) )
    {
        $self->{$_} = $localConf->{$_} foreach ( keys %$localConf );
    }

    my $conf = $self->confAcc->getConf();
    #
    # Return unless configuration is available
    return 0 unless ($conf);
    foreach my $type (@sessionTypes) {
        if ( my $tmp =
            $self->{ $type . 'Storage' } || $conf->{ $type . 'Storage' } )
        {
            $self->{conf}->{$type}->{module} = $tmp;
            $self->{conf}->{$type}->{options} =
                 $self->{ $type . 'StorageOptions' }
              || $conf->{ $type . 'StorageOptions' }
              || {};
            $self->{conf}->{$type}->{kind} =
              ( $type eq 'global' ? 'SSO' : ucfirst($type) );
        }
    }

    $self->{ipField}              ||= 'ipAddr';
    $self->{multiValuesSeparator} ||= '; ';
    $self->{hiddenAttributes} //= "_password";
}

#######################
# II. DISPLAY METHODS #
#######################

sub sessions {
    my ( $self, $req, $session, $skey ) = @_;

    # Case 1: only one session is required
    if ($session) {
        return $self->session( $req, $session, $skey );
    }

    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $params = $req->params();
    my $type   = delete $params->{sessionType};
    $type = $type eq 'global' ? 'SSO' : ucfirst($type);

    my $res;

    # Case 2: list of sessions

    # 2.1 Get fields to require
    my @fields =
      ( '_httpSessionType', $self->{ipField}, $tsv->{whatToTrace} );
    if ( my $groupBy = $params->{groupBy} ) {
        $groupBy =~ s/^substr\((\w+)(?:,\d+(?:,\d+)?)?\)$/$1/
          or $groupBy =~ s/^net4\((\w+),\d\)$/$1/;
        $groupBy =~ s/^_whatToTrace$/$tsv->{whatToTrace}/o
          or push @fields, $groupBy;
    }
    elsif ( my $order = $params->{orderBy} ) {
        $order =~ s/\bnet4\((\w+)\)$/$1/;
        $order =~ s/\b_whatToTrace\b/$tsv->{whatToTrace}/o
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
        $s =~ s/\b_whatToTrace\b/$tsv->{whatToTrace}/o;
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

    # Check if a '*' is required
    my $function = 'searchOn';
    $function = 'searchOnExpr' if ( grep /\*/, values %filters );

    # For now, only one argument can be passed to
    # Lemonldap::NG::Common::Apache::Session so just the first filter is
    # used
    my ($firstFilter) = sort {
            $a eq '_session_kind' ? 1
          : $b eq '_session_kind' ? -1
          : $a cmp $b
    } keys %filters;
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

    delete $filters{$firstFilter};
    foreach my $k ( keys %filters ) {
        $filters{$k} =~ s/\./\\./g;
        $filters{$k} =~ s/\*/\.\*/g;
        foreach my $session ( keys %$res ) {
            if ( $res->{$session}->{$k} ) {
                delete $res->{$session}
                  unless ( $res->{$session}->{$k} =~ /^$filters{$k}$/ );
            }
        }
    }

    my $total = ( keys %$res );

    # 2.4 Special case doubleIp (users connected from more than 1 IP)
    if ( $params->{doubleIp} ) {
        my %r;

        # 2.4.1 Store user IP addresses in %r
        foreach my $id ( keys %$res ) {
            my $entry = $res->{$id};
            next if ( $entry->{_httpSessionType} );
            $r{ $entry->{ $tsv->{whatToTrace} } }
              ->{ $entry->{ $self->{ipField} } }++;
        }

   # 2.4.2 Store sessions owned by users that has more than one IP address in $r
        my $r;
        $total = 0;
        foreach my $k ( keys %$res ) {
            my @tmp = keys %{ $r{ $res->{$k}->{ $tsv->{whatToTrace} } } };
            if ( @tmp > 1 ) {
                $total += 1;
                $res->{$k}->{_sessionId} = $k;
                push @{ $r->{ $res->{$k}->{ $tsv->{whatToTrace} } } },
                  $res->{$k};
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
                            session => $_->{_sessionId},
                            date    => $_->{_utime}
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
        $group =~ s/\b_whatToTrace\b/$tsv->{whatToTrace}/o;

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

        # Subnets
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

        # Simple field groupBy query
        elsif ( $group =~ /^\w+$/ ) {
            eval {
                foreach my $k ( keys %$res ) {
                    $r->{ $res->{$k}->{$group} }++;
                }
            };
            return $self->sendError( $req,
                "Use of an unexistent attribute $group to group sessions", 400 )
              if ($@);
        }
        else {
            return $self->sendError( $req, 'Syntax error in groupBy', 400 );
        }

        # Build result
        $res = [
            sort { $a->{value} cmp $b->{value} }
            map { { value => $_, count => $r->{$_} } } keys %$r
        ];
    }

    # Else if "orderBy" is asked, $res elements will be like:
    #   { uid => 'foo.bar', session => <sessionId> }
    elsif ( my $f = $req->params('orderBy') ) {
        my @fields = split /,/, $f;
        my @r = map {
            my $tmp = { session => $_ };
            foreach my $f (@fields) {
                my $s = $f;
                $s =~ s/^net4\((\w+)\)$/$1/;
                $tmp->{$s} = $res->{$_}->{$s};
            }
            $tmp
        } keys %$res;
        while ( my $f = pop @fields ) {
            $f =~ s/^_whatToTrace$/$tsv->{whatToTrace}/o;
            if ( $f =~ s/^net4\((\w+)\)$/$1/ ) {
                @r = sort {
                    my @a = split /\./, $a->{$f};
                    my @b = split /\./, $b->{$f};
                    my $cmp = 0;
                  F: for ( my $i = 0 ; $i < 4 ; $i++ ) {
                        if ( $a[$i] != $b[$i] ) {
                            $cmp = $a[$i] <=> $b[$i];
                            last F;
                        }
                    }
                    $cmp;
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
              map { { session => $_, date => $res->{$_}->{_utime} } }
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

sub delSession {
    my ( $self, $req ) = @_;
    return $self->sendJSONresponse( $req, { result => 1 } )
      if ( $self->{demoMode} );
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );
    my $id = $req->params('sessionId')
      or return $self->sendError( $req, 'sessionId is missing', 400 );
    my $session = $self->getApacheSession( $mod, $id );
    $session->remove;
    if ( $session->error ) {
        return $self->sendError( $req, $session->error, 200 );
    }
    return $self->sendJSONresponse( $req, { result => 1 } );
}

sub session {
    my ( $self, $req, $id, $skey ) = @_;
    my ( %h, $res );
    my $mod = $self->getMod($req)
      or return $self->sendError( $req, undef, 400 );

    # Try to read session
    my $apacheSession = $self->getApacheSession( $mod, $id )
      or return $self->sendError( $req, undef, 400 );

    my %session = %{ $apacheSession->data };

    foreach my $k ( keys %session ) {
        $session{$k} = '**********'
          if ( $self->{hiddenAttributes} =~ /\b$k\b/ );
        $session{$k} = [ split /$self->{multiValuesSeparator}/o, $session{$k} ]
          if ( $session{$k} =~ /$self->{multiValuesSeparator}/o );
    }

    if ($skey) {
        return $self->sendJSONresponse( $req, $session{$skey} );
    }
    else {
        return $self->sendJSONresponse( $req, \%session );
    }

    # TODO: check for utf-8 problems
}

sub getApacheSession {
    my ( $self, $mod, $id ) = @_;
    my $apacheSession = Lemonldap::NG::Common::Session->new(
        {
            storageModule        => $mod->{module},
            storageModuleOptions => $mod->{options},
            cacheModule          => $tsv->{sessionCacheModule},
            cacheModuleOptions   => $tsv->{sessionCacheOptions},
            id                   => $id,
            kind                 => $mod->{kind},
        }
    );
    if ( $apacheSession->error ) {
        $self->error( $apacheSession->error );
        return undef;
    }
    return $apacheSession;
}

sub getMod {
    my ( $self, $req ) = @_;
    my ( $s, $m );
    unless ( $s = $req->params('sessionType') ) {
        $self->error('Session type is required');
        return ();
    }
    unless ( $m = $self->conf->{$s} ) {
        $self->error('Unknown (or unconfigured) session type');
        return ();
    }
    return $m;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Sessions - Sessions explorer component of
L<Lemonldap::NG::Manager>.

=head1 SYNOPSIS

See L<Lemonldap::NG::Manager>.

=head1 DESCRIPTION

Lemonldap::NG::Manager provides a web interface to manage Lemonldap::NG Web-SSO
system.

The Perl part of Lemonldap::NG::Manager is the REST server. Web interface is
written in Javascript, using AngularJS framework and can be found in `site`
directory. The REST API is described in REST-API.md file given in source tree.

Lemonldap::NG Manager::Sessions provides the sessions explorer part.

=head1 ORGANIZATION

Lemonldap::NG Manager::Sessions is the only one module used to explore sessions.
The javascript part is in `site/static/js/sessions.js` file.

=head1 SEE ALSO

L<Lemonldap::NG::Manager>, L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item Clement Oudot, E<lt>clem.oudot@gmail.comE<gt>

=item François-Xavier Deltombe, E<lt>fxdeltombe@gmail.com.E<gt>

=item Xavier Guimard, E<lt>x.guimard@free.frE<gt>

=item Thomas Chemineau, E<lt>thomas.chemineau@gmail.comE<gt>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

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
