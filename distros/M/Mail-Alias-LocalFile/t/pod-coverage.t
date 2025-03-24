#!perl -T
use 5.012;
use strict;
use warnings;
use Test::More;
use Symbol qw(qualify_to_ref);

# Test::Pod::Coverage
# Pod::Coverage
#     most end users dont need these tests 
#     but contributers should ensure POD coverage is complete

# Plan tests
plan tests => 2;  # require_ok + pod_coverage_ok

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

# Make sure the module can be loaded
require_ok('Mail::Alias::LocalFile') or BAIL_OUT("Cannot load module!");

# Get all symbols from the module's namespace
my $private_regex = qr/^[A-Z_]+$/;
my $trustme_regex = qr/^(BUILD|DEMOLISH|BUILDARGS|DOES)$/;

diag("\nExamining methods in Mail::Alias::LocalFile:");
diag("-------------------------------------------");

# Get a list of all subroutines in the package
my $package = 'Mail::Alias::LocalFile';
{
    no strict 'refs';
    my @all_subs = grep { defined &{$package . '::' . $_} } keys %{$package . '::'};
    
    # Filter out imported methods
    my @methods = sort grep { $_ !~ /^(import|AUTOLOAD|BEGIN|DESTROY|END|INIT|CHECK)$/ } @all_subs;
    
    diag("Found " . scalar(@methods) . " methods in $package");
    
    foreach my $method (@methods) {
        # Skip methods matching our exclusion patterns
        my $excluded = "";
        if ($method =~ $private_regex) {
            $excluded = " [EXCLUDED: matches private pattern]";
        }
        elsif ($method =~ $trustme_regex) {
            $excluded = " [EXCLUDED: matches Moo-generated pattern]";
        }
        
        diag("  - $method$excluded");
    }
}

diag("\nChecking POD documentation:");
diag("--------------------------");

# Enable verbose mode for Pod::Coverage
$Pod::Coverage::VERBOSE = 1;

# Test specific module
my $pc = Pod::Coverage->new(
    package => $package,
    also_private => [$private_regex],
    trustme => [$trustme_regex],
);

if ($pc) {
    my $coverage = $pc->coverage;
    if (defined $coverage) {
        my @naked = $pc->naked;
        
        # We don't have direct access to documented methods,
        # but we can list all methods in the symbol table
        diag("\nMethods and documentation status:");
        {
            no strict 'refs';
            my @all_subs = sort grep { 
                defined &{$package . '::' . $_} && 
                $_ !~ /^(import|AUTOLOAD|BEGIN|DESTROY|END|INIT|CHECK)$/ 
            } keys %{$package . '::'};
            
            foreach my $method (@all_subs) {
                # Skip methods matching our exclusion patterns
                if ($method =~ $private_regex || $method =~ $trustme_regex) {
                    diag("  - $method [EXCLUDED from coverage check]");
                    next;
                }
                
                my $is_naked = grep { $_ eq $method } @naked;
                if ($is_naked) {
                    diag("  ✗ $method (not documented)");
                } else {
                    diag("  ✓ $method (documented)");
                }
            }
        }
        
        if (@naked) {
            diag("\nUndocumented methods (" . scalar(@naked) . "):");
            foreach my $method (sort @naked) {
                diag("  ✗ $method");
            }
        } else {
            diag("\nAll methods are documented!");
        }
        
        my $percentage = sprintf("%.2f%%", $coverage * 100);
        diag("\nDocumentation coverage: $percentage");
    }
    else {
        diag("No coverage calculated - possible error");
    }
}

# Now do the actual test
pod_coverage_ok(
    $package,
    {
        # Moo-generated accessors don't need pod coverage
        also_private => [$private_regex], 
        # Ignore Moo-generated methods
        trustme => [$trustme_regex],
    },
    "$package POD coverage"
);
