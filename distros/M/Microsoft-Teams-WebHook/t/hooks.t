#!/usr/bin/env perl

use v5.26;
use warnings;

use Test2::V0;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;
use Test::MockModule;

use Microsoft::Teams::WebHook;

use experimental qw(signatures);

my $posted;

my $mock_http = Test::MockModule->new('HTTP::Tiny');
$mock_http->redefine(
  post => sub($self, @args) {
    note 'calling HTTP::Tiny post mocked method';
    $posted = [@args];
  }
);

like(
  dies {Microsoft::Teams::WebHook->new()},
  qr/\QRequired parameter 'url' is missing for Microsoft::Teams::WebHook constructor\E/,
  'Dies when missing URL'
);

my $url  = 'http://localhost';
my $hook = Microsoft::Teams::WebHook->new(url => $url);

$hook->post("hello world");
check_posted_values({text => 'hello world'}, 'raw message using post');

$hook->post({text => 'hello world', custom => 'field'});
check_posted_values({text => 'hello world', custom => 'field'}, 'custom hash using post');

$hook->post_ok('posting a simple "ok" text');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'good',
              'text'  => 'posting a simple "ok" text',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_ok( msg )'
);

$hook->post_ok(text => 'posting a simple "ok" text as hash');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'good',
              'text'  => 'posting a simple "ok" text as hash',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_ok( hash(msg) )'
);

$hook->post_info('posting a simple "info" text');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'accent',
              'text'  => 'posting a simple "info" text',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_info( msg )'
);

$hook->post_info(text => 'posting a simple "info" text as hash');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'accent',
              'text'  => 'posting a simple "info" text as hash',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_info( hash(msg) )'
);

$hook->post_warning('posting a simple "warning" text');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'warning',
              'text'  => 'posting a simple "warning" text',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_warning( msg )'
);

$hook->post_warning(text => 'posting a simple "warning" text as hash');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'warning',
              'text'  => 'posting a simple "warning" text as hash',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_warning( hash(msg) )'
);

$hook->post_error('posting a simple "error" text');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'attention',
              'text'  => 'posting a simple "error" text',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_error( msg )'
);

$hook->post_error(text => 'posting a simple "error" text as hash');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'attention',
              'text'  => 'posting a simple "error" text as hash',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_error( hash(msg) )'
);

$hook->post_ok([qw(line1 line2 line3)]);
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'good',
              'text'  => 'line1',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }, {
              'color' => 'good',
              'text'  => 'line2',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }, {
              'color' => 'good',
              'text'  => 'line3',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_ok( array(msg) )'
);

$hook->post_ok(text => [qw(line1 line2 line3)]);
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'good',
              'text'  => 'line1',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }, {
              'color' => 'good',
              'text'  => 'line2',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }, {
              'color' => 'good',
              'text'  => 'line3',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_ok( array(hash(msg)) )'
);

$hook->post_ok(text => 'posting a light "msg" text', text_color => 'light');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'light',
              'text'  => 'posting a light "msg" text',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_ok( light_msg )'
);

$hook->post_start('start');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'accent',
              'text'  => 'start',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_start(msg)'
);

sleep(3);
$hook->post_end('end');
check_posted_values(
  {
    attachments => [
      {
        content => {
          '$schema' => 'http://adaptivecards.io/schemas/adaptive-card.json',
          'body'    => [
            {
              'color' => 'good',
              'text'  => 'end',
              'type'  => 'TextBlock',
              'wrap'  => 1
            }, {
              'type'  => 'RichTextBlock',
              inlines => [
                {
                  type   => 'TextRun',
                  text   => 'run time: 3 seconds',
                  italic => 1
                }
              ]
            }
          ],
          'msteams' => {
            'width' => 'Full'
          },
          'type'    => 'AdaptiveCard',
          'version' => '1.5'
        },
        'contentType' => 'application/vnd.microsoft.card.adaptive',
        'contentUrl'  => undef
      }
    ],
    'type' => 'message'
  },
  'post_end(msg)'
);

sub check_posted_values($expect, $msg = 'check_posted_values') {
  is($posted, [$url, D()], 'check_posted_values called') or die;

  my $content = eval {JSON::XS->new->utf8(0)->decode($posted->[1]->{content})};
  diag 'Error: ', $@ if $@;
  is($content, $expect, $msg) or diag explain $content, explain $posted->[1]->{content};

  $posted = undef;
}

done_testing;
