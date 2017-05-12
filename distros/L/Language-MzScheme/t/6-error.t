use strict;
use Test::More tests => 7;

use_ok('Language::MzScheme');

my $env = Language::MzScheme->new;

my $obj = eval { $env->eval('this is an error') };
isa_ok($obj, 'Language::MzScheme::Object', 'return value from eval {}');
is($obj->as_perl_data, undef, 'return value from {} is undefined');

$SIG{__DIE__} = sub { show_ok(@_); goto &next };
$env->eval('(not well formed');

sub next {
    $SIG{__DIE__} = sub { show_ok(@_); goto &last };
    $env->eval('(perl-eval "die q(died from perl)")');
}

sub last {
    $SIG{__WARN__} = sub { return };
    my $obj = eval { $env->eval('this is an error') };
    isa_ok($obj, 'Language::MzScheme::Object', 'return value from eval {}');
    is($obj->as_perl_data, undef, 'return value from {} is undefined');
    exit;
}

sub show_ok {
    my $err = shift; chomp $err;
    ok($err, "error captured with \$SIG{__DIE__}: [$err]");
}
