use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 3;
use Safe;
use Devel::Confess ();

local $TODO = 'not working reliably with Safe in perl 5.6'
  if "$]" < 5.008;
{
  package Shared::Ex;
  use overload '""' => sub { $_[0]->{message} };
  sub foo {
    die @_;
  }
  sub bar {
    foo(@_);
  }
  sub new {
    my $class = shift;
    bless {@_}, $class;
  }
}

my $comp = Safe->new;
$comp->share_from('main', [
  '*Shared::Ex::'
]);
$comp->permit('entereval');
Devel::Confess->import;
$comp->reval('Shared::Ex::bar("string")');
Devel::Confess->unimport;
like $@, qr{
  \Astring\ at\ \S+\ line\ \d+\.[\r\n]+
  [\t]Shared::Ex::foo\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
  [\t]Shared::Ex::bar\(.*?\)\ called\ at\ .*\ line\ \d+[\r\n]+
}x, 'works in Safe compartment with string error';

Devel::Confess->import;
sub { sub {
  $comp->reval('Shared::Ex->new(message => "welp")->bar');
}->(2) }->(1);
Devel::Confess->unimport;

isa_ok $@, 'Shared::Ex';
ok !$@->isa('Devel::Confess::_Attached'),
  "didn't interfere with object inside Safe";
