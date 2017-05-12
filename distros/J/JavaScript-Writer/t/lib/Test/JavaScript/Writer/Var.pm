package Test::JavaScript::Writer::Var;
use strict;
use warnings;

use base qw(Test::Class);
use Test::More;
use JavaScript::Writer;

use self;

sub setup : Test(setup) {
    self->{js} = JavaScript::Writer->new;
}

sub test_var_decl : Test(1) {
    my $js = self->{js};

    $js->var('a');

    is "$js", 'var a;', "var declaration";
}

sub test_var_declinit : Test(1) {
    my $js = self->{js};

    $js->var(a => 1);

    is "$js", 'var a = 1;', "var declaration with initialization";
}

sub test_var_declinittie : Test(1) {
    my $js = self->{js};

    my $a = 1;
    $js->var(a => \$a);
    is "$js", 'var a = 1;', "var declaration with initialization, tie version";
}

sub test_var_assignment : Test(1) {
    my $js = self->{js};

    my $a;
    $js->var(a => \$a);
    $a = 1;

    is "$js", "var a;a = 1;", "variable assignment in perl can be written as javascript.";
}

sub test_var_assignment_after_declinit : Test(1) {
    my $js = self->{js};

    my $a = 1;
    $js->var(a => \$a);
    $a = 42;

    is "$js", "var a = 1;a = 42;", "variable assignment in perl can be written as javascript.";
}

sub test_var_assigned_a_function : Test(1) {
    my $js = self->{js};

    my $a;
    $js->var(a => \$a);
    $a = $js->new->somefunc("/foo/bar");

    is "$js", 'var a;a = somefunc("/foo/bar");';
}

sub test_var_initiallzed_a_funcion : Test(1) {
    my $js = self->{js};
    my $a = $js->new->function(
        sub {
            my $js = shift;
            $js->foobar();
        }
    );
    $js->var(a => \$a);

    is "$js", 'var a = function(){foobar();};', "another way to assign a function to a variable.";
}

sub test_var_operation : Test(1) {
 SKIP: {
        skip "This feels quit difficult... ", 1;

        my $js = JavaScript::Writer->new();
        my $a = 1;
        my $b = 41;
        $js->var(a => \$a);
        $js->var(b => \$b);
        $a = $a + $b;
        is $js, "var a = 1;var b = 41;a = a + b;";
    }
}

1;


