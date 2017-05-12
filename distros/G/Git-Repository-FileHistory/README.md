# NAME

Git::Repository::FileHistory - Class representing file on git repository

# SYNOPSIS

    # load the File plugin
    use Git::Repository 'FileHistory';
    
    my $repo = Git::Repository->new;
    my $file = $repo->file_history('somefile');
    
    print $file->created_at;
    print $file->created_by;
    print $file->last_modified_at;
    print $file->last_modified_by;

# DESCRIPTION

Git::Repository::FileHistory is class representing file on git repository.

# CONSTRUCTOR

## new( $file\_name )

Create a new `Git::Repository::FileHistory` instance, using the file name
on git repository as parameter.

## ACCESORS

The following accessors methods are recognized.

- created\_at

    Return epoch.

- last\_modified\_at

    Return epoch.

- created\_by

    Return author name.

- last\_modified\_by

    Return author name.

- logs

    Return array of Git::Repository::Log objects

# AUTHOR

Masayuki Matsuki <y.songmu@gmail.com>

BooK gives me many advice. Thanks a lot.

# SEE ALSO

[Git::Repository](https://metacpan.org/pod/Git::Repository)
[Git::Repository::Log](https://metacpan.org/pod/Git::Repository::Log)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
