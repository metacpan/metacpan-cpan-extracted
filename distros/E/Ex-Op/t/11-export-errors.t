#!perl
use 5.010;
use strict;
use warnings;
use lib 't/lib';
use Test::More;
use EO::Basic ();
use EO::BasicX ();
use EO::Twin qw(imp twin_is fresh);

no strict 'refs';

sub use_err {
    my ($mod, $pkg, $list) = @_;
    local $@;
    eval qq{package $pkg;\n#line 100 "fake.pl"\nuse $mod qw($list);\n1} and return undef;
    return $@;
}

{
    my $p = fresh();
    is( use_err('EO::Basic', $p, 'nope'),
        qq{"nope" is not exported by the EO::Basic module\n}
      . qq{Can't continue after import errors at fake.pl line 100.\n}
      . qq{BEGIN failed--compilation aborted at fake.pl line 100.\n},
        'one bad name: the message, file and line' );
    SKIP: {
        skip "Exporter $Exporter::VERSION prints its own warnings", 1 unless eval { Exporter->VERSION('5.70'); 1 };
        (my $x = use_err('EO::BasicX', fresh(), 'nope')) =~ s/BasicX/Basic/;
        $x =~ s/(import errors at fake\.pl line 100)\n/$1.\n/;
        is( $x, use_err('EO::Basic', fresh(), 'nope'), '... word for word as Exporter' );
    }
}

{
    my $p = fresh();
    is( use_err('EO::Basic', $p, 'nope g zip $s $nope &nope @nope'),
        qq{"nope" is not exported by the EO::Basic module\n}
      . qq{"zip" is not exported by the EO::Basic module\n}
      . qq{"\$nope" is not exported by the EO::Basic module\n}
      . qq{"nope" is not exported by the EO::Basic module\n}
      . qq{"\@nope" is not exported by the EO::Basic module\n}
      . qq{Can't continue after import errors at fake.pl line 100.\n}
      . qq{BEGIN failed--compilation aborted at fake.pl line 100.\n},
        'several bad names, & stripped from the report' );
    ok( !defined &{"${p}::g"}, 'nothing is installed when any name fails' );
    ok( !defined ${"${p}::s"}, '... not even the good scalar' );
}

{
    my $e = imp('EO::Basic', fresh(), 'nope');
    like( $e, qr/^"nope" is not exported by the EO::Basic module\nCan't continue after import errors at \(eval \d+\) line 1\.\n\z/,
          'a run-time import croaks at its caller' );
}

{
    local $@;
    ok( !eval q{ package EO::Opt; use Ex::Op qw(bogus); 1 }, 'an unknown option for Ex::Op' );
    like( $@, qr/^"bogus" is not exported by the Ex::Op module\nCan't continue after import errors at /,
          '... croaks the way Exporter does for itself' );
    ok( eval q{ package EO::Opt2; use Ex::Op qw(import); 1 }, q{use Ex::Op 'import' is accepted} )
        or diag $@;
    ok( defined &EO::Opt2::import, '... and installs import' );
}

twin_is( 'one bad name',     qw(nope) );
twin_is( 'bad and good',     qw(g nope $s) );
twin_is( 'sigils on bad',    qw($nope &nope @nope %nope *nope) );
twin_is( 'a version, a bad', '0.5', 'nope' );
twin_is( 'bad, then 0',      'nope', '0' );

done_testing;
