use Test::More tests => 11;

use Data::Dumper;
require Inline::denter;
use Inline Ruby;
# TEST
ok(1);

# Depending on whether FLATTEN_CALLBACK_ARGS is defined or not, array refs may
# be flattened on their way to the Perl iterators. To enable passing the tests
# anyway, we'll just make sure to check for that here:
my %results = (
    0	=> [1, "2", [3], {4 => 5}],
    1	=> [1, "2", 3, {4 => 5}],
);
my $obj = new Iterator(1, "2", [3], {4 => 5});

my $n;
sub my_iter {
    my $element = shift;
    print "It looks like Ruby passed me this: ", Dumper($element);

    my $got = Inline::denter->new->indent($element);
    my $exp = Inline::denter->new->indent(
	$results{Inline::Ruby::config_var("FLATTEN_CALLBACK_ARGS")}[$n++]
    );
    print Dumper $got, $exp;
    # TEST*(4+4)
    is($got, $exp);
}

$n = 0;
$obj->iter(\&my_iter)->each;
$n = 0;
$obj->iter(\&my_iter)->each_proc;

# We WANT this to fail:
eval {
    $obj->each();
};
my $Err = $@;
# TEST
is ($Err->type, 'LocalJumpError', "Error type");
# TEST
like (
    $Err->message,
    qr/\Ano block given(?: \(yield\))?\z/,
    "Message is correct.",
);
print "NOTE: $@\n";

__END__
__Ruby__

class Iterator
  def initialize(*elements)
    @elements = elements
  end
  def each
    @elements.each { |x| yield x }
  end
  def each_proc(&pr)
    @elements.each { |x| pr.call(x) }
  end
end
