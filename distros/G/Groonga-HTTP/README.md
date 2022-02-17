# NAME

Groonga::HTTP - Perl module for sending HTTP requests to Groonga.

# INSTALL

    % cpanm Groonga-HTTP

# SYNOPSIS

    use Groonga::HTTP;

    my $groonga = Groonga::HTTP->new;

    # Search for the "Site" table of Groonga.
    my @result = $groonga->select(
       table => 'Site'
    );
    print @result;

# DESCRIPTION

Groonga-HTTP is a Perl module for sending HTTP requests to Groonga.

Groonga-HTTP provides user-friendly Web API instead of low-level Groonga Web API.
The user-friendly Web API is implemented top of the low-level Groonga Web API.

# LICENSE

Copyright 2021-2022 Horimoto Yasuhiro.

GNU Lesser General Public License version 3 or later.
See [COPYING](https://github.com/groonga/Groonga-HTTP/blob/main/COPYING) and [COPYING.LESSER](https://github.com/groonga/Groonga-HTTP/blob/main/COPYING.LESSER) for details.

# AUTHOR

Horimoto Yasuhiro <horimoto@clear-code.com>
