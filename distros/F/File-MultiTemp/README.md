# NAME

File::MultiTemp - manage a hash of temporary files

# VERSION

version v0.1.3

# SYNOPSIS

```perl
my $files = File::MultiTemp->new(
  suffix   => '.csv',
  template => 'KEY-report-XXXX',
);

...

my @headers = ....

my $csv = Text::CSV_XS->new( { binary => 1 } );

my $fh = $files->file_handle( $key, sub {
    my ( $key, $path, $fh ) = @_;
    $csv->say( $fh, \@headings );
} );

$csv->say( $fh, $row );

...

$files->close;

my @reports = @{ $files->files };
```

# DESCRIPTION

This class maintains a hash reference of objects and opened filehandles.

This is useful for maintaining several separate files, for example, several reports based on codes where grouping the
data may require a lot of work for the database.

# ATTRIBUTES

## template

This is the filename template that is passed to [File::Temp](https://metacpan.org/pod/File%3A%3ATemp). It should have a string of at least four Xs in a row,
which will be filled in with a unique string.

If it has the text "KEY" then that will be replaced by the hash key. Note that this should only be used if the hash key
is suitable for a filename.

This is optional.

## has\_template

Returns true if ["template"](#template) is set.

## suffix

This is the filename suffix that is passed to [File::Temp](https://metacpan.org/pod/File%3A%3ATemp). This is optional.

## has\_suffix

Returns true if ["suffix"](#suffix) is set.

## dir

This is the base directory that is passed to [File::Temp](https://metacpan.org/pod/File%3A%3ATemp). This is optional.

## has\_dir

Returns true if ["dir"](#dir) is set.

## unlink

If this is true (default), then the files will be deleted after the object is destroyed.

## init

This is an optional function to initialise the file after it is created.

The function is calle with the three arguments:

- key

    The hash key.

- file

    The [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object that was created.

    You can use the `cached_temp` method to access the original [File::Temp](https://metacpan.org/pod/File%3A%3ATemp) object.

- fh

    The file handle, which is an exclusive write lock on the file.

## has\_init

Returns true if ["init"](#init) is set.

# METHODS

## file

```perl
my $path = $files->file( $key, \&init );
```

This returns a [Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny) object of the created file.

A file handle will be opened, that can be accessed using ["file\_handle"](#file_handle).

If a `&init` function is passed, then it will be called, otherwise the ["init"](#init) function will be called,
with the parameters documented in the ["init"](#init) function.

## file\_handle

```perl
my $fh = $files->file_handle( $key, \&init );
```

This is a file handle used for writing.

If the filehandle does not exist, then it will be re-opened in append mode.

## keys

This returns all files created.

## files

This returns all files created.

## close

This closes all files that are open.

This is called automatically when the object is destroyed.

# SEE ALSO

[File::Temp](https://metacpan.org/pod/File%3A%3ATemp)

[Path::Tiny](https://metacpan.org/pod/Path%3A%3ATiny)

# SOURCE

The development version is on github at [https://github.com/robrwo/perl5-File-MultiTemp](https://github.com/robrwo/perl5-File-MultiTemp)
and may be cloned from [git://github.com/robrwo/perl5-File-MultiTemp.git](git://github.com/robrwo/perl5-File-MultiTemp.git)

# BUGS

Please report any bugs or feature requests on the bugtracker website
[https://github.com/robrwo/perl5-File-MultiTemp/issues](https://github.com/robrwo/perl5-File-MultiTemp/issues)

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

# AUTHOR

Robert Rothenberg <rrwo@cpan.org>

The initial development of this module was sponsored by Science Photo
Library [https://www.sciencephoto.com](https://www.sciencephoto.com).

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2022-2023 by Robert Rothenberg.

This is free software, licensed under:

```
The Artistic License 2.0 (GPL Compatible)
```
