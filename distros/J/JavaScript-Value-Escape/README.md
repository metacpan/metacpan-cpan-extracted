# NAME

JavaScript::Value::Escape - Avoid XSS with JavaScript value interpolation

# SYNOPSIS

    use JavaScript::Value::Escape;

    my $escaped = javascript_value_escape(q!&foo"bar'</script>!);
    # $escaped is "\u0026foo\u0022bar\u0027\u003c\/script\u003e"

    my $html_escaped = javascript_value_escape(Text::Xslate::Util::escape_html(q!&foo"bar'</script>!));

    print <<EOF;
    <script>
    var param = '$escaped';
    alert(param);

    document.write('$html_escaped');

    </script>
    EOF

# DESCRIPTION

There are a lot of XSS, a security hole typically found in web applications,
caused by incorrect (or lack of) JavaScript escaping. This module aims to
provide secure JavaScript escaping to avoid XSS with JavaScript values.

The escaping routine JavaScript::Value::Escape provides escapes for
q!"!, q!'!, q!&!, q!=!, q!-!, q!+!, q!;!, q!<!, q!>!, q!/!, q!\\! and
control characters to JavaScript unicode entities like "\\u0026".

# EXPORT FUNCTION

- javascript\_value\_escape($value :Str) :Str

    Escape a string. The argument of this function must be a text string
    (a.k.a. UTF-8 flagged string, Perl's internal form).

    This is exported by default.

- js($value :Str) :Str

    Alias to `javascript_value_escape()` for convenience.

    This is exported by your request.

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# THANKS TO

Fuji, Goro (gfx)

# SEE ALSO

[http://subtech.g.hatena.ne.jp/mala/20100222/1266843093](http://subtech.g.hatena.ne.jp/mala/20100222/1266843093) - About XSS caused by buggy JavaScript escaping for HTML script sections (Japanese)

[http://blog.nomadscafe.jp/2010/11/htmlscript.html](http://blog.nomadscafe.jp/2010/11/htmlscript.html) - Wrote a module (JavaScript::Value::Escape) to escape data for HTML script sections (Japanese)

[https://www.owasp.org/index.php/XSS\_%28Cross\_Site\_Scripting%29\_Prevention\_Cheat\_Sheet](https://www.owasp.org/index.php/XSS_%28Cross_Site_Scripting%29_Prevention_Cheat_Sheet) - Preventing XSS (Cross Site Scripting) (English)

[RFC4627](https://metacpan.org/pod/RFC4627) - The application/json Media Type for JSON

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
