package DhMakePerl::Command::make;

use warnings;
use strict;
our $VERSION = '0.84';
use 5.010;    # we use smart matching

use base 'DhMakePerl::Command::Packaging';
use DhMakePerl::Utils qw(apt_cache);

__PACKAGE__->mk_accessors(
    qw(
        cfg apt_contents main_dir debian_dir meta
        perlname version pkgversion
        copyright author
        extrasfields  extrapfields
        docs examples
        )
);

=head1 NAME

DhMakePerl::Command::make - implementation of 'dh-make-perl make'

=cut

=head1 SYNOPSIS

TO BE FILLED

    use DhMakePerl;

    my $foo = DhMakePerl->new();
    ...

=head1 METHODS

=over

=cut

use CPAN ();
use Cwd qw( realpath );
use Debian::Dependencies      ();
use Debian::Dependency        ();
use Debian::WNPP::Query;
use DhMakePerl::Utils qw(
    find_cpan_module find_cpan_distribution
    is_core_module );
use Email::Date::Format qw(email_date);
use File::Basename qw( basename dirname );
use File::Copy qw( copy move );
use File::Path ();
use File::Spec::Functions qw( catdir catfile updir );
use Module::Depends            ();
use Module::Metadata;
use Text::Wrap qw( wrap );

sub check_deprecated_overrides {
    my $self = shift;

    my $overrides = catfile( $self->cfg->data_dir, 'overrides' );

    if ( -e $overrides ) {
        warn "*** deprecated overrides file ignored\n";
        warn "***\n";
        warn "*** Overrides mechanism is deprecated in dh-make-perl 0.65\n";
        warn "*** You may want to remove $overrides\n";
    }
}

sub execute {
    my ( $self, $already_done ) = @_;

    die "CPANPLUS support disabled, sorry" if $self->cfg->cpanplus;

    $self->check_deprecated_overrides;

    my $tarball = $self->setup_dir();
    $self->process_meta;
    $self->findbin_fix();

    $self->extract_basic();

    $tarball //= $self->guess_debian_tarball if $self->cfg->{vcs} eq 'git';

    unless ( defined $self->cfg->version ) {
        $self->pkgversion( $self->version . '-1' );
    }
    else {
        $self->pkgversion( $self->cfg->version );
    }

    $self->fill_maintainer;

    my $bin = $self->control->binary_tie->Values(0);
    $bin->short_description( $self->cfg->desc )
        if $self->cfg->desc;

    if ( $tarball and $tarball =~ /(?:\.tar\.gz|\.tgz)$/ ) {
        my $dest = sprintf( "%s/%s_%s.orig.tar.gz",
            dirname($tarball), $self->pkgname, $self->version );

        move( $tarball, $dest ) or die "move($tarball, $dest): $!";

        $tarball = $dest;
    }

    # Here I init the git repo. If the upstream has a debian/ directory, this is
    # removed in a separate git commit
    $self->git_import_upstream__init_debian
        if $self->cfg->{vcs} eq 'git';

    # if the upstream has a debian/ directory, rename it to debian.bak so that
    # dh-make-perl can create its own debian/ directory. If we're creating a git
    # repo, the original debian/ directory was already dealt with by
    # git_import_upstream__init_debian()
    if ( -d $self->debian_dir ) {
        $self->warning( $self->debian_dir . ' already exists' );
        my $bak = $self->debian_dir . '.bak';
        $self->warning( "moving to $bak" );
        if ( -d $bak ) {
            $self->warning("overwriting existing $bak");
            File::Path::rmtree($bak);
        }
        rename $self->debian_dir, $bak or die $!;
    }

    my $apt_contents = $self->get_apt_contents;
    my $src = $self->control->source;

    $src->Testsuite('autopkgtest-pkg-perl') if $self->cfg->{pkg_perl};

    my @missing = $self->discover_dependencies;

    $bin->Depends->add( $self->cfg->depends )
        if $self->cfg->depends;

    $src->Build_Depends->add( $self->cfg->bdepends )
        if $self->cfg->bdepends;

    $src->Build_Depends_Indep->add( $self->cfg->bdependsi )
        if $self->cfg->bdependsi;

    $self->extract_docs;
    $self->extract_examples;

    die "Cannot find a description for the package: use the --desc switch\n"
        unless $bin->short_description;

    print "Package does not provide a long description - ",
        " Please fill it in manually.\n"
        if ( !defined $bin->long_description
        or $bin->long_description =~ /^\s*\.?\s*$/ )
        and $self->cfg->verbose;

    printf( "Using maintainer: %s\n", $src->Maintainer )
        if $self->cfg->verbose;

    print "Found docs: @{ $self->docs }\n" if $self->cfg->verbose;
    print "Found examples: @{ $self->examples }\n"
        if @{ $self->examples } and $self->cfg->verbose;

    # start writing out the data
    mkdir( $self->debian_dir, 0755 )
        || die "Cannot create " . $self->debian_dir . " dir: $!\n";
    $self->write_source_format(
        catfile( $self->debian_dir, 'source', 'format' ) );
    $self->create_changelog( $self->debian_file('changelog'),
        $self->cfg->closes // $self->get_wnpp( $self->pkgname ) );
    $self->create_rules;

    # now that rules are there, see if we need some dependency for them
    $self->discover_utility_deps( $self->control );
    $self->control->prune_perl_deps;
    $self->prune_deps;
    $src->Standards_Version( $self->debstdversion );
    $src->Homepage( $self->upsurl );
    if ( $self->cfg->pkg_perl ) {
        my $vcs = lc( $self->cfg->vcs );
        if ( $vcs eq 'svn' ) {
            $self->control->source->Vcs_Svn(
                sprintf( "svn://svn.debian.org/pkg-perl/trunk/%s/",
                    $self->pkgname )
            );
            $self->control->source->Vcs_Browser(
                sprintf( "http://anonscm.debian.org/viewvc/pkg-perl/trunk/%s/",
                    $self->pkgname )
            );
        }
        elsif ( $vcs eq 'git' ) {
            $self->control->source->Vcs_Git(
                sprintf( "git://anonscm.debian.org/pkg-perl/packages/%s.git",
                    $self->pkgname )
            );
            $self->control->source->Vcs_Browser(
                sprintf( "https://anonscm.debian.org/cgit/pkg-perl/packages/%s.git",
                    $self->pkgname )
            );
        }
        else {
            warn "Version control system '$vcs' not known. Please submit a patch :)\n";
        }
    }
    $self->control->write( $self->debian_file('control') );

    $self->create_compat( $self->debian_file('compat') );
    $self->create_watch( $self->debian_file('watch') );

    #create_readme("$debiandir/README.Debian");
    $self->create_copyright( $self->debian_file('copyright') );
    $self->update_file_list( docs => $self->docs, examples => $self->examples );

    $self->create_upstream_metadata;

    if ( $self->cfg->recursive ) {
        $already_done //= {};
        my $mod_name = $self->perlname;
        $mod_name =~ s/-/::/g;
        $already_done->{$mod_name} = 1;

        for my $m (@missing) {
            next if exists $already_done->{$m};

            if ( $self->cfg->verbose ) {
                print "\n";
                print "==================================\n";
                print "  recursively building $m\n";
                print "==================================\n";
            }

            my $new_cfg
                = DhMakePerl::Config->new( { %{ $self->cfg }, cpan => $m, } );
            my $maker = $self->new( { cfg => $new_cfg } );
            $maker->execute($already_done)
        }
    }

    $self->git_add_debian($tarball)
        if $self->cfg->{vcs} eq 'git';

    $self->build_source_package
        if $self->cfg->build_source;
    $self->build_package
        if $self->cfg->build or $self->cfg->install;
    $self->install_package if $self->cfg->install;
    print "--- Done\n" if $self->cfg->verbose;

    $self->package_already_exists($apt_contents)
        or $self->modules_already_packaged($apt_contents);

    # explicitly call Debian::Rules destroy
    # this is needed because after the rename the object's
    # destroy method would update a file on a stale path
    $self->rules( undef );
    $self->rename_to_debian_package_dir;

    return(0);
}

sub guess_debian_tarball {
    my $self = shift;

    my $prefix = catfile( $self->main_dir, '..',
                          $self->control->source->Source . '_'
                          . $self->version
                          . '.orig' );
    $self->guess_tarball($prefix);
}

sub guess_tarball {
    my $self = shift;
    my $prefix = shift;
    die "guess_tarball(): Needs everything except the file type suffix as parameter"
        unless defined $prefix;

    foreach my $compression_suffix (qw(gz bz2 xz lzma)) {
        my $try = "$prefix.tar.$compression_suffix";

        print "Trying $try...";
        if ( -f $try ) {
            print " found!\n";
            return $try;
        }
        else {
            print " not found.\n";
        }
    }
    return undef;
}

sub setup_dir {
    my ($self) = @_;

    my ( $tarball );
    if ( $self->cfg->cpan ) {
        my ( $new_maindir, $orig_pwd, $mod, $dist );

        # CPAN::Distribution::get() sets $ENV{'PWD'} to $CPAN::Config->{build_dir}
        # so we have to save it here
        $orig_pwd = $ENV{'PWD'};

        # Is the module a core module?
       if ( is_core_module( $self->cfg->cpan ) ) {
            die $self->cfg->cpan
            . " is a standard module. Will not build without --core-ok.\n"
                unless $self->cfg->core_ok;
        }

        $self->configure_cpan;

        if ( $mod = find_cpan_module( $self->cfg->cpan ) ) {
            $self->mod_cpan_version( $mod->cpan_version );

            $dist = $CPAN::META->instance( 'CPAN::Distribution',
                $mod->cpan_file );
        }
        elsif ( $dist = find_cpan_distribution( $self->cfg->cpan ) ) {
            my $ver;
            if ( $dist->base_id =~ /-v?(\d[\d._]*)\./ ) {
                $self->mod_cpan_version($1);
            }
            else {
                die "Unable to determine the version of "
                    . $dist->base_id . "\n";
            }
        }
        else {
            die "Can't find '"
                . $self->cfg->cpan
                . "' module or distribution on CPAN\n";
        }

        $dist->get;     # <- here $ENV{'PWD'} gets set to $HOME/.cpan/build
        chdir $orig_pwd;   # so set it back
        $dist->pretty_id =~ /^(.)(.)/;
        $tarball = $CPAN::Config->{'keep_source_where'} . "/authors/id/$1/$1$2/";
        # the file is under authors/id/A/AU/AUTHOR directory
        # how silly there is no $dist->filename method

        $tarball .= $dist->pretty_id;
        $self->main_dir( $dist->dir );

        copy( $tarball, $orig_pwd ) or die "copy($tarball, $orig_pwd): $!";
        $tarball = $orig_pwd . "/" . basename($tarball);

        # build_dir contains a random part since 1.88_59
        # use the new CPAN::Distribution::base_id (introduced in 1.91_53)
        $new_maindir = $orig_pwd . "/" . $dist->base_id;

        # rename existing directory
        my $new_inc;
        my $rename_to = "$new_maindir.$$";
        while (-d $rename_to)
        {
            $new_inc++;
            $rename_to = "$new_maindir.$$-$new_inc";
        }
        if ( -d $new_maindir
            && rename $new_maindir, $rename_to)
        {
            print '=' x 70, "\n";
            print
                "Unpacked tarball already existed, directory renamed to $rename_to\n";
            print '=' x 70, "\n";
        }
        system( "mv", $self->main_dir, "$new_maindir" ) == 0
            or die "Failed to move " . $self->main_dir . " to $new_maindir: $!";
        $self->main_dir($new_maindir);

    }
    elsif ( $self->cfg->cpanplus ) {
        die "CPANPLUS support is b0rken at the moment.";

# 		my ($cb, $href, $file);

# 		eval "use CPANPLUS 0.045;";
# 		$cb = CPANPLUS::Backend->new(conf => {debug => 1, verbose => 1});
# 		$href = $cb->fetch( modules => [ $self->cfg->cpanplus ], fetchdir => $ENV{'PWD'});
# 		die "Cannot get " . $self->cfg->cpanplus . "\n" if keys(%$href) != 1;
# 		$file = (values %$href)[0];
# 		print $file, "\n\n";
# 		$self->main_dir(
# 		    $cb->extract( files => [ $file ], extractdir => $ENV{'PWD'} )->{$file}
# 		);
    }
    else {
        my $maindir = realpath( shift(@ARGV) || '.' );
        $maindir =~ s/\/$//;
        $self->main_dir($maindir);
        my $guessed_tarball_prefix = catfile( $self->main_dir, "..",
            basename( $self->main_dir ) );

        $tarball = $self->guess_tarball($guessed_tarball_prefix);
    }
    return $tarball;
}

sub build_package {
    my ( $self ) = @_;

    my $main_dir = $self->main_dir;
    # uhmf! dpkg-genchanges doesn't cope with the deb being in another dir..
    #system("dpkg-buildpackage -b -us -uc " . $self->cfg->dbflags) == 0
    system("fakeroot make -C $main_dir -f debian/rules clean");
    system("make -C $main_dir -f debian/rules build") == 0
        || die "Cannot create deb package: 'debian/rules build' failed.\n";
    system("fakeroot make -C $main_dir -f debian/rules binary") == 0
        || die "Cannot create deb package: 'fakeroot debian/rules binary' failed.\n";
}

sub build_source_package {
    my ( $self ) = @_;

    my $main_dir = $self->main_dir;
    # uhmf! dpkg-genchanges doesn't cope with the deb being in another dir..
    #system("dpkg-buildpackage -S -us -uc " . $self->cfg->dbflags) == 0
    system("fakeroot make -C $main_dir -f debian/rules clean");
    system("dpkg-source -b $main_dir") == 0
        || die "Cannot create source package: 'dpkg-source -b' failed.\n";
}

sub install_package {
    my ($self) = @_;

    my ( $archspec, $debname );

    my $arch = $self->control->binary_tie->Values(0)->Architecture;

    if ( !defined $arch || $arch eq 'any' ) {
        $archspec = `dpkg --print-architecture`;
        chomp($archspec);
    }
    else {
        $archspec = $arch;
    }

    $debname = sprintf( "%s_%s-1_%s.deb", $self->pkgname, $self->version,
        $archspec );

    my $deb = $self->main_dir . "/../$debname";
    my $dpkg_cmd = "dpkg -i $deb";
    $dpkg_cmd = "sudo $dpkg_cmd" if $>;
    $self->info("Running '$dpkg_cmd'...");
    system($dpkg_cmd) == 0
        || die "Cannot install package $deb\n";
}

sub findbin_fix {
    my ($self) = @_;

    # FindBin requires to know the name of the invoker - and requires it to be
    # Makefile.PL to function properly :-/
    $0 = $self->makefile_pl();
    if ( exists $FindBin::{Bin} ) {
        FindBin::again();
    }
}

# finds the list of modules that the distribution depends on
# if $build_deps is true, returns build-time dependencies, otherwise
# returns run-time dependencies
sub run_depends {
    my ( $self, $depends_module, $build_deps ) = @_;

    no warnings;
    local *STDERR;
    open( STDERR, ">/dev/null" );
    my $mod_dep = $depends_module->new();

    $mod_dep->dist_dir( $self->main_dir );
    $mod_dep->find_modules();

    my $deps = $build_deps ? $mod_dep->build_requires : $mod_dep->requires;

    my $error = $mod_dep->error();
    die "Error: $error\n" if $error;

    return $deps;
}

# filter @deps to contain only one instance of each package
# say we have te following list of dependencies:
#   libppi-perl, libppi-perl (>= 3.0), libarm-perl, libalpa-perl, libarm-perl (>= 2)
# we want a clean list instead:
#   libalpa-perl, libarm-perl (>= 2), libppi-perl (>= 3.0)
sub prune_deps(@) {
    my $self = shift;

    my %deps;
    for (@_) {
        my $p = $_->pkg;
        my $v = $_->ver;
        if ( exists $deps{$p} ) {
            my $cur_ver = $deps{$p};

            $deps{$p} = $v
                if defined($v)
                    and ( not defined($cur_ver)
                        or $cur_ver < $v );
        }
        else {
            $deps{$p} = $v;
        }

    }

    return map( Debian::Dependency->new( $_, $deps{$_} ), sort( keys(%deps) ) );
}

sub create_changelog {
    my ( $self, $file, $bug ) = @_;

    my $fh  = $self->_file_w($file);

    my $closes = $bug ? " (Closes: #$bug)" : '';
    my $changelog_dist = $self->cfg->pkg_perl ? "UNRELEASED" : "unstable";

    $fh->printf( "%s (%s) %s; urgency=low\n",
        $self->srcname, $self->pkgversion, $changelog_dist );
    $fh->print("\n  * Initial Release.$closes\n\n");
    $fh->printf( " -- %s  %s\n", $self->get_developer,
        email_date(time) );

    #$fh->print("Local variables:\nmode: debian-changelog\nEnd:\n");
    $fh->close;
}

sub create_readme {
    my ( $self, $filename ) = @_;

    my $fh = $self->_file_w($filename);
    $fh->printf(
        "This is the debian package for the %s module.
It was created by %s using dh-make-perl.
", $self->perlname, $self->maintainer,
    );
    $fh->close;
}

sub create_watch {
    my ( $self, $filename ) = @_;

    my $fh = $self->_file_w($filename);

    my $version_re = 'v?(\d[\d.-]*)\.(?:tar(?:\.gz|\.bz2)?|tgz|zip)';

    $fh->printf( "version=3\n%s   .*/%s-%s\$\n",
        $self->upsurl, $self->perlname, $version_re );
    $fh->close;
}

sub search_pkg_perl {
    my $self = shift;

    return undef unless $self->cfg->network;

    my $pkg = $self->pkgname;

    require LWP::UserAgent;
    require LWP::ConnCache;

    my ( $ua, $resp );

    $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua->conn_cache( LWP::ConnCache->new );

    $resp = $ua->get(
        "https://anonscm.debian.org/cgit/pkg-perl/packages/$pkg.git");
    return { url => $resp->request->uri }
        if $resp->is_success;

    $resp = $ua->get(
        "https://anonscm.debian.org/cgit/pkg-perl/attic/$pkg.git");
    return { url => $resp->request->uri }
        if $resp->is_success;

    return undef;
}

sub rename_to_debian_package_dir {
    my( $self ) = @_;
    return unless $self->cfg->cpan;

    my $maindir = $self->main_dir;
    my $newmaindir = catdir( $maindir, updir(), $self->pkgname );

    if( -d $newmaindir ) {
      warn "$newmaindir already exists, skipping rename";
      return;
    }

    rename $maindir, $newmaindir or die "rename failed: $self->main_dir to $newmaindir";
    $self->main_dir( $newmaindir );
    return;
}

sub package_already_exists {
    my( $self, $apt_contents ) = @_;

    my $found;
    if (my $apt_cache = apt_cache())
    {
        $found = $apt_cache->packages->lookup( $self->pkgname );
    }

    if ($found) {
        warn "**********\n";
        warn "WARNING: a package named\n";
        warn "              '" . $self->pkgname ."'\n";
        warn "         is already available in APT repositories\n";
        warn "Maintainer: ", $found->{Maintainer}, "\n";
        my $short_desc = (split( /\n/, $found->{LongDesc} ))[0];
        warn "Description: $short_desc\n";
    }
    elsif ($apt_contents) {
        $found = $apt_contents->find_perl_module_package( $self->perlname );

        if ($found) {
            ( my $mod_name = $self->perlname ) =~ s/-/::/g;
            warn "**********\n";
            warn "NOTICE: the package '$found', available in APT repositories\n";
            warn "        already contains a module named "
                . $self->perlname . "\n";
        }
        elsif ( $found = $self->search_pkg_perl ) {
            warn "********************\n";
            warn sprintf(
                "The Debian Perl Group has a repository for the %s package\n  at %s\n",
                $self->pkgname, $found->{url} );
            warn "You may want to contact them to avoid duplication of effort.\n";
            warn "More information is available at https://wiki.debian.org/Teams/DebianPerlGroup\n";
        }
    }
    else {
        ( my $mod_name = $self->perlname ) =~ s/-/::/g;
        require Debian::DpkgLists;
        my @found = Debian::DpkgLists->scan_perl_mod($mod_name);

        if (@found) {
            warn "**********\n";
            warn "NOTICE: the following locally installed package(s) already\n";
            warn "        contain $mod_name\n";
            warn "          ", join ( ', ', @found ), "\n";
            $found = 1;
        }
    }

    return $found ? 1 : 0;
}

sub modules_already_packaged {
    my( $self, $apt_contents ) = @_;

    my @modules;

    File::Find::find(
        sub {
            if (basename($File::Find::dir)
                =~ /^(?:
                    \.(?:git|svn|hg|)
                    |CVS
                    |eg|samples?|examples?
                    |t|xt
                    |inc|privinc
                    )$/x
                )
            {
                $File::Find::prune = 1;
                return;
            }
            if (/.+\.pm$/) {
                my $mi = Module::Metadata->new_from_file($_);
                push @modules, $mi->packages_inside;
            }
        },
        $self->main_dir,
    );

    my $found;

    sub show_notice($$) {
        warn $_[0] unless $_[1];
        $_[1] = 1;
    }

    my $notice = <<EOF;
*** Notice ***
Some of the modules in the newly created package are already present
in other packages.

EOF
    my $notice_shown = 0;

    for my $mod (@modules) {
        if ($apt_contents) {
            $found = $apt_contents->find_perl_module_package($mod);

            if ($found) {
                show_notice( $notice, $notice_shown );
                warn "  $mod is in '$found' (APT)\n";
            }
        }
        if ( !$found ) {
            require Debian::DpkgLists;
            my @found = Debian::DpkgLists->scan_perl_mod($mod);

            if (@found) {
                show_notice( $notice, $notice_shown );
                warn "  $mod is in " . join( ', ', @found ), " (local .deb)\n";
                $found = 1;
            }
        }
    }

    warn "\n" if $notice_shown;

    return $found ? 1 : 0;
}

sub reset_git_environment {
    # The Git environment variables may be set from previous iterations
    # of this program being run. In this case, it's possible that the
    # Git module will use these to point to the wrong source tree.
    delete $ENV{'GIT_DIR'};
    delete $ENV{'GIT_WORK_TREE'};
}

sub git_import_upstream__init_debian {
    my ( $self ) = @_;

    require Git;

    $self->reset_git_environment();

    Git::command( 'init', $self->main_dir );

    my $git = Git->repository( $self->main_dir );
    $git->command( qw(symbolic-ref HEAD refs/heads/upstream) );
    $git->command( 'add', '.' );
    $git->command( 'commit', '-m',
              "Import original source of "
            . $self->perlname . ' '
            . $self->version );
    $git->command( 'tag', "upstream/".$self->version, 'upstream' );

    $git->command( qw( checkout -b master upstream ) );
    if ( -d $self->debian_dir ) {
      # remove debian/ directory if the upstream ships it. This goes into the
      # 'master' branch, so the 'upstream' branch contains the original debian/
      # directory, and thus matches the pristine-tar. Here I also remove the
      # debian/ directory from the working tree; git has the history, so I don't
      # need the debian.bak
      $git->command( 'rm', '-r', $self->debian_dir );
      $git->command( 'commit', '-m',
                     'Removed debian directory embedded in upstream source' );
    }
}

sub git_add_debian {
    my ( $self, $tarball ) = @_;

    require Git;
    require File::Which;

    $self->reset_git_environment;

    my $git = Git->repository( $self->main_dir );
    $git->command( 'add', 'debian' );
    $git->command( 'commit', '-m',
        "Initial packaging by dh-make-perl $VERSION" );
    $git->command(
        qw( remote add origin ),
        sprintf( "ssh://git.debian.org/git/pkg-perl/packages/%s.git",
            $self->pkgname ),
    ) if $self->cfg->pkg_perl;

    if ( File::Which::which('pristine-tar') ) {
        if ( $tarball and -f $tarball ) {
            $ENV{GIT_DIR} = File::Spec->catdir( $self->main_dir, '.git' );
            system( 'pristine-tar', 'commit', $tarball, "upstream/".$self->version ) >= 0
                or warn "error running pristine-tar: $!\n";
        }
        else {
            die "No tarball found to handle with pristine-tar. Bailing out."
        }
    }
    else {
        warn "W: pristine-tar not available. Please run\n";
        warn "W:     apt-get install pristine-tar\n";
        warn "W:  followed by\n";
        warn "W:     pristine-tar commit $tarball upstream/"
            . $self->version . "\n";
    }
}

=item warning I<string> ...

In verbose mode, prints supplied arguments on STDERR, prepended with C<W: > and
suffixed with a new line.

Does nothing in non-verbose mode.

=cut

sub warning {
    my $self = shift;

    return unless $self->cfg->verbose;

    warn "W: ", @_, "\n";
}

=item info I<string> ...

In verbose mode, prints supplied arguments on STDERR, prepended with C<I: > and
suffixed with a new line.

Does nothing in non-verbose mode.

=cut

sub info {
    my $self = shift;

    return unless $self->cfg->verbose;

    warn "I: ", @_, "\n";
}

=back

=head1 AUTHOR

dh-make-perl was created by Paolo Molaro.

It is currently maintained by Gunnar Wolf and others, under the umbrella of the
Debian Perl Group <debian-perl@lists.debian.org>

=head1 BUGS

Please report any bugs or feature requests to the Debian Bug Tracking System
(L<http://bugs.debian.org/>, use I<dh-make-perl> as package name) or to the
L<debian-perl@lists.debian.org> mailing list.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DhMakePerl

You can also look for information at:

=over 4

=item * Debian Bugtracking System

L<http://bugs.debian.org/dh-make-perl>

=back



=head1 COPYRIGHT & LICENSE

=over 4

=item Copyright (C) 2000, 2001 Paolo Molaro <lupus@debian.org>

=item Copyright (C) 2002, 2003, 2008 Ivan Kohler <ivan-debian@420.am>

=item Copyright (C) 2003, 2004 Marc 'HE' Brockschmidt <he@debian.org>

=item Copyright (C) 2005-2007 Gunnar Wolf <gwolf@debian.org>

=item Copyright (C) 2006 Frank Lichtenheld <djpig@debian.org>

=item Copyright (C) 2007-2014 Gregor Herrmann <gregoa@debian.org>

=item Copyright (C) 2007,2008,2009,2010,2011,2012,2015 Damyan Ivanov <dmn@debian.org>

=item Copyright (C) 2008, Roberto C. Sanchez <roberto@connexer.com>

=item Copyright (C) 2009-2010, Salvatore Bonaccorso <carnil@debian.org>

=item Copyright (C) 2013, Axel Beckert <abe@debian.org>

=back

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

1; # End of DhMakePerl
