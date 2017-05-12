
use blib;

use Data::Dumper;
use Test::More qw( no_plan );

my $sMod;
BEGIN
  {
  $sMod = q{Devel::Todo::Find};
  use_ok($sMod);
  };
my $o = new $sMod;
isa_ok($o, $sMod);

# Create a file whose name ends with tilde (because CVS doesn't let us
# have it in the distro):
warn $! if ! open TILDE, '>', q{t/LeaveOut/tilde.txt~};
print TILDE <<ENDTILDE or warn $!;
TODO: tilde.txt~ line 1
TODO:tildetxtline2
ENDTILDE
close TILDE or warn $!;

# Force scalar mode, default options:
my $s = $o->todos;
isnt($s, q{}, 'got some todos (scalar mode)');

# Force array mode, default options:
my @as = $o->todos;
# diag(@as);
cmp_ok(scalar(@as), q{>}, 0, 'got some todos (array mode)');

$o->add_dirs(q{t});
@as = $o->todos;
# warn Dumper(\@as);
is(scalar(@as), 8, 'todos in t');

$o->ignore_dirs(q{LeaveOut});
@as = $o->todos;
is(scalar(@as), 4, 'todos in t but not t/LeaveOut');

$o->ignore_dirs(q{.pm});
@as = $o->todos;
is(scalar(@as), 2, 'todos in t but not t/LeaveOut and not *.pm');

pass(q{all done});

__END__
