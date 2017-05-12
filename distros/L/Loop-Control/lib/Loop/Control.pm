use 5.008;
use strict;
use warnings;

package Loop::Control;
our $VERSION = '1.100861';
# ABSTRACT: FIRST and NEXT functions for loops
use Scope::Upper qw(reap :words);
use Exporter qw(import);
our @EXPORT  = qw(FIRST NEXT);

sub callstack_depth {
    my $depth = 0;
    while (caller($depth)) { $depth++ }
    $depth;
}

sub FIRST (&) {
    my $code = shift;
    my ($package, $filename, $line) = caller;
    my $callstack_depth = callstack_depth();
    my $key             = "FIRST $package $filename $line $callstack_depth";
    our %seen;
    unless ($seen{$key}++) {
        $code->();
    }
    reap sub { delete $seen{$key} } => UP UP;
}

sub NEXT (&) {
    my $code = shift;
    reap sub { $code->() } => UP;
}
1;


__END__
=pod

=head1 NAME

Loop::Control - FIRST and NEXT functions for loops

=head1 VERSION

version 1.100861

=head1 SYNOPSIS

    use Loop::Control;

    for (1..10) {
        FIRST { print "called only in the first iteration" };
        FIRST { print "also called only in the first iteration" };
        # do things
        NEXT { print "called at the end of each iteration" };
        NEXT { print "also called at the end of each iteration" };
        # do more things
        next if rand() < 0.5
        # the NEXT code will be executed even if the loop is ended with next()
    }

=head1 DESCRIPTION

This module provides ways to execute code at certain points in a C<for> or
C<while> loop that are outside the normal control flow. For example, you could
have code that executes only during the first iteration of a loop, or code that
executes after every iteration of the loop, regardless of how the iteration
ended (normally or via C<next>). 

=head1 METHODS

=head2 FIRST

Automatically exported, this function is meant to be placed inside a C<for> or
C<while> loop. It takes a code block which it will execute only during the
first iteration of the loop. They block is run at the point where the C<FIRST>
statement occurs. You can specify several C<FIRST> blocks in a loop. If the
loop is called recursively, each recursion level is treated as a separate loop.

The block will have additional entries in the call stack, that is, C<caller()>
will not show the same results as the code that is placed directly in the loop.

=head2 NEXT

Automatically exported, this function is meant to be placed inside a C<for> or
C<while> loop. It takes a code block which it will execute after each iteration
of the loop, regardless of whether the loop iteration ended normally or via
C<next>. You can specify several C<NEXT> blocks in a loop, and they will be run
in the reverse order in which they were encountered.

The block will have additional entries in the call stack, that is, C<caller()>
will not show the same results as the code that is placed directly in the loop.

=head2 callstack_depth

Convenience function that returns the number of levels on the call stack, that
is, the maximum number for which C<caller($i)> will return data. The number
includes the call stack entry for C<callstack_depth()> itself. This function is
used by C<NEXT> and is not exported.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Loop-Control>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Loop-Control/>.

The development version lives at
L<http://github.com/hanekomu/Loop-Control/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

