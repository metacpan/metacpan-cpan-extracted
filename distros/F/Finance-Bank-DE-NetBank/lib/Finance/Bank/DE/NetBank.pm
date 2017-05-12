package Finance::Bank::DE::NetBank;

use strict;
use vars qw($VERSION $DEBUG);
use base qw(Class::Accessor);
Finance::Bank::DE::NetBank->mk_accessors(
    qw(BASE_URL BLZ CUSTOMER_ID PASSWORD AGENT_TYPE AGENT ACCOUNT Debug));

use WWW::Mechanize;
use Text::CSV_XS;
use Data::Dumper;

$| = 1;

$VERSION = "1.05";

sub Version {
    return $VERSION;
}

sub new {
    my $proto  = shift;
    my %values = (
        AGENT_TYPE => "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)",
        BASE_URL =>
          'https://www.netbank-money.de/netbank-barrierefrei-banking/view/',
        BLZ         => '20090500', # NetBank BLZ
        CUSTOMER_ID => '',
        PASSWORD    => '',
        ACCOUNT     => '', 
        @_
    );

    my $class = ref($proto) || $proto;
    my $parent = ref($proto) && $proto;

    my $self = {};
    bless( $self, $class );

    foreach my $key ( keys %values ) {
        $self->$key("$values{$key}");
    }

    #$self->Debug(1);
    return $self;
}

sub connect {
    my $self  = shift;
    print STDERR "Method connect() is deprecated. Use only login() instead!\n";
    return $self->login(@_);
}

sub login {
    my $self   = shift;
    my %values = (
        CUSTOMER_ID => $self->CUSTOMER_ID(),
        PASSWORD    => $self->PASSWORD(),
        @_
    );
   
    my $url   = $self->BASE_URL() . "index.jsp?blz=" . $self->BLZ() . "&graphics=false";
    my $agent = WWW::Mechanize->new( agent => $self->AGENT_TYPE(), );
    $agent->{agent} = "";
    $agent->get($url);
    $self->AGENT($agent);

    $agent->field( "kundennummer", $values{'CUSTOMER_ID'} );
    $agent->field( "pin",          $values{'PASSWORD'} );
    $agent->click();

    print STDERR Dumper( $agent->content ) if $self->Debug();
    
    if ($agent->content =~ /fieldtableerrorred/ig) {
        return undef;
    }

    return 1;
 
}

sub saldo {
    my $self = shift;
    my $data = $self->statement(@_);
   
    if ($data) { 
        print STDERR Dumper($data) if $self->Debug();
        return $data->{'STATEMENT'}{'SALDO'};
    } else {
        return undef;
    }
}

sub statement {
    my $self   = shift;
    my %values = (
        TIMEFRAME => "30"
        , # 1 or 30 days || "alle" = ALL || "variabel" = between START_DATE and END_DATE only
        START_DATE => 0,                  # dd.mm.yyyy
        END_DATE   => 0,                  # dd.mm.yyyy
        ACCOUNT    => $self->ACCOUNT(),
        @_
    );

    # get mainpage
    my $login_status = $self->login();
    return undef unless $login_status;
       
    my $agent = $self->AGENT();

#   If you've problems with your environmet settings activate this and "use encodings"
#   binmode(STDOUT, ":encoding(iso-8859-15)");

    $agent->field( "kontonummer", $values{'ACCOUNT'} );
    $agent->field( "zeitraum",    $values{'TIMEFRAME'} );

    if (   $values{'TIMEFRAME'} eq "variabel"
        && $values{'START_DATE'}
        && $values{'END_DATE'} )
    {
        $agent->field( "startdatum", $values{'START_DATE'} );
        $agent->field( "enddatum",   $values{'END_DATE'} );
    }

    $agent->click();
    $agent->get( $self->BASE_URL() . "umsatzdownload.do" );

    my $content = $agent->content();
    print STDERR Dumper($content) if $self->Debug();

    my $csv_content = $self->_parse_csv($content);
    return $csv_content;
}

sub transfer {
    my $self   = shift;
    my %values = (
        SENDER_ACCOUNT   => $self->ACCOUNT(),
        RECEIVER_NAME    => "",
        RECEIVER_ACCOUNT => "",
        RECEIVER_BLZ     => "",
        RECEIVER_SAVE    => "false",
        COMMENT_1        => "",
        COMMENT_2        => "",
        AMOUNT           => "0.00",
        TAN              => "",
        @_
    );
    
    # get mainpage
    my $login_status = $self->login();
    return undef unless $login_status;

    my $agent = $self->AGENT();
    my $url   = $self->BASE_URL();

    $agent->get($url . "ueberweisung_per_heute_neu.do");

    ( $values{'AMOUNT_EURO'}, $values{'AMOUNT_CENT'} ) =
      split( /\.|,/, $values{'AMOUNT'} );
    
    $values{'AMOUNT_CENT'} = sprintf("%02d", $values{'AMOUNT_CENT'});

    $agent->field("auftraggeberKontonummer", $values{'SENDER_ACCOUNT'});
    $agent->field("empfaengerName",          $values{'RECEIVER_NAME'});
    $agent->field("empfaengerBankleitzahl",  $values{'RECEIVER_BLZ'});
    $agent->field("empfaengerKontonummer",   $values{'RECEIVER_ACCOUNT'});
    $agent->field("betragEuro",              $values{'AMOUNT_EURO'});
    $agent->field("betragCent",              $values{'AMOUNT_CENT'});
    $agent->field("verwendungszweck1",       $values{'COMMENT_1'});
    $agent->field("verwendungszweck2",       $values{'COMMENT_2'});
    $agent->click("btnNeuSpeichern");

    # get TAN fieldname, index
    my $tan_field;
    my $tan_index;
    my $tan;
    
    $agent->content =~ /<label\s*for=["']*(.*?)["']\s*>(?:Tr|TAN)(?:[a-z].*?)\s?(\d+)/gmix;
   
    $tan_field = $1;
    $tan_index = $2;
   
    print STDERR "tan_field: $tan_field, tan_index: $tan_index\n" if $self->Debug();
    
    if ($tan_field && $tan_index && ref($values{'TAN'}) eq "HASH" && $values{'TAN'}->{$tan_index}) {
        print STDERR "METHOD: TAN HASH" if $self->Debug();
        $tan = $values{'TAN'}->{$tan_index};
    } elsif ($tan_field && $tan_index && ref($values{'TAN'}) eq "ARRAY") {
        print STDERR "METHOD: Object/Method" if $self->Debug();
        my $obj    = $values{'TAN'}[0];
        my $method = $values{'TAN'}[1];
        eval ( $tan = $obj->$method() );
        if ($@) {
            print "ERROR: Could not execute TAN method: $method";
            return undef;
        }
    } elsif ($tan_field && $tan_index && ref($values{'TAN'}) eq "CODE") {
        print STDERR "METHOD: CALLBACK" if $self->Debug();
        $tan = &{$values{'TAN'}}($tan_index);
    }

    print STDERR " TAN: [$tan]\n" if $self->Debug();
    
    if ($tan) {
	    $agent->field($tan_field, $tan_index);
	    $agent->click("btnBestaetigen");

        # lazy error checking
        if ( $agent->content() =~ m|<span class="error">(.*)30017(.*)</span>| ) {
            $agent->content() =~ m|<span class="error">(.*?)</span>|;
            my $error = $1;
            print "ERROR: $error";
            return;
        } else {
            my $content = $agent->content();
            return $agent->content();
        }
    } else {
        print "ERROR: Could not identify requested TAN Index #";
        return;
    }
}

sub logout {
    my $self  = shift;
    my $agent = $self->AGENT();
    my $url   = $self->BASE_URL();
    $agent->get( $url . "logout.do" );
}

sub _parse_csv {
    my $self        = shift;
    my $csv_content = shift;
    $csv_content =~ s/\r//gmi;
    $csv_content =~ s/\f//gmi;
    my @lines = split( "\n", $csv_content );
    my %data;

    my $csv = Text::CSV_XS->new(
        {
            sep_char => "\t",
            binary   => 1,      ### german umlauts...
        }
    );

    my $line_count = 0;

    foreach my $line (@lines) {
        my $status  = $csv->parse($line);
        my @columns = $csv->fields();
        $line_count++;

        ### Account Details ########################
        if ( $line_count > 3 && $line_count < 6 ) {
            $columns[0] =~ s/://;
            $data{"ACCOUNT"}{ uc( $columns[0] ) } = $columns[1];
        }

        ### Statement Details ######################
        if ( $line_count == 9 ) {
            $data{"STATEMENT"}{"START_DATE"} = $columns[0];
            $data{"STATEMENT"}{"END_DATE"}   = $columns[1];
            $data{"STATEMENT"}{"ACCOUNT_ID"} = $columns[2];
            $data{"STATEMENT"}{"SALDO"}      = $columns[3];
            $data{"STATEMENT"}{"WAEHRUNG"}   = $columns[4];
        }

        ### Transactions ###########################
        if ( $line_count > 12 && $line_count <= $#lines ) {
            my $row = $line_count - 13;
            $data{"TRANSACTION"}[$row]{"BUCHUNGSTAG"}      = $columns[0];
            $data{"TRANSACTION"}[$row]{"WERTSTELLUNGSTAG"} = $columns[1];
            $data{"TRANSACTION"}[$row]{"VERWENDUNGSZWECK"} = $columns[2];

            $columns[3] =~ s/\.//;
            $columns[3] =~ s/,/\./;

            $data{"TRANSACTION"}[$row]{"UMSATZ"}           = $columns[3];
            $data{"TRANSACTION"}[$row]{"WAEHRUNG"}         = $columns[4];
            $data{"TRANSACTION"}[$row]{"NOT_YET_FINISHED"} = $columns[5]
              if ( defined( $columns[5] ) && $columns[5] =~ m/^[^\s]$/ig );
        }
    }

    return \%data;
}

1;
__END__

=head1 NAME

Finance::Bank::DE::NetBank - Check your NetBank Bank Accounts with Perl

=head1 SYNOPSIS

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

=head1 DESCRIPTION


This module provides a very limited interface to the webbased online banking
interface of the German "NetBank e.G." operated by Sparda-Datenverarbeitung e.G..

B<WARNING!> This module is neither offical nor is it tested to be 100% save! 
Because of the nature of web-robots, B<everything may break from one day to
the other> when the underlaying web interface changes.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

You can find tests in the C< t > subdirectory. See L< TESTS > for more details.

=head1 METHODS

=head2 my $account = Finance::Bank::DE::NetBank->new(%values) 

This constructor will set the default values and/or user provided values for
connection and authentication.

    my $account = Finance::Bank::DE::NetBank->new (
        CUSTOMER_ID => 'demo',    
        PASSWORD => '',      
        ACCOUNT => '2777770',   
        @_);

If you don't provide any values the module will automatically use the demo account.

CUSTOMER_ID is your "Kundennummer" and ACCOUNT is the "Kontonummer" 
(if you have only one account you can skip that)

=head2 $account->Version()

returns the module version

=head2 $account->Debug($value)

Provide a true  C< $value > get some Data::Dumper outputs on STDERR.

=head2 $account->connect()

deprecated. use only $account->login()

=head2 $account->login(%values)

This method will try to log in with the provided authentication details. If
nothing is specified the values from the constructor or the defaults will be used.

    $account->login(ACCOUNT => '1234');

Returns C< undef > on error.

=head2 $account->saldo(%values)

This method will return the current account balance called "Saldo".
The method uses the account number if previously set. 

You can override/set it:

    $account->saldo(ACCOUNT => '5555555');

Returns C< undef > on error.

=head2 $account->statement(%values)

This method will retrieve an account statement (Kontoauszug) and return a hashref.

You can specify the timeframe of the statement by passing different arguments:
The value of TIMEFRAME can be "1" (last day only), "30" (last 30 days only), "alle" (all possible) or "variable" (between
START_DATE and END_DATE only).

    $account->statement(
        TIMEFRAME => 'variabel',
        START_DATE => '10.04.2005',
        END_DATE => '02.05.2005',
    );

Returns C< undef > on error.

=head2 $account->transfer()

Returns C< undef > on error.

=head2 $account->logout()

well - every login method should have a logout method

=head1 TESTS

Since version 1.04 C<Finance::Bank::DE::NetBank> comes with a testsuite.
It's located in the subdirectory C< t > of the distribution.

To run the tests against the live NetBank demo account use this:

    perl Makefile.PL --livetest
    make test TEST_VERBOSE=1

The default behaviour is not to test against the live website:

    perl Makefile.PL
    make test


=head1 BUGS

Please report bugs via 
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-DE-NetBank>
or email the author.

=head1 HISTORY

see file 'Changes'

=head1 THANK YOU

Torsten Mueller (updated URL, saldo() bug reporting)

Sascha Stock (reported bad example in POD)

=head1 AUTHOR

Roland Moriz (RMORIZ) <rmoriz@cpan.org>

http://www.perl-freelancer.de/ 

http://www.roland-moriz.de/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

WWW::Mechanize

=cut

