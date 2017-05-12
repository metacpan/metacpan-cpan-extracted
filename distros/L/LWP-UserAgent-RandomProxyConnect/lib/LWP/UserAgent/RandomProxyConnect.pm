package LWP::UserAgent::RandomProxyConnect;
use base( "LWP::UserAgent" );
use Data::Dumper;
use 5.006;
use strict;
use warnings;
our $AUTOLOAD;
use Carp;

=head1 NAME

LWP::UserAgent::RandomProxyConnect - A LWP::UserAgent extension for becoming an omnipresent client.

=head1 VERSION

Version 1.10

=cut

our $VERSION = '1.10';


=head1 SYNOPSIS

This Object does exactly the same than the L<LWP::UserAgent> class with a
new useful feature: it can make each HTTP request throw a different proxy each
time. Also, a few methods improve the proxy list management, and makes the iterative
connections faster.

=head1 CONSTRUCTOR

=head2 new()

When this class is invoked as:

    my $obj = LWP::UserAgent::RandomProxyConnect->new
    
several test will be made. First, the class must find a valid file with a proxy
list, if not, this object will stop. This file must be placed in the environmental
variable $ENV{PROXY_LIST}.

However, the class can be invoked as:

    my $obj = LWP::UserAgent::RandomProxyConnect->new(-proxy_list => $proxy_file_path)
    
the created object will search the file at the specified path.

Whatever the method you use to invoke the class, the object will
stop if the specified file doest not exists, is not readable or there is no proxy
found into it.

Furthermore, you can add as argument all the properties described at L<LWP::UserAgent>

=cut

sub new{
    
    my ($class, %arg) = @_;
    
    
    
    # Extended attributes declaration
    my %def;
    $def{proxy_list}        = $ENV{PROXY_LIST} unless delete $arg{proxy_list};
    $def{protocol}          = "http"           unless delete $arg{protocol};
    $def{allowed_protocols} = ["http","https"] unless delete $arg{allowed_protocols};
    $def{current_proxy}     = "????:??";
    $def{last_proxy}        = "????:??";
    
    # Create the SUPER object with the remaining arguments
    my $ua = LWP::UserAgent->new(%arg);
    
    # And add the extended attributes
    $ua->{proxy_list}        = $def{proxy_list};
    $ua->{protocol}          = $def{protocol};
    $ua->{allowed_protocols} = $def{allowed_protocols};
    $ua->{current_proxy}     = $def{current_proxy};
    $ua->{last_proxy}        = $def{last_proxy};
    
    # Let's load a new "current_proxy". By this way, if there are any errors
    # the object will stop.
    my $self = bless $ua, $class;
    
    # Let's load a random proxy!
    $self->renove_proxy;
    
    return $self;
    
}


=head1 THE EXTENDED REQUEST METHOD

=head2 request

This method is exactly the same than LWP::UserAgent->request L<LWP::UserAgent>
with the implemented proxy-change in each request. It obiously make the connection
slowler. NOTICE: Only http and https protocols are allowed.

=cut

sub request
{
    
    my($self, $request, $arg, $size, $previous) = @_;
    
    # I want to use the same method name to invoke the request, so I am
    # overriding it in this block. However, I need the original (SUPER)
    # method to do the request. So I'm going to replicate the object into
    # a new LWP::UserAgent superclass.
    
    
    # Get the proxy
    my $new_proxy         = $self->get_current_proxy;
    my $allowed_protocols = $self->get_allowed_protocols;
    
    # Set the proxy in the user agent
    $self->SUPER::proxy($allowed_protocols,$new_proxy);
    
    # Set a new proxy for the next connection
    $self->renove_proxy;
    
    # Set the "last proxy used" value
    $self->set_last_proxy($new_proxy);
    
    # Make the request
    my $response = $self->SUPER::request($request,$arg,$size,$previous);
    
    # Return exactly the same than LWP::UserAgeng->request($request) method
    return ($response);
    
}

# I can't do that, and I don't know why!!
# Override the proxy methods
#sub proxy{
#    my ($self) = @_;
#    carp(<<EOF);
#\nWARNING:\nBad class usage: The method LWP::UserAgent::RandomProxyConnect->proxy is incompatible with the philosophy of this class and it has been disabled, the proxy is randomized by this class and it can't be set as static. You can use the LWP::UserAgent class to do it yourself.
#The execution continue ignoring this warning.
#EOF
#}

=head2 env_proxy

This function overrides the original function in order to avoid the static proxy configuration

=cut

sub env_proxy{
    my ($self) = @_;
    carp(<<EOF);
\nWARNING:\nBad class usage: The method LWP::UserAgent::RandomProxyConnect->env_proxy is incompatible with the philosophy of this class and it has been disabled, the proxy is randomized by this class and it can't be set as static. You can use the LWP::UserAgent class to do it yourself.
The execution continue ignoring this warning.
EOF

}

=head1 ATTRIBUTES

As inherited class from LWP::UserAgent, it contains the described attributes at
L<LWP::UserAgent>, but there is some new attributes in this class:

=head2 proxy_list (Default value: $ENV{"PROXY_LIST"})

The C<proxy_list> attribute contains the string with the proxy list file path.
The accessor method:

    my $proxy_list = $obj->get_proxy_list;
    
returns such string.

Also it can be set by the mutator method:

    $obj->set_proxy_list($new_proxy_list_value);

=head2 protocols_allowed (Default value: ['http','https'])

Protocols allowed to stablish the communication.

=head2 protocol (Default value: 'http')

The protocol used to communicate. e.g.: if the specified protocol is "ftp",
the absolute proxy URI will be:

    ftp://proxy.url.or.ip:port/

=cut

=head1 METHODS FOR HANDLING THE PROXY LIST

=head2 renove_proxy

This function returns a new random proxy from the list. This return value
is a string with the format: <proxyUrlorIP>:<port>. This is just a query
for a single request.

=cut

sub renove_proxy {
    
    # This method must handle errors correctly; it is a critical test for
    # proxy list integrity.
    
    my ($self) = @_;
    
    open FH, $self->get_proxy_list;
    my @provisional_proxy_list = <FH>;
    close FH;
    
    my $random_proxy = $provisional_proxy_list[rand @provisional_proxy_list];
    chomp($random_proxy);
    my $protocol = $self->get_protocol;
    
    $self->set_current_proxy($protocol."://".$random_proxy);
    
    return 1;
    
    #if(1){
    #    my $obj_name = ref($self);
    #    croak("The object ".$obj_name." could not load any proxy at ".$self->get_proxy_list."\n");
    #}
    
    
}






#
# The AUTOLOAD method to get/set the class attributes
# sub get_attribute {...}
# sub set_attribute {...}
sub AUTOLOAD{
    
    my ($self,$newvalue) = @_;
    
    my ($operation,$attribute) = ($AUTOLOAD =~ /(get|set)_(\w+)$/);
    
    # Is this a legal method name?
    unless($operation && $attribute){ croak "Method name $AUTOLOAD is not the recogniced form (get|set)_attribute\n"; }
    unless(exists $self->{$attribute}){ croak "No such attribute '$attribute' exists in the class ", ref($self); }
    
    # Turn off strict references to enagle magic AUTOLOAD speedup
    no strict 'refs';
    
    # AUTOLOAD Accessors
    if($operation eq 'get'){
        # Define subroutine
        *{$AUTOLOAD} = sub { shift->{$attribute} };
    
    # AUTOLOAD Mutators
    }elsif($operation eq 'set'){
        # Define subroutine ...
        *{$AUTOLOAD} = sub { shift->{$attribute} = shift; };
        # ... and set the new attribute value.
        $self->{$attribute} = $newvalue;
    }
    
    # Turn strict references back on
    use strict 'refs';
    
    # Return the attribute value
    return $self->{$attribute};
    
}

sub DESTROY{
    my $self = @_;
}

__END__

=head1 AUTHOR

Hector Valverde, C<< <hvalverde at uma.es> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-useragent-randomproxyconnect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-RandomProxyConnect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::UserAgent::RandomProxyConnect


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-UserAgent-RandomProxyConnect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-UserAgent-RandomProxyConnect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-UserAgent-RandomProxyConnect>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-UserAgent-RandomProxyConnect/>

=back


=head1 ACKNOWLEDGEMENTS

I thank the University of Malaga for being so incompetent and make me prove it.

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Hector Valverde.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of LWP::UserAgent::RandomProxyConnect
