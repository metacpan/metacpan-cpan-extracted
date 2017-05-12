package InlineX::XS::MM;
use strict;
use warnings;

our $VERSION = 0.01;

require InlineX::XS;
use ExtUtils::MakeMaker;
use ExtUtils::Manifest 'maniadd';

sub import {
    my $class = shift;
    my @args = @_;

    $InlineX::XS::PACKAGE = $InlineX::XS::PACKAGE = 1;
    $InlineX::XS::PACKAGER = $InlineX::XS::PACKAGER = 'InlineX::XS::MM';

    warn 'Setting PACKAGE and PACKAGER options';
    unshift(@INC, 'lib');
    chdir($args[0]) if defined $args[0];
    return 1;
}

sub hook_after_c2xs {
    my $class = shift;
    my $pkg = shift;

    warn 'Adding XS and C files to MANIFEST';
    $pkg =~ /([^:]+)$/;
    my $xs_file = $1 or die;
    my $c_file = "src/$xs_file.c"; # no File::Spec => MANIFEST
    $xs_file .= '.xs';
    my $args = {
        $xs_file => 'Added by '.__PACKAGE__,
        $c_file => 'Added by '.__PACKAGE__,
    };
    $args->{'INLINE.h'} = 'Added by '.__PACKAGE__
      if -e 'INLINE.h';

    maniadd($args);
    return 1;
}

1;

