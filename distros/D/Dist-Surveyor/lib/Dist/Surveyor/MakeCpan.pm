package Dist::Surveyor::MakeCpan;

use strict;
use warnings;
use Carp; # core
use Data::Dumper; # core
use File::Path; # core
use CPAN::DistnameInfo;
use File::Basename qw{dirname};  # core
use HTTP::Tiny;
use Dist::Surveyor::Inquiry;
use List::Util qw(max); # core

our $VERSION = '0.022';

our $verbose;
*verbose = \$::VERBOSE;

sub new {
    my ($class, $cpan_dir, $progname, $irregularities) = @_;

    require Compress::Zlib;
    mkpath("$cpan_dir/modules");

    # --- write extra data files that may be useful XXX may change
    # XXX these don't all (yet?) merge with existing data
    my $survey_datadump_dir = "$cpan_dir/$progname";
    mkpath($survey_datadump_dir);

    # Write list of releases, like default stdout
    open my $rel_fh, ">", "$survey_datadump_dir/releases.txt";

    # dump the primary result data for additional info and debugging
    my $gzwrite = Compress::Zlib::gzopen("$survey_datadump_dir/_data_dump.perl.gz", 'wb')
        or croak "Cannot open $survey_datadump_dir/_data_dump.perl.gz for writing: " . $Compress::Zlib::gzerrno;
    $gzwrite->gzwrite("[\n");


    my $self = {
        errors => 0,
        cpan_dir => $cpan_dir,
        irregularities => $irregularities,
        pkg_ver_rel => {}, # for 02packages
        progname => $progname,
        rel_fh => $rel_fh,
        gzwrite => $gzwrite,
    };
    return bless $self, $class;
}

sub close {
    my $self = shift;

    # --- write 02packages file

    my $pkg_lines = _readpkgs($self->{cpan_dir});
    my %packages;
    for my $line (@$pkg_lines, map { $_->{line} } values %{ $self->{pkg_ver_rel} }) {
        my ($pkg) = split(/\s+/, $line, 2);
        if ($packages{$pkg} and $packages{$pkg} ne $line) {
            warn "Old $packages{$pkg}\nNew $line\n" if $verbose;
        }
        $packages{$pkg} = $line;
    };
    _writepkgs($self->{cpan_dir}, [ sort { lc $a cmp lc $b } values %packages ] );



    # Write list of token packages - each should match only one release.
    # This makes it _much_ faster to do installs via cpanm because it
    # can skip the modules it knows are installed (whereas using a list of
    # distros it has to reinstall _all_ of them every time).
    # XXX maybe add as a separate option: "--mainpkgs mainpkgs.lst"
    my %dist_packages;
    while ( my ($pkg, $line) = each %packages) {
        my $distpath = (split /\s+/, $line)[2];
        $dist_packages{$distpath}{$pkg}++;
    }
    my %token_package;
    my %token_package_pri = (       # alter install order for some modules
        'Module::Build' => 100,     # should be near first
        Moose => 50,

        # install distros that use Module::Install late so their dependencies
        # have already been resolved (else they try to fetch them directly,
        # bypassing our cpanm --mirror-only goal)
        'Olson::Abbreviations' => -90,

        # distros with special needs
        'Term::ReadKey' => -100,    # tests hang if run in background
    );
    for my $distpath (sort keys %dist_packages) {
        my $dp = $dist_packages{$distpath};
        my $di = CPAN::DistnameInfo->new($distpath);
        #warn Dumper([ $distpath, $di->dist, $di]);
        (my $token_pkg = $di->dist) =~ s/-/::/g;
        if (!$dp->{$token_pkg}) {
            if (my $keypkg = $self->{irregularities}->{$di->dist}) {
                $token_pkg = $keypkg;
            }
            else {
                # XXX not good - may pick a dummy test package
                $token_pkg = (grep { $_ } keys %$dp)[0] || $token_pkg;
                warn "Picked $token_pkg as token package for ".$di->distvname."\n";
            }
        }
        $token_package{$token_pkg} = $token_package_pri{$token_pkg} || 0;
    }

    my @main_pkgs = sort { $token_package{$b} <=> $token_package{$a} or $a cmp $b } keys %token_package;
    open my $key_pkg_fh, ">", join('/', $self->{cpan_dir}, $self->{progname}, "token_packages.txt");
    print $key_pkg_fh "$_\n" for @main_pkgs;
    close $key_pkg_fh;

    close $self->{rel_fh};

    $self->{gzwrite}->gzwrite("]\n");
    $self->{gzwrite}->gzclose;

    warn $self->{cpan_dir}." updated.\n";
    return $self->{errors};
}

sub add_release {
    my ($self, $ri) = @_;

    # --- get the file

    my $main_url = $ri->{download_url};
    my $di = distname_info_from_url($main_url);
    my $pathfile = "authors/id/".$di->pathname;
    my $destfile = $self->{cpan_dir}."/$pathfile";
    mkpath(dirname($destfile));

    my @urls = ($main_url);
    for my $mirror ('http://backpan.perl.org') {
        push @urls, "$mirror/$pathfile";
    }

    my $mirror_status;
    my $ua = HTTP::Tiny->new(agent => "dist_surveyor/$VERSION");
    for my $url (@urls) {
        $mirror_status = $ua->mirror($url, $destfile);
        last if $mirror_status->{success};
    }
    if (!$mirror_status->{success}) {
        my $err = $mirror_status->{status} == 599 ? $mirror_status->{content} : $mirror_status->{status};
        my $msg = "Error $err mirroring $main_url";
        if (-f $destfile) {
            warn "$msg - using existing file\n";
        }
        else {
            # better to keep going and add the packages to the index
            # than abort at this stage due to network/mirror problems
            # the user can drop the files in later
            warn "$msg - continuing, ADD FILE MANUALLY!\n";
            $self->{errors}++;
        }
    }
    else {
        warn "$mirror_status->{status} $main_url\n" if $verbose;
    }


    my $mods_in_rel = get_module_versions_in_release($ri->{author}, $ri->{name});

    if (!keys %$mods_in_rel) { # XXX hack for common::sense
        (my $dist_as_pkg = $ri->{distribution}) =~ s/-/::/g;
        warn "$ri->{author}/$ri->{name} has no modules! Adding fake module $dist_as_pkg ".$di->version."\n";
        $mods_in_rel->{$dist_as_pkg} = {
            name => $dist_as_pkg,
            version => $di->version,
            version_obj => version->parse($di->version),
        };
    }


    # --- accumulate package info for 02packages file

    for my $pkg (sort keys %$mods_in_rel ) {
        # pi => { name=>, version=>, version_obj=> }
        my $pi = $mods_in_rel->{$pkg};

        # for selecting which dist a package belongs to
        # XXX should factor in authorization status
        my $p_r_match_score = p_r_match_score($pkg, $ri);

        if (my $pvr = $self->{pkg_ver_rel}->{$pkg}) {
            # already seen same package name in different distribution
            if ($p_r_match_score < $pvr->{p_r_match_score}) {
                warn "$pkg seen in $pvr->{ri}{name} so ignoring one in $ri->{name}\n";
                next;
            }
            warn "$pkg seen in $pvr->{ri}{name} - now overridden by $ri->{name}\n";
        }

        my $line = _fmtmodule($pkg, $di->pathname, $pi->{version});
        $self->{pkg_ver_rel}->{$pkg} = { line => $line, pi => $pi, ri => $ri, p_r_match_score => $p_r_match_score };
    }

    printf { $self->{rel_fh} } "%s\n", ( exists $ri->{url} ? $ri->{url} : "?url" );

    $self->{gzwrite}->gzwrite(Dumper($ri));
    $self->{gzwrite}->gzwrite(",");

}

sub p_r_match_score {
    my ($pkg_name, $ri) = @_;
    my @p = split /\W/, $pkg_name;
    my @r = split /\W/, $ri->{name};
    for my $i (0..max(scalar @p, scalar @r)) {
        return $i if not defined $p[$i]
                  or not defined $r[$i]
                  or $p[$i] ne $r[$i]
    }
    die; # unreached
}

# copied from CPAN::Mini::Inject and hacked

sub _readpkgs {
    my ($cpandir) = @_;

    my $packages_file = $cpandir.'/modules/02packages.details.txt.gz';
    return [] if not -f $packages_file;

    my $gzread = Compress::Zlib::gzopen($packages_file, 'rb')
        or croak "Cannot open $packages_file: " . $Compress::Zlib::gzerrno . "\n";

    my $inheader = 1;
    my @packages;
    my $package;

    while ( $gzread->gzreadline( $package ) ) {
        if ( $inheader ) {
            $inheader = 0 unless $package =~ /\S/;
            next;
        }
        chomp $package;
        push @packages, $package;
    }

    $gzread->gzclose;

    return \@packages;
}

sub _writepkgs {
    my ($cpandir, $pkgs) = @_;

    my $packages_file = $cpandir.'/modules/02packages.details.txt.gz';
    my $gzwrite = Compress::Zlib::gzopen($packages_file, 'wb')
        or croak "Cannot open $packages_file for writing: " . $Compress::Zlib::gzerrno;
    
    $gzwrite->gzwrite( "File:         02packages.details.txt\n" );
    $gzwrite->gzwrite(
        "URL:          http://www.perl.com/CPAN/modules/02packages.details.txt\n"
    );
    $gzwrite->gzwrite(
        'Description:  Package names found in directory $CPAN/authors/id/'
        . "\n" );
    $gzwrite->gzwrite( "Columns:      package name, version, path\n" );
    $gzwrite->gzwrite(
        "Intended-For: Automated fetch routines, namespace documentation.\n"
    );
    $gzwrite->gzwrite( "Written-By:   $0 0.001\n" ); # XXX TODO
    $gzwrite->gzwrite( "Line-Count:   " . scalar( @$pkgs ) . "\n" );
    # Last-Updated: Sat, 19 Mar 2005 19:49:10 GMT
    my @date = split( /\s+/, scalar( gmtime ) );
    $gzwrite->gzwrite( "Last-Updated: $date[0], $date[2] $date[1] $date[4] $date[3] GMT\n\n" );
    
    $gzwrite->gzwrite( "$_\n" ) for ( @$pkgs );
    
    $gzwrite->gzclose;
}

sub distname_info_from_url {
    my ($url) = @_;
    $url =~ s{.* \b authors/id/ }{}x
        or warn "No authors/ in '$url'\n";
    my $di = CPAN::DistnameInfo->new($url);
    return $di;
}

sub _fmtmodule {
    my ( $module, $file, $version ) = @_;
    $version = "undef" if not defined $version;
    my $fw = 38 - length $version;
    $fw = length $module if $fw < length $module;
    return sprintf "%-${fw}s %s  %s", $module, $version, $file;
}

sub errors {
    my $self = shift;
    return $self->{errors};
}

1;

=head1 NAME

Dist::Surveyor::MakeCpan - Create a Mini-CPAN for the surveyed modules

=head1 SYNOPSIS

    use Dist::Surveyor::MakeCpan;
    my $cpan = Dist::Surveyor::MakeCpan->new(
            $cpan_dir, $progname, $irregularities);
    foreach my $rel (@releases) {
        $cpan->add_release($rel);
    }
    $cpan->close();
    say "There where ", $cpan->errors(), " errors";

=head1 DESCRIPTION

Create a mini-CPAN for the surveyed modules, so you will be able to re-install 
the same setup in a new computer.

=head1 CONSTRUCTOR

    my $cpan = Dist::Surveyor::MakeCpan->new(
            $cpan_dir, $progname, $irregularities, $verbose);

=over

=item $cpan_dir

The directory where the mini-cpan will be created

=item $progname

The name of the running program - will be used to create a subdirectory 
inside $cpan_dir, that will contain debug information.

=item $irregularities

A hashref with a list of irregular named releases. i.e. 'libwww-perl' => 'LWP'.

=back

=head1 METHODS

=head2 $cpan->add_release($rel)

Add one release to the mini-cpan. the $rel should be a hashref, 
and contain the following fields:

    $rel = {
        download_url => 'http://cpan.metacpan.org/authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz',
        url => 'authors/id/S/SE/SEMUELF/Dist-Surveyor-0.009.tar.gz',
        author => 'SEMUELF',
        name => 'Dist-Surveyor-0.009',
        distribution => 'Dist-Surveyor',
    }

=head2 $cpan->close()

Close the mini-CPAN, and close all the debug data dump files.

=head1 License, Copyright

Please see L<Dist::Surveyor> for details

=cut
