#!/usr/bin/perl -w

use strict;
use warnings;

use Module::Build;

if( $^O ne 'darwin' ) {
    print <<EOT; # for the user
==========================================================
This module only works under Mac OS X
==========================================================
EOT
    die "OS unsupported"; # for CPAN testers
}

if( !-d 'PerlWrapper' ) {
    die <<'EOT';
PerlWrapper sources not found, please run:

    git clone git://github.com/mbarbon/mac-perl-wrapper.git PerlWrapper

to download them.
EOT
}

my $CODE = <<'EOT';
sub ACTION_code {
    my( $self ) = @_;

    $self->SUPER::ACTION_code;

    my $pw_src = 'PerlWrapper';
    my $pw_dst = 'blib/lib/Mac/QuickBundle/PerlWrapper';

    for my $file ( qw(Source/PerlInterpreter.c Source/PerlInterpreter.h
                      Source/main.c Tools/update_dylib_references.pl
                      Resources/PerlWrapperApp.icns) ) {
        $self->copy_if_modified( from => "$pw_src/$file",
                                 to   => "$pw_dst/$file" );
    }
}
EOT

my $class = Module::Build->subclass
  ( class           => 'My::Build',
    code            => $CODE,
    );

my $build = $class->new
  ( module_name     => 'Mac::QuickBundle',
    license         => 'perl',
    requires =>
        { 'Config::IniFiles'     => 0,
          'Module::ScanDeps'     => 0,
          'File::Slurp'          => 0,
          'Module::Build'        => 0.28,
           },
    build_requires =>
        { 'Capture::Tiny'        => 0,
          },
    meta_merge =>
        { resources => { 'license'       => 'http://dev.perl.org/licenses/',
                         'repository'    => 'http://github.com/mbarbon/mac-quickbundle',
                         },
          },
    );
$build->create_build_script;
