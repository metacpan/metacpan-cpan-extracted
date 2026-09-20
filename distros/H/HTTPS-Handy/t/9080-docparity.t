######################################################################
# 9080-docparity.t  The documentation must describe this code, and only
#                   this code.
#
# POD and README drift away from the source quietly: a method is
# renamed, a default changes, a cipher suite is replaced, and the
# documentation goes on describing the old one. Every check here reads
# a fact out of lib/HTTPS/Handy.pm and the same fact out of the prose,
# and fails when they disagree.
#
# Checks:
#   V1  every documented method exists in the code
#   V2  every public method in the code is documented
#   V3  the $env keys the code sets are the ones the POD lists
#   V4  the cipher suite names match the ones the code implements
#   V5  the packages the POD lists are the packages the file holds
#   V6  documented defaults (port, cert_dir, certificate lifetime)
#       match the code
#   V7  README version matches $VERSION
#   V8  README names the same cipher suites as the code
#   V9  the line counts in the package table match the file
#   V10 every package in the file is listed in provides, in all three
#       of META.yml, META.json and Makefile.PL
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub';
        eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use lib "$FindBin::Bin/../lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));
my $PM = 'lib/HTTPS/Handy.pm';

plan_skip("$PM not found") unless -f "$ROOT/$PM";

plan_tests(10);

my $text = _slurp("$ROOT/$PM");
my $code = $text;
$code =~ s/\n__END__\b.*\z//s;
my ($pod) = ($text =~ /\n__END__\b(.*)\z/s);
$pod = '' unless defined $pod;

######################################################################
# V1, V2 -- methods
######################################################################

# Public methods: subs in package HTTPS::Handy, before any other
# package begins, whose names do not start with an underscore.
my @public;
{
    my $in_main = 0;
    for my $line (split /\n/, $code) {
        if ($line =~ /^package\s+([\w:]+);/) {
            $in_main = ($1 eq 'HTTPS::Handy') ? 1 : 0;
            next;
        }
        next unless $in_main;
        push @public, $1 if $line =~ /^sub\s+([a-z]\w*)/;
    }
}

# Documented methods: =head2 C<name(...)> or =head2 C<name>
my @documented;
while ($pod =~ /^=head2\s+C<(\w+)\s*\(/mg) { push @documented, $1 }

my %is_public    = map { $_ => 1 } @public;
my %is_documented = map { $_ => 1 } @documented;

my @phantom = grep { !$is_public{$_} } @documented;
ok(!@phantom, 'V1 - every documented method exists in the code'
            . (@phantom ? " (not found: @phantom)" : ''));

my @undocumented = grep { !$is_documented{$_} } @public;
ok(!@undocumented, 'V2 - every public method is documented'
                 . (@undocumented ? " (missing: @undocumented)" : ''));

######################################################################
# V3 -- the PSGI environment
######################################################################

# The keys the code puts into %env, plus the HTTP_ prefix it builds
my @env_keys;
if ($code =~ /my\s+%env\s*=\s*\((.*?)\n    \);/s) {
    my $block = $1;
    while ($block =~ /^\s*'([\w.]+)'\s*=>/mg) { push @env_keys, $1 }
}
push @env_keys, 'HTTP_*' if $code =~ /'HTTP_'\s*\.\s*uc/;

# The keys the POD table lists, between the table header and the
# blank line that ends the verbatim block
my @pod_keys;
if ($pod =~ /Key\s+Description\n\s+-+\s+-+\n(.*?)\n\n/s) {
    my $table = $1;
    for my $line (split /\n/, $table) {
        push @pod_keys, $1 if $line =~ /^\s{2,}([A-Za-z][\w.*]*)\s{2,}\S/;
    }
}

my %in_code = map { $_ => 1 } @env_keys;
my %in_pod  = map { $_ => 1 } @pod_keys;
my @env_missing = grep { !$in_pod{$_}  } @env_keys;
my @env_extra   = grep { !$in_code{$_} } @pod_keys;
ok(!@env_missing && !@env_extra && scalar(@env_keys),
   'V3 - the documented $env keys are the ones the code sets'
   . (@env_missing ? " (undocumented: @env_missing)" : '')
   . (@env_extra   ? " (documented but never set: @env_extra)" : '')
   . (scalar(@env_keys) ? '' : ' (no keys found in the code)'));

######################################################################
# V4 -- cipher suites
######################################################################

my @code_suites;
while ($code =~ /'name'\s*=>\s*'(TLS_\w+)'/g) { push @code_suites, $1 }
my %pod_suites;
while ($pod =~ /\b(TLS_ECDHE_\w+)/g) { $pod_suites{$1} = 1 }

my @suite_missing = grep { !$pod_suites{$_} } @code_suites;
my %code_suite = map { $_ => 1 } @code_suites;
my @suite_extra = grep { !$code_suite{$_} } sort keys %pod_suites;
ok(scalar(@code_suites) && !@suite_missing && !@suite_extra,
   'V4 - the POD names exactly the cipher suites the code implements'
   . (@suite_missing ? " (not in the POD: @suite_missing)" : '')
   . (@suite_extra   ? " (in the POD only: @suite_extra)" : ''));

######################################################################
# V5 -- packages
######################################################################

my @code_packages;
{
    my %seen;
    while ($code =~ /^package\s+([\w:]+);/mg) {
        push @code_packages, $1 unless $seen{$1}++;
    }
}
my @pod_packages;
{
    my %seen;
    if ($pod =~ /Package\s+Lines\s+What it does\n(.*?)\n\n/s) {
        my $table = $1;
        while ($table =~ /^\s+(HTTPS::\S+)/mg) {
            push @pod_packages, $1 unless $seen{$1}++;
        }
    }
}
my %pod_pkg  = map { $_ => 1 } @pod_packages;
my %code_pkg = map { $_ => 1 } @code_packages;
my @pkg_missing = grep { !$pod_pkg{$_}  } @code_packages;
my @pkg_extra   = grep { !$code_pkg{$_} } @pod_packages;
ok(scalar(@pod_packages) && !@pkg_missing && !@pkg_extra,
   'V5 - the POD lists exactly the packages in the file'
   . (@pkg_missing ? " (missing: @pkg_missing)" : '')
   . (@pkg_extra   ? " (listed but absent: @pkg_extra)" : ''));

######################################################################
# V6 -- documented defaults
######################################################################

my @default_bad;
{
    # Default port
    my ($port) = ($code =~ /\$args\{port\}\s*:\s*(\d+)/);
    push @default_bad, 'port' unless defined $port
        && $pod =~ /port\s+=>\s+\Q$port\E,\s+#\s*optional/;
    push @default_bad, 'port in DIFFERENCES' unless defined $port
        && $pod =~ /Default port is \Q$port\E\b/;

    # Default certificate directory
    my ($dir) = ($code =~ /\$args\{cert_dir\}\s*\|\|\s*'([^']+)'/);
    push @default_bad, 'cert_dir' unless defined $dir
        && $pod =~ /F<\Q$dir\E>/;

    # Certificate lifetime
    my ($days) = ($code =~ /\$CERT_DAYS\s*=\s*(\d+)/);
    push @default_bad, 'certificate lifetime' unless defined $days
        && $pod =~ /valid for \Q$days\E days/;

    # Maximum POST size
    my ($mb) = ($code =~ /\$DEFAULT_MAX_POST_SIZE\s*=\s*(\d+)\s*\*\s*1024\s*\*\s*1024/);
    push @default_bad, 'max_post_size' unless defined $mb
        && $pod =~ /default:\s*\Q$mb\E\s*MB\b/i;
}
ok(!@default_bad, 'V6 - documented defaults match the code'
                . (@default_bad ? " (wrong: @default_bad)" : ''));

######################################################################
# V7, V8 -- README
######################################################################

SKIP_README: {
    my $readme = -f "$ROOT/README" ? _slurp("$ROOT/README") : '';
    my ($version) = ($code =~ /^\$VERSION\s*=\s*'([^']+)';/m);
    ok(length($readme) && defined $version
       && $readme =~ /^\s*Version \Q$version\E\s*$/m,
       "V7 - README states version $version");

    my @readme_missing = grep { index($readme, $_) < 0 } @code_suites;
    ok(length($readme) && !@readme_missing,
       'V8 - README names the cipher suites the code implements'
       . (@readme_missing ? " (missing: @readme_missing)" : ''));
}

######################################################################
# V9 -- the line counts in the package table
######################################################################

my %code_lines;
{
    my $pkg = '';
    for my $line (split /\n/, $code) {
        $pkg = $1 if $line =~ /^package\s+([\w:]+);/;
        $code_lines{$pkg}++ if $pkg ne '';
    }
}
my @count_bad;
if ($pod =~ /Package\s+Lines\s+What it does\n(.*?)\n\n/s) {
    my $table = $1;
    for my $line (split /\n/, $table) {
        next unless $line =~ /^\s+(HTTPS::\S+)\s+(\d+)\s/;
        my ($pkg, $claim) = ($1, $2);
        my $real = $code_lines{$pkg};
        push @count_bad, "$pkg says $claim, file has "
                       . (defined $real ? $real : 'none')
            unless defined $real && ($real == $claim);
    }
}
ok(!@count_bad, 'V9 - the package line counts match the file'
              . (@count_bad ? ' (' . join('; ', @count_bad) . ')' : ''));

######################################################################
# V10 -- the provides list
######################################################################
#
# A package that is missing from provides is a package CPAN will not
# index, and one that is listed but absent is an index entry pointing
# at nothing. check_B already compares the versions in provides with
# $VERSION; what it cannot see is whether the list is complete.
######################################################################

my @provides_bad;
{
    my %wanted = map { $_ => 1 } @code_packages;

    my %found;
    if (-f "$ROOT/META.yml") {
        my $yml = _slurp("$ROOT/META.yml");
        if ($yml =~ /^provides:\n(.*?)(?=^\S|\z)/ms) {
            my $block = $1;
            while ($block =~ /^  ([\w:]+):\s*$/mg) { $found{'META.yml'}{$1} = 1 }
        }
    }
    if (-f "$ROOT/META.json") {
        my $json = _slurp("$ROOT/META.json");
        if ($json =~ /"provides"\s*:\s*\{(.*)\}/s) {
            my $block = $1;
            while ($block =~ /"([\w:]+)"\s*:\s*\{/g) { $found{'META.json'}{$1} = 1 }
        }
    }
    if (-f "$ROOT/Makefile.PL") {
        my $mk = _slurp("$ROOT/Makefile.PL");
        if ($mk =~ /provides\}?\s*=>\s*\{(.*?)\n        \},/s) {
            my $block = $1;
            while ($block =~ /q\{([\w:]+)\}\s*=>\s*\{/g) { $found{'Makefile.PL'}{$1} = 1 }
        }
    }

    for my $file (sort keys %found) {
        my @missing = grep { !$found{$file}{$_} } @code_packages;
        my @extra   = grep { !$wanted{$_} } sort keys %{ $found{$file} };
        push @provides_bad, "$file is missing @missing" if @missing;
        push @provides_bad, "$file lists absent @extra" if @extra;
    }
    push @provides_bad, 'no provides list found at all' unless keys %found;
}
ok(!@provides_bad, 'V10 - provides lists every package in the file'
                 . (@provides_bad ? ' (' . join('; ', @provides_bad) . ')' : ''));

END { end_testing() }
