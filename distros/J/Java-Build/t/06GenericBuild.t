use strict;
use warnings;

use Test::More tests => 13;

BEGIN { use_ok('Java::Build::GenericBuild') }

my $builder = MyBuild->new();
is($builder->{MISSING}, 12, "process one attr");

my $targets = [ qw(init purge checkout compile make_jars) ];
$builder->targets($targets);
is_deeply($targets, $builder->{TARGETS}, "targets set");

eval q{
    $builder->GO();
};
like($@, qr/supply a BUILD_SUCCESS/, 'no success file');

open SUCCESS, '>t/generic.success' or die "couldn't write success file\n";
print SUCCESS "last_successful_target=";
$builder->{BUILD_SUCCESS} = 't/generic.success';

eval q{
    $builder->GO();
};
like($@, qr/Can.t locate.*init/, 'missing sub');

$targets = [ qw(step1 step2 step3 step4 step5) ];
$builder->targets($targets);
$builder->GO();
is($builder->{STEPS}, 'step1step2step3step4step5', 'full build');

$builder->{STEPS} = "";
$builder->GO("step3");
is($builder->{STEPS}, 'step1step3', 'redo step3');

$builder->{STEPS} = "";
$builder->GO(qw( step2 step3 ));
is($builder->{STEPS}, 'step1step2step3', 'redo steps 2 and 3');

$builder->{STEPS} = "";
$builder->GO("step5");
is($builder->{STEPS}, 'step1step4step5', 'redo from step3 to step5');

unlink 't/generic.success';
open SUCCESS, '>t/generic.success' or die "couldn't write success file\n";
print SUCCESS "last_successful_target=";

$builder->{STEPS} = "";
$builder->GO("step3");
is($builder->{STEPS}, 'step1step2step3', 'scratch to step3');

$builder->{STEPS} = "";
$builder->GO( qw(step1 step4) );
is($builder->{STEPS}, 'step1step2step3step4', 'explicit step1 thru step4');

$builder->targets([qw( one two three four five ) ]);

eval {
    $builder->GO("blah");
};
like($@, qr/Please choose from\n'one'/, "bad target error");

unlink 't/generic.success';

# The following test makes sure that the success file can be absent when GO is
# called.  It is a bit funny because of its indirection.  When the bug
# was found, GO would die complaining that it could not read the success
# file.  With this test it should die when it tries to perform the target
# called 'one' since there is no method by that name.
$builder->{BUILD_SUCCESS} = 't/generic.success';
eval {
    $builder->GO("three");
};
like($@, qr/Can.t locate object method/, "wrote missing build success");

package MyBuild;
use base 'Java::Build::GenericBuild';

sub new {
    my $class = shift;
    my $self  = {
        ATTRIBUTES => [
            { MISSING => sub { my $s = shift; $s->{MISSING} = 12; } },
        ],
    };
    Java::Build::GenericBuild::process_attrs($self);
    bless $self, $class;
}

sub step1 { $_[0]->{STEPS}  = "step1"; }
sub step2 { $_[0]->{STEPS} .= "step2"; }
sub step3 { $_[0]->{STEPS} .= "step3"; }
sub step4 { $_[0]->{STEPS} .= "step4"; }
sub step5 { $_[0]->{STEPS} .= "step5"; }

