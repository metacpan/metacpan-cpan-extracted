#!/usr/bin/env perl
# The vision pre-check of a target (k27): the wire (Langertha::Role::ImageInput),
# the server's model metadata (probe_model_capabilities_f), and the sight test
# -- a request without and with an image, where a template that drops the image
# leaves the input tokens where they were. A pre-check, never a graded case
# (ADR 0006). Langertha::Engine::Virtual only, no network.
use strict;
use warnings;
use Test::More;
use Future;
use Moose::Util ();

use Langertha::Engine::Virtual;
use Langertha::Holmgang::Structure;
use Langertha::Holmgang::Target;
use Langertha::Virtual::Rules qw( answer error );

{
  # a Virtual whose server metadata says the model takes no image
  package T::BlindByMetadata;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  with 'Langertha::Role::ImageInput';
  sub probe_model_capabilities_f { Future->done( { $_[0]->chat_model => { image_input => 0 } } ) }
  package T::SeeingByMetadata;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  with 'Langertha::Role::ImageInput';
  sub probe_model_capabilities_f { Future->done( { $_[0]->chat_model => { image_input => 1 }, other => { image_input => 0 } } ) }
  package T::ProbeFails;
  use Moose;
  extends 'Langertha::Engine::Virtual';
  with 'Langertha::Role::ImageInput';
  sub probe_model_capabilities_f { Future->fail('connection refused') }
}

# input tokens of a request: 10 per message, plus $per_image per image part
sub counting {
  my ( $per_image ) = @_;
  return sub {
    my ( $view ) = @_;
    my $n = 0;
    for my $m ( @{ $view->{messages} } ) {
      $n += 10;
      next unless ref $m->{content} eq 'ARRAY';
      $n += $per_image * grep { ref $_ eq 'HASH' && ( $_->{type} // '' ) eq 'image_url' } @{ $m->{content} };
    }
    return { prompt_tokens => $n, completion_tokens => 1 };
  };
}

sub seeing {
  my ( %o ) = @_;
  my $class = delete $o{class};
  my $e = ( $class // 'Langertha::Engine::Virtual' )->new( rules => [ qr/./ => answer('OK') ], %o );
  Moose::Util::apply_all_roles( $e, 'Langertha::Role::ImageInput' ) unless $class;
  return $e;
}

sub check { Langertha::Holmgang::Target->new( engine => $_[0], variant => $_[1] // {} )->vision_check_f->get }

subtest 'the sight test image' => sub {
  my $png = Langertha::Holmgang::Target->sight_test_image;
  is_deeply( [ Langertha::Holmgang::Structure::image_measure($png) ], [ 'image/png', 512, 512 ], 'a 512 x 512 PNG' );
  is( Langertha::Holmgang::Target->sight_test_image, $png, 'the same bytes every time' );
  is( Langertha::Holmgang::Target->sight_test_min_tokens, 200, 'at least 200 input tokens for the image' );
};

subtest 'the wire' => sub {
  my $e = Langertha::Engine::Virtual->new( rules => [ qr/./ => answer('OK') ] );
  my $c = check($e);
  is( $c->{check}, 'wire', 'a mock engine without vision: decided at the wire' );
  like( $c->{no_vision}, qr/takes no image.*ImageInput/, '... no_vision, saying why' );
  is( scalar @{ $e->requests }, 0, '... without a request' );
};

subtest 'the server\'s model metadata' => sub {
  my $e = seeing( class => 'T::BlindByMetadata', default_usage => counting(300) );
  my $c = check($e);
  is( $c->{check}, 'probe', 'metadata says no image: decided by the probe' );
  like( $c->{no_vision}, qr/model metadata says the model virtual takes no image/, '... no_vision' );
  is( scalar @{ $e->requests }, 0, '... without a request' );

  $c = check( seeing( class => 'T::SeeingByMetadata', default_usage => counting(300) ) );
  ok( !defined $c->{no_vision}, 'metadata says it sees (another model does not): on to the sight test, seen' );
  is( $c->{check}, 'sight_test', '... decided there' );

  $c = check( seeing( class => 'T::ProbeFails', default_usage => counting(300) ) );
  ok( !defined $c->{no_vision}, 'a failing probe decides nothing' );
  is( $c->{check}, 'sight_test', '... the sight test does' );
};

subtest 'the sight test' => sub {
  my $e = seeing( default_usage => counting(256) );
  my $c = check($e);
  is_deeply( $c, { no_vision => undef, check => 'sight_test', added_tokens => 256 }, 'a mock that sees: seen, 256 tokens added' );
  is( scalar @{ $e->requests }, 2, '... two requests' );
  my ( $plain, $img ) = map { $_->{body}{messages}[0]{content} } @{ $e->requests };
  ok( !ref $plain, '... the first without an image' );
  is( $img->[1]{type}, 'image_url', '... the second with the image as a content part' );
  like( $img->[1]{image_url}{url}, qr{\Adata:image/png;base64,iVBOR}, '... inline, as a data URL' );
  is_deeply( [ map { $_->{body}{max_tokens} } @{ $e->requests } ], [ 16, 16 ], '... short answers' );

  $e = seeing( default_usage => counting(0) );
  $c = check($e);
  is( $c->{check}, 'sight_test', 'a mock that drops the image: caught by the sight test' );
  like( $c->{no_vision}, qr/the image added 0 input tokens, at least 200 expected -- the target drops the image/, '... no_vision' );
  is( $c->{added_tokens}, 0, '... nothing added' );

  $c = check( seeing( default_usage => counting(199) ) );
  ok( defined $c->{no_vision}, '199 tokens: below the minimum, no_vision' );
  $c = check( seeing( default_usage => counting(200) ) );
  ok( !defined $c->{no_vision}, '200 tokens: seen' );

  $c = check( seeing() );
  ok( !defined $c->{no_vision}, 'a mock without token usage: not no_vision' );
  like( $c->{note}, qr/unmeasured/, '... noted as unmeasured' );

  $e = seeing( rules => [
    sub { ref $_[0]{messages}[0]{content} } => error( 400, 'image input is not supported - hint: if this is unexpected, you may need to provide the mmproj' ),
    qr/./ => answer('OK'),
  ], default_usage => counting(300) );
  $c = check($e);
  like( $c->{no_vision}, qr/the target refused the image: .*image input is not supported/, 'the image refused with a vision signature: no_vision' );

  $e = seeing( rules => [ qr/./ => error( 500, 'boom' ) ] );
  $c = check($e);
  ok( !defined $c->{no_vision}, 'a target that fails otherwise: not no_vision' );
  like( $c->{note}, qr/sight test failed: .*500/, '... noted' );

  $e = seeing( default_usage => counting(300) );
  check( $e, { max_tokens => 7, reasoning_effort => 'low' } );
  is_deeply( [ map { $_->{body}{max_tokens} } @{ $e->requests } ], [ 7, 7 ], 'the variant applies to the sight test' );
};

done_testing;
