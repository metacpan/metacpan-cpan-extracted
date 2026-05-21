#!/usr/bin/env perl

use v5.8;
use warnings;
use utf8;

use Test2::V0;

our $buf;
open *TESTOUT, '>', \$buf or die "Cannot open capture buffer: $!";

sub reset_capture {
    close *TESTOUT;
    $buf = '';
    open *TESTOUT, '>', \$buf or die "Cannot reopen capture buffer: $!";
}

require Devel::Bug;

sub bug :lvalue;

# Storing a ref through the tie delays DESTROY to global cleanup, so these
# tests use val => $ref with a plain scalar assigned.  DESTROY fires promptly,
# and pp is still called on the ref passed as val.

my $href = {a => 1};

# ---------------------------------------------------------------------------
# default pp (Data::Dumper::Dumper)
# ---------------------------------------------------------------------------

{
    Devel::Bug->import(out => *TESTOUT, color => undef);
    reset_capture();
    my $in;
    ($in = bug('ref', val => $href) = 42);
    like $buf, qr/\$VAR1/, 'default pp produces Data::Dumper-style output';
    like $buf, qr/a/,      'ref value appears in output with default pp';
}

# Non-ref scalars bypass pp entirely regardless of pp setting.
{
    Devel::Bug->import(out => *TESTOUT, color => undef);
    reset_capture();
    my $in;
    ($in = bug('num') = 42);
    unlike $buf, qr/\$VAR1/, 'pp not called for non-ref scalar';
    like   $buf, qr/42/,     'scalar value appears in output';
}

subtest 'Data::Dump pp' => sub {
    plan skip_all => 'Data::Dump not installed' unless eval { require Data::Dump; 1 };

    # pp => 'Data::Dump::pp' at import time
    {
        Devel::Bug->import(out => *TESTOUT, color => undef, pp => 'Data::Dump::pp');
        reset_capture();
        my $in;
        ($in = bug('ref', val => $href) = 42);
        unlike $buf, qr/\$VAR1/, 'Data::Dump::pp used when pp set at import';
        like   $buf, qr/a/,      'ref value appears in output with Data::Dump::pp';
    }

    # Non-ref scalars still bypass pp even when a custom pp is set.
    {
        Devel::Bug->import(out => *TESTOUT, color => undef, pp => 'Data::Dump::pp');
        reset_capture();
        my $in;
        ($in = bug('num') = 42);
        unlike $buf, qr/\$VAR1/, 'pp not called for non-ref scalar with custom pp set';
        like   $buf, qr/42/,     'scalar value still appears in output';
    }

    # pp => 'Data::Dump::pp' as a per-call override
    {
        Devel::Bug->import(out => *TESTOUT, color => undef);
        reset_capture();
        my $in;
        ($in = bug('ref', val => $href, pp => 'Data::Dump::pp') = 42);
        unlike $buf, qr/\$VAR1/, 'Data::Dump::pp used when pp set per-call';
    }

    # Per-call pp does not affect other calls (import default still applies).
    {
        Devel::Bug->import(out => *TESTOUT, color => undef);

        reset_capture();
        my $in;
        ($in = bug('ref', val => $href, pp => 'Data::Dump::pp') = 42);
        unlike $buf, qr/\$VAR1/, 'per-call pp uses Data::Dump::pp';

        reset_capture();
        ($in = bug('ref', val => $href) = 42);
        like $buf, qr/\$VAR1/, 'subsequent call reverts to default pp';
    }
};

# ---------------------------------------------------------------------------
# error cases — invalid pp warns and falls back to Data::Dump::pp
# ---------------------------------------------------------------------------

# Format with no '::' separator warns.
{
    Devel::Bug->import(out => *TESTOUT, color => undef);
    reset_capture();
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    my $in;
    ($in = bug('x', pp => 'nocolons') = 42);
    like $warned, qr/Invalid pretty-printer/, 'pp with no module qualifier warns';
    like $buf,    qr/42/,                     'output still produced after invalid pp';
}

# Nonexistent module warns.
{
    Devel::Bug->import(out => *TESTOUT, color => undef);
    reset_capture();
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    my $in;
    ($in = bug('x', pp => 'NoSuch::Module::func') = 42);
    like $warned, qr/Can't locate/, 'nonexistent module warns';
    like $buf,    qr/42/,                'output still produced after missing module';
}

# Module exists but named sub does not.
{
    Devel::Bug->import(out => *TESTOUT, color => undef);
    reset_capture();
    my $warned = '';
    local $SIG{__WARN__} = sub { $warned .= $_[0] };
    my $in;
    ($in = bug('x', pp => 'POSIX::nonexistent_func') = 42);
    like $warned, qr/Invalid pretty-printer/, 'missing sub in valid module warns';
    like $buf,    qr/42/,              'output still produced after missing sub';
}

done_testing;
