use strict;
use warnings;
use Test::More tests => 12;

# this is needed to avoid false passes if was done first without 'info'
use Inline 'C++' => config => force_build => 1, clean_after_build => 0;

# Test modified from original: Constructor must make copies of the strings
# passed in as params, otherwise pointers may become invalid.

# Original test passed in strings as char* stored them, and returned them
# later.  But no copy was made.  That meant that it was possible for the
# char* pointer that was being stored as member data could become
# invalid, causing wonky behavior (at best).

# The behavior detected was getting improper return values; expecting
# one name, getting another, for example.

my $obj1 = new_ok( 'Soldier', [ 'Benjamin', 'Private', 11111 ] );
my $obj2 = new_ok( 'Soldier', [ 'Sanders', 'Colonel', 22222 ] );
my $obj3 = new_ok( 'Soldier', [ 'Matt', 'Sergeant', 33333 ] );

is( $obj1->get_serial, 11111,      "get_serial() on Priave Benjamin." );
is( $obj1->get_name,   'Benjamin', "get_name() on Private Benjamin."  );
is( $obj1->get_rank,   'Private',  "get_rank() on Private Benjamin."  );

is( $obj2->get_serial, 22222,     "get_serial() on Colonel Sanders." );
is( $obj2->get_name,   'Sanders', "get_name() on Colonel Sanders."   );
is( $obj2->get_rank,   'Colonel', "get_rank() on Colonel Sanders."   );

is( $obj3->get_serial, 33333,      "get_serial() on Sergeant Matt."  );
is( $obj3->get_name,   'Matt',     "get_name() on Sergeant Matt."    );
is( $obj3->get_rank,   'Sergeant', "get_rank() on Sergeant Matt."    );

##############################################################################

use Inline 'C++' => <<END;

class Soldier {
  public:
    Soldier( char *name, char *rank, int serial );
    ~Soldier() { delete[] name; delete[] rank; }

    char *get_name();
    char *get_rank();
    int get_serial();

 private:
    size_t cslen( char *cs );
    char* cscopy( char *cs );
    char *name;
    char *rank;
    int serial;
};

Soldier::Soldier(char *name, char *rank, int serial) {
   this->name = cscopy( name );
   this->rank = cscopy( rank );
   this->serial = serial;
}

char *Soldier::get_name() {
    return name;
}

char *Soldier::get_rank() {
    return rank;
}

int Soldier::get_serial() {
    return serial;
}

size_t Soldier::cslen( char *cs )
{
    size_t len = 0;
    while( *cs++ )
        len++;
    len += 1;
    return len;
}

char* Soldier::cscopy ( char *cs )
{
    char *copy = 0;
    char *head = 0;
    size_t len = cslen( cs );
    copy = head = new char[ len ];
    while( *cs )
        *head++ = *cs++;
    *head = 0;
    return copy;
}

END

done_testing();
