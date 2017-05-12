package Domain::Register::TK;

use strict;
use warnings;

=head1 NAME

Domain::Register::TK - an interface to Dot TK's Reseller API Program

=cut

our $VERSION = '2.1';

=head1 VERSION

Version 2.1

=cut

use LWP::UserAgent;
use XML::Simple;

# if you're browsing this, please note: you also need a library to allow LWP to use SSL.
# Crypt::SSLeay or OpenSSL, for example

=head1 SYNOPSIS

This module allows developers to create and maintain domains within the .TK 
name space, using Dot TK's reseller program API, without having to know the 
details of how the API program works.  Domains can be checked (with price 
provided in local currency) and updated, including using URL forwarding 
services, or manipulating nameserver references

=head1 DESCRIPTION

Dot TK has an extensive Application Programming Interface (API) that allows 
you to administer your domains simply and effectively. Designed for large 
portfolio resellers, the Dot TK API will allow you to automate functions and
reduce the time needed to manage your Dot TK Reseller account.

This version of the Dot TK API allows you to use the API as a Perl library 
without needing to understand the complexities of the regular API. This 
document, however, just handles the Perl library for this API. For more 
complete documentation of the functions, see the main API documentation.

=head1 DEPENDENCIES

This module relies on C<XML::Simple> and C<LWP>. In addition it requires that
LWP be installed with an additional library to handle secure connections.
C<OpenSSL> or C<Crypt::SSL> are suggested as possibilities.

=head1 SUBROUTINES/METHODS

An object of this class represents a potential dialogue with Dot TK's servers,
and as such needs correct log in credentials to do anything useful.

Standard usage is to create an object, supply that object with log in
credentials, and perform an arbitrary number of transactions with the remote
server. There is a ping transaction which does not require parameters, that
should be used to test if a connection is still possible. It is possible to
change credentials after some operations (if, for example, different
currencies were being used for different end-users) without having to create
a new object.

No state is saved by the remote server between transactions, so it is not
necessary to log on or log off separately, as long as valid credentials are
supplied.

=head2 Setting Up

Simply create an object from the library, and pass the email address and 
password of your reseller account to it.

 use Domain::Register::TK;
 my $api_object = Domain::Register::TK->new();
 $api_object->credentials('login@email.com', 'mypassword');

=head2 General error handling

Every request made after setup will return values, in addition to setting
internal variables to hold the status (accessible via functions)
 
 # for example (more details on this operation later)
 $api_object->availability_check('DOT.TK');
 print $api_object->status . ' - ' . $api_object->errstr;

The function C<status> will either return C<OK> or C<NOT OK>. If a request 
was able to be processed successfully; it will have a C<status> set to C<OK>. 
This does not mean that the request was processed (for example, if registering 
a domain that was not available), just that enough information was passed 
that it could have been. If the C<status> is C<NOT OK> there will be a 
detailed reason in the C<errstr> function, which otherwise will be C<undef>.

The values returned will be in form of a reference to an associative array, with
contents depending on the function involved.

=cut

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    return $self;
}

sub status {
    my $self = shift;
    return $self->{status};
}

sub errstr {
    my $self = shift;
    return $self->{errstr};
}

=head2 Proxy

Function: C<proxy>

Parameters: C<URL>

If you need to use a proxy server to be able to access the Dot TK server on the
internet, it can be specified here.
It should be in the form of a URL, with the port number to use.

 $api_object->proxy('https://192.168.10.1:443');

No response is given to this function, it simply sets a value that can be used by
other operations

=cut

sub proxy {
    my $self = shift;
    $self->{proxy} = shift;
    return;
}

=head2 Set Timeout

Function: C<set_timeout>

Parameters: C<TIME_IN_WHOLE_SECONDS>

By default, requests will return, giving an error state if there has been no
response from either the supplied proxy, or the Dot TK servers, in 15 seconds.
If you want to change this, pass in the required time, in seconds.

=cut

sub set_timeout {
    my $self = shift;
    $self->{timeout} = shift;
    return;
}

=head2 Ping

Function: C<ping>

Parameters: none

 $result_code = $api_object->ping();

Possible response:

 $result_code = {
          'timestamp' => '2009-07-28 14:10:28 UTC',
          'status' => 'PING REPLY',
          'type' => 'result'
        };

=cut

sub ping {
    my $self = shift;
    my $st = $self->_get_url( { function => 'ping' } );
    return $st;
}

sub credentials {
    my $self     = shift;
    my $email    = shift;
    my $password = shift;
    $self->{email}    = $email;
    $self->{password} = $password;
    return;
}

=head2 Availability Check

Function: C<availability_check>

Parameters (all compulsory): C<DOMAIN-NAME.TK>, C<PERIOD_IN_YEARS>

 # an example
 my $return_value = $api_object->availability_check('TESTDOMAIN-0001.TK',1);

Possible responses are:

 # if available to be registered, this is what the return value would look like
 $return_value = {
          'partnerrate' => '4.50',
          'status' => 'AVAILABLE',
          'retailrate' => '9.95',
          'domainname' => 'TESTDOMAIN-0001.TK',
          'currency' => 'GBP',
          'lengthofregistration' => '1',
          'type' => 'result',
          'domaintype' => 'PAID'
 };

or
 
 # if already registered:
 $return_value = {
          'status' => 'NOT AVAILABLE',
          'lengthofregistration' => '1',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0002.TK',
          'expirationdate' => '20100225'
        };

=cut

sub availability_check {
    my $self   = shift;
    my $domain = shift;
    my $length = shift;

    my $st = $self->_get_url(
        {
            function             => 'availability_check',
            domainname           => $domain,
            lengthofregistration => $length
        }
    );

    return $st;
}

=head2 Domain Registration

Function: C<register>

Parameters: (compulsory) C<DOMAIN-NAME.TK>, C<PERIOD_IN_YEARS>

Parameters: (optional) either an array reference of name servers, B<or> a URL for
forwarding, or no parameter

 # with an array of name servers
 $return_value = $api_object->register('TESTDOMAIN-0003.TK', 1, ['NS1.A.COM.TK', 'NS2.A.COM.TK']);

or

 # with a URL for forwarding
 $return_value = $api_object->register('TESTDOMAIN-0004.TK', 1, 'http://www.icann.org/');

or

 # with unused (can be set later, or just protected from other potential uses)
 $return_value = $api_object->register('TESTDOMAIN-0005.TK', 1);

Possible responses:
 
 $return value = {
          'partnerrate' => '4.50',
          'status' => 'REGISTERED',
          'retailrate' => '9.95',
          'domainname' => 'TESTDOMAIN-0004.TK',
          'expirationdate' => '20100724',
          'currency' => 'GBP',
          'lengthofregistration' => '1',
          'type' => 'result'
        };


or


 # if already registered:
 $return_value = {
          'status' => 'NOT AVAILABLE',
          'lengthofregistration' => '1',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0002.TK',
          'expirationdate' => '20100225'
        };

=cut

sub register {
    my $self          = shift;
    my $domain        = shift;
    my $length_of_reg = shift;

    my $st;

    if ( 'ARRAY' eq ref $_[0] ) {
        # list of name servers,
        my $ns = shift;
        $st = $self->_get_url(
            {
                function             => 'register',
                domainname           => $domain,
                lengthofregistration => $length_of_reg,
                nameserver           => $ns,
            }
        );
    }
    elsif ( not defined $_[0] ) {
        $st = $self->_get_url(
            {
                function             => 'register',
                domainname           => $domain,
                lengthofregistration => $length_of_reg,
            }
        );
    }
    else {
        # forwarding URL
        my $target_url = shift;
        $st = $self->_get_url(
            {
                function             => 'register',
                domainname           => $domain,
                lengthofregistration => $length_of_reg,
                forwardurl           => $target_url,
            }
        );
    }
    return $st;
}

=head2 Renewal of Domains

Function: C<renew>

Parameters: (compulsory) C<DOMAIN-NAME.TK>, C<PERIOD_IN_YEARS>

 $return_value = $api_object->renew('TESTDOMAIN-0001.TK', 3);

Possible responses:

 # if supplied domain is available
 $return_value = {
          'partnerrate' => '13.5',
          'status' => 'RENEWED',
          'retailrate' => '24.75',
          'domainname' => 'TESTDOMAIN-0001.TK',
          'expirationdate' => '20120723',
          'currency' => 'GBP',
          'lengthofregistration' => '3',
          'type' => 'result'
        };
 
 # if domain is not available
 $return_value = {
          'domainname' => 'TESTDOMAIN-0002.TK',
          'lengthofregistration' => '3',
          'status' => 'NOT AVAILABLE',
        };

=cut

sub renew {
    my $self          = shift;
    my $domain        = shift;
    my $length_of_reg = shift;
    my $st            = $self->_get_url(
        {
            function             => 'renew',
            domainname           => $domain,
            lengthofregistration => $length_of_reg,
        }
    );
    return $st;
}

=head2 Add/modify glue record

Function: C<host_registration>

Parameters: C<HOSTNAME>, C<IPADDRESS> (both are compulsory)

 $return_value = $api_object->host_registration('NS1.TESTDOMAIN-0005.TK','192.168.1.22');

Possible responses:

 $return_value = {
          'status' => 'REGISTERED',
          'type' => 'result',
          'hostname' => 'NS1.TESTDOMAIN-0005.TK',
          'ipaddress' => '192.168.1.22'
        };
 # or if this name has already been used as a glue record
 $return_value = {
          'status' => 'UPDATED',
          'type' => 'result',
          'hostname' => 'NS1.TESTDOMAIN-0005.TK',
          'ipaddress' => '192.168.1.22'
        };

This routine will use standard error messages if you attempt to add glue records to
domains not in your portfolio.

=cut

sub host_registration {
    my $self      = shift;
    my $hostname  = shift;
    my $ipaddress = shift;
    my $st        = $self->_get_url(
        {
            function  => 'host_registration',
            hostname  => $hostname,
            ipaddress => $ipaddress,
        }
    );
    return $st;
}

=head2 Remove glue record

Function: C<host_removal>

Parameters: C<HOSTNAME> (compulsory)

  $return_value = $api_object->host_removal('NS1.TESTDOMAIN-0005.TK');

Possible responses
  
 $return_value = {
          'status' => 'REMOVED',
          'type' => 'result',
          'hostname' => 'NS1.TESTDOMAIN-0003.TK'
        };

=cut

sub host_removal {
    my $self     = shift;
    my $hostname = shift;
    my $st       = $self->_get_url(
        {
            function => 'host_removal',
            hostname => $hostname,
        }
    );
    return $st;
}

=head2 List glue records

Function: C<host_list>

Parameters: C<DOMAIN> (compulsory)

 $return_value = $api_object->host_list('TESTDOMAIN-0003.TK');

Possible responses:

 $return_value = {
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0003.TK',
          'host' => [
                    {
                      'hostname' => 'NS3.TESTDOMAIN-0003.TK',
                      'ipaddress' => '192.168.0.11'
                    },
                    {
                      'hostname' => 'NS2.TESTDOMAIN-0003.TK',
                      'ipaddress' => '192.168.20.254'
                    },
                    {
                      'hostname' => 'NS4.TESTDOMAIN-0003.TK',
                      'ipaddress' => '192.168.1.1'
                    },
                    {
                      'hostname' => 'NS1.TESTDOMAIN-0003.TK',
                      'ipaddress' => '192.168.10.1'
                    }
                  ]
        };

=cut

sub host_list {
    my $self   = shift;
    my $domain = shift;
    my $st     = $self->_get_url(
        {
            function   => 'host_list',
            domainname => $domain,
        }
    );
    return $st;
}

=head2 Update domain DNS

Function: C<UPDATEDNS>

Parameters: C<DOMAIN> (Compulsory)

Parameters: (optional) either an array reference of name servers, B<or> a URL for
forwarding.

 # with an array of name servers
 $return_value = $api_object->updatedns('TESTDOMAIN-0003.TK', ['NS1.A.COM.TK', 'NS2.A.COM.TK']);

or

 # with a URL for forwarding
 $return_value = $api_object->updatedns('TESTDOMAIN-0004.TK', 'http://www.icann.org/');

Possible response (regardless of form used):

 $return_value  = {
          'status' => 'NAMESERVERS UPDATED',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0004.TK'
        };

=cut

sub updatedns {
    my $self   = shift;
    my $domain = shift;

    my $st;

    if ( ref $_[0] eq 'ARRAY' ) {

        # list of name servers
        $st = $self->_get_url(
            {
                function   => 'updatedns',
                domainname => $domain,
                nameserver => $_[0],
            }
        );
    }
    elsif ( not defined $_[0] ) {

        # no details, so (I guess) reset settings
        $st = $self->_get_url(
            {
                function   => 'updatedns',
                domainname => $domain,
            }
        );
    }
    else {

        # url forwarder
        $st = $self->_get_url(
            {
                function   => 'updatedns',
                domainname => $domain,
                forwardurl => $_[0],
            }
        );
    }
    return $st;
}

=head2 Update WHOIS information

Function: C<updatewhois>

Parameters: (compulsory) C<DOMAIN>, C<HASHREFENCE of keys to change>

This function is called a little differently from everything else. Instead
of passing a large number of parameters in a fixed order, it requires a
C<Hash Reference> to a collection of key->value pairs representing the items
in the WHOIS record that are to be changed.

The keys the system recognizes are those mentioned in the main API
documentation under updatewhois, except function, email and password.

For example:

 $result_code = $api_object->updatewhois('TESTDOMAIN-0003.TK', {reg_company => 'Dot TK BV', reg_city => 'Amsterdam', reg_countrycode => 'NL'});

Possible response: 

 $result_code = {
          'status' => 'WHOIS INFORMATION UPDATED',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0003.TK'
        };

=cut

sub updatewhois {
    my $self   = shift;
    my $domain = shift;
    my $param  = shift;

    my $temp_st = { function => 'updatewhois', domainname => $domain };
    foreach my $k ( keys %{$param} ) {
        $temp_st->{$k} = $param->{$k};
    }

    my $st = $self->_get_url($temp_st);
    return $st;
}

=head2 Domain Status

Function: C<domain_status>

Parameter: (compulsory) C<DOMAIN>

 $result_code = $api_object->domain_status('TESTDOMAIN-0003.TK');

Possible response:

Depending on the relation between Reseller and Domain, there can be three different types of output:

I<If the domain is available for registration>

 $ result_code = {
          'status' => 'AVAILABLE',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0003.TK',
          'pricing' => [
                       {
                         'currency' => 'GBP',
                         'retailprice' => '19.90',
                         'partnerprice' => '9.00',
                         'lengthofregistration' => '2'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '24.75',
                         'partnerprice' => '13.50',
                         'lengthofregistration' => '3'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '31.80',
                         'partnerprice' => '18.00',
                         'lengthofregistration' => '4'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '37.50',
                         'partnerprice' => '22.50',
                         'lengthofregistration' => '5'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '62.55',
                         'partnerprice' => '40.50',
                         'lengthofregistration' => '9'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '9.95',
                         'partnerprice' => '4.50',
                         'lengthofregistration' => '1'
                       }
                     ],
          'domaintype' => 'PAID'
        };

I<If the domain is registered, but not part of the domain portfolio of the reseller that uses this query>

 $result_code = {
          'whois_info' => {
                          'reg_name' => 'Ccops Center',
                          'reg_address' => 'PMB 155, 10400 Overland Road',
                          'reg_zipcode' => '83709',
                          'reg_statecode' => 'US-ID',
                          'reg_countrycode' => 'US',
                          'reg_company' => 'eMarkmonitor Inc',
                          'reg_email' => 'ccopsbilling@markmonitor.com',
                          'reg_fax_nr' => '208-3895799',
                          'reg_city' => 'Boise',
                          'reg_phone_nr' => '208-3895740'
                        },
          'status' => 'NOT AVAILABLE',
          'type' => 'result',
          'nameservers' => [
                           {
                             'hostname' => 'NS1.GOOGLE.COM'
                           },
                           {
                             'hostname' => 'NS2.GOOGLE.COM'
                           },
                           {
                             'hostname' => 'NS3.GOOGLE.COM'
                           },
                           {
                             'hostname' => 'NS4.GOOGLE.COM'
                           }
                         ],
          'domainname' => 'GOOGLE.TK',
          'expirationdate' => '99999999'
        };

I<If the domain is registered and is part of the domain portfolio of the reseller that uses this query>

 $result_code = {
          'whois_info' => {
                          'reg_name' => 'Dot TK Reseller',
                          'reg_address' => '8 Berwick Street',
                          'reg_zipcode' => 'W1F 0PH',
                          'reg_countrycode' => 'GB',
                          'reg_company' => 'Dot TK plc',
                          'reg_email' => 'partners@dot.tk',
                          'reg_fax_nr' => '2077349597',
                          'reg_city' => 'London',
                          'reg_phone_nr' => '2077349596'
                        },
          'status' => 'NOT AVAILABLE',
          'type' => 'result',
          'nameservers' => [
                           {
                             'hostname' => 'NS1.A.COM.TK',
                             'ipaddress' => {'192.168.0.1'}
                           },
                           {
                             'hostname' => 'NS2.A.COM.TK',
                             'ipaddress' => {'192.168.202.1'}
                           }
                         ],
          'domainname' => 'TESTDOMAIN-0003.TK',
          'expirationdate' => '20100723',
          'pricing' => [
                       {
                         'currency' => 'GBP',
                         'retailprice' => '19.90',
                         'partnerprice' => '9.00',
                         'lengthofregistration' => '2'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '24.75',
                         'partnerprice' => '13.50',
                         'lengthofregistration' => '3'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '31.80',
                         'partnerprice' => '18.00',
                         'lengthofregistration' => '4'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '37.50',
                         'partnerprice' => '22.50',
                         'lengthofregistration' => '5'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '62.55',
                         'partnerprice' => '40.50',
                         'lengthofregistration' => '9'
                       },
                       {
                         'currency' => 'GBP',
                         'retailprice' => '9.95',
                         'partnerprice' => '4.50',
                         'lengthofregistration' => '1'
                       }
                     ],
          'domaintype' => 'PAID'
        };

=cut

sub domain_status {
    my $self   = shift;
    my $domain = shift;
    my $st     = $self->_get_url(
        {
            function   => 'domain_status',
            domainname => $domain,
        }
    );
    return $st;
}

=head2 Generate authorization code

Function: generate_authcode

Parameters: C<DOMAIN> (compulsory) - the domain to generate the code for

 $api_object->generate_authcode('TESTDOMAIN-0001.TK');

Possible response:

 # if successful
 $VAR1 = {
          'authcode' => '1234567890123456',
          'status' => 'AUTHCODE GENERATED',
          'type' => 'result',
          'domainname' => 'TESTDOMAIN-0001.TK'
        };

=cut

sub generate_authcode {
    my $self   = shift;
    my $domain = shift;
    my $st     = $self->_get_url(
        {
            function   => 'generate_authcode',
            domainname => $domain,
        }
    );
    return $st;
}

=head2 Price Transfers

Function: C<price_transfer>

Parameters: C<DOMAIN>, C<AUTHCODE> (both compulsory)

 # in receiving account
 $result_code = $api_object->price_transfer('TESTDOMAIN-0001.TK', '1234567890123456');

Possible response:

 $result_code = {
          'partnerrate' => '2.00',
          'status' => 'RATES PROVIDED',
          'retailrate' => '12.50',
          'domainname' => 'TESTDOMAIN-0001.TK',
          'currency' => 'YTL',
          'lengthofregistration' => '1',
          'type' => 'result',
          'domaintype' => 'PAID'
        };

=cut

sub price_transfer {
    my $self     = shift;
    my $domain   = shift;
    my $authcode = shift;

    my $st = $self->_get_url(
        {
            function   => 'price_transfer',
            domainname => $domain,
            authcode   => $authcode,
        }
    );
    return $st;
}

=head2 Transfer of domains

Function: C<transfer>

Parameters: C<DOMAINAME>, C<AUTHCODE>

 # again, in receiving account
 $result_code = $api_object->transfer('TESTDOMAIN-0001.TK', '1234567890123456');

Possible response:

 $result_code = {
          'partnerrate' => '2.00',
          'status' => 'TRANSFERRED',
          'retailrate' => '12.50',
          'domainname' => 'TESTDOMAIN-0001.TK',
          'expirationdate' => '20110731',
          'currency' => 'YTL',
          'lengthofregistration' => '1',
          'type' => 'result'
        };

=cut

sub transfer {
    my $self     = shift;
    my $domain   = shift;
    my $authcode = shift;

    my $st = $self->_get_url(
        {
            function   => 'transfer',
            domainname => $domain,
            authcode   => $authcode,
        }
    );
    return $st;
}

# This routine does not have POD - because it contains all the bits the user doesn't need to know
sub _get_url {

    # this is really the only routine with any smarts at all.....
    my $self   = shift;
    my $params = shift;

    $params->{email}    = $self->{email};
    $params->{password} = $self->{password};

    my $url = 'https://partners.nic.tk/api/partnerapi.tk';

    my $ua = LWP::UserAgent->new;
    $ua->timeout((defined $self->{'timeout'} ? $self->{'timeout'} : 15));
    $ua->agent("Domain::Register::TK/$VERSION");

    # Create a request
    my $used_url = URI->new($url);
    $used_url->query_form($params);

    my $req = HTTP::Request->new( GET => $used_url );

    if ( defined $self->{proxy} ) {
        $ua->proxy( ['https'], $self->{proxy} );
    }

    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    my $status = '';

    # Check the outcome of the response
    if ( $res->is_success ) {
        my $xml = $res->content;

        my $xml_st = XMLin($xml);
        $self->{status} = $xml_st->{status};
        if ( $xml_st->{status} eq 'OK' ) {
            delete $xml_st->{errstr};
            delete $self->{errstr};
        }
        else {
            $self->{errstr} = $xml_st->{reason};
        }
        delete $xml_st->{status};
        my @k = keys %{$xml_st};
        return $xml_st->{ $k[0] };
    }
    else {
        $self->{status} = 'NOT OK';
        $self->{errstr} = $res->status_line;
        return;
    }
}

=head1 AUTHOR

Dot TK Reseller API Program C<< <partnerapi at dot.tk> >>

Please report any bugs or feature requests to C<bug-domain-register-tk at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Domain-Register-TK>.  

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Domain::Register::TK

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Domain-Register-TK>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Domain-Register-TK>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Domain-Register-TK>

=item * Search CPAN

L<http://search.cpan.org/dist/Domain-Register-TK/>

=back

=head1 COPYRIGHT

Copyright (c) 2010 Dot TK Ltd. All Rights Reserved. This module is free software; you can redistribute it
and/or modify it under the terms of either:  a) the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any later version, or b) the "Artistic License",
that is, the same terms as Perl itself.

This module requires that the client user have an active account with Dot TK L<http://www.dot.tk> in order to access it's key functionality

=cut

1;
