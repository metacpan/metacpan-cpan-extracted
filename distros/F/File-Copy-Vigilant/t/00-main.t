
use Test::More tests => 24;
use FindBin;
use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok(
        'File::Copy::Vigilant',
        qw( copy_vigilant copy cp move_vigilant move mv )
    );
    use_ok( 'File::Temp', qw(:POSIX) );
    use_ok( 'IO::File' );
}

my $from_file = tmpnam();
my $to_file = tmpnam();

write_random_file_contents($from_file)
  || BAIL_OUT("Unable to write to $from_file");

# Test as copy_vigilant
my ($success, @errors) = copy_vigilant($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run copy_vigilant");
unlink $to_file;

# Test as copy
($success, @errors) = copy($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run copy");
unlink $to_file;

# Test as cp
($success, @errors) = copy($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run cp");
unlink $to_file;

# Test as move_vigilant
($success, @errors) = move_vigilant($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run move_vigilant");
unlink $to_file;
write_random_file_contents($from_file);

# Test as move
($success, @errors) = move($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run move");
unlink $to_file;
write_random_file_contents($from_file);

# Test as mv
($success, @errors) = mv($from_file, $to_file);
$success || print STDERR '#', join('#', @errors);
ok($success, "run mv");
unlink $to_file;
write_random_file_contents($from_file);

# Test with nonexistent source
($success, @errors) = copy($to_file, $to_file.'2');
ok(!$success, "copy fails when source doesn't exits");

# Test with filehandle for source
my $TMP;
open $TMP, '<', $from_file;
($success, @errors) = copy($TMP, $to_file);
ok(!$success, "copy fails when source is a filehandle");
close $TMP;

# Test with filehandle for dest
open $TMP, '>', $to_file;
($success, @errors) = copy($from_file, $TMP);
ok(!$success, "copy fails when destination is a filehandle");
close $TMP;
unlink $to_file;

# Test with IO::File object for source
$TMP = IO::File->new($from_file,'r');
($success, @errors) = copy($TMP, $to_file);
ok(!$success, "copy fails when source is an IO::File object");
$TMP->close;

# Test with IO::File object for dest
$TMP = IO::File->new($from_file,'w');
($success, @errors) = copy($from_file, $TMP);
ok(!$success, "copy fails when destination is an IO::File object");
$TMP->close;
unlink $to_file;

# Test with non-default retries of 3, fail attempt 1, 2, and 3, succeed on 4
my $counter = 0;
($success, @errors) = copy(
    $from_file,
    $to_file,
    'retries'   => 3,
    '_postcopy' => sub {
        if (++$counter < 4) { write_random_file_contents($to_file); }
    }
);
$success || print STDERR '#', join('#', @errors);
ok($success, "nonstandard retries, fail all tries except last one");
unlink $to_file;

# Test with bogus code in postcopy, no retries
($success, @errors) = copy(
    $from_file,
    $to_file,
    'retries'   => 0,
    '_postcopy' => sub { die; }
);
ok(!$success, "fail when we put a die into postcopy");
unlink $to_file;

# Test with explicit md5 for success
($success, @errors) = copy_vigilant($from_file, $to_file, 'check' => 'md5');
$success || print STDERR '#', join('#', @errors);
ok($success, "copy with explicit check of md5");
unlink $to_file;

# Test md5 fails if we modify the destination file contents but not the
# size, no retries
($success, @errors) = copy(
    $from_file,
    $to_file,
    'check'     => 'md5',
    'retries'   => 0,
    '_postcopy' => sub { write_random_file_contents($to_file); }
);
ok(
    !$success,
    "fail when we modify the contents but not the size postcopy for md5"
);
unlink $to_file;

# Test md5 fails if we modify the destination file size, no retries
($success, @errors) = copy(
    $from_file,
    $to_file,
    'check'     => 'md5',
    'retries'   => 0,
    '_postcopy' => sub { write_random_file_contents($to_file, 1024*1024*2); }
);
ok(!$success, "fail when we modify the size postcopy for md5");
unlink $to_file;

# Test with size for success
($success, @errors) = copy_vigilant($from_file, $to_file, 'check' => 'size');
$success || print STDERR '#', join('#', @errors);
ok($success, "copy with size for success");
unlink $to_file;

# Test with size for failure, no retries
($success, @errors) = copy(
    $from_file,
    $to_file,
    'check'     => 'size',
    'retries'   => 0,
    '_postcopy' => sub { write_random_file_contents($to_file, 1024*1024*2); }
);
ok(!$success, "fail when we modify the size postcopy for size");
unlink $to_file;

# Test with compare for success
($success, @errors)
    = copy_vigilant($from_file, $to_file, 'check' => 'compare');
$success || print STDERR '#', join('#', @errors);
ok($success, "copy with compare for success");
unlink $to_file;

# Test with compare for failure
($success, @errors) = copy(
    $from_file,
    $to_file,
    'check'     => 'compare',
    'retries'   => 0,
    '_postcopy' => sub { write_random_file_contents($to_file, 1024*1024*2); }
);
ok(!$success, "fail when we modify the contents postcopy for compare");
unlink $to_file;

# Test with no check
($success, @errors) = copy_vigilant($from_file, $to_file, 'check' => 'none');
$success || print STDERR '#', join('#', @errors);
ok($success, "copy with no check");
unlink $to_file;

sub write_random_file_contents
{
    my $filename = shift;
    my $size = defined(shift) || 1024 * 1024 * 4; # Default size 10MB

    my $str = '';
    foreach (0..$size)
    {
        $str .= (0..9,'A'..'Z','a'..'z')[int rand 62];
    }

    my $OUT;
    open $OUT, '>', $filename || return 0;
    print $OUT $str;
    close $OUT || return 0;
    
    return 1;
}
