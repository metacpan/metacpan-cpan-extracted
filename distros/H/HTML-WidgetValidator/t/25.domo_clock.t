use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'DomoClock' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Domo Clock script - test1
--- input
<script type="text/javascript"
 src="http://www.domomode.com/blogparts/domo_clock02.js"></script>
--- expected
Domo Clock
