use Test;
BEGIN { plan tests => 6 }
use Data::Dumper;
use Inline::Ruby qw(
			rb_eval
			rb_call_class_method
			rb_call_instance_method
			rb_new_object
			rb_call_function
			rb_iter
		    );

rb_eval(join '', <DATA>);

rb_iter('Fuzzy', sub { ok($_[0]) })->classMeth(1, 2, 3);
my $o = rb_call_class_method('Fuzzy', 'new');
ok(ref($o), 'Inline::Ruby::Object');
my $o2 = rb_new_object('Fuzzy', 'Fuzzy');
ok(ref($o2), 'Fuzzy');

print Dumper $o, $o2;
rb_iter($o, sub { ok($_[0], "neil") })->instMeth("neil");

__END__

class Fuzzy
  def Fuzzy.classMeth(*things)
    print "Inside Fuzzy.classMeth\n"
    things.each { |x| yield x }
  end
  def instMeth(*things)
    print "Inside Fuzzy.instMeth\n"
    things.each { |x| yield x }
  end
end
