#!/usr/bin/perl -T

# This script tests compatibility with HTML::Form's interface. These tests
# are plagiarised from that module's tests (22/Sep/7), except for a few at
# the bottom.

use strict; use warnings; use lib 't';

use Test::More tests
 => 116 # form.t
  +  24 # form_param.t
  +  2  # misc
  +  3  # <button>
  +  4; # bugs

BEGIN{	use_ok 'HTML::DOM' };

# Since HTML::Form's click method is the one to call make_request, whereas
# with HTML::DOM, it just triggers the event and it is up to an event
# handler to call make_request, I'm putting a handler here that (sort of)
# imitates HTML::Form's behaviour, for the sake of the tests.

{	my $req;
	sub new_doc {
		0&&$req; # work around perl 5.8 bug
		my $doc = new HTML::DOM url => shift;
		$doc->default_event_handler(sub{
			my $target = shift->target;
			$req = ($target->tag eq 'form' ? $target :
				$target->form)->make_request;
		});
		$doc
	}
	sub click {
		shift->click;
		return $req;
	}
}
	

# ----------- from libwww-5.806/t/html/form.t ------------- #
my @warn;
$SIG{__WARN__} = sub { push(@warn, $_[0]) };

(my $doc = new_doc "http://localhost/")->write(<<'EOT', );
<form action="abc" name="foo">
<input name="name">
</form>
<form></form>
EOT
$doc->close;

my $f = ($doc->forms)[0];
is($f->value("name"), "");

my $req = $f->main::click;
is($req->method, "GET");
is($req->uri, "http://localhost/abc?name=");

$f->value(name => "Gisle Aas");
$req = $f->main::click;
is($req->method, "GET");
is($req->uri, "http://localhost/abc?name=Gisle+Aas");

is($f->attr("name"), "foo");
is($f->attr("method"), undef);

$f = ($doc->forms)[1];
is($f->method, "get");
is($f->action, "http://localhost/");
is($f->enctype, "application/x-www-form-urlencoded");

# try some more advanced inputs
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form method=post>
   <input name=i type="image" src="foo.gif">
   <input name=c type="checkbox" checked>
   <input name=r type="radio" value="a">
   <input name=r type="radio" value="b" checked>
   <input name=t type="text">
   <input name=p type="PASSWORD">
   <input name=h type="hidden" value=xyzzy>
   <input name=s type="submit" value="Doit!">
   <input name=r type="reset">
   <input name=b type="button">
   <input name=f type="file" value="foo.txt">
   <input name=x type="xyzzy">

   <textarea name=a>
abc
   </textarea>

   <select name=s>
      <option>Foo
      <option value="bar" selected>Bar
   </select>

   <select name=m multiple>
      <option selected value="a">Foo
      <option selected value="b">Bar
   </select>
</form>
EOT


#print $f->dump;
#print $f->click->as_string;

my $t = <<'EOT';
POST http://localhost/
Content-Length: 76
Content-Type: application/x-www-form-urlencoded; charset="utf-8"

i.x=1&i.y=1&c=on&r=b&t=&p=&h=xyzzy&f=foo.txt&x=&a=%0Aabc%0A+++&s=bar&m=a&m=b
EOT
($t = quotemeta $t) =~ s/\\%0A/(?:%0D)?%0A/g;
$t =~ s/76/(?:76|82)/;
like($f->main::click->as_string, qr/^$t\z/);


$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>
   <input type=submit value="Upload it!" name=n disabled>
   <input type=image alt="Foo">
   <input type=text name=t value="1">
</form>
EOT

#$f->dump;
is($f->main::click->as_string, <<'EOT');
GET http://localhost/?x=1&y=1&t=1

EOT

# test file upload
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form method=post enctype="MULTIPART/FORM-DATA">
   <input name=f type=file value=>
   <input type=submit value="Upload it!">
</form>
EOT

#print $f->dump;
#print $f->click->as_string;

is($f->main::click->as_string, <<'EOT');
POST http://localhost/
Content-Length: 0
Content-Type: multipart/form-data; boundary=none

EOT

my $filename = sprintf "foo-%08d.txt", $$;
die if -e $filename;

open(FILE, ">$filename") || die;
binmode(FILE);
print FILE "This is some text\n";
close(FILE) || die;

$f->value(f => $filename);

#print $f->click->as_string;

is($f->main::click->as_string, <<"EOT");
POST http://localhost/
Content-Length: 139
Content-Type: multipart/form-data; boundary=xYzZY

--xYzZY\r
Content-Disposition: form-data; name="f"; filename="$filename"\r
Content-Type: text/plain\r
\r
This is some text
\r
--xYzZY--\r
EOT

unlink($filename) || warn "Can't unlink '$filename': $!";

is(@warn, 0);


$doc = new_doc "http://www.example.com";
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>
   <input type=checkbox name=x> I like it!
</form>
EOT


SKIP:{ skip 'not supported', 1; # and probably won't ever be
$f->find_input("x")->check;

is($f->main::click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT
}


SKIP: { skip 'not yet implemented', 3;
$f->value("x", "off");
ok($f->main::click->as_string, <<"EOT");
GET http://www.example.com

EOT

$f->value("x", "I like it!");
ok($f->main::click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT

$f->value("x", "I LIKE IT!");
ok($f->main::click->as_string, <<"EOT");
GET http://www.example.com?x=on

EOT
} # SKIP



$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>
<select name=x>
   <option value=1>one
   <option value=2>two
   <option>3
</select>
<select name=y multiple>
   <option value=1>
</select>
</form>
EOT

$f->value("x", "one");

is($f->main::click->as_string, <<"EOT");
GET http://www.example.com?x=1

EOT

SKIP: { skip 'not yet implemented', 2;
$f->value("x", "TWO");
ok($f->main::click->as_string, <<"EOT");
GET http://www.example.com?x=2

EOT

ok(join(":", $f->find_input("x")->value_names), "one:two:3");
} # SKIP

is(join(":", map $_->name, $f->find_input(undef, "option")), "x:y");

$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>
<input name=x value=1 disabled>
<input name=y value=2 READONLY type=TEXT>
<input name=z value=3 type=hidden>
</form>
EOT

is($f->value("x"), 1);
is($f->value("y"), 2);
is($f->value("z"), 3);
is($f->main::click->uri->query, "y=2&z=3");

my $input = $f->find_input("x");
is($input->type, "text");
SKIP: { skip 'not supported', 1;
ok(!$input->readonly);
}
ok($input->disabled);
ok($input->disabled(0));
ok(!$input->disabled);
is($f->main::click->uri->query, "x=1&y=2&z=3");

$input = $f->find_input("y");
is($input->type, "text");
SKIP: { skip 'not supported', 1;
ok($input->readonly);
}
ok(!$input->disabled);

$input->value(22);
is($f->main::click->uri->query, "x=1&y=22&z=3");
SKIP:{ skip 'not yet implemented', 2; # if ever?
ok(@warn, 1);
ok($warn[0] =~ /^Input 'y' is readonly/);
}
@warn = ();

SKIP:{ skip 'not supported', 2;
ok($input->readonly(0));
ok(!$input->readonly);
}

$input->value(222);
SKIP: { skip 'not yet implemented', 1;
ok(@warn, 0);
print @warn;
}
is($f->main::click->uri->query, "x=1&y=222&z=3");

$input = $f->find_input("z");
is($input->type, "hidden");
SKIP: { skip 'not supported', 1;
ok($input->readonly);
}
ok(!$input->disabled);

$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>
<textarea name="t" type="hidden">
<foo>
</textarea>
<select name=s value=s>
 <option name=y>Foo
 <option name=x value=bar type=x>Bar
</form>
EOT

is($f->value("t"), "\n<foo>\n");
SKIP: { skip 'doesn\'t work yet', 2; is($f->value("s"), "Foo");
is(join(":", $f->find_input("s")->possible_values), "Foo:bar"); } # ~~~
SKIP: { skip 'not supported', 1;
ok(join(":", $f->find_input("s")->other_possible_values), "bar");
}
SKIP: { skip "doesn't work yet",2; is($f->value("s", "bar"), "Foo");
is($f->value("s"), "bar");} # ~~~
SKIP: { skip 'not supported', 1;
ok(join(":", $f->find_input("s")->other_possible_values), "");
}


$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form>

<input type=radio name=r0 value=1 disabled>one

<input type=radio name=r1 value=1 disabled>one
<input type=radio name=r1 value=2>two
<input type=radio name=r1 value=3>three

<input type=radio name=r2 value=1>one
<input type=radio name=r2 value=2 disabled>two
<input type=radio name=r2 value=3>three

<select name=s0>
 <option disabled>1
</select>

<select name=s1>
 <option disabled>1
 <option>2
 <option>3
</select>

<select name=s2>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=s3 disabled>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=m0 multiple>
 <option disabled>1
</select>

<select name=m1 multiple="">
 <option disabled>1
 <option>2
 <option>3
</select>

<select name=m2 multiple>
 <option>1
 <option disabled>2
 <option>3
</select>

<select name=m3 disabled multiple>
 <option>1
 <option disabled>2
 <option>3
</select>

</form>

EOT
#print $f->dump;
ok($f->find_input("r0")->disabled);
ok(!eval {$f->value("r0", 1);});
ok($@ && $@ =~ /^The value '1' has been disabled for field 'r0'/);
SKIP: { skip 'not supported', 4;
ok($f->find_input("r0")->disabled(0));
ok(!$f->find_input("r0")->disabled); # test 59
is($f->value("r0", 1), undef);
is($f->value("r0"), 1);
}

ok(!$f->find_input("r1")->disabled);
is($f->value("r1", 2), undef);
is($f->value("r1"), 2);
ok(!eval {$f->value("r1", 1);});
ok($@ && $@ =~ /^The value '1' has been disabled for field 'r1'/);

is($f->value("r2", 1), undef);
ok(!eval {$f->value("r2", 2);});
ok($@ && $@ =~ /^The value '2' has been disabled for field 'r2'/);
SKIP: { skip 'not yet implemented', 2;
ok(!eval {$f->value("r2", "two");}); # test 70
ok($@ && $@ =~ /^The value 'two' has been disabled for field 'r2'/);
}
SKIP : { skip 'not supported', 4;
ok(!$f->find_input("r2")->disabled(1));
ok(!eval {$f->value("r2", 1);});
ok($@ && $@ =~ /^The value '1' has been disabled for field 'r2'/);
ok($f->find_input("r2")->disabled(0));
}
ok(!$f->find_input("r2")->disabled);
SKIP : { skip 'not supported', 1;
is($f->value("r2", 2), 1);
}

ok($f->find_input("s0")->disabled); # test 78
ok(!$f->find_input("s1")->disabled);
ok(!$f->find_input("s2")->disabled);
ok($f->find_input("s3")->disabled);

SKIP: { skip "doesn't work yet", 2;
ok(!eval {$f->value("s1", 1);});
ok($@ && $@ =~ /^The value '1' has been disabled for field 's1'/);
}

ok($f->find_input("m0")->disabled);
SKIP: { skip "doesn't work yet", 17;
ok($f->find_input("m1", undef, 1)->disabled);
ok(!$f->find_input("m1", undef, 2)->disabled);
ok(!$f->find_input("m1", undef, 3)->disabled);

ok(!$f->find_input("m2", undef, 1)->disabled);
ok($f->find_input("m2", undef, 2)->disabled);
ok(!$f->find_input("m2", undef, 3)->disabled);

ok($f->find_input("m3", undef, 1)->disabled);
ok($f->find_input("m3", undef, 2)->disabled);
ok($f->find_input("m3", undef, 3)->disabled);

$f->find_input("m3", undef, 2)->disabled(0);
ok(!$f->find_input("m3", undef, 2)->disabled);
is($f->find_input("m3", undef, 2)->value(2), undef);
is($f->find_input("m3", undef, 2)->value(undef), 2);

$f->find_input("m3", undef, 2)->disabled(1);
ok($f->find_input("m3", undef, 2)->disabled);
is(eval{$f->find_input("m3", undef, 2)->value(2)}, undef);
ok($@ && $@ =~ /^The value '2' has been disabled/);
is(eval{$f->find_input("m3", undef, 2)->value(undef)}, undef);
ok($@ && $@ =~ /^The 'm3' field can't be unchecked/);
}

SKIP:{ skip 'not supported', 5;
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<!-- from http://www.blooberry.com/indexdot/html/tagpages/k/keygen.htm -->
<form  METHOD="post" ACTION="http://example.com/secure/keygen/test.cgi" ENCTYPE="application/x-www-form-urlencoded">
   <keygen NAME="randomkey" CHALLENGE="1234567890">
   <input TYPE="text" NAME="Field1" VALUE="Default Text">
</form>
EOT

ok($f->find_input("randomkey"));
ok($f->find_input("randomkey")->challenge, "1234567890");
ok($f->find_input("randomkey")->keytype, "rsa");
ok($f->main::click->as_string, <<EOT);
POST http://example.com/secure/keygen/test.cgi
Content-Length: 19
Content-Type: application/x-www-form-urlencoded; charset=utf-8

Field1=Default+Text
EOT

$f->value(randomkey => "foo");
ok($f->main::click->as_string, <<EOT);
POST http://example.com/secure/keygen/test.cgi
Content-Length: 33
Content-Type: application/x-www-form-urlencoded; charset=utf-8

randomkey=foo&Field1=Default+Text
EOT
} # SKIP

$doc = new_doc "http://www.example.com";
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form  ACTION="http://example.com/">
   <select name=s>
     <option>1
     <option>2
   <input name=t>
</form>
EOT

ok($f);
ok($f->find_input("t"));


$doc->write(<<'EOT'); $doc->close; my @f = $doc->forms;
<form  ACTION="http://example.com/">
   <select name=s>
     <option>1
     <option>2
</form>
<form  ACTION="http://example.com/">
     <input name=t>
</form>
EOT

is(@f, 2);
ok($f[0]->find_input("s"));
ok($f[1]->find_input("t"));

SKIP: { skip 'not supported (?)', 5;
$doc->write(<<'EOT'); $doc->close; $f = ($doc->forms)[0];
<form  ACTION="http://example.com/">
  <fieldset>
    <legend>Radio Buttons with Labels</legend>
    <label>
      <input type=radio name=r0 value=0 />zero
    </label>
    <label>one
      <input type=radio name=r1 value=1>
    </label>
    <label for="r2">two</label>
    <input type=radio name=r2 id=r2 value=2>
    <label>
      <span>nested</span>
      <input type=radio name=r3 value=3>
    </label>
    <label>
      before
      and <input type=radio name=r4 value=4>
      after
    </label>
  </fieldset>
</form>
EOT

is(join(":", $f->find_input("r0")->value_names), "zero");
is(join(":", $f->find_input("r1")->value_names), "one");
is(join(":", $f->find_input("r2")->value_names), "two");
is(join(":", $f->find_input("r3")->value_names), "nested");
is(join(":", $f->find_input("r4")->value_names), "before and after");
}


# ----------- from libwww-5.806/t/html/form-param.t ------------- #
# Tests 117 onwards

($doc = new_doc "http://example.com")
 ->write(<<'EOT', ); my $form = ($doc->forms)[0];
<form>
<input type="hidden" name="hidden_1">

<input type="checkbox" name="checkbox_1" value="c1_v1" CHECKED>
<input type="checkbox" name="checkbox_1" value="c1_v2" CHECKED>
<input type="checkbox" name="checkbox_2" value="c2_v1" CHECKED>

<select name="multi_select_field" multiple="1">
 <option> 1
 <option> 2
 <option> 3
</select>
</form>
EOT

# list names
is($form->param, 4);
is(j($form->param), "hidden_1:checkbox_1:checkbox_2:multi_select_field");

# get
is($form->param('hidden_1'), '');
is($form->param('checkbox_1'), 'c1_v1');
is(j($form->param('checkbox_1')), 'c1_v1:c1_v2');
is($form->param('checkbox_2'), 'c2_v1');
is(j($form->param('checkbox_2')), 'c2_v1');
ok(!defined($form->param('multi_select_field')));
is(j($form->param('multi_select_field')), '');
ok(!defined($form->param('unknown')));
is(j($form->param('unknown')), '');
ok(!@warn, 'no warnings');

# set
$form->param('hidden_1', 'x');
SKIP:{ skip 'not yet implemented', 1;
ok(@warn && $warn[0] =~ /^Input 'hidden_1' is readonly/);
}
@warn = ();
is(j($form->param('hidden_1')), 'x');

eval {
    $form->param('checkbox_1', 'foo');
};
ok($@);
is(j($form->param('checkbox_1')), 'c1_v1:c1_v2');

$form->param('checkbox_1', 'c1_v2');
is(j($form->param('checkbox_1')), 'c1_v2');
$form->param('checkbox_1', 'c1_v2');
is(j($form->param('checkbox_1')), 'c1_v2');
$form->param('checkbox_1', []);
is(j($form->param('checkbox_1')), '');
$form->param('checkbox_1', ['c1_v2', 'c1_v1']);
is(j($form->param('checkbox_1')), 'c1_v1:c1_v2');
$form->param('checkbox_1', []);
is(j($form->param('checkbox_1')), '');
$form->param('checkbox_1', 'c1_v2', 'c1_v1');
is(j($form->param('checkbox_1')), 'c1_v1:c1_v2');

SKIP: { skip "doesn't work yet", 1;
$form->param('multi_select_field', 3, 2);
is(j($form->param('multi_select_field')), "2:3");
}

print "# Done\n";
ok(!@warn);

sub j {
    join(":", @_);
}

# -------- Miscellaneous Tests That Were Not Filched from LWP -------- #

$doc->open; $doc->write(
 '<form action="file:///dwile"><input name=plew value=glor>
                               <input name=frat value=flin></form>'
);
is +($doc->forms)[0]->make_request->uri,
   'file:///dwile?plew=glor&frat=flin',
   'make_request with the file protocol';
$doc->open; $doc->write(
 '<form action="data:text/html,squext"><input name=plew value=glor>
                               <input name=frat value=flin></form>'
);
is +($doc->forms)[0]->make_request->uri,
   'data:text/html,squext',
   'make_request with GET method and data: URL';

# -------- <button> elements ---------- #

$doc->close;
$doc->write("<form><button name=b value=v><button name=b value=w>
                   <button name=btnAccept></button>(no value)
                   <button type=reset name=c value=d>
                   <button type=button name=e value=f>
            </form>");
is $doc->getElementsByTagName('button')->[1]->main'click->as_string,
   "GET http://example.com?b=w\n\n", '<button> elements';
is +($doc->forms)[0]->main::click->as_string,
   "GET http://example.com?b=v\n\n",
   'form->click supports <button>s';
is $doc->getElementsByTagName('button')->[2]->main'click->as_string,
   "GET http://example.com?btnAccept=\n\n", '<button> element with no val';

# -------- Bugs related to HTML::DOM’s HTML::Form imitation ---------- #
{

my $doc = new HTML::DOM;
$doc->write('<title>What’s up, Doc?</title>
	<form><select name=Bunny><!-- no options --></select></form>');
$doc->close;
is eval { $doc->forms->[0]->{Bunny}->options->name } || diag($@), 'Bunny',
	'select->options->name no longer dies when there are no options';

$doc->write(
 '<form><input name=c type=checkbox value=12345 checked></form>'
);
my $f = $doc->forms->[0];
$f->value(c => undef);
ok ! $f->{c}->checked, 'form->value(field, undef) unchecks a checkbox';

local $SIG{__WARN__};
$f->innerHTML(
 '<input name=c type=radio value=a><input name=c type=radio value=b>'
);
my $radioset = $f->find_input('c');
$radioset->value('a');
ok $f->{c}[0]->checked && !$f->{c}[1]->checked,
    '->value(x) on radio nodelist works if nothing is checked yet';
$radioset->value('b');
ok !$f->{c}[0]->checked && $f->{c}[1]->checked,
    '->value(x) on radio nodelist works if something is checked already';

}

