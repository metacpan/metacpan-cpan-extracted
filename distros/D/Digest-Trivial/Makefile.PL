use 5.006;

use ExtUtils::MakeMaker;

my %args = (
    NAME              => 'Digest::Trivial',
    VERSION_FROM      => 'lib/Digest/Trivial.pm',
    ABSTRACT_FROM     => 'lib/Digest/Trivial.pm',
    PREREQ_PM         => {
        strict            =>  0,
        warnings          =>  0,
        Exporter          =>  0,
        AutoLoader        =>  0,
        XSLoader          =>  0,
    },
    MIN_PERL_VERSION  =>  5.006,
    AUTHOR            => 'Abigail <abigail@abigail.be>',
    LICENSE           => 'mit',
    META_MERGE        => {
        test_requires    => {
            strict           =>  0,
            warnings         =>  0,
            constant         =>  0,
           'Test::More'      =>  0.88,
        },
        resources        => {
            repository   => 'git://github.com/Abigail/Digest--Trivial.git',
        },
        keywords         => [qw [ ]],
    },
);

$args {META_MERGE} {build_requires} ||= {
    'ExtUtils::MakeMaker' =>  0,
    %{$args {META_MERGE} {test_requires}}
};

$args {META_MERGE} {configure_requires} ||=
    $args {META_MERGE} {build_requires};


my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);

delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;

__END__
