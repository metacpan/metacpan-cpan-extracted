## @file
# OpenID SREG extension for Lemonldap::NG::Portal::IssuerOpenID class

## @class
# OpenID SREG extension for Lemonldap::NG::Portal::IssuerOpenID class

package Lemonldap::NG::Portal::OpenID::SREG;

use strict;
use Lemonldap::NG::Common::Regexp;
use Lemonldap::NG::Portal::Simple;
use utf8;

## @method protected hash sregHook(hash prm)
# Hook called to add SREG parameters to the OpenID response
# @return Hash containing wanted parameters
sub sregHook {
    my ( $self, $u, $trust_root, $is_id, $is_trusted, $prm ) = @_;
    my ( @req, @opt );

    # Refuse federation if rejected by user
    if ( $self->param('confirm') == -1 ) {
        my %h;
        $h{$_} = undef foreach (
            qw(fullname nickname language postcode timezone country gender email dob)
        );
        $self->updatePersistentSession( \%h );
        return 0;
    }

    # If identity is not trusted, does nothing
    return ( 0, $prm ) unless ( $is_id and $is_trusted );

    $self->lmLog( "SREG start", 'debug' );

    my $accepted = 1;

    # Check all parameters
    while ( my ( $k, $v ) = each %$prm ) {

        # Store policy if provided
        if ( $k eq 'policy_url' ) {
            if ( $v =~ Lemonldap::NG::Common::Regexp::HTTP_URI ) {
                $self->{_openIdTrustExtMsg} .=
                    '<dl><dt>'
                  . $self->msg(PM_OPENID_PA)
                  . "&nbsp;:</dt><dd><a href=\"$v\">$v</a></dd></dl>";

                # Question: is it important to notify policy changes ?
                # if yes, uncomment this
                #my $p =
                #  $self->{sessionInfo}->{"_openidTrust$trust_root\_Policy"};
                #$accepted = 0 unless ( $p and $p eq $v );
            }
            else {
                $self->lmLog( "Bad policy url", 'error' );
            }
        }

        # Parse required attributes
        elsif ( $k eq 'required' ) {
            $self->lmLog( "Required attr $v", 'debug' );
            push @req, split( /,/, $v );
        }

        # Parse optional attributes
        elsif ( $k eq 'optional' ) {
            $self->lmLog( "Optional attr $v", 'debug' );
            push @opt, grep { defined $self->{"openIdSreg_$trust_root$_"} }
              split( /,/, $v );
        }
        else {
            $self->lmLog( "Unknown OpenID SREG request $k", 'error' );
        }
    }

    # Check if required keys are valid SREG requests
    # Question: reject bad SREG request ? Not done yet
    @req = sregfilter( $self, @req );
    @opt = sregfilter( $self, @opt );

    # Return if nothing is asked
    return ( 1, {} ) unless ( @req or @opt );

    # If a required data is not available, returns nothing
    foreach my $k (@req) {
        unless ( $self->{"openIdSreg_$k"} ) {
            $self->lmLog(
"Parameter $k is required by $trust_root but not defined in configuration",
                'notice'
            );

            $self->info(
                '<h3>' . sprintf( $self->msg(PM_OPENID_RPNS), $k ) . '</h3>' );
            return ( 0, {} );
        }
    }

    # Now set datas
    my ( %r, %msg, %ag, %toStore );

    # Requested parameters: check if already agreed or confirm is set
    foreach my $k (@req) {
        my $agree = $self->{sessionInfo}->{"_openidTrust$trust_root\_$k"};
        if ($accepted) {
            unless ( $self->param('confirm') or $agree ) {
                $accepted = 0;
            }
            elsif ( !$agree ) {
                $toStore{"_openidTrust$trust_root\_$k"} = 1;
            }
        }
        $self->{"openIdSreg_$k"} =~ s/^\$//;
        $msg{req}->{$k} = $r{$k} =
          $self->{sessionInfo}->{ $self->{"openIdSreg_$k"} } || '';
    }

    # Optional parameters:
    foreach my $k (@opt) {
        $self->{"openIdSreg_$k"} =~ s/^\$//;
        my $agree = $self->{sessionInfo}->{"_openidTrust$trust_root\_$k"};
        if ($accepted) {

            # First, check if already accepted
            unless ( $self->param('confirm') or defined($agree) ) {
                $accepted = 0;
                $r{$k} = $self->{sessionInfo}->{ $self->{"openIdSreg_$k"} }
                  || '';
            }

            # If confirmation is returned, check the value for this field
            elsif ( $self->param('confirm') == 1 ) {
                my $ck = 0;
                if ( defined( $self->param("sreg_$k") ) ) {
                    $ck = ( $self->param("sreg_$k") eq 'OK' ) || 0;
                }

                # Store the value returned
                if ( !defined($agree) or $agree != $ck ) {
                    $toStore{"_openidTrust$trust_root\_$k"} = $ck;
                    $agree = $ck;
                }
            }
        }

        $msg{opt}->{$k} = $self->{sessionInfo}->{ $self->{"openIdSreg_$k"} }
          || '';

        # Store the value only if user agree it
        if ($agree) {
            $r{$k}  = $msg{opt}->{$k};
            $ag{$k} = 1;
        }
        elsif ( !defined($agree) ) {
            $ag{$k} = 1;
        }
        else {
            $ag{$k} = 0;
        }
    }
    $self->updatePersistentSession( \%toStore ) if (%toStore);

    # Check if user has agreed request
    if ($accepted) {
        $self->_sub( 'userInfo',
            $self->{sessionInfo}->{ $self->{whatToTrace} }
              . " has accepted OpenID SREG exchange with $trust_root" );
        return ( 1, \%r );
    }

    # else build message and return 0
    else {

        $self->{_openIdTrustExtMsg} .=
          "<h3>" . $self->msg(PM_OPENID_AP) . "</h3>\n";

        $self->{_openIdTrustExtMsg} .= "<table class=\"openidsreg\">\n";

        # No choice for requested parameters: just an information
        foreach my $k (@req) {
            utf8::decode( $msg{req}->{$k} );
            $self->{_openIdTrustExtMsg} .=
                "<tr class=\"required\">\n" . "<td>"
              . "<input type=\"checkbox\" disabled=\"disabled\" checked=\"checked\"/>"
              . "</td>\n"
              . "<td>$k</td>\n" . "<td>"
              . $msg{req}->{$k}
              . "</td>\n"
              . "</tr>\n";
        }

        # For optional parameters: checkboxes are displayed
        foreach my $k (@opt) {
            utf8::decode( $msg{opt}->{$k} );
            $self->{_openIdTrustExtMsg} .=
                "<tr class=\"optional\">\n"
              . "<td>\n"
              . "<input type=\"checkbox\" value=\"OK\""
              . ( $ag{$k} ? 'checked="checked"' : '' )
              . " name=\"sreg_$k\" />"
              . "</td>\n"
              . "<td>$k</td>\n" . "<td>"
              . $msg{opt}->{$k}
              . "</td>\n"
              . "</tr>\n";
        }

        $self->{_openIdTrustExtMsg} .= "</table>\n";

        $self->lmLog( 'Building validation form', 'debug' );
        return ( 0, $prm );
    }
}

## @method private array sregfilter(array attr)
# Filter the arguments passed as parameters by checking their compliance with
# SREG.
# @return fitered datas
sub sregfilter {
    my ( $self, @attr ) = @_;
    my ( @ret, @rej );

    # Browse attributes
    foreach my $s (@attr) {
        if ( $s =~
/^(?:(?:(?:full|nick)nam|languag|postcod|timezon)e|country|gender|email|dob)$/
          )
        {
            push @ret, $s;
        }
        else {
            $s =~ s/\W/\./sg;
            push @rej, $s;
        }
    }

    # Warn if some parameters are rejected
    if (@rej) {
        $self->lmLog(
            "Requested parameter(s) "
              . join( ',', @rej )
              . "is(are) not valid OpenID SREG parameter(s)",
            'warn'
        );
    }

    # Return valid SREG parameters
    return @ret;
}
1;
