# NAME

HTML::Filter::Callbacks - modify HTML with callbacks

# SYNOPSIS

    use HTML::Filter::Callbacks;

    # Case 1: remove script tags
    my $filter = HTML::Filter::Callbacks->new;
    $filter->add_callbacks(
      script => {
        start => sub { shift->remove_text_and_tag },
        end   => sub { shift->remove_text_and_tag },
      },
    );
    my $new_html = $filter->process($html);

    # Case 2: remove on_* attributes
    my $filter = HTML::Filter::Callbacks->new;
    $filter->add_callbacks(
      '*' => {
        start => sub { shift->remove_attr(qr/^on_/) },
      },
    );
    my $new_html = $filter->process($html);

    # Case 3: replace url of <img src="...">
    my $filter = HTML::Filter::Callbacks->new;
    $filter->add_callbacks(
      'img' => {
        start => sub {
          shift->replace_attr(src => sub { URI->new(shift)->canonical })
        },
      },
    );
    my $new_html = $filter->process($html);

    # Case 4: more complex example to enforce a submit button
    my $filter = HTML::Filter::Callbacks->new;
    $filter->add_callbacks(
      'form' => {
        start => sub {
          my ($tag, $c) = @_;
          $c->stash->{__form_has_submit} = 0;
        },
        end => sub {
          my ($tag, $c) = @_;
          $tag->prepend(qq/<input type="submit">\n/)
            unless $c->stash->{__form_has_submit};
          delete $c->stash->{__form_has_submit};
        }
      },
      'input' => {
        start => sub {
          my ($tag, $c) = @_;
          $c->stash->{__form_has_submit} = 1
            if $tag->attr('type') eq 'submit';
        }
      },
    );
    my $new_html = $filter->process($html);

# DESCRIPTION

This is a rather simple HTML filter, based on [HTML::Parser](http://search.cpan.org/perldoc?HTML::Parser). It only looks for tags you add callbacks to modify something that is related to the tags (i.e. tag attributes and related comments and texts that it looked and skipped). If you want finer control, you can add extra handlers to the filter. See the SYNOPSIS and tests for usage.

# METHODS

## new

creates an object.

## process

takes an (X)HTML, applies all the callbacks, and returns the result.

## add\_callbacks

takes an array of callbacks, which typically have a tag name, and a hash reference which holds a callback for the open tag of the name (`start =` {...}>), and a callback for the close tag of the name (`end =` {...}>). The callbacks will take a HTML::Filter::Callbacks::Tag object, and the filter object itself as a context holder (stash).

## stash

is just a hash reference which you can use freely in the callbacks.

## init

used internally to register default callbacks.

# SEE ALSO

[HTML::Parser](http://search.cpan.org/perldoc?HTML::Parser)

# AUTHOR

Kenichi Ishigaki, <ishigaki@cpan.org>

Yuji Shimada <xaicron@cpan.org>

# COPYRIGHT AND LICENSE

Copyright (C) 2009 by Kenichi Ishigaki.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
