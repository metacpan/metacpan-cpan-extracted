#!perl
use strict;
use warnings;
use Test::More;
use File::Find::Rex;
use feature 'say';

# Exclude hidden files that might get added by OS that could cause false
# negatives. (E.g., .DS_Store on MacOS).
my %options = (
  ignore_dirs => 1,
  ignore_hidden => 1,
);
my $context;

my $rex = new File::Find::Rex(\%options);
my $source = './xt/data';
my @files = $rex->query($source);
ok (scalar(@files) == 2);

$rex->set_option('ignore_dirs', 0);
@files = $rex->query($source);
ok (scalar(@files) == 6); # 6 files including the dirs

$rex->set_option('recursive', 1);
@files = $rex->query($source);
ok (scalar(@files) == 36); # 36 files including the dirs

@files = $rex->query($source, qr/^99/i);
ok(scalar(@files) == 14); # there are 7 files that start with 99 + 7 dirs

$rex->set_option('ignore_dirs', 1);
@files = $rex->query($source, qr/\.Dat$/);
ok(scalar(@files) == 1); # there are 11 .dat files

# verify finder regex test is case insentive
@files = $rex->query($source, qr/\.Dat$/i);
ok(scalar(@files) == 11); # there are 11 .dat files

@files = $rex->query($source, qr/^99/);
ok(scalar(@files) == 7); # there are 7 files that start with 99

@files = $rex->query($source, qr/(\.jpg|\.png)$/i);
ok(scalar(@files) == 11); # there are 11 image files (jpg & png)

# verify file as source
$source = './xt/data/logo.jpg';
@files = $rex->query($source);
ok(scalar(@files) == 1);

$source = './xt/data';

# verify callback method working
@files = ();
%options = (
  recursive => 1,
  ignore_dirs => 1,
  ignore_hidden => 1,
  );
$rex = new File::Find::Rex(\%options, \&callback);
$rex->query($source, qr/(\.jpg|\.png)$/i);
ok(scalar(@files) == 11); # there are 11 image files (jpg & png)

# verify context is working by passing reference to $rex object itself
@files = ();

$rex->query($source, qr/(\.jpg|\.png)$/, $rex);
ok($context->is_ignore_dirs == 1);

# verify callback method working w/ file as source
@files = ();
$source = './xt/data/logo.jpg';
$rex->query($source);
ok(scalar(@files) == 1);

done_testing();

sub callback {
  my ($file, $ctx) = @_;
  push @files, $file;
  if (defined $ctx)
  {
    $context = $ctx;
  }
}
