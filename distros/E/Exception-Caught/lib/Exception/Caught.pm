package Exception::Caught;

# ABSTRACT: Sugar for class-based exception handlers

use warnings;
use strict;

use Scalar::Util qw(blessed);
use namespace::clean qw(blessed);

use Sub::Exporter::Lexical ();
use Sub::Exporter -setup => {
    installer => Sub::Exporter::Lexical::lexical_installer, 
    exports => [qw(caught rethrow)],
    groups  => {
        default => [qw(caught rethrow)]
    },
};

sub caught { 
    my $class = shift;
    my $e     = @_ > 0 ? $_[0] : $_;
    blessed($e) && $e->isa($class);
}

sub rethrow { 
    my $e = @_ > 0 ? $_[0] : $_;
    blessed($e) && $e->can('rethrow') ? $e->rethrow : die $e 
}

no namespace::clean;

1;



=pod

=head1 NAME

Exception::Caught - Sugar for class-based exception handlers

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Try::Tiny;
    use Exception::Caught;
    use Exception::Class qw(MyException);

    try {
        MyException->throw();
    }
    catch {
        rethrow unless caught('MyException');
        # do something special with $_
    };

=head1 WHY?

Doing different things with an exception based on its class is a common
pattern. L<TryCatch> does a good job with this, but is a bit heavyweight.
L<Try::Tiny> is nice and lightweight, but doesn't help out with the type
dispatching problem. Hence, this module. You don't have to use it with
Try::Tiny, but that's what it's best at.

=head1 EXPORTS

Exception::Caught uses L<Sub::Exporter>, so see that module if you want to
rename these subroutines to something else.  The subs are only exported for
your lexical scope so that you don't get extra methods/subs in your
package/class. If this isn't what you want, consider using L<Sub::Import>.

C<caught> and C<rethrow> are exported by default.

=head2 caught(classname, exception?)

Returns true if the exception (optional argument, defaults to $_) passes isa()
for the given classname.

=head2 rethrow(exception?)

Calls rethrow on the exception (optional argument, defaults to $_) if it is an
object with a rethrow method, otherwise just dies with the exception.

=head1 AUTHOR

Paul Driver <frodwith@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Paul Driver <frodwith@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

