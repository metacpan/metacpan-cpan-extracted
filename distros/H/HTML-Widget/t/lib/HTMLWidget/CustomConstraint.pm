package HTMLWidget::CustomConstraint;

use warnings;
use strict;
use base 'HTML::Widget::Constraint::Regex';

sub regex { qr/^[0-9]*$/ }

1;
