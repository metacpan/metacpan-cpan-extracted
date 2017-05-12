use strict;
use Test::More tests => 44;
use Iterator::IO;

# Check that ifile and ifile_reverse work as promised.

sub begins_with
{
    my ($actual, $expected, $test_name) = @_;

    $actual = substr($actual, 0, length $expected);
    @_ =  ($actual, $expected, $test_name);
    goto &is;
}

my ($file, @vals);

# ifile bad chomp value (4)
eval
{
    $file = ifile 't/test_data.txt', 'barf';
};

isnt ($@, q{}, q{Bad option to ifile threw exception});
ok (Iterator::X->caught(), q{Bad-option exception is correct base class});
ok (Iterator::X::Parameter_Error->caught(),
    q{Bad-option exception is correct specific class});
begins_with ($@, q{Second argument to ifile must be a hashref},
             q{Bad-option exception formatted properly});

# ifile old-style chomp parameter -- DEPRECATED.
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', 'chomp';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile Iterator old-style chomp created and executed.});
is_deeply (\@vals, ['First line', 'Second line', 'Third line', 'Fourth line'],
           q{ifile old-style chomp returned proper values.});

# ifile normal operation (2)
@vals = ();
eval
{
    $file = ifile 't/test_data.txt';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile Iterator created and executed.});
is_deeply (\@vals, ['First line', 'Second line', 'Third line', 'Fourth line'],
           q{ifile returned proper values.});

# ifile without chomping (2)
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', {chomp => 0};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile Iterator created and executed.});
is_deeply (\@vals, ["First line\n", "Second line\n", "Third line\n", "Fourth line\n"],
           q{ifile returned proper values.});

# ifile without chomping, the old way (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', 'nochomp';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile old-style nochomp Iterator created and executed.});
is_deeply (\@vals, ["First line\n", "Second line\n", "Third line\n", "Fourth line\n"],
           q{ifile old-style nochomp returned proper values.});

# ifile separator (2)
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', {chomp => 1, '$/' => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile Iterator created and executed.});
is_deeply (\@vals, ["First", "Second", "Third", "Fourth"],
           q{ifile returned proper values.});

# ifile separator 2 (2)
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', {chomp => 1, rs => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile 'rs' Iterator created and executed.});
is_deeply (\@vals, ["First", "Second", "Third", "Fourth"],
           q{ifile 'rs' returned proper values.});

# ifile separator 3 (2)
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', {chomp => 1, input_record_separator => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile 'input_record_separator' Iterator created and executed.});
is_deeply (\@vals, ["First", "Second", "Third", "Fourth"],
           q{ifile 'input_record_separator' returned proper values.});

# ifile separator, old-style (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', 'chomp', " line\n";
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile old-style line-end Iterator created and executed.});
is_deeply (\@vals, ["First", "Second", "Third", "Fourth"],
           q{ifile old-style line-end returned proper values.});

# ifile separator, old-style (2)  -- DEPRECATED
@vals = ();
eval
{
    $file = ifile 't/test_data.txt', 'nochomp', " line\n";
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile old-style line-end 2 Iterator created and executed.});
is_deeply (\@vals, ["First line\n", "Second line\n", "Third line\n", "Fourth line\n"],
           q{ifile old-style line-end 2 returned proper values.});


################################################################

# ifile_reverse bad chomp value (4)
eval
{
    $file = ifile_reverse 't/test_data.txt', 'barf';
};

isnt ($@, q{}, q{Bad option to ifile_reverse threw exception});
ok (Iterator::X->caught(), q{Bad-option exception is correct base class});
ok (Iterator::X::Parameter_Error->caught(),
    q{Bad-option exception is correct specific class});
begins_with ($@, q{Second argument to ifile_reverse must be a hashref},
             q{Bad-option exception formatted properly});


# ifile_reverse normal operation (2)
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse Iterator created and executed.});
is_deeply (\@vals, ['Fourth line', 'Third line', 'Second line', 'First line'],
           q{ifile_reverse returned proper values.});

# ifile_reverse normal operation, old-style chomp (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', 'chomp';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse old-style chomp Iterator created and executed.});
is_deeply (\@vals, ['Fourth line', 'Third line', 'Second line', 'First line'],
           q{ifile_reverse old-style chomp returned proper values.});

# ifile_reverse without chomping (2)
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', {chomp => 0};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse Iterator created and executed.});
is_deeply (\@vals, ["Fourth line\n", "Third line\n", "Second line\n", "First line\n"],
           q{ifile_reverse returned proper values.});

# ifile_reverse without chomping, old-style (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', 'nochomp';
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse old-style nochomp Iterator created and executed.});
is_deeply (\@vals, ["Fourth line\n", "Third line\n", "Second line\n", "First line\n"],
           q{ifile_reverse old-style nochomp returned proper values.});

# ifile_reverse line separator (2)
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', {chomp => 1, '$/' => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse Iterator created and executed.});
is_deeply (\@vals, ["Fourth", "Third", "Second", "First"],
           q{ifile_reverse returned proper values.});

# ifile_reverse line separator 2 (2)
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', {chomp => 1, rs => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse 'rs' Iterator created and executed.});
is_deeply (\@vals, ["Fourth", "Third", "Second", "First"],
           q{ifile_reverse 'rs' returned proper values.});

# ifile_reverse line separator 3 (2)
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', {chomp => 1, input_record_separator => " line\n"};
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse input_record_separator Iterator created and executed.});
is_deeply (\@vals, ["Fourth", "Third", "Second", "First"],
           q{ifile_reverse input_record_separator returned proper values.});

# ifile_reverse line separator, old-style (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', 'chomp', " line\n";
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse old-style line-ending Iterator created and executed.});
is_deeply (\@vals, ["Fourth", "Third", "Second", "First"],
           q{ifile_reverse old-style line-ending returned proper values.});

# ifile_reverse line separator, old-style (2) -- DEPRECATED
@vals = ();
eval
{
    $file = ifile_reverse 't/test_data.txt', 'nochomp', " line\n";
    push @vals, $file->value()  while $file->isnt_exhausted();
};

is ($@, q{}, q{ifile_reverse old-style line-ending 2 Iterator created and executed.});
is_deeply (\@vals, ["Fourth line\n", "Third line\n", "Second line\n", "First line\n"],
           q{ifile_reverse old-style line-ending 2 returned proper values.});

