use Test::More tests => 6;

BEGIN {
    use_ok('Devel::SearchINC', 't/lib');
    use_ok('C::D::F');
    use_ok('C::D::F::G');

    # use_ok('E');
    local $@;
    my $bad_module = 'AModuleThatIsDefinitelyNotThere';
    eval "use $bad_module;";
    like($@, qr/Can't locate $bad_module/, 'non-existing module');
}
is(C::D::F::answer(),    42, 'C::D::F::answer is 42');
is(C::D::F::G::answer(), 42, 'C::D::F::G::answer is 42');

# is(E::answer(), 42, 'E::answer is 42');
