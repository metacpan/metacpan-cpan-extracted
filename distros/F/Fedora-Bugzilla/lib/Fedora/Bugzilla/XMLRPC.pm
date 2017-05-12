#############################################################################
#
# Override certain RPC::XML::Client methods to better fit in
#
# Author:  Chris Weyl (cpan:RSRCHBOY), <cweyl@alumni.drew.edu>
# Company: No company, personal work
# Created: 01/27/2009 07:08:51 PM PST
#
# Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
#############################################################################

package Fedora::Bugzilla::XMLRPC;

use English qw{ -no_match_vars };  # Avoids regex performance penalty

use Moose;

extends 'RPC::XML::Client', 'Moose::Object';

# debugging
#use Smart::Comments '###', '####';

our $VERSION = '0.13';

has login_cb => (is => 'ro', isa => 'CodeRef', required => 1);

sub new { 
    my $class = shift; 
    
    # call XML::RPC's constructor 
    my $obj = $class->SUPER::new(@_); 
    $obj = $class->meta->new_object( 
        # pass in the constructed object using the special key __INSTANCE__ 
        __INSTANCE__ => $obj,
        login_cb     => pop @_,
    );
    $obj->BUILDALL;
    return $obj;
}

around fault_handler => sub {
    my $next = shift @_;
    my $self = shift @_;
    
    if (ref $_[0] eq 'CODE') {

        # we're passed a code ref, so set our new handler
        my $new_handler = shift @_;
        return $next->($self, 
            sub { 

                # login and retry if we're a login failure
                my $fault = $_[0]->{faultString}->value;
                ### fault: "$fault"

                do { $self->login_cb->(); die 'RETRY' } 
                    if "$fault" eq 'Login Required'; 
                
                # otherwise just call the real handler
                return $new_handler->(@_);
            }
        );
    }

    # otherwise just call our handler
    return $next->($self);
};

override send_request => sub {
    my $self = shift @_;

    # let's try it...
    my $ret;
    eval { $ret = super };

    ### $EVAL_ERROR
    return $ret unless $EVAL_ERROR;

    # check to see if it's a 'Login Required' fault
    # if it is, we've already handled the login in the fault handler
    do { return super }
        if $EVAL_ERROR =~ /^RETRY/;

    return $ret;
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;

__END__

=head1 NAME

Fedora::Bugzilla::XMLRPC - Subclass RPC::XML::Client to catch login faults

=head1 SYNOPSIS

	use <Module::Name>;
	# Brief but working code example(s) here showing the most common usage(s)

	# This section will be as far as many users bother reading
	# so make it as educational and exemplary as possible.


=head1 DESCRIPTION

A subclass of L<RPC::XML::Client>, overriding a number send_request() and
fault_handler() to handle logins when they need to happen.


=head1 SUBROUTINES/METHODS

=over

=item B<fault_handler>

=item B<send_request>

=back

=head1 DIAGNOSTICS

See L<RPC::XML::Client>.  We catch 'Login Required' faults, but everything
else remains the same.

=head1 SEE ALSO

L<RPC::XML::Client>.

=head1 BUGS AND LIMITATIONS

See L<Fedora::Bugzilla>.

Patches are welcome.

=head1 AUTHOR

Chris Weyl  <cweyl@alumni.drew.edu>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2009 Chris Weyl <cweyl@alumni.drew.edu>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the 

    Free Software Foundation, Inc.
    59 Temple Place, Suite 330
    Boston, MA  02111-1307  USA

=cut

