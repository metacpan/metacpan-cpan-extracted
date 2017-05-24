##We are not interested here in testing duktape api for safe_call, else we need to test
##how safe call function scopes work with eval, and errors from perl land
use lib './lib';
use strict;
use warnings;
use JavaScript::Duktape;
use Data::Dumper;
use Test::More;

my $js  = JavaScript::Duktape->new();
my $duk = $js->duk;

sub safe_fn {
    my $arg = shift;

    eval { };
    eval { die "$arg This is Some Fake Error"; };
    ok( $@ =~ /^Hi This is Some Fake Error/ );

    my $top = $duk->get_top;
    is( $top, 3 );
    ok "must be called";

    ###Editing above this line should change tests
    ###about error line number below
    die "From Perl";
    ##############################################
    fail "should never reach here after we died";
}

$duk->push_function( \&safe_fn, 3 );
$duk->push_string("Hi");
$duk->pcall(1);

my $top = $duk->get_top;
is( $top, 1 );

##error thrown from perl, must be an error object
my $errcode = $duk->get_error_code(0);
is( $errcode, 1 );

my $errorstr = $duk->to_string(0);
ok( $errorstr =~ /Error: From Perl at (.*?)safe-call\.t line 26\./, $errorstr );

$duk->reset_top();

{
    ##same test above but instead throwing from javascript
    sub safe_fn_2 {
        my $self = shift;

        eval { };
        eval { die "Hi This is Some Fake Error"; };
        ok( $@ =~ /^Hi This is Some Fake Error/ );

        my $top = $duk->get_top;
        is( $top, 3 );
        ok "must be called";

        eval { $duk->push_string("error from javascript"); };

        $duk->throw();

        die;

        fail "should never reach here after we died";
    }

    $duk->push_function( \&safe_fn_2, 3 );
    $duk->push_string("Hi");
    eval { $duk->pcall(1) };

    my $top = $duk->get_top;
    is( $top, 1 );

    ##error thrown but it wasn't an instance of Error
    my $errcode = $duk->get_error_code(0);
    is( $errcode, 0 );

    my $errorstr = $duk->to_string(0);
    ok( $errorstr =~ /error from javascript/, $errorstr );
}

done_testing(12);
