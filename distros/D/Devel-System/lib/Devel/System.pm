use strict;
package Devel::System;
use String::ShellQuote qw( shell_quote );
use Carp qw( croak );
our $VERSION = '0.01';

=head1 NAME

Devel::System - intercept calls to C<system> to add extra diagnostics

=head1 SYNOPSIS

  use Devel::System;
  $Devel::System::dry_run = 1; # don't really do it

  system qw( rm -rf / );

or from the command line:

  perl -MDevel::System=dry_run -e'system qw( rm -rf / )'

=head1 DESCRIPTION

Devel::System hooks the system builtin to add diagnostic output about
what system calls are being made.  It's like the -x switch for /bin/sh
all over again.

=head2 Variables

The behaviour of the substitued C<system> builtin can be swayed by the
following package variables in the C<Devel::System> namespace

=over

=item $dry_run

Don't actually perform the command. Always returns $return

=cut

our $dry_run;


=item $return

The return value to use when $dry_run is active.  Defaults to 0

=cut

our $return = 0;


=item $fh

The filehandle to print the diagnostics to.  Defaults to \*STDERR

=back

=cut

our $fh = \*STDERR;

*CORE::GLOBAL::system = sub {
    print $fh "+ ", @_ > 1 ? shell_quote(@_) : @_, "\n";
    return $return if $dry_run;

    return CORE::system @_;
};


=head2 Options

In addition there are the following import symbols that you can use to
set options from the commands line.

=over

=item dry_run

Sets $dry_run to a true value.

=back

=cut


sub import {
    my $class = shift;
    for (@_) {
        /^dry_run$/ and do { $dry_run = 1; next };
        croak "unknown option '$_'";
    }
}

1;
__END__

=head1 CAVEAT

Devel::System must be used before any other code that has a call to
system in order for it to be used in preference of the built-in.  This
should normally be easilly arranged via the command line as shown in
L</SYNOPSIS> or via L<perlrun/PERL5OPTS>

=head1 AUTHOR

Richard Clamp <richardc@unixbeard.net>

=head1 COPYRIGHT

Copyright (C) 2003 Richard Clamp. All Rights Reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<perlfunc/system>

=cut
