use Test::Simple 'no_plan';
use strict;
use lib './lib';
use vars qw($_part $cwd);
use Smart::Comments '###';

use LEOCHARRE::Strings ':all';



my @tests_shomp = (
   [' this is ' => 'this is'],
   [" arg\n" => 'arg'],
);



for (@tests_shomp){

   printf STDERR "%s\n",'-'x80;
   my($arg,$correct)=@$_;
   my $argcopy =$arg;
   shomp $arg ;
   ok( $arg eq $correct,"shomp()") ;
   
   warn("arg after shomp: '$arg'\nshould be: '$correct'\noriginal arg: '$argcopy'\n\n");
   
}




my $arg = " this/is/apath sortof\n";

ok( shomp $arg );

my $sq = sq($arg);
### $sq
ok( $sq ); 


my $pretty = pretty($arg);
### $pretty
ok $pretty;

ok_part();


my $line = "   # i am a comment\n";
my $line2= "         "; # blank
my $line3 ="not blank or comment # ok.\n";

ok( is_comment($line),'is_comment() 1');
ok( ! is_comment($line3),'is_comment()');
ok( ! is_comment(),'is_comment() with no args');

ok_part();
ok( ! is_blank($line3),'is_blank()');
ok( is_blank($line2),'is_blank() 1' );
ok( is_blank(),'is_blank() with no args' );


ok_part();
ok( is_blank_or_comment($line),'is_blank_or_comment() 1' );
ok( is_blank_or_comment($line2), 'is_blank_or_comment() 2');
ok( ! is_blank_or_comment($line3), 'is_blank_or_comment() 3' );

ok( is_blank_or_comment(),'is_blank_or_comment() 4 ');






exit;






sub ok_part { printf STDERR "\n%s\nPART %s %s\n\n", '='x80, $_part++, "@_"; }

