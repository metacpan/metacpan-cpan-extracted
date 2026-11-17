use strict;
use warnings;
use ExtUtils::MakeMaker;
use EV::MakeMaker;
use Alien::MySQL;

my $cflags = Alien::MySQL->cflags;
my $libs   = Alien::MySQL->libs;

my @link_flags;
my @clean_libs;
for my $tok (split /\s+/, $libs) {
    next unless length $tok;
    if ($tok =~ /^-Wl,/) {
        push @link_flags, $tok;
    } else {
        push @clean_libs, $tok;
    }
}

my %mm_args = EV::MakeMaker::ev_args(
    NAME             => 'EV::mysql',
    VERSION_FROM     => 'lib/EV/mysql.pm',
    ABSTRACT_FROM    => 'lib/EV/mysql.pm',
    AUTHOR           => 'vividsnow',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.012000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
        'EV'                  => '4.11',
        'EV::MakeMaker'       => 0,
        'Alien::MySQL'        => 0,
    },
    PREREQ_PM => {
        'EV'           => '4.11',
        'Alien::MySQL' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    INC    => $cflags,
    LIBS   => [ join(' ', @clean_libs) ],
    XS     => { 'mysql.xs' => 'mysql.c' },
    OBJECT => 'mysql$(OBJ_EXT)',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/vividsnow/perl5-ev-mysql.git',
                web  => 'https://github.com/vividsnow/perl5-ev-mysql',
            },
            bugtracker => {
                web => 'https://github.com/vividsnow/perl5-ev-mysql/issues',
            },
        },
    },
);

if (@link_flags) {
    $mm_args{dynamic_lib} ||= {};
    $mm_args{dynamic_lib}{OTHERLDFLAGS} =
        join(' ', grep { length } ($mm_args{dynamic_lib}{OTHERLDFLAGS} // ''), @link_flags);
}

WriteMakefile(%mm_args);
