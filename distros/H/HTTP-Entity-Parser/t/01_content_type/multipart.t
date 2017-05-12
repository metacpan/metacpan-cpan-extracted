use strict;
use warnings;
use Test::More;
use HTTP::Entity::Parser::MultiPart;
use Hash::MultiValue;
use HTTP::Headers;
require "./t/Util.pm";
t::Util->import();
use File::Basename;

my $content = qq{------BOUNDARY
Content-Disposition: form-data; name="hoge"
Content-Type: text/plain

fuga
------BOUNDARY
Content-Disposition: form-data; name="hoge"
Content-Type: text/plain

hige
------BOUNDARY
Content-Disposition: form-data; name="nobuko"
Content-Type: text/plain

iwaki
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo.txt"
Content-Type: text/plain

SHOGUN
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file"; filename="yappo2.txt"
Content-Type: text/plain

SHOGUN2
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file3"; filename="yappo3.txt"
Content-Type: text/plain

SHOGUN3
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo4.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file4"; filename="yappo5.txt"
Content-Type: text/plain

SHOGUN4
------BOUNDARY
Content-Disposition: form-data; name="test_upload_file6"; filename="yappo6.txt"
Foo: bar
  baz
X: Y:Z
Content-Type: text/plain

SHOGUN6
------BOUNDARY--
};
$content =~ s/\r\n/\n/g;
$content =~ s/\n/\r\n/g;

my $tmpdir;

{
    my $env = {
        CONTENT_LENGTH => length($content),
        CONTENT_TYPE   => 'multipart/form-data; boundary=----BOUNDARY',
    };

    # read from file.
    my $parser = HTTP::Entity::Parser::MultiPart->new($env);
    $parser->add($_) for split //, $content;
    my ($params, $uploads) = $parser->finalize();

    is_deeply( Hash::MultiValue->new(@$params)->as_hashref_multi, {   
        hoge => ['fuga', 'hige'],
        nobuko => ['iwaki'],
    });

    $uploads = Hash::MultiValue->new(@$uploads);

    my @test_upload_file = $uploads->get_all('test_upload_file');
    is 0+@test_upload_file, 2;
    is slurp($test_upload_file[0]->{tempname}), 'SHOGUN';
    is slurp($test_upload_file[1]->{tempname}), 'SHOGUN2';

    {
        my $test_upload_file3 = $uploads->{'test_upload_file3'};
        is slurp($test_upload_file3->{tempname}), 'SHOGUN3';

        my @test_upload_file6 = $uploads->{'test_upload_file6'};
        is slurp($test_upload_file6[0]->{tempname}), 'SHOGUN6';
        my $header = HTTP::Headers->new(@{$test_upload_file6[0]->{headers}});
        is $header->header('Content-Type'), 'text/plain';
        is $header->content_type, 'text/plain';
        is $header->header('X'), 'Y:Z';
        is $header->header('Foo'), 'bar baz';
    }

    $tmpdir = dirname($test_upload_file[0]->{tempname});
}

ok(! -d $tmpdir);

done_testing();




