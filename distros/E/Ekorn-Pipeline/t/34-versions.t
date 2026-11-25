use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Every module has a $VERSION, the distribution's, so a caller can ask
# for the version a module's feature came in, as
# `use Ekorn::Pipeline::Tooling v0.3.15 qw(:context)`. minil prepare
# sets $VERSION in every module that declares one, so they stay in step
# as long as each declares one, for its own package, and no other
# package does (roadmap 2026-0053, D5).

use File::Find qw(find);
use File::Spec qw();
use Ekorn::Pipeline;

my $want = Ekorn::Pipeline->VERSION;

# The modules, by their files under the folder Ekorn::Pipeline was
# loaded from, as installed or as here.
my $lib
    = $INC{'Ekorn/Pipeline.pm'} =~ s( [\/\\] Ekorn [\/\\] Pipeline\.pm \z )()xr;
my @files;
find(sub { push @files, $File::Find::name if m( \.pm \z )x }, "$lib/Ekorn");

# Return the code of a module's file, before its POD.
sub code_of ($path) {
    open my $in, '<', $path or die "Can't read $path: $!";
    local $/ = undef;
    my $text = <$in>;
    close $in;
    return $text =~ s( ^ __END__ $ .* )()xmsr;
}

# Each file's path as require takes it, relative to the folder, with
# / between its parts, on any platform; and the module it holds.
my %relative_of = map {
    $_ => join '/', File::Spec->splitdir(File::Spec->abs2rel($_, $lib))
} @files;
my %module_of
    = map { $_ => $relative_of{$_} =~ s( \.pm \z )()xr =~ s( / )(::)xgr }
    @files;
my %is_module = map { $_ => 1 } values %module_of;

for my $path (sort @files) {
    my $module   = $module_of{$path};
    my $code     = code_of($path);
    my @versions = $code =~ m( ^ \s* our \s+ \$VERSION \b )xmg;
    is scalar @versions, 1, "$module declares one \$VERSION";
    require $relative_of{$path};
    is $module->VERSION, $want, "$module is at the distribution's version";
    # The packages it defines inside, which a $VERSION would stray to;
    # Operators reopens other modules' packages, which have their own.
    for my $inner (grep { !$is_module{$_} }
        $code =~ m( ^ \s* package \s+ ([\w:]+) \s* \{ )xmg)
    {
        is $inner->VERSION, undef, "$inner, inside $module, has none";
    }
}

ok scalar @files >= 23, 'every module was found';

done_testing;
