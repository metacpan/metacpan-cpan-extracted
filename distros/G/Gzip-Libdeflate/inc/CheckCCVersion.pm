package CheckCCVersion;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw/check_cc_version/;
use warnings;
use strict;
use utf8;
use Carp;

use Config qw/%Config/;

# The minimum allowed versions of the compilers.
my $clangmin = 3.9;
my $gccmin = 4.9;
# Version regexp matches 1.1.1 etc.
my $vre = qr!((?:[0-9]+\.)+[0-9]+)!;

sub check_cc_version
{
    my $cc = $Config{cc};
    if (! $cc) {
	die "I cannot find a C compiler in your \%Config";
    }
    my $version = `$cc --version`;
    if ($version =~ /clang.*?$vre/) {
	compiler ('clang', $1, $clangmin);
	return;
    }
    if ($version =~ /gcc.*?$vre/) {
	compiler ('gcc', $1, $gccmin);
	return;
    }
    # Need to add tests for MSVC compiler here to check it is 2015 or
    # later, according to Biggers' README page.
    warn "Your compiler, $version, may be incompatible with libdeflate";
}

sub compiler
{
    my ($name, $num, $min) = @_;
    if ($num =~ /([0-9]+\.[0-9]+)\.[0-9]+/) {
	$num = $1;
    }
    if ($num < $min) {
	die "Your C compiler, $name $num, is too old for libdeflate, the minimum requirement is version $min";
    }
}


1;
