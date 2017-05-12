# makepm.PL -- Builds News/Gateway.pm from News/Gateway.in.
# $Id: makepm.PL,v 0.3 1998/04/12 11:35:42 eagle Exp $

# First, grab the line to set the version number, since we'll need to
# substitute that in to News/Gateway.pm when we build it.  It's the second
# line of VERSION.pm.
open (VERSION, 'VERSION.pm') or die "Cannot open VERSION.pm: $!\n";
<VERSION>;
my $version = <VERSION>;
close VERSION;

# Build a list of all of the available modules and their exported interface
# by trolling through the .al files in the modules directory and looking for
# a line that looks like:
#
# @@ Interface:  ['directive', 'directive']
#
# .al files without a line like that will be presumed to be utility modules
# and won't be added to the hooks in News::Gateway proper.
opendir (MODULES, 'modules') or die "Cannot open directory modules: $!\n";
my ($module, %interfaces);
for $file (grep { /\.al$/ && !/^\./ } readdir MODULES) {
    open (MODULE, "modules/$file")
        or die "Cannot open module modules/$file: $!\n";
    while (<MODULE>) {
        chomp;
        if (/^\# \@\@ Interface:\s+(.*)/) {
            my $interface = $1;
            my $module = $file;
            $module =~ s/\.al$//;
            $interfaces{$module} = $interface;
            last;
        }
    }
    close MODULE;
}
closedir MODULES;

# For nice printing, figure out how long the longest module name is.
my $max = 0;
for (keys %interfaces) {
    if (length $_ > $max) { $max = length $_ }
}

# We now have a complete hash of the modules and their interfaces in
# %interfaces.  Open up our input file (News/Gateway.in) and our output
# file, the final module (News/Gateway.pm) and replace the interface section
# with our generated interface.  We also replace the marker for the version
# number with the version string read in from VERSION above.
open (IN, 'News/Gateway.in') or die "Cannot open News/Gateway.in: $!\n";
open (OUT, '>News/Gateway.pm') or die "Cannot create News/Gateway.pm: $!\n";
while (<IN>) {
    if (/^\# @@ VERSION/) { print OUT $version; next }
    print OUT;
    if (/^\# \@\@ Begin automatically generated section/) {
        print OUT '%HOOKS = (';
        my $first = 1;
        my $module;
        for $module (sort keys %interfaces) {
            if ($first) { $first = 0 } else { print OUT ",\n          " }
            printf OUT ("%-${max}s => %s", $module, $interfaces{$module});
        }
        print OUT ");\n";
    }
}
