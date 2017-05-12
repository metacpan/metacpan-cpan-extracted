use strict;
use warnings;
use inc::Module::Install;
use File::Copy;

name                'Imager-QRCode';
author              'Yoshiki KURIHARA <kurihara at cpan.org>';
all_from            'lib/Imager/QRCode.pm';

can_cc or die "This module requires a C compiler";

cc_inc_paths 'src';
cc_src_paths 'src';

configure_requires  'Imager'           => '0.55';
build_requires      'Imager'           => '0.55';
test_requires       'Test::More'       => 0;

auto_install;
WriteAll;

sub MY::post_constants {
    eval { require Imager::ExtUtils };
    if ( $@ ) {
        warn "*** You must install Imager.";
        exit 0; # tell cpan testers that this is not a failure
    }
    my $typemap  = Imager::ExtUtils->typemap;
    my $includes = Imager::ExtUtils->includes;
    return <<"POST_CONST";
XSUBPPARGS += -typemap $typemap
INC += $includes
CCFLAGS += -DOVER_LIBQRENCODE_2_0_0 -DHAVE_CONFIG_H
POST_CONST
}

