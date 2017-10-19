=head1 BENCHMARKS

These module were tested building the same structure, a
L<Bootstrap4 modal|https://getbootstrap.com/docs/4.0/components/modal/#modal-components>
from their documentation.

The code for each of these tests is in the source for this file.

=head1 RESULTS

  use Benchmark ':all';

  timethese 10_000, {
    'HTML::Builder'        => sub{ Bench::HTML::Builder::modal        'this is my modal' },
    'HTML::Tiny',          => sub{ Bench::HTML::Tiny::modal           'this is my modal' },
    'HTML::HTML5::Builder' => sub{ Bench::HTML::HTML5::Builder::modal 'this is my modal' },
    'HTML::Untidy'         => sub{ Bench::HTML::Untidy::modal         'this is my modal' },
  };

  Benchmark: timing 10000 iterations of HTML::Builder, HTML::HTML5::Builder, HTML::Tiny, HTML::Untidy...
  HTML::Builder: 66 wallclock secs (33.58 usr + 31.68 sys = 65.26 CPU) @ 153.23/s (n=10000)
  HTML::HTML5::Builder:  5 wallclock secs ( 5.30 usr +  0.00 sys =  5.30 CPU) @ 1886.79/s (n=10000)
  HTML::Tiny:  2 wallclock secs ( 1.38 usr +  0.00 sys =  1.38 CPU) @ 7246.38/s (n=10000)
  HTML::Untidy:  1 wallclock secs ( 0.88 usr +  0.00 sys =  0.88 CPU) @ 11363.64/s (n=10000)

=cut

package Bench::HTML::Untidy;
use HTML::Untidy ':common';

sub modal {
  my $content = shift;

  div {
    class 'modal';

    div {
      class 'modal-dialog';

      div {
        class 'modal-header';
        h5 { class 'modal-title'; text 'Modal title' };
        button { class 'close'; attr 'type' => 'button', 'data-dismiss' => 'modal'; raw '&times;'; };
      };

      div { class 'modal-body'; raw $content; };

      div {
        class 'modal-footer';
        button { class 'btn btn-primary'; attr 'type' => 'button'; text 'Save changes'; };
        button { class 'btn btn-secondary'; attr 'type' => 'button', 'data-dismiss' => 'modal'; text 'Close'; };
      };
    };
  };
}

1;

package Bench::HTML::Tiny;
use HTML::Tiny;

sub modal {
  my $content = shift;
  my $h = HTML::Tiny->new();
  $h->div({class => 'modal'}, [
    $h->div({class => 'modal-dialog'}, [
      $h->div({class => 'modal-header'}, [
        $h->h5({class => 'modal-title'}, 'Modal title'),
        $h->button({class => 'close', type => 'button', 'data-dismiss' => 'modal'}, '&times;'),
      ]),
      $h->div({class => 'modal-body'}, $content),
      $h->div({class => 'modal-footer'}, [
        $h->button({class => 'btn btn-primary', type => 'button'}, 'Save changes'),
        $h->button({class => 'btn btn-secondary', type => 'button', 'data-dismiss' => 'modal'}, 'Close'),
      ]),
    ]),
  ]);
}

1;

package Bench::HTML::Builder;
use HTML::Builder ':minimal', ':header', ':html5', ':form';

sub modal {
  my $content = shift;

  div {
    attr {class => 'modal'};

    div {
      attr {class => 'modal-dialog'};

      div {
        attr {class => 'modal-header'};

        h5 {
          attr {class => 'modal-title'};
          'Modal title';
        };

        button {
          attr {class => 'close', type => 'button', 'data-dismiss' => 'modal'};
          '&times;';
        };
      };

      div {
        attr {class => 'modal-body'};
        $content;
      };

      div {
        attr {class => 'modal-footer'};
        button { attr {class => 'btn btn-primary', type => 'button'}; 'Save changes' };
        button { attr {class => 'btn btn-secondary', type => 'button', 'data-dismiss' => 'modal'}; 'Close' };
      };
    };
  };
}

1;

package Bench::HTML::HTML5::Builder;
use HTML::HTML5::Builder ':standard';

sub modal {
  my $content = shift;

  div(-class => 'modal',
    div(-class => 'modal-dialog',
      div(-class => 'modal-header',
        h5(-class => 'modal-title', 'Modal title'),
        button(-class => 'close', -type => 'button', '-data-dismiss' => 'modal', RAW_CHUNK('&times;')),
      ),
      div(-class => 'modal-body', RAW_CHUNK($content)),
      div(-class => 'modal-footer',
        button(-class => 'btn btn-primary', -type => 'button', 'Save Changes'),
        button(-class => 'btn btn-secondary', -type => 'button', '-data-dismiss' => 'modal', 'Close')
      ),
    ),
  );
}

1;

package main;
use Benchmark ':all';

timethese 10_000, {
  'HTML::Builder'        => sub{ Bench::HTML::Builder::modal        'this is my modal' },
  'HTML::Tiny',          => sub{ Bench::HTML::Tiny::modal           'this is my modal' },
  'HTML::HTML5::Builder' => sub{ Bench::HTML::HTML5::Builder::modal 'this is my modal' },
  'HTML::Untidy'         => sub{ Bench::HTML::Untidy::modal         'this is my modal' },
};

