use strict;
use warnings;

use File::Temp qw{tempfile};
use Test::More 0.88;	# Because of done_testing();

my $HAS_PLUTIL  = -x '/usr/bin/plutil';

{
    my $class = 'Mac::PropertyList';
    my @exports = qw{parse_plist plist_as_string};

    use_ok $class, @exports or BAIL_OUT( "$class did not compile\n" );
    can_ok $class, @exports;
}

{
    my $class = 'Mac::PropertyList::WriteBinary';
    my @exports = qw{as_string};

    use_ok $class, @exports or BAIL_OUT( "$class did not compile\n" );
    can_ok $class, @exports;
}

my $ORIGINAL_PLIST = create_plist();
my $BINARY_PLIST = as_string($ORIGINAL_PLIST);

subtest 'Mac::PropertyList' => sub {
    is_deeply(parse_plist($BINARY_PLIST), $ORIGINAL_PLIST, 'Round trip');
};

subtest 'plutil' => sub {
    plan skip_all => 'Test requires plutil' unless $HAS_PLUTIL;

    my( $temp_fh, $temp_filename ) = tempfile();
    binmode $temp_fh;
    print { $temp_fh } $BINARY_PLIST;

    is_deeply(
        parse_plist( slurp_plutil($temp_filename) ),
        $ORIGINAL_PLIST,
        'Round-trip via Mac::PropertyList and plutil' );


    seek $temp_fh, 0, 0;
    binmode $temp_fh, ':encoding(utf-8)';
    print { $temp_fh } plist_as_string( $ORIGINAL_PLIST );

    is_deeply(
        parse_plist( slurp_plutil($temp_filename) ),
        $ORIGINAL_PLIST,
        'Round-trip via plutil and Mac::PropertyList' );

};

done_testing();

sub create_plist {
    my @integers;
    foreach my $value ( qw{
            0
            1
            255
            256
            65535
            65536
            4294967295
            4294967296
            9223372036854775807
            -1
            -255
            -256
            -65536
            -4294967296
            -9223372036854775808
        }
    ) {
        push @integers, Mac::PropertyList::integer->new( $value );
    }
    return Mac::PropertyList::dict->new(
        {
            integers    => Mac::PropertyList::array->new( \@integers ),
        },
    );
}

sub slurp_plutil {
    my( $from_filename ) = @_;
    my $binary = -B $from_filename;
    my ( $encoding, $format ) = -B $from_filename ? ( qw{raw binary1} )
    : ( qw{encoding(utf-8) xml1} );
    my $pipe_fh;
    open $pipe_fh, "-|:$encoding",
        qw{plutil -convert}, $format, qw{-o -}, $from_filename
        or do {
        my ( undef, $file, $line ) = caller;
        BAIL_OUT "Failed to pipe from plutil: $! at $file line $line";
    };
    local $/ = undef;   # slurp mode
    return <$pipe_fh>;
}

# ex: set textwidth=72 tabstop=4 expandtab :
