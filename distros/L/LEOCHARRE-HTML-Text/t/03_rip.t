use Test::Simple 'no_plan';
use lib './lib';
use LEOCHARRE::HTML::Rip ':all';
use Smart::Comments '###';

my $html = `cat ./t/bbc.html`;
ok $html;

for my $tag ( qw(title script meta link style) ){ 
   printf STDERR "\n======================================\n%s====================\n\n",uc($tag);
   my @got = find_tag($html,$tag);
   ok @got, "got $tag";
   ### @got
}





for my $tag ( qw(title script meta link style) ){ 
   $html = rip_tag( $html, $tag );
}

## $html;

