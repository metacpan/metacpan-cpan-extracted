# Copyright (c) 2008-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Checking package consistency (version numbers, file names, ...).
# These are tests for the distribution maintainer.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/92_consistency.t'

use 5.006;
use strict;
use warnings;
use lib 't/lib';
use Test::MyUtils;
BEGIN {
    use_or_bail('File::Spec');
    use_or_bail('File::Basename', undef, [qw(basename dirname)]);
    use_or_bail('YAML', undef, []);
}

my $test_plan  = 0;
my $test_count = 0;
my $test_fail  = 0;

sub plan {
    my ($n) = @_;
    $test_plan = $n;
    print "1..$n\n";
}

sub test {
    my ($ok, $comment) = @_;
    ++$test_count;
    ++$test_fail if !$ok;
    print
        !$ok && 'not ', "ok $test_count",
        defined($comment) && " - $comment", "\n";
}

sub skip {
    my ($tests, $reason) = @_;
    while (0 < $tests) {
        ++$test_count;
        --$tests;
        print "ok $test_count # skip $reason\n";
    }
}

sub conclude {
    my $code = 0;
    if ($test_plan != $test_count) {
        if ($test_count) {
            my $s = 1 == $test_plan? q[]: q[s];
            print
                "# Looks like you planned $test_plan test$s ",
                "but ran $test_count.\n";
        }
        else {
            print "# No tests run!\n";
        }
        $code = -1;
    }
    if ($test_fail) {
        my $s = 1 == $test_fail? q[]: q[s];
        my $r = $test_plan == $test_count? q[]: q[ run];
        print
            "# Looks like you failed $test_fail test$s ",
            "out of $test_count$r.\n";
        $code ||= $test_fail <= 255? $test_fail: 255;
    }
    exit $code;
}

sub hoh_equal {
    my ($this, $that) = @_;
    my @these = sort keys %{$this};
    my @those = sort keys %{$that};
    return 0
        if @these != @those || grep {$these[$_] ne $those[$_]} 0 .. $#these;
    foreach my $ktop (@these) {
        my ($h1, $h2) = ($this->{$ktop}, $that->{$ktop});
        return 0 if grep { 'HASH' ne ref $_ } $h1, $h2;
        my @k1 = sort keys %{$h1};
        my @k2 = sort keys %{$h2};
        return 0 if "@k1" ne "@k2" || "@{$h1}{@k1}" ne "@{$h2}{@k2}";
    }
    return 1;
}

$| = 1;
undef $/;

maintainer_only();

plan 43;

my $MAKEFILE_PL            = 'Makefile.PL';
my $README                 = 'README';
my $META_YML               = 'META.yml';
my $AGENDA_YML             = 't/data/AGENDA.yml';
my $MANIFEST               = 'MANIFEST';
my $CHANGES                = 'Changes';
my ($modname, $authormail) = info_from_makefile_pl();
my ($ambox, $amhost)       = split /\@/, $authormail;
(my $distname              = $modname) =~ s{::}{-}g;
(my $modfilename           = $modname) =~ s{::}{/}g;
$modfilename .= '.pm';
my $items_to_provide       = undef;

my %ignore_copyright = map {($_ => 1)} qw(
    CONTRIBUTING
    Changes
    LICENSE
    MANIFEST
    META.json
    META.yml
    MYMETA.json
    MYMETA.yml
    SIGNATURE
    t/data/AGENDA.yml
    t/data/KNOWN_VERSIONS
);

my %ignore_whitespace = map {($_ => 1)} qw(
    LICENSE
);

my %pattern = (
    'binary_file'      => qr{\.(?i:png|jpg|gif)\z},
    'perl_code'        => qr{\.(?i:pm|pl|t|pod)\z},
    'library_module'   => qr{^lib/.*\.pm\z},
    'copyright_info'   => qr{\bCopyright \(c\) (?:\d{4}-)?(\d{4})?\b},
    'revision_id'      => qr{^\s*#\s+\$Id[\:\$]},
    'revision_info'    =>
        qr{
            ^\s*\#\s+
            \$ Id \:\s+         # keyword
            (\S+)\s+            # filename into $1
            \S+\s+              # version/patch number
            (\d{4})             # year into $2
            -\d\d-\d\d\s+       # month/day
            \S+\s+              # time
            \S+\s+              # user name
            \$
        }x,
    'script_ref'       =>
        qr{
            ^\s*\#[^\n]*\b
            After\s+['`]make\s+install\'\s+it\s+should\s+work\s+as\s+
            ['`]perl\s+(?:t/)?
            ([\-\w]+\.t)
            \'
        }mx,
    'changes_version_std' =>
        qr{^(\d+\.\d\S*)\s+(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)\b},
    'changes_version_short_dates' =>
        qr{^(\d+\.\d\S*)\s+\d{4}-\d{2}-\d{2}\b},
    'changes_version_headlines' =>
        qr{^\s*\Q$modname\E\s+(?:[Vv]ersion\s+)?(\d\S*)\s*$},
    'authormail_code' =>
        qr[\QE<lt>$ambox\E(?:\@|E<64>|\s*\(at\)\s*)\Q${amhost}E<gt>\E],
    'package_line' => qr/^\s*package\s+(\w+(?:\:\:\w+)*)\s*;/,
    'version_line' => qr/^\s*(?:our\s*)\$VERSION\s*=\s*(.*?)\s*\z/,
    'version' => qr/^'([\d._]+)';\z/,
);

# part 1: names and version numbers in various places

require $modfilename;
my $mod_version = $modname->VERSION;
my $meta_provides = undef;

print "# dist name is $distname\n";
print "# module version is $mod_version\n";
test $mod_version =~ qr/^\d+\.\d+\z/, 'sane version number';

if (eval 'require FindBin') {
    my $distroot = '.' eq $FindBin::Bin? '..': dirname($FindBin::Bin);
    if ($distroot =~ /\b\Q$distname\E-(\d+\.\d+)(?:-\w+)?\z/) {
        test $1 eq $mod_version, 'numbered distro dir matches version';
    }
    else {
        skip 1, "not running in numbered distro dir";
    }
}
else {
    skip 1, "FindBin not available";
}

if (open FILE, '<', $README) {
    my $readme = <FILE>;
    close FILE;
    my $found = $readme =~ /^(\S+)(?:\s+version\s+(\d+\.\d+))?\n/i;
    test $found, "$README contains distro name and optional version number";
    if ($found) {
        my ($readme_distname, $readme_version) = ($1, $2);
        my $qrv =
            defined($readme_version)?
                "version $readme_version":
                'without version';
        print "# $README refers to $readme_distname $qrv\n";
        test $readme_distname eq $distname || $readme_distname eq $modname,
            "distro name in $README matches";
        if (defined $readme_version) {
            test $readme_version eq $mod_version, "version in $README matches";
        }
        else {
            skip 1, "version number not specified in $README";
        }
    }
    else {
        skip 2, "unknown $README version";
    }
}
else {
    skip 3, "cannot open $README file";
}

if (open FILE, '<', $META_YML) {
    my $metayml = <FILE>;
    close FILE;
    my $found_dist = $metayml =~ /^name:\s+(\S+)$/mi;
    test $found_dist, "found distro name in $META_YML";
    if ($found_dist) {
        test $1 eq $distname, "$META_YML has matching distro name";
    }
    else {
        skip 1, "unknown $META_YML dist name";
    }
    my $found_vers = $metayml =~ /^version:\s+('?)([^\s']+)\1$/mi;
    test $found_vers, "found version in $META_YML";
    if ($found_vers) {
        test $2 eq $mod_version, "$META_YML has matching version";
    }
    else {
        skip 1, "module version not found in $META_YML";
    }
    my $meta = YAML::Load($metayml);
    my $meta_is_hash = 'HASH' eq ref($meta);
    test $meta_is_hash, "YAML can parse $META_YML as hash";
    if ($meta_is_hash) {
        $meta_provides = $meta->{'provides'};
        test defined($meta_provides), "$META_YML contains a provides section";
    }
    else {
        skip 1, "$META_YML not understood";
    }
}
else {
    skip 6, "cannot open $META_YML file";
}

my $agenda       = undef;
my %agenda_fixme = ();
my %agenda_todo  = ();
my %agenda_debug = ();
if (open FILE, '<', $AGENDA_YML) {
    my $agendayml = <FILE>;
    close FILE;
    $agenda = eval { YAML::Load($agendayml) || {} };
    my $agenda_is_ok =
        defined($agenda) &&
        'HASH' eq ref($agenda) &&
        !grep { 'ARRAY' ne ref $_ } values %{$agenda};
    test $agenda_is_ok, "$AGENDA_YML is syntactically correct";
    $agenda = {} if !$agenda_is_ok;
}
else {
    $agenda = {};
    test 1, "$AGENDA_YML is not present";
}
foreach my $ca (
    [fixme => \%agenda_fixme],
    [todo  => \%agenda_todo ],
    [debug => \%agenda_debug],
) {
    my ($cat, $ag) = @{$ca};
    @{$ag}{@{$agenda->{$cat}}} = () if exists $agenda->{$cat};
}

my $changes_version = undef;
if (open FILE, '<', $CHANGES) {
    local $/ = "\n";
    $changes_version = '';
    while (<FILE>) {
        if (
            /$pattern{'changes_version_std'}/o ||
            /$pattern{'changes_version_short_dates'}/o ||
            /$pattern{'changes_version_headlines'}/o
        ) {
            $changes_version = $1;
            print "# topmost version in $CHANGES is $changes_version\n";
            last;
        }
    }
    close FILE;
}
test defined($changes_version), "$CHANGES file is present";
if (defined $changes_version) {
    test '' ne $changes_version, "$CHANGES file has version numbers";
    test $mod_version eq $changes_version, "$CHANGES file is up to date";
}
else {
    skip 2, "cannot open $CHANGES file";
}

# part 2: references to filenames

my $files_count       = 0;
my @unreadable_files  = ();
my @missing_filenames = ();
my @wrong_filenames   = ();
foreach my $script_path (glob File::Spec->catfile('t', '*.t')) {
    ++$files_count;
    my $script_name = basename($script_path);
    if (open FILE, '<', $script_path) {
        my $script = <FILE>;
        close FILE;
        if ($script =~ /$pattern{'script_ref'}/o) {
            my $referenced_name = $1;
            if ($referenced_name ne $script_name) {
                push @wrong_filenames, "$referenced_name vs. $script_name";
            }
        }
        else {
            push @missing_filenames, $script_name;
        }
    }
    else {
        push @unreadable_files, $script_name;
    }
}
print "# found $files_count test script(s)\n";
test $files_count, 'found test scripts';
print "# unreadable: @unreadable_files\n" if @unreadable_files;
test !@unreadable_files, 'test scripts readable';
print "# w/o file names: @missing_filenames\n" if @missing_filenames;
test !@missing_filenames, 'script filenames referenced';
print "# wrong filename referenced: $_\n" foreach @wrong_filenames;
test !@wrong_filenames, 'referenced filenames match script names';

# part 3: code maturity

$/ = "\n";

my @missing_distfiles   = ();
my @fixme_distfiles     = ();
my @todo_distfiles      = ();
my @debug_distfiles     = ();
my @badchar_distfiles   = ();
my @hardtab_distfiles   = ();
my @invspace_distfiles  = ();
my @lacking_copyright   = ();
my @lacking_revision_id = ();
my @lacking_author_pod  = ();
my @bogus_author_pod    = ();
my @stale_copyright     = ();
my @mtime_copyright     = ();
my @uncommited_files    = ();
my @all_distfiles       = ();
my @bad_package_versions= ();
my %provided_items      = ();
my $having_revision_id  = 0;
my $manifest_open = open MANIFEST, '<', $MANIFEST;
test $manifest_open, "$MANIFEST is present";
if ($manifest_open) {
    while (<MANIFEST>) {
        chomp;
        s/\s\s.*//s;
        push @all_distfiles, $_;
    }
    close MANIFEST;
    foreach my $file (@all_distfiles) {
        if (open FILE, '<', $file) {
            my $is_perlcode = $file =~ /$pattern{'perl_code'}/o;
            my $is_module   = $file =~ /$pattern{'library_module'}/o;
            my $has_pod = 0;
            if ($file !~ /$pattern{'binary_file'}/o) {
                my $seen_copyright   = 0;
                my $seen_revision_id = 0;
                my $seen_fixme       = 0;
                my $seen_todo        = 0;
                my $seen_debug       = 0;
                my $seen_badchar     = 0;
                my $seen_hardtab     = 0;
                my $seen_invspace    = 0;
                my $in_signature     = 0;
                my $before_end       = 1;
                my $in_author        = 0;
                my $copyright_year   = undef;
                my $checkin_filename = undef;
                my $checkin_year     = undef;
                my $package          = undef;
                my @authors          = ();
                while (<FILE>) {
                    if (/$pattern{'copyright_info'}/o) {
                        ++$seen_copyright;
                        $copyright_year = $1;
                    }
                    if (/$pattern{'revision_id'}/o) {
                        ++$seen_revision_id;
                        if (/$pattern{'revision_info'}/o) {
                            ($checkin_filename, $checkin_year) = ($1, $2);
                        }
                    }
                    if (!$in_signature && /FI[X]ME/) {
                        ++$seen_fixme;
                    }
                    if (!$in_signature && /TO[D]O/) {
                        ++$seen_todo;
                    }
                    if (!$in_signature && /DE[B]UG/) {
                        ++$seen_debug;
                    }
                    if (/[^\t\n\x20-\x7e]/) {
                        ++$seen_badchar;
                    }
                    if (/\t/) {
                        ++$seen_hardtab;
                    }
                    if (/[^\S\n]\n/) {
                        ++$seen_invspace;
                    }
                    if (/-----(BEGIN|END) PGP SIGNATURE-----/) {
                        $in_signature = 'BEGIN' eq $1;
                    }
                    next if !$is_perlcode;
                    if (/^=head1 AUTHOR/) {
                        $in_author = 1;
                        $has_pod = 1;
                    }
                    elsif (/^=head1/) {
                        $in_author = 0;
                        $has_pod = 1;
                    }
                    elsif ($in_author && /^\s*(\S.*\S)/) {
                        push @authors, $1;
                    }
                    next if !$is_module;
                    if (/^__END__$/) {
                        $before_end = 0;
                    }
                    if ($before_end && /$pattern{'package_line'}/o) {
                        $package = $1;
                        $provided_items{$package} ||= { file => $file };
                    }
                    elsif (
                        $before_end &&
                        defined($package) &&
                        exists($provided_items{$package}) &&
                        !exists($provided_items{$package}->{'version'}) &&
                        /$pattern{'version_line'}/o
                    ) {
                        my $raw_version = $1;
                        if ($raw_version =~ /$pattern{'version'}/o) {
                            $provided_items{$package}->{'version'} ||= $1;
                        }
                        else {
                            push @bad_package_versions,
                                [$file, $package, $raw_version];
                        }
                    }
                }
                if (!$seen_copyright && !exists $ignore_copyright{$file}) {
                    push @lacking_copyright, $file;
                }
                if (!$seen_revision_id && $is_perlcode) {
                    push @lacking_revision_id, $file;
                }
                if ($seen_fixme) {
                    push @fixme_distfiles, $file;
                }
                if ($seen_todo) {
                    push @todo_distfiles, $file;
                }
                if ($seen_debug) {
                    push @debug_distfiles, $file;
                }
                if ($seen_badchar) {
                    push @badchar_distfiles, $file;
                }
                elsif (!exists $ignore_whitespace{$file}) {
                    if ($seen_hardtab) {
                        push @hardtab_distfiles, $file;
                    }
                    if ($seen_invspace) {
                        push @invspace_distfiles, $file;
                    }
                }
                if ($seen_revision_id) {
                    if (!defined $checkin_year) {
                        push @uncommited_files, $file;
                    }
                    else {
                        if (
                            defined($copyright_year) &&
                            !defined($ignore_copyright{$file}) &&
                            $copyright_year ne $checkin_year
                        ) {
                            push @stale_copyright, $file;
                        }
                        if ($checkin_filename ne basename($file)) {
                            push @uncommited_files, $file;
                        }
                    }
                }
                else {
                    my $mtime = (stat FILE)[9];
                    my $myear = (localtime $mtime)[5] + 1900;
                    if (
                        defined($copyright_year) &&
                        !defined($ignore_copyright{$file}) &&
                        $copyright_year ne $myear
                    ) {
                        push @mtime_copyright, $file;
                    }
                }
                if ($has_pod) {
                    if (@authors) {
                        grep { /$pattern{'authormail_code'}/o } @authors or
                            push @bogus_author_pod, $file;
                    }
                    else {
                        push @lacking_author_pod, $file;
                    }
                }
                ++$having_revision_id if $seen_revision_id;
            }
            close FILE;
        }
        else {
            push @missing_distfiles, $file;
        }
    }
    foreach my $file (@missing_distfiles) {
        print qq{# missing file: "$file"\n};
    }
    test !@missing_distfiles, 'distribution complete';

    my (@fixme_a, @fixme_u) = ();
    foreach my $file (@fixme_distfiles) {
        my $in_a = q[];
        if (exists $agenda_fixme{$file}) {
            $in_a = ' (in agenda)';
            push @fixme_a, $file;
            delete $agenda_fixme{$file};
        }
        else {
            push @fixme_u, $file;
        }
        print "# file with FIX", "ME tag: $file$in_a\n";
    }
    test !@fixme_u, 'no files flagged as needing fix';
    my @fixme_x = sort keys %agenda_fixme;
    foreach my $file (@fixme_x) {
        print "# extra file in fixme agenda: $file\n";
    }
    test !@fixme_x, 'no extra files in fixme agenda';

    my (@todo_a, @todo_u) = ();
    foreach my $file (@todo_distfiles) {
        my $in_a = q[];
        if (exists $agenda_todo{$file}) {
            $in_a = ' (in agenda)';
            push @todo_a, $file;
            delete $agenda_todo{$file};
        }
        else {
            push @todo_u, $file;
        }
        print "# file with TO", "DO tag: $file$in_a\n";
    }
    test !@todo_u, 'no files flagged as needing more work';
    my @todo_x = sort keys %agenda_todo;
    foreach my $file (@todo_x) {
        print "# extra file in todo agenda: $file\n";
    }
    test !@todo_x, 'no extra files in todo agenda';

    my (@debug_a, @debug_u) = ();
    foreach my $file (@debug_distfiles) {
        my $in_a = q[];
        if (exists $agenda_debug{$file}) {
            $in_a = ' (in agenda)';
            push @debug_a, $file;
            delete $agenda_debug{$file};
        }
        else {
            push @debug_u, $file;
        }
        print "# file with DE", "BUG tag: $file$in_a\n";
    }
    test !@debug_distfiles, 'no files with temporary debugging aids';
    my @debug_x = sort keys %agenda_debug;
    foreach my $file (@debug_x) {
        print "# extra file in debug agenda: $file\n";
    }
    test !@debug_x, 'no extra files in debug agenda';

    foreach my $file (@badchar_distfiles) {
        print "# file with strange characters: $file\n";
    }
    test !@badchar_distfiles, 'no text files with strange characters';
    foreach my $file (@hardtab_distfiles) {
        print "# file with hardtab characters: $file\n";
    }
    test !@hardtab_distfiles, 'no text files with hardtab characters';
    foreach my $file (@invspace_distfiles) {
        print "# file with whitespace at end of line: $file\n";
    }
    test !@invspace_distfiles, 'no text files with whitespace at end of line';
    foreach my $file (@lacking_author_pod) {
        print "# POD source file without AUTHOR section: $file\n";
    }
    test !@lacking_author_pod, 'POD sources have AUTHOR section';
    foreach my $file (@bogus_author_pod) {
        print "# POD AUTHOR section without this author's email: $file\n";
    }
    test !@bogus_author_pod, q{POD AUTHOR sections have this author's email};
    foreach my $file (@lacking_copyright) {
        print "# file lacking copyright notice: $file\n";
    }
    test !@lacking_copyright, 'copyright notice present where appropriate';
    foreach my $file (@stale_copyright) {
        print "# copyright year != checkin year: $file\n";
    }
    test !@stale_copyright, 'copyright years match checkin dates';
    foreach my $file (@mtime_copyright) {
        print "# copyright year != year of last file modification: $file\n";
    }
    test !@mtime_copyright, 'copyright years match file modification times';
    if ($having_revision_id) {
        foreach my $file (@lacking_revision_id) {
            print "# file lacking revision ID: $file\n";
        }
        test !@lacking_revision_id, 'revision ID present in perl source code';
        foreach my $file (@uncommited_files) {
            print "# file probably not yet commited: $file\n";
        }
        test !@uncommited_files, 'revision IDs have date and match filenames';
    }
    else {
        skip 2, 'no revision ids in this distro';
    }
    foreach my $pkg (@bad_package_versions) {
        print "# strange package version: @{$pkg}\n";
    }
    test !@bad_package_versions, 'all package versions can be parsed';
    test scalar(keys %provided_items), 'library files provide packages';
    if (keys %provided_items) {
        print
            "# provides:\n",
            map {
                my $h = $provided_items{$_};
                "#   $_:\n",
                map {
                    "#     $_: $h->{$_}\n"
                } sort keys %{$h}
            } sort keys %provided_items;
    }
    if (defined $meta_provides) {
        test hoh_equal($meta_provides, \%provided_items),
            qq{"provides" section in $META_YML matches found packages};
    }
    else {
        skip 1, qq{got no "provides" section from $META_YML};
    }
}
else {
    skip 15, "cannot open $MANIFEST file";
}

conclude();

# prologue: fetching the module name and author mail address
sub info_from_makefile_pl {
    my ($modname, $authormail) = ();
    my $mf_content = '';
    my $mf_open = open MF, '<', $MAKEFILE_PL;
    if ($mf_open) {
        $mf_content = <MF>;
        close MF;
    }
    test $mf_open, "$MAKEFILE_PL present";
    if ($mf_open) {
        $mf_content =~ m{
            ^ \s* WriteMakefile\( \s*       # WriteMakefile call
            (['"]?)                         # optional quote in $1
            NAME                            # NAME key
            \1                              # optional quote from $1
            \s* => \s*                      # fat comma
            (['"]?)                         # optional quote in $2
            ([\w:]+)                        # module name in $3
            \2                              # optional quote from $2
            \s* ,                           # comma
        }mx and $modname = $3;
        if (defined $modname) {
            print "# module name is $modname\n";
        }
        test defined($modname), "module name found in $MAKEFILE_PL file";
        $mf_content =~ m{
            ^ \s*                           # line start
            (['"]?)                         # optional quote in $1
            AUTHOR                          # AUTHOR key
            \1                              # optional quote from $1
            \s* => \s*                      # fat comma
            (['"])                          # mandatory quote in $2
            ([^\s<>]+ (?:\s+ [^\s<>]+)* )   # civilian name in $3
            \s* \<                          # left angular bracket
            ([\w.-]+)                       # mailbox in $4
            (?:
            \\? \@                          # optional backslash, at-sign
            |
            \s*\(at\)\s*                    # optionally replaced by (at)
            )
            ([\w.-]+)                       # host in $5
            \>                              # right angular bracket
            \2                              # quote from $2
            \s* ,                           # comma
        }mx and $authormail = join '@', $4, $5;
        if (defined $authormail) {
            print "# single author mailbox is $authormail\n";
        }
        test defined($authormail), "author mailbox found in $MAKEFILE_PL file";
    }
    else {
        skip 2, "cannot open $MAKEFILE_PL file";
    }
    return (
        defined($modname)   ? $modname   : 'Acme::Cruft',
        defined($authormail)? $authormail: 'john.doe@example.com',
    );
}

__END__
