[![Build Status](https://travis-ci.org/s-aska/DocLife.png?branch=master)](https://travis-ci.org/s-aska/DocLife)
# NAME

DocLife - Document Viewer written in Perl, to run under Plack.

# SYNOPSIS

    # app.psgi
    use DocLife::Pod;
    DocLife::Pod->new( root => "./lib" );

    # one-liner
    plackup -MDocLife::Pod -e 'DocLife::Pod->new( root => "./lib" )->to_app'

# How To Mount

need base\_url option.

    # app.psgi
    use Plack::Builder;
    use DocLife::Pod;
    use DocLife::Markdown;

    my $pod_app = DocLife::Pod->new(
        root => '../lib',
        base_url => '/pod/'
    );

    my $doc_app = DocLife::Markdown->new(
        root => './doc',
        suffix => '.md',
        base_url => '/doc/'
    );

    builder {
        mount '/pod' => $pod_app;
        mount '/doc' => $doc_app;
    };

# CONFIGURATION

- root

    Document root directory. Defaults to the current directory.

- base\_url

    Specifies a base URL for all URLs on a index page. Defaults to the \`/\`.

- suffix

    Show only files that match the suffix. No url suffix.

# SEE ALSO

[Plack](http://search.cpan.org/perldoc?Plack)

# COPYRIGHT

Copyright 2013 Shinichiro Aska

# LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
