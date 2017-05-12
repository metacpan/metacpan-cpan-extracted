package Mac::QuickBundle;

=head1 NAME

Mac::QuickBundle - build Mac OS X bundles for Perl scripts

=cut

use strict;
use warnings;

use Exporter 'import';

our $VERSION = '0.03';
our @EXPORT_OK = qw(scan_dependencies_from_section copy_scripts
                    scan_dependencies load_dependencies merge_dependencies
                    find_shared_dependencies find_all_shared_dependencies
                    scan_dependencies_from_config copy_libraries
                    fix_libraries create_bundle create_pkginfo
                    create_info_plist build_perlwrapper build_application);

=head1 SYNOPSIS

Either use F<quickbundle.pl>, or

    my $cfg = Config::IniFiles->new( -file => 'file.ini' );

    build_application( $cfg );

See L</CONFIGURATION> for a description of the configuration file.

    [application]
    name=MyFilms
    dependencies=myfilms_dependencies
    main=bin/myfilms
    languages=<<EOT
    myfilms_default
    myfilms_italian
    EOT

    [myfilms_default]
    language=default
    name=MyFilms
    version=0.02

    [myfilms_italian]
    language=it
    copyright=Copyright 2011 Mattia Barbon

    [myfilms_dependencies]
    scandeps=myfilms_scandeps

    [myfilms_scandeps]
    script=bin/myfilms
    inc=lib

=cut

our $INFO_PLIST = <<EOT;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>CFBundleDevelopmentRegion</key>
        <string>English</string>
        <key>CFBundleDisplayName</key>
        <string>{{name}}</string>
        <key>CFBundleExecutable</key>
        <string>{{executable}}</string>
        <key>CFBundleIconFile</key>
        <string>{{icon}}</string>
        <key>CFBundleIdentifier</key>
        <string>{{identifier}}</string>
        <key>CFBundleInfoDictionaryVersion</key>
        <string>6.0</string>
        <key>CFBundlePackageType</key>
        <string>APPL</string>
        <key>CFBundleSignature</key>
        <string>????</string>
        <key>CFBundleVersion</key>
        <string>{{version}}</string>
        <key>CSResourcesFileMapped</key>
        <true/>
</dict>
</plist>
EOT

our %STRING_KEYS =
  ( name        => 'CFBundleName',
    display     => 'CFBundleDisplayName',
    version     => 'CFBundleShortVersionString',
    info        => 'CFBundleGetInfoString',
    copyright   => 'NSHumanReadableCopyright',
    );

our %LANGUAGES =
  ( en          => 'English',
    it          => 'Italian',
    nl          => 'Dutch',
    fr          => 'French',
    de          => 'German',
    ja          => 'Japanese',
    es          => 'Spanish',
    );

sub _find_in_inc {
    my( $module, $inc ) = @_;
    ( my $file = $module . '.pm' ) =~ s{::}{/}g;

    require File::Spec;

    for my $path ( @$inc ) {
        my $abs = File::Spec->catfile( $path, $file );
        return $abs if -f $abs;
    }

    die "Can't find '$module' in \@INC: @$inc"
}

sub _find_file_in_inc {
    my( $file, $inc ) = @_;

    require File::Spec;

    for my $path ( @$inc ) {
        my $abs = File::Spec->catfile( $path, $file );
        return $abs if -f $abs;
    }

    return undef;
}

sub _find_inc_dir {
    my( $file, $inc ) = @_;

    for my $path ( @$inc ) {
        return $file if $file =~ s{^$path(?:/)?}{};
    }

    die "Can't find '$file' in \@INC: @$inc"
}

sub scan_dependencies {
    my( $scripts, $scandeps, $inc ) = @_;

    require Module::ScanDeps;

    local @Module::ScanDeps::IncludeLibs = @$inc;
    local $ENV{PERL5LIB} = join( ':', @$inc, $ENV{PERL5LIB} || '' );

    my $deps = Module::ScanDeps::scan_deps( %$scandeps );

    my( %inchash, %dl_shared_objects );
    foreach my $file ( values %$deps ) {
        next if grep $file->{file} eq $_, @$scripts;

        my $dest;
        if( $file->{type} eq 'shared' ) {
            $dl_shared_objects{$file->{key}} = $file->{file};
        } else {
            $inchash{$file->{key}} = $file->{file};
        }
    }

    return ( { %inchash }, { %dl_shared_objects } );
}

sub load_dependencies {
    my( $dump ) = @_;
    our( %inchash, @incarray, @dl_shared_objects );
    local( %inchash, @incarray, @dl_shared_objects );

    do $dump;

    my %dl_shared_objects;
    foreach my $file ( @dl_shared_objects ) {
        my $key = _find_inc_dir( $file, \@incarray );

        $dl_shared_objects{$key} = $file;
    }

    my %files;
    foreach my $key ( keys %inchash ) {
        if( $key =~ m{^/} ) {
            my $k = _find_inc_dir( $key, \@incarray );

            $files{$k} = $inchash{$key};
        } else {
            $files{$key} = $inchash{$key};
        }
    }

    return ( \%files, \%dl_shared_objects );
}

sub merge_dependencies {
    my( %files, %shared );
    while( @_ ) {
        my( $files, $shared ) = splice @_, 0, 2;

        %files = ( %files, %$files );
        %shared = ( %shared, %$shared );
    }

    return \%files, \%shared;
}

sub find_shared_dependencies {
    my( $bundle ) = @_;
    my @lines = readpipe( "otool -L '$bundle'" );
    my @libs;

    for( my $i = 1; $i <= $#lines; ++$i ) {
        ( my $line = $lines[$i] ) =~ s{^\s+}{};

        next if $line =~ m{^(?:/System/|^/usr/lib/)};
        next unless $line =~ m{^(.*?)\s+\(};

        push @libs, $1;
    }

    return @libs;
}

sub find_all_shared_dependencies {
    my( $libs ) = @_;
    my @queue = @$libs;
    my( %libs, %seen );

    while( my $lib = shift @queue ) {
        next if $seen{$lib};
        my @libs = find_shared_dependencies( $lib );

        push @queue, @libs;
        @libs{@libs} = @libs;
        $seen{$lib} = 1;
    }

    return [ keys %libs ];
}

sub _make_absolute($$) {
    my( $path, $base ) = @_;

    require File::Spec;

    return $path if File::Spec->file_name_is_absolute( $path );
    return File::Spec->rel2abs( $path, $base );
}

sub scan_dependencies_from_section {
    my( $cfg, $base_path, $deps_section ) = @_;

    my @dumps = $cfg->val( $deps_section, 'dump' );
    my @scandeps_sections = $cfg->val( $deps_section, 'scandeps' );
    my( @deps, %skip );

    foreach my $file ( qw(unicore/mktables unicore/mktables.lst
                          unicore/TestProp.pl) ) {
        my $abs = _find_file_in_inc( $file, \@INC );
        next unless $abs;

        $skip{$abs} = 1;
    }

    for my $dump ( @dumps ) {
        push @deps, load_dependencies( _make_absolute( $dump, $base_path ) );
    }

    for my $scandeps ( @scandeps_sections ) {
        my @inc = map _make_absolute( $_, $base_path ),
                      $cfg->val( $scandeps, 'inc' );
        my $cache_file = $cfg->val( $scandeps, 'cache' );
        my $cache_path = $cache_file ? _make_absolute( $cache_file, $base_path ) : undef;
        my $compile_flag = $cfg->val( $scandeps, 'compile', 0 );
        my $execute_flag = $cfg->val( $scandeps, 'execute', 0 );
        my @scripts = map _make_absolute( $_, $base_path ),
                          $cfg->val( $scandeps, 'script' );
        my %modules = map { $_ => _find_in_inc( $_, [ @INC, @inc ] ) }
                          $cfg->val( $scandeps, 'modules' );

        my %args = ( files      => [ @scripts, values %modules ],
                     $cache_file ? ( cache_file => $cache_path ) : (),
                     recurse    => 1,
                     compile    => $compile_flag,
                     execute    => $execute_flag,
                     skip       => \%skip,
                     );

        push @deps, scan_dependencies( \@scripts, \%args, \@inc ) if @scripts;

        # bug/misfeature in Module::ScanDeps: only takes into account the last
        # executed file, so we must process them one by one
        foreach my $execute ( $execute_flag ? values %modules : () ) {
            $args{files} = [ $execute ];
            $args{execute} = 1;

            push @deps, scan_dependencies( \@scripts, \%args, \@inc );
        }
    }

    return @deps;
}

sub scan_dependencies_from_config {
    my( $cfg, $base_path ) = @_;
    my @deps_sections = $cfg->val( 'application', 'dependencies' );
    my @deps = map scan_dependencies_from_section( $cfg, $base_path, $_ ),
                   @deps_sections;

    return merge_dependencies( @deps );
}

sub copy_libraries {
    my( $bundle_dir, $modules, $shared, $libs ) = @_;

    require File::Path;
    require File::Copy;

    foreach my $key ( keys %$modules ) {
        my $dest = "$bundle_dir/Contents/Resources/Perl-Libraries/$key";

        File::Path::mkpath( File::Basename::dirname( $dest ) );
        File::Copy::copy( $modules->{$key}, $dest );
    }

    foreach my $key ( keys %$shared ) {
        my $dest = "$bundle_dir/Contents/Resources/Perl-Libraries/$key";

        File::Path::mkpath( File::Basename::dirname( $dest ) );
        File::Copy::copy( $shared->{$key}, $dest );
    }

    foreach my $lib ( @$libs ) {
        my $libfile = File::Basename::basename( $lib );

        File::Copy::copy( $lib, "$bundle_dir/Contents/Resources/Libraries/$libfile" );
    }
}

sub create_bundle {
    my( $bundle_dir ) = @_;

    require File::Path;

    File::Path::mkpath( "$bundle_dir/Contents/MacOS" );
    File::Path::mkpath( "$bundle_dir/Contents/Resources" );
    File::Path::mkpath( "$bundle_dir/Contents/Resources/Libraries" );
    File::Path::mkpath( "$bundle_dir/Contents/Resources/Perl-Libraries" );
    File::Path::mkpath( "$bundle_dir/Contents/Resources/Perl-Source" );
}

sub create_pkginfo {
    my( $bundle_dir ) = @_;

    require File::Slurp;

    File::Slurp::write_file( "$bundle_dir/Contents/PkgInfo", 'APPL????' );
}

sub create_info_plist {
    my( $bundle_dir, $keys ) = @_;
    ( my $text = $INFO_PLIST ) =~ s[{{(\w+)}}][$keys->{$1}]eg;

    require File::Slurp;
    require Encode;

    File::Slurp::write_file( "$bundle_dir/Contents/Info.plist", $text );

    foreach my $lang ( @{$keys->{languages} || []} ) {
        my $name = $lang->{dir_name};
        next unless $name; # TODO warn

        my $path = "$bundle_dir/Contents/Resources/$name.lproj";
        my $text = '';

        foreach my $key ( keys %$lang ) {
            my $info_key = $STRING_KEYS{$key};
            next unless $info_key && $lang->{$key};

            $text .= sprintf qq{%s = "%s";\n}, $info_key, $lang->{$key};
        }

        my $encoded = Encode::encode( 'utf-16', $text );

        File::Path::mkpath( $path );
        File::Slurp::write_file( "$path/InfoPlist.strings", $encoded );
    }
}

sub create_icon {
    my( $bundle_dir, $icon, $icon_name ) = @_;

    require File::Copy;

    File::Copy::copy( $icon, "$bundle_dir/Contents/Resources/$icon_name" );
}

sub fix_libraries {
    my( $perlwrapper, $bundle_dir ) = @_;

    require Cwd;

    my $dir = Cwd::cwd();
    chdir "$bundle_dir/Contents/Resources/Perl-Source";
    system( $^X, "$perlwrapper/Tools/update_dylib_references.pl", '-q' );
    chdir $dir;
}

sub build_perlwrapper {
    my( $perlwrapper, $bundle_dir, $executable_name ) = @_;

    require Config;
    require ExtUtils::Embed;
    require File::Copy;

    my $ccopts = ExtUtils::Embed::ccopts();
    my $ldopts = ExtUtils::Embed::ldopts();

    $ldopts =~ s/(?:^|\s)-lutil(?=\s|$)/ /g;

    system( join ' ', "$Config::Config{cc} $ccopts",
                      "'$perlwrapper/Source/PerlInterpreter.c'",
                      "'$perlwrapper/Source/main.c' -I'$perlwrapper/Source'",
                      "-Wall -o '$bundle_dir/Contents/MacOS/$executable_name'",
                      "-framework CoreFoundation -framework CoreServices",
                      $ldopts
            );
    File::Copy::copy( "$bundle_dir/Contents/MacOS/$executable_name",
                      "$bundle_dir/Contents/MacOS/perl" );
    chmod( 0777, "$bundle_dir/Contents/MacOS/perl" );
}

sub copy_scripts {
    my( $cfg, $base_path, $bundle_dir ) = @_;

    require File::Copy;
    require File::Basename;

    File::Copy::copy( _make_absolute( $cfg->val( 'application', 'main' ),
                                      $base_path ),
                      "$bundle_dir/Contents/Resources/Perl-Source/main.pl" );
    foreach my $script ( $cfg->val( 'application', 'script' ) ) {
        my $name = File::Basename::basename( $script );

        File::Copy::copy( _make_absolute( $script, $base_path ),
                          "$bundle_dir/Contents/Resources/Perl-Source/$name" );
    }
}

sub bundled_perlwrapper {
    my $mydir = $INC{'Mac/QuickBundle.pm'};
    ( my $perlwrapper = $mydir ) =~ s{\.pm$}{/PerlWrapper}i;

    return $perlwrapper;
}

sub read_languages {
    my( $cfg, @lang ) = @_;
    my( @res, $default );

    $default = {};
    foreach my $lang ( @lang ) {
        my $val = { map { $_ => scalar $cfg->val( $lang, $_, undef ) }
                        qw(language name display version copyright) };
        if( $val->{language} eq 'default' ) {
            $default = $val;
        } else {
            $val->{dir_name} = $LANGUAGES{$val->{language}} || $val->{language};
            push @res, $val;
        }
    }

    foreach my $lang ( @res ) {
        while( my( $k, $v ) = each %$default ) {
            $lang->{$k} ||= $v;
        }

        if( $lang->{name} && $lang->{version} && $lang->{copyright} ) {
            $lang->{info} = sprintf qq{%s %s, %s}, $lang->{name},
                                    $lang->{version}, $lang->{copyright};
        }
    }

    return \@res;
}

sub build_application {
    my( $cfg, $outdir ) = @_;

    require Cwd;
    $outdir ||= Cwd::cwd();

    my( $modules, $libs ) = scan_dependencies_from_config( $cfg, Cwd::cwd() );

    my $output = $cfg->val( 'application', 'name' );
    my $version = scalar $cfg->val( 'application', 'version' );
    my $bundle_dir = _make_absolute( "$output.app", $outdir );
    my $perlwrapper = $cfg->val( 'application', 'perlwrapper',
                                 bundled_perlwrapper() );
    my $icon = $cfg->val( 'application', 'icon',
                          "$perlwrapper/Resources/PerlWrapperApp.icns" );
    my @lang = $cfg->val( 'application', 'languages' );
    my $languages = read_languages( $cfg, @lang );

    create_bundle( $bundle_dir );
    create_pkginfo( $bundle_dir );
    create_icon( $bundle_dir, $icon, $output . '.icns' );
    create_info_plist( $bundle_dir,
                       { executable => $output,
                         name       => $output,
                         icon       => $output . '.icns',
                         identifier => 'org.wxperl.' . $output,
                         version    => $version,
                         languages  => $languages,
                         } );
    build_perlwrapper( $perlwrapper, $bundle_dir, $output );
    copy_libraries( $bundle_dir, $modules, $libs,
                    find_all_shared_dependencies( [ "$bundle_dir/Contents/MacOS/perl", values %$libs ] ) );
    copy_scripts( $cfg, Cwd::cwd(), $bundle_dir );
    fix_libraries( $perlwrapper, $bundle_dir );
    system( 'touch', $bundle_dir );
}

1;

__END__

=head1 CONFIGURATION

=head2 application

Contains some meta-information about the bundle, and pointers to other
sections.

=over 4

=item name

The name of the application bundle.

=item version

Application version.

=item icon

Application icon (in .icns format).

=item main

The file name of the main script, copied to
F<Contents/Resources/Perl-Scripts/main.pl>.

=item script

Additional script files, copied to
F<Contents/Resources/Perl-Scripts/E<lt>scriptnameE<gt>>.

=item dependencies

List of sections containing dependency information, see L</dependencies>.

=item languages

List of sections containing language information, see L</languages>.

=item perlwrapper

Path to PerlWrapper sources, defaults to the PerlWrapper bundled with
L<Mac::QuickBundle>.

=back

=head2 languages

Each language section contains localized strings used when displaying
information about the bundle.

=over 4

=item language

ISO 639 language code (es. en, it, ko, ...).

As a special case the C<default> language specifies default keys for
the other languages.

=item name

Short localized application name.

=item display

Longer localized application name, used by Finder, SpotLight, ...

=item version

Human-readable version (es. 12.3, 0.02, ...)

=item copyright

Copyright string (es. Copyright 2011 Yoyodyne corp.)

=back

=head2 dependencies

=over 4

=item scandeps

List of sections containing configuration for L<Module::ScanDeps>, see
L</scandeps>.

=item dump

B<INTERNAL, DO NOT USE>

List of dump files, in the format used by L<Module::ScanDeps> and
created by L<Module::ScanDeps::DataFeed>.

    perl -MModule::ScanDeps::DataFeed=my.dump <program>

=back

=head2 scandeps

=over 4

=item script

Path to the script file (optional).

=item modules

List of additional modules to include (optional).

=item inc

Additional directories to scan.

=item cache

L<Module::ScanDeps> cache file path.

=item compile

If true, run files in compile-only mode and inspects C<%INC> to determine
additional dependencies.

=item execute

Run the script and inspects C<%INC> to determine additional dependencies.

=back

=head1 SEE ALSO

L<Module::ScanDeps>

PerlWrapper (created by Christian Renz):

L<http://svn.scratchcomputing.com/Module-Build-Plugins-MacBundle/trunk>
L<https://github.com/mbarbon/mac-perl-wrapper>

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SOURCES

The latest sources can be found on GitHub at
L<http://github.com/mbarbon/mac-quickbundle> and
L<http://github.com/mbarbon/mac-perl-wrapper>

=cut
