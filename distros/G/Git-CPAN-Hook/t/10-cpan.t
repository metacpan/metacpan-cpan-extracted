use strict;
use warnings;
use Test::More;

my %cpan = (
    'CPAN::Distribution::install'   => 'Git::CPAN::Hook::_install',
    'CPAN::HandleConfig::neatvalue' => 'Git::CPAN::Hook::_neatvalue',
);

plan tests => 4 * keys %cpan;

no strict 'refs';

# now load the module, but not CPAN.pm
require Git::CPAN::Hook;

# check the CPAN.pm routines are not defined
ok( !defined &$_, "CPAN.pm not loaded yet, $_ is not defined" )
    for keys %cpan;

# "unload" Git::CPAN::Hook
delete $INC{'Git/CPAN/Hook.pm'};

# now load CPAN.pm and check the CPAN.pm routines are now defined
require CPAN;
ok( defined &$_, "CPAN.pm loaded, $_ has been defined" ) for keys %cpan;

# collect the addresses of the CPAN.pm routines
my %cpan_orig = map { ( $_ => \&$_ ) } keys %cpan;

# "reload" our module
{
    local $SIG{__WARN__} = sub { };    # ignore warnings!
    require Git::CPAN::Hook;
}

for ( keys %cpan ) {

    # check the addresses have changed
    isnt( \&$_, $cpan_orig{$_}, "$_ has been modified" );

    # check they point to the replacement code
    is( \&$_, \&{ $cpan{$_} }, "$_ is now $cpan{$_}" );
}

