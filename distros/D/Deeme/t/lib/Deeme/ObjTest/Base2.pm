package Deeme::ObjTest::Base2;
use Deeme::Obj 'Deeme::ObjTest::Base1';

has [qw(ears eyes)] => sub {2};
has coconuts => 0;

1;