use strict;
use warnings;

# dummy version of [Libarchive] so that doesn't get
# used
package Dist::Zilla::Plugin::Libarchive 0.1 {
  $INC{'Dist/Zilla/Plugin/Libarchive.pm'} = __FILE__;
};

my @list = sort map { chomp; s/\.pm$//; s/^lib\///; s/\//::/g; $_ } `find lib -name \*.pm`;

open my $fh, '>', 't/01_use.t';

print $fh <<'EOM';
use Test2::V0 -no_srand => 1;

sub require_ok ($);

EOM

foreach my $module (@list)
{
  print $fh "require_ok '$module';\n";
}

print $fh <<'EOM';
done_testing;

sub require_ok ($)
{
  # special case of when I really do want require_ok.
  # I just want a test that checks that the modules
  # will compile okay.  I won't be trying to use them.
  my($mod) = @_;
  my $ctx = context();
  my $pm = "$mod.pm";
  $pm =~ s/::/\//g;
  eval { require $pm };
  my $error = $@;
  my $ok = !$error;
  $ctx->ok($ok, "require $mod");
  $ctx->diag("error: $error") if $error ne '';
  $ctx->release;
}
EOM

close $fh;


