use strict;

use lib 'inc';
require Module::Build::HiPi::BCM2835;

our $VERSION ='0.65';

my $requires = {
        'HiPi'             => '0.80',
        'threads::shared'  => '0',
};


my $build = Module::Build::HiPi::BCM2835->new(
	module_name         => 'HiPi::BCM2835',
	license             => 'GPL_3',
	dist_author         => q{Mark Dootson <mdootson@cpan.org>},
	dist_version_from   => 'lib/HiPi/BCM2835.pm',
	configure_requires  => {
        'perl'          => '5.14.0',
	    'Module::Build' => '0',
	},
    requires            => $requires,
	add_to_cleanup => [
        '*.o',
        'blib',
        '*.a',
        '*.so',
        '*.c',
        '*.xsc',
        '*.bs',
        '*.mksf',
	],
	meta_merge => {
        resources => {
            homepage   => 'http://raspberry.znix.com/',
        },
        no_index => {
            directory => [qw<inc modlib userbin>],
        },
	},
	dist_abstract    => 'Interface to BCM2835 library',
    dist_description => 'Interface to BCM2835 library',
    
    # script_files    => 'script',

);

{ # Get Options
    
    #my $doupdate  = _hipi_option_is_yes($build->args('hipi-update'));
    #
    #$build->notes( doupdate     => $doupdate );
    
    if( $ENV{PERL5_CPAN_IS_RUNNING} || $ENV{PERL5_CPANPLUS_IS_RUNNING} || $ENV{PERL5_CPAN_IS_EXECUTING} ) {
        $build->notes( cpanskip  => 1 );
    } else {
        $build->notes( cpanskip  => 0 );
    }
}

$build->create_build_script();

sub _hipi_option_is_yes {
    return lc( $_[0] ) eq 'y' || lc( $_[0] ) eq 'yes' || $_[0] eq 1;
}

1;
