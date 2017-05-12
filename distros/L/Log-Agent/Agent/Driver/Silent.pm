###########################################################################
#
#   Silent.pm
#
#   Copyright (C) 1999 Raphael Manfredi.
#   Copyright (C) 2002-2015 Mark Rogaski, mrogaski@cpan.org;
#   all rights reserved.
#
#   See the README file included with the
#   distribution for license information.
#
##########################################################################

use strict;
require Log::Agent::Driver;

########################################################################
package Log::Agent::Driver::Silent;

use vars qw(@ISA);

@ISA = qw(Log::Agent::Driver);

#
# ->make			-- defined
#
# Creation routine.
#
sub make {
	my $self = bless {}, shift;
	return $self;
}

#
# NOP routines.
#

sub prefix_msg {}
sub emit {}
sub channel_eq { 1 }

#
# In theory, we could live with the above NOP ops and the logxxx()
# routines would not do anything. Let's redefine them though...
#

sub logerr {}
sub logwarn {}
sub logsay {}
sub logwrite {}
sub logxcarp {}

#
# Those need minimal processing.
# We explicitely stringify the string argument (uses overloaded "" method)
#

sub logconfess { require Carp; Carp::confess("$_[1]"); }
sub logdie     { die "$_[0]\n"; }

#
# ->logxcroak		-- redefined
#
# Handle the offset parameter correctly
#
sub logxcroak  {
	my $self = shift;
	my ($offset, $str) = @_;
	require Carp;
	my $msg = $self->carpmess($offset, $str, \&Carp::shortmess);
	die "$msg\n";
}

1;	# for require
__END__

=head1 NAME

Log::Agent::Driver::Silent - silent logging driver for Log::Agent

=head1 SYNOPSIS

 use Log::Agent;
 require Log::Agent::Driver::Silent;

 my $driver = Log::Agent::Driver::Silent->make();
 logconfig(-driver => $driver);

=head1 DESCRIPTION

The silent logging driver remaps most of the logxxx() operations to NOPs.
Only logconfess() and logdie() respectively call Carp::confess() and die().

=head1 CHANNELS

All the channels go to /dev/null, so to speak.

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::Driver(3), Log::Agent(3).

=cut
