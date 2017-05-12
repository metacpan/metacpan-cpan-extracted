NAME
    Finance::Bank::DE::NetBank - Check your NetBank Bank Accounts with Perl

SYNOPSIS
        use Finance::Bank::DE::NetBank;
    
        my $account = Finance::Bank::DE::NetBank->new(
            CUSTOMER_ID => '12345678',
            ACCOUNT => '12345678',
            PASSWORD => 'ROUTE66',
        );
    
        if ($account->login()) {
            print $account->saldo();
            $account->logout();
        } 
        else {
            print 'login failed. manual interaction needed';
        }

DESCRIPTION
    This module provides a very limited interface to the webbased online
    banking interface of the German "NetBank e.G." operated by
    Sparda-Datenverarbeitung e.G..

    WARNING! This module is neither offical nor is it tested to be 100%
    save! Because of the nature of web-robots, everything may break from one
    day to the other when the underlaying web interface changes.

    This is code for online banking, and that means your money, and that
    means BE CAREFUL. You are encouraged, nay, expected, to audit the source
    of this module yourself to reassure yourself that I am not doing
    anything untoward with your banking data. This software is useful to me,
    but is provided under NO GUARANTEE, explicit or implied.

    You can find tests in the " t " subdirectory. See TESTS for more
    details.

METHODS
  my $account = Finance::Bank::DE::NetBank->new(%values)
    This constructor will set the default values and/or user provided values
    for connection and authentication.

        my $account = Finance::Bank::DE::NetBank->new (
            CUSTOMER_ID => 'demo',    
            PASSWORD => '',      
            ACCOUNT => '2777770',   
            @_);

    If you don't provide any values the module will automatically use the
    demo account.

    CUSTOMER_ID is your "Kundennummer" and ACCOUNT is the "Kontonummer" (if
    you have only one account you can skip that)

  $account->Version()
    returns the module version

  $account->Debug($value)
    Provide a true $value get some Data::Dumper outputs on STDERR.

  $account->connect()
    deprecated. use only $account->login()

  $account->login(%values)
    This method will try to log in with the provided authentication details.
    If nothing is specified the values from the constructor or the defaults
    will be used.

        $account->login(ACCOUNT => '1234');

    Returns " undef " on error.

  $account->saldo(%values)
    This method will return the current account balance called "Saldo". The
    method uses the account number if previously set.

    You can override/set it:

        $account->saldo(ACCOUNT => '5555555');

    Returns " undef " on error.

  $account->statement(%values)
    This method will retrieve an account statement (Kontoauszug) and return
    a hashref.

    You can specify the timeframe of the statement by passing different
    arguments: The value of TIMEFRAME can be "1" (last day only), "30" (last
    30 days only), "alle" (all possible) or "variable" (between START_DATE
    and END_DATE only).

        $account->statement(
            TIMEFRAME => 'variabel',
            START_DATE => '10.04.2005',
            END_DATE => '02.05.2005',
        );

    Returns " undef " on error.

  $account->transfer()
    Returns " undef " on error.

  $account->logout()
    well - every login method should have a logout method

TESTS
    Since version 1.04 "Finance::Bank::DE::NetBank" comes with a testsuite.
    It's located in the subdirectory " t " of the distribution.

    To run the tests against the live NetBank demo account use this:

        perl Makefile.PL --livetest
        make test TEST_VERBOSE=1

    The default behaviour is not to test against the live website:

        perl Makefile.PL
        make test

BUGS
    Please report bugs via
    <http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-DE-NetBank> or
    email the author.

HISTORY
    see file 'Changes'

THANK YOU
    Torsten Mueller (updated URL, saldo() bug reporting)

    Sascha Stock (reported bad example in POD)

AUTHOR
    Roland Moriz (RMORIZ) <rmoriz@cpan.org>

    http://www.perl-freelancer.de/

    http://www.roland-moriz.de/

COPYRIGHT
    This program is free software; you can redistribute it and/or modify it
    under the same terms as Perl itself.

SEE ALSO
    WWW::Mechanize

