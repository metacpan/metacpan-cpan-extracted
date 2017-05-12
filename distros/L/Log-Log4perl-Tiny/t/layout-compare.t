#!perl -T
use Test::More;

BEGIN {
   plan skip_all => 'these tests are for testing by the author'
     unless $ENV{AUTHOR_TESTING};
   plan skip_all => 'these tests are not run in continuous integration'
     if $ENV{CONTINUOUS_INTEGRATION};

   # else... let's just test!
   plan tests => 6;
} ## end BEGIN

use Symbol qw< gensym >;
use IPC::Open3;
use Config;
use Path::Tiny;

# get some useful paths
my $me         = path(__FILE__)->realpath();
my $md         = $me->parent();
my $lib        = $md->sibling('lib')->stringify();
my $local_lib  = $md->sibling(qw< local lib perl5 >)->stringify();
my $layout_cmp = $md->child('layout-compare.pl')->stringify();
$md = $md->stringify();

# securely get the Perl path
my $perl_path = $Config{perlpath};
$perl_path .= $Config{_exe}
   if ($^O ne 'VMS') && ($perl_path !~ m<$Config{_exe}$>i);

delete $ENV{PATH}; # avoid taint complains
for my $expander (qw< C F l L M T >) {
   my $got = invoke_compare('Log::Log4perl::Tiny', $expander);
   my $exp = invoke_compare('Log::Log4perl', $expander);
   is $got, $exp, "expansion of %$expander";
}

done_testing();

sub invoke_compare {
   my ($module, $expander) = @_;
   my @command = (
      $perl_path,
      -I => $md,
      -I => $lib,
      -I => $local_lib,
      $layout_cmp,
      $module,
      $expander
   );
   my ($child_in, $child_out);
   my $child_err = gensym();
   my $pid = open3($child_in, $child_out, $child_err, @command);

   local $/;
   my $retval = <$child_err>;
   <$child_out>; # exhaust output

   $retval =~ s{CODE\([^)]+\)}{CODE(...)}gmxs;
   return $retval;
}
