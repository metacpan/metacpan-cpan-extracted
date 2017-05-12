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

$ua->agent( "$0/1.0" );

my $rc = $ua->upload(
	'async' => 1,
	'photo' => 't/testimage.jpg',
	'auth_token' => $pw,
	'tags' => "test kernel perl cat dog",
	'description' => "Flickr Upload test for $0",
	'is_public' => 0,
	'is_friend' => 0,
	'is_family' => 0,
);

ok( defined $rc );

print STDERR "Got ticket id '$rc'\n";

do {
	sleep 1;
	my @checked = $ua->check_upload( $rc );

	for( @checked ) {
		if( $_->{id} eq $rc and $_->{complete} ) {
			ok( $_->{complete} == 1 );	# completed
			ok( defined $_->{photoid} and $_->{photoid} );
			print STDERR "Got photoid '$_->{photoid}'\n";
			$rc = undef;
		}
	}
} while( defined $rc );

exit 0;
