#!/usr/bin/perl

use utf8;
use strict;
use warnings;

#######################
# TESTING starts here #
#######################
use Test::More tests => 2;

use EBook::MOBI;
my $obj = EBook::MOBI->new();
$obj->set_encoding(':encoding(UTF-8)');

my $c = EBook::MOBI::Converter->new();

my $mhtml_text = '';

$mhtml_text .= $c->title(     $c->text('Hello! Viele Grüße!') , 1, 0);
$mhtml_text .= $c->paragraph( $c->text('He said <你好>.') );

$obj->add_mhtml_content($mhtml_text);
$obj->make();
my $res = $obj->print_mhtml(1);

# We expect non ASCII chars and special chars such as < to be encoded
like($res, qr|<h1>Hello! Viele Gr&uuml;&szlig;e!</h1>|s, 'Title encoded OK');
like($res, qr|<p>He said &lt;&#x4F60;&#x597D;&gt;.</p>|s, 'Body encoded OK');

########
# done #
########
1;

