use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'HOP::Parser',
    abstract          => '"Higher Order Perl" Parser',
    dist_author       => [
        'Mark Jason Dominus <mjd@plover.com>',
        'Curtis "Ovid" Poe <ovid@cpan.org>',
        'David E. Wheeler <david@justatheory.com>',
        'Xavier Caron <xav@cpan.org>',
    ],
    dist_version_from => 'lib/HOP/Parser.pm',
    requires          => {
        'Sub::Uplevel'    => 0,      # get around CPANPLUS bug
        'HOP::Stream'     => 0.03,
        'HOP::Lexer'      => 0.032,
    },
    build_requires     => {
        'Test::Exception' => 0,
        'Test::More'      => 0,
    },
    add_to_cleanup     => [ 'HOP-Parser-*' ],
    create_makefile_pl => 'traditional',
    license            => 'unrestricted',
    meta_merge         => {
        resources => {
            license     => [ 'http://hop.perl.plover.com/Examples/LICENSE.txt' ],
            homepage    => 'http://hop.perl.plover.com/',
            bugtracker  => {
                web    => 'http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HOP-Parser',
                mailto => 'xav@cpan.org',
            },
            repository  => {
                url  => 'git://github.com/maspalio/hop.git',
                web  => 'http://github.com/maspalio/hop',
                type => 'git',
            },
            x_MailingList => 'http://hop.perl.plover.com/#mlist', # hop-discuss-subscribe@plover.com
        },
    },
);

$builder->create_build_script();
