package IO::EPP

our $VERSION = 0.004;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

IO::EPP - Object and procedure interface of the client-side for work with EPP API of registries and some resellers

=head1 SYNOPSIS

    use IO::EPP;
    print "IO::EPP version is $IO::EPP::VERSION\n";

=head1 DESCRIPTION

IO::EPP is a very light and fast interface of the access to EPP API from the client's side with minimum dependences.
It is independent of libxml and other heavy libraries.

It works over L<IO::Socket::SSL> without additional modules and demands only L<Digest::MD5> for generation of unique ID and L<Time::HiRes> for the purpose of logging.
L<LWP> is necessary for two registries and one reseller (TCI/RIPN, Taeping и HosterKZ), because EPP of these providers works over HTTPS.

In test mode IO::EPP can emulate the job of some registries.
Now the emulation of Verisign Core and CentralNic servers is supported at the level of 99% of answers.
The test environment for L<IO::EPP::Base> uses the emulation of CentralNic without extensions.

The main difference of the emulation from a registry is that all the data are into the process which makes requests. That's why when the process comes to the end all the data will be lost.
If you want to save the data between queries you need to replace the functions in the module L<IO::EPP::Test::Server>.

The library IO::EPP has two ways of working - procedural or object one.
The procedural method works over the object one and when called returns the object of connection.

The authorization occurs when an object is created.

Logout is called automatically from the object destructor.

The basic module is L<IO::EPP::Base>. It supports all the functions of EPP RFC and the extension DNSSEC.
But since many registries and resellers use a large number of their own extensions the special modules that work over L<IO::EPP::Base> are wrote for them.

The description of definite functions see in L<IO::EPP::Base>.

The special parameters for every provider should be seen in relevant modules.

Full examples of working with every function of packages see in the tests t/Base.t and t/VerisignCore.t.

=head1 OVERVIEW OF PACKAGES

For now there are the modules for such providers:

=over 3

=item L<IO::EPP::Base>

The universal module for working with EPP API and the basic class for other modules.

=item L<IO::EPP::Verisign>

L<https://www.verisign.com/en_US/domain-names/index.xhtml>

Registry for gtlds (Core Server), cctlds and new gtlds (NameStore Server)

=item L<IO::EPP::Afilias>

L<https://afilias.info/global-registry-services>,

.org, .ngo, .org, .орг, .संगठन, .机构 – L<https://thenew.org/org-people/domain-products/>

Registry for gltds and cctlds

=item L<IO::EPP::CNic>

L<https://centralnicregistry.com/services>

Registry for 3lvl.cctlds and new gtlds

=item L<IO::EPP::RRPProxy>

L<https://www.rrpproxy.net/Domains>

Reseller, belongs to the CentralNic Group

=item L<IO::EPP::CoCCA>

L<https://cocca.org.nz/#five>

Registry for cctlds and some new gtlds

.рус – L<http://rusnames.ru/en/index.pl>

=item L<IO::EPP::TCI>

The module for working with TCI tlds over normal EPP

L<https://www.tcinet.ru/>

L<https://cctld.ru/>

Registry for .tatar, .дети

=item L<IO::EPP::RIPN>

The module for working with TCI tlds over HTTPS, needs LWP

L<https://www.tcinet.ru/>

Registry for .ru, .su, .рф

=item L<IO::EPP::Taeping>

L<https://www.taeping.ru/>

Registry for net.ru, org. pp.ru tlds

This module works over HTTPS, needs LWP

=item L<IO::EPP::Flexireg>

L<https://faitid.org/>

L<https://www.flexireg.net/>

Registry for .moscow, .москва, .ru.net and 3lvl.ru/su tlds

=item L<IO::EPP::CoreNic>

L<https://corenic.org/>

Registry for new gtlds

=item L<IO::EPP::DrsUa>

L<http://drs.ua/>

Registry for biz.ua, co.ua, pp.ua and reseller for other .ua tlds

=item L<IO::EPP::IRRP>

L<https://www.irrp.net/>, L<https://www.hexonet.net/>, L<https://idotz.net/>

Reseller, a division of BRS Media Inc.

=item L<IO::EPP::HosterKZ>

L<https://hoster.kz/>

Reseller for .kz, .қаз tlds

This module works over HTTPS, needs LWP.

=back

The links on documentation of EPP for each provider are in relevant modules.

The list of emulation modules:

=over 3

=item L<IO::EPP::Test::Base>

The module of emulation of server with standard EPP API, mostly repeats the behavior of CentralNic server.

=item L<IO::EPP::Test::CNic>

The module of emulation of CentralNic server.

=item L<IO::EPP::Test::VerisignCore>

The module of emulation of Verisign Core Server. The real test Verisign server does not support the redemption of domains.
The redemption of domains works in this module, but without checking of parametres.

=back

For working with emulation of registries it is necessary to set the parameter C<test_mode = 1>.
Error codes and messages have been checked on production server.

The modules of emulation of other registries are still in construction.

=head1 OBJECT STYLE WORK

It is more convenient for cases when it is necessary to keep the connection with the registry.

An example of registration of a new nameserver

    use IO::EPP::CNic;
    use Data::Dumper;

    # Parameters for IO::Socket::SSL
    my %sock_params = (
        PeerHost        => 'epp.centralnic.com',
        PeerPort        => 700,
        SSL_key_file    => 'ssl_key_file.pem',
        SSL_cert_file   => 'ssl_cert_file.pem',
        Timeout         => 30,
        debug           => 1,
    );

    # Login parameters
    my %params = (
        user        => 'H1234567',
        pass        => 'XXXXXXXX',
        sock_params => \%sock_params,
        test_mode   => 0, # real connect
        no_log      => 1, # without logger
    );

    my $conn = IO::EPP::CNic->new( \%params ); # create object, get greeting and call login()

    my ( $answer, $code, $msg ) = $conn->get_ns_info( ns => 'ns.example.xyz' );

    if ( $code == 2303 ) {
        # $msg eq 'The host &#039;ns.example.com&#039; does not exist'
        ( $answer, $code, $msg ) = $conn->create_ns( { ns => 'ns.example.xyz', ips => ['1.2.3.4', 'fe80::1'] } );

        if ( $code == 1000 ) {
            print "ns created\n";
        }
        else {
            print "error: $msg\n";
        }
    }
    elsif ( $code == 1000 ) {
        print "ns.example.xyz allready exist: " . Dumper $answer;
    }
    else {
        print "error getting ns info: $msg\n";
    }

    undef $conn; # call logout() and DESTROY()

=head1 PROCEDURE STYLE WORK

This method of working is more suitable for single requests.

An example of cheking of two domains access

    use Data::Dumper;
    use IO::EPP::Verisign;
    use Config;

    # common function for setting the connection parametres
    sub make_request {
        my ( $action, $params ) = @_;

        if ( !$params->{tld}  &&  $params->{dname} ) {
            ( $params->{tld} ) = $params->{dname} =~ /\.([^.]+)$/;
        }

        unless ( $params->{tld} ) {
            my $msg = 'Not found tld';
            return ( { code => 0, msg => "code: 0\nmsg: $msg" }, $msg, 0 );
        }

        unless ( $params->{conn} ) {
            # need create new connection
            state $config = Config::get('Providers.Verisign');

            # Parameters for IO::Socket::SSL
            my %sock_params = (
                PeerPort         => $config->{port},
                Proto            => 'tcp',
                SSL_key_file     => $config->{ssl_key_file},
                SSL_cert_file    => $config->{ssl_cert_file},
                # SSL_verify_mode => SSL_VERIFY_NONE, -- for this parameter need use IO::Socket::SSL
                Timeout          => 30,
                debug            => 1,
            );

            if ( $params->{tld} =~ /^(com|net|edu)$/ ) {
                $params->{server}      = 'Core';
                $params->{user}        = $config->{core_username};
                $params->{pass}        = $config->{core_password};
                $sock_params{PeerHost} = $config->{core_url}; # epp.verisign-grs.com
            }
            elsif ( $params->{tld} eq 'name' ) {
                # For .name need set special epp extensions
                # earlier this tld was located on the dedicated server
                $params->{server}      = 'DotName';
                $params->{user}        = $config->{name_username};
                $params->{pass}        = $config->{name_password};
                $sock_params{PeerHost} = $config->{name_url}; # namestoressl.verisign-grs.com
            }
            else {
                # .tv, .cc, .jobs and other tlds
                $params->{server}      = 'NameStore';
                $params->{user}        = $config->{name_username};
                $params->{pass}        = $config->{name_password};
                $sock_params{PeerHost} = $config->{name_url}; # namestoressl.verisign-grs.com
            }

            $params->{sock_params} = \%sock_params;
            $params->{test_mode} = 0;
            # By default the logging is directed into STDOUT, but this can be changed
            # $params->{no_logs} = 1; -- work without logs
            # $params->{log_fn} = sub { print "\nverisign logger:\n$_[0]\n" }; -- use manual logger
            $params->{log_name} = '/var/log/comm_epp_verisign.log'; # use this file for output
        }

        return IO::EPP::Verisign::make_request( $action, $params );
    }

    my ( $answer, $msg ) = make_request(  'check_domains', { tld => 'com', domains => [ 'xn--offshrehosting-4jf.com', 'qqq.net' ] } );

    print Dumper $answer;

As a result in STDOUT will be output:

    $VAR1 = {
          'msg' => 'Command completed successfully',
          'xn--offshrehosting-4jf.com' => {
                                            'avail' => '1'
                                          },
          'qqq.net' => {
                         'reason' => 'Domain exists',
                         'avail' => '0'
                       },
          'code' => '1000'
        };

=head1 AUTHORS

Vadim Likhota <vadiml@cpan.org>, some edits were made by Andrey Voyshko, Victor Efimov

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 NOTE

=over 3

=item *

Version # 1 will be assigned to the library when the emulations of all registries and the tests for them will be written.

=item *

The additions for working with other registries and resellers are welcome.

=back

=cut
