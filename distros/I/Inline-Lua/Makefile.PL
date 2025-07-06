use ExtUtils::MakeMaker;
use FFI::Build::MM;

# This is the simple, conventional constructor from the official documentation.
# It will auto-detect the 'ffi' directory and configure the build automatically.
my $ffi = FFI::Build::MM->new;

# Pass arguments to WriteMakefile using the mm_args method.
WriteMakefile($ffi->mm_args(
    NAME                => 'Inline::Lua',
    DISTNAME            => 'Inline-Lua',
    VERSION_FROM        => 'lib/Inline/Lua.pm',
    ABSTRACT_FROM       => 'lib/Inline/Lua.pm',
    AUTHOR              => 'Andrew D. France <andrewforlua@gmail.com>',
    LICENSE             => 'lgpl_3_0',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => '6.64',
        'FFI::Build::MM'        => '2.00',
        'FFI::Build::File::Cargo' => '0.17',
    },

    PREREQ_PM => {
        'FFI::Platypus'             => '2.00',
        'FFI::Platypus::Lang::Rust' => '0.11',
        'JSON::MaybeXS'             => '1.004000',
        'Cpanel::JSON::XS'          => '4.00',
    },

    test      => {TESTS => 't/*.t'},

    # Add metadata for CPAN and GitHub
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/ItsMeForLua/Inline-Lua.git',
                web  => 'https://github.com/ItsMeForLua/Inline-Lua',
            },
            bugtracker => {
                web => 'https://github.com/ItsMeForLua/Inline-Lua/issues',
            },
        },
    },

    # The clean target is now managed automatically by FFI::Build::MM
));

# The postamble is the key. It lets FFI::Build::MM inject all the
# necessary rules for compiling the Rust code.
package MY;
sub postamble {
    return $ffi->mm_postamble;
}
