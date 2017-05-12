########################################
package Log::Dispatch::SNMP;
use Log::Dispatch::Output;
use base qw( Log::Dispatch::Output );
########################################
use strict;
use warnings;

use Net::SNMP qw(:asn1);
use Params::Validate qw(validate SCALAR);
use Carp qw(carp croak); #TODO: option to warn or die or do nothing on errors

our $VERSION = '0.02';

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    # new versions of Log::Dispatch may complain about unknown options,
    # so we take our options out of the equation (err.. hash)
    my %parameters = @_;
    my %snmp_parameters = ();
    foreach my $key (qw(ManagementHostTrapListenPort
                        ManagementHost
                        EnterpriseOID
                        LocalIPAddress
                        LocalTrapSendPort
                        GenericTrapType
                        SpecificTrapType
                        ApplicationTrapOID
                        CommunityString
                     )
    ) {
        if (exists $parameters{$key}) {
            $snmp_parameters{$key} = $parameters{$key};
            delete $parameters{$key};
        }
    }

    my $self = bless {}, $class;

    $self->_basic_init(%parameters);
    $self->_set_snmp_parameters(%snmp_parameters);
    $self->_start_snmp_session();
    
    return $self;
}

sub _set_snmp_parameters {
    my $self = shift;

    # validate user supplied parameters
    my %p = validate (@_, {
                'ManagementHostTrapListenPort' => { type    => SCALAR,
                                                    default => 162,
                                                  },
                'ManagementHost'     => { type => SCALAR },
                'EnterpriseOID'      => { type => SCALAR },
                'LocalIPAddress'     => { type => SCALAR },
                'LocalTrapSendPort'  => { type => SCALAR,
                                          default => 161,
                                        },
                'GenericTrapType'    => { type => SCALAR,
                                          default => 6,
                                        },
                'SpecificTrapType'   => { type => SCALAR },
                'ApplicationTrapOID' => { type => SCALAR },
                'CommunityString'    => { type => SCALAR,
                                          default => 'public',
                                        },
            });
    
    # put everything in the actual object
    foreach (keys %p) {
        $self->{$_} = $p{$_};
    }
}

sub _start_snmp_session {
    my $self = shift;
    my $error = '';
    
    ($self->{'session'}, $error) =
        Net::SNMP->session(
               -hostname    => $self->{'ManagementHost'},
               -port        => $self->{'ManagementHostTrapListenPort'},
               -version     => 'snmpv1', #TODO: make this configurable
               -community   => $self->{'CommunityString'},
               -nonblocking => 0,        #TODO: make this configurable
               -domain      => 'udp4',   #TODO: make this configurable
    );
    croak "error starting SNMP session: $error\n"
        unless $self->{'session'};
}

sub log_message {
    my $self = shift;
    my %p = @_;

    #TODO: This check is probably not necessary
    # or could be just plain wrong
    $self->_start_snmp_session()
        unless $self->{'session'};
    
    # first trio is always the EOID
    my @varbindlist = (
            $self->{'EnterpriseOID'},
            OBJECT_IDENTIFIER, 
            $self->{'EnterpriseOID'},
    );
    
    # then we put the message itself on the varbind.
    # this is separate in order to easen the future
    # (planned) integration with a special Layout
    # "SnmpDelimitedConversionPatternLayout" for Log4perl.
    push @varbindlist, $self->{'ApplicationTrapOID'},
                       OCTET_STRING,
                       $p{'message'}
    ;
    
    if ( ! $self->{'session'}->trap(
                                -enterprise   => $self->{'EnterpriseOID'},
                                -generictrap  => $self->{'GenericTrapType'},
                                -specifictrap => $self->{'SpecificTrapType'},
                                -varbindlist  => \@varbindlist,
                            )
    ) {
        carp 'Error sending trap: ' . $self->{'session'}->error() . "\n";
    }
}

sub DESTROY {
    my $self = shift;
    if ($self->{'session'}) {
        $self->{'session'}->close();
    }
}

42;
__END__
=head1 NAME

Log::Dispatch::SNMP - Object for logging to SNMP servers

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

If you're using Log::Dispatch:

    use Log::Dispatch::SNMP;

    # *OPTIONAL* parameters (and their default values)
    # name                         - defaults to a unique one
    # max_level                    - defaults to no maximum
    # ManagementHostTrapListenPort - defaults to 162
    # LocalTrapSendPort            - defaults to 161
    # CommunityString              - defaults to 'public'
    # GenericTrapType              - defaults to 6
    #
    # other parameters are *REQUIRED*
    
    my $snmp = Log::Dispatch::SNMP->new(
                 name      => 'snmp',
                 min_level => 'debug',
                 max_level => 'error',
                 
                 ManagementHost               => '192.168.0.1',
                 ManagementHostTrapListenPort => 162,
                 EnterpriseOID                => '1.1.1.1.1.1.1.1.1.1.1',
                 LocalIPAddress               => '127.0.0.1',
                 LocalTrapSendPort            => 161,
                 GenericTrapType              => 6,
                 SpecificTrapType             => 0,
                 ApplicationTrapOID           => '2.2.2.2.2.2.2.2.2.2.2',
                 CommunityString              => 'public',
    );

    $snmp->log( level => 'alert', message => "houston, we have a problem.\n" );
    
Or even better, if you're using Log::Log4perl, just set the appender options on your configuration file (or string) and you're good to go:

    log4perl.category.Foo.Bar = INFO SNMPTrap
    
    log4perl.appender.SNMPTrap = Log::Dispatch::SNMP;
    log4perl.appender.SNMPTrap.ManagementHost = 192.168.0.1
    log4perl.appender.SNMPTrap.ManagementHostTrapListenPort = 162
    log4perl.appender.SNMPTrap.EnterpriseOID=1.1.1.1.1.1.1.1.1.1.1
    log4perl.appender.SNMPTrap.LocalIPAddress=127.0.0.1
    log4perl.appender.SNMPTrap.LocalTrapSendPort=161
    log4perl.appender.SNMPTrap.GenericTrapType=6
    log4perl.appender.SNMPTrap.SpecificTrapType=0
    log4perl.appender.SNMPTrap.ApplicationTrapOID=2.2.2.2.2.2.2.2.2.2.2
    log4perl.appender.SNMPTrap.CommunityString=public
    log4perl.appender.SNMPTrap.ForwardStackTraceWithTrap=true
    log4perl.appender.SNMPTrap.Threshold=DEBUG
    log4perl.appender.SNMPTrap.layout=PatternLayout
    log4perl.appender.SNMPTrap.layout.ConversionPattern=%d,%p,[%t],[%c],%m%n
    
You can also share the same Log4j configuration file of any Java-based application using SNMPTrapAppender (log4j-snmp-trap-appender):

    # write this in your Perl code, 
    # before you call Log::Log4perl::init()
    $Log::Log4perl::JavaMap::user_defined{'org.apache.log4j.ext.SNMPTrapAppender'}
        = 'Log::Dispatch::SNMP';

...but please note that you will *not* be able to use the special Layout Class I<SnmpDelimitedConversionPatternLayout> for multiple VarBinds. At least not for now :)


=head1 DESCRIPTION

Log::Dispatch::SNMP is an appender to send logging messages to a specified management host in SNMP-managed networks (with a MLM or SMNP management console of some kind), commonly found in large and/or distributed networks. It should be used under the L<< Log::Dispatch >> system or other compatible logging environments such as L<< Log::Log4perl >>.

Note that this appender does not attempt to provide full access to the SNMP API, so you cannot use it as an interface to SNMP GET or SET calls (you should check L<Net::SNMP> and others for this). All we do is pass your logging event as a TRAP.

=head2 Log::Log4perl Integration

Remember that, if you're using Log4perl, you don't have to directly instantiate any dispatcher on your code - Log4perl will do that for you tranparently. So, if you're using this module with Log4perl, just remember to set the parameters in your configuration file (usually 'log4perl.conf'). Please refer to the SYNOPSIS under this document for syntax information, and to the L<Log::Log4Perl> documentation for further information on using Log4perl.


=head1 METHODS

=head2 new

Instantiates a new logging object. It takes the following parameters (all are required, except when otherwise noted):

=over 4

=item name  (optional)

A string containing the name of the logging object. This is useful if you want to refer to the object later, e.g. to log specifically to it or remove it (Log4perl users don't need this at all, as specific logs can be easily done via its configuration).

By default a unique name will be generated. You should not depend on the form of generated names, as they may change.

=item min_level  *REQUIRED*

A string ('warning') or integer ('3') containing the minimum logging level this object will accept. Please refer to the L<Log::Dispatcher> documentation for further information.

=item ManagementHost  *REQUIRED*

A string containing the SNMP server host name (i.e. the destination for your traps)

=item ManagementHostTrapListenPort  (optional)

The port number the SNMP server is listening to. This parameter is optional, and defaults to port 162.

=item EnterpriseOID  *REQUIRED*

A string containing the Enterprise Object Identifier (EOID).

=item LocalIPAddress  *REQUIRED*

A string containing the local IP address.

=item LocalTrapSendPort  (optional)

The port number to use locally. This parameter is optional, and defaults to port 161.

=item GenericTrapType  (optional)

A number with the Generic Trap type. This parameter is optional, and defaults to 6 which corresponds to "enterpriseSpecific" (what you usually want under message logging).

=item SpecificTrapType  *REQUIRED*

A number with the specific Trap type.

=item ApplicationTrapOID  *REQUIRED*

A string containing the Object Identifier (OID) for the Application.

=item CommunityString  (optional)

A string containing the SNMP community name. This parameter is optional, and defaults to 'public'.

=back

=head2 log_message( message => $ )

Format and sends the given message. This method generally should B<< NOT >> be called directly. Instead, you should use the C<log()> method on your chosen logging interface.

=head1 WHAT IS IT WITH ALL THESE LONG/WEIRD-NAMED PARAMETERS?

I know, I know. As much as I loved to name stuff like 'ManagementHostTrapListenPort' into something more simple (and perlish) like 'remote_port', I've kept the original Java names to support interoperability and interchangeability with Log4j and easen the learning curve for Java folks migrating to Perl :)

I might introduce more perlish synonyms for all the long-and-mixed-cased atributes if you ask for them via RT or email.

=head1 AUTHOR

Breno G. de Oliveira, C<< <garu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-dispatch-snmp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Dispatch-SNMP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Dispatch::SNMP


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-SNMP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Dispatch-SNMP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Dispatch-SNMP>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Dispatch-SNMP/>

=back


=head1 ACKNOWLEDGEMENTS

Many thanks to Dave Rolsky for his C<Log::Dispatch> framework, to Michael Schilli for C<Log::Log4perl> and to David Town for C<Net::SNMP>.

This module's functionality is based on L<< http://code.google.com/p/log4j-snmp-trap-appender/ >>

=head1 SEE ALSO

L<Log::Dispatch>
L<Log::Log4perl>
L<Net::SNMP>

=head1 COPYRIGHT & LICENSE

Copyright 2009-2010 Breno G. de Oliveira, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
