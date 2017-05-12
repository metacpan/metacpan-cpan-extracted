# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..19\n"; }
END {print "not ok 1\n" unless $loaded;}
use HTML::Macro;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$ifp = HTML::Macro->new();
$ifp->set ('@precompile', 1);
$result = $ifp->process ('test/test1.html');
if ($result eq '<if expr="0">ok</if>')
{
    print "ok 1a\n";
} else
{
    print "not ok 1a: $result\nshould be: <if expr=\"0\">ok</if>\n";
}


$ifp = HTML::Macro->new();
$ifp->declare ('var', 'missing', 'outer');
$ifp->set ('var', 'value');
$ifp->set ('qvar', '"<quote me>"');
$ifp->set ('var_var', 'value2');
$ifp->set ('var_UP', 'value3');
$result = $ifp->process ('test/test.html');
if ($result eq 'value &quot;&lt;quote me&gt;&quot; value2 value_x ##VAR_UP##')
{
    print "ok 2\n";
} else
{
    print "not ok 2: $result\n";
}

$ifp = HTML::Macro->new();
$ifp->set ('val', 1);
$result = $ifp->process ('test/test2.html');
if ($result eq "greater\ngreaterequal\ngreaterequal\ngreater\ngreater\ngreaterequal\ngreaterequal\ngreater\nok\n")
{
    print "ok 3\n";
} else
{
    print "not ok 3: $result\n";
}

$ifp = HTML::Macro->new();
$ifp->set ('val', 1);
$ifp->set ('yes', 1);
$result = $ifp->process ('test/test3.html');
if ($result eq "greater\nlessequal\n")
{
    print "ok 4\n";
} else
{
    print "not ok 4: $result\n";
}

$ifp = HTML::Macro->new();
$ifp->set ('pagenum', 2);
$ifp->set ('val', 2);
$result = $ifp->process ('test/test4.html');
if ($result eq "2greater\ngreaterequal\ngreaterequal\ngreater\ngreater\ngreaterequal\ngreaterequal\ngreater\nok\n\ngreater\ngreaterequal\ngreaterequal\ngreater\ngreater\ngreaterequal\ngreaterequal\ngreater\nok\n")
{
    print "ok 5\n";
} else
{
    print "not ok 5: $result\n";
}

$ifp = HTML::Macro->new();
$ifp->set ('pagenum', 2);
$ifp->set ('val', 2);
$result = $ifp->process ('test/test5.html');
if ($result eq '<include/ file="/etc/passwd"><if expr="##YES##">greater</if><quote preserve="1">output should have the quote tag in it</quote>#VAL#')
{
    print "ok 6\n";
} else
{
    print "not ok 6: $result\n";
}

$ifp = HTML::Macro->new();
$ifp->push_incpath ('test/include');
$result = $ifp->process ('test/test6.html');
if ($result eq 'included file stuff.htmlincluded file substuff.html 6a')
{
    print "ok 7\n";
} else
{
    print "not ok 7: $result\n";
}

$ifp->set ('@collapse_whitespace', 1);
$result = $ifp->process ('test/test7.html');
if ($result eq "This has extra white space <textarea name=\"test\">\nbut\npreserve\nthis\n</textarea> end ")
{
    print "ok 8\n";
} else
{
    print "not ok 8: $result\n";
}

$ifp->set ('@collapse_whitespace', 0);
$ifp->set ('@collapse_blank_lines', 1);
$result = $ifp->process ('test/test7.html');
if ($result eq "This       has        extra\n    white     space\n<textarea name=\"test\">\nbut\npreserve\nthis\n</textarea>\nend\n")
{
    print "ok 9\n";
} else
{
    print "not ok 9: $result\nshould be:This       has        extra\n    white     space\n<textarea name=\"test\">\nbut\npreserve\nthis\n</textarea>\nend\n";
}

sub set_val_to_world
{
    my ($htm) = @_;
    $htm->set ('val', 'World');
    return $htm->process;
}

sub set_val_to_world_no_nest
{
    my ($htm) = @_;
    $htm->set ('val', 'World');
}

$result = $ifp->process ('test/test-eval.html');
if ($result eq "Hello, World!\n" x 7)
{
    print "ok 10\n";
} else
{
    print "not ok 10:\n$result\nshould be:\n", ("Hello, World!\n" x 6);
}

$ifp->set_global ('val', -1);
$ifp->set ('yes', 1);
$result = $ifp->process ('test/test-global.html');
if ($result eq "greater\nlessequal\n")
{
    print "ok 11\n";
} else
{
    print "not ok 11: $result\n";
    print "val=", $ifp->get ('val'), "\n";
}

$ifp->set_ovalue ('val', -1);
$ifp->set_ovalue ('oval', 1);
$result = $ifp->process ('test/test-global.html');
if ($result eq "lessequal\ngreater\n")
{
    print "ok 12\n";
} else
{
    print "not ok 12: $result\n";
    print "ovalues=", keys %{$ifp->{'@ovalues'}}, "\n";
    print "val=", $ifp->get ('val'), "\n";
}

if (grep /oval/, $ifp->keys()) {
    print "ok 13\n";
} else {
    print "not ok 13: keys does not contain oval\n";
}

eval {
    $ifp->process ('test/test-error.txt');
};

if ($@ =~ qr{^HTML::Macro: error parsing 'if' attributes:  blah
parsing .*test-error.txt on line 3, char 0

<if blah>; the error should be at char 0

called from test.pl, line }) {
    print "ok 14\n";
} else {
    print "not ok 14: error handler produced $@\n";
    print "should be: ", q{HTML::Macro: error parsing 'if' attributes:  blah
parsing .*/test-error.txt on line 3, char 0

<if blah>; the error should be at char 0

called from test.pl, line };
}

$ifp = new HTML::Macro;
$result = $ifp->process ('test/test-elsif.html');
if ($result ne "one\ntwo\nthree\nfour\n") {
    print "not ok 15: test-elsif produced $result\n";
} else {
    print "ok 15\n";
}

$ifp = new HTML::Macro;
$ifp->set ('yes', 1);
$result = $ifp->process ('test/test-def-global.html');
if ($result eq "greater\nlessequal\n")
{
    print "ok 16\n";
} else
{
    print "not ok 16: $result\n";
    print "val=", $ifp->get ('val'), "\n";
}

$ifp = new HTML::Macro;
$result = $ifp->process ('test/test-include-body.html');
if ($result eq "included: BODY")
{
    print "ok 17\n";
} else
{
    print "not ok 17: $result\n";
}

$result = $ifp->process ('test/test-include-body2.html');
if ($result eq "<outer><inner>BODY</inner></outer>")
{
    print "ok 18\n";
} else
{
    print "not ok 18: $result\n";
}

$result = $ifp->process ('test/test-include-body3.html');
if ($result eq "<outer><inner>BODY</inner></outer>")
{
    print "ok 19\n";
} else
{
    print "not ok 19: $result\n";
}

$result = $ifp->process_buf ('<!--#hidden#-->ok<!---not here--->');
if ($result eq "ok")
{
    print "ok 20\n";
} else
{
    print "not ok 20: $result\n";
}

$result = $ifp->process_buf ('<define name="ok">ok</define>#ok#');
if ($result eq "ok")
{
    print "ok 21\n";
} else
{
    print "not ok 21: $result\n";
}

$result = $ifp->process_buf (q{
<define name="ok1">ok</define>
<define name="ok2">#ok1#</define>
#ok1# #ok2#
});
if ($result =~ /ok ok/)
{
    print "ok 22\n";
} else
{
    print "not ok 22: $result\n";
}

$result = $ifp->process_buf (q{
<define name="ok1"><eval expr="'ok'"></eval></define>
<define name="ok2">#ok1#</define>
#ok1# #ok2#
});
if ($result =~ /ok ok/)
{
    print "ok 23\n";
} else
{
    print "not ok 23: $result\n";
}

