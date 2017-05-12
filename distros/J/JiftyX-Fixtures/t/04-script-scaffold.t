use lib qw(lib t/lib);
use Test::More 'no_plan';
use Cwd 'abs_path';
use File::Basename;

use UNIVERSAL::dump;

use Jifty;
use Jifty::Everything;

use JiftyTest;

use JiftyX::Fixtures;
use JiftyX::Fixtures::Script::Scaffold;

BEGIN {
  Jifty->new;
}


my $s = JiftyX::Fixtures::Script::Scaffold->new;

my $scaffold = qq{#-
#  account:
#  auth_token:
#  email:
#  password:
#  email_confirmed:
#  privilege:
-
  account:
  auth_token:
  email:
  password:
  email_confirmed:
  privilege:
};

my @columns = Jifty->app_class("Model","User")->columns;
is($s->render_scaffold(@columns), $scaffold, "test scaffold");



