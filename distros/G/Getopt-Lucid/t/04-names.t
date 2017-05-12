use strict;
use Test::More;
use Data::Dumper;
use Exception::Class::TryCatch;

use Getopt::Lucid ':all';
use Getopt::Lucid::Exception;

# Work around win32 console buffering that can show diags out of order
Test::More->builder->failure_output(*STDOUT) if $ENV{HARNESS_VERBOSE};

sub why {
    my %vars = @_;
    $Data::Dumper::Sortkeys = 1;
    return "\n" . Data::Dumper->Dump([values %vars],[keys %vars]) . "\n";
}

#--------------------------------------------------------------------------#
# Test cases
#--------------------------------------------------------------------------#

my $spec = [
    Switch("--ver-bose"),
    Switch("--test"),
    Switch("-r"),
];

plan tests => 2;

my $gl;
try eval { $gl = Getopt::Lucid->new($spec) };
catch my $err;
is( $err, undef, "spec should validate" );
SKIP: {
    skip( "because spec did not validate", 1) if $err;
    my @expect = sort qw(ver-bose test r);
    my @got = sort $gl->names();
    is_deeply( \@got, \@expect, "names() produces keywords") or
        diag why( got => \@got, expected => \@expect );
}


