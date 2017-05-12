use strict;
use Test::More;
use List::Util qw(shuffle);
use Flickr::Upload;

# The $HTTP::Request::Common::DYNAMIC_FILE_UPLOAD facility allows us
# to supply a callback that'll get the contents of each chunk in the
# multipart POST request to flickr. By inspecting the whole multipart
# request we can determine how far along the upload is and display an
# accurate progres meter via Term::ProgressBar.

# Ideally there would be a callaback that would be called with the
# contents of each logical form field in the multipart chunk, since
# that isn't the case we'll have to build an ad-hoc parser that gets
# called with each chunk in the multipart request and returns the
# number of bytes of the file that has been uploaded.

my $NUM_TESTS = 9001;
my @IMAGE_SIZE_RANGE = ( 500, 1000 );

plan tests => $NUM_TESTS;

my @PARTS = (
q[--%ID%
Content-Disposition: form-data; name="photo"; filename="%IMAGE_NAME%"
Content-Type: %IMAGE_TYPE%

%IMAGE_DATA%],
q[--%ID%
Content-Disposition: form-data; name="async"

1],
q[--%ID%
Content-Disposition: form-data; name="api_sig"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="auth_token"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="title"

Test],
q[--%ID%
Content-Disposition: form-data; name="api_key"

XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX],
q[--%ID%
Content-Disposition: form-data; name="description"

Test picture],
);

for my $num_test (1 .. $NUM_TESTS) {
	my $image_name = "Testimage.png";
	my $image_type = "image/png";
	my $image_size = 512 + int rand 1024;
	my $image_data = ('x' x $image_size);
	my $chunk_size = 128 + int rand 256;
	my $id = 'qBXwGcnVvxg14vk2iUnT8v2YB3FilB3b3rmAmVeq';
	my @parts = shuffle @PARTS;
	my @mod_parts = map {
		s/\n/\r\n/g;
		s/%ID%/$id/g;
		s/%IMAGE_NAME%/$image_name/g;
		s/%IMAGE_TYPE%/$image_type/g;
		s/%IMAGE_DATA%/$image_data/g;
		$_;
	} @parts;
	my $whole_message = join("\r\n", @mod_parts) . "\r\n" . "--$id\r\n";
	my @split_message = unpack "(Z$chunk_size)*", $whole_message;

	my ($state, $size);

	for my $part (@split_message) {
		$size += Flickr::Upload::file_length_in_encoded_chunk(\$part, \$state, $image_size);
	}

	cmp_ok $size, '==', $image_size, "Correct size (img_size: $image_size) (chunk_size: $chunk_size)";
}
