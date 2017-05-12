package Devel::TypeCheck::Util;

require Exporter;
use Carp;

=head1 NAME

Devel::TypeCheck::Util - Exports utility functions to other TypeCheck modules.

=head1 SYNOPSIS

use Devel::TypeCheck::Util;

=head1 DESCRIPTION

=over 4

=cut
@ISA = qw(Exporter);

@EXPORT = qw(getVerbose setVerbose verbose verbose_ TRUE FALSE abstract);

our $verbose = 0;

=item B<getVerbose>

Return whether or not verbose mode is enabled.

=cut
# getVerbose(): return the verbosity status
sub getVerbose () {
    return $verbose;
}

=item B<setVerbose>($status)

Turn verbose mode on or off, depending on the value of C<<$status>>

=cut
# setVerbose($status): set the verbosity status
sub setVerbose ($) {
    my $status = shift;
    if ($status) {
        $verbose = 1;
    } else {
        $verbose = 0;
    }
}

=item B<verbose>($msg1, $msg2, ...)

If verbosity is on, print out the messages to STDOUT.  Otherwise, do nothing.

=cut
sub verbose {
    if ($verbose) {
        print STDOUT (@_, "\n");
    }
}

=item B<verbose_>

Like verbose(), but without a carriage return. 

=cut
sub verbose_ {
    if ($verbose) {
	print STDOUT (@_);
    }
}

=item B<TRUE>
=item B<FALSE>

Helper functions to signify that we are using scalars to store boolean values.

=cut
sub TRUE () {
    return 1;
}

sub FALSE () {
    return 0;
}

=item B<abstract>($method, $class)

Called from abstract methods to indicate an error

=cut
sub abstract ($$) {
    my ($method, $class) = @_;
    confess("Method &$method is not implemented in class $class");
}

TRUE;

=back

=head1 AUTHOR

Gary Jackson, C<< <bargle at umiacs.umd.edu> >>

=head1 BUGS

This version is specific to Perl 5.8.1.  It may work with other
versions that have the same opcode list and structure, but this is
entirely untested.  It definitely will not work if those parameters
change.

Please report any bugs or feature requests to
C<bug-devel-typecheck at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-TypeCheck>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2005 Gary Jackson, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
