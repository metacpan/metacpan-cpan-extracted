use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'TsukumoRanking' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Tsukumo Ranking
--- input
<script type="text/javascript" src="http://shop.tsukumo.co.jp/blogparts/ranking/runner.js"></script>
--- expected
TSUKUMO Ranking
