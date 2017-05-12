use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

use_ok('LWP::UserAgent');
$HTTP::Request::Common::DYNAMIC_FILE_UPLOAD = 1;

my $api_key = '8dcf37880da64acfe8e30bb1091376b7';
my $not_so_secret = '2f3695d0562cdac7';

# grab auth token. If none, fail nicely.
my $pw = '******';
open( F, '<', 't/password' ) || (print STDERR "No password file\n" && exit 0);
$pw = <F>;
chomp $pw;
close F;

my $ua = Flickr::Upload->new({'key'=>$api_key, 'secret'=>$not_so_secret});
ok(defined $ua);

my $req = $ua->make_upload_request(
	'description' => "Flickr Upload test for $0",
	'auth_token' => $pw,
	'photo' => 't/testimage.jpg',
	'tags' => "test kernel perl cat dog",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

# all we want to do is replace the default content generator with something
# that will spit out a '.' for each kilobyte and pass the data back.
my $gen = $req->content();
die unless ref($gen) eq "CODE";

$req->content(
	sub {
		my $chunk = &$gen();
		print "." x (length($chunk)/1024) if defined $chunk;
		return $chunk;
	}
);

$ua->agent( "$0/1.0" );

print "# ";
my $photoid = $ua->upload_request( $req );
print "\n";

ok( defined $photoid );

exit 0;
