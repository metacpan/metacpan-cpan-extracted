use strict;
use warnings;

use Data::Dumper;
use Test::More;
use JavaScript::Duktape::XS;

sub test_cyclic_perl {
    my $duk = JavaScript::Duktape::XS->new();
    ok($duk, "created JavaScript::Duktape::XS object");

    my @array = qw/ 1 2 3 /;
    my %hash = ( "number" => 11, "string" => 'gonzo' );
    $hash{'array'} = \@array;
    $hash{'hash'} = \%hash;
    push @array, \%hash;
    push @array, \@array;
    # printf STDERR ("Perl: %s", Dumper({ array => \@array, hash => \%hash }));

    $duk->set('perl_array', \@array);
    $duk->set('perl_hash', \%hash);

    my $got_array = $duk->get('perl_array');
    my $got_hash = $duk->get('perl_hash');
    # printf STDERR ("Perl: %s", Dumper({ array => $got_array, hash => $got_hash }));

    is_deeply($got_array, \@array, "cyclic array roundtrip");
    is_deeply($got_hash, \%hash, "cyclic hash roundtrip");
}

sub main {
    test_cyclic_perl();
    done_testing;
    return 0;
}

exit main();
