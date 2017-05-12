# This is a test for module HTML::Valid.

use warnings;
use strict;
use Test::More;
use HTML::Valid;

my $htv = HTML::Valid->new ();
ok ($htv, "made the object ok");
my ($output, $errors) = $htv->run ("<title>Foo</title><p>Foo!");
like ($output, qr/<!DOCTYPE html>/, "got right output");
like ($errors, qr/missing <!DOCTYPE> declaration/, "got right errors");

done_testing ();
# Local variables:
# mode: perl
# End:
