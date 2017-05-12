# NAME

EnvDir - Modify environment variables according to files in a specified directory

# SYNOPSIS

    # Load environment variables from ./env
    use EnvDir -autoload;

    # You can specify a directory.
    use EnvDir -autoload => '/path/to/dir';

    # envdir function returns a guard object.
    use EnvDir 'envdir';

    $ENV{PATH} = '/bin';
    {
        my $guard = envdir('/path/to/dir');
    }
    # PATH is /bin from here

    # you can nest envdir by OOP syntax.
    use EnvDir;

    my $envdir = EnvDir->new;
    {
        my $guard = $envdir->envdir('/env1');
        ...

        {
            my $guard = $envdir->envdir('/env2');
            ...
        }
    }

    # If you set the clean option,
    # removes all current %ENV and set PATH=/bin:/usr/bin.
    # This behavior is the same as envdir(8).
    use EnvDir -autoload, -clean;

    # in function style
    use EnvDir 'envdir', -clean;

    # OO style
    use EnvDir;
    my $envdir = EnvDir->new( clean => 1 );

# DESCRIPTION

EnvDir is a module like envdir(8). But this module does not reset all
environments by default, updates only the value that file exists. If you want to reset all environment variables, you can use the `-clean` option.

# SCRIPT

This distribution contains envdir.pl. See [envdir.pl](http://search.cpan.org/perldoc?envdir.pl) for more details.

# COPYRIGHT AND LICENSE

Copyright (C) 2013 Yoshihiro Sasaki <ysasaki at cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yoshihiro Sasaki <ysasaki at cpan.org>
