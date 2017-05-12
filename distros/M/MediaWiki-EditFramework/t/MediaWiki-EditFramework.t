use Test::More;
use Test::MockModule;
use Storable('nstore', 'retrieve');

use constant MODULE => 'MediaWiki::EditFramework';

use_ok(MODULE);
my $api = Test::MockModule->new('MediaWiki::API');
$api->mock( get_page => sub {
	      my $self = shift;
	      my $arg = shift;
	      my $title = $arg->{title};
	      $title =~ s:/:-:g;
	      retrieve("t/data/$title");
	    }
);

ok(my $wiki = 'MediaWiki::EditFramework'->new('en.wikisource.org'));
isa_ok($wiki,'MediaWiki::EditFramework', 'framework is right class');

ok(my $page = $wiki->get_page('Main_Page'), 'got page');
isa_ok($page, 'MediaWiki::EditFramework::Page', 'page is right class');
ok($page->exists, 'page exists');

ok(my $bogus_page = $wiki->get_page('Test/w/index.php'));
ok(not($bogus_page->exists), "page doesn't exist");

# nstore($page->[1], 'good-page.txt');
# nstore($bogus_page->[1], 'bogus-page.txt');

done_testing;
