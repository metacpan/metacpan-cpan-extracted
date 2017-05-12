use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'PostPet' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== PostPet Uranai
--- input
<script language="JavaScript" type="text/javascript" src="http://www.so-net.ne.jp/ad/pp-uranai/postpet.js" ></script>
--- expected
PostPet

=== PostPet Window
--- input
<script language="javascript" type="text/javascript" src="http://ppwin.so-net.ne.jp/webmail/petwindow/script.do?window_id=ba949cafca17685b66e077b4114d6c33"></script>
--- expected
PostPet

=== PostPet Clock v1
--- input
<script type="text/javascript" src="http://www.postpet.so-net.ne.jp/webmail/blog/clock_v1_momo.js"></script>
--- expected
PostPet

=== PostPet Clock v2
--- input
<script type="text/javascript" src="http://www.postpet.so-net.ne.jp/webmail/blog/clock_v2_momo.js"></script>
--- expected
PostPet
