use strict;
use warnings;

use Test::More tests => 7;

use Digest::Whirlpool;

=head1 DESCRIPTION

Test the XS constructor, should be equivalent to:

    sub new
    {
        my $proto = shift;
        bless {}, ref $proto || $proto;
    }

These tests are taken from the (as of writing) yet-to-be released
L<Cwlib> (unix-cw wrapper) test suite.

=head1 TESTS

=over

=cut

=item * Plain object construction works

=cut

{
    my $cw = Digest::Whirlpool->new;
    isa_ok($cw, 'Digest::Whirlpool');
}


=item * Direct call to the constructor using a READONLY SV

=cut

{
    my $cw = Digest::Whirlpool::new('Digest::Whirlpool');
    isa_ok($cw, 'Digest::Whirlpool');
}

=item * Direct call to the constructor using a normal SV

=cut

{
    my $pkg = 'Digest::Whirlpool';
    my $cw = Digest::Whirlpool::new($pkg);
    isa_ok($cw, $pkg);
}

=item * Direct call to the constructor using a non-existing package name

=cut

{
    my $pkg = 'Digest::Whirlpool::Subclass::One';
    my $cw = Digest::Whirlpool::new($pkg);
    isa_ok($cw, $pkg);
}

=item * Direct call to the constructor using an existing package name

=cut

{
    package Digest::Whirlpool::Subclass::Two;
    package main;
    my $pkg = 'Digest::Whirlpool::Subclass::Two';
    my $cw = Digest::Whirlpool::new($pkg);
    isa_ok($cw, $pkg);
}

=item * Construction using a package reference.

=cut

{
    my $cw = Digest::Whirlpool->new->new;
    isa_ok($cw, 'Digest::Whirlpool');
}

=item * Construction of a subclassed package

=cut

{
    package Digest::Whirlpool::Subclass::Three;
    use strict;
    use warnings;

    BEGIN { our @ISA = 'Digest::Whirlpool' }

    package main;

    my $pkg = 'Digest::Whirlpool::Subclass::Three';
    my $cw = $pkg->new;
    isa_ok($cw, $pkg);
}

=back

=cut
