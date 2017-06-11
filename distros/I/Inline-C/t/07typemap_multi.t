use strict; use warnings; use diagnostics;
use FindBin '$Bin';
use lib $Bin;
my $t = $Bin;
use Test::More;
use TestInlineSetup;
use Inline Config => DIRECTORY => $TestInlineSetup::DIR;

my $obj = Soldier->new('Benjamin', 'Private', 11111);

is($obj->get_serial, 11111);
is($obj->get_name, 'Benjamin');
is($obj->get_rank, 'Private');
done_testing;

package Soldier;

BEGIN { $t = -d 'test' ? 'test' : 't'; }

use Inline C => Config => USING => 'Inline::C::Parser::RegExp',
  TYPEMAPS => ["$t/typemap", "$t/soldier_typemap"];

use Inline C => <<'END';

typedef struct {
  char* name;
  char* rank;
  long  serial;
} Soldier;

Soldier * new(char* class, char* name, char* rank, long serial) {
    Soldier* soldier;
    New(42, soldier, 1, Soldier);

    soldier->name = savepv(name);
    soldier->rank = savepv(rank);
    soldier->serial = serial;

    return soldier;
}


char* get_name(Soldier * obj) {
      return obj->name;
}

char* get_rank(Soldier * obj) {
      return obj->rank;
}

long get_serial(Soldier * obj) {
     return obj->serial;
}

void DESTROY(Soldier* obj) {
     Safefree(obj->name);
     Safefree(obj->rank);
     Safefree(obj);
}
END
