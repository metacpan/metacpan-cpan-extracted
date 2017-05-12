#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2011 Christopher J. Madsen
#
# Test Dist::Zilla plugin for Pod::Loom
#---------------------------------------------------------------------

use strict;
use warnings;
use 5.008;
use utf8;

use Test::More 0.88;  # want done_testing

use Test::DZil qw(Builder);
use Encode qw(decode);

# Load Test::Differences, if available (better output for failures):
BEGIN {
  # SUGGEST PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

#=====================================================================
my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>:utf8', '/tmp/10-podloom.t') or die $!;
  printf OUT "#%s\nmy %%expected;\n", '=' x 69;
} else {
  plan tests => 3;
}

#=====================================================================
my %expected;

$expected{'module'} = <<'END EXPECTED MODULE';
package DZT::Sample;
# ABSTRACT: Sample DZ Dist

use strict;
use warnings;

our $VERSION = '0.04';

1;

__END__

=encoding utf8

=head1 NAME

DZT::Sample - Sample DZ Dist

=head1 VERSION

This is the version section.

=head1 SYNOPSIS

  use DZT::Sample;

=head1 DEPENDENCIES

DZT::Sample requires ümlauts.

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

=cut
END EXPECTED MODULE

$expected{'script'} = <<'END EXPECTED SCRIPT';
#! /usr/bin/perl

# ABSTRACT: Sample DZ script

use strict;
use warnings;

use DZT::Sample;

our $VERSION = '0.04';

print "Hello, world!\n";

__END__

=head1 NAME

script - Sample DZ script

=head1 VERSION

This is the version section.

=head1 SYNOPSIS

  script [FILE]...

=head1 CONFIGURATION AND ENVIRONMENT

script requires no configuration files or environment variables.

=head1 AUTHOR

E. Xavier Ample  S<C<< <example AT example.org> >>>

=cut
END EXPECTED SCRIPT

#=====================================================================
sub check_file
{
  my ($tzil, $name, $path) = @_;

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $got = $tzil->slurp_file($path);
  $got = decode('utf8', $got) if Dist::Zilla->VERSION < 5;

  $got =~ s/\n(?:[ \t]*\n)+/\n\n/g; # Normalize blank lines

  if ($generateResults) {
    printf OUT ("\n\$expected{'%s'} = <<'END EXPECTED %s';\n%sEND EXPECTED %s\n",
                $name, uc($name), $got, uc($name));
  } else {
    eq_or_diff($got, $expected{$name}, "expected $name content");
  }
} # end check_file

{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
  );

  $tzil->build;
  ok(1, 'built ok') unless $generateResults;

  #printf STDERR "\n# %s\n", $tzil->root; $_ = <STDIN>;

  check_file($tzil, module => 'build/lib/DZT/Sample.pm');
  check_file($tzil, script => 'build/bin/script');
}

if ($generateResults) {
  printf OUT "\n#%s\n", '=' x 69;
} else {
  done_testing;
}

# Local Variables:
# compile-command: "cd .. && perl t/10-podloom.t gen"
# End:
