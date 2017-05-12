use I22r::Translate::Filter::Literal;
use I22r::Translate::Request;
use Test::More;
use strict;
use warnings;

my $input1 = "this is {{literal}} text";
my $input2 = "no literal text";
my $input3 = "more [lit]literal[/lit] text";
my $input4 = "even more [literal]protected[/literal] text";
my $input5 = "Some <span lang=\"en\">English</span> text";

my $req = I22r::Translate::Request->new(
    src => 'ab', dest => 'cd', 
    text => { 1 => $input1, 2 => $input2, 3 => $input3,
	      4 => $input4, 5 => $input5 } );

my $f = I22r::Translate::Filter::Literal->new;
ok($f, 'filter created');

$f->apply($req, 1);
$f->apply($req, 2);
$f->apply($req, 3);
$f->apply($req, 4);
$f->apply($req, 5);

my %input = %{ $req->text };

ok($input{1} =~ /this is.*text/, 'unprotected text not preserved');
ok($input{1} !~ /literal/, 'literal text protected');
ok($input{2} eq $input2, 'unprotected text 2 not preserved');
ok($input{3} =~ /more.*text/ && $input{3} !~ /lit/, 
   '[lit][/lit] provides protection') or diag $input{3};
ok($input{4} =~ /even.*text/ && $input{4} !~ /protected/,
   '[literal][/literal] provides protection');
ok($input{5} =~ /Some.*text/ && $input{5} !~ /English/ && $input{5}!~/span/,
   '<span lang="..."></span> provides protection');

$f->unapply($req, $_) for 1..5;

my %output = %{ $req->text };

ok( $output{1} eq $input1, '1 restored after postprocess' )
    or diag $output{1},$input1;
ok( $output{2} eq $input2, '2 restored after postprocess' );
ok( $output{3} eq $input3, '3 restored after postprocess' );
ok( $output{4} eq $input4, '4 restored after postprocess' );
ok( $output{5} eq $input5, '5 restored after postprocess' );

done_testing();
1;
