
use feature qw( :5.20 );
use Rex -feature => ['1.3'];

group www => qw( preaction.me );

set PERL5LIB =>
    join ":",
        '/home/doug/perl5/lib/perl5',
        '/home/doug/perl5/lib/perl5/amd64-openbsd',
        ;

path '/home/doug/perl5/bin',
    split /:/, '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin';

desc 'Deploy the site';
task deploy => ( group => 'www' ), sub {

    file( 'etc/init.d', ensure => 'directory' );
    file( 'etc/init.d/mercury', source => 'eg/daemon.pl', mode => '755' );

    say scalar run 'cpanm -l perl5 Mercury Daemon::Control';
    say scalar run './etc/init.d/mercury restart',
        env => {
            PERL5LIB => get( 'PERL5LIB' ),
        };

    LOCAL {
        run 'statocles deploy';
    }
};

