#! perl

use strict;
use warnings;
use HTML::Summary;
use HTML::TreeBuilder;
use Test::More 0.88 tests => 2;

my $meta_abstract = "This is the abstract for the page. It is more than 20 characters.";
my $heading       = "This is the heading!";
my $para1         = "This is the first paragraph.";

my $page1 = <<"END_PAGE";
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name=description content="$meta_abstract">
</head>
<body>
<h1>$heading</h1>
<p>$para1</p>
</body>
</html>
END_PAGE

my $tree = HTML::TreeBuilder->new;

$tree->parse( $page1 );

my $summariser = HTML::Summary->new(
                     LENGTH => 20,
                     USE_META => 1,
                 );

my $summary =  $summariser->generate($tree);
is($summary,$meta_abstract,"We should get the content of the meta abstract");

my $page2 = <<"END_PAGE";
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
</head>
<body>
<h1>$heading</h1>
<p>$para1</p>
</body>
</html>
END_PAGE

$tree = HTML::TreeBuilder->new;
$tree->parse( $page2 );
$summary = $summariser->generate($tree);
is($summary,substr($para1,0,20),
   "without meta description we should get body text");
