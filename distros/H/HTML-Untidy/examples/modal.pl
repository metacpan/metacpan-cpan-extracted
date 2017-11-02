use strict;
use warnings;
use HTML::Untidy ':common';

sub modal (%) {
  my %param   = @_;
  my $title   = $param{title};
  my $body    = $param{body};
  my $dismiss = $param{dismiss};
  my $close   = $param{close};

  local $HTML::Untidy::INDENT = 2;

  div {
    class 'modal';

    if ($dismiss) {
      attr 'data-backdrop' => 'static';
    }

    div {
      class 'modal-dialog';

      if ($title) {
        div {
          class 'modal-header';
          h5 { class 'modal-title'; text $title };

          if ($dismiss) {
            button { class 'close'; attr 'type' => 'button', 'data-dismiss' => 'modal'; raw '&times;'; };
          }
        };
      }

      div {
        class 'modal-body';

        if ($body) {
          raw $body;
        }
      };

      if ($close || $dismiss) {
        div {
          class 'modal-footer';

          if ($close) {
            button { class 'btn btn-primary'; attr 'type' => 'button'; text $close; };
          }

          if ($dismiss) {
            button { class 'btn btn-secondary'; attr 'type' => 'button', 'data-dismiss' => 'modal'; text $dismiss; };
          }
        };
      }
    };
  };
}
