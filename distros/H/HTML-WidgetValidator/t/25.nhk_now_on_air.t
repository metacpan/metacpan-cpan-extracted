use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'NhkNowOnAir' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== NhkNowOnAir 1
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/noa150.js"></script>
--- expected
NHK NOW ON AIR

=== NhkNowOnAir 2
--- input
<script type="text/javascript" language="javascript" src="http://www.nhk.or.jp/lab-blog/blogtools/script/noa210.js"></script>
--- expected
NHK NOW ON AIR
