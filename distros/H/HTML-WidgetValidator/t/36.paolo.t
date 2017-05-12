use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'Paolo' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Paolo script - test1
--- input
<script type="text/javascript" charset="utf-8" src="http://paolo.blogdeco.jp/js/paolo.js#80957"></script>
--- expected
Paolo

