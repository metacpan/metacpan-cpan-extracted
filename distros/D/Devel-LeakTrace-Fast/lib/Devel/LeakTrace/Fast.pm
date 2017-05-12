package Devel::LeakTrace::Fast;

require 5.006;

use strict;
use warnings;
use base 'DynaLoader';

BEGIN {
    our $VERSION = '0.11';
    bootstrap Devel::LeakTrace::Fast $VERSION;
    _hook_runops();
}

INIT {
    _reset_counters();
}

END {
    _show_used();
}

1;

__END__

=head1 NAME

Devel::LeakTrace::Fast - indicate where leaked variables are coming from.

=head1 SYNOPSIS

  perl -MDevel::LeakTrace::Fast -e '{ my $foo; $foo = \$foo }'
  leaked SV(0x528d0) from -e line 1
  leaked SV(0x116a10) from -e line 1

=head1 DESCRIPTION

Devel::LeakTrace::Fast is a rewrite of Devel::LeakTrace. Like
Devel::LeakTrace it uses the pluggable runops feature found in perl 5.6
and later in order to trace SV allocations of a running program.

At END time Devel::LeakTrace::Fast identifies any remaining variables, and
reports on the lines in which the came into existence.

Note that by default state is first recorded during the INIT phase.
As such the module will not pay attention to any scalars created
during BEGIN time.  This is intentional as symbol table aliasing is
never released before the END times and this is most common in the
implicit BEGIN blocks of C<use> statements.

=head1 TODO

Improve the documentation.

Clustering of reports if they're from the same line.

Stack backtraces to suspect lines.

=head1 AUTHOR

Andy Armstrong <andy@hexten.net>

Originally based on code by Richard Clamp that carried this attribution:

Richard Clamp <richardc@unixbeard.net> with portions of LeakTrace.xs
taken from Nick Ing-Simmons' Devel::Leak module.

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

L<Devel::Leak>, L<Devel::Cover>

=cut
