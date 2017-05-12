use strict;
use Test::More tests => 4;
use Cwd;
use Iterator::IO;

# Check that idir_listing and idir_walk work as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

# Get list of files in current directory, the old-fashioned way.

my $cwd = cwd();
opendir (my $curdir_h, $cwd)
    or die "Cannot read current directory '$cwd'";

my @files = map "$cwd/$_", grep {$_ ne '.' && $_ ne '..'} readdir ($curdir_h);
closedir ($curdir_h);

my %files_found;
foreach my $file (@files)
{
    $files_found{$file}++;
    diag "I'm confused about '$file'" if $files_found{$file} > 1;
}


# idir_listing (2)
my $iter;
eval
{
    $iter = idir_listing ($cwd);
};
is ($@, q{}, q{No exception when creating idir_listing iterator});

# Subtract results from known-good list
while ($iter->isnt_exhausted)
{
    my $file = $iter->value;
    $files_found{$file}--;
}

my @bad;
while (my ($file, $count) = each %files_found)
{
    next if $count == 0;
    push @bad, "$file: $count\n";
}
ok (@bad == 0, q{idir_listing: no surprises.});

diag "Surprise file: $_" for @bad;


# start over again for idir_walk
$cwd = cwd();
my @walk_files;
my @queue = ($cwd);
while (@queue)
{
    my $dir = shift (@queue);

    opendir (my $curdir_h, $dir)
        or die "Cannot read directory '$dir'";

    foreach my $file (readdir $curdir_h)
    {
        next if $file eq '.' || $file eq '..';
        my $full_name = "$dir/$file";

        push @walk_files, $full_name;
        push @queue, $full_name if -d $full_name && !-l $full_name;
    }

    closedir ($curdir_h);
}

%files_found = ();
foreach my $file (@walk_files)
{
    $files_found{$file}++;
    diag "I'm confused about '$file'" if $files_found{$file} > 1;
}

eval
{
    $iter = idir_walk ($cwd);
};
is ($@, q{}, q{No exception when creating idir_walk iterator});

# Subtract results from known-good list
while ($iter->isnt_exhausted)
{
    my $file = $iter->value;
    $files_found{$file}--;
}


@bad = ();
while (my ($file, $count) = each %files_found)
{
    next if $count == 0;
    push @bad, "$file: $count\n";
}
ok (@bad == 0, q{idir_walk: no surprises.});

diag "Surprise file: $_" for @bad;
