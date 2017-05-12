# mix procedural subroutine and object-oriented method
use strict;
use warnings;
use Test::More tests => 5;

use Inline (CPP => 'DATA', classes => sub { join('::', split('__', shift)); } );  # AUTOMATIC
#use Inline (CPP => 'DATA', classes => { 'Inline__Test__Inline_CPP_Debug' => 'Inline::Test::Inline_CPP_Debug'} );  # MANUAL

can_ok 'Inline::Test::Inline_CPP_Debug', 'new';
my $my_object = new_ok 'Inline::Test::Inline_CPP_Debug';
is ref($my_object), 'Inline::Test::Inline_CPP_Debug', 'Our "Inline__Test__Inline_CPP_Debug" is a "Inline::Test::Inline_CPP_Debug"';
is $my_object->my_method(), 'RETVAL FROM my_subroutine()', 'Proper object method association from Inline::Test::Inline_CPP_Debug.';
is my_subroutine(), 'RETVAL FROM my_subroutine()', 'Proper subroutine association.';

done_testing();

__DATA__
__CPP__

SV* my_subroutine() { return(newSVpv("RETVAL FROM my_subroutine()", 27)); }

class Inline__Test__Inline_CPP_Debug
{
public:
    SV* my_method() { return my_subroutine(); }
    Inline__Test__Inline_CPP_Debug() {}
    ~Inline__Test__Inline_CPP_Debug() {}
};
