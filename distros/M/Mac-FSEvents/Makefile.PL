use 5.008008;
use ExtUtils::MakeMaker;
use ExtUtils::Constant qw(WriteConstants);
use lib '.';
use MacVersion;

use Config;

### Build Makefile with support for multiple EUMM versions
# Stolen from Tobyink and Chorny

my %params = (
    NAME              => 'Mac::FSEvents',
    AUTHOR            => 'Andy Grundman <andy@hybridized.org>, Rob Hoelz <rob@hoelz.ro>',
    VERSION_FROM      => 'lib/Mac/FSEvents.pm',
    ABSTRACT_FROM     => 'lib/Mac/FSEvents.pm',
    LICENSE           => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/hoelzro/Mac-FSEvents',
        },
    },

    LIBS              => [''],
    LDDLFLAGS         => $Config{lddlflags} . ' -framework CoreServices -framework CoreFoundation',
    DEFINE            => '',
    INC               => '-I.',
    PM                => {
        'lib/Mac/FSEvents.pm'       => '$(INST_LIBDIR)/FSEvents.pm',
        'lib/Mac/FSEvents/Event.pm' => '$(INST_LIBDIR)/FSEvents/Event.pm',
    },

    MIN_PERL_VERSION  => '5.008008',
    PREREQ_PM => {
        strict      => 0,
        warnings    => 0,
        Exporter    => 0,
        base        => 0,
    },
    TEST_REQUIRES => {
        'Test::More'    => 0.99, # subtest and done_testing
        autodie         => 0,
        'IO::Select'    => 0,
        'Cwd'           => 0,
        'File::Path'    => 0,
        'File::Spec'    => 0,
        'File::Temp'    => 0,
        'Scalar::Util'  => 0,
    },
);

# Mangle the above params based on EUMM version
my $eumm_version=$ExtUtils::MakeMaker::VERSION;
$eumm_version=eval $eumm_version;
if ( $eumm_version < 6.6303 ) {
    for my $param_name ( qw( TEST_REQUIRES CONFIGURE_REQUIRES ) ) {
        next unless $params{ $param_name };
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{$param_name}} };
        delete $params{$param_name};
    }
}

if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
    $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
    delete $params{BUILD_REQUIRES};
}

delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
delete $params{META_MERGE} if $eumm_version < 6.46;
delete $params{META_ADD} if $eumm_version < 6.46;
delete $params{LICENSE} if $eumm_version < 6.31;
delete $params{AUTHOR} if $] < 5.005;
delete $params{ABSTRACT_FROM} if $] < 5.005;
delete $params{BINARY_LOCATION} if $] < 5.005;

WriteMakefile( %params );

### Write the constants for this version of OS X
my @names = qw{
    kFSEventStreamCreateFlagNone
    kFSEventStreamCreateFlagWatchRoot
};

my ( $major, $minor, $release ) = osx_version();

if($minor >= 6) {
    push @names, 'kFSEventStreamCreateFlagIgnoreSelf';

    if($minor >= 7) {
        push @names, 'kFSEventStreamCreateFlagFileEvents';
    }
}

foreach my $element ( @names ) {
    my $c_name = $element;

    my $perl_name = $c_name;
    $perl_name =~ s/kFSEventStreamCreateFlag//; # strip off leading name
    $perl_name =~ s/([a-z])([A-Z])/"$1_$2"/ge;  # convert camel case to underscores
    $perl_name = uc($perl_name);                # uppercase

    $element = {
        name  => $perl_name,
        value => $c_name,
        macro => 1,
    };
}

WriteConstants(
    NAME  => 'Mac::FSEvents',
    NAMES => \@names,
);
