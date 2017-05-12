# -*- Mode: Perl; -*-

use strict;

$^W = 1;

#An object without a "param" method
package Support::Object;

sub new{
    my ($proto) = @_;
    my $self = {};
    bless $self, $proto;
    return $self;
}

###
#End of Support::Object

use Test::More tests => 38;

use_ok('HTML::FillInForm');

my $html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
<input type="text" name="three" value="not disturbed">
</form>
];

my $result = HTML::FillInForm->new->fill_scalarref(
                                         \$html,
                                         fdat => {
                                           two => "new val 2",
                                           three => "new val 3",
                                         },
                                         ignore_fields => 'one',
                                         );

ok($result =~ /not disturbed/ && $result =~/\bone/,'scalar value of ignore_fields');
ok($result =~ /new val 2/ && $result =~ /two/,'fill_scalarref worked');
ok($result =~ /new val 3/ && $result =~ /three/,'fill_scalarref worked 2');


$html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];

my @html_array = split /\n/, $html;


{ 
    $result = HTML::FillInForm->new->fill_arrayref(
                                             \@html_array,
                                             fdat => {
                                               one => "new val 1",
                                               two => "new val 2",
                                             },
                                             );

    ok($result =~ /new val 1/ && $result =~ /\bone/, 'fill_arrayref 1');
    ok($result =~ /new val 2/ && $result =~ /\btwo/, 'fill_arrayref 2');
}

{
    $result = HTML::FillInForm->fill(
        \@html_array,
        {
            one => "new val 1",
            two => "new val 2",
        },
     );

    ok($result =~ /new val 1/ && $result =~ /\bone/, 'fill_arrayref 1');
    ok($result =~ /new val 2/ && $result =~ /\btwo/, 'fill_arrayref 2');
}

{

    $result = HTML::FillInForm->new->fill_file(
        "t/data/form1.html",
        fdat => {
            one => "new val 1",
            two => "new val 2",
            three => "new val 3",
        },
    );

    ok($result =~ /new val 1/ && $result =~ /\bone/,'fill_file 1');
    ok($result =~ /new val 2/ && $result =~ /\btwo/,'fill_file 2');
    ok($result =~ /new val 3/ && $result =~ /\bthree/,'fill_file 3');
}

{
    $result = HTML::FillInForm->fill(
        "t/data/form1.html",
        {
            one => "new val 1",
            two => "new val 2",
            three => "new val 3",
        },
    );

    ok($result =~ /new val 1/ && $result =~ /\bone/,'fill_file 1');
    ok($result =~ /new val 2/ && $result =~ /\btwo/,'fill_file 2');
    ok($result =~ /new val 3/ && $result =~ /\bthree/,'fill_file 3');
}
{
    my $fh = open FH, "<t/data/form1.html" || die "can't open file: $!";

    $result = HTML::FillInForm->fill(
        \*FH,
        {
            one => "new val 1",
            two => "new val 2",
            three => "new val 3",
        },
    );

    ok($result =~ /new val 1/ && $result =~ /\bone/,'fill_file 1');
    ok($result =~ /new val 2/ && $result =~ /\btwo/,'fill_file 2');
    ok($result =~ /new val 3/ && $result =~ /\bthree/,'fill_file 3');
    close(\*FH);
}



$html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];

eval{
$result = HTML::FillInForm->new->fill_scalarref(
                                         \$html
                                         );
};

$result = HTML::FillInForm->new->fill(
                                    fdat => {}
                                    );

#No meaningful arguments - should not this produce an error?


$html = qq[
<form>
<input type="text" name="one" value="not disturbed">
<input type="text" name="two" value="not disturbed">
</form>
];

my $fobject = new Support::Object;

eval{
$result = HTML::FillInForm->new->fill_scalarref(
                                         $html,
                                         fobject => $fobject
                                         );
};

like($@, qr/HTML::FillInForm->fill called with fobject option, containing object of type Support::Object which lacks a param\(\) method!/, "bad fobject parameter");


$html = qq{<INPUT TYPE="radio" NAME="foo1">
<input type="radio" name="foo1" >
};

my %fdat = (foo1 => 'bar2');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result =~ /on/ && $result =~ /\bfoo1/,'defaulting radio buttons to on');


$html = qq{<INPUT TYPE="password" NAME="foo1">
};

%fdat = (foo1 => ['bar2', 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result =~ /bar2/ && $result =~ /\bfoo1/,'first array element taken for password fields');


$html = qq{<INPUT TYPE="radio" NAME="foo1" value="bar2">
<INPUT TYPE="radio" NAME="foo1" value="bar3">
};

%fdat = (foo1 => ['bar2', 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

my $is_checked = join(" ",map { m/checked/ ? "yes" : "no" } split ("\n",$result));

ok($is_checked eq "yes no",'first array element taken for radio buttons');


$html = qq{<TEXTAREA></TEXTAREA>};

%fdat = (area => 'foo1');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result !~ /foo1/,'textarea with no name');


$html = qq{<TEXTAREA NAME="foo1"></TEXTAREA>};

%fdat = (foo1 => ['bar2', 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);


ok($result eq '<TEXTAREA NAME="foo1">bar2</TEXTAREA>','first array element taken for textareas');


$html = qq{<INPUT TYPE="radio" NAME="foo1" value="bar2">
<INPUT TYPE="radio" NAME="foo1" value="bar3">
<TEXTAREA NAME="foo2"></TEXTAREA>
<INPUT TYPE="password" NAME="foo3">
};

%fdat = (foo1 => [undef, 'bar1'], foo2 => [undef, 'bar2'], foo3 => [undef, 'bar3']);

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result !~ m/checked/, "Empty radio button value");
like($result, qr#<TEXTAREA NAME="foo2"></TEXTAREA>#, "Empty textarea");
like($result, qr/<input( (type="password"|name="foo3"|value="")){3}>/, "Empty password field value");


$html = qq[<div></div>
<!--Comment 1-->
<form>
<!--Comment 2-->
<input type="text" name="foo0" value="not disturbed">
<!--Comment

3-->
<TEXTAREA NAME="foo1"></TEXTAREA>
</form>
<!--Comment 4-->
];

%fdat = (foo0 => 'bar1', foo1 => 'bar2');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result =~ /bar1/ and $result =~ /\bfoo0/,'form with comments 1');
like($result, qr'<TEXTAREA NAME="foo1">bar2</TEXTAREA>','form with comments 2');
like($result, qr'<!--Comment 1-->','Comment 1');
like($result, qr'<!--Comment 2-->','Comment 2');
like($result, qr'<!--Comment\n\n3-->','Comment 3');
like($result, qr'<!--Comment 4-->','Comment 4');

$html = qq[<div></div>
<? HTML processing instructions 1 ?>
<form>
<? XML processing instructions 2?>
<input type="text" name="foo0" value="not disturbed">
<? HTML processing instructions

3><TEXTAREA NAME="foo1"></TEXTAREA>
</form>
<?HTML processing instructions 4 >
];

%fdat = (foo0 => 'bar1', foo1 => 'bar2');

$result = HTML::FillInForm->new->fill(scalarref => \$html,
                        fdat => \%fdat);

ok($result =~ /bar1/ && $result =~ /\bfoo0/,'form with processing 1');
like($result, qr'<TEXTAREA NAME="foo1">bar2</TEXTAREA>','form with processing 2');
like($result, qr'<\? HTML processing instructions 1 \?>','processing 1');
like($result, qr'<\? XML processing instructions 2\?>','processing 2');
like($result, qr'<\? HTML processing instructions\n\n3>','processing 3');
like($result, qr'<\?HTML processing instructions 4 >','processing 4');

