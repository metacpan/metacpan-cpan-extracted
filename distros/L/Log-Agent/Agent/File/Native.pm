###########################################################################
#
#   Native.pm
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

########################################################################
package Log::Agent::File::Native;

#
# A native Perl filehandle.
#
# I'm no longer using the IO::* hierarchy because it is not adapted
# to what we're trying to achieve here.
#

#
# ->make
#
# Creation routine.
# Turns on autoflush as a side effect.
#
sub make {
	my $class = shift;
	my ($glob) = @_;
	select((select($glob), $| = 1)[0]);		# autoflush turned on
	return bless $glob, $class;
}

#
# ->print
#
# Print to file, propagates print() status.
#
sub print {
	my $glob = shift;
	local $\ = undef;
	return CORE::print $glob @_;
}

#
# ->close
#
# Close file.
#
sub close {
	my $glob = shift;
	CORE::close $glob;
}

#
# ->DESTROY
#
sub DESTROY {
	my $glob = shift;
	CORE::close $glob;
}

1;	# for require
__END__

=head1 NAME

Log::Agent::File::Native - low-overhead IO::File

=head1 SYNOPSIS

 require Log::Agent::File::Native;

 my $fh = Log::Agent::File::Native->make(\*main::STDERR);

=head1 DESCRIPTION

This class is a stripped down implementation of IO::File, to avoid using
the IO::* hierarchy which does not work properly for my simple needs.

=over 4

=item make I<glob>

This is the creation routine. Encapsulates the I<glob> reference so that
we can use object-oriented calls on it.

=item print I<args>

Prints I<args> to the file.

=back

=head1 AUTHOR

Raphael Manfredi F<E<lt>Raphael_Manfredi@pobox.comE<gt>>

=head1 SEE ALSO

Log::Agent::File::Rotate(3), Log::Agent::Driver::File(3).

=cut
