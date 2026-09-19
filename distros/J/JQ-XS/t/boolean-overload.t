#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use File::Temp ();
use File::Spec;

use JQ::XS ();

# Loading JQ::XS must not make another JSON module warn about the shared
# JSON::PP::Boolean class, in either load order.  Cpanel::JSON::XS installs the
# boolean operators itself, and JSON::XS does the same through
# Types::Serialiser:
#
#   - loaded after one of them, pulling in JSON::PP::Boolean would redefine
#     their operators ("Subroutine JSON::PP::Boolean::(0+ redefined");
#   - loaded before, leaving JSON::PP::Boolean loaded without JSON::PP would
#     make Cpanel::JSON::XS's version check read an undefined
#     $JSON::PP::VERSION.
#
# Both warnings are gated on $^W, so the checks below run under -w.  Neither
# module is a dependency here, so stand one up that sets JSON::PP::Boolean up
# the way Cpanel::JSON::XS does, guard included.

my $libdir = File::Temp::tempdir(CLEANUP => 1);

sub write_file {
    my ($name, $content) = @_;
    my $path = File::Spec->catfile($libdir, $name);
    open my $fh, '>', $path or die "cannot write $path: $!";
    print $fh $content;
    close $fh or die "cannot close $path: $!";
    return $path;
}

write_file('FakeJSONXS.pm', <<'FAKE');
package FakeJSONXS;
use strict;
use warnings;
BEGIN {
  package
    JSON::PP::Boolean;
  require overload;
  local $^W;
  if (!defined $JSON::PP::Boolean::VERSION or $JSON::PP::VERSION lt '4.00') {
    &overload::import('overload',
      '0+'     => sub { ${$_[0]} },
      '++'     => sub { $_[0] = ${$_[0]} + 1 },
      '--'     => sub { $_[0] = ${$_[0]} - 1 },
    );
  }
  &overload::import('overload',
    '""'     => sub { ${$_[0]} == 1 ? '1' : '0' },
    fallback => 1,
  );
}
1;
FAKE

my $report = <<'PROG';
my ($true)  = JQ::XS->new('. > 2')->process(5);
my ($false) = JQ::XS->new('. > 2')->process(1);
print "ref=", ref($true), " true=", ($true ? 1 : 0), " false=", ($false ? 1 : 0),
      " num=", 0 + $true, "\n";
PROG

sub run_script {
    my ($name, @lines) = @_;
    my $script = write_file($name, join('', @lines, $report));
    my $cmd = join ' ',
      map { quotemeta } ($^X, '-w', (map { "-I$_" } @INC, $libdir), $script);
    return scalar `$cmd 2>&1`;
}

my $expected = "ref=JSON::PP::Boolean true=1 false=0 num=1\n";

is(run_script('after.pl', "use FakeJSONXS;\n", "use JQ::XS;\n"), $expected,
   'loading JQ::XS after another module overloaded JSON::PP::Boolean is '
   . 'silent under -w and leaves the booleans working');

is(run_script('before.pl', "use JQ::XS;\n", "use FakeJSONXS;\n"), $expected,
   'loading JQ::XS before it is silent under -w too');

# On its own, JQ::XS still has to provide the overloads.
ok(JSON::PP::Boolean->can('(('), 'JSON::PP::Boolean is overloaded');
my ($true) = JQ::XS->new('. > 2')->process(5);
isa_ok($true, 'JSON::PP::Boolean');
is(0 + $true, 1, 'true numifies to 1');
ok($true, 'true is true');
my ($false) = JQ::XS->new('. > 2')->process(1);
is(0 + $false, 0, 'false numifies to 0');
ok(!$false, 'false is false');

done_testing();
