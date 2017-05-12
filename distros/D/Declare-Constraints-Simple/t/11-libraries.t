#!/usr/bin/perl
use warnings;
use strict;

use Test::More tests => 6;
use Declare::Constraints::Simple;

{   
    BEGIN {
        package TestLibrary;
        use warnings; use strict;
        use Declare::Constraints::Simple-Library;
        use base 'Declare::Constraints::Simple::Library';

        constraint Foo => sub { sub { _result(0, 'Foo A') }};
        constraint Bar => sub { sub { _result(0, 'Bar A') }};
    }

    package TestLibrary::Tests;
    use warnings; use strict;
    BEGIN { TestLibrary->import('-All') }
    Test::More::ok(IsInt->(12), 'inheritance from default library');
    Test::More::is(Foo->(23)->message, 'Foo A', 'custom method');
}

{
    BEGIN {
        package TestOverride;
        use warnings; use strict;
        use Declare::Constraints::Simple-Library;
        use base 'TestLibrary';

        constraint Bar => sub { sub { _result(0, 'Bar B') }};
        constraint Baz => sub { sub { _result(0, 'Baz B') }};
    }

    package TestOverride::Tests;
    use warnings; use strict;
    BEGIN { TestOverride->import('-All') }
    Test::More::ok(IsInt->(23), 'inheritance from far away default');
    Test::More::is(Foo->(23)->message, 'Foo A', 'inherited constraint');
    Test::More::is(Bar->(23)->message, 'Bar B', 'overridden constraint');
    Test::More::is(Baz->(23)->message, 'Baz B', 'new constraint');
}
 


1;
