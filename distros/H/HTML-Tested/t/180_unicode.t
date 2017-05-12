use strict;
use warnings FATAL => 'all';
use Encode;
use Data::Dumper;

use Test::More tests => 10;

BEGIN { use_ok('HTML::Tested', 'HTV');
	use_ok('HTML::Tested::Value::Marked');
}

package T;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget(::HTV."::Marked", 'v');

package main;

my $a = Encode::decode('utf-8', 'дед');
my $object = T->new({ v => $a });
my $stash = {};
$object->ht_render($stash);
is_deeply($stash, { v => "<!-- v --> $a" });

my $s = HTML::Tested::Seal->instance('boo boo boo');
is(Encode::decode_utf8($s->decrypt($s->encrypt($a))), $a);

my $h = "hel\0oo";
is($s->decrypt($s->encrypt($h)), $h);

my $b;
open my $fh, '/dev/urandom';
sysread $fh, $b, 1024;
close $fh;
is($s->decrypt($s->encrypt($b)), $b);

my @_get_opts;

package V;
use base 'HTML::Tested::Value';

sub seal_value {
	return $_[1] . "_sealed>";
}

package T2;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("V", 'v');

sub ht_get_widget_option {
	my ($self, $wname, $opname) = @_;
	push @_get_opts, $opname;
	return shift()->SUPER::ht_get_widget_option(@_);
}


package main;

$object = T2->new({ v => 'aaa' });
$stash = {};
@_get_opts = ();
$object->ht_render($stash);
is_deeply(\@_get_opts, []) or diag(Dumper(\@_get_opts));

$object->v(undef);
$object->ht_render($stash);
is_deeply(\@_get_opts, []) or diag(Dumper(\@_get_opts));

package T3;
use base 'HTML::Tested';
__PACKAGE__->ht_add_widget("V", 'v' => is_sealed => 1);

package main;

$object = T3->new({ v => '<a' });
$stash = {};
@_get_opts = ();
$object->ht_render($stash);
is_deeply(\@_get_opts, []) or diag(Dumper(\@_get_opts));
is_deeply($stash, { v => '&lt;a_sealed&gt;' });
