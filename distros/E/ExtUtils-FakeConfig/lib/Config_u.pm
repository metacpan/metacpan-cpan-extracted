package Config_u;

require ExtUtils::FakeConfig;
require Config;

my %values =
  ( lddlflags => ' -arch i386 -arch ppc ' . $Config::Config{lddlflags},
    ccflags   => ' -arch i386 -arch ppc ' . $Config::Config{ccflags},
    );

ExtUtils::FakeConfig->import( %values );

1;

__DATA__

=head1 NAME

Config_u - compile Mac OS X modules as Universal binaries

=head1 SYNOPSIS

  perl -MConfig_u Makefile.PL
  make
  make test
  make install

with CPAN.pm/CPANPLUS.pm

  set PERL5OPT=-MConfig_u
  cpanp

=head1 DESCRIPTION

This module is only useful at Makefile.PL invocation time. It modifies
some %Config values allowing compilation of Perl XS modules as
Universal binaries.  Note that the safest way to build Universal
binaries is to compile the modules separately and then use lipo(1) to
merge the resulting .bundle files.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=cut
