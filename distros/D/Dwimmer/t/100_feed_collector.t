use strict;
use warnings;

use Test::More;
use Test::Deep;

use Capture::Tiny qw(capture);
use Data::Dumper  qw(Dumper);
use DateTime;
use File::Copy    qw(copy);
use File::Temp    qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1);
my $html_dir1 = "$tempdir/html1";
my $html_dir2 = "$tempdir/html2";
mkdir $html_dir1 or die;
mkdir $html_dir2 or die;
my $site = 'drinks';
my $site2 = 'food';
my @sources = (
	{
		'site_id' => 1,
		'id' => 1,
		'comment' => 'some comment',
		'feed' => "file://$tempdir/atom.xml",
		'status' => 'enabled',
		'title' => 'This is a title',
		'twitter' => 'chirip',
		'url' => 'http://beer.com/',
		'last_fetch_time'    => undef,
		'last_fetch_status'  => undef,
		'last_fetch_error'   => undef,
	},
	{
		'site_id' => 1,
		'id' => 2,
		'comment' => '',
		'feed' => "file://$tempdir/rss.xml",
		'status' => 'enabled',
		'title' => 'My web site',
		'twitter' => 'micro blog',
		'url' => 'http://vodka.com/',
		'last_fetch_time'    => undef,
		'last_fetch_status'  => undef,
		'last_fetch_error'   => undef,
	},
);
my @sources2 = (
	{
		'site_id' => 2,
		'id' => 3,
		'comment' => 'Food store',
		'feed' => "file://$tempdir/burger.xml",
		'status' => 'enabled',
		'title' => 'This is a title of the Brugers',
		'twitter' => 'burger_land',
		'url' => 'http://burger.com/',
		'last_fetch_time'    => undef,
		'last_fetch_status'  => undef,
		'last_fetch_error'   => undef,
	},
);


plan tests => 101;

my $store = "$tempdir/data.db";
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl" };
	like $err, qr{--store storage.db}, 'dwimmer_feed_admin.pl requires the --store option';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store" };
	like $err, qr{does NOT exist}, 'first dwimmer_feed_admin.pl needs to be called with --setup';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}


# adding a site
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --addsite $site" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}

# and checking if it was added
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsite" };
	is $err, '', 'no STDERR for setup';
	my $data = check_dump($out);
	is_deeply $data, [[
		{
			'id' => 1,
			'name' => 'drinks'
		}
	]], 'listing sites';
}


# adding two sources (feeds)
{
	my $infile = save_infile(@{$sources[0]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --site $site --add < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my $data = check_dump($out);

	is_deeply $data, [$sources[0]], 'dumped correctly after adding feed';
	is $err, '', 'no STDERR';
}

{
	my $infile = save_infile(@{$sources[1]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --site $site --add < $infile" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[1]], 'dumped correctly after adding second feed';
	is $err, '', 'no STDERR';
}

# adding a 2nd site
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --addsite $site2" };
	is $err, '', 'no STDERR for setup';
	is $out, '', 'no STDOUT for setup. Really?';
}

{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsite" };
	is $err, '', 'no STDERR for setup';
	my $data = check_dump($out);
	is_deeply $data, [[
		{
			'id' => 1,
			'name' => 'drinks'
		},
		{
			'id' => 2,
			'name' => 'food'
		}
	]], 'listing sites';
}

# add feed
{
	my $infile = save_infile(@{$sources2[0]}{qw(url feed title twitter comment)});
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --add --site $site2 < $infile" };

	like $out, qr{URL.*Feed.*Title.*Twitter.*Comment}s, 'prompts';
	my $data = check_dump($out);

	is_deeply $data, [$sources2[0]], 'dumped correctly after adding feed';
	is $err, '', 'no STDERR';
}


# make sure we cannot reset the database by mistake
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --setup" };
	like $err, qr{Database .+ already exists}, 'cannot destroy database';
	is $out, '', 'no STDOUT for setup. Really?';
}


# list sources filtered to 'beer'
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource beer" };
	my $data = check_dump($out);
	is_deeply $data, [$sources[0]], 'listed correctly' or diag $out;
	is $err, '', 'no STDERR';
}

# list sources, unfiltered
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0,1], $sources2[0] ], 'listed correctly';
	is $err, '', 'no STDERR';
}

# list sources of a specific site based on name or id
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0,1]], 'listed correctly';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 1" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0,1]], 'listed correctly';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site $site2" };
	my $data = check_dump($out);
	is_deeply $data, [ $sources2[0] ], 'listed correctly';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 2" };
	my $data = check_dump($out);
	is_deeply $data, [ $sources2[0] ], 'listed correctly';
	is $err, '', 'no STDERR';
}

# list sources of invalid name
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site Other" };
	is $out, '', 'no STDOUT';
	like $err, qr{Could not find site 'Other'}, 'exception when invalid site name given';
}
# list source of invalid id
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 3" };
	is $out, '', 'no STDOUT';
	like $err, qr{Invalid site id '3'}, 'exception when invalid site id given';
}



# disable source based on id
my $disabled = clone($sources[0]);
$disabled->{status} = 'disabled';
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --disable 1" };
	my $data = check_dump($out);
	is_deeply $data, [ $sources[0], $disabled ], '--disable';
	is $err, '', 'no STDERR';
}

# check list of sources after disable
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ $disabled, $sources[1], $sources2[0] ], 'listed correctly after disable';
	is $err, '', 'no STDERR';
}

# enable source
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --enable 1" };
	my $data = check_dump($out);
	is_deeply $data, [ $disabled, $sources[0] ], '--enable';
	is $err, '', 'no STDERR';
}
# check list of sources after enable
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource" };
	my $data = check_dump($out);
	is_deeply $data, [ @sources[0, 1], $sources2[0] ], 'listed correctly after enable';
	is $err, '', 'no STDERR';
}

# list configuration options
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [[]], 'no config';
	is $err, '', 'no STDERR';
}

# set configuration option without --site fails
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config name Foo" };
	is $out, '', 'no STDOUT Hmm, not good';
	like $err, qr{--site SITE  required for this operation}, ' --site required for --config';
}
# set configuration with --site works
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config from foo\@bar.com --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --config another option --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}
# listing config of a site
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [[
		{
			key => 'from',
			value => 'foo@bar.com',
			site_id => 1,
		},
		{
			key => 'another',
			value => 'option',
			site_id => 1,
		},
		]], 'config' or diag $out;
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site2" };
	my $data = check_dump($out);
	is_deeply $data, [[
		]], 'config' or diag $out;
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --unconfig another --site $site" };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listconfig --site $site" };
	my $data = check_dump($out);
	is_deeply $data, [[{
		key => 'from',
		value => 'foo@bar.com',
		site_id => 1,
		},
		]], 'config';
	is $err, '', 'no STDERR';
}
{
	my ($out, $err) = capture { system qq{$^X script/dwimmer_feed_admin.pl --store $store --config html_dir "$html_dir1" --site $site} };
	is $out, '', 'no STDOUT Hmm, not good';
	is $err, '', 'no STDERR';
}


# disable feeds for now so we only test the rss
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --disable 1" };
	copy 't/files/rss.xml', "$tempdir/rss.xml";
	copy 't/files/burger.xml', "$tempdir/burger.xml";
}

# running the collector, I think it should give some kind of an error message if it cannot find feed
{
	my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store" };
	is $out, '', 'no STDOUT';
	like $err, qr{Usage: }, 'Usage on STDERR';
	#diag $err;
}
{
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect --verbose" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listqueue mail" };
		is $err, '';
		my $data = check_dump($out);
		is_deeply $data, [[]];
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listentries" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
			{
				'id' => 2,
				'source_id' => 3,
				'site_id' => 2,
				'author' => 'szabgab',
				'link' => 'http://perl6maven.com/parsing-command-line-arguments-perl6',
				'remote_id' => undef,
				'content' => '',
				'tags' => '',
				'summary' => re('Perl 6 application'),
				'issued' => '2012-09-14 10:52:03',
				'title' => 'Parsing command line arguments in Perl 6'
			},
			{
				'id' => 1,
				'source_id' => 2,
				'site_id' => 1,
				'author' => 'Gabor Szabo',
				'content' => re('^\s*Description\s*$'),
				'issued' => '2012-03-28 10:57:35',
				'link' => 'http://szabgab.com/first.html',
				'remote_id' => undef,
				'summary' => '',
				'tags' => '',
				'title' => 'First title'
			},
		]];
	}
	my $disabled = clone($sources[0]);
	$disabled->{status} = 'disabled';
	$sources[1]{last_fetch_error}  = '';
	$sources[1]{last_fetch_status} = 'success';
	$sources[1]{last_fetch_time}   = re('\d{10}');
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 1" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $disabled, $sources[1] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}
	$sources2[0]{last_fetch_error}  = '';
	$sources2[0]{last_fetch_status} = 'success';
	$sources2[0]{last_fetch_time}   = re('\d{10}');
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 2" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $sources2[0] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --html" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		is $out, '', 'STDOUT is empty';
		like $err, qr{Missing directory name at}, 'html directory is not defined for one of the sites';
	}

	{
		my ($out, $err) = capture { system qq{$^X script/dwimmer_feed_admin.pl --store $store --config html_dir "$html_dir2" --site $site2} };
		is $out, '', 'no STDOUT Hmm, not good';
		is $err, '', 'no STDERR';
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --html --verbose" };
		#like $out, qr{^sources loaded: \d \s* Processing feed $sources[0]{feed} .* Elapsed time: [01]\s*$}x, 'STDOUT is only elapsed time';
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}
}


{
	open my $fh, '<', 't/files/rss2.xml' or die;
	my $content = do { local $/ = undef; <$fh> };
	my $dt = DateTime->now;;
	$content =~ s/DATE/$dt/;
	open my $out, '>', "$tempdir/rss.xml" or die;
	print $out $content;
	close $fh;
	close $out;

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect --verbose" };
		like $out, qr{Elapsed time: \d+}, 'STDOUT has elapsed time';
		unlike $out, qr{ERROR|EXCEPTION}, 'STDOUT no ERROR or EXCEPTION';
		is $err, '', 'no STDERR';
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listqueue mail" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
			{
				'remote_id' => undef,
				'link' => 'http://szabgab.com/second.html',
				'entry' => 3,
				'source_id' => 2,
				'site_id' => 1,
				'content' => re('^\s*Placeholder for some texts\s*'),
				'channel' => 'mail',
				'author' => 'Foo',
				'tags' => '',
				'summary' => '',
				'issued' => re('^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$'),
				'id' => 3,
				'title' => 'Second title'
			}
		]];
	}

	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listentries" };
		is $err, '';
		my $data = check_dump($out);
		cmp_deeply $data, [[
			{
				'id' => 3,
				'source_id' => 2,
				'site_id' => 1,
				'author' => 'Foo',
				'content' => re('^\s*Placeholder for some texts\s*$'),
				'issued' => re('^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d$'),
				'link' => 'http://szabgab.com/second.html',
				'remote_id' => undef,
				'summary' => '',
				'tags' => '',
				'title' => 'Second title'
			},
			{
				'id' => 2,
				'source_id' => 3,
				'site_id' => 2,
				'author' => 'szabgab',
				'link' => 'http://perl6maven.com/parsing-command-line-arguments-perl6',
				'remote_id' => undef,
				'content' => '',
				'tags' => '',
				'summary' => re('Perl 6 application'),
				'issued' => '2012-09-14 10:52:03',
				'title' => 'Parsing command line arguments in Perl 6'
			},
			{
				'id' => 1,
				'source_id' => 2,
				'site_id' => 1,
				'author' => 'Gabor Szabo',
				'content' => re('^\s*Description\s*$'),
				'issued' => '2012-03-28 10:57:35',
				'link' => 'http://szabgab.com/first.html',
				'remote_id' => undef,
				'summary' => '',
				'tags' => '',
				'title' => 'First title'
			}
	]];
	}

	# list sources mostly to check the last_fetch fields
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 1" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $disabled, $sources[1] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 2" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $sources2[0] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}


}

{
	# creat an invalid feed to see how we handle errors
	{
		#open my $atom, '>', "$tempdir/atom.xml" or die;
		#print $atom '<Garbage>in file';
		#close $atom;
		open my $rss, '>', "$tempdir/rss.xml" or die;
		print $rss '<rss> Garbage';
		close $rss;
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_collector.pl --store $store --collect --verbose" };
		like $out, qr{Elapsed time: [01]\s*$}, 'STDOUT is only elapsed time';
		is $err, '', 'no STDERR';
	}
	# list sources mostly to check the last_fetch fields

	$sources[1]{last_fetch_error}  = re('Malformed RSS');
	$sources[1]{last_fetch_status} = 'fail_fetch';
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 1" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $disabled, $sources[1] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}
	{
		my ($out, $err) = capture { system "$^X script/dwimmer_feed_admin.pl --store $store --listsource --site 2" };
		my $data = check_dump($out);
		cmp_deeply $data, [ $sources2[0] ], 'listed correctly' or diag $out;
		is $err, '', 'no STDERR';
	}

}


exit;
############################################################################

sub clone {
	my $old = shift;
	my $dump = Dumper $old;
	$dump =~ s/\$VAR1\s+=//;
	my $var = eval $dump;
	die $@ if $@;
	return $var;
}


sub check_dump {
	my ($out) = @_;

	my @parts = split /\$VAR1\s+=\s*/, $out;
	shift @parts;

	my @data;
	foreach my $p (@parts) {
		my $v = eval $p;
		die $@ if $@;
		push @data, $v;
	}
	return \@data;
}

sub save_infile {
	my @in = @_;

	my $infile = "$tempdir/in";
	open my $tmp, '>', $infile or die;
	print $tmp join '', map {"$_\n"} @in;
	close $tmp;
	return $infile;
}


