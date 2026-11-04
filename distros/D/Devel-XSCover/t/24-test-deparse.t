use 5.020;
use strict;
use warnings;
use Test::More;
use B ();
use Devel::XSCover::Deparse ();

package Fake::Op {
    sub new { my ($class, %f) = @_; bless { flags => 0, kids => [], %f }, $class }
    sub type { $_[0]{type} // B::opnumber('custom') }
    sub name { $_[0]{name} }
    sub flags { $_[0]{flags} }
    sub first { $_[0]{kids}[0] // Fake::Null->new }
    sub sibling { my ($self) = @_; $self->{next} // Fake::Null->new }
}
package Fake::Null { our @ISA = ('B::NULL'); sub new { my $z = 0; bless \$z, shift } }

my $deparser = bless {}, 'B::Deparse';
{
    no warnings 'redefine';
    local *B::Deparse::deparse = sub { my ($self, $op) = @_; '<' . $op->name . '>' };

    my $bare = Fake::Op->new(name => 'frob');
    $B::Deparse::AUTOLOAD = 'B::Deparse::pp_frob';
    is(B::Deparse::AUTOLOAD($deparser, $bare, 0), 'frob()', 'a custom op without kids deparses as a call of nothing');

    my $c2 = Fake::Op->new(name => 'const', type => B::opnumber('const'));
    my $c1 = Fake::Op->new(name => 'padsv', type => B::opnumber('padsv'), next => $c2);
    my $pm = Fake::Op->new(name => 'pushmark', type => B::opnumber('pushmark'), next => $c1);
    my $op = Fake::Op->new(name => 'exop_call', flags => B::OPf_KIDS(), kids => [$pm]);
    $B::Deparse::AUTOLOAD = 'B::Deparse::pp_exop_call';
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, @_ };
    is(B::Deparse::AUTOLOAD($deparser, $op, 0), 'exop_call(<padsv>, <const>)', 'a custom op with kids deparses as a call of them, the pushmark dropped');
    is_deeply(\@warn, [], 'and no warning');

    $B::Deparse::AUTOLOAD = 'B::Deparse::pp_nosuchop';
    my $plain = Fake::Op->new(name => 'nosuchop', type => B::opnumber('const'));
    my $out = B::Deparse::AUTOLOAD($deparser, $plain, 0);
    is($out, 'XXX', 'an op that is not custom still goes to the original fallback');
    like($warn[0] // '', qr/unexpected OP_NOSUCHOP/, 'which warns as it did');

    my $typeless = Fake::Op->new(name => 'frob', kids => [Fake::Op->new(name => 'const', type => B::opnumber('const'))]);
    $B::Deparse::AUTOLOAD = 'B::Deparse::pp_frob';
    my $sub = sub { 'from the original' };
    {
        local $Devel::XSCover::Deparse::ORIGINAL = $sub;
        is(B::Deparse::AUTOLOAD($deparser, Fake::Thing->new, 0), 'from the original', 'an argument with no type method goes to the original');
        is(B::Deparse::AUTOLOAD($deparser, 'frob', 0), 'from the original', 'a plain string argument goes to the original');
        is(B::Deparse::AUTOLOAD($deparser), 'from the original', 'a call with no op goes to the original');
        $B::Deparse::AUTOLOAD = 'B::Deparse::not_a_pp_method';
        is(B::Deparse::AUTOLOAD($deparser, $bare, 0), 'from the original', 'a method that is not a pp_ one goes to the original, custom op or not');
    }

    my $unsiblinged = Fake::Op->new(name => 'const', type => B::opnumber('const'), next => 0);
    my $short = Fake::Op->new(name => 'frob', flags => B::OPf_KIDS(), kids => [$unsiblinged]);
    is(Devel::XSCover::Deparse::custom($deparser, $short, 0), 'frob(<const>)', 'a kid list that ends in a non reference ends there');

    my $firstless = Fake::Firstless->new(name => 'frob', flags => B::OPf_KIDS());
    is(Devel::XSCover::Deparse::custom($deparser, $firstless, 0), 'frob()', 'an op class without a first method has no kids to deparse');
}

package Fake::Thing { sub new { bless {}, shift } }
package Fake::Firstless {
    sub new { my ($class, %f) = @_; bless {%f}, $class }
    sub name { $_[0]{name} }
    sub flags { $_[0]{flags} }
}

ok(B::Deparse->can('pp_const'), 'B::Deparse is loaded and intact');

done_testing;
