package ExtUtils::FakeConfig;

use strict;

require File::Spec;
require Config;

use vars qw($VERSION);

$VERSION = '0.12';

sub import {
  shift;
  my $obj = tied %Config::Config;
  my $key;

  while( $key = shift ) {
    $obj->{$key} = shift;
  }
}

sub find_program {
  my @path = File::Spec->path();

  # we can't use Config here...
  foreach my $prog ( map { ( $_, "$_.exe" ) } @_ ) {
    foreach my $path ( @path ) {
      if( -f File::Spec->catfile( $path, $prog ) ) {
        $prog =~ s/\.exe//;
        return ( $path, $prog );
      }
    }
  }

  return;
}

1;

__END__

=head1 NAME

ExtUtils::FakeConfig - override %Config values on-the-fly

=head1 SYNOPSIS

  use ExtUtils::FakeConfig cc => 'gcc', make => 'gmake';

=head1 DESCRIPTION

This module is basically an hack to be used in Makefile.PL invocation:
create a driver module like

    package my_Config:

    use ExtUtils::FakeConfig cflags => '-lfoo -O14', ld => 'g++';

    1;

and invoke

    perl -Mmy_Config Makefile.PL

=head1 FUNCTIONS

=head2 import

  ExtUtils::FakeConfig->import( name1 => value1, name2 => value2 );

Usually called through use(); overrides values from %Config.

=head2 find_program 

  my $executable = ExtUtils::FakeConfig::find_program( $program1, $program2 );

Returns the absolute path of the first of the programs given as arguments found
in the program search path.

=head1 AUTHOR

Mattia Barbon <mbarbon@cpan.org>

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
