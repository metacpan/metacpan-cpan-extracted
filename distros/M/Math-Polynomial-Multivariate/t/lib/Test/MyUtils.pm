# Copyright (c) 2008-2013 Martin Becker.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: MyUtils.pm 20 2013-06-01 21:19:29Z demetri $

# Utility functions for tests:
# * conditionally skip tests if required modules are not available
# * conditionally skip tests intended for the maintainer only
# * conditionally skip tests if some file cannot be read into a string
# * fetch an executable file name of the perl binary currently running

package Test::MyUtils;

use 5.006;
use strict;
use warnings;
use Config;
use base 'Exporter';

our $VERSION   = '0.006';
our @EXPORT    = qw(use_or_bail maintainer_only);
our @EXPORT_OK = qw(slurp_or_bail this_perl);

our $DIST_NAME    = _guess_distname();
our $MAX_FILESIZE = 1024 * 1024;

sub _guess_distname {
    my $distname = undef;
    if (open my $rh, '<', 'README') {
        my $headline = <$rh>;
        if (defined $headline && $headline =~ /^\s*(\w+(?:[^\w\s]+\w+)*)\s/) {
            $distname = $1;
        }
        close $rh;
    }
    if (!defined $distname) {
        $distname = 'This-Distribution';
    }
    return $distname;
}

sub _skip_all {
    my ($reason) = @_;
    print "1..0 # SKIP $reason\n";
    exit 0;
}

# To enforce a minimum version of a module, supply a $version value.
# To use a module with default imports, omit $imports_ref.
# To use a module with explicit or no imports, supply an array reference.
sub use_or_bail {
    my ($module, $version, $imports_ref) = @_;

    if (!eval "require $module") {
        _skip_all("$module not available");
    }

    if (defined($version) && !defined eval { $module->VERSION($version) }) {
        _skip_all("$module version $version or higher not available");
    }

    if (!$imports_ref || @{$imports_ref}) {
        my $package = caller;
        my @imports = $imports_ref? @{$imports_ref}: ();
        if (!eval "package $package; \$module->import(\@imports); 1") {
            my $error = $@;
            $error =~ s/\n.*//s;
            _skip_all("import of $module failed: $error");
        }
    }
    return 1;
}

# Call this before plan() in test scripts reserved for the maintainer.
# Add names of mandatory configuration features for further restrictions.
sub maintainer_only {
    my @required_features = @_;
    my $env_maint = 'MAINTAINER_OF_' . uc $DIST_NAME;
    $env_maint =~ s/[_\W]+/_/g;
    if (!$ENV{$env_maint}) {
        _skip_all("setenv $env_maint=1 to run these tests");
    }
    foreach my $feature (@required_features) {
        if (!$Config{$feature}) {
            _skip_all("feature not available: $feature");
        }
    }
    return 1;
}

# Call this before plan() in test scripts analysing some file.
# Return value is the file content.  Returns only on success.
sub slurp_or_bail {
    my ($filename) = @_;
    local $/;
    my $fh;
    my $result;
    my $err;
    if (!-e $filename) {
        $err = 'file does not exist';
    }
    elsif (!-f _) {
        $err = 'not a plain file';
    }
    elsif ($MAX_FILESIZE < -s _) {
        $err = 'file too large';
    }
    elsif (open $fh, '<', $filename) {
        defined($result = <$fh>) or $err = "cannot read: $!";
        close $fh;
    }
    else {
        $err = "cannot open: $!";
    }
    if (!defined $result) {
        _skip_all("$filename: $err");
    }
    return $result;
}

sub this_perl {
    my $this_perl = $Config{'perlpath'};
    my $suffix    = exists($Config{'_exe'})? $Config{'_exe'}: '';
    if ($^O ne 'VMS' && '' ne $suffix && $this_perl !~ /$suffix\z/) {
        $this_perl .= $suffix;
    }
    return $this_perl;
}

1;
__END__
