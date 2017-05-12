#
# Error/Wait.pm
#
# $Author: grazz $
# $Date: 2003/12/23 16:32:42 $
#

package Error::Wait;

use 5.006;
our $VERSION = '0.05';

use strict;
use warnings;

use POSIX;
use Config;

our $ERR;  # alias to original $?

sub TIESCALAR { bless [], shift }
sub FETCH     { return $_[0] }
sub STORE     { $ERR = $_[1] }

use overload '""' => \&stringify,
             '0+' => sub { $ERR },
             bool => sub { $ERR },
             fallback => 1;

my @names = split ' ', $Config{sig_name};

sub stringify {
    return $! if $ERR < 0;

    if (WIFEXITED($ERR)) {
	my $status = WEXITSTATUS($ERR);
	return "Exited: $status";
    }
    if (WIFSIGNALED($ERR)) { 
	my $sig = WTERMSIG($ERR);
	return "Killed: $names[$sig]";
    }
    if (WIFSTOPPED($ERR)) { 
	my $sig = WSTOPSIG($ERR);
	return "Stopped: $names[$sig]";
    }

    return $ERR;  # shouldn't get here
}

#
# the WIF* macros aren't really as portable as "$? >> 8"
#
eval { WIFEXITED(0) };
if ($@) {
    no warnings 'redefine';
    *WIFEXITED   = sub { 0 == ($_[0] & 0xff) };
    *WEXITSTATUS = sub { $_[0] >> 8 };
    *WIFSIGNALED = sub { $_[0] & 0xff };
    *WTERMSIG    = sub { $_[0] & 0xff };
}

#
# save the original $? and get it out of harm's way
#
(*ERR, *?) = \($?, $ERR);
tie $?, __PACKAGE__;

1;

__END__

=head1 NAME

Error::Wait - User-friendly version of C<$?>

=head1 SYNOPSIS

  use Error::Wait;

  system('/no/such/file') == 0 or die $?;   # "No such file or directory"
  system('/bin/false')    == 0 or die $?;   # "Exited: 1"
  system('kill -HUP $$')  == 0 or die $?;   # "Killed: HUP"

=head1 DESCRIPTION

Error::Wait overloads the stringification of C<$?> to provide sensible
error messages.  Numeric and boolean operations continue to work as usual,
so code using C<<< $? >> 8 >>> won't break.

=head1 SEE ALSO

L<perlvar/$?>, L<perlfunc/system>, L<perlport/system>

=head1 KNOWN ISSUES

C<$?> and the C<wait.h> macros aren't very portable.

=head1 BUGS

Please report them to the author.

=head1 AUTHOR

Steve Grazzini <grazz@pobox.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Steve Grazzini

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

