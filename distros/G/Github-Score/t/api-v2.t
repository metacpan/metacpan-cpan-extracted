use Test::More tests => 21;
use Data::Dumper;
 
BEGIN { use_ok 'Github::Score'; }

{
     isa_ok( my $gs = Github::Score->new( { user => 'stevan', repo => 'ox' } ), 'Github::Score' );
     my $scores = $gs->scores;
     cmp_ok ((my $count = grep { /(stevan|doy|arcanez|jasonmay)/} keys %$scores),
     	'>',0, "Found at least one of stevan|doy|arcanez|jasonmay");
}



 
{
my $gs1 = Github::Score->new(); ##Bare constructor. Not much use without:
$gs1->user('Getty'); ## Still need a:
cmp_ok $gs1->user(), 'eq', 'Getty', 'User (Getty) explicitly set';
$gs1->repo('p5-www-duckduckgo');
cmp_ok $gs1->repo(), 'eq', 'p5-www-duckduckgo', 'Repo (p5-www-duckduckgo) explicitly set';

my $gs2 = Github::Score->new(user=>'Getty', repo=>'p5-www-duckduckgo'); 
cmp_ok $gs2->user(), 'eq', 'Getty', 'User (Getty) set by named constructor arg';
cmp_ok $gs1->repo(), 'eq', 'p5-www-duckduckgo', 'Repo (p5-www-duckduckgo) set by named constructor arg';

my $gs3 = Github::Score->new('Getty/p5-www-duckduckgo'); 
cmp_ok $gs2->user(), 'eq', 'Getty', 'User (Getty) set with url-style constructor arg';
cmp_ok $gs1->repo(), 'eq', 'p5-www-duckduckgo', 'Repo (p5-www-duckduckgo) set with url-style constructor arg';

cmp_ok $gs3->timeout(), '==', 10, 'Default timer is 10';
cmp_ok $gs3->timeout(5), '==', 5, 'Timer reset to 5';
my $author_contrib_map = $gs1->scores();
cmp_ok my $count = keys %$author_contrib_map, '>', 0, 'Found scores';
cmp_ok ( $_->scores, '~~' , $author_contrib_map, "Different constructor, same scores"  ) for ($gs2, $gs3) ;
}
 

{
	my $gs = Github::Score->new('stevan/ox', timeout => 0.0001);
	is($gs->timeout(), 0.0001,'Silly low non-zero timeout value');
	cmp_ok my $count = keys %{$gs->scores}, '==',0,'No scores in silly timeout case';
}

{
	my $gs = Github::Score->new('canardee-io/tunna');
	cmp_ok my $count = keys %{$gs->scores}, '==',0,'No scores in non-existent repo case';
}

{
	my $gs = Github::Score->new('Fishbones/p5-www-duckduckgo');
	cmp_ok my $count = keys %{$gs->scores}, '==',0,'No scores in non-existent user case';
}

{
	my $gs = Github::Score->new('Fishbones/tunna');
	cmp_ok my $count = keys %{$gs->scores}, '==',0,'No scores in non-existent user + case';
}

SKIP:{
     skip "Version 3 api not supported yet", 2 unless $GITHUB_API_V3;
     isa_ok( my $gs = Github::Score->new( { user => 'stevan', repo => 'ox', api_version => 'v3' } ), 'Github::Score' );
     my $scores = $gs->scores;
     cmp_ok ((my $count = grep { /(stevan|doy|arcanez|jasonmay)/} keys %$scores),
     	'>',0, "Found at least one of stevan|doy|arcanez|jasonmay");
};
