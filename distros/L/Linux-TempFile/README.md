# NAME

Linux::TempFile - Creates a temporary file using O\_TMPFILE

# SYNOPSIS

    use Linux::TempFile;
    my $file = Linux::TempFile->new;
    # do something with $file (eg: print, chmod)
    $file->link('/path/to/file');

# DESCRIPTION

Linux::TempFile is a module to create a temporary file using O\_TMPFILE.

This module is only available on GNU/Linux 3.11 or higher.

# METHODS

- Linux::TempFile->new(\[$dir\])

    Creates a temporary file using O\_TMPFILE.

    Returns an instance of this class (inherits [IO::Handle](https://metacpan.org/pod/IO::Handle)).

- $self->link($path)

    Creates a new filename linked to the temporary file by calling linkat(2).

# SEE ALSO

[File::Temp](https://metacpan.org/pod/File::Temp), [IO::Handle](https://metacpan.org/pod/IO::Handle), **open(2)**, **linkat(2)**

# LICENSE

Copyright (C) Jiro Nishiguchi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jiro Nishiguchi &lt;jiro@cpan.org>
