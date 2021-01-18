package Dist::Mgr;

use strict;
use warnings;
use version;

use Capture::Tiny qw(:all);
use Carp qw(croak cluck);
use CPAN::Uploader;
use Cwd qw(getcwd);
use Data::Dumper;
use Digest::SHA;
use Dist::Mgr::FileData qw(:all);
use Dist::Mgr::Git qw(:all);
use File::Copy;
use File::Copy::Recursive qw(rmove_glob);
use File::Path qw(make_path rmtree);
use File::Find::Rule;
use JSON;
use Module::Starter;
use PPI;
use Term::ReadKey;
use Tie::File;

use Exporter qw(import);
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
    add_bugtracker
    add_repository
    changes
    changes_bump
    changes_date
    ci_badges
    ci_github
    config
    config_file
    copyright_info
    copyright_bump
    cpan_upload
    git_add
    git_commit
    git_clone
    git_pull
    git_push
    git_ignore
    git_release
    git_repo
    git_status_differs
    git_tag
    init
    make_dist
    make_distclean
    make_manifest
    make_test
    manifest_skip
    manifest_t
    move_distribution_files
    remove_unwanted_files
    version_bump
    version_incr
    version_info
);
our @EXPORT_PRIVATE = qw(
    _dist_dir_re
    _validate_git
);
our %EXPORT_TAGS = (
    all     => [@EXPORT_OK],
    private => _export_private(),
);

our $VERSION = '1.06';

use constant {
    CONFIG_FILE         => 'dist-mgr.json',
    GITHUB_CI_FILE      => 'github_ci_default.yml',
    GITHUB_CI_PATH      => '.github/workflows/',
    CHANGES_FILE        => 'Changes',
    CHANGES_ORIG_SHA    => '97624d56464d7254ef5577e4a0c8a098d6c6d9e6', # Module::Starter version
    FSTYPE_IS_DIR       => 1,
    FSTYPE_IS_FILE      => 2,
    DEFAULT_DIR         => 'lib/',
    DEFAULT_POD_DIR     => '.',
    MAKE                => $^O =~ /win32/i ? 'gmake' : 'make',
};

# Public

sub add_bugtracker {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_bugtracker(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_bugtracker($author, $repo, $makefile);
}
sub add_repository {
    my ($author, $repo, $makefile) = @_;

    if (! defined $author || ! defined $repo) {
        croak("Usage: add_repository(\$author, \$repository_name)\n");
    }

    $makefile //= 'Makefile.PL';

    _makefile_insert_repository($author, $repo, $makefile);
}
sub changes {
    my ($module, $file) = @_;

    croak("changes() needs a module parameter") if ! defined $module;

    $file //= 'Changes';

    # Overwrite the Changes file if there aren't any dates in it

    my @contents;

    my $changes_date_count = 0;

    if (-e $file) {
        my ($contents, $tie) = _changes_tie($file);
        $changes_date_count = grep /\d{4}-\d{2}-\d{2}/, $contents;
        untie $tie;
    }
    if (! -e $file || ! $changes_date_count) {
        my @contents = _changes_file($module);
        _changes_write_file($file, \@contents);
    }

    return @contents;
}
sub changes_bump {
    my ($version, $file) = @_;

    croak("changes_bump() requires a version sent in") if ! defined $version;
    _validate_version($version);

    $file //= 'Changes';

    my ($contents, $tie) = _changes_tie($file);

    for (0..$#$contents) {
        if ($contents->[$_] =~ /^\d+\.\d+\s+/) {
            $contents->[$_-1] = "\n$version UNREL\n    -\n\n";
            last;
        }
    }

    untie $tie;
}
sub changes_date {
    my ($file) = @_;

    $file //= 'Changes';

    my ($contents, $tie) = _changes_tie($file);

    my ($d, $m, $y) = (localtime)[3, 4, 5];
    $y += 1900;
    $m += 1;

    $m = "0$m" if length $m == 1;
    $d = "0$d" if length $d == 1;

    for (0..$#$contents) {
        if ($contents->[$_] =~ /^(.*)\s+UNREL/) {
            $contents->[$_] = "$1    $y-$m-$d";
            last;
        }
    }

    untie $tie;
}
sub ci_badges {
    if (scalar @_ < 2) {
        croak("ci_badges() needs \$author and \$repo sent in");
    }

    my ($author, $repo, $fs_entry) = @_;

    $fs_entry //= DEFAULT_DIR;

    my $exit = 0;

    for (_module_find_files($fs_entry)) {
        $exit = -1 if _module_insert_ci_badges($author, $repo, $_) == -1;
    }

    return $exit;
}
sub ci_github {
    my ($os) = @_;

    if (defined $os && ref $os ne 'ARRAY') {
        croak("\$os parameter to ci_github() must be an array ref");
    }

    # Add the CI file to MANIFEST.SKIP

    if (-e 'MANIFEST.SKIP') {
        open my $fh, '<', 'MANIFEST.SKIP'
            or croak("Can't open MANIFEST.SKIP for reading");

        my @makefile_skip_contents = <$fh>;

        if (grep !m|\.github$|, @makefile_skip_contents) {
            close $fh;
            open my $wfh, '>>', 'MANIFEST.SKIP'
                or croak("Can't open MANIFEST.SKIP for writing");

            print $wfh '^\.github/';
        }
    }
    else {
        open my $wfh, '>>', 'MANIFEST.SKIP'
            or croak("Can't open MANIFEST.SKIP for writing");

        print $wfh '^\.github/';
    }

    my @contents = _ci_github_file($os);
    _ci_github_write_file(\@contents);

    return @contents;
}
sub config {
    my ($args, $file) = @_;

    if (! defined $args) {
        croak("config() requires \$args hash reference parameter");
    }
    elsif (ref $args ne 'HASH') {
        croak("\$args parameter must be a hash reference.");
    }

    $file = config_file() if ! defined $file;
    my $conf;

    if (-e $file && -f $file) {
        {
            local $/;
            open my $fh, '<', $file or croak "Can't open config file $file: $!";
            my $json = <$fh>;
            $conf = decode_json $json;

            for (keys %{ $conf }) {
                delete $conf->{$_} if $conf->{$_} eq '';
            }
        }
    }
    else {
        # No config file present
        _config_file_write($file, _config_file());

        print "\nGenerated new configuration file: $file\n";
    }

    %{ $args } = (%{ $args }, %{ $conf }) if $conf;

    return $args;
}
sub config_file {
    my $file = $^O =~ /win32/i
        ? "$ENV{USERPROFILE}/${\CONFIG_FILE}"
        : "$ENV{HOME}/${\CONFIG_FILE}";

    return $file;
}
sub copyright_bump {
    my ($fs_entry) = @_;

    $fs_entry //= DEFAULT_POD_DIR;
    _validate_fs_entry($fs_entry);

    my ($year) = (localtime)[5];
    $year += 1900;

    my @pod_files = _pod_find_files($fs_entry);
    my %info;

    for my $pod_file (@pod_files) {
        my ($contents, $tie) = _pod_tie($pod_file);

        for (0 .. $#$contents) {
            if ($contents->[$_] =~ /^(Copyright\s+)\d{4}(\s+.*)/) {
                $contents->[$_] = "$1$year$2";
                $info{$pod_file} = $year;
                last;
            }
        }
        untie $tie;
    }

    return \%info;
}
sub copyright_info {
    my ($fs_entry) = @_;

    $fs_entry //= DEFAULT_POD_DIR;

    _validate_fs_entry($fs_entry);

    my @pod_files = _pod_find_files($fs_entry);

    my %copyright_info;

    for my $file (@pod_files) {
        my $copyright = _pod_extract_file_copyright($file);
        next if ! defined $copyright || $copyright !~ /^\d{4}$/;
        $copyright_info{$file} = $copyright if defined $copyright;
    }

    return \%copyright_info;
}
sub cpan_upload {
    my ($dist_file_name, %args) = @_;

    config(\%args);

    if (! defined $dist_file_name) {
        croak("cpan_upload() requires the name of a distribution file sent in");
    }

    if (! -f $dist_file_name) {
        croak("File name sent to cpan_upload() isn't a valid file");
    }

    $args{user}     //= $args{cpan_id};
    $args{password} //= $args{cpan_pw};

    $args{user} = $ENV{CPAN_USERNAME} if ! $args{user};
    $args{password} = $ENV{CPAN_PASSWORD} if ! $args{password};

    if (! $args{user} || ! $args{password}) {
        croak("\ncpan_upload() requires --cpan_id and --cpan_pw");
    }

    if ($args{dry_run}) {
        print "\nCPAN upload is in dry run mode... nothing will be uploaded\n";
    }

    CPAN::Uploader->upload_file(
        $dist_file_name,
        \%args
    );

    print "\nSuccessfully uploaded $dist_file_name to the CPAN\n";

    return %args;
}
sub git_add {
    _git_add();
}
sub git_ignore {
    my ($dir) = @_;

    $dir //= '.';

    my @content = _git_ignore_file();

    _git_ignore_write_file($dir, \@content);

    return @content;
}
sub git_commit {
    _git_commit(@_);
}
sub git_clone {
    _git_clone(@_);
}
sub git_push {
    _git_push(@_);
}
sub git_pull {
    _git_pull(@_);
}
sub git_release {
    _git_release(@_);
}
sub git_repo {
    _git_repo();
}
sub git_status_differs {
    _git_status_differs(@_);
}
sub git_tag {
    _git_tag(@_);
}
sub init {
    my (%args) = @_;

    config(\%args);

    my $cwd = getcwd();

    if ($cwd =~ _dist_dir_re()) {
        croak "Can't run init() while in the '$cwd' directory";
    }

    $args{license} = 'artistic2' if ! exists $args{license};
    $args{builder} = 'ExtUtils::MakeMaker';

    for (qw(modules author email)) {
        if (! exists $args{$_}) {
            croak("init() requires '$_' in the parameter hash");
        }
    }

    if (ref $args{modules} ne 'ARRAY') {
        croak("init()'s 'modules' parameter must be an array reference");
    }

    if ($args{verbose}) {
        delete $args{verbose};
        Module::Starter->create_distro(%args);
    }
    else {
        capture_merged {
            Module::Starter->create_distro(%args);
        };
    }

    my ($module) = (@{ $args{modules} })[0];
    my $module_file = $module;
    $module_file =~ s/::/\//g;
    $module_file = "lib/$module_file.pm";

    my $module_dir = $module;
    $module_dir =~ s/::/-/g;

    chdir $module_dir or croak("Can't change into directory '$module_dir'");

    unlink $module_file
        or croak("Can't delete the Module::Starter module '$module_file': $!");

    _module_write_template($module_file, $module, $args{author}, $args{email});

    chdir '..' or croak "Can't change into original directory";
}
sub manifest_skip {
    my ($dir) = @_;

    $dir //= '.';

    my @content = _manifest_skip_file();

    _manifest_skip_write_file($dir, \@content);

    return @content;
}
sub manifest_t {
    my ($dir) = @_;

    $dir //= './t';

    my @content = _manifest_t_file();

    _manifest_t_write_file($dir, \@content);

    return @content;
}
sub move_distribution_files {
    my ($module) = @_;

    if (! defined $module) {
        croak("_move_distribution_files() requires a module name sent in");
    }

    my $module_dir = $module;
    $module_dir =~ s/::/-/g;

    my @move_count = rmove_glob("$module_dir/*", '.')
        or croak("Can't move files from the '$module_dir' directory: $!");

    my $dist_count = _default_distribution_file_count();

    for my $outer_idx (0..$#move_count) {
        my $outer = $move_count[$outer_idx];
        for my $inner_idx (0..$#$outer) {
            my $inner = $move_count[$outer_idx][$inner_idx];
            for (0..$#$inner) {
                if ($inner->[$_] != $dist_count->[$outer_idx][$inner_idx][$_]) {
                    croak("Results from the move are mismatched... bailing out");
                }
            }
        }
    }

    rmtree $module_dir or croak("Couldn't remove the '$module_dir' directory");

    return 0;
}
sub remove_unwanted_files {
    for (_unwanted_filesystem_entries()) {
        rmtree $_;
    }
    make_manifest();
    return 0;
}
sub make_dist {
    my ($verbose) = @_;

    my $cmd = "${\MAKE} dist";
    $verbose ? `$cmd` : capture_merged {`$cmd`};

    if ($? != 0) {
        croak("Exit code $? returned... '${\MAKE} dist' failed");
    }

    return $?;
}
sub make_distclean {
    my ($verbose) = @_;

    my $cmd = "${\MAKE} distclean";
    $verbose ? print `$cmd` : capture_merged {`$cmd`};

    if ($? != 0) {
        croak("Exit code $? returned... '${\MAKE} distclean' failed\n");
    }

    return $?;
}
sub make_manifest {
    my ($verbose) = @_;

    if ($verbose) {
        if (-f 'MANIFEST') {
            unlink 'MANIFEST' or die "make_manifest() Couldn't remove MANIFEST\n";
        }
        print `$^X Makefile.PL`;
        print `${\MAKE} manifest`;
        make_distclean($verbose);
    }
    else {
        capture_merged {
            if (-f 'MANIFEST') {
                unlink 'MANIFEST' or die "make_manifest() Couldn't remove MANIFEST\n";
            }
            `$^X Makefile.PL`;
            `${\MAKE} manifest`;
            make_distclean($verbose);
        };
    }

    if ($? != 0) {
        croak("Exit code $? returned... '${\MAKE} manifest' failed\n");
    }

    return $?;
}
sub make_test {
    my ($verbose) = @_;

    if ($verbose) {
        print `$^X Makefile.PL`;
        print `${\MAKE} test`;
    }
    capture_merged {
        `$^X Makefile.PL`;
        `${\MAKE} test`;
    };

    if ($? != 0) {
        croak("Exit code $? returned... '${\MAKE} test' failed\n");
    }

    return $?;
}
sub version_bump {
    my ($version, $fs_entry) = @_;

    my $dry_run = 0;

    if (defined $version && $version =~ /^-/) {
        print "\nDry run\n\n";
        $version =~ s/-//;
        $dry_run = 1;
    }

    $fs_entry //= DEFAULT_DIR;

    _validate_version($version);
    _validate_fs_entry($fs_entry);

    my @module_files = _module_find_files($fs_entry);

    my %files;

    for (@module_files) {
        my $current_version = _module_extract_file_version($_);
        my $version_line    = _module_extract_file_version_line($_);
        my @file_contents   = _module_fetch_file_contents($_);

        if (! defined $version_line) {
            next;
        }

        if (! defined $current_version) {
            next;
        }

        if (version->parse($current_version) >= version->parse($version)) {
            croak(
                "Your new version $version must be greater than the current " .
                    "one, $current_version"
            );
        }

        my $mem_file;

        open my $wfh, '>', \$mem_file or croak("Can't open mem file!: $!");

        for my $line (@file_contents) {
            chomp $line;

            if ($line eq $version_line) {
                $line =~ s/$current_version/$version/;
            }

            $line .= "\n";

            # Write out the line to the in-memory temp file
            print $wfh $line;

            $files{$_}{from}    = $current_version;
            $files{$_}{to}      = $version;
        }

        close $wfh;

        $files{$_}{dry_run} = $dry_run;
        $files{$_}{content} = $mem_file;

        if (! $dry_run) {
            # Write out the actual file
            _module_write_file($_, $mem_file);
        }
    }
    return \%files;
}
sub version_incr {
    my ($version) = @_;

    croak("version_incr() needs a version number sent in") if ! defined $version;

    my $incremented_version;

    _validate_version($version);
    return sprintf("%.2f", $version + '0.01');
}
sub version_info {
    my ($fs_entry) = @_;

    $fs_entry //= DEFAULT_DIR;

    _validate_fs_entry($fs_entry);

    my @module_files = _module_find_files($fs_entry);

    my %version_info;

    for (@module_files) {
        my $version = _module_extract_file_version($_);
        $version_info{$_} = $version;
    }

    return \%version_info;
}

# Changes file related

sub _changes_tie {
    # Ties the Changes file to an array

    my ($changes) = @_;
    croak("_changes_tie() needs a Changes file name sent in") if ! defined $changes;

    my $tie = tie my @changes, 'Tie::File', $changes;
    return (\@changes, $tie);
}
sub _changes_write_file {
    # Writes out the custom Changes file

    my ($file, $content) = @_;

    open my $fh, '>', $file or cluck("Can't open file $file: $!");

    for (@$content) {
        print $fh "$_\n"
    }

    close $fh;

    return 0;
}

# CI related

sub _ci_github_write_file {
    # Writes out the Github Actions config file

    my ($contents) = @_;

    if (ref $contents ne 'ARRAY') {
        croak("_ci_github_write_file() requires an array ref of contents");
    }

    my $ci_file //= GITHUB_CI_PATH . GITHUB_CI_FILE;

    make_path(GITHUB_CI_PATH) if ! -d GITHUB_CI_PATH;

    open my $fh, '>', $ci_file or croak $!;

    print $fh "$_\n" for @$contents;
}

# Configuration related

sub _config_file_write {
    my ($file, $contents) = @_;

    if (ref $contents ne 'HASH') {
        croak("_config_file_write() requires a hash ref of contents");
    }

    my $jobj = JSON->new;

    my $json = $jobj->pretty->encode($contents);

    open my $fh, '>', $file or croak "Can't open config $file for writing: $!";

    print $fh $json;

}

# Distribution related

sub _default_distribution_file_count {
    # Returns the file count in a distribution
    # This is used to ensure everything moved OK

    return [
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [3, 2, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [1, 0, 0] ],
        [ [5, 1, 0] ],
        [ [2, 1, 0] ],
    ];
}

# Git related

sub _git_ignore_write_file {
    # Writes out the .gitignore file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/.gitignore" or croak $!;

    for (@$content) {
        print $fh "$_\n"
    }

    return 0;
}

# Makefile related

sub _makefile_tie {
    # Ties the Makefile.PL file to an array

    my ($mf) = @_;
    croak("_makefile_tie() needs a Makefile name sent in") if ! defined $mf;

    my $tie = tie my @mf, 'Tie::File', $mf;
    return (\@mf, $tie);
}
sub _makefile_insert_meta_merge {
    # Inserts the META_MERGE section into Makefile.PL

    my ($mf) = @_;

    croak("_makefile_insert_meta_merge() needs a Makefile tie sent in") if ! defined $mf;

    # Check to ensure we're not duplicating
    return if grep /META_MERGE/, @$mf;

    for (0..$#$mf) {
        if ($mf->[$_] =~ /MIN_PERL_VERSION/) {
            splice @$mf, $_+1, 0, _makefile_section_meta_merge();
            last;
        }
    }
}
sub _makefile_insert_bugtracker {
    # Inserts bugtracker information into Makefile.PL

    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_bugtracker() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_tie($makefile);

    return -1 if grep /bugtracker/, @$mf;

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
        if ($mf->[$_] =~ /resources   => \{/) {
            splice @$mf, $_+1, 0, _makefile_section_bugtracker($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}
sub _makefile_insert_repository {
    # Inserts repository information to Makefile.PL

    my ($author, $repo, $makefile) = @_;

    if (! defined $makefile) {
        croak("_makefile_insert_repository() needs author, repo and makefile");
    }

    my ($mf, $tie) = _makefile_tie($makefile);

    return -1 if grep /repository/, @$mf;

    if (grep ! /META_MERGE/, @$mf) {
        _makefile_insert_meta_merge($mf);
    }

    for (0..$#$mf) {
        if ($mf->[$_] =~ /resources   => \{/) {
            splice @$mf, $_+1, 0, _makefile_section_repo($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}

# MANIFEST related

sub _manifest_skip_write_file {
    # Writes out the MANIFEST.SKIP file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/MANIFEST.SKIP" or croak $!;

    for (@$content) {
        print $fh "$_\n"
    }

    return 0;
}
sub _manifest_t_write_file {
    # Writes out the t/manifest.t test file

    my ($dir, $content) = @_;

    open my $fh, '>', "$dir/manifest.t"
        or croak("Can't open t/manifest.t for writing: $!\n");

    for (@$content) {
        print $fh "$_\n"
    }

    return 0;
}

# Module related

sub _module_extract_file_version {
    # Extracts the version number from a module's $VERSION definition line

    my ($module_file) = @_;

    my $version_line = _module_extract_file_version_line($module_file);

    if (defined $version_line) {

        if ($version_line =~ /=(.*)$/) {
            my $ver = $1;

            $ver =~ s/\s+//g;
            $ver =~ s/;//g;
            $ver =~ s/[a-zA-Z]+//g;
            $ver =~ s/"//g;
            $ver =~ s/'//g;

            if (! defined eval { version->parse($ver); 1 }) {
                warn("$_: Can't find a valid version\n");
                return undef;
            }

            return $ver;
        }
    }
    else {
        warn("$_: Can't find a \$VERSION definition\n");
    }
    return undef;
}
sub _module_extract_file_version_line {
    # Extracts the $VERSION definition line from a module file

    my ($module_file) = @_;

    my $doc = PPI::Document->new($module_file);

    my $token = $doc->find(
        sub {
            $_[1]->isa("PPI::Statement::Variable")
                and $_[1]->content =~ /\$VERSION/;
        }
    );

    return undef if ref $token ne 'ARRAY';

    my $version_line = $token->[0]->content;

    return $version_line;
}
sub _module_fetch_file_contents {
    # Fetches the file contents of a module file

    my ($file) = @_;

    open my $fh, '<', $file
      or croak("Can't open file '$file' for reading!: $!");

    my @contents = <$fh>;
    close $fh;
    return @contents;
}
sub _module_find_files {
    # Finds module files

    my ($fs_entry, $module) = @_;

    $fs_entry //= DEFAULT_DIR;

    if (defined $module) {
        $module =~ s/::/\//g;
        $module .= '.pm';
    }
    else {
        $module = '*.pm';
    }


    return File::Find::Rule->file()
        ->name($module)
        ->in($fs_entry);
}
sub _module_insert_ci_badges {
    # Inserts the CI and Coveralls badges into POD

    my ($author, $repo, $module_file) = @_;

    my ($mf, $tie) = _module_tie($module_file);

    return -1 if grep /badge\.svg/, @$mf;

    for (0..$#$mf) {
        if ($mf->[$_] =~ /^=head1 NAME/) {
            splice @$mf, $_+3, 0, _module_section_ci_badges($author, $repo);
            last;
        }
    }
    untie $tie;

    return 0;
}
sub _module_tie {
    # Ties a module file to an array

    my ($mod_file) = @_;
    croak("Acme-STEVEB() needs a module file name sent in") if ! defined $mod_file;

    my $tie = tie my @mf, 'Tie::File', $mod_file;
    return (\@mf, $tie);
}
sub _module_write_file {
    # Writes out a Perl module file

    my ($module_file, $content) = @_;

    open my $wfh, '>', $module_file or croak("Can't open '$module_file' for writing!: $!");

    print $wfh $content;

    close $wfh or croak("Can't close the temporary memory module file!: $!");
}
sub _module_write_template {
    # Writes out our custom module template after init()

    my ($module_file, $module, $author, $email) = @_;

    if (! defined $module_file) {
        croak("_module_write_template() needs the module's file name sent in");
    }

    if (! defined $module || ! defined $author || ! defined $email) {
        croak("_module_template_file() requires 'module', 'author' and 'email' parameters");
    }

    my @content = _module_template_file($module, $author, $email);

    open my $wfh, '>', $module_file or croak("Can't open '$module_file' for writing!: $!");

    print $wfh "$_\n" for @content;
}

# POD related

sub _pod_extract_file_copyright {
    # Extracts the copyright year from POD

    my ($module_file) = @_;

    my $copyright_line = _pod_extract_file_copyright_line($module_file);

    if (defined $copyright_line) {
        if ($copyright_line =~ /^Copyright\s+(\d{4})\s+\w+/) {
            return $1;
        }
    }
    else {
        warn("$_: Can't find a Copyright definition\n");
    }
    return undef;
}
sub _pod_extract_file_copyright_line {
    # Extracts the Copyright line from a module file

    my ($pod_file) = @_;

    open my $fh, '<', $pod_file or croak("Can't open POD file $pod_file: $!");

    while (<$fh>) {
        if (/^Copyright\s+\d{4}\s+\w+/) {
            return $_;
        }
    }
}
sub _pod_find_files {
    # Finds POD files

    my ($fs_entry) = @_;

    $fs_entry //= DEFAULT_POD_DIR;

    return File::Find::Rule->file()
        ->name('*.pod', '*.pm', '*.pl')
        ->in($fs_entry);
}
sub _pod_tie {
    # Ties a POD file to an array

    my ($pod_file) = @_;
    croak("_pod_tie() needs a POD file name sent in") if ! defined $pod_file;

    my $tie = tie my @pf, 'Tie::File', $pod_file;
    return (\@pf, $tie);
}

# Validation related

sub _dist_dir_re {
    # Capture permutations of the distribution directory for various
    # CPAN testers
    # Use YAPE::Regex::Explain for details

    return qr/dist-mgr(?:-\d+\.\d+)?(?:-\w+)?$/i;
}
sub _validate_git {
    my $sep = $^O =~ /win32/i ? ';' : ':';
    return grep {-x "$_/git" } split /$sep/, $ENV{PATH};
}
sub _validate_fs_entry {
    # Validates a file system entry as valid

    my ($fs_entry) = @_;

    cluck("Need name of dir or file!") if ! defined $fs_entry;

    return FSTYPE_IS_DIR    if -d $fs_entry;
    return FSTYPE_IS_FILE   if -f $fs_entry;

    croak("File system entry '$fs_entry' is invalid");
}
sub _validate_version {
    # Parses a version number to ensure it is valid

    my ($version) = @_;

    croak("version parameter must be supplied!") if ! defined $version;

    if (! defined eval { version->parse($version); 1 }) {
        croak("The version number '$version' specified is invalid");
    }
}

# Miscellaneous

sub _export_private {
    push @EXPORT_OK, @EXPORT_PRIVATE;
    return \@EXPORT_OK;
}
sub __placeholder {}

1;
__END__

=head1 AUTHOR

Steve Bertrand, C<< <steveb at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2021 Steve Bertrand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

