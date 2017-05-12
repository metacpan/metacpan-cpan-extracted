package Test::MockBank::BankOfIreland;

use strict;
use warnings;

use base qw( Test::MockBank );

use HTTP::Status;
use HTTP::Response;

use Finance::Bank::IE::BankOfIreland;

my $pages = Finance::Bank::IE::BankOfIreland::_pages();

sub request {
    my ( $self, $response ) = @_;

    my $request = $response->request();

    my @args;
    my @args_and_equals;
    my ( $url, $content ) = split( /\?/, $request->uri, 2 );
    $content ||= "";
    if ( $request->method eq 'POST' ) {
        $content = join( '&', $content, $request->content );
    }
    if ( $content ) {
        my @args_and_equals = split( /\&/, $content );
        for my $arg_and_equals ( @args_and_equals ) {
            my ( $key, $value ) = split( /=/, $arg_and_equals, 2 );
            push @args, [ $key, $value ];
        }
    }

    # business logic
    # Credentials expiry - no state
    if ( $url eq $pages->{expired}->{url} ) {
        print STDERR "# early return: expired session\n" if $ENV{DEBUG};
        return $self->SUPER::request($response, 'BankOfIreland' );
    }

    my $execution = $self->get_param( 'execution', \@args ) || 'e0s0';
    print STDERR "#  Looking for $url, $execution (from " . $request->uri . ")\n" if $ENV{DEBUG};

    # Bad Credentials page shouldn't need any state
    # unpleasantly, it does
    if ( $url eq $pages->{badcreds}->{url} and $execution eq 'e1s4') {
        print STDERR "# early return: bad creds\n" if $ENV{DEBUG};
        return $self->SUPER::request($response, 'BankOfIreland' );
    }

    if ( $url eq $pages->{login}->{url} ) {
        if ( $execution =~ /s[01]$/ ) {
            if ( $execution eq 'e0s0' or
                 ( $execution =~ /s1$/ and !$self->get_param( 'form:userId', \@args ))) {
                $request->uri( $request->uri . "?execution=e1s1" );
                $response = $self->SUPER::request( $response, 'BankOfIreland' );
                Test::MockBank->globalstate( 'loggedin', 1 );
                return $response;
            } else {
                if ( Test::MockBank->globalstate('loggedin') != 1 ) {
                    print STDERR "# login state " . Test::MockBank->globalstate('loggedin') . ", expected 1\n" if $ENV{DEBUG};
                    $response->code( RC_FOUND );
                    $response->header( 'Location' => $pages->{expired}->{url} );
                    Test::MockBank->globalstate( 'loggedin', 0 );
                    return $response;
                }
                my $user = $self->get_param( 'form:userId', \@args );
                my $pass = $self->get_param( 'form:phoneNumber', \@args );
                if ( !defined($pass )) {
                    $pass = join( '/',
                                  $self->get_param( 'form:dateOfBirth_date', \@args ),
                                  $self->get_param( 'form:dateOfBirth_month', \@args ),
                                  $self->get_param( 'form:dateOfBirth_year', \@args )
                                );
                }
                $response = $self->SUPER::request( $response, 'BankOfIreland' );
                Test::MockBank->globalstate('user', $user);
                Test::MockBank->globalstate('pass', $pass );
                Test::MockBank->globalstate('loggedin', 2);
                $response->code( RC_FOUND );
                $response->header( 'Location' => $pages->{login2}->{url} .
                                   "?execution=e1s2" );
                return $response;
            }
        } elsif ( $execution =~ /s2$/ ) {
            if ( Test::MockBank->globalstate('loggedin') != 2 ) {
                print STDERR "# login state " . Test::MockBank->globalstate('loggedin') . ", expected 2\n" if $ENV{DEBUG};
                $response->code( RC_FOUND );
                $response->header( 'Location' => $pages->{expired}->{url} );
                Test::MockBank->globalstate( 'loggedin', 0 );
                return $response;
            }
            if ( $self->get_param( 'form:continue', \@args )) {
                my $digits_ok = 0;
                my $digits_submitted = 0;
                my $expected = Test::MockBank->globalstate( 'config' )->{pin};

                for my $index ( 1..6 ) {
                    my $digit = $self->get_param( 'form:security_number_digit' . $index, \@args );
                    if ( defined( $digit )) {
                        $digits_submitted++;
                        if ( substr( $expected, $index - 1, 1 ) eq $digit ) {
                            $digits_ok++;
                        }
                    }
                }

                if ( Test::MockBank->globalstate( 'user' ) ne Test::MockBank->globalstate( 'config')->{user} or
                     ( Test::MockBank->globalstate( 'pass' ) ne Test::MockBank->globalstate( 'config')->{dob} and
                       Test::MockBank->globalstate('pass') ne Test::MockBank->globalstate('config')->{'contact'}) or
                     $digits_ok != 3 ) {

                    print STDERR "# bad login details, returning badcreds page\n" if $ENV{DEBUG};
                    $response->code( RC_FOUND );
                    $response->header( 'Location' => $pages->{badcreds}->{url} . "?execution=e1s4" );

                    Test::MockBank->globalstate('loggedin', 0);
                    return $response;
                } elsif ( $digits_submitted != 3 ) {
                    # need to capture pages for this
                    die "not enough digits ($digits_submitted)";
                } else {
                    $response->code( RC_FOUND );
                    $response->header( 'Location' => $pages->{accounts}->{url});
                    return $response;
                }
            } else {
                # just return the login-2 page
                $response = $self->SUPER::request( $response, 'BankOfIreland' );
                return $response;
            }
        }
    }

    if ( !Test::MockBank->globalstate( 'loggedin' )) {
        $response->code( RC_FOUND );
        $response->header( 'Location' => $pages->{expired}->{url} );
        Test::MockBank->globalstate( 'loggedin', 0 );
        return $response;
    } elsif ( Test::MockBank->globalstate('loggedin') == 1 ) {
        print STDERR "Can't happen\n" if $ENV{DEBUG};
        die;
    } else {
        if ( $url eq $pages->{manageaccounts}->{url} and
             $request->method eq 'POST' and
             $self->get_param( 'form:managePayees', \@args )) {
            $response->code( RC_FOUND );
            $response->header( 'Location' => $pages->{managepayees}->{url} );
            return $response;
        } else {
            # this is how they should all work...
            my ( $page ) = $request->uri =~ m@/(\w+)\?@;
            my ( $e, $s ) = $execution =~ /e(\d+)s(\d+)/;

            if ( $page eq 'moneyTransfer' ) {
                # TODO: make these check inputs and respond appropriately
                if ( $s == 1 ) {
                    if ( $self->get_param( 'form:domesticPayment', \@args )) {
                        ( my $responsepage = $request->uri ) =~ s/s1$/s2/;
                        $response->code( RC_FOUND );
                        $response->header( 'Location' => $responsepage );
                        return $response;
                    }
                } elsif ( $s == 2 ) {
                    if ( $self->get_param( 'form:formActions:continue', \@args )) {
                        ( my $responsepage = $request->uri ) =~ s/s2$/s3/;
                        $response->code( RC_FOUND );
                        $response->header( 'Location' => $responsepage );
                        return $response;
                    }
                } elsif ( $s == 3 ) {
                    if ( $self->get_param( 'form:formActions:continue', \@args )) {
                        ( my $responsepage = $request->uri ) =~ s/s3$/s4/;
                        $response->code( RC_FOUND );
                        $response->header( 'Location' => $responsepage );
                        return $response;
                    }
                } elsif ( $s == 4 ) {
                    if ( $self->get_param( 'form:formActions:continue', \@args )) {
                        ( my $responsepage = $request->uri ) =~ s/s4$/s5/;
                        $response->code( RC_FOUND );
                        $response->header( 'Location' => $responsepage );

                        return $response;
                    }
                }
            }
            $response = $self->SUPER::request( $response, 'BankOfIreland' );
        }
    }

    $response;
}
1;
