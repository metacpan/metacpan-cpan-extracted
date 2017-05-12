# t/002_new.t 
# vim:ft=perl
use strict;
use warnings;

# use Test::More tests => 2;
use Test::More qw(no_plan);
use Log::Log4perl;
use Config::IniFiles;
use FindBin;
use Log::Log4perl::ConfigByInifile;

ok( Log::Log4perl::ConfigByInifile->can('new'), "Module can new");
# must die without arguments
eval {
    Log::Log4perl::ConfigByInifile->new();
};
ok( $@, "new dies without arguments");

# define an ini-file
# there is no section log4perl in the file:
my $bad_ini_fqn = $FindBin::Bin . '/bad.ini';
ok(-e $bad_ini_fqn, "Bad Inifile '$bad_ini_fqn' found");

my $good_ini_fqn = $FindBin::Bin . '/good.ini';
ok(-e $good_ini_fqn, "Good Inifile '$good_ini_fqn' found");

# must die with 2 good arguments
eval {
    Log::Log4perl::ConfigByInifile->new(
        {
            ini_file => $good_ini_fqn,
            ini_obj => Config::IniFiles->new(-file => $good_ini_fqn),
        }
    );
};
ok( $@, "new dies with 2 good arguments which is too much");

# must die with invalid filename
eval {
    Log::Log4perl::ConfigByInifile->new(
        {
            ini_file => 'does_not_exist.ini',
        }
    );
};
ok( $@, "new dies if arg ini_file is not a file");

# must die with invalid object
eval {
    Log::Log4perl::ConfigByInifile->new(
        {
            ini_obj => bless( {}, 'Different::Object'),
        }
    );
};
ok( $@, "new dies if arg ini_obj is not of type Config::IniFiles");

# must die with inifile without section [log4perl]
# 
eval {
    Log::Log4perl::ConfigByInifile->new(
        {
            ini_file => $bad_ini_fqn,
        }
    );
};
ok( $@, "new dies if arg ini_file without section log4perl");

# must survive with good ini_file
eval {
    Log::Log4perl::ConfigByInifile->new(
        {
            ini_file => $good_ini_fqn,
        }
    );
};
ok( ! $@, "new survives with arg ini_file with section log4perl");

# Is Log4perl initialized right?
my $logger;

$logger = Log::Log4perl->get_logger('main');
is( $logger->level(), $Log::Log4perl::INFO, 
    'Loglevel of main is INFO') ;

$logger = Log::Log4perl->get_logger('somewhere_must_inherit_from_main');
is( $logger->level(), $Log::Log4perl::INFO, 
    'Loglevel of somewhere is INFO') ;

$logger = Log::Log4perl->get_logger('juhei');
is( $logger->level(), $Log::Log4perl::DEBUG,
    'Loglevel of juhei is DEBUG') ;


# my $object = Log::Log4perl::ConfigByInifile->new ();
# isa_ok ($object, 'Log::Log4perl::ConfigByInifile');

