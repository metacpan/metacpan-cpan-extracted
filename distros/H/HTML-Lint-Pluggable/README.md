[![Build Status](https://travis-ci.org/karupanerura/p5-HTML-Lint-Pluggable.svg?branch=master)](https://travis-ci.org/karupanerura/p5-HTML-Lint-Pluggable)
# NAME

HTML::Lint::Pluggable - plugin system for HTML::Lint

# VERSION

This document describes HTML::Lint::Pluggable version 0.10.

# SYNOPSIS

    use HTML::Lint::Pluggable;

    my $lint = HTML::Lint::Pluggable->new;
    $lint->only_types( HTML::Lint::Error::STRUCTURE );
    $lint->load_plugins(qw/HTML5/);

    while ( my $line = <HTML> ) {
        $lint->parse( $line );
    }
    $lint->eof;
    # or $lint->parse_file( $filename );

    my $error_count = $lint->errors;

    foreach my $error ( $lint->errors ) {
        print $error->as_string, "\n";
    }

# DESCRIPTION

HTML::Lint::Pluggable adds plugin system for [HTML::Lint](https://metacpan.org/pod/HTML::Lint).

# WHY CREATED THIS MODULE?

[HTML::Lint](https://metacpan.org/pod/HTML::Lint) is useful. But, [HTML::Lint](https://metacpan.org/pod/HTML::Lint) can interpret \*only\* for rules of HTML4.
and, [HTML::Lint](https://metacpan.org/pod/HTML::Lint) gives an error of "Character char should be written as entity" for such as for multi-byte characters.
However, you are often no problem if they are properly encoded.

These problems can be solved easily to facilitate the various hooks for [HTML::Lint](https://metacpan.org/pod/HTML::Lint).

# INTERFACE

## Methods

### `$lint->load_plugin($module_name[, \%config])`

This method loads plugin for the instance.

$module\_name: package name of the plugin. You can write it as two form like DBIx::Class:

    $lint->load_plugin("HTML5"); # => loads HTML::Lint::Pluggable::HTML5

If you want to load a plugin in your own name space, use '+' character before package name like following:

    $lint->load_plugin("+MyApp::Plugin::XHTML"); # => loads MyApp::Plugin::XHTML

### `$lint->load_plugins($module_name[, \%config ], ...)`

Load multiple plugins at one time.

    $lint->load_plugins(
        qw/HTML5/,
        WhiteList => +{
            rule => +{
                'attr-unknown' => sub {
                    my $param = shift;
                    if ($param->{tag} =~ /input|textarea/ && $param->{attr} eq 'istyle') {
                        return 1;
                    }
                    else {
                        return 0;
                    }
                },
            }
        }
    ); # => loads HTML::Lint::Pluggable::HTML5, HTML::Lint::Pluggable::WhiteList

this code is same as:

    $lint->load_plugin('HTML5'); # => loads HTML::Lint::Pluggable::HTML5
    $lint->load_plugin(WhiteList => +{
        rule => +{
            'attr-unknown' => sub {
                my $param = shift;
                if ($param->{tag} =~ /input|textarea/ && $param->{attr} eq 'istyle') {
                    return 1;
                }
                else {
                    return 0;
                }
            },
        }
    }); # => loads HTML::Lint::Pluggable::WhiteList

# DEPENDENCIES

Perl 5.8.1 or later.

# BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

# SEE ALSO

[HTML::Lint](https://metacpan.org/pod/HTML::Lint)
[HTML::Tidy5](https://metacpan.org/pod/HTML::Tidy5)

# AUTHOR

Kenta Sato <karupa@cpan.org>

# LICENSE AND COPYRIGHT

Copyright (c) 2012, Kenta Sato. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
