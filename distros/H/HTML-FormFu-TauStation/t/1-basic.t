use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
  use_ok('HTML::FormFu::Constraint::TauStation::DateTime');
  use_ok('HTML::FormFu::Constraint::TauStation::Duration');
  use_ok('HTML::FormFu::Inflator::TauStation::DateTime');
  use_ok('HTML::FormFu::Inflator::TauStation::Duration');
  use_ok('HTML::FormFu::Deflator::TauStation::DateTime');
  use_ok('HTML::FormFu::Deflator::TauStation::Duration');
};
