use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

my $api_key = '8dcf37880da64acfe8e30bb1091376b7';
my $not_so_secret = '2f3695d0562cdac7';

my $ua = Flickr::Upload->new({'key'=>$api_key, 'secret'=>$not_so_secret});
ok(defined $ua);

$ua->agent( "$0/1.0" );

my $rc = $ua->upload(
	'photo' => 't/testimage.jpg',
	'auth_token' => 'bad_pass',	# we're supposed to fail gracefully
	'tags' => "test kernel perl cat dog",
	'description' => "Flickr::Upload test for $0",
	'is_public' => 1,
	'is_friend' => 1,
	'is_family' => 1
);

ok( not defined $rc );

exit 0;
