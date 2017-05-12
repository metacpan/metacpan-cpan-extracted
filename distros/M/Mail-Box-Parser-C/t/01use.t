#!/usr/bin/env perl
use Test::More;
BEGIN
{
    eval "require Mail::Box::Parser";
    if($@)
    {    plan skip_all =>
             "Skipping tests, because MailBox is not installed (yet)\n";
         exit 0;
    }

    plan tests => 1;
}

require Mail::Box::Parser::C;
ok(1);
