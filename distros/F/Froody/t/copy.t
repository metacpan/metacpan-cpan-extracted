#!/usr/bin/perl

####################################################################
# This test ensures that all the Perl Modules and POD in this
# distribution have the correct Fotango copyright sections
####################################################################

use strict;
use warnings;

# use the local directory.  Note that this doesn't work
# with prove.  Darn!
use File::Spec::Functions;
use FindBin;
use lib catdir($FindBin::Bin, "lib");

# lots of standard helper modules that I like to have
# loaded for all test scripts
use Cwd;
use File::Copy qw(move copy);
use File::Path qw(mkpath rmtree);

# useful diagnostic modules that's good to have loaded
use Data::Dumper;
use Devel::Peek;

# colourising the output if we want to
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

# load any enviromental variables set by the child
sub enable_command_line_options
{
  eval q{
    use Module::Build;
    my $build = Module::Build->current;
    foreach (keys %{ $build->notes() })
    {
      my $key = $_;
      s/^option_//;
      $ENV{ $_ } = $build->notes( $key )
       unless exists $ENV{ $_ }
    }
  }
}

###################################
# user editable parts

# Test modules we might want to use:
# use Test::DatabaseRow;
# use Test::Exception;

# do we want to get the values from Module Build?
# (turning this on is slower, but nicer)
# enable_command_line_options;

my @files;

BEGIN {
  use File::Find::Rule;
  @files = File::Find::Rule->file()->name('[A-Z]*.pm', '*.pod')
                                   ->in(catdir($FindBin::Bin, updir,'lib'));
}

use Test::More tests => ((@files-1) * 1);

foreach my $filename (@files)
{
  next if $filename =~ /Froody.pm$/;

  undef $/;
  open my $fh, "<", $filename
    or die "Eeeek! Can't open '$filename': $!";
  my $file = <$fh>;
  close $fh;
  
  # does this contain our standard copyright disclaimer?
  ok($file =~ m{ 
\QCopyright Fotango 200\E\d.\Q  All rights reserved\E.
\s*
\QPlease see the main L<Froody> documentation for details of who has worked
on this project.\E
\s*
\QThis module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.\E
}mx, "$filename contains copyright");
}
