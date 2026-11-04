use 5.036;
use utf8;
use warnings FATAL => 'utf8';
use open ':std', ':encoding(UTF-8)';
use Test2::V0;
use File::Temp qw(tempdir);
use Path::Tiny;
use Cpanel::JSON::XS;
use Finance::Tiller2QIF::WriteQIF;
use Finance::Tiller2QIF::Interactive;

plan skip_all => 'Windows viewer command integration' unless $^O eq 'MSWin32';

my $dir = tempdir(CLEANUP => 1);
my $recorder = "$dir/record arguments.pl";
my $marker = "$dir/arguments.json";
path($recorder)->spew_utf8(<<'RECORDER');
use 5.036;
use utf8;
use warnings FATAL => 'utf8';
use Path::Tiny;
use Cpanel::JSON::XS;
my $marker = shift @ARGV;
path($marker)->spew_utf8(Cpanel::JSON::XS->new->encode(\@ARGV));
RECORDER

# Editors such as VS Code use a .cmd entry point on Windows. Exercise that
# path as well as quoted program arguments and literal shell metacharacters.
my $wrapper = "$dir/viewer ' & with spaces.cmd";
path($wrapper)->spew_utf8(qq{\@echo off\r\n"$^X" "$recorder" "$marker" %*\r\n});
my $viewer = qq{"$wrapper" --wait "option with spaces"};
local $ENV{TILLER_VIEWER_TEST} = 'must not replace the file name';
my $map = "$dir/rules ' & %TILLER_VIEWER_TEST% ! ^.map";
my $sql = "$dir/corrections ' & %TILLER_VIEWER_TEST% ! ^.t2qsql";
path($_)->spew_utf8('test file') for $map, $sql;

my ($preview, $out);
{
  open local *STDOUT, '>:encoding(UTF-8)', \$out or die $!;
  ok(lives {
    $preview = Finance::Tiller2QIF::WriteQIF::_launch_viewer($viewer, 'preview text', $map, $sql);
  }, 'preview launches a Windows command wrapper');
}
is(Cpanel::JSON::XS->new->decode(path($marker)->slurp_utf8),
  ['--wait', 'option with spaces', $preview, $map, $sql],
  'preview preserves options and literal file names');

{
  open local *STDOUT, '>:encoding(UTF-8)', \$out or die $!;
  ok(lives {
    Finance::Tiller2QIF::Interactive::_view({
      options => { viewer => $viewer, mapfile => $map, corrections => $sql },
      review => { preview => $preview, count => 1 },
    });
  }, 'interactive review launches the Windows viewer without publication');
}
is(Cpanel::JSON::XS->new->decode(path($marker)->slurp_utf8),
  ['--wait', 'option with spaces', $preview, $map, $sql],
  'interactive review preserves the preview, map and SQL arguments');

chmod 0600, $preview or die $!;
unlink $preview or die $!;
done_testing;
