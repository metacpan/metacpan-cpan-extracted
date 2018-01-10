use strict;
use warnings;
use autodie;
use Test::More;

BEGIN { use_ok('Makefile::Update'); }

my $vars = read_files_list(*DATA);
is_deeply([sort keys %$vars], [qw(ALL VAR1 VAR2)], 'Expected variables have been read');
is_deeply($vars->{VAR1}, [qw(file1 file2)], 'VAR1 has expected value');
is_deeply($vars->{VAR2}, [qw(file3 file4)], 'VAR2 has expected value');
is_deeply($vars->{ALL}, [qw(file1 file2 file3 file4)], 'ALL combines both values');

done_testing()

__DATA__
# Some comments

VAR1 =
    file1
    # comment between the files
    file2
VAR2 =
    file3
    file4 # comment
    # another comment

ALL =
    $VAR1
    $VAR2
