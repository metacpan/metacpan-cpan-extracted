use strict;
use Config;
use Module::Build;
use File::Spec;
use File::Path;

# Detect platform and compiler capabilities
my %not_sse_archs = map { $_ => 1 } qw[armv7l aarch64];
my $arch          = $^O =~ /Win/ ? '' : `uname -m 2>/dev/null`;
chomp $arch if $arch;
$arch ||= $Config::Config{archname};
my $is_x86   = $arch =~ /x86|i[3-6]86|x64|AMD64|amd64/;
my @cc_flags = split( / /, $Config::Config{ccflags} );

push @cc_flags, '-O3' if !grep {/-O\d/} @cc_flags;
push( @cc_flags, '-msse2', '-msse4.2' ) if $is_x86 && !$not_sse_archs{$arch};
push @cc_flags, '-std=c17' unless grep {/-std=/} @cc_flags;

my $class = Module::Build->subclass(
    override => 'process_support_files',
    code     => <<'END_CODE',
sub process_support_files {
    my $s = shift;
    my $p = $s->{properties};
    return if $s->pureperl_only && $s->allow_pureperl;

    require Config;
    require ExtUtils::Mkbootstrap;

    my $is_x86 = $Config::Config{archname} =~ /x86|i[3-6]86|x64|AMD64|amd64/;
    my $exclude = $is_x86
        ? qr{(?:^|[/\\])(?:tests|cli|fuzz)[/\\]}
        : qr{(?:^|[/\\])(?:tests|cli|fuzz)[/\\]|xxh_x86dispatch\.c$};

    # Compile c_source dirs (ext/xxHash, ext/perl_math_int64)
    if (my $src = $p->{c_source}) {
        my @dirs = ref($src) eq 'ARRAY' ? @$src : ($src);
        push @{$p->{include_dirs}}, @dirs;
        for my $path (@dirs) {
            next unless -d $path;
            my @found = grep { !/$exclude/ } @{ $s->rscan_dir($path, $s->file_qr('\.c(c|p|pp|xx|\+\+)?$')) };
            push @{$p->{objects}}, $s->compile_c($_) for @found;
        }
    }

    # Compile pre-generated XS .c (no .xs needed)
    my $xs_c = 'lib/Digest/xxHash.c';
    return unless -e $xs_c;

    my $v = $s->dist_version;
    my $obj = $s->compile_c(
        $xs_c,
        defines => { VERSION => qq{"$v"}, XS_VERSION => qq{"$v"} },
    );
    push @{$p->{objects}}, $obj;

    # Create arch auto dir
    my $archdir = File::Spec->catdir('blib', 'arch', 'auto', 'Digest', 'xxHash');
    File::Path::mkpath($archdir, 0, oct(777)) unless -d $archdir;

    # Bootstrap .bs
    my $bs_file = File::Spec->catfile($archdir, 'xxHash.bs');
    ExtUtils::Mkbootstrap::Mkbootstrap($bs_file);
    open(my $fh, '>>', $bs_file);
    utime((time)x2, $bs_file);

    # Link into shared library
    my $dlext = $Config::Config{dlext};
    my $lib_file = File::Spec->catfile($archdir, "xxHash.$dlext");
    $s->cbuilder->link(
        module_name => 'Digest::xxHash',
        objects     => [ @{$p->{objects}} ],
        lib_file    => $lib_file,
        extra_linker_flags => $p->{extra_linker_flags} || '',
    );
}
END_CODE
);

my $build = $class->new(
    module_name          => 'Digest::xxHash',
    license              => 'bsd',
    create_readme        => 1,
    configure_requires   => { 'Module::Build'      => '0.4229' },
    build_requires       => { 'ExtUtils::CBuilder' => 0,       'Test::More' => 0 },
    requires             => { 'perl'               => '5.022', ( $Config::Config{ivsize} < 8 ? ( 'Math::Int64' => '0.53' ) : () ), },
    needs_compiler       => 1,
    extra_compiler_flags => [@cc_flags],
    extra_linker_flags   => [@cc_flags],
    include_dirs         => ['.', 'lib/Digest'],
    c_source             => [ 'ext/xxHash', 'ext/perl_math_int64' ]
);
$build->create_build_script;
