use strict;
use warnings;
use Test::More 0.96;
use File::pushd;

my @warnings;

$SIG{__WARN__} = sub {
    push @warnings, $_[0];
};

{
    no warnings 'void';

    @warnings = ();
    pushd; # Calling in void context
    is_deeply( \@warnings, [], 'no warning if "void" category disabled' );
    @warnings = ();
    tempd; # Calling in void context
    is_deeply( \@warnings, [], 'no warning if "void" category disabled' );

    @warnings = ();
}

{
    no warnings;
    use warnings 'void';

    @warnings = ();
    #<<< No perltidy
    pushd; # Calling in void context
    my $expected = 'Useless use of File::pushd::pushd in void context at '.__FILE__.' line '.(__LINE__-1);
    #>>>
    is( scalar @warnings, 1, "pushd: got one warning" );
    like( $warnings[0], qr/^\Q$expected\E/, 'warning if "void" category enabled' );

    @warnings = ();
    #<<< No perltidy
    tempd; # Calling in void context
    $expected = 'Useless use of File::pushd::tempd in void context at '.__FILE__.' line '.(__LINE__-1);
    #>>>
    is( scalar @warnings, 1, "tempd: got one warning" );
    like( $warnings[0], qr/^\Q$expected\E/, 'warning if "void" category enabled' );

    @warnings = ();
}

done_testing;
