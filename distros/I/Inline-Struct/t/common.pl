use Test::More;

# assumes suitable class setup before call
sub run_struct_tests {
  my $class = 'Inline::Struct::Foo';
  my $o = $class->new;
  isa_ok $o, $class;
  isa_ok $o->inum(10), $class;
  $o->dnum(3.1415);
  $o->str('Wazzup?');
  my %vals = (inum => 10, dnum => 3.1415, str => 'Wazzup?');
  is $o->$_(), $vals{$_}, $_ for qw(inum str);
  ok eq_float($o->dnum(), $vals{dnum}), 'dnum';
  is_deeply [ sort keys %{ $o->_HASH } ], [ qw(dnum inum str) ], '_HASH method';
  is_deeply $o->_KEYS, [ qw(inum dnum str) ], '_KEYS method';
}

my $EPSILON = 1e-6;
# true if same within $EPSILON
sub eq_float {
  my ($f1, $f2) = @_;
  abs(($f1//0) - ($f2//0)) <= $EPSILON;
}

1;

__END__
$o->Print;

package Inline::Struct::Foo;
sub Print {
    my $o = shift;
    print "Foo {\n" . (join "\n", map { "\t".$o->$_() } @{$o->_KEYS}) . "\n}\n";
}
