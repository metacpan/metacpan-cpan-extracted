#!/usr/bin/env perl
#
# Benchmark: Medusa (pure Perl) vs Medusa::XS
#
# Run from the bench/ directory:
#   perl compare.pl
#
use strict;
use warnings;
use Benchmark qw(cmpthese timethese :hireswallclock);
use File::Temp qw(tempfile tempdir);

# ── library paths ────────────────────────────────────────────
use FindBin qw($Bin);
use lib "$Bin/../blib/lib", "$Bin/../blib/arch",   # Medusa::XS
        "$Bin/../../Medusa/blib/lib",               # Medusa (pure Perl)
        "$Bin/../../Medusa/lib";

# ── temp log files (thrown away after benchmark) ─────────────
my $dir    = tempdir(CLEANUP => 1);
my $log_pp = "$dir/medusa_pp.log";
my $log_xs = "$dir/medusa_xs.log";

# ── Load both modules into separate packages ────────────────
#
# We configure each to write to its own temp file so the
# benchmark includes real I/O, matching production behaviour.

########################################
# Pure-Perl Medusa setup
########################################
{
    package PP::Setup;
    require Medusa;
    $Medusa::LOG{LOG_FILE} = $log_pp;
    $Medusa::LOG{LOG}      = $Medusa::LOG{LOG_INIT}->();
}

########################################
# XS Medusa setup
########################################
{
    package XS::Setup;
    require Medusa::XS;
    $Medusa::XS::LOG{LOG_FILE} = $log_xs;
    $Medusa::XS::LOG{LOG}      = undef;  # XS does lazy init
}

# ── Define audited subs in separate packages ─────────────────

{
    package PP::Bench;
    use Medusa;

    sub add :Audit {
        return $_[0] + $_[1];
    }

    sub greet :Audit {
        my ($self, %args) = @_;
        return "Hello, $args{name}!";
    }

    sub multi_return :Audit {
        return (1, 2, 3, 4, 5);
    }

    sub complex_args :Audit {
        my ($self, $data) = @_;
        return $data;
    }
}

{
    package XS::Bench;
    use Medusa::XS;

    sub add :Audit {
        return $_[0] + $_[1];
    }

    sub greet :Audit {
        my ($self, %args) = @_;
        return "Hello, $args{name}!";
    }

    sub multi_return :Audit {
        return (1, 2, 3, 4, 5);
    }

    sub complex_args :Audit {
        my ($self, $data) = @_;
        return $data;
    }
}

# ── Unaudited baseline ───────────────────────────────────────
{
    package Bare;
    sub add { return $_[0] + $_[1] }
}

# ── Warm up (trigger lazy logger init) ───────────────────────
PP::Bench::add(1, 2);
XS::Bench::add(1, 2);

# ══════════════════════════════════════════════════════════════
print "=" x 64, "\n";
print "  Medusa (pure Perl) vs Medusa::XS  —  Full Audit Benchmark\n";
print "=" x 64, "\n\n";

# ── 1. Simple numeric call ───────────────────────────────────
print "1. Simple add(1, 2)  — minimal args, scalar return\n";
print "-" x 50, "\n";
cmpthese(-3, {
    'bare (no audit)' => sub { Bare::add(1, 2) },
    'Medusa (PP)'     => sub { PP::Bench::add(1, 2) },
    'Medusa::XS'      => sub { XS::Bench::add(1, 2) },
});
print "\n";

# ── 2. Named arguments ──────────────────────────────────────
print "2. greet(name => 'World')  — hash args, string return\n";
print "-" x 50, "\n";
cmpthese(-3, {
    'Medusa (PP)' => sub { PP::Bench::greet(undef, name => 'World') },
    'Medusa::XS'  => sub { XS::Bench::greet(undef, name => 'World') },
});
print "\n";

# ── 3. Multiple return values ───────────────────────────────
print "3. multi_return()  — 5-element list return\n";
print "-" x 50, "\n";
cmpthese(-3, {
    'Medusa (PP)' => sub { my @r = PP::Bench::multi_return() },
    'Medusa::XS'  => sub { my @r = XS::Bench::multi_return() },
});
print "\n";

# ── 4. Complex nested data ──────────────────────────────────
my $complex = {
    users => [
        { id => 1, name => 'Alice', roles => ['admin', 'user'] },
        { id => 2, name => 'Bob',   roles => ['user'] },
    ],
    meta => { page => 1, total => 42 },
};

print "4. complex_args(nested hashref)  — deep structure serialisation\n";
print "-" x 50, "\n";
cmpthese(-3, {
    'Medusa (PP)' => sub { PP::Bench::complex_args(undef, $complex) },
    'Medusa::XS'  => sub { XS::Bench::complex_args(undef, $complex) },
});
print "\n";

# ── 5. Component micro-benchmarks ───────────────────────────
print "5. Component benchmarks (10k iterations each)\n";
print "-" x 50, "\n";

# GUID
print "\n  a) GUID generation\n";
{
    require Data::GUID;
    cmpthese(-3, {
        'Data::GUID'          => sub { Data::GUID->new->as_string },
        'XS::generate_guid'   => sub { Medusa::XS::generate_guid() },
    });
}

# Caller stack (4 levels deep)
sub _wrap3 { $_[0]->() }
sub _wrap2 { _wrap3($_[0]) }
sub _wrap1 { _wrap2($_[0]) }

print "\n  b) Caller stack collection (4 levels)\n";
{
    my $perl_caller = sub {
        my ($n, $stack) = (0, "");
        while (my @l = (caller($n))) {
            $stack .= "->" if $stack;
            $stack = sprintf "%s%s:%s", $stack, $l[0], $l[2];
            $n++;
        }
        $stack;
    };

    cmpthese(-3, {
        'Perl caller() loop'  => sub { _wrap1($perl_caller) },
        'XS::caller_stack'    => sub { _wrap1(sub { Medusa::XS::collect_caller_stack() }) },
    });
}

# Timestamp
print "\n  c) Timestamp formatting\n";
{
    require POSIX;
    cmpthese(-3, {
        'Perl gmtime+strftime' => sub { POSIX::strftime('%a %b %e %H:%M:%S %Y', gmtime) },
        'XS::format_time'      => sub { Medusa::XS::format_time(1) },
    });
}

# Serialisation
print "\n  d) Argument serialisation (nested hash)\n";
{
    require Data::Dumper;
    my $perl_dump_clean = sub {
        my $data = Data::Dumper::Dumper($complex);
        $data =~ s/\$VAR1\s=\s//;
        $data =~ s/(\s+)(['"][^"]+['"])*/defined $2 ? $2 : ""/gem;
        $data =~ s/;$//;
        $data;
    };

    cmpthese(-3, {
        'Dumper+regex'  => sub { $perl_dump_clean->() },
        'XS::dump_sv'   => sub { Medusa::XS::dump_sv($complex) },
    });
}

# ── Summary ──────────────────────────────────────────────────
print "\n", "=" x 64, "\n";
print "  Benchmark complete.\n\n";
print "  Medusa::XS accelerates every stage of the audit pipeline:\n";
print "    GUID          — C arc4random / /dev/urandom vs Data::GUID\n";
print "    Caller stack  — cx_stack walk vs caller() loop\n";
print "    Timestamp     — inline strftime vs Perl gmtime+strftime\n";
print "    Serialisation — pure C dump_sv vs Data::Dumper+regex\n";
print "    Log dispatch  — cached CV / direct C write vs call_method\n";
print "    Formatting    — sv_catpvn composition vs sprintf chain\n";
print "=" x 64, "\n";
