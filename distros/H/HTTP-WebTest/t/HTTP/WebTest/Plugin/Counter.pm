# $Id: Counter.pm,v 1.1.1.1 2002/01/24 12:26:20 m_ilya Exp $

package HTTP::WebTest::Plugin::Counter;

use strict;

use base qw(HTTP::WebTest::Plugin);

use HTTP::WebTest::Utils qw(make_access_method);

*counter_ref = make_access_method('COUNTER_REF');

sub start_tests {
    my $self = shift;

    my $var = 10;

    $self->counter_ref(\$var);
}

sub check_response {
    my $self = shift;

    ${$self->counter_ref} ++;

    my $value = ${$self->counter_ref};

    return ['COUNTER', $self->test_result(1, "Counter value is a '$value'")];
}

1;
