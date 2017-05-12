# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use Devel::Peek;
BEGIN { plan tests => 13 };
use HTML::SyntaxHighlighter;
ok(1); # If we made it this far, we're ok.

#########################

# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

my $file = 't/example.xhtml';

my $hli;
my $data;
my $outfile = 't/output.test';

ok( $hli = HTML::SyntaxHighlighter->new() );
ok( $hli->parse_file( $file ) );

ok( $hli->out_func(\$data) );
ok( $hli->parse_file( $file ) );
ok( $data );

ok( $hli->header(1) );
ok( $hli->force_type(1) );
ok( $hli->debug(1) );
ok( $hli->br('<br>') );

open OUTFILE, ">$outfile";
ok( $hli->out_func( \*OUTFILE) );
ok( $hli->parse_file( $file ) );
close OUTFILE;

ok( -s $outfile );
#unlink( $outfile );

1;
