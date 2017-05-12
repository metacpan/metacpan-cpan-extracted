#!/usr/bin/env perl
#
# Test formatting as plain text with Text::Autoformat
#

use strict;
use warnings;

use Mail::Message::Test;
use Mail::Message::Body;

use Test::More;

BEGIN {
    eval 'require Text::Autoformat';
    if($@)
    {   plan skip_all => "Text::Autoformat not available.";
        exit 0;
    }

    require Mail::Message::Convert::TextAutoformat;
    require Text::Autoformat;
    Text::Autoformat->import('break_wrap');

    plan tests => 3;
}

my $content = <<'TEXT';
This is some raw text to form the body of the
message which has to be printed.  I hope it is nice.
> some badly formatted
>    input lines
>  are also in here, to test whether autoformat works.... This line is for instance much too long and should be spread over multiple lines.
TEXT

my $body = Mail::Message::Body->new
 ( type  => 'text/html'
 , data  => $content
 );

my $af = Mail::Message::Convert::TextAutoformat
  ->new( options => {break => break_wrap} );
ok($af);

my $dump = $af->autoformatBody($body);
ok(defined $dump);

is("$dump", <<'DUMP');
This is some raw text to form the body of the message which has to be
printed. I hope it is nice.
> some badly formatted input lines are also in here, to test whether
> autoformat works.... This line is for instance much too long and
> should be spread over multiple lines.
DUMP
