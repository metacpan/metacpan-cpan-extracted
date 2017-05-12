use strict;
use warnings;

use utf8;
use Test::More;
use JSON::Any;

$ENV{JSON_ANY_CONFIG} = "utf8=1";

sub run_tests_for {
    my $backend = shift;
    note "testing backend $backend";
    my $j = eval {
        JSON::Any->import($backend);
        JSON::Any->new;
    };

    note "$backend: " . $@ and next if $@;

    $j and $j->handler or return;

    note "handler is " . ( ref( $j->handler ) || $j->handlerType );

    foreach my $text (qw(foo שלום)) {

        my $struct = [$text];

        my $frozen = $j->encode($struct);
        my $thawed = $j->decode($frozen);

        ok( utf8::is_utf8($frozen) || !scalar( $frozen !~ /[\w\d[:punct:]]/ ),
            "json output is utf8" );

        is_deeply( $thawed, $struct, "deeply" );

        compare_strings($thawed->[0], $text);

        ok( utf8::is_utf8( $thawed->[0] ) || !scalar( $text !~ /[a-z]/ ),
            "text is utf8 if it needs to be" );

        if ( utf8::valid($frozen) ) {
            utf8::decode($frozen);

            my $thawed = $j->decode($frozen);

            is_deeply( $thawed, $struct, "deeply" );

            compare_strings($thawed->[0], $text);

            ok( utf8::is_utf8( $thawed->[0] ) || !scalar( $text !~ /[a-z]/ ),
                "text is utf8 if it needs to be" );
        }
    }
}

sub compare_strings {
    my ($got, $expected) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    is( $got, $expected, "text is the same" ) && return;

    require Data::Dumper;
    no warnings 'once';
    local $Data::Dumper::Terse = 1;

    binmode $_, ':utf8' foreach 'STDOUT', 'STDERR',
        map { Test::Builder->new->$_ } qw(output failure_output);

    diag 'raw form: ', Data::Dumper::Dumper({
        got => $got,
        expected => $expected,
        got_is_utf8 => (utf8::is_utf8($got) ? 1 : 0),
    });
}

{
    run_tests_for 'XS';
}

{
    require Test::Without::Module;
    Test::Without::Module->import('JSON::XS');
    run_tests_for $_ for (qw(PP JSON CPANEL DWIW));
}


done_testing;
