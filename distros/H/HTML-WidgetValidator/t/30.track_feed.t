use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 'TrackFeed' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== Track Feed a - test1
--- input
<a href="http://trackfeed.com/"><img name="trackfeed_banner" src="http://img.trackfeed.com/img/tfg.gif" alt="track feed" border="0"></a>
--- expected
Track Feed

=== Track Feed script - test2
--- input
<script src="http://script.trackfeed.com/usr/91b6d17d62.js"></script>
--- expected
Track Feed
