#!perl
#
# This file is part of Jedi-Plugin-Auth
#
# This software is copyright (c) 2013 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;
use Test::More;

use Jedi;

my $jedi = Jedi->new;
ok !eval { $jedi->road( '/', 't::lib::MissingSession' ); 1 },
    'missing session';
like $@,
    qr{\QYou need to include and configure Jedi::Plugin::Session first.\E},
    'error ok';

done_testing;
