use warnings;
use Test::More tests => 1;
use HTML::YaTmpl;
my $t=HTML::YaTmpl->new( onerror=>'die', path=>['templates'] );

sub x {
  $t->template=$_[2];
  my $rc=$t->evaluate_as_config;
  #use Data::Dumper;
  #warn "-------------------\n", Dumper($rc), "-------------------\n";
  is_deeply($rc, $_[1], $_[0]);
}

x( 'simple config',
   { 'v1' => 'v1',
     'v2' => 'v2',
     'v3' => 'v3',
     'v4' => 'v4',
     'v5' => 'v5',
   },
   <<'EOF' );
 <=v1>v1</=v1>
 <=v2>v2</=v2>
 <=v3>v3</=v3>
 <=v4>v4</=v4>
 <=v5>v5</=v5>
EOF

# Local Variables:
# mode: cperl
# End:
