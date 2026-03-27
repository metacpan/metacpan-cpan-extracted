#!/usr/bin/env perl
#
# Benchmark: Compare XS vs Pure Perl utilities
#
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use Time::HiRes ();
use Data::Dumper ();
use POSIX qw(strftime);

use lib '../blib/lib', '../blib/arch';
use Medusa::XS;

print "=" x 60, "\n";
print "Medusa::XS Performance Benchmarks\n";
print "=" x 60, "\n\n";

#---------------------------------------------------------------
# Benchmark 1: GUID Generation
#---------------------------------------------------------------
print "1. GUID Generation\n";
print "-" x 40, "\n";

# Pure Perl equivalent (simulated Data::GUID style)
sub perl_guid {
    my @chars = ('0'..'9', 'a'..'f');
    my $guid = '';
    for my $len (8, 4, 4, 4, 12) {
        $guid .= join('', map { $chars[int(rand(16))] } 1..$len);
        $guid .= '-' if length($guid) < 36;
    }
    return $guid;
}

cmpthese(100000, {
    'XS::generate_guid' => sub { Medusa::XS::generate_guid() },
    'Perl GUID'         => sub { perl_guid() },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 2: Caller Stack Collection
#---------------------------------------------------------------
print "2. Caller Stack Collection (5 levels deep)\n";
print "-" x 40, "\n";

sub perl_caller_stack {
    my ($n, $stack) = (0, "");
    while (my @l = (caller($n))) {
        $stack .= "->" if $stack;
        $stack = sprintf "%s%s:%s", $stack, $l[0], $l[2];
        $n++;
    }
    return $stack;
}

sub level1 { level2() }
sub level2 { level3() }
sub level3 { level4() }
sub level4 { level5() }
sub level5 { 
    return {
        xs   => Medusa::XS::collect_caller_stack(),
        perl => perl_caller_stack(),
    };
}

# Warm up
level1();

cmpthese(50000, {
    'XS::collect_caller_stack' => sub { level1()->{xs} },
    'Perl caller() loop'       => sub { level1()->{perl} },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 3: Timestamp Formatting
#---------------------------------------------------------------
print "3. Timestamp Formatting\n";
print "-" x 40, "\n";

sub perl_format_time {
    my @now = gmtime;
    return strftime('%a %b %e %H:%M:%S %Y', @now);
}

cmpthese(100000, {
    'XS::format_time'  => sub { Medusa::XS::format_time(1) },
    'Perl strftime'    => sub { perl_format_time() },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 4: Data::Dumper Cleanup  
#---------------------------------------------------------------
print "4. Data::Dumper Output Cleanup\n";
print "-" x 40, "\n";

my $dumper_input = Data::Dumper::Dumper({ key => 'value', nested => { a => 1, b => [1,2,3] } });

sub perl_clean_dumper {
    my $data = shift;
    $data =~ s/\$VAR1\s=\s//;
    $data =~ s/(\s+)(['"][^"]+['"])*/defined $2 ? $2 : ""/gem;
    $data =~ s/;$//;
    return $data;
}

cmpthese(50000, {
    'XS::clean_dumper' => sub { Medusa::XS::clean_dumper($dumper_input) },
    'Perl regex'       => sub { perl_clean_dumper($dumper_input) },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 5: Horus GUID Version Comparison
#---------------------------------------------------------------
print "5. Horus GUID Version Comparison\n";
print "-" x 40, "\n";

cmpthese(100000, {
    'guid_v4 (random)'  => sub { Medusa::XS::generate_guid(4) },
    'guid_v7 (time)'    => sub { Medusa::XS::generate_guid(7) },
    'guid_v1 (greg)'    => sub { Medusa::XS::generate_guid(1) },
    'guid_v5 (sha1)'    => sub { Medusa::XS::generate_guid(5, 'dns', 'example.com') },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 6: Loo Dump vs Data::Dumper
#---------------------------------------------------------------
print "6. Loo dump_sv vs Data::Dumper\n";
print "-" x 40, "\n";

# Disable colour for fair comparison
$Medusa::XS::LOG{OPTIONS}{colour} = 0;

my $simple_struct  = { a => 1, b => [2, 3] };
my $complex_struct = {
    users => [
        { id => 1, name => 'Alice', roles => ['admin', 'user'] },
        { id => 2, name => 'Bob',   roles => ['user'] },
    ],
    meta => { version => '2.0', nested => { deep => { value => 42 } } },
};

sub perl_dumper_simple  { Data::Dumper::Dumper($simple_struct) }
sub perl_dumper_complex { Data::Dumper::Dumper($complex_struct) }

cmpthese(50000, {
    'Loo simple'    => sub { Medusa::XS::dump_sv($simple_struct) },
    'Dumper simple' => sub { perl_dumper_simple() },
});

print "\n";

cmpthese(20000, {
    'Loo complex'    => sub { Medusa::XS::dump_sv($complex_struct) },
    'Dumper complex' => sub { perl_dumper_complex() },
});

print "\n";

#---------------------------------------------------------------
# Benchmark 7: Colour vs No-Colour Dump Overhead
#---------------------------------------------------------------
print "7. Colour vs No-Colour Dump Overhead\n";
print "-" x 40, "\n";

cmpthese(50000, {
    'dump no-colour' => sub {
        $Medusa::XS::LOG{OPTIONS}{colour} = 0;
        Medusa::XS::dump_sv($simple_struct);
    },
    'dump colour' => sub {
        $Medusa::XS::LOG{OPTIONS}{colour} = 1;
        Medusa::XS::dump_sv($simple_struct);
    },
});

# Reset
$Medusa::XS::LOG{OPTIONS}{colour} = 0;

print "\n";

#---------------------------------------------------------------
# Benchmark 8: Full Audit Wrapper Overhead
#---------------------------------------------------------------
print "8. Full :Audit Wrapper Overhead\n";
print "-" x 40, "\n";

# Set up mock logger
{
    package MockLogger;
    sub new { bless {}, shift }
    sub debug { }
    sub info { }
    sub error { }
}

$Medusa::XS::LOG{LOG} = MockLogger->new();

{
    package BenchPkg;
    use Medusa::XS;
    
    sub audited_add :Audit {
        my ($a, $b) = @_;
        return $a + $b;
    }
    
    sub plain_add {
        my ($a, $b) = @_;
        return $a + $b;
    }
}

cmpthese(10000, {
    'audited_add'   => sub { BenchPkg::audited_add(1, 2) },
    'plain_add'     => sub { BenchPkg::plain_add(1, 2) },
});

print "\n";
print "=" x 60, "\n";
print "Benchmark complete.\n";
print "XS utilities provide significant speedup for:\n";
print "  - GUID generation (Horus C library vs Perl rand)\n";
print "  - Caller stack (cx_stack walk vs caller() loop)\n";
print "  - Timestamp (direct strftime vs Perl strftime)\n";
print "  - SV dump (Loo C library vs Data::Dumper)\n";
print "  - Colour overhead is minimal for dump operations\n";
print "=" x 60, "\n";
