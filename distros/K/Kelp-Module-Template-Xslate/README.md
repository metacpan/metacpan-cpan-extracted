# NAME

Kelp::Module::Template::Xslate - Template rendering via Text::Xslate for Kelp

# SYNOPSIS

First ...

```perl
# conf/config.pl
{
    modules => ['Template::Xslate'],
    modules_init => {
        'Template::Xslate' => {
            ...
        }
    }
}
```

Then ...

```perl
# lib/MyApp.pm
sub some_route {
    my $self = shift;
    return $self->template( \'Inline <: $name :>', { name => 'template' } );
}

sub another_route {
    my $self = shift;
    return $self->template( 'filename', { bar => 'foo' } );
}
```

# SEE ALSO

[Kelp](http://search.cpan.org/perldoc?Kelp), [Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate)
