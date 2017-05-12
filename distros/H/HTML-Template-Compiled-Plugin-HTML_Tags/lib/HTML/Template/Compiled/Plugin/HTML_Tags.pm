package HTML::Template::Compiled::Plugin::HTML_Tags;
# $Id: HTML_Tags.pm,v 1.17 2007/10/27 11:33:29 tinita Exp $
use strict;
use warnings;
use Carp qw(croak carp);
use HTML::Template::Compiled::Expression qw(:expressions);
use HTML::Template::Compiled;
HTML::Template::Compiled->register('HTML::Template::Compiled::Plugin::HTML_Tags');
our $VERSION = '0.05';

sub register {
    my ($class) = @_;
    my %plugs = (
        tagnames => {
            HTML::Template::Compiled::Token::OPENING_TAG() => {
                HTML_OPTION => [sub { exists $_[1]->{NAME} }, qw(NAME)],
                HTML_SELECT => [sub { exists $_[1]->{NAME} }, qw(NAME SELECT_ATTR)],
                HTML_TABLE  => [
                    sub { exists $_[1]->{NAME} },
                    qw(NAME TH_ATTR TD_ATTR TR_ATTR TABLE_ATTR HEADER)
                ],
                HTML_OPTION_LOOP => [sub { exists $_[1]->{NAME} }, qw(NAME)],
                HTML_BOX_LOOP    => [sub { exists $_[1]->{NAME} }, qw(NAME)],
            },
            HTML::Template::Compiled::Token::CLOSING_TAG() => {
                HTML_OPTION_LOOP => [undef, qw(NAME)],
                HTML_BOX_LOOP    => [undef, qw(NAME)],
            },
        },
        compile => {
            HTML_SELECT => {
                open => \&_html_select,
            },
            HTML_OPTION => {
                open => \&_html_option,
            },
            HTML_TABLE => {
                open => \&_html_table,
            },
            HTML_OPTION_LOOP => {
                open => \&_html_option_loop,
                close => \&_html_option_loop_close,
            },
            HTML_BOX_LOOP => {
                open => \&_html_box_loop,
                close => \&_html_option_loop_close, # sic!
            },
        },
    );
    return \%plugs;
}

sub _html_option_loop_close {
    return <<'EOM';
    }
 }
EOM
}

sub _option_loop {
    my ($select_string, $var) = @_;
    my @var = @{ $var };
    my $selected = shift @var;
    my %selected = defined $selected
        ? ref $selected eq 'ARRAY'
        ? (map { $_ => 1 } @$selected)
        : ($selected => 1)
        : ();
    my @options;
    for (@var) {
        push @options,  {
            value => $_->[0],
            label => $_->[1],
            selected => $selected{$_->[0]} ? qq#$select_string="$select_string"# : '',
        };
    }
    return \@options;
}

sub _html_box_loop {
    my ($htc, $token, $args) = @_;
    my $attr = $token->get_attributes;
    my $varstr = $htc->get_compiler->parse_var($htc,
        var => $attr->{NAME},
        method_call => $htc->method_call,
        deref => $htc->deref,
        formatter_path => $htc->formatter_path,
    );
    my $expression = <<"EOM";
\{
    my \$items = HTML::Template::Compiled::Plugin::HTML_Tags::_option_loop(
        "checked",
        $varstr,
    );
for my \$_html_option_loop_entry (\@\$items) {
    my \$C = \\\$_html_option_loop_entry;
EOM
}

sub _html_option_loop {
    my ($htc, $token, $args) = @_;
    my $attr = $token->get_attributes;
    my $varstr = $htc->get_compiler->parse_var($htc,
        var => $attr->{NAME},
        method_call => $htc->method_call,
        deref => $htc->deref,
        formatter_path => $htc->formatter_path,
    );
    my $expression = <<"EOM";
\{
    my \$items = HTML::Template::Compiled::Plugin::HTML_Tags::_option_loop(
        "selected",
        $varstr,
    );
for my \$_html_option_loop_entry (\@\$items) {
    my \$C = \\\$_html_option_loop_entry;
EOM
}

sub _html_table {
    my ($htc, $token, $args) = @_;
    my $OUT = $args->{out};
    my $attr = $token->get_attributes;
    my $varstr = $htc->get_compiler->parse_var($htc,
        var => $attr->{NAME},
        method_call => $htc->method_call,
        deref => $htc->deref,
        formatter_path => $htc->formatter_path,
    );
    my $header = $attr->{HEADER} || 0;
    my $tr_attr = $attr->{TR_ATTR} || '';
    my $td_attr = $attr->{TD_ATTR} || '';
    my $th_attr = $attr->{TH_ATTR} || '';
    my $table_attr = $attr->{TABLE_ATTR} || '';
    for ($tr_attr, $td_attr, $th_attr, $table_attr) {
        s/'/\\'/g;
    }
    my $expression = qq#my \@aoa = \@{ +$varstr };\n#;
    $expression .= <<"EOM";
    $OUT '<table $table_attr>'."\\n";
if ($header) \{
    my \$header = shift \@aoa;
    $OUT join "", '<tr $tr_attr>', (map {
        qq#<th #.'$th_attr'.qq#>\$_</th>#
    } \@\$header), '</tr>', "\\n";
\}
for (\@aoa) \{
    $OUT join "\\n", '<tr $tr_attr>', (map {
        qq#<td #.'$td_attr'.qq#>\$_</th>#
    } \@\$_), '</tr>', "\\n";
\}
$OUT '</table>'. "\\n";
EOM
    return $expression;
}

sub _html_select {
    my ($htc, $token, $args) = @_;
    my $OUT = $args->{out};
    my $attr = $token->get_attributes;
    my $varstr = $htc->get_compiler->parse_var($htc,
        var => $attr->{NAME},
        method_call => $htc->method_call,
        deref => $htc->deref,
        formatter_path => $htc->formatter_path,
    );
    my $select_attr = $attr->{SELECT_ATTR} || '';
    $select_attr =~ s/'/\\'/g;
    my $expression = qq#\{\nmy \$var = $varstr;\n#;
    $expression .= qq#my \$attr = '$select_attr';\n#;
    $expression .= <<'EOM';
    my $name = $var->{name};
    my $value = $var->{value};
    my @options = @{ $var->{options} };
    my $select = qq#<select name="$name" $attr>\n#;
    $select .= HTML::Template::Compiled::Plugin::HTML_Tags::_options($value, @options);
    $select .= qq#\n</select>\n#;
EOM
    $expression .= qq#$OUT \$select;\n\}#;
    return $expression;
}

sub _html_option {
    my ($htc, $token, $args) = @_;
    my $OUT = $args->{out};
    my $attr = $token->get_attributes;
    my $varstr = $htc->get_compiler->parse_var($htc,
        var => $attr->{NAME},
        method_call => $htc->method_call,
        deref => $htc->deref,
        formatter_path => $htc->formatter_path,
    );
    my $expression = qq!
my \$aref = $varstr;
my \@aoa = \@\$aref;
!;
    $expression .= <<'EOM';
my $options = HTML::Template::Compiled::Plugin::HTML_Tags::_options(@aoa);
EOM
    $expression .= qq#$OUT \$options;\n#;
    return $expression;
}

sub _options {
    my @aoa = @_;
    my $selected = shift @aoa;
    my %selected = defined $selected
    ? ref $selected eq 'ARRAY'
    ? (map { $_ => 1 } @$selected)
    : ($selected => 1)
    : ();
    my $options = join "\n", map {
        unless (ref $_ eq 'ARRAY') {
            # values and labels should be equal
            $_ = [$_, $_];
        }
        my $escaped = HTML::Template::Compiled::Utils::escape_html($_->[0]);
        my $sel = $selected{ $_->[0] } ? 'selected="selected"' : '';
        my $escaped_display = @$_ > 1
            ? HTML::Template::Compiled::Utils::escape_html($_->[1])
            : $escaped;
        qq#<option value="$escaped" $sel>$escaped_display</option>#;
    } @aoa;
}



1;

__END__

=pod

=head1 NAME

HTML::Template::Compiled::Plugin::HTML_Tags - HTC-Plugin for various HTML tags

=head1 SYNOPSIS

    use HTML::Template::Compiled::Plugin::HTML_Tags;

    my $htc = HTML::Template::Compiled->new(
        plugin => [qw(HTML::Template::Compiled::Plugin::HTML_Tags)],
        ...
    );

=head1 DESCRIPTION

This plugin offers you five tags:

=over 4

=item HTML_OPTION

    <tmpl_html_option arrayref>

    $htc->param(
        arrayref => [ 'opt_2', # selected
            ['opt_1', 'option 1'],
            ['opt_2', 'option 2'],
        ],
    );

    Output:
    <option value="opt_1">option 1</option>
    <option value="opt_2" selected="selected">option 2</option>

You can also select multiple options:

    $htc->param(
        arrayref => [ ['opt_1','opt_2'], # selected
            ['opt_1', 'option 1'],
            ['opt_2', 'option 2'],
        ],
    );

If you have values and labels equal (for example in a year-select),
you can use this syntax:

    $htc->param(
        arrayref => [ 2007, # selected
            '2005',
            '2006',
            '2007',
        ],
    );

    Output:
    <option value="2005">2005</option>
    <option value="2006">2006</option>
    <option value="2007" selected="selected">2007</option>

=item HTML_SELECT

    <tmpl_html_select select SELECT_ATTR="class='myselect'">

    $htc->param(
        select => {
            name => 'foo',
            value => 'opt_1',
            options => [
                ['opt_1', 'option 1'], # or use simple scalars if values and labals are equal
                ['opt_2', 'option 2'],
            ],
        },
    );

    Output:
    <select name='foo' class='myselect'>
    <option value="opt_1" selected="selected">option 1</option>
    <option value="opt_2">option 2</option>
    </select>

=item HTML_OPTION_LOOP

I'm using tt-style syntax here (see option C<tagstyle> in
L<HTML::Template::Compiled>) for readability:

    <select name="foo">
    [%html_option_loop arrayref%]
    <option value="[%= value%]" [%= selected%] >[%= label %]</option>
    [%/html_option_loop%]
    </select>

    $htc->param(
        arrayref => [ 'opt_2',
            ['opt_1', 'option 1'], # or use simple scalars if values and labals are equal
            ['opt_2', 'option 2'],
        ],
    );

    Output:
    <select name="foo">
    <option value="opt_1" >option 1</option>
    <option value="opt_2" selected="selected">option 2</option>
    </select>

=item HTML_BOX_LOOP

I'm using tt-style syntax here for readability:

    [%html_box_loop arrayref%]
    <checkbox name="foo" value="[%= value%]" [%= selected%] >[%= label %]
    [%/html_box_loop%]

    $htc->param(
        arrayref => [ 'opt_2',
            ['opt_1', 'option 1'], # or use simple scalars if values and labals are equal
            ['opt_2', 'option 2'],
        ],
    );

    Output:
    <checkbox name="foo" value="opt_1" >option 1
    <checkbox name="foo" value="opt_2" checked="checked">option 2

This can also be used with radio boxes. Code is the same.

=item HTML_TABLE

    Easy example:
    <tmpl_html_table arrayref>

    Example with all possible attributes:
    <tmpl_html_table arrayref
    header=1
    table_attr="bgcolor='black'"
    tr_attr="bgcolor='red'"
    th_attr="bgcolor='green'"
    td_attr="bgcolor='green'" >

    $htc->param(
        arrayref => [
            [qw(foo bar)], # table header
            [qw(foo bar)],
            [qw(foo bar)],
        ],
    );

    Output:
    <table bgcolor='black'>
    <tr bgcolor='red'>
    <th bgcolor='green'>foo</th><th bgcolor='green'>bar</th>
    </tr>
    <tr bgcolor='red'>
    <td bgcolor='green'>foo</td><td bgcolor='green'>bar</td>
    </tr>
    ...
    </table>

=back

=head1 EXAMPLES

See the examples directory in this distribution.

=head1 METHODS

=over 4

=item register

gets called by HTC

=back

=head1 AUTHOR

Tina Mueller

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Tina Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.


=cut

