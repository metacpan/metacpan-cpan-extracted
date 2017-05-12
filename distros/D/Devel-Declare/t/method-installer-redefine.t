use strict;
use warnings;
use Test::More tests => 5;
use Devel::Declare::MethodInstaller::Simple;

BEGIN {
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method',
    into => 'main',
  );
}

BEGIN {
  no warnings 'redefine';
  Devel::Declare::MethodInstaller::Simple->install_methodhandler(
    name => 'method_quiet',
    into => 'main',
  );
}

ok(!main->can('foo'), 'foo() not installed yet');

method foo {
    $_[0]->method
}

ok(main->can('foo'), 'foo() installed at runtime');

my @warnings;
$SIG{__WARN__} = sub { push @warnings, $_[0] };

@warnings = ();
method foo {
$_[0]->method;
}
is scalar(@warnings), 1;
like $warnings[0], qr/redefined/;

@warnings = ();
method_quiet foo {
$_[0]->method;
}
is_deeply \@warnings, [];
