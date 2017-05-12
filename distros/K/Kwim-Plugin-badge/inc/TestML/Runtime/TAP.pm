use Test::Builder;
use TestML::Runtime;

package TestML::Runtime::TAP;

use TestML::Base;
extends 'TestML::Runtime';

has tap_object => sub { Test::Builder->new };
has planned => 0;

sub run {
    my ($self) = @_;
    $self->SUPER::run;
    $self->check_plan;
    $self->plan_end;
}

sub run_assertion {
    my ($self, @args) = @_;
    $self->check_plan;
    $self->SUPER::run_assertion(@args);
}

sub check_plan {
    my ($self) = @_;
    if (! $self->planned) {
        $self->title;
        $self->plan_begin;
        $self->{planned} = 1;
    }
}

sub title {
    my ($self) = @_;
    if (my $title = $self->function->getvar('Title')) {
        $title = $title->value;
        $title = "=== $title ===\n";
        $self->tap_object->note($title);
    }
}

sub skip_test {
    my ($self, $reason) = @_;
    $self->tap_object->plan(skip_all => $reason);
}

sub plan_begin {
    my ($self) = @_;
    if (my $tests = $self->function->getvar('Plan')) {
        $self->tap_object->plan(tests => $tests->value);
    }
}

sub plan_end {
    my ($self) = @_;
    $self->tap_object->done_testing();
}

# TODO Use Test::Diff here.
sub assert_EQ {
    my ($self, $got, $want) = @_;
    $got = $got->str->value;
    $want = $want->str->value;
    if ($got ne $want and $want =~ /\n/) {
        my $block = $self->function->getvar('Block');
        my $diff = $self->function->getvar('Diff');
        if ($diff or exists $block->points->{DIFF}) {
            require Text::Diff;
            $self->tap_object->ok(0, $self->get_label);
            my $diff = Text::Diff::diff(
                \$want, \$got, {
                    FILENAME_A => "want",
                    FILENAME_B => "got",
                },
            );
            $self->tap_object->diag($diff);
            return;
        }
    }
    $self->tap_object->is_eq(
        $got,
        $want,
        $self->get_label,
    );
}

sub assert_HAS {
    my ($self, $got, $has) = @_;
    $got = $got->str->value;
    $has = $has->str->value;
    my $assertion = (index($got, $has) >= 0);
    if (not $assertion) {
        my $msg = <<"...";
Failed TestML HAS (~~) assertion. This text:
'$got'
does not contain this string:
'$has'
...
        $self->tap_object->diag($msg);
    }
    $self->tap_object->ok($assertion, $self->get_label);
}

sub assert_OK {
    my ($self, $got) = @_;
    $self->tap_object->ok(
        $got->bool->value,
        $self->get_label,
    );
}

1;
