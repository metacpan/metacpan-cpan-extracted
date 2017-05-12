use strict;
use Test::Base;
use HTML::WidgetValidator;

sub validate {
    my $validator = HTML::WidgetValidator->new(widgets => [ 
	'CubeDriving','CubeDrivingGame', 'CubeEawaseGame', 'CubeThrowinGame' ]);
    my $result = $validator->validate(shift);
    return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__
=== CUBE DRIVING script
--- input
<script src="http://www.nissan.co.jp/CUBE/PARTS/driving_game/drive.js" type="text/javascript"></script>
--- expected
CUBE DRIVING

=== CUBE DRIVING GAME script
--- input
<script src="http://www.nissan.co.jp/CUBE/PARTS/DRIVING_BLOG/driving_blog.js" type="text/javascript"></script>
--- expected
CUBE DRIVING GAME

=== CUBE EAWASE GAME script
--- input
<script src="http://www.nissan.co.jp/CUBE/PARTS/eawase/eawase.js" type="text/javascript"></script>
--- expected
CUBE EAWASE GAME

=== CUBE Throw-in Game script
--- input
<script src="http://www.nissan.co.jp/CUBE/PARTS/throw_in/throw.js" type="text/javascript"></script>
--- expected
CUBE Throw-in Game
