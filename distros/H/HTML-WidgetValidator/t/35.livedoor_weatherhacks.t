use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'LivedoorWeatherHacks' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Livedoor Weather Hacks script - test1
--- input
<script language="javascript" charset="euc-jp" type="text/javascript" src="http://weather.livedoor.com/plugin/common/forecast/13.js"></script>
--- expected
livedoor Weather Hacks
