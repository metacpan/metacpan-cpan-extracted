package HTML::CallJS;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.02";

use parent qw(Exporter);

use JSON::XS;

our @EXPORT = qw(call_js);

my $JSON = JSON::XS->new()->ascii(1)->allow_nonref();

my %_ESCAPE = (
    '+' => '\\u002b',    # do not eval as UTF-7
    '&' => '\\u0026',
    '<' => '\\u003c',    # do not eval as HTML
    '>' => '\\u003e',    # ditto.
);

sub call_js {
    my ($func, $data) = @_;

    my $json = $JSON->encode($data);
    $json =~ s!([&+<>])!$_ESCAPE{$1}!g;

    join('',
        q{<script class="call_js" type="text/javascript">},
        $func,
        '(',
        $json,
        ')',
        q{</script>}
    );
}


1;
__END__

=encoding utf-8

=head1 NAME

HTML::CallJS - Pass server side data to JavaScript safety.

=head1 SYNOPSIS

    use HTML::CallJS;

    call_js('foo', {x => 1});
    # => <script class="call_js" type="text/javascript">foo({"x":1})</script>

=head1 DESCRIPTION

Pass server side data to JavaScript safety.

=head1 HTML::CallJS with Text::Xslate

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

You can use HTML::CallJS with L<Text::Xslate>.

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

This method is introduced by kazuhooku.
L<http://d.hatena.ne.jp/kazuhooku/20131106/1383690938>

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

