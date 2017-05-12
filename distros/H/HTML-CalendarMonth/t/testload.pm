package testload;

use vars qw( @ISA @EXPORT $Dat_Dir );

use strict;
use warnings;
use Test::More;

use Cwd qw( abs_path );

my $DEBUG = 0;

require Exporter;
@ISA = qw(Exporter);

use vars qw(
  $Dat_Dir
  $Bulk_File
  $Head_File
  $Odd_File
  $Woy_File
  $Narrow_File
  $I8N_File
  $I8N_Legacy1_File
  $I8N_Legacy2_File
);

@EXPORT = qw(
  $Dat_Dir
  $Bulk_File $Head_File $Odd_File $Woy_File $I8N_File $Narrow_File
  check_datetool
  check_bulk_with_datetool
  check_odd_with_datetool
  check_woy_with_datetool
  check_i8n
  check_narrow

  bulk_count
  odd_count
  woy_count
  i8n_count
  narrow_count

  clean
);

use File::Spec;

use HTML::CalendarMonth;
use HTML::CalendarMonth::DateTool;

BEGIN {
  my($vol, $dir, $file) = File::Spec->splitpath(abs_path(__FILE__));
  $dir = File::Spec->catdir($dir, 'dat');
  $Dat_Dir = File::Spec->catpath($vol, $dir, '');
}

$Bulk_File       = File::Spec->catdir($Dat_Dir,    'bulk.dat');
$Head_File       = File::Spec->catdir($Dat_Dir,    'head.dat');
$Odd_File        = File::Spec->catdir($Dat_Dir,     'odd.dat');
$Woy_File        = File::Spec->catdir($Dat_Dir,     'woy.dat');
$Narrow_File     = File::Spec->catdir($Dat_Dir,  'narrow.dat');
$I8N_File        = File::Spec->catdir($Dat_Dir,     'i8n.dat');
$I8N_Legacy1_File = File::Spec->catdir($Dat_Dir, 'i8n_leg1.dat');
$I8N_Legacy2_File = File::Spec->catdir($Dat_Dir, 'i8n_leg2.dat');

my(@Bulk, @Head, @Odd, @Woy, @I8N, @Nar);

sub _load_file {
  my $f   = shift;
  my $cal = shift || [];
  local(*F);
  return unless open(F, '<', $f);
  while (my $h = <F>) {
    chomp $h;
    my($d, $wb, @other) = split(/\s+/, $h);
    my($y, $m) = split(/\//, $d);
    my $c = <F>;
    chomp $c;
    push(@$cal, [$d, $y, $m, $wb, \@other, clean($c)]);
  }
  $cal;
}

_load_file($Bulk_File, \@Bulk    );
_load_file($Head_File,  \@Head   );
_load_file($Odd_File,    \@Odd   );
_load_file($Woy_File,     \@Woy  );
_load_file($Narrow_File,   \@Nar);

if (HTML::CalendarMonth::Locale->_locale_version >= 1.03) {
  _load_file($I8N_File, \@I8N );
}
elsif (HTML::CalendarMonth::Locale->_locale_version >= 0.93) {
  _load_file($I8N_Legacy2_File, \@I8N );
}
else {
  _load_file($I8N_Legacy1_File, \@I8N );
}

sub bulk_count   { scalar @Bulk }
sub head_count   { scalar @Head }
sub odd_count    { scalar @Odd  }
sub woy_count    { scalar @Woy  }
sub i8n_count    { scalar @I8N  }
sub narrow_count { scalar @Nar  }

# Today's date
my($month, $year) = (localtime(time))[4,5];
++$month;
$year += 1900;

my $today         = sprintf("%d/%02d", $year, $month);
my $year_from_now = sprintf("%d/%02d", $year+1, $month);

# keep the next year
@Bulk = grep { $_ ge $today && $_->[0] le $year_from_now } @Bulk;

###

sub clean {
  my $str = shift || Carp::confess "string required";
  $str =~ s/^\s*//; $str =~ s/\s*$//;
  # guard against HTML::Tree starting to quote numeric attrs as of
  # v3.19_02
  $str =~ s/\"(\d+)\"/$1/g;
  $str;
}

sub check_datetool {
  my $datetool = shift;
  my $module = HTML::CalendarMonth::DateTool->_toolmap($datetool);
  ok($module, "toolmap($datetool) : $module");
  require_ok($module);
}

sub check_bulk_with_datetool {
  my $datetool = shift;
  my @days;
  foreach (@Bulk) {
    my($d, $y, $m, $wb, $other, $tc) = @$_;
    my $c = HTML::CalendarMonth->new(
      year       => $y,
      month      => $m,
      week_begin => $wb,
      datetool   => $datetool,
    );
    @days = $c->dayheaders unless @days;
    my $day1 = $days[$wb - 1];
    my $method = $c->_caltool->_name;
    $method = "auto-select ($method)" unless $datetool;
    my $msg = sprintf(
      "(%d/%02d %s 1st day) using %s",
      $y, $m, $day1, $method
    );
    cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
  }
}

sub check_head_with_datetool {
  my $datetool = shift;
  my @days;
  foreach (@Head) {
    my($d, $y, $m, $wb, $other, $tc) = @$_;
    my($hm, $hy, $hd, $hw) = @$other;
    my $c = HTML::CalendarMonth->new(
      year       => $y,
      month      => $m,
      week_begin => $wb,
      head_m     => $hm,
      head_y     => $hy,
      head_dow   => $hd,
      head_week  => $hw,
      datetool   => $datetool,
    );
    my $method = $c->_caltool->_name;
    $method = "auto-select ($method)" unless $datetool;
    my $msg = sprintf(
      "(%d/%02d hm:%d hy:%d hd:%d hw:%d) using %s",
      $y, $m, $hm, $hy, $hd, $hw, $method
    );
    cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
  }
}

sub check_odd_with_datetool {
  my $datetool = shift;
  my @days;
  foreach (@Odd) {
    my($d, $y, $m, $wb, $other, $tc) = @$_;
    SKIP: {
      my $c;
      eval {
        $c = HTML::CalendarMonth->new(
          year       => $y,
          month      => $m,
          week_begin => $wb,
          datetool   => $datetool,
        );
      };
      if ($@ || !$c) {
        croak $@ unless $@ =~ /(no|in)\s*valid date tool/i;
        skip("$datetool odd $y/$m", 1);
      }
      @days = $c->dayheaders unless @days;
      my $day1 = $days[$wb - 1];
      my $method = $c->_caltool->_name;
      $method = "auto-select ($method)" unless $datetool;
      my $msg = sprintf(
        "(%d/%02d %s 1st day) using %s",
        $y, $m, $day1, $method
      );
      cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
    }
  }
}

sub check_woy_with_datetool {
  my $datetool = shift;
  foreach (@Woy) {
    my($d, $y, $m, $wb, $other, $tc) = @$_;
    my $c = HTML::CalendarMonth->new(
      year       => $y,
      month      => $m,
      head_week  => 1,
      datetool   => $datetool,
    );
    my $msg = sprintf("(%d/%02d week of year) using %s", $y, $m, $datetool);
    cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
  }
}

sub check_i8n {
  foreach (@I8N) {
    my($d, $y, $m, $id, $other, $tc) = @$_;
    my $c = HTML::CalendarMonth->new(
      year   => $y,
      month  => $m,
      locale => $id,
    );
    my $name = $c->loc->loc->name;
    my $msg = sprintf(
      "(%d/%02d i8n) %s (wb:%d) using auto-detect",
      $y, $m, $name, $c->week_begin
    );
    cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
  }
}

sub check_narrow {
  my @days;
  foreach (@Nar) {
    my($d, $y, $m, $wb, $other, $tc) = @$_;
    my $c = HTML::CalendarMonth->new(
      year       => $y,
      month      => $m,
      week_begin => $wb,
      full_days  => -1,
    );
    @days = $c->dayheaders unless @days;
    my $day1 = $days[$wb - 1];
    my $msg = sprintf(
      "(%d/%02d %s/%s 1st day) narrow/alias using auto-detect",
      $y, $m, $day1, $c->item_alias($day1)
    );
    cmp_ok(clean($c->as_HTML), 'eq', $tc, $msg);
  }
}

sub debug_dump {
  my($l1, $str1, $l2, $str2) = @_;
  local(*DUMP);
  open(DUMP, ">$DEBUG") or die "Could not dump to $DEBUG: $!\n";
  print DUMP "<html><body><table><tr><td>$l1</td><td>$l2</td></tr><tr><td>\n";
  print DUMP "$str1\n</td><td>\n";
  print DUMP "$str2\n</td></tr></table></body></html>\n";
  close(DUMP);
  print STDERR "\nDumped tables to $DEBUG. Aborting test.\n";
  exit;
}

1;
