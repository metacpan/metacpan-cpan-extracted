use Test;
BEGIN { plan tests => 6 }
use Data::Dumper;
use Inline::Ruby qw(rb_eval rb_bind_func rb_bind_class);

rb_eval <<'END';
# An unbound method
def smut(*args)
  print "=============================================================\n"
  print "Yo! smut() called inside ruby!\nArguments:\n"
  args.each {|x| printf("\t%s\n", x)}
  print "=============================================================\n"
  return [52, 25]
end

# A class
class Scrooge
  def initialize
    print "=============================================================\n"
    print "Creating a new instance of Scrooge in Ruby!\n"
    print "=============================================================\n"
  end
  def here_i_am(*args)
    print "=============================================================\n"
    print "This is ruby's here_i_am method\nArguments:\n"
    #args.each {|x| printf("\t%s\n", x)}
    p args
    print "=============================================================\n"
    return 17
  end
end
END

ok(1);

rb_bind_func('main::smut', 'smut');
print "Calling the Ruby function 'smut()'...\n";
my $foo = smut(0, 0xFF, "neil");
print Dumper $foo;
ok(ref($foo), 'ARRAY');
ok($foo->[0], 52);
ok($foo->[1], 25);

rb_bind_class('main::Scrooge', 'Scrooge');
print "Creating an instance of the Ruby class 'Scrooge()'...\n";
my $o = Scrooge->new;
print Dumper $o;
ok($o);
my $bar = $o->here_i_am({neil => 10});
ok($bar, 17);
print Dumper $bar;
