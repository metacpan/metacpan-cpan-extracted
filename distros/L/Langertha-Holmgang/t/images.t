#!/usr/bin/env perl
# Images on user messages (k27): what the loader checks (inside the suite,
# PNG/JPEG by magic bytes, at most 2 MiB, at most four per message, only on a
# user message), what the case keeps (sha256, size, media type, dimensions),
# the digest (unchanged without images, moved by an image), and that the image
# goes out only in the request -- the transcript and the report keep the
# placeholder { image, sha256, bytes }, never base64. Network-free, invented
# suites only (ADR 0003).
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use Digest::SHA qw( sha256_hex );
use JSON::MaybeXS ();
use MIME::Base64 qw( encode_base64 );
use Path::Tiny qw( path );
use YAML::XS ();

use Holmgang::Images qw( png jpeg image_suite $IMAGE_CASE );
use Holmgang::SuiteDir qw( suite_dir loader $FAN_CASE );
use Langertha::Engine::Virtual;
use Langertha::Holmgang::Error;
use Langertha::Holmgang::Grader;
use Langertha::Holmgang::Lint;
use Langertha::Holmgang::Loader;
use Langertha::Holmgang::Report;
use Langertha::Holmgang::Runner;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Target;
use Langertha::Virtual::Rules qw( answer tool );

my $JSON = JSON::MaybeXS->new( canonical => 1, convert_blessed => 1 );
my $NOTE = png( 8, 6 );

sub load_err {
  my ( $dir ) = @_;
  my $s = eval { loader()->load($dir) };
  return ( $s, Langertha::Holmgang::Error->caught($@) // $@ );
}

sub refused_image {
  my ( $name, $field_re, $why_re, %o ) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ( $s, $r ) = load_err( image_suite(%o) );
  ok( !$s && ref $r && $r->field =~ $field_re && $r->reason =~ $why_re, $name )
    or diag( $s ? 'loaded' : "$r" );
}

subtest 'measuring' => sub {
  is_deeply( [ Langertha::Holmgang::Structure::image_measure( png( 640, 480 ) ) ], [ 'image/png', 640, 480 ], 'PNG: type, width, height' );
  is_deeply( [ Langertha::Holmgang::Structure::image_measure( jpeg( 1024, 768 ) ) ], [ 'image/jpeg', 1024, 768 ], 'JPEG: from the frame header' );
  is_deeply( [ Langertha::Holmgang::Structure::image_measure("GIF89a\x01\0\x01\0") ], [], 'GIF: not an image here' );
  is_deeply( [ Langertha::Holmgang::Structure::image_measure("\xFF\xD8\xFF\xD9") ], ['image/jpeg'], 'JPEG without a frame header: type only' );
};

subtest 'a case with an image loads' => sub {
  my $dir = image_suite();
  my ( $s, $err ) = load_err($dir);
  ok( $s, 'loads (lint and both mock runs included)' ) or return diag "$err";
  my $c = $s->cases->[0];
  ok( $c->has_images, 'has_images' );
  my $info = $c->image_files->{'img/note.png'};
  is_deeply( { %$info, path => undef }, {
    file => 'img/note.png', path => undef, media_type => 'image/png', width => 8, height => 6,
    bytes => length $NOTE, sha256 => sha256_hex($NOTE),
  }, 'image_files: media type, dimensions, size, sha256' );
  is( path( $info->{path} )->realpath, path( $dir, 'img/note.png' )->realpath, '... and the file on disk' );
  is_deeply( $c->prompt_messages, [ { role => 'user', content => [
    { type => 'text', text => 'Set the fan as the note in the picture says.' },
    { image => 'img/note.png', sha256 => sha256_hex($NOTE), bytes => length $NOTE },
  ] } ], 'prompt_messages: text first, then the placeholder' );
  is_deeply( $c->messages->[0]{images}, [ { file => 'img/note.png' } ], 'the case keeps its own values as written' );
  ok( !$c->has_untrusted, 'not untrusted without a mark' );
  my $img = $c->image_content('img/note.png');
  isa_ok( $img, 'Langertha::Content::Image', 'image_content' );
  is( $img->base64, encode_base64( $NOTE, '' ), '... with the bytes of the file' );
  is( $img->media_type, 'image/png', '... and its media type' );

  my ( $s2 ) = load_err( image_suite( case => $IMAGE_CASE =~ s/- file: img\/note.png/- { file: img\/note.png, untrusted: true }/r ) );
  ok( $s2 && $s2->cases->[0]->has_untrusted, 'an image marked untrusted makes the case untrusted' );

  my ( $s3 ) = load_err( image_suite( files => { 'img/note.png' => jpeg( 300, 200 ) } ) );
  ok( $s3, 'a JPEG loads (by its magic bytes, whatever the name says)' );
  is( $s3 && $s3->cases->[0]->image_files->{'img/note.png'}{media_type}, 'image/jpeg', '... as image/jpeg' );

  my $four = $IMAGE_CASE =~ s/(      - file: img\/note.png\n)/$1 x 4/er;
  ok( ( load_err( image_suite( case => $four ) ) )[0], 'four images on one message load (the same file four times)' );
};

subtest 'refusals' => sub {
  refused_image( 'absolute path', qr/messages\[0\]\.images\[0\]\.file/, qr/relative/,
    case => $IMAGE_CASE =~ s/img\/note.png/\/etc\/passwd/r );
  refused_image( '.. out of the suite', qr/images\[0\]\.file/, qr/without \.\./,
    case => $IMAGE_CASE =~ s/img\/note.png/img\/..\/..\/x.png/r );
  refused_image( 'missing file', qr/images\[0\]\.file/, qr/no such file/, files => {} );
  {
    my $outside = Path::Tiny->tempfile( SUFFIX => '.png' );
    $outside->spew_raw($NOTE);
    my $dir = image_suite( files => {} );
    path( $dir, 'img' )->mkpath;
    symlink( "$outside", path( $dir, 'img/note.png' ) ) or plan skip_all => 'no symlinks';
    my ( $s, $r ) = load_err($dir);
    ok( !$s && ref $r && $r->reason =~ /outside the suite/, 'a link out of the suite' ) or diag( $s ? 'loaded' : "$r" );
  }
  refused_image( 'a directory', qr/images\[0\]\.file/, qr/plain file/,
    case => $IMAGE_CASE =~ s/img\/note.png/img/r );
  refused_image( 'GIF', qr/images\[0\]\.file/, qr/not a PNG or JPEG/, files => { 'img/note.png' => "GIF89a".( "\0" x 20 ) } );
  refused_image( 'text named .png', qr/images\[0\]\.file/, qr/not a PNG or JPEG/, files => { 'img/note.png' => "hello\n" } );
  refused_image( 'PNG without a header', qr/images\[0\]\.file/, qr/width and height/,
    files => { 'img/note.png' => "\x89PNG\r\n\x1a\n" } );
  refused_image( 'over 2 MiB', qr/images\[0\]\.file/, qr/larger than 2097152/,
    files => { 'img/note.png' => png( 8, 6 ).( "\0" x ( 2 * 1024 * 1024 ) ) } );
  ok( ( load_err( image_suite( files => { 'img/note.png' => ( $NOTE.( "\0" x ( 2 * 1024 * 1024 - length $NOTE ) ) ) } ) ) )[0],
    'exactly 2 MiB loads' );
  refused_image( 'five images', qr/messages\[0\]\.images$/, qr/at most 4/,
    case => $IMAGE_CASE =~ s/(      - file: img\/note.png\n)/$1 x 5/er );
  refused_image( 'empty list', qr/messages\[0\]\.images$/, qr/empty list/,
    case => $IMAGE_CASE =~ s/    images:\n      - file: img\/note.png\n/    images: []\n/r );
  refused_image( 'unknown key', qr/images\[0\]\.alt$/, qr/unknown key/,
    case => $IMAGE_CASE =~ s/- file: img\/note.png/- { file: img\/note.png, alt: x }/r );
  refused_image( 'untrusted not a flag', qr/images\[0\]\.untrusted$/, qr/true or false/,
    case => $IMAGE_CASE =~ s/- file: img\/note.png/- { file: img\/note.png, untrusted: maybe }/r );
  my $assistant = $IMAGE_CASE =~ s/  - role: user\n/  - role: assistant\n/r;
  $assistant =~ s/(images:\n      - file: img\/note.png\n)/$1  - { role: user, content: "Go." }\n/;
  refused_image( 'on an assistant message', qr/messages\[0\]\.images$/, qr/only on a user message/, case => $assistant );

  my $st = Langertha::Holmgang::Structure->new;
  my $data = YAML::XS::Load($IMAGE_CASE);
  my $r = Langertha::Holmgang::Error->caught( do { eval { $st->case( $data, tools => [ { name => 'fan_set', description => 'x',
    parameters => { type => 'object' }, handlers => [ { output => 'x' } ] } ] ) }; $@ } );
  like( $r && $r->reason, qr/suite directory/, 'Structure->case without dir: an image cannot be read' );
};

subtest 'digest' => sub {
  # without images, the digest is the formula of before (k30): suite.yaml, then each case file
  my ( $dir ) = suite_dir( cases => { 'c1.yaml' => $FAN_CASE } );
  my $sha = Digest::SHA->new(256);
  $sha->add( "suite.yaml\0", path( $dir, 'suite.yaml' )->slurp_raw, "\0" );
  $sha->add( "cases/c1.yaml\0", path( $dir, 'cases/c1.yaml' )->slurp_raw, "\0" );
  is( loader()->load($dir)->digest, $sha->hexdigest, 'a suite without images: the digest as before' );

  my @roots = map { Path::Tiny->tempdir } 1 .. 4;
  my $a = loader()->load( image_suite( id => 'img-a', root => $roots[0] ) );
  my $b = loader()->load( image_suite( id => 'img-a', root => $roots[1], files => { 'img/note.png' => png( 8, 6, 0x10 ) } ) );
  my $c = loader()->load( image_suite( id => 'img-a', root => $roots[2] ) );
  isnt( $a->digest, $b->digest, 'another image under the same name: another digest' );
  is( $a->digest, $c->digest, 'the same image: the same digest' );
  my $idir = image_suite( id => 'img-b', root => $roots[3] );
  my $isha = Digest::SHA->new(256);
  $isha->add( "suite.yaml\0", path( $idir, 'suite.yaml' )->slurp_raw, "\0" );
  $isha->add( "cases/c1.yaml\0", path( $idir, 'cases/c1.yaml' )->slurp_raw, "\0" );
  $isha->add( "cases/c1.yaml: messages[0].images[0]\0", 'img/note.png '.sha256_hex($NOTE).' 8 6', "\0" );
  is( loader()->load($idir)->digest, $isha->hexdigest, 'an image enters the digest as file, sha256, width and height' );
};

subtest 'the image goes out only in the request' => sub {
  my $case = loader()->load( image_suite() )->cases->[0];
  my $engine = Langertha::Holmgang::Runner->mock_engine( $case, 'solution' );
  ok( $engine->does('Langertha::Role::ImageInput'), 'the mock of a case with images claims image_input' );
  my $runner = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $engine ) );
  my $r = $runner->run_case($case);
  is( $r->{status}, 'passed', 'the mock replay passes' );
  my @bodies = map { $_->{body} } @{ $engine->requests };
  my $data_url = 'data:image/png;base64,'.encode_base64( $NOTE, '' );
  for my $i ( 0 .. $#bodies ) {
    is_deeply( $bodies[$i]{messages}[0]{content}, [
      { type => 'text', text => 'Set the fan as the note in the picture says.' },
      { type => 'image_url', image_url => { url => $data_url } },
    ], 'request '.( $i + 1 ).': the image as an OpenAI image_url part with a data URL' );
  }
  my $placeholder = { image => 'img/note.png', sha256 => sha256_hex($NOTE), bytes => length $NOTE };
  is_deeply( $r->{transcript}[0]{content}[1], $placeholder, 'the transcript keeps the placeholder' );
  unlike( $JSON->encode( $r->{transcript} ), qr/base64|data:|iVBOR/, '... and no image content' );

  my $report = Langertha::Holmgang::Report->new( with_transcript => 1 );
  $report->add_run(
    target  => { label => 'mock', engine => 'Virtual', model => undef, url => undef },
    variant => { name => 'default', settings => {} },
    suite   => { id => 's', version => 1, topic => 'demo', digest => 'x' },
    repeat  => 1, status => 'complete', error => undef,
    cases   => [ $case->report_meta ],
    results => [ $r ],
  );
  my $json = $report->to_json;
  unlike( $json, qr/base64|data:image|iVBOR/, 'the report (with transcript) holds no base64 and no data URL' );
  is_deeply( $JSON->decode($json)->{runs}[0]{cases}[0]{repetitions}[0]{transcript}[0]{content}[1], $placeholder,
    '... only the placeholder' );

  # the bytes changed after loading: refused, nothing goes out
  # (a loader without the mock runs: they would read and keep the image at load)
  my $dir = image_suite();
  my $bare = Langertha::Holmgang::Loader->new( lint => Langertha::Holmgang::Lint->new( grader => Langertha::Holmgang::Grader->new ) );
  my $c2  = $bare->load($dir)->cases->[0];
  path( $dir, 'img/note.png' )->spew_raw( png( 8, 6, 0x22 ) );
  my $e2 = Langertha::Engine::Virtual->new( script => [ answer('x') ] );
  ok( !eval { Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e2 ) )->run_case($c2); 1 },
    'an image that changed since loading: the run croaks' );
  like( $@, qr/changed since the suite was loaded/, '... saying so' );
  is( scalar @{ $e2->requests }, 0, '... before any request' );
};

subtest 'no_vision from the pre-check' => sub {
  my $case = loader()->load( image_suite() )->cases->[0];
  my $engine = Langertha::Engine::Virtual->new( script => [ answer('x') ] );
  my $runner = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $engine ) );
  my $r = $runner->run_case( $case, no_vision => 'blind' );
  is( $r->{status}, 'no_vision', 'a case with images: no_vision' );
  is( $r->{error}, 'blind', '... the pre-check\'s reason as its error' );
  is_deeply( $r->{turns}, [], '... no turn' );
  is( scalar @{ $engine->requests }, 0, '... no request' );

  my $plain = loader()->load( suite_dir() )->cases->[0];
  my $e2 = Langertha::Engine::Virtual->new( script => [ tool( fan_set => { level => 'high' } ), answer('ok') ] );
  my $r2 = Langertha::Holmgang::Runner->new( target => Langertha::Holmgang::Target->new( engine => $e2 ) )
    ->run_case( $plain, no_vision => 'blind' );
  is( $r2->{status}, 'passed', 'a case without images ignores it' );
};

done_testing;
