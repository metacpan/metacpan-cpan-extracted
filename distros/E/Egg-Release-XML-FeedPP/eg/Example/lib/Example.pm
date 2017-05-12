package Example;
use strict;
use warnings;
use Egg qw/ -Debug
  Dispatch::Fast
  Debugging
  /;

our $VERSION= '0.01';

__PACKAGE__->egg_startup(

  title      => 'Example',
  root       => '/path/to/Example',
  static_uri => '/',
  dir => {
    lib      => '< $e.root >/lib',
    static   => '< $e.root >/htdocs',
    etc      => '< $e.root >/etc',
    cache    => '< $e.root >/cache',
    tmp      => '< $e.root >/tmp',
    template => '< $e.root >/root',
    comp     => '< $e.root >/comp',
    },
  template_path=> ['< $e.dir.template >', '< $e.dir.comp >'],

  VIEW=> [

    [ Template=> {
      .....
      ...
      } ],

    [ FeedPP => {
      content_type=> 'application/rss+xml',
      charset     => 'UTF-8',
      } ],

    ],

  MODEL=> [ [ FeedPP => {} ] ],

  );

# Dispatch. ------------------------------------------------
__PACKAGE__->run_modes(
  xml  => \&send_feed,
  read => \&read_feed,
  );
# ----------------------------------------------------------

sub send_feed {
	my($e)= @_;
	my $view= $e->default_view('FeedPP');
	my $type= $view->feed_type($e->snip->[2]);
	$view->cache('FileCache', "send_feed_${type}") || do {
		my $feed= $view->feed($type);
		$feed->title('MY BLOG');
		$feed->description('Example blog feed.');
		$e->db->table_name->arrayref(
		  [qw/add_date title url description/],
		  q{ active = 1 ORDER BY add_date OFFSET 0 LIMIT 30 }, [], sub {
			my($array, %hash)= @_;
			$feed->add_item( $hash{url},
			  title       => $hash{title},
			  description => $hash{description},
			  );
			$feed->pubDate($e->timelocal($hash{add_date}));
		  });
	  };
}
sub read_feed {
	my($e)= @_;
	my $param= $e->view->params;
	my $model= $e->model('FeedPP');
	my $feed = $model->feed('http://mydomain/blog/index.rdf');
	$param->{rss_title}= $feed->title;
	$param->{rss_link} = $feed->link;
	my @items;
	for $item ($feed->get_item) {
		push @items, {
		  title=> $item->title,
		  link => $item->link,
		  date => $item->pubDate,
		  };
	}
	$param->{rss_items}= \@items;
	$e->template('/rss_read.tt');
}

1;
