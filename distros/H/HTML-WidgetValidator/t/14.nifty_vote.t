use Test::Base;
use HTML::WidgetValidator;

sub validate {
  my $validateor = HTML::WidgetValidator->new(widgets => [ 'NiftyVote' ]);
  my $result  = $validateor->validate(shift);
  return $result ? $result->name : ' ';
}

filters {
    input    => [qw/chomp validate/],
    expected => [qw/chomp/],
};

__END__

=== NiftyVote 1
--- input
<script type="text/javascript" charset="utf8" src="http://files.vote.nifty.com/individual/196/3222/vote.js"></script>
--- expected
NiftyVote
=== NiftyVote 2
--- input
<script type="text/javascript" charset="utf8" src="http://files.vote.nifty.com/individual/1616/3431/vote.js"></script>
--- expected
NiftyVote
=== NiftyVote 3
--- input
<script type="text/javascript" charset="utf8" src="http://files.vote.nifty.com/individual/132/2528/vote.js"></script>
--- expected
NiftyVote

