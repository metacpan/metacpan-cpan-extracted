package Distribution::Metadata;
use 5.008001;
use strict;
use warnings;
use CPAN::DistnameInfo;
use CPAN::Meta;
use Config;
use Cwd ();
use ExtUtils::Packlist;
use File::Basename qw(basename dirname);
use File::Find 'find';
use File::Spec::Functions qw(catdir catfile);
use JSON ();
use Module::Metadata;
use constant DEBUG => $ENV{PERL_DISTRIBUTION_METADATA_DEBUG};

my $SEP = qr{/|\\}; # path separater
my $ARCHNAME = $Config{archname};

our $VERSION = "0.05";

our $CACHE;

sub new_from_file {
    my ($class, $file, %option) = @_;
    $class->_new(%option, _module => {file => $file});
}

sub new_from_module {
    my ($class, $module, %option) = @_;
    $class->_new(%option, _module => {name => $module});
}

sub _new {
    my ($class, %option) = @_;
    my $module = $option{_module};
    my $inc = $option{inc} || \@INC;
    $inc = $class->_abs_path($inc);
    $inc = $class->_fill_archlib($inc) if $option{fill_archlib};
    my $metadata = $module->{file}
        ? Module::Metadata->new_from_file($module->{file}, inc => $inc)
        : Module::Metadata->new_from_module($module->{name}, inc => $inc);

    my $self = bless {}, $class;
    return $self unless $metadata;

    $module->{file} = $metadata->filename;
    $module->{name} = $metadata->name;
    $module->{version} = $metadata->version;

    my ($packlist, $files) = $class->_find_packlist($module->{file}, $inc);
    if ($packlist) {
        $self->{packlist} = $packlist;
        $self->{files}    = $files;
    } else {
        return $self;
    }

    my ($main_module, $lib) = $self->_guess_main_module($packlist);
    if ($main_module) {
        $self->{main_module} = $main_module;
        if ($main_module eq "perl") {
            $self->{main_module_version} = $^V;
            $self->{main_module_file} = $^X;
            $self->{dist} = "perl";
            my $version = "" . $^V;
            $version =~ s/v//;
            $self->{distvname} = "perl-$version";
            $self->{version} = $version;
            return $self;
        }
    } else {
        return $self;
    }

    my $archlib = catdir($lib, $ARCHNAME);
    my $main_metadata = Module::Metadata->new_from_module(
        $main_module, inc => [$archlib, $lib]
    );

    my ($find_module, $find_version);
    if ($main_metadata) {
        $self->{main_module_version} = $main_metadata->version;
        $self->{main_module_file} = $main_metadata->filename;
        $find_module = $main_metadata->name;
        $find_version = $main_metadata->version;
    } else {
        $find_module = $module->{name};
        $find_version = $module->{version};
    }

    my ($meta_directory, $install_json, $install_json_hash, $mymeta_json) = $class->_find_meta(
        $main_module, $find_module, $find_version,
        catdir($archlib, ".meta")
    );
    $self->{meta_directory}    = $meta_directory;
    $self->{install_json}      = $install_json;
    $self->{install_json_hash} = $install_json_hash;
    $self->{mymeta_json}       = $mymeta_json;
    $self;
}

sub _guess_main_module {
    my ($self, $packlist) = @_;
    my @piece = File::Spec->splitdir( dirname($packlist) );
    if ($piece[-1] eq $ARCHNAME) {
        return ("perl", undef);
    }

    my (@module, @lib);
    for my $i ( 1 .. ($#piece-2) ) {
        if ($piece[$i] eq $ARCHNAME && $piece[$i+1] eq "auto") {
            @module = @piece[ ($i+2) .. $#piece ];
            @lib    = @piece[ 0      .. ($i-1)  ];
            last;
        }
    }
    return unless @module;
    return ( _fix_module_name( join("::", @module) ), catdir(@lib) );
}

# ugly workaround for case insensitive filesystem
# eg: if you install 'Version::Next' module and later 'version' module,
# then version's packlist is located at Version/.packlist! (capital V!)
# Maybe there are a lot of others...
my @fix_module_name = qw(version Version::Next);
sub _fix_module_name {
    my $module_name = shift;
    if (my ($fix) = grep { $module_name =~ /^$_$/i } @fix_module_name) {
        $fix;
    } else {
        $module_name;
    }
}

sub _fill_archlib {
    my ($class, $incs) = @_;
    my %incs = map { $_ => 1 } @$incs;
    my @out;
    for my $inc (@$incs) {
        push @out, $inc;
        next if $inc =~ /$ARCHNAME$/o;
        my $archlib = catdir($inc, $ARCHNAME);
        if (-d $archlib && !$incs{$archlib}) {
            push @out, $archlib;
        }
    }
    \@out;
}

my $decode_install_json = sub {
    my $file = shift;
    my $content = do { open my $fh, "<", $file or next; local $/; <$fh> };
    JSON::decode_json($content);
};
sub _decode_install_json {
    my ($class, $file, $dir) = @_;
    if ($CACHE) {
        $CACHE->{install_json}{$dir}{$file} ||= $decode_install_json->($file);
    } else {
        $decode_install_json->($file);
    }
}
sub _find_meta {
    my ($class, $main_module, $module, $version, $dir) = @_;
    return unless -d $dir;

    my @install_json;
    if ($CACHE and $CACHE->{install_json_collected}{$dir}) {
        @install_json = keys %{$CACHE->{install_json}{$dir}};
    } else {
        @install_json = do {
            opendir my $dh, $dir or die "opendir $dir: $!";
            my @meta_dir = grep { !/^[.]{1,2}$/ } readdir $dh;
            grep -f, map { catfile($dir, $_, "install.json") } @meta_dir;
        };
        if ($CACHE) {
            $CACHE->{install_json}{$dir}{$_} ||= undef for @install_json;
            $CACHE->{install_json_collected}{$dir}++;
        }
    }

    # to speed up, first try distribution which just $module =~ s/::/-/gr;
    my $naive = do { my $dist = $main_module; $dist =~ s/::/-/g; $dist };
    @install_json = (
        (sort { $b cmp $a } grep {  /^$naive/ } @install_json),
        (sort { $b cmp $a } grep { !/^$naive/ } @install_json),
    );

    my ($meta_directory, $install_json, $install_json_hash, $mymeta_json);
    INSTALL_JSON_LOOP:
    for my $file (@install_json) {
        my $hash = $class->_decode_install_json($file, $dir);

        # name VS target ? When LWP, name is LWP, and target is LWP::UserAgent
        # So name is main_module!
        my $name = $hash->{name} || "";
        next if $name ne $main_module;
        my $provides = $hash->{provides} || +{};
        for my $provide (sort keys %$provides) {
            if ($provide eq $module
                && ($provides->{$provide}{version} || "") eq $version) {
                $meta_directory = dirname($file);
                $install_json = $file;
                $mymeta_json  = catfile($meta_directory, "MYMETA.json");
                $install_json_hash = $hash;
                last INSTALL_JSON_LOOP;
            }
        }
        DEBUG and warn "==> failed to find $module $version in $file\n";
    }

    return ($meta_directory, $install_json, $install_json_hash, $mymeta_json);
}

sub _naive_packlist {
    my ($class, $module_file, $inc) = @_;
    for my $i (@$inc) {
        if (my ($path) = $module_file =~ /$i $SEP (.+)\.pm /x) {
            my $archlib = $i =~ /$ARCHNAME$/o ? $i : catdir($i, $ARCHNAME);
            my $try = catfile( $archlib, "auto", $path, ".packlist" );
            return $try if -f $try;
        }
    }
    return;
}

# It happens that .packlist files are symlink path.
# eg: OSX,
# in .packlist: /var/folders/...
# but /var/folders/.. is a symlink to /private/var/folders
my $extract_files = sub {
    my $packlist = shift;
    [
        map  { Cwd::abs_path($_) } grep { -f }
        sort keys %{ ExtUtils::Packlist->new($packlist) || +{} }
    ];
};
sub _extract_files {
    my ($class, $packlist) = @_;
    if ($CACHE) {
        $CACHE->{packlist}{$packlist} ||= $extract_files->($packlist);
    } else {
        $extract_files->($packlist);
    }
}

sub _core_packlist {
    my ($self, $inc) = @_;
    for my $dir (grep -d, @$inc) {
        opendir my $dh, $dir or die "Cannot open dir $dir: $!\n";
        my ($packlist) = map { catfile($dir, $_) } grep {$_ eq ".packlist"} readdir $dh;
        return $packlist if $packlist;
    }
    return;
}

sub _find_packlist {
    my ($class, $module_file, $inc) = @_;

    if ($CACHE and my $core_packlist = $CACHE->{core_packlist}) {
        my $files = $class->_extract_files($core_packlist);
        if (grep {$module_file eq $_} @$files) {
            return ($core_packlist, $files);
        }
    }

    # to speed up, first try packlist which is naively guessed by $module_file
    if (my $naive_packlist = $class->_naive_packlist($module_file, $inc)) {
        my $files = $class->_extract_files($naive_packlist);
        if ( grep { $module_file eq $_ } @$files ) {
            DEBUG and warn "-> naively found packlist: $module_file\n";
            return ($naive_packlist, $files);
        }
    }

    my @packlists;
    if ($CACHE and $CACHE->{packlist_collected}) {
        @packlists = keys %{ $CACHE->{packlist} };
    } else {
        if (my $core_packlist = $class->_core_packlist($inc)) {
            push @packlists, $core_packlist;
            $CACHE->{core_packlist} = $core_packlist if $CACHE;
        }
        find sub {
            return unless -f;
            return unless $_ eq ".packlist";
            push @packlists, $File::Find::name;
        }, grep -d, map { catdir($_, "auto") } @{$class->_fill_archlib($inc)};
        if ($CACHE) {
            $CACHE->{packlist}{$_} ||= undef for @packlists;
            $CACHE->{packlist_collected}++;
        }
    }

    for my $try (@packlists) {
        my $files = $class->_extract_files($try);
        if (grep { $module_file eq $_ } @$files) {
            return ($try, $files);
        }
    }
    return;
}

sub _abs_path {
    my ($class, $dirs) = @_;
    my @out;
    for my $dir (grep -d, @$dirs) {
        my $abs = Cwd::abs_path($dir);
        $abs =~ s/$SEP+$//;
        push @out, $abs if $abs;
    }
    \@out;
}

sub packlist            { shift->{packlist} }
sub meta_directory      { shift->{meta_directory} }
sub install_json        { shift->{install_json} }
sub mymeta_json         { shift->{mymeta_json} }
sub main_module         { shift->{main_module} }
sub main_module_version { shift->{main_module_version} }
sub main_module_file    { shift->{main_module_file} }
sub files               { shift->{files} }
sub install_json_hash   { shift->{install_json_hash} }

sub mymeta_json_hash {
    my $self = shift;
    return unless my $mymeta_json = $self->mymeta_json;
    $self->{mymeta_json_hash} ||= CPAN::Meta->load_file($mymeta_json)->as_struct;
}

sub _distnameinfo {
    my $self = shift;
    return unless my $hash = $self->install_json_hash;
    $self->{_distnameinfo} ||= CPAN::DistnameInfo->new( $hash->{pathname} );
}

for my $attr (qw(dist version cpanid distvname pathname)) {
    no strict 'refs';
    *$attr = sub {
        my $self = shift;
        return $self->{$attr} if exists $self->{$attr}; # for 'perl' distribution
        return unless $self->_distnameinfo;
        $self->_distnameinfo->$attr;
    };
}

# alias
sub name   { shift->dist }
sub author { shift->cpanid }

1;

__END__

=for stopwords .packlist inc pathname eg archname eq archlibs vname libwww-perl

=encoding utf-8

=head1 NAME

Distribution::Metadata - gather distribution metadata in local

=head1 SYNOPSIS

    use Distribution::Metadata;

    my $info = Distribution::Metadata->new_from_module("LWP::UserAgent");

    print $info->name;      # libwww-perl
    print $info->version;   # 6.13
    print $info->distvname; # libwww-perl-6.13
    print $info->author;    # ETHER
    print $info->pathname;  # E/ET/ETHER/libwww-perl-6.13.tar.gz

    print $info->main_module;         # LWP
    print $info->main_module_version; # 6.13
    print $info->main_module_file;    # path of LWP.pm

    print $info->packlist;       # path of .packlist
    print $info->meta_directory; # path of .meta directory
    print $info->install_json;   # path of install.json
    print $info->mymeta_json;    # path of MYMETA.json

    my $files = $info->files; # files which are listed in .packlist

    my $install_json_hash = $info->install_json_hash;
    my $mymeta_json_hash  = $info->mymeta_json_hash;

=head1 DESCRIPTION

(B<CAUTION>: This module is still in development phase. API will change without notice.)

Sometimes we want to know:
I<Where this module comes from? Which distribution does this module belong to?>

Since L<cpanm> 1.5000 (released 2011.10.13),
it installs not only modules but also their meta data.
So we can answer that questions!

Distribution::Metadata gathers distribution metadata in local.
That is, this module tries to gather

=over 4

=item * main module name, version, file

=item * C<.packlist> file

=item * C<.meta> directory

=item * C<install.json> file

=item * C<MYMETA.json> file

=back

Please note that as mentioned above, B<this module deeply depends on cpanm behavior>.
If you install cpan modules by hands or some cpan clients other than cpanm,
this module won't work.

=head1 HOW IT WORKS

Let me explain how C<< $class->new_from_module($module, inc => $inc) >> works.

=over 4

=item * Get C<$module_file> by

    Module::Metadata->new_from_module($module, inc => $inc)->filename.

=item * Find C<$packlist> in which C<$module_file> is listed.

=item * From C<$packlist> pathname (eg: ...auto/LWP/.packlist), determine C<$main_module> and main module search directory C<$lib>.

=item * Get C<$main_module_version> by

    Module::Metadata->new_from_module($main_module, inc => [$lib, "$lib/$Config{archname}"])->version

=item * Find install.json that has "name" eq C<$main_module>, and provides C<$main_module> with version C<$main_module_version>.

=item * Get .meta directory and MYMETA.json with install.json.

=back

=head2 CONSTRUCTORS

=over 4

=item C<< my $info = $class->new_from_module($module, inc => \@dirs, fill_archlib => $bool) >>

Create Distribution::Metadata instance from module name.

You can append C<inc> argument
to specify module/packlist/meta search paths. Default is C<\@INC>.

Also you can append C<fill_archlib> argument
so that archlibs are automatically added to C<inc> if missing.

Please note that, even if the module cannot be found,
C<new_from_module> returns a Distribution::Metadata instance.
However almost all methods returns false for such objects.
If you want to know whether the distribution was found or not, try:

    my $info = $class->new_from_module($module);

    if ($info->packlist) {
        # found
    } else {
        # not found
    }

=item C<< my $info = $class->new_from_file($file, inc => \@dirs, fill_archlib => $bool) >>

Create Distribution::Metadata instance from file path.
You can append C<inc> and C<fill_archlib> arguments too.

Also C<new_from_file> retunes a Distribution::Metadata instance,
even if file cannot be found.

=back

=head2 METHODS

Please note that the following methods return false
when appropriate modules or files cannot be found.

=over 4

=item C<< my $name = $info->name (alias: $info->dist) >>

distribution name (eg: C<libwww-perl>)

=item C<< my $version = $info->version >>

distribution version (eg: C<6.13>)

=item C<< my $distvname = $info->distvname >>

distribution vname (eg: C<libwww-perl-6.13>)

=item C<< my $author = $info->author (alias: $info->cpanid) >>

distribution author (eg: C<ETHER>)

=item C<< my $pathname = $info->pathname >>

distribution pathname (eg: C<E/ET/ETHER/libwww-perl-6.13.tar.gz>)

=item C<< my $file = $info->packlist >>

C<.packlist> file path

=item C<< my $dir = $info->meta_directory >>

C<.meta> directory path

=item C<< my $file = $info->install_json >>

C<install.json> file path

=item C<< my $file = $info->mymeta_json >>

C<MYMETA.json> file path

=item C<< my $main_module = $info->main_module >>

main module name

=item C<< my $version = $info->main_module_version >>

main module version

=item C<< my $file = $info->main_module_file >>

main module file path

=item C<< my $files = $info->files >>

file paths which is listed in C<.packlist> file,
note that paths are acutually C<< Cwd::abs_path() >>-ed

=item C<< my $hash = $info->install_json_hash >>

a hash reference for C<install.json>

    my $info = Distribution::Metadata->new_from_module("LWP::UserAgent");
    my $install = $info->install_json_hash;
    $install->{version};  # 6.13
    $install->{dist};     # libwww-perl-6.13
    $install->{provides}; # a hash reference of providing modules
    ...

=item C<< my $hash = $info->mymeta_json_hash >>

a hash reference for C<MYMETA.json>

    my $info = Distribution::Metadata->new_from_module("LWP::UserAgent");
    my $meta = $info->mymeta_hash;
    $meta->{version};  # 6.13
    $meta->{abstract}; # The World-Wide Web library for Perl
    $meta->{prereqs};  # prereq hash
    ...

=back

=head1 SEE ALSO

L<Module::Metadata>

L<App::cpanminus>

=head1 LICENSE

Copyright (C) 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

