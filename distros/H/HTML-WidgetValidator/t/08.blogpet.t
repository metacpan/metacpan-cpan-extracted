use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'BlogPet' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== BlogPet
--- input
<script language="JavaScript" type="text/javascript" src="http://www.blogpet.net/js/68bc2a398e2a4a69ae518ad7b59642b5.js" charset="UTF-8"></script>
--- expected
BlogPet

