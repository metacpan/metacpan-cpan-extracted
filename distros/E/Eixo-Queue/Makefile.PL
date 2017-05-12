use 5.012;
use ExtUtils::MakeMaker;

die('OS unsupported') if($^O eq 'MSWin32');

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    MIN_PERL_VERSION => '5.012',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/frmadem/eixo_queue.git',
                web => 'https://github.com/frmadem/eixo_queue',
            },
        },
    },
    #TEST_REQUIRES => {
    #},

    NAME              => 'Eixo::Queue',
    VERSION_FROM      => 'lib/Eixo/Queue.pm', # finds $VERSION
    PREREQ_PM         => {
        'Eixo::Base' => '1.400',
        'JSON' => '2.5',
        'Data::UUID' => '1',
        'MongoDB' => '0.708',
        'Crypt::JWT' => '0.018',
        'Net::AMQP::RabbitMQ' => '2.3'
    }, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Eixo/Queue.pod', # retrieve abstract from module
    AUTHOR         =>  ['Francisco Maseda <frmadem@gmail.com>', 'Javier Gomez <alambike@gmail.com>'],
    LICENSE => 'apache',
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;

    WriteMakefile(%params);
}

