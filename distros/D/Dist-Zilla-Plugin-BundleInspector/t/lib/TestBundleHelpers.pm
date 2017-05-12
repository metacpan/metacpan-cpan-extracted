use strict;
use warnings;

package # no_index
  TestBundleHelpers;

use Path::Class qw( file dir );
use Test::More;
use Test::Differences;

our @EXPORT = qw(
  eq_or_diff
  file
  dir
  pod_eq_or_diff
  disk_file
  zilla_file
);

sub import {
  my $pkg = caller;
  no strict 'refs';
  *{ $pkg . '::' . $_ } = \&$_
    for @EXPORT;
}

sub pod_eq_or_diff ($$$) {
  my ($got, $exp, $desc) = @_;
  eq_or_diff( ($got =~ /(=head1.+=cut\n)/s)[0], $exp, $desc );
}

sub disk_file {
  my ($root, $name) = @_;
  return $root->file($name);
}

sub zilla_file {
  my ($name, $files) = @_;
  $name = $name->as_foreign('Unix');
  return ( grep { $_->name eq $name } @$files )[0];
}

1;
