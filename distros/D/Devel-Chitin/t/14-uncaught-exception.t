#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';
use lib 'lib';
use lib 't/lib';
use Devel::Chitin::TestRunner;
run_in_debugger();

Devel::Chitin::TestDB->attach();

eval { die "trapped" };
do_die();
sub do_die {
    die "untrapped"; # 15
}
exit;

package Devel::Chitin::TestDB;
use base 'Devel::Chitin';

sub notify_uncaught_exception {
    my($db, $exception) = @_;

    require Test::Builder;
    my $tb = Test::Builder->new();
    $tb->plan( tests => 7 );

    my %expected_location = (
        package => 'main',
        line    => 14,
        filename => __FILE__,
        subroutine => 'main::do_die'
    );

    $tb->is_eq(ref($exception), 'Devel::Chitin::Exception', 'exception is-a Devel::Chitin::Exception');
    foreach my $k ( keys %expected_location ) {
        $tb->is_eq($exception->$k, $expected_location{$k}, "exception location $k");
    }
    $tb->like($exception->exception, qr(untrapped), 'exception property');
    if (Devel::Chitin::TestRunner::has_callsite) {
        $tb->ok($exception->callsite, 'callsite has a value');
    } else {
       eval { $tb->ok(!defined($exception->callsite), 'unsupported callsite is undef'); };
    }

    $? = 0;
}

