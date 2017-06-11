use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

use Inline C => Config => USING => 'Inline::C::Parser::RegExp';
use Inline C => <<'EOC';

void foo() {
     printf( "Hello World\n" );
}

void foo2() {
     Inline_Stack_Vars;
     int i;

     Inline_Stack_Reset;

     if(0) printf( "Hello World again\n" ); /* tests balanced quotes bugfix */

     for(i = 24; i < 30; ++ i) Inline_Stack_Push(sv_2mortal(newSViv(i)));

     Inline_Stack_Done;
     Inline_Stack_Return(6);
}

EOC

my @z = foo2();

is(scalar(@z), 6);

done_testing;
