#!/usr/bin/perl

use strict;
use warnings;
use vars qw($TEMPLATE $instance @all_env);

use Test::More;

@all_env = sort grep(/^[A-Za-z_]\w*$/, keys %ENV);

plan tests => scalar @all_env + 4;

$TEMPLATE = <<'END_TEMPLATE';
use Env::Export qw(PATTERN);

PATTERN;
END_TEMPLATE

for my $test (@all_env)
{
    ($instance = $TEMPLATE) =~ s/PATTERN/$test/g;

    is(eval $instance, $ENV{$test}, "Import of $test");
}

# Test that nothing is imported by "use Env::Export" without args
require File::Spec;
(my $vol, my $dir, undef) = File::Spec->splitpath(File::Spec->rel2abs($0));
require File::Spec->catpath($vol, $dir, 'sub_count.pl');

my $code = <<ENDCODE;
package namespace0;
use Env::Export;
1;
ENDCODE
eval $code;
SKIP: {
    skip "Eval failed ($@), cannot test namespace0", 1 if $@;

    is(sub_count('namespace0'), 0, 'Env::Export exported nothing');
}

$code = <<ENDCODE;
package namespace1;
use Env::Export ();
1;
ENDCODE
eval $code;
SKIP: {
    skip "Eval failed ($@), cannot test namespace1", 1 if $@;

    is(sub_count('namespace1'), 0, 'Env::Export () exported nothing');
}

# Test that a bad pattern/string given in the use statement generates the
# correct warning:
my $err = q{};
$SIG{__WARN__} = sub { $err = shift };
$code = <<ENDCODE;
package namespace2;
use Env::Export q/::/;
1;
ENDCODE
eval $code;
SKIP: {
    skip "Eval failed ($@), cannot test namespace1", 1 if $@;

    like($err, qr/Unrecognized pattern or keyword '::'/,
         'Proper warning message issued');
    is(sub_count('namespace2'), 0, 'Env::Export () exported nothing');
}

exit;
