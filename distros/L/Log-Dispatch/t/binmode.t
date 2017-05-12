use strict;
use warnings;

use File::Spec;
use File::Temp qw( tempdir );
use Test::More 0.88;

use Log::Dispatch;
use Log::Dispatch::File;

## no critic (ControlStructures::ProhibitNegativeExpressionsInUnlessAndUntilConditions)
plan skip_all => "Cannot test utf8 files with this version of Perl ($])"
    unless $] >= 5.008;

my $dir = tempdir( CLEANUP => 1 );

my %params = (
    name      => 'file',
    min_level => 'debug',
    filename  => File::Spec->catfile( $dir, 'logfile_X.txt' ),
);

my @tests = (
    {
        params           => { %params, 'binmode' => ':utf8' },
        message          => "foo bar\x{20AC}",
        expected_message => "foo bar\xe2\x82\xac",
    },
);

my $count = 0;
for my $t (@tests) {
    my $dispatcher = Log::Dispatch->new();
    ok( $dispatcher, 'got a logger object' );

    $t->{params}{filename} =~ s/X\.txt$/$count++ . '.txt'/e;
    my $file = $t->{params}{filename};

    my $logger = Log::Dispatch::File->new( %{ $t->{params} } );
    ok( $logger, 'got a file output object' );

    $dispatcher->add($logger);
    $dispatcher->log( level => 'info', message => $t->{message} );

    ok( -e $file, "$file exists" );

    open my $fh, '<', $file or die $!;
    my $line = do { local $/ = undef; <$fh> };
    close $fh or die $!;

    is( $line, $t->{expected_message}, 'output contains UTF-8 bytes' );
}

done_testing();

