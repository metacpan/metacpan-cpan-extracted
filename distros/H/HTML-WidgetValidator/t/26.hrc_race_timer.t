use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'HrcRaceTimer' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== HRC Race Timer script - test1
--- input
<script type="text/javascript" src=http://www.honda.co.jp/HRC/fun/blogparts/swf/parts.js></script>
--- expected
HRC Race Timer
