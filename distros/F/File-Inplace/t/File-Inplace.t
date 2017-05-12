use strict;
use Test::More tests => 21;
use File::Copy;
use File::Spec;

BEGIN { use_ok('File::Inplace') };

my $data_dir = sub { File::Spec->catfile('t', shift); };
my $abc_file = $data_dir->("abc.txt");
my $cba_file = $data_dir->("cba.txt");
my $adc_file = $data_dir->("adc.txt");
my $csv_file = $data_dir->("csv.txt");
my $csv_squared_file = $data_dir->("csv-squared.txt");

# Test case 1, make sure a change, with a backup, works
{
  copy($abc_file, $data_dir->("test01.txt")) or die "copy: $!";

  my $edit = new File::Inplace(file => $data_dir->("test01.txt"), suffix => ".bak");
  quick_change($edit, b => 'd');
  $edit->commit;

  ok(same_file($data_dir->("test01.txt"), $adc_file), "file changed properly");
  ok(same_file($abc_file, $data_dir->("test01.txt.bak")), "backup unchanged");
}

# Test case 2, make sure a change, with a backup, can save changes only to the backup
{
  copy($abc_file, $data_dir->("test02.txt")) or die "copy: $!";

  my $edit = new File::Inplace(file => $data_dir->("test02.txt"), suffix => ".bak");
  quick_change($edit, b => 'd');
  $edit->commit_to_backup;

  ok(same_file($data_dir->("test02.txt"), $abc_file), "original unchanged");
  ok(same_file($adc_file, $data_dir->("test02.txt.bak")), "changes written to backup");
}

# Test case 3, make sure a rollback works
{
  copy($abc_file, $data_dir->("test03.txt")) or die "copy: $!";

  my $edit = new File::Inplace(file => $data_dir->("test03.txt"), suffix => ".bak");
  quick_change($edit, b => 'd');
  $edit->rollback;

  ok(same_file($data_dir->("test03.txt"), $abc_file), "original unchanged");
  ok(same_file($abc_file, $data_dir->("test03.txt.bak")), "backup unchanged");
}

# Test case 4, make sure an edit w/o a backup works
{
  copy($abc_file, $data_dir->("test04.txt")) or die "copy: $!";
  my $edit = new File::Inplace(file => $data_dir->("test04.txt"));
  quick_change($edit, b => 'd');
  $edit->commit;

  ok(same_file($data_dir->("test04.txt"), $adc_file), "original changed");
  ok(file_not_there($data_dir->("test04.txt.bak")), "backup does not exist");
}

# Test case 5, make sure an rolled back edit w/o a backup works
{
  copy($abc_file, $data_dir->("test05.txt")) or die "copy: $!";
  my $edit = new File::Inplace(file => $data_dir->("test05.txt"));
  quick_change($edit, b => 'd');
  $edit->rollback;

  ok(same_file($data_dir->("test05.txt"), $abc_file), "original unchanged");
  ok(file_not_there($data_dir->("test05.txt.bak")), "backup does not exist");
}

# Test case 6, make sure non-chomping works
{
  copy($abc_file, $data_dir->("test06.txt")) or die "copy: $!";
  my $edit = new File::Inplace(file => $data_dir->("test06.txt"), chomp => 0);
  quick_change($edit, b => 'd');
  $edit->commit;

  ok(same_file($data_dir->("test06.txt"), $abc_file), "original unchanged");
  ok(file_not_there($data_dir->("test06.txt.bak")), "backup does not exist");
}

# Test case 7, make sure non-chomping works
{
  copy($csv_file, $data_dir->("test07.txt")) or die "copy: $!";
  my $edit = new File::Inplace(file => $data_dir->("test07.txt"), separator => ",");

  while ($edit->has_lines) {
    my @fields = $edit->next_line_split;
    $fields[$_] **= 2 for 0 .. $#fields;
    $edit->replace_line(@fields);
  }

  $edit->commit;

  ok(same_file($data_dir->("test07.txt"), $csv_squared_file), "csv edit successful");
  ok(file_not_there($data_dir->("test07.txt.bak")), "backup does not exist");
}

# Test case 8, array access works
{
  copy($abc_file, $data_dir->("test08.txt")) or die "copy: $!";
  my $edit = new File::Inplace(file => $data_dir->("test08.txt"));
  my @lines = $edit->all_lines;
  $edit->replace_lines(reverse @lines);
  $edit->commit;

  ok(same_file($data_dir->("test08.txt"), $cba_file), "array edit successful");
  ok(file_not_there($data_dir->("test08.txt.bak")), "backup does not exist");
}

# Test case 9, simplified interface works
{
  copy($abc_file, $data_dir->("test09.txt")) or die "copy: $!";

  my $edit = new File::Inplace(file => $data_dir->("test09.txt"));
  while (my ($line) = $edit->next_line) {
    if ($line eq 'b') {
      $edit->replace_line('d');
    }
  }
  $edit->commit;

  ok(same_file($data_dir->("test09.txt"), $adc_file), "file changed properly");
  ok(file_not_there($data_dir->("test09.txt.bak")), "backup does not exist");
}

# Test case 10, abort changes half way through
{
  copy($abc_file, $data_dir->("test10.txt")) or die "copy: $!";

  my $edit = new File::Inplace(file => $data_dir->("test10.txt"));

  # this simulates, say, an exception being raised halfway through a change
  while (my ($line) = $edit->next_line) {
    if ($line eq 'a') {
      $edit->replace_line('x');
    }
    if ($line eq 'b') {
      last;
    }
  }
  undef $edit;

  ok(same_file($data_dir->("test10.txt"), $abc_file), "file unchanged");
  ok(file_not_there($data_dir->("test10.txt.bak")), "backup does not exist");
}

sub quick_change {
  my $edit = shift;
  my $from = shift;
  my $to = shift;

  while ($edit->has_lines) {
    my $line = $edit->next_line;
    if ($line eq $from) {
      $edit->replace_line($to);
    }
  }
}

sub same_file {
  my $file_a = shift;
  my $file_b = shift;

  local $/ = undef;

  open FHA, "<$file_a" or die "open $file_a: $!";
  my $a = <FHA>;

  open FHB, "<$file_b" or die "open $file_b: $!";
  my $b = <FHB>;

  close FHA; close FHB;

  return $a eq $b;
}

sub file_not_there {
  my $file = shift;

  return not -e $file;
}
