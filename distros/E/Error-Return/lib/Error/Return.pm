use 5.008;
use strict;
use warnings;

package Error::Return;
BEGIN {
  $Error::Return::VERSION = '1.110510';
}
# ABSTRACT: Really return() from a try/catch-block
use Scope::Upper qw(unwind want_at :words);
use Exporter qw(import);
our @EXPORT = qw(RETURN);

sub RETURN {
    my $context = SUB UP SUB UP SUB UP SUB;
    # read the context definition from right to left.
    # SUB == this sub: RETURN()
    # SUB UP SUB == the try() or catch() sub in which we're expected to run
    # SUB UP SUB UP SUB == the sub containing the try/catch block
    # SUB UP SUB UP SUB UP SUB == where we really want to return to

    # Do the cleanup that try() would normally do if the try-block had ended
    # without an exception; this is only necessary if using Error.pm, but
    # doesn't hurt if using Try::Tiny.

    shift @Error::STACK;
    unwind +(want_at($context) ? @_ : $_[0]) => $context;
}
1;


__END__
=pod

=head1 NAME

Error::Return - Really return() from a try/catch-block

=head1 VERSION

version 1.110510

=head1 SYNOPSIS

    use Try::Tiny;
    use Error::Return;

    sub foo {
        # ...
        try {
            # ...
            # return() here doesn't do what you might think it does
            RETURN 'bar';  # this actually returns from foo()
            # ...
        } catch {
            warn "caught error [$_]\n";
        };
        # ...
    }

=head1 DESCRIPTION

This module provides a way to return from within try/catch blocks with the
expected semantics.

=head1 FUNCTIONS

=head2 RETURN

A try/catch-block as provided by L<Try::Tiny> looks like the kind of block you
might use in a for-loop or an if/then/else statement. However, it is really an
anonymous subroutine, so if you C<return()> from a try-block or a catch-block,
you don't really return from the parent subroutine.

Like C<return> except that it doesn't just return to its upper scope but
smashes right through it to the next-higher scope. Actually, it skips two
scopes, because it has to return from the C<try()> subroutine as well.

C<RETURN> is automatically exported.

=head1 ALTERNATIVES

Without this module, if you really wanted to return from a try/catch-block's
parent subroutine, you would have to resort to something like this:

    use Try::Tiny;

    sub foo {
        ...
        my $should_return;
        try {
            ...
            $should_return = 1;
            ...
        } catch {
            ...
            # if we caught an exception, we should probably set
            # $should_return as well...
            ...
        };
        return if $should_return;
        ...
    }

=head1 PERFORMANCE

This module uses L<Scope::Upper>, so there is a performance impact. However, a
benchmark has shown that if used with L<Try::Tiny>, it only takes about 5%
more time than using the unsightly code given in the "ALTERNATIVES" section
above. That is because try/catch does quite a bit of work itself, so the
additional performance impact by munging scopes is not overly severe.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Error-Return>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Error-Return/>.

The development version lives at L<http://github.com/hanekomu/Error-Return>
and may be cloned from L<git://github.com/hanekomu/Error-Return.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

