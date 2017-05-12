#!perl

# tests for Extented form object

use strict;
use warnings;
use Test::More tests => 20;

BEGIN{ use_ok('HTML::FillInForm::Lite') }

use Time::localtime;
use File::stat;

sub field2re{
	my($struct, $field) = @_;
	my $src = sprintf q{name="%s" \s+ value="%s"}, $field, $struct->$field();
	return qr/$src/xms;
}

# Name Value to regexp
sub nv2re{
	return qr/name="$_[0]" \s+ value="$_[1]"/xms;
}

my $tm = localtime();
my $st = stat(__FILE__);
isa_ok $tm, 'Time::tm';
isa_ok $st, 'File::stat';

my $o = HTML::FillInForm::Lite->new();

my $tmf = <<'EOT';
<input name="year"/>
<input name="mon"/>
<input name="mday"/>
<input name="hour"/>
<input name="min"/>
<input name="sec"/>
<input name="no_such_field" value="x"/>
EOT

my $stf = <<'EOT';
<input name="size"/>
<input name="atime"/>
<input name="mtime"/>
<input name="ctime"/>
<input name="no_such_field" value="x"/>
EOT

my $output = $o->fill(\$tmf, $tm);
foreach my $field (qw(year mon mday hour min sec)){
	like $output, field2re($tm, $field), "field: tm->$field";
}
like $output, nv2re("no_such_field", "x"), "no such field";

$output = $o->fill(\$stf, $st);

foreach my $field (qw(size atime mtime ctime)){
	like $output, field2re($st, $field), "field: st->$field";
}
like $output, nv2re("no_such_field", "x"), "no such field";
{
	package MyObject;
	sub new{ bless {} };
	sub return_undef{ undef  }
	sub return_empty{ return }
	sub return_list { return qw(foo bar) };
}

my $myobj = MyObject->new;

my $objf = <<'EOT';
<input name="return_undef" value="x"/>
<input name="return_empty" value="x"/>
<input name="return_list" id="0" value="x"/>
<input name="return_list" id="1" value="x"/>
<input name="return_list" id="2" value="x"/>
EOT

$output = $o->fill(\$objf, $myobj);

like $output, nv2re("return_undef", "x"), "accessor returning undef";
like $output, nv2re("return_empty", "x"), "accessor returning null list";

my @expected = qw(foo bar x);
for my $i (0 .. 2){
	like $output,  qr/name="return_list" \s+id="$i" \s+ value="$expected[$i]"/xms,
		"accessor returning list($i)";
}
