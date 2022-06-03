use Storable 'dclone';

use strict;
use warnings;

HTML::Obj2HTML::register_extension("dbtable", {
  tag => "table",
  before => sub {
    my $obj = shift;
    # we should have: hdl, the db handle to use;
    if ($obj->{header}) {
      push(@{$obj->{_}}, thead => [ tr => HTML::Obj2HTML::iterate("th", $obj->{header}) ]);
      delete($obj->{header});
    }
    if ($obj->{hdl} && $obj->{map}) {
      my @rows = ();
      while (my $r = $obj->{hdl}->next) {
        my @cols = ();
        foreach my $c (@{$obj->{map}}) {
          if (!ref $c) {
            if (exists $r->{$c}) {
              push(@cols, td => $r->{$c});
            } else {
              push(@cols, td => $c);
            }
          } else {
            if (ref $c eq "CODE") {
              my $coderet = &$c($r);
              push(@cols, td => $coderet );
            } else {
              my $newc = dclone $c;
              push(@cols, td => deepreplace($newc, $r) );
            }
          }
        }
        push(@rows, tr => \@cols);
      }
      push(@{$obj->{_}}, tbody => \@rows);
      delete($obj->{hdl});
      delete($obj->{map});
    }
    return "";
  },
  attr => { class => 'ui celled table' }
});

sub deepreplace {
  my $target = shift;
  my $record = shift;
  if (ref $target eq "ARRAY") {
    for (my $i=0; $i<=$#{$target}; $i++) {
      $target->[$i] = deepreplace($target->[$i], $record);
    }
  } elsif (ref $target eq "HASH") {
    foreach my $k (keys %{$target}) {
      $target->{$k} = deepreplace($target->{$k}, $record);
    }

  } elsif (!ref $target) {
    $target = shallowreplace($target, $record);
  }
  return $target;
}
sub shallowreplace {
  my $str = shift;
  my $record = shift;
  $str =~ s/\$\$([a-zA-Z0-9]+)/$record->{$1}/g;
  return $str;
}

1;
