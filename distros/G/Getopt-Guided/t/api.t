use Test2::V1
  -pragmas,
  -target => { MODULE => 'Getopt::Guided' },
  qw( dies like imported_ok plan );
BEGIN { MODULE->import( ':all' ) }

plan 2;

{
  no strict 'refs'; ## no critic ( ProhibitNoStrict )
  imported_ok @{ MODULE . '::EXPORT_OK' }
}

like dies { MODULE->import( 'private' ) }, qr/not exported/, 'Export error'
