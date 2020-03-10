#!/usr/bin/env perl
use strict;
use warnings;
use Test::Spec;
use Test::Spec::Mocks;
use JSON::MaybeXS 'encode_json';

use Docker::Registry::V2;
use Docker::Registry::Request;
use Docker::Registry::Response;


describe 'Pagination' => sub {
  my $d = Docker::Registry::V2->new(
      url => 'https://my.awesome.registry',
  );
  my $repository = 'my-repository';
  my ($expected_request, $stubbed_response);

  describe "'n' parameter" => sub {
    describe "When it is not passed" => sub {
      before all => sub {
        $expected_request = _request({ repository => $repository });
        $stubbed_response = _response();
        $d->caller
          ->expects('send_request')
          ->with_deep($expected_request)
          ->returns($stubbed_response);
      };

      it 'is not added to the request & the result is correctly parsed' => sub {
        my $result = $d->repository_tags(repository => $repository);
        cmp_ok($result->name, 'eq', $repository);
        is_deeply($result->tags, ['v1','v2']);
      };
    };

    describe "When it is passed" => sub {
      before each => sub {
        $expected_request = _request({ repository => $repository, n => 101 });
        $stubbed_response = _response({ n => 101 });
        $d->caller
          ->expects('send_request')
          ->with_deep($expected_request)
          ->returns($stubbed_response);
      };

      it 'is added to the request & the result is correctly parsed' => sub {
        my $result = $d->repository_tags(repository => $repository, n => 101);
        cmp_ok($result->name, 'eq', $repository);
        is_deeply($result->tags, [map { "v$_" } (1..101)]);
      };
    };
  };

  describe "'last' parameter" => sub {
    describe "When it is not passed" => sub {
      before each => sub {
        $expected_request = _request({ repository => $repository });
        $stubbed_response = _response();
        $d->caller
          ->expects('send_request')
          ->with_deep($expected_request)
          ->returns($stubbed_response);
      };

      it 'is not added to the request & the result is correctly parsed' => sub {
        my $result = $d->repository_tags(repository => $repository);
        cmp_ok($result->name, 'eq', $repository);
        is_deeply($result->tags, ['v1','v2']);
        ok(!$result->last);
      };
    };

    describe "When it is passed" => sub {
      my $result;
      my $last = 'ukD72mdD/mC8b5xV3susmJzzaTgp';

      before all => sub {
        $expected_request = _request({ repository => $repository, last => $last });
        $stubbed_response = _response({ last => $last });
        $d->caller
          ->expects('send_request')
          ->with_deep($expected_request)
          ->returns($stubbed_response);
      };

      it 'is added to the request & the result is correctly parsed' => sub {
       $result = $d->repository_tags(repository => $repository, last => $last);
        cmp_ok($result->name, 'eq', $repository);
        is_deeply($result->tags, [map { "v$_" } (1..2)]);
      };

      it "the received 'last' value in the 'Link' header is returned in the result object" => sub {
        cmp_ok($result->last, 'eq', $last);
      };
    };
  };
};

runtests unless caller;


use URI;
sub _request {
  my $args = shift;
  my $url  = URI->new(join '/', 'https://my.awesome.registry', 'v2', $args->{repository}, 'tags/list');

  if ($args->{n} or $args->{last}) {
    if ($args->{n} and !$args->{last}) {
      $url->query_form(n => $args->{n});
    } elsif (!$args->{n} and $args->{last}) {
      $url->query_form(last => $args->{last});
    } else {
      $url->query_form(last => $args->{last}, n => $args->{n});
    }
  }

  return Docker::Registry::Request->new(
    method => 'GET',
    url => $url->as_string,
  );
}


sub _response {
  my $args = shift;
  my $n = $args->{n} || 2;

  return Docker::Registry::Response->new(
    status => 200,
    headers => {
      'docker-distribution-api-version' => 'registry/2.0',
      'date' => 'Wed, 21 Oct 2015 07:28:00 GMT',
      'transfer-encoding' => 'chunked',
      'content-type' => 'text/plain; charset=utf-8',
      'connection' => 'keep-alive',
      $args->{last}
        ? (link => "<https://my.awesome.registry/v2/my-repository/tags/list?last=$args->{last}&n=1000>; rel='next'")
        : (),
    },
    content => $args->{content}
      ? encode_json($args->{content})
      : encode_json({ name => 'my-repository', tags =>  [map { "v$_" } (1..$n)] }),
  );
}
