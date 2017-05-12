# NAME

HTML::CallJS - Pass server side data to JavaScript safety.

# SYNOPSIS

    use HTML::CallJS;

    call_js('foo', {x => 1});
    # => <script class="call_js" type="text/javascript">foo({"x":1})</script>

# DESCRIPTION

Pass server side data to JavaScript safety.

# HTML::CallJS with Text::Xslate

    use Text::Xslate;
    use HTML::CallJS;

    my $tx = Text::Xslate->new(
        html_builder_module => [
            'HTML::CallJS' => [qw(call_js)]
        ]
    );
    print $tx->render_string(
        '<: call_js("foo", {x=>$x}) :>', { x => 5963 },
    ), "\n";

    # => <script class="call_js" type="text/javascript">foo({"x":5963})</script>

You can use HTML::CallJS with [Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate).

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

This method is introduced by kazuhooku.
[http://d.hatena.ne.jp/kazuhooku/20131106/1383690938](http://d.hatena.ne.jp/kazuhooku/20131106/1383690938)

# AUTHOR

tokuhirom <tokuhirom@gmail.com>
