use Goo::BackLinkFinder;

my @backlinks = Goo::BackLinkFinder::get_back_links("Object.pm");

print join("\n", @backlinks);
