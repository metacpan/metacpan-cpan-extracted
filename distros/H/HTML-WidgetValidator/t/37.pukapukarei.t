use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'PukaPukaRei' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== PukaPukaRei script - test1
--- input
<script src="http://blogtool.evastore.jp/puka_rei/pukapuka1.js" type="text/javascript"></script>
--- expected
PukaPukaRei

