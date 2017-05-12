#
# This file is part of Git-DescribeVersion
#
# This software is copyright (c) 2010 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package # no_index
  inc::GitVersion;

# 1.5 renamed git-repo-config to git-config
# 1.5.5 added --match to git-describe
our @MIN = qw( 1 5 5 );

sub import {
  shift->require_minimum;
}

sub check_minimum {
  my ($class, $version) = @_;
  $version ||= $class->version;

  my @parts = split(/\./, ($version =~ m/(?:git\sversion\s)?(\d+(\.\d+)*)/)[0]);

  foreach my $i ( 0 .. $#MIN ){
    # if not equal
    if( my $cmp = $parts[$i] <=> $MIN[$i] ){
      # return true if version is sufficient (greater) false if not (lesser)
      return $cmp > 0;
    }
  }

  return 1; # not less or greater, must be equal
}

sub require_minimum {
  my ($class, $version) = @_;
  $version ||= $class->version;
  $class->check_minimum($version)
    or die <<MSG;
 # Git version 1.5.5+ required.
 # Found: $version
 #
 # If you believe this to be an error please submit a bug report
 # including the output of `git --version`.
MSG
}

sub version {
  chomp(my $v = qx/git --version/);
  $v;
}

1;
