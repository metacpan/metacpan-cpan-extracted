package LedgerSMB::Installer v0.999.1;

use v5.20;
use experimental qw(signatures);

use Carp qw( croak );
use CPAN::Meta::Requirements;
use English;
use File::Path qw( make_path remove_tree );
use File::Spec;
use File::Temp qw( tempfile );
use Getopt::Long qw(GetOptionsFromArray);
use HTTP::Tiny;
use IO::Handle;
use JSON::PP;
use List::Util qw(uniq);
use Module::CoreList;
use version;

use Log::Any qw($log);
use Log::Any::Adapter;
use Module::CPANfile;

use LedgerSMB::Installer::Configuration;

my $INSTALLER_VERSION = 'version CLONED'; # not intended to be the module version

my $http = HTTP::Tiny->new( agent => 'LedgerSMB-Installer/0.1' );
my $json = JSON::PP->new->canonical;

sub _post_boot_configure($class, $dss, $config) {
    Log::Any::Adapter->set('Stdout', log_level => $config->loglevel);
}

sub _boot($class, $args, $options) {
    my $dss = $class->_load_dist_support;
    my $config = LedgerSMB::Installer::Configuration->new(
        sys_pkgs => ($EFFECTIVE_USER_ID == 0)
        );

    GetOptionsFromArray(
        $args,
        $config->option_callbacks( $options ),
        );

    # normalize $installpath (at least cpanm needs that)
    # assume $locallib to be inside $installpath
    $config->normalize_paths;

    $class->_post_boot_configure( $dss, $config );
    return ($dss, $config);
}

sub _build_install_tree($class, $dss, $config, $installpath, $version) {
    my $archive = "ledgersmb-$version.tar.gz";

    $log->info( "Creating installation path $installpath" );
    make_path( $installpath ); # croaks on fatal errors

    $log->info( "Downloading release tarball $archive" );
    $class->_download( $installpath, $version );

    #$log->info( "Verifying tarball against gpg public key & signature" );
    #$dss->verify_gpg( \@cmds, $archive )
    #    if $verify;

    $log->info( "Extracting release tarball" );
    $dss->untar( File::Spec->catfile( $installpath, $archive),
                 $installpath,
                 strip_components => 1 );
    $config->cpanfile( File::Spec->catfile( $installpath, 'cpanfile' ) );

    $log->info( "Removing extracted release tarball" );
    remove_tree(               # croaks on fatal errors
        map {
            File::Spec->catfile( $installpath, $_ )
        } ( $archive, "$archive.asc" ) );
}

sub _get_cpanfile($class, $config) {
    return $config->cpanfile if $config->cpanfile;

    my $response = $http->get(
        sprintf("https://raw.githubusercontent.com/ledgersmb/LedgerSMB/refs/tags/%s/cpanfile",
               $config->effective_version)
        );
    unless ($response->{success}) {
        die $log->fatal("Unable to get 'cpanfile' from GitHub: $response->{content}");
    }

    my ($fh, $fn) = tempfile();
    print $fh $response->{content};
    $fh->flush;

    my $decl = Module::CPANfile->load( $fn );
    $config->cpanfile( $decl );

    return $decl;
}

sub _get_immediate_prereqs($class, $config) {
    my $decl = $class->_get_cpanfile( $config );
    return $decl->prereqs;
}

sub _compute_immediate_deps($class, $config) {
    my @types     = qw( requires recommends );
    my @phases    = qw( runtime );
    my $decl      = $class->_get_cpanfile( $config );
    my $prereqs   = $decl->prereqs_with( map { $_->identifier } $decl->features ); # all features
    my $effective = CPAN::Meta::Requirements->new;
    for my $phase (@phases) {
        for my $type (@types) {
            $effective->add_requirements( $prereqs->requirements_for( $phase, $type ) );
        }
    }

    my @mods = sort { lc($a) cmp lc($b) } $effective->required_modules;

    $log->debug( "Direct dependency count: " . scalar(@mods) );
    return @mods;
}

sub _compute_all_deps($class, $config) {
    my @deps = $class->_compute_immediate_deps( $config );

    my @last_deps = @deps;
    my %dists;
    my $iteration = 1;
    do {
        my $query = {
            query => { match_all => {} },
            _source => [ qw( release distribution status provides ), 'dependency.*' ],
            filter => {
                and => [
                    { term => { status => 'latest' } },
                    { terms => { provides => [ @last_deps ] } }
                    ]
            }
        };

        my $body = $json->encode( $query );
        my $r = $http->request( 'POST', 'https://fastapi.metacpan.org/v1/release/_search?size=1000',
                                { headers => { 'Content-Type' => 'application/json' },
                                  content => $body });
        my $hits = $json->decode($r->{content})->{hits};

        for my $release ($hits->{hits}->@*) {
            $dists{$release->{_source}->{distribution}} = 1;
        }

        my %provide;
        for my $release ($hits->{hits}->@*) {
            for my $provided ($release->{_source}->{provides}->@*) {
                $provide{$provided} = 1;
            }
        }

        my %rdeps;
        for my $release ($hits->{hits}->@*) {
            for my $dep ($release->{_source}->{dependency}->@*) {
                next unless $dep->{relationship} eq 'requires';
                next unless $dep->{phase} eq 'runtime';
                $rdeps{$dep->{module}} = 1;
            }
        }

        delete $rdeps{perl};
        @last_deps = sort grep {
            my $m = $_;
            my $c = Module::CoreList->is_core($m);

            not ($provide{$m} or $c);
        } keys %rdeps;
        push @deps, @last_deps;

        $log->trace( "Dependency resolution iteration $iteration - "
                     . "remaining to resolve: " . scalar(@last_deps) );
        $iteration++;
    } while (@last_deps);

    @deps = uniq @deps;
    $log->debug( "Dependency tree size: " . scalar(@deps) );
    return uniq @deps;
}

sub _compute_dep_pkgs($class, $dss, $config ) {
    my @mods = $class->_compute_all_deps( $config );

    # the array passed in gets modified; copy @mods so we still have it below
    my ($pkgs, $unmapped) = $dss->pkgs_from_modules( [ @mods ] );

    my $c = scalar(@mods);
    my $p = scalar(keys $pkgs->%*);
    my $u = scalar($unmapped->@*);
    $log->debug( "Resolved $c modules to $p packages; $u unmapped" );
    return ([ sort keys $pkgs->%* ], $unmapped);
}

sub _download($class, $installpath, $version) {
    my $fn   = "ledgersmb-$version.tar.gz";
    my $url  = $ENV{ARTIFACT_LOCATION} // "https://download.ledgersmb.org/f/Releases/$version/";
    my $http = HTTP::Tiny->new;

    do {
        open( my $fh, '>', File::Spec->catfile($installpath, $fn))
            or croak $log->fatal( "Unable to open output file $fn: $!" );
        binmode $fh, ':raw';
        my $r = $http->get(
            "$url$fn",
            {
                data_callback => sub($data, $status) {
                    print $fh $data;
                }
            });

        if ($r->{status} == 599) {
            croak $log->fatal( "Unable to request $url/$fn: " . $r->{content} );
        }
        elsif (not $r->{success}) {
            croak $log->fatal( "Unable to request $url/$fn: $r->{status} - $r->{reason}" );
        }
    };

    do {
        my $r = $http->get( "$url$fn.asc" );
        if ($r->{status} == 599) {
            croak $log->fatal( "Unable to request $url/$fn: " . $r->{content} );
        }
        elsif (not $r->{success}) {
            croak $log->fatal( "Unable to request $url/$fn: $r->{status} - $r->{reason}" );
        }
        else {
            open( my $fh, '>', File::Spec->catfile($installpath, "$fn.asc"))
                or croak $log->fatal( "Unable to open output file $fn.asc: $!" );
            binmode $fh, ':raw';
            print $fh $r->{content};
        }
    };
}

sub _find_executable($class, $dss, $executable, $dirs) {
    while (my $dir = shift $dirs->@*) {
        my $exe = File::Spec->catfile( $dir, $dss->executable_name( $executable ) );
        $log->trace( "Found $executable: $exe; but not executable" )
            if -e $exe and not -x $exe;
        my $rv = -x $exe ? $exe : '';

        if ($rv) {
            $log->debug( "Searching for $executable; found $exe" );
            return $rv;
        }
    }
    return undef;
}

# This function is borrowed from App::Info::RDBMS::PostgreSQL v0.57
# because that is what DBD::Pg uses to identify where pg_config lives
sub _search_bin_dirs($class) {
    return (( exists $ENV{POSTGRES_HOME}
          ? (File::Spec->catdir($ENV{POSTGRES_HOME}, "bin"))
          : ()
      ),
      ( exists $ENV{POSTGRES_LIB}
          ? (File::Spec->catdir($ENV{POSTGRES_LIB}, File::Spec->updir, "bin"))
          : ()
      ),
      File::Spec->path,
      qw(/usr/local/pgsql/bin
         /usr/local/postgres/bin
         /usr/lib/postgresql/bin
         /opt/pgsql/bin
         /usr/local/bin
         /usr/local/sbin
         /usr/bin
         /usr/sbin
         /bin),
      'C:\Program Files\PostgreSQL\bin');
}
# end of borrowed code

sub _find_pg_config($class, $dss, $config) {
    my @dirs = $class->_search_bin_dirs;

    # TODO: Check for pg_config in $config

    return $class->_find_executable( $dss, 'pg_config', \@dirs );
}

sub _find_xml2_config($class, $dss, $config) {
    return $class->_find_executable( $dss, 'xml2-config', [ File::Spec->path ] );
}

sub _find_latex($class, $dss, $config) {
    return $class->_find_executable( $dss, 'latex', [ File::Spec->path ] );
}


# mapping taken from File::Spec
my %module = (
    MSWin32 => 'win32',
    os2     => 'os2',
    VMS     => 'vms',
    NetWare => 'win32',
    symbian => 'win32',
    dos     => 'os2',
    cygwin  => 'cygwin',
    amigaos => 'amigaos',
    linux   => 'linux'    # not mapped in File::Spec
    );

sub _get_os($class) {
    return $module{$^O} || 'unix';
}

sub _load_dist_support($class) {
    my $OS = $class->_get_os;

    $log->info( "Detected O/S: $OS" );
    my $oss_class = "LedgerSMB::Installer::OS::$OS";

    local $@ = undef;
    unless (eval "require $oss_class") {
        say "Unable to load $oss_class: $@";
        say "No support for $OS";
        exit 2;
    }

    my $oss = $oss_class->new; # operating system support instance
    $log->debug( "Detecting distribution" );
    return $oss->detect_dss; # detect and return distribution support instance
}

sub compute($class, @args) {
    my ($dss, $config) = $class->_boot(
        \@args,
        [ 'yes|y!', 'target=s', 'local-lib=s', 'log-level=s' ]
        );
    my $version = shift @args;

    $config->compute_deps( 1 );
    $config->version( $version ) if defined $version;

    if (@args != 1) {
        die "Incorrect number of arguments";
    }
    my $deps_outfile = $args[0];
    open( my $out, '>:raw', $deps_outfile )
        or die "Unable to open output file '$deps_outfile': $!";


    unless ($dss->am_system_perl) {
        close( $out ) or warn $log->warn( "Unable to close output file" );
        unlink $deps_outfile;
        die $log->fatal( "Not running the system perl; not able to re-use system packages" );
    }

    ###TODO: _get_immediate_prereqs may throw
    my $prereqs = $class->_get_immediate_prereqs( $config );
    my $requirements = $prereqs->merged_requirements();
    unless  ($requirements->accepts_module( 'perl', $])) {
        close( $out ) or warn $log->warn( "Unable to close output file" );
        unlink $deps_outfile;
        my $perl_version = version->parse( $] )->normal;
        die $log->fatal( "Perl version ($perl_version) not compliant with LedgerSMB " . $config->effective_version
                         . "; requires: " . $requirements->requirements_for_module( 'perl' ));
    }

    ###TODO: prepare_pkg_resolver_env may throw
    if ($config->effective_prepare_env) {
        $dss->prepare_pkg_resolver_env( $config );
    }
    my $exception;
    do {
        local $@ = undef;
        my $failed = not eval {
            $log->info( "Computing O/S packages for declared dependencies" );
            my ($deps, $mods) = $class->_compute_dep_pkgs( $dss, $config );

            say $out $json->encode( { identifier => $dss->dependency_packages_identifier,
                                      packages => $deps,
                                      modules => $mods,
                                      name => $dss->name,
                                      'schema-version' => "1" } );

            return 1;
        };
        $exception = $@ if $failed;

        $log->info( "Dependencies written to $deps_outfile" );
        if ($config->effective_uninstall_env) {
            $log->warning( "Cleaning up Perl module installation dependencies" );
            $dss->cleanup_env($config);
        }
    };
    die $exception if defined $exception;

    return 0;
}

sub download($class, @args) {
}

sub help($class, @args) {
    my $help_text = do {
        local $/ = undef;
        <DATA>;
    };
    $help_text =~ s/\bSCRIPT\b/$0/g;
    say $help_text;

    return 0;
}

sub _module_will_install($class, $mod, $pkgs, $unmapped) {
    # no packages will be installed:
    return 0 if ((not $pkgs) or (not $pkgs->@*));

    # package in the list of those not installed through a package:
    return 0 if (grep { $mod eq $_ } $unmapped->@*);

    # package must be in one of the packages being installed
    return 1;
}

sub install($class, @args) {
    my $rv = 1;
    my ($dss, $config) = $class->_boot(
        \@args,
        [ 'yes|y!', 'system-packages!', 'prepare-env!', 'target=s',
          'local-lib=s', 'log-level=s', 'verify-sig!' ]
        );
    my $version = shift @args;
    $config->version( $version ) if defined $version;

    my ($pkg_deps, $unmapped_mods);
    my @extra_pkgs;
    if ($dss->am_system_perl) {
        my $name = $dss->name;
        my $dep_pkg_id = $dss->dependency_packages_identifier;
        if ($config->sys_pkgs) {
            ($pkg_deps, $unmapped_mods) = $config->retrieve_precomputed_deps($name, $dep_pkg_id);
        }
        if ($pkg_deps) {
            if ($dss->pkg_can_install()) {
                if ($config->effective_prepare_env) {
                    $dss->prepare_builder_env( $config );
                }
                goto INSTALL_SYS_PKGS;
            }
            else {
                $log->warn( "Unable to install system packages; will resort to installation of CPAN modules" );
                $pkg_deps = undef;
            }
        }
        else {
            $log->warn( "No precomputed dependencies available for $name/$dep_pkg_id" );
            $log->info( "Configuring environment for dependency computation" );
        }
    }

    my $prereqs = $class->_get_immediate_prereqs( $config );
    my $requirements = $prereqs->merged_requirements();


    unless  ($requirements->accepts_module( 'perl', $])) {
        # BAIL: No suitable Perl here...
        #
        # well, we might want to see if Perlbrew is installed with an acceptable version?
        #
        # and if not, we could install Perlbrew here...
        die $log->fatal( "Not running a Perl version compliant with LedgerSMB " . $config->effective_version );
    }


    ########################################################################################
    #
    #  Need to clean up on failure after this point! We're about to change system state!
    #
    ########################################################################################
    if ($config->effective_prepare_env) {
        $dss->prepare_builder_env( $config );
    }

    if ($dss->am_system_perl and $dss->pkg_can_install) {  # and $dss->deps_can_map
        if ($config->effective_prepare_env) {
            $dss->prepare_pkg_resolver_env( $config );
        }
        ($pkg_deps, $unmapped_mods) = $class->_compute_dep_pkgs( $dss, $config );
    }
    else {
        $unmapped_mods = [ $class->_compute_all_deps( $config ) ];
    }

    $log->info( "Checking for availability of DBD::Pg" );
    if (not eval { require DBD::Pg; 1; } # not loadable, and
        and not $class->_module_will_install( 'DBD::Pg', $pkg_deps, $unmapped_mods )) {
        # don't have DBD::Pg
        # *and* won't install as part of $pkg_deps

        my $pg_config = $class->_find_pg_config( $dss, $config );
        die $log->fatal( "Missing 'pg_config' command to build DBD::Pg" )
            unless $pg_config;
        chomp( my $include_dir = `'$pg_config' --includedir` );

        $log->debug( "Directory for PostgreSQL headers: $include_dir" );
        my $header_file = File::Spec->catfile( $include_dir, 'libpq-fe.h' );

        if (not -e $header_file) {
            if (not $dss->pkg_can_install) {
                die $log->fatal( "Missing 'libpq-fe.h' PostgreSQL header to build DBD::Pg" );
            }

            my ($run_deps, $build_deps) = $dss->pkg_deps_dbd_pg;
            $config->mark_pkgs_for_cleanup( $build_deps );
            push @extra_pkgs, $run_deps->@*, $build_deps->@*;
        }
    }
    elsif (eval { require DBD::Pg; 1; }) {
        $log->info( "DBD::Pg is loadable" );
    }
    elsif (not grep { $_ eq 'DBD::Pg' } $unmapped_mods->@*) {
        $log->info( "DBD::Pg will be installed" );
    }
    else {
        $log->fatal( "Internal error: DBD::Pg not available and won't be installed, but build prereqs not checked?!?!" );
    }

    $log->info( "Checking for availability of LaTeX::Driver" );
    if (not eval { require LaTeX::Driver; 1; } # loadable, and
        and not $class->_module_will_install( 'LaTeX::Driver', $pkg_deps, $unmapped_mods )) {
        # don't have LaTeX::Driver
        # *and* won't install as part of $pkg_deps

        # testing early, because LaTeX::Driver only installs
        # when LaTeX is installed...

        my $latex = $class->_find_latex( $dss, $config );
        if (not $latex) {
            if (not $dss->pkg_can_install) {
                die $log->fatal( "Missing 'latex' executable required for building 'LaTeX::Driver' module" );
            }

            my ($run_deps, $build_deps) = $dss->pkg_deps_latex;
            $config->mark_pkgs_for_cleanup( $build_deps );
            push @extra_pkgs, $run_deps->@*, $build_deps->@*;
        }
    }
    elsif (eval { require LaTeX::Driver; 1; }) {
        $log->info( "LaTeX::Driver is loadable" );
    }
    elsif (not grep { $_ eq 'LaTeX::Driver' } $unmapped_mods->@*) {
        $log->info( "LaTeX::Driver will be installed" );
    }
    else {
        $log->fatal( "Internal error: LaTeX::Driver not available and won't be installed, but build prereqs not checked?!?!" );
    }

    $log->info( "Checking for availability of XML::Parser" );
    if (not eval { require XML::Parser; 1; }
        and not $class->_module_will_install( 'XML::Parser', $pkg_deps, $unmapped_mods)) {

        $log->info( "Checking availability of libexpat" );
        my $incpath = $ENV{EXPATINCPATH} // '';
        my $libpath = $ENV{EXPATLIBPATH} // '';

        # Devel::CheckLib tries to find the C compiler when use-d
        # however, we might be installing it as part of the installation
        # process, so we don't want Devel::CheckLib to check when loading the script...
        eval "use Devel::CheckLib qw(assert_lib);";
        unless (eval { assert_lib( lib => [qw(expat)],
                                   header => ['expat.h'],
                                   incpath => $incpath,
                                   ( $libpath ? (libpath => $libpath) : () )
                           ); 1; }) {
            if (not $dss->pkg_can_install) {
                ###TODO: We could push Alien::Expat into @unmapped_mods
                # instead of bailing out here...
                die $log->fatal( "Missing XML parser library Expat blocking installation of XML::Parser" );
            }
            else {
                my ($run_deps, $build_deps) = $dss->pkg_deps_expat;
                $config->mark_pkgs_for_cleanup( $build_deps );
                push @extra_pkgs, $run_deps->@*, $build_deps->@*;
            }
        }
        else {
            $log->info( "Found expat header and library for XML::Parser compilation" );
        }
    }
    elsif (eval { require XML::Parser; 1; }) {
        $log->info( "XML::Parser is loadable" );
    }
    elsif (not grep { $_ eq 'XML::Parser' } $unmapped_mods->@*) {
        $log->info( "XML::Parser will be installed" );
    }
    else {
        $log->fatal( "Internal error: XML::Parser not available and won't be installed, but build prereqs not checked?!?!" );
    }

    if ((not eval { require XML::LibXML; 1; }
         and not $class->_module_will_install( 'XML::LibXML', $pkg_deps, $unmapped_mods ))
        and (not eval { require XML::Twig; 1; }
             and not $class->_module_will_install( 'XML::Twig', $pkg_deps, $unmapped_mods ))) {
        # don't have either XML::LibXML or XML::Twig

        my $xml2_config = $class->_find_xml2_config( $dss, $config );
        if (not $xml2_config) {
            if (not $dss->pkg_can_install) {
                warn $log->warning("Missing 'xml2-config' executable required for building XML::LibXML -- falling back to Alien::Libxml2" );
            }
            else {
                my ($run_deps, $build_deps) = $dss->pkg_deps_xml;
                $config->mark_pkgs_for_cleanup( $build_deps );
                push @extra_pkgs, $run_deps->@*, $build_deps->@*;
            }
        }
    }

    goto PREPARE_TREE if (not $pkg_deps or not $pkg_deps->@*);

  INSTALL_SYS_PKGS:
    $log->info( "Installing O/S packages: " . join(' ', $pkg_deps->@*) );
    $dss->pkg_install( $pkg_deps );

  PREPARE_TREE:
    if (@extra_pkgs) {
        $log->info( "Installing build dependency packages: " . join(' ', @extra_pkgs) );
        $dss->pkg_install( \@extra_pkgs );
    }
    if ($config->effective_prepare_env) {
        $dss->prepare_installer_env( $config );
    }
    $class->_build_install_tree( $dss, $config, $config->installpath, $config->effective_version );

    ###TODO: ideally, we pass the immediate dependencies instead of the installation path;
    # that allows selection of specific features in a later iteration
    $dss->cpanm_install( $config->installpath, $config->locallib, $unmapped_mods );
    $rv = 0;

    $log->info( "Generating application server startup script (server-start)" );
    $dss->generate_start_script( $config->installpath, $config->locallib );

  CLEANUP:
    $log->warning( "Cleaning up Perl module installation dependencies" );
    $dss->cleanup_env($config);

    if ($rv) {
        say "Failed to complete server installation.";
    }
    else {
        my $installpath = $config->installpath;
        say "
LedgerSMB installation into $installpath completed.

The LedgerSMB server can be started using the generated
startup script:

 \$ $installpath/server-start

The server will run with its default configuration. To change
the configuration, copy the file doc/conf/ledgersmb.yaml to
$installpath and modify it. After modification, restart the
LedgerSMB server to activate the new configuration.

";
    }

    return $rv;
}

sub print_id( $class, @args) {
    my $dss = $class->_load_dist_support;
    say $dss->dependency_packages_identifier;
}

sub run($class, $cmd, @args) {
    STDOUT->autoflush(1);
    STDERR->autoflush(1);

    if ($cmd =~ m/^-/) { # option(s)
        unshift @args, $cmd;
        $cmd = 'install';
    }

    if ($cmd eq 'compute') {
        say $log->info( "Computing dependencies using installer version $INSTALLER_VERSION" );
        return $class->compute( @args );
    }
    elsif ($cmd eq 'download') {
        return $class->download( @args );
    }
    elsif ($cmd eq 'help') {
        return $class->help( @args );
    }
    elsif ($cmd eq 'install') {
        say $log->info( "Installing LedgerSMB using $INSTALLER_VERSION" );
        return $class->install( @args );
    }
    elsif ($cmd eq 'system-id') {
        return $class->print_id( @args );
    }
    else {
        $class->help();
        exit 1;
    }
}


1;

__DATA__
SCRIPT version CLONED
Usage: SCRIPT [command] [option ..]

  Commands:
    compute
    download
    install
    help
    system-id
