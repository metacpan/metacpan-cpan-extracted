use 5.008005;
use ExtUtils::MakeMaker;

my @libs = map { chomp;$_ } `pkg-config --libs libpostal`;
my $inc  = join ' ', map { chomp;$_ } `pkg-config --cflags libpostal`;

WriteMakefile(
    NAME           => 'Geo::libpostal',
    VERSION_FROM   => 'lib/Geo/libpostal.pm',
    PREREQ_PM      => { 'Test::More' => 0, 'Exporter' => '5.57', 'Test::Fatal' => 0, 'Const::Fast' => 0 },
    ABSTRACT_FROM  => 'lib/Geo/libpostal.pm',
    AUTHOR         => 'David Farrell',
    CCFLAGS        => '-Wall',
    LIBS           => \@libs,
    OPTIMIZE       => '-O3',
    DEFINE         => '',
    INC            => $inc,
    LICENSE        => 'freebsd',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/dnmfarrell/Geo-libpostal.git',
                web  => 'https://github.com/dnmfarrell/Geo-libpostal',
            },
        }})
     : ()
    ),
);
