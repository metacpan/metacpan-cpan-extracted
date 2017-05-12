use Test::More;

use strict;
use warnings;

BEGIN {
    eval "use IO::Capture::Stdout";
    plan skip_all => "IO::Capture::Stdout required" if $@;
    plan tests => 9;

    use_ok( 'File::SAUCE' );
}

eval 'use IO::Capture::Stdout';

my $filename = 't/data/W7-R666.ANS';
my $output   = <<'EOF';
  Sauce_id: SAUCE
   Version: 00
     Title: Route 666
    Author: White Trash
     Group: ACiD Productions
      Date: 04/01/1997
  Filesize: 42990
  Datatype: 1 (Character)
  Filetype: 1 (ANSi)
    Tinfo1: 80 (Width)
    Tinfo2: 180 (Height)
    Tinfo3: 0
    Tinfo4: 0
  Comments: 4
     Flags: 0 (None)
    Filler:                       
Comment_id: COMNT
  Comments: To purchase your white trash ansi:  send cash/check to
            keith nadolny / 41 loretto drive / cheektowaga, ny / 14225
            make checks payable to keith nadolny/us funds only
            5 dollars = 100 lines - 10 dollars = 200 lines
EOF

check_output( $filename, $output );

$filename = 't/data/NA-SEVEN.CIA';
$output   = <<'EOF';
  Sauce_id: SAUCE
   Version: 00
     Title: the seventh seal
    Author: napalm
     Group: cia
      Date: 10/10/1997
  Filesize: 40280
  Datatype: 1 (Character)
  Filetype: 1 (ANSi)
    Tinfo1: 80 (Width)
    Tinfo2: 25 (Height)
    Tinfo3: 0
    Tinfo4: 0
  Comments: 0
     Flags: 0 (None)
    Filler:                       
EOF

check_output( $filename, $output );

$output = <<'EOF';
  Sauce_id: SAUCE
   Version: 00
     Title: the seventh seal
    Author: napalm
     Group: cia
      Date: 10/10/1997
  Filesize: 40280
  Datatype: 1 (Character)
  Filetype: 99
    Tinfo1: 80
    Tinfo2: 25
    Tinfo3: 0
    Tinfo4: 0
  Comments: 0
     Flags: 0 (None)
    Filler:                       
EOF

check_output( $filename, $output, { filetype_id => 99 } );

$filename = 't/data/bogus.dat';
$output   = <<'EOF';
The file last read did not contain a SAUCE record
EOF

check_output( $filename, $output );

sub check_output {
    my ( $filename, $output, $special ) = @_;

    my $sauce = File::SAUCE->new( file => $filename );
    isa_ok( $sauce, 'File::SAUCE', 'SAUCE record' );

    $sauce->$_( $special->{ $_ } ) for keys %$special;

    my $capture = IO::Capture::Stdout->new;
    $capture->start;
    $sauce->print;
    $capture->stop;
    my @lines = $capture->read;

    is( join( '', @lines ), $output, 'Print' );
}
