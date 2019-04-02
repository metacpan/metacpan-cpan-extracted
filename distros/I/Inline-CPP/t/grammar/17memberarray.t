use strict;
use warnings;
use Test::More;
# Test member array feature (single-dimensional only).

# this is needed to avoid false passes if was done first without 'info'
use Inline CPP => config => force_build => 1, clean_after_build => 0;

use Inline CPP => 'DATA';

my $obj = new_ok( 'TestMemberArray' );
is( $obj->get_value_at(1), 101, "Member array accessor gets correct value." );

done_testing();


__DATA__
__CPP__

class TestMemberArray {
  public:
    TestMemberArray() { for( size_t i = 0; i < 5; i++ ) member_array[i] = i + 100; }
    ~TestMemberArray() {}
    int get_value_at( int i ) { return member_array[i]; }
  private:
    int member_array[5];
};

