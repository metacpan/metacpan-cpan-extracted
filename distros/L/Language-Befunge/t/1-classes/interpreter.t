#!perl
#
# This file is part of Language-Befunge
#
# This software is copyright (c) 2003 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#

#
# Language::Befunge::Interpreter tests
#

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 46;
use Language::Befunge::Interpreter;


#-- new()
# defaults
my $interp = Language::Befunge::Interpreter->new();
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 2, "default number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::2D::Sparse', "storage object");
is($interp->get_storage->get_dims, 2, "storage has same number of dimensions");

# templates
$interp = Language::Befunge::Interpreter->new({ syntax => 'befunge98' });
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 2, "default number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::2D::Sparse', "storage object");
is($interp->get_storage->get_dims, 2, "storage has same number of dimensions");

$interp = Language::Befunge::Interpreter->new({ syntax => 'unefunge98' });
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 1, "correct number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::Generic::AoA', "storage object");
is($interp->get_storage->get_dims, 1, "storage has same number of dimensions");

$interp = Language::Befunge::Interpreter->new({ syntax => 'trefunge98' });
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 3, "correct number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::Generic::AoA', "storage object");
is($interp->get_storage->get_dims, 3, "storage has same number of dimensions");

# by dims
$interp = Language::Befunge::Interpreter->new({ dims => 5 });
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 5, "correct number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::Generic::AoA', "storage object");
is($interp->get_storage->get_dims, 5, "storage has same number of dimensions");

# special storage requirement
$interp = Language::Befunge::Interpreter->new({
    storage => 'Language::Befunge::Storage::Generic::Vec'
});
isa_ok($interp, "Language::Befunge::Interpreter");
is($interp->get_dimensions, 2, "correct number of dimensions");
is(scalar @{$interp->get_ips()}, 0, "starts out with no IPs");
isa_ok($interp->get_storage, 'Language::Befunge::Storage::Generic::Vec', "storage object");
is($interp->get_storage->get_dims, 2, "storage has same number of dimensions");

# syntax combinations like "4funge98" are supported
$interp = Language::Befunge::Interpreter->new({
    syntax  => '4funge98',
    storage => 'Language::Befunge::Storage::Generic::Vec' });
is(ref($interp->get_storage), 'Language::Befunge::Storage::Generic::Vec', 'storage specified');
is($$interp{dimensions}, 4, 'dims inferred from syntax name');
ok(exists($$interp{ops}{m}), 'GenericFunge98 ops used');
$interp = Language::Befunge::Interpreter->new({
    syntax   => '4funge98',
    wrapping => 'Language::Befunge::Wrapping::LaheySpace' });
is(ref($interp->get_wrapping), 'Language::Befunge::Wrapping::LaheySpace', 'wrapping specified');
is(ref($interp->get_storage), 'Language::Befunge::Storage::Generic::AoA', 'default storage');
$interp = Language::Befunge::Interpreter->new({
    syntax => '4funge98',
    ops    => 'Language::Befunge::Ops::Unefunge98' });
ok(!exists($$interp{ops}{m}), 'ops specified');
$interp = Language::Befunge::Interpreter->new({
    syntax => '4funge98',
    dims   => 5 });
is($$interp{dimensions}, 5, 'dims specified');

# accessor methods not tested anywhere else
$interp->set_handprint('TEST');
is($interp->get_handprint(), 'TEST', 'set_handprint');
$interp->set_dimensions(6);
is($interp->get_dimensions(), 6, 'set_dimensions');
$interp->set_ops(Language::Befunge::Ops::GenericFunge98->get_ops_map);
ok(exists($$interp{ops}{m}), 'set_ops');

# unrecognized arguments are rejected
throws_ok(sub { Language::Befunge::Interpreter->new({ syntax => 'crashme' }) },
    qr/not recognized/, "unknown 'syntax' arguments are rejected");

# nonsensical combinations are rejected
throws_ok(sub { Language::Befunge::Interpreter->new({ dims => 3, syntax => 'befunge98' }) },
    qr/only useful for 2-dimensional/, "LBS2S rejects non-2D");
throws_ok(sub { Language::Befunge::Interpreter->new({ storage => 'Nonexistent::Module' }) },
    qr/via package "Nonexistent::Module"/, "unfound Storage module");
throws_ok(sub { Language::Befunge::Interpreter->new({ ops => 'Nonexistent::Module' }) },
    qr/via package "Nonexistent::Module"/, "unfound Ops module");
throws_ok(sub { Language::Befunge::Interpreter->new({ wrapping => 'Nonexistent::Module' }) },
    qr/via package "Nonexistent::Module"/, "unfound Wrapping module");
throws_ok(sub { Language::Befunge::Interpreter->new({ dims => 'abc' }) },
    qr/must be numeric/, "non-numeric dimensions");

