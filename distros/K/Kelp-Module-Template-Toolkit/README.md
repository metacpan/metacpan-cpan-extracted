# NAME

Kelp::Module::Template::Toolkit - Template::Toolkit processing for Kelp applications

# SYNOPSIS

First ...

```perl
# conf/config.pl
{
    modules => ['Template::Toolkit'],
    modules_init => {
        'Template::Toolkit' => { ... }
    }
};
```

Then ...

```perl
# lib/MyApp.pm
sub some_route {
    my $self = shift;
    $self->template('some_template', { bar => 'foo' });
}
```

# DESCRIPTION

This module provides an interface for using [Template](http://search.cpan.org/perldoc?Template) inside a Kelp web application.

# REGISTERED METHODS

## template

`template($filename, \%vars)`

Renders a file using the currently loaded template engine.

# PERKS

## UTF8

[Template](http://search.cpan.org/perldoc?Template) is sometimes unable to detect the correct encoding, so to ensure
proper rendering, you may want to add `ENCODING` to its configuration:

```perl
# conf/config.pl
{
    modules      => ['Template::Toolkit'],
    modules_init => {
        'Template::Toolkit' => {
            ENCODING => 'utf8'
        }
    }
};
```
