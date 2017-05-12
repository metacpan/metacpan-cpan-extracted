use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'NhkClock' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== NhkClock 1
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/clock150wood.js"></script>
--- expected
NHK CLOCK

=== NhkClock 2
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/clock210wood.js"></script>
--- expected
NHK CLOCK

=== NhkClock 3
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/clock150.js"></script>
--- expected
NHK CLOCK

=== NhkClock 4
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/clock210.js"></script>
--- expected
NHK CLOCK
