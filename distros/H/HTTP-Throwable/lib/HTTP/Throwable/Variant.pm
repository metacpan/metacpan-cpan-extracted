package HTTP::Throwable::Variant;
our $AUTHORITY = 'cpan:STEVAN';
$HTTP::Throwable::Variant::VERSION = '0.026';
use strict;
use warnings;

use Package::Variant 1.002000
  importing => ['Moo', 'MooX::StrictConstructor'],
  subs      => [ qw(extends with) ];

sub make_variant {
    my ($class, $target_package, %arguments) = @_;
    extends @{ $arguments{superclasses} }
        if  @{ $arguments{superclasses} };
    with @{ $arguments{roles} };
}

1;

=pod

=encoding UTF-8

=head1 NAME

HTTP::Throwable::Variant - a package that constructs Moo-based HTTP::Throwables for you

=head1 VERSION

version 0.026

=head1 OVERVIEW

This package is used by L<HTTP::Throwable::Factory> to build
exceptions at runtime.  The exceptions are L<Moo>-based, with
L<MooX::StrictConstructor> applied as well.  It takes two arguments:
C<superclasses>, an arrayref of classes to extend, and C<roles>, an
arrayref of roles to compose.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Ricardo Signes <rjbs@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

# ABSTRACT: a package that constructs Moo-based HTTP::Throwables for you

#pod =head1 OVERVIEW
#pod
#pod This package is used by L<HTTP::Throwable::Factory> to build
#pod exceptions at runtime.  The exceptions are L<Moo>-based, with
#pod L<MooX::StrictConstructor> applied as well.  It takes two arguments:
#pod C<superclasses>, an arrayref of classes to extend, and C<roles>, an
#pod arrayref of roles to compose.
