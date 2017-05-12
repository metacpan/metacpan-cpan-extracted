use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'SlideShare' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== SlideShare object - test1
--- input
<object type="application/x-shockwave-flash" data="http://s3.amazonaws.com/slideshare/ssplayer.swf?id=99618&doc=webscraper1372" width="425" height="348"><param name="movie" value="http://s3.amazonaws.com/slideshare/ssplayer.swf?id=99618&doc=webscraper1372" /></object>
--- expected
SlideShare
