package HTMLWidget::CustomFilter;

use warnings;
use strict;
use base 'HTML::Widget::Filter';

sub filter {
    my ( $self, $value ) = @_;
    return lc $value;
}

1;
