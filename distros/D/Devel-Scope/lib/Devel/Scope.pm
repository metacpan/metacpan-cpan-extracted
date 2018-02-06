package Devel::Scope;

use 5.006;
use strict;
use warnings;

use List::Util qw( min );
use Scope::Upper qw( SCOPE );
use Term::Colormap qw( colormap print_colored_text );
use Time::HiRes qw( tv_interval gettimeofday );

require Exporter;
our @ISA       = qw( Exporter );
our @EXPORT_OK = qw( debug );

our $VERSION = '0.05';

my $env_prefix = 'DEVEL_SCOPE_';
my @env_vars_maybe = grep { m|^$env_prefix| } keys %ENV;

my %config = (
    'DEVEL_SCOPE_DEPTH'                => 0,
    'DEVEL_SCOPE_MIN_DECIMAL_PLACES'   => 10,
    'DEVEL_SCOPE_TIME_FORMAT'          => '%06f',
    'DEVEL_SCOPE_TIME_LOG_BASE'        => 5,
    'DEVEL_SCOPE_TIME_LOG_OFFSET'      => 4,
);

for my $env_var (@env_vars_maybe) {
    if ( not defined $config{$env_var} ) {
        print "Invalid " . __PACKAGE__ . " env variable '$env_var'\n";
        print "Possible variable names: [name=default]\n";
        for my $key ( sort keys %config ) {
            print "    " . $key . '=' . $config{$key} . "\n";
        }
        die "\n";
    } else {
        $config{ $env_var } = $ENV{ $env_var };
    }
}

my $time_format = $config{'DEVEL_SCOPE_TIME_FORMAT'};
my $format_total_and_elapsed = "[ $time_format : $time_format ]";

my $debug_min_elapsed = 10 ** (-1 * $config{'DEVEL_SCOPE_MIN_DECIMAL_PLACES'} );
my $log_base = log( $config{ 'DEVEL_SCOPE_TIME_LOG_BASE' } );

#               blue  cyan  green  yellow  orange  red
my $colormap = [ 201,   51,    46,    226,    202, 196 ];

my $start_time = [ gettimeofday ];
my $tic = $start_time;

debug("Using " . __PACKAGE__ . ' with ');
for my $key (sort keys %config) {
    debug("    " . $key . '=' . $config{$key});
}
debug("-"x40);

sub debug {
    return if not defined $ENV{'DEVEL_SCOPE_DEPTH'};

    my $toc = [ gettimeofday ];

    my ($message) = join(' ', @_);
    my $depth = SCOPE(1);

    my ($pack0, $file0, $line0) = caller(); # If in main
    return if ($depth > $config{'DEVEL_SCOPE_DEPTH'}) and ($pack0 ne __PACKAGE__);

    my ($package, $filename, $line, $subroutine) = caller(1);
    if (defined $subroutine) {
        if ($subroutine eq 'main::' or $subroutine eq '(eval)') {
            $subroutine = '';
        } else {
            $subroutine .= "()";
        }
    } else {
        $line = $line0;
        $subroutine = '';
        $filename = $file0;
    }

    my $elapsed = tv_interval( $tic, $toc );
    return unless $elapsed >= $debug_min_elapsed;

    my $total_elapsed = tv_interval( $start_time, $toc );
    my $time_output = sprintf($format_total_and_elapsed,
                              $total_elapsed, $elapsed);

    # Time level capped at the number of colors in our colormap
    my $time_level = int( $config{'DEVEL_SCOPE_TIME_LOG_OFFSET'}
                          + ( log($elapsed) / $log_base ));

    output("$time_output D-$depth $filename $line $subroutine : ");
    if ($time_level > 0) {
        # Highligh longer running steps with stars (* = fastish, ***** = slow )
        my $color_index = min($time_level, $#$colormap);
        print_colored_text($colormap->[$color_index],
                           "(" . ('*'x$time_level) . ")");
        print " : ";
    }
    output("$message\n");
    $tic = [ gettimeofday ];
}

sub output {
    my ($msg) = @_;

    {
        local $| = 1;
        print $msg;
    }
}

1; # End of Devel::Scope

__END__

=head1 NAME

Devel::Scope - Scope based debug

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

Provide a debug method that outputs conditionally based on the scoping level.

    use Devel::Scope qw( debug );

    debug("main"); # Main Scope

    sub foo {
        debug("inside foo"); # Function Scope
        if ( 1 ) {
            debug("if true start calculations"); # Function Scope + 1
            for my $x ( 0..3 ) {
                debug("x is set to $x"); # Function Scope + 2
                for my $y ( 0..3 ) {
                    debug("x=$x, y=$y"); # Function Scope + 3
                    for my $z ( 0 ..3 ) {
                        debug("x=$x, y=$y, z=$z"); # Function Scope + 4
                    }
                }
            }
            debug("end of calculaions");
        }
        debug("leaving foo");
    }

    ...

    DEVEL_SCOPE_DEPTH=3 perl foo.pl

=head1 EXPORT

    debug

=head1 SUBROUTINES/METHODS

=head2 debug

    Prints only when the scope is greater (deeper) than some number.
    Turns into a NO-OP unless DEVEL_SCOPE_DEPTH environmental variable is set.

=cut

=head1 AUTHOR

Felix Tubiana, C<< <felixtubiana at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-devel-debug-scope at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Scope>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Devel::Scope


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Scope>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Devel-Scope>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Devel-Scope>

=item * Search CPAN

L<http://search.cpan.org/dist/Devel-Scope/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Felix Tubiana.

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

