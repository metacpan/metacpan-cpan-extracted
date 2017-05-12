#!/usr/bin/env perl

use strict;
use warnings;

package Method::Lexical::Test::Qualified;

sub test { __PACKAGE__ }

package Method::Lexical::Test::Unqualified;

sub test { __PACKAGE__ }

package main;

use constant UNDEFINED_METHOD => qr{^Can't locate object method "\w+" via package };

use Test::More tests => 12;

# a poor man's Test::Fatal::exception to keep the dependencies light(er)
sub exception (&) {
    my $code = shift;
    eval { $code->() };
    return $@;
}

my $self = bless [] => 'Method::Lexical::Test::Unqualified';

{
    package Method::Lexical::Test::Unqualified;

    use Test::More;

    use Method::Lexical {
        autoload_qualified   => '+Method::Lexical::Test::Qualified::test',
        qualified            => 'Method::Lexical::Test::Qualified::test',
        autoload_unqualified => '+test',
        unqualified          => 'test',
    };

    is ($self->autoload_qualified, 'Method::Lexical::Test::Qualified', 'qualified method-name value resolved to specified package (autoloaded)');
    is ($self->qualified, 'Method::Lexical::Test::Qualified', 'qualified method-name value resolved to specified package');
    is ($self->autoload_unqualified, 'Method::Lexical::Test::Unqualified', 'unqualified method-name value resolved to currently-compiling package (autoloaded)');
    is ($self->unqualified, 'Method::Lexical::Test::Unqualified', 'unqualified method-name value resolved to currently-compiling package');
}

for my $method_name (qw(autoload_qualified qualified autoload_unqualified unqualified)) {
    like exception { $self->$method_name }, UNDEFINED_METHOD, "autoloaded: lexical method undefined outside scope: $method_name";
}

{
    package Method::Lexical::Test::Unqualified;

    use Test::More;

    use Method::Lexical {
        qualified   => 'Method::Lexical::Test::Qualified::test',
        unqualified => 'test',
      '-autoload'   => 1,
    };

    is ($self->qualified, 'Method::Lexical::Test::Qualified', 'qualified method-name value resolved to specified package (-autoload => 1)');
    is ($self->unqualified, 'Method::Lexical::Test::Unqualified', 'unqualified method-name value resolved to currently-compiling package (-autoload => 1)');
}

for my $method_name (qw(qualified unqualified)) {
    like exception { $self->$method_name }, UNDEFINED_METHOD, "-autoload => 1: lexical method undefined outside scope: $method_name";
}
