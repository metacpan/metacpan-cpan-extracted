use strict;

# Copyright    : Copyright (c) 2013-2018 Mark Dootson
# License      : This is free software; you can redistribute it and/or modify it under
#                the same terms as the Perl 5 programming language system itself.

use lib 'inc';
require Module::Build::HiPi;

our $VERSION ='0.81';

my $requires = {
        'Try::Tiny'             => '0',
        'File::Slurp'           => '0',
        'UNIVERSAL::require'    => '0',
        'JSON'                  => '0',
        'Getopt::Long'          => '0',
        'Bit::Vector'           => '0',
};

if( $^O =~ /^linux$/i ) {
    $requires->{'Device::SerialPort'} = '0';
    $requires->{'Image::Imlib2'}      = '0';
    $requires->{'XML::LibXML'}        = '0';
    $requires->{'LWP::UserAgent'}     = '0';
    $requires->{'MIME::Base64'}       = '0';
    $requires->{'Digest::SHA'}        = '0';
}

my $build = Module::Build::HiPi->new(
	module_name         => 'HiPi',
	license             => 'Perl_5',
	dist_author         => q{Mark Dootson <mdootson@cpan.org>},
	dist_version_from   => 'lib/HiPi.pm',
	configure_requires  => {
        'perl'          => '5.14.0',
	    'Module::Build' => '0',
	},
    build_requires  => {
        'File::Copy::Recursive' => '0'
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
	dist_abstract    => 'Raspberry Pi GPIO Perl Modules',
    dist_description => 'Manage Raspberry Pi GPIO and peripherals',
    
    script_files    => 'script',
    
    create_packlist => ( $ENV{'HIPI_BUILD_SKIP_PACKLIST'} ) ? 0 : 1,
);

{ # Get Options
        
    if( $ENV{PERL5_CPAN_IS_RUNNING} || $ENV{PERL5_CPANPLUS_IS_RUNNING} || $ENV{PERL5_CPAN_IS_EXECUTING} ) {
        $build->notes( cpanskip  => 1 );
    } else {
        $build->notes( cpanskip  => 0 );
    }
}

$build->create_build_script();

1;
