package Devel::ebug::Backend::Plugin::Eval;
$Devel::ebug::Backend::Plugin::Eval::VERSION = '0.59';
use strict;
use warnings;


sub register_commands {
  return (
    eval => { sub => \&DB::eval, record => 1 },
    yaml => { sub => \&DB::yaml },
  );
}


package DB;
$DB::VERSION = '0.59';

# there appears to be something semi-magical about the DB 
# namespace that makes this eval only work when it's in it
sub eval {
  my($req, $context) = @_;
  my $eval = $req->{eval};
  local $SIG{__WARN__} = sub {};

  my $v = eval "package $context->{package}; $eval";
  if ($@) {
    return { eval => $@, exception => 1 };
  } else {
    return { eval => $v, exception => 0 };
  }
}

sub yaml {
  my($req, $context) = @_;
  my $eval = $req->{yaml};
  local $SIG{__WARN__} = sub {};

  my $v = eval "package $context->{package}; use YAML; Dump($eval)";
  if ($@) {
    return { yaml => $@ };
  } else {
    return { yaml => $v };
  }
}

1;
