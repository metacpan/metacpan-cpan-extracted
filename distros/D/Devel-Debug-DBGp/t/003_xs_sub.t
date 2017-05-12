#!/usr/bin/perl

use DB::DbgrXS;
use if $ENV{DBGP_PURE_PERL},  'Test::More' => 'skip_all' => 'Skipping XS-specific test in pure-Perl mode';
use if !DB::DbgrXS::HAS_XS(), 'Test::More' => 'skip_all' => 'XS version not compiled';
use t::lib::Test;

{
    package DB;

    our ($ldebug, $stack_depth) = (0, 0);
    my ($deep) = (0);
    my (%FQFnNameLookupTable, @stack);

    sub setup_lexicals {
        DB::XS::setup_lexicals(\$ldebug, \@stack, \$deep, \%FQFnNameLookupTable);
    }
}

$^P = 0x400; # so the debugger is initialized
my ($context);
my ($unused, @unused);
my ($result, @result);

use XSLoader;

XSLoader::load('dbgp-helper::perl5db');

call('can_call'); # sanity check

call('context');
is($context, undef);

$unused = call('context');
is($context, '');

@unused = call('context');
is($context, 1);

call('add', 1, 2);
is($result, 3);

call('add_mutated', 1, 2, 3);
is($result, 5);

$result = call('ret_scalar');
is($result, 42);

done_testing();

sub call {
    package DB;

    our $sub;
    local $sub = 'main::' . shift;

    &DB::XS::sub_xs;
}

sub can_call {
}

sub context {
    $context = wantarray;
}

sub add {
    $result = $_[0] + $_[1];
}

sub mutate {
    shift;
}

sub add_mutated {
    local $DB::sub = 'main::mutate';
    &DB::XS::sub_xs;
    $result = $_[0] + $_[1];
}

sub ret_scalar {
    return 42;
}

sub ret_array {
    my @dummy = (42, 43);
    return @dummy;
}

sub ret_list {
    return (42, 43);
}

sub ret_void {
    return;
}
