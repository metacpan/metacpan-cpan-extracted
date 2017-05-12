use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Capture
  'capture',
  capture_builtin => ['-MDevel::Confess::Builtin'],
;
use Devel::Confess::Builtin ();

my @class = (
  'Exception::Class' => {
    declare => 'use Exception::Class qw(MyException);',
    throw   => 'MyException->throw("nope");',
  },
  'Ouch' => {
    throw   => 'Ouch::ouch(100, "nope");',
  },
  'Class::Throwable' => {
    throw   => 'Class::Throwable->throw("nope");',
  },
  'Exception::Base' => {
    declare => 'use Exception::Base qw(MyException);',
    throw   => 'MyException->throw("nope");',
  },
);

plan tests => scalar @class;

while (@class) {
  my ($class, $info) = splice @class, 0, 2;
  (my $module = "$class.pm") =~ s{::}{/}g;
  require $module;
  my $declare = $info->{declare} || "use $class;";
  my $code = <<END;
$declare

package PackageA;
sub f {
$info->{throw}
}
package PackageB;
sub g {
PackageA::f();
}
END
  my $before = capture_builtin $code.'PackageB::g();';
  my $after = capture $code.'require Devel::Confess::Builtin;Devel::Confess::Builtin->import(); PackageB::g();';
  like $before, qr/PackageB::g/, "verbose when loaded before $class";
  like $after, qr/PackageB::g/, "verbose when loaded after $class";
}
