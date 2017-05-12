use Test::More qw(no_plan);
BEGIN { use_ok('Flickr::Upload') };

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

# slurp in the photo
my $photo = 't/testimage.jpg';
my $photobuf = '';
open( F, '<', $photo ) or die $!;
while(<F>) { $photobuf .= $_; }
close F;

ok( $photobuf ne '' );

my $req = $ua->make_upload_request(
	'description' => "Flickr Upload test for $0",
	'auth_token' => $pw,
	'tags' => "test kernel perl cat dog",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

# HACK: this will be recalculated when the content is regenerated, but
# if we leave it as it is we get a nasty warning because the added part
# will invalidate the existing value.
$req->remove_header( 'Content-Length' );

# we didn't provide a photo when we made the message because we're
# trying to generate the message from a data buffer, not a file.
# Now that we have a request, add in the actual image.
my $p = new HTTP::Message(
	[
		'Content-Disposition'
			=> qq(form-data; name="photo"; filename="$photo"),
		'Content-Type' => 'image/jpeg',
	],
	$photobuf,
);
$req->add_part( $p );

my $photoid = $ua->upload_request( $req );
ok( defined $photoid );

exit 0;
