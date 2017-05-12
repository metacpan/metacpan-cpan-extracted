use 5.008;
use strict;
use warnings FATAL => 'all';

package Log::Log4perl::Lazy;
no strict 'refs';
no warnings 'redefine';

use Carp qw(croak);
use Params::Lazy;
require Log::Log4perl;

my @available_levels = qw(TRACE DEBUG INFO WARN ERROR FATAL);
my %is_available_level = map {$_ => 1} @available_levels;

sub import {
    my ($self_pkg, @levels) = @_;
    my $caller_pkg = caller;

    if (@levels == 0) {
        @levels = @available_levels;
    } else {
        for my $level (@levels) {
            unless ($is_available_level{$level}) {
                croak qq("$level" is not exported by the $self_pkg module);
            }
        }
    }

    my $logger = Log::Log4perl->get_logger($caller_pkg);
    my @defined_levels;

    for my $level (@levels) {
        my $method = lc($level);
        my $is_method = "is_$method";

        *{$caller_pkg.'::'.$level} = sub {
            if ($logger->$is_method) {
                local $Log::Log4perl::caller_depth =
                      $Log::Log4perl::caller_depth + 1;
                $logger->$method(force($_[0]));
            }
        };

        push @defined_levels, $level;
    }

    Params::Lazy->import(map {
        $caller_pkg.'::'.$_ => '^'
    } @defined_levels);
}

=head1 NAME

Log::Log4perl::Lazy - Lazily evaluate logging arguments

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

    use Log::Log4perl::Lazy;
    DEBUG 'debug message';

=head1 EXPORT

C<TRACE>, C<DEBUG>, C<INFO>, C<WARN>, C<ERROR>, and C<FATAL>

=head1 DESCRIPTION

This module is an extension of L<Log::Log4perl>.

You can simply write something like this:

    DEBUG 'obj = '.slow_func($obj);

where the argument of the C<DEBUG> subroutine will be *lazily* evaluated.

This means, if the DEBUG level is not enabled for the current package,
the argument is not evaluated at all. As a result, C<slow_func> is not
called when it is unnecessary.

It allows you to avoid writing the if-statements everywhere like this:

    use Log::Log4perl qw(get_logger);
    my $logger = get_logger;
    $logger->debug('obj1 = '.slow_func($obj1)) if $logger->is_debug;
    $logger->debug('obj2 = '.slow_func($obj2)) if $logger->is_debug;
    $logger->debug('obj3 = '.slow_func($obj3)) if $logger->is_debug;

while you don't need to worry about the performance overhead of C<slow_func>
in the production code.

=head1 LIMITATIONS

The current version does not support the object-oriented interface.

With the non-OO subroutines, although C<Log::Log4perl> allows you to pass
as many arguments as you want, this module only allows you to pass one
argument.

    # This does not work with Log::Log4perl::Lazy.
    DEBUG 'a', 'b', 'c';

    # You should concatenate the argument into one.
    DEBUG 'a'.'b'.'c';

In the above, if the debug level is not enabled, the concatenation will
not take place, so no worries about overhead!

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-log-log4perl-lazy at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Log-Log4perl-Lazy>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Log::Log4perl::Lazy

You can also look for information at:

=over 4

=item * GitHub repository (report bugs here)

L<https://github.com/mahiro/perl-Log-Log4perl-Lazy>

=item * RT: CPAN's request tracker (report bugs here, alternatively)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Log4perl-Lazy>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Log4perl-Lazy>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Log-Log4perl-Lazy>

=item * Search CPAN

L<http://search.cpan.org/dist/Log-Log4perl-Lazy/>

=back

=head1 ACKNOWLEDGEMENTS

L<Log::Log4perl>, L<Params::Lazy>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Log::Log4perl::Lazy
