use strict;
use warnings;
use Test::More;

use MARC::Parser::RAW;

my $data
    = '00755cam  22002414a 4500001001300000003000600013005001700019008004100036010001700077020004300094040001800137042000800155050002600163082001700189100003100206245005400237260004200291300007200333500003300405650003700438630002500475630001300500fol05731351 IMchF20000613133448.0000107s2000    nyua          001 0 eng    a   00020737   a0471383147 (paper/cd-rom : alk. paper)  aDLCcDLCdDLC  apcc00aQA76.73.P22bM33 200000a005.13/32211 aMartinsson, Tobias,d1976-10aActivePerl with ASP and ADO /cTobias Martinsson.  aNew York :bJohn Wiley & Sons,c2000.  axxi, 289 p. :bill. ;c23 cm. +e1 computer  laser disc (4 3/4 in.)  a"Wiley Computer Publishing." 0aPerl (Computer program language)00aActive server pages.00aActiveX.';

open my $fh, '<', \$data or die "cannot open file";

new_ok( 'MARC::Parser::RAW' => ['./t/camel.mrc'] );
new_ok( 'MARC::Parser::RAW' => [ './t/camel.mrc', 'UTF-8' ] );
new_ok( 'MARC::Parser::RAW' => [ \$data ] );
new_ok( 'MARC::Parser::RAW' => [$fh] );
can_ok( 'MARC::Parser::RAW', qw{ next } );

my $failure = eval { MARC::Parser::RAW->new() };
is( $failure, undef, 'croak missing argument' );
$failure = eval { MARC::Parser::RAW->new('./t/camel.mrk') };
is( $failure, undef, 'croak cannot find file' );
$failure = eval { MARC::Parser::RAW->new( './t/camel.mrc', 'XXX-0' ) };
is( $failure, undef, 'croak unavailable encoding' );

my $parser = MARC::Parser::RAW->new('./t/camel.mrc');
my $record = $parser->next();
is_deeply( $record->[0],
    [ 'LDR', undef, undef, '_', '00755cam  22002414a 4500' ], 'LDR' );
is_deeply( $record->[1], [ '001', undef, undef, '_', 'fol05731351 ' ],
    'first field' );
is_deeply( $record->[6],
    [ '020', ' ', ' ', 'a', '0471383147 (paper/cd-rom : alk. paper)' ],
    'sixth field' );

{
    my @warnings;
    local $SIG{__WARN__} = sub {
        push @warnings, @_;
    };
    my $record = $parser->next();
    is_deeply(
        $record->[0],
        [ 'LDR', undef, undef, '_', '00665nam  22002298a 4500' ],
        'skipped faulty records'
    );
    is scalar(@warnings), 4, 'got warnings';
    like $warnings[0], qr{no fields found in record},
        'carp no fields found in record';
    like $warnings[1], qr{no valid record leader found in record},
        'carp no valid record leader found in record';
    like $warnings[2], qr{different number of tags and fields in record},
        'carp different number of tags and fields in record';
    like $warnings[3], qr{incomplete directory entry in record},
        'carp incomplete directory entry in record';
}

done_testing;
