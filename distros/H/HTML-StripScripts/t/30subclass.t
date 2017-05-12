
use strict;
use Test::More tests => 27;

BEGIN { $^W = 1 }

use HTML::StripScripts;

=head1 name

F<t/30subclass.t> - HTML::StripScripts subclassing test script

=head1 DESCRIPTION

This file is part of the reggression test suite of L<HTML::StripScripts>,
testing that subclassing works as documented.  This file also serves as
a set of examples of subclassing L<HTML::StripScripts>.

=head1 TESTS

=over

=item output_start_document

Overriding output_start_document() to prepend an HTML comment.

=cut

{
    package SubClass_output_start_document;
    use base qw(HTML::StripScripts);

    sub output_start_document {
        my ($self) = @_;

    $self->output_comment('<!--foo-->');
    }
}
my $f = SubClass_output_start_document->new;
$f->input_start_document;
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<!--foo-->foo', 'subclass output_start_document' );

=item output_end_document

Overriding output_end_document() to apend an HTML comment.

=cut

{
    package SubClass_output_end_document;
    use base qw(HTML::StripScripts);

    sub output_end_document {
        my ($self) = @_;

    $self->output_comment('<!--foo-->');
    }
}
$f = SubClass_output_end_document->new;
$f->input_start_document;
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, 'foo<!--foo-->', 'subclass output_end_document' );

=item output_start

Overriding output_start() to convert start tags to upper case

=cut

{
    package SubClass_output_start;
    use base qw(HTML::StripScripts);

    sub output_start {
        my ($self, $text) = @_;

    $self->output(uc $text);
    }
}
$f = SubClass_output_start->new;
$f->input_start_document;
$f->input_start('<font color=Red>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<FONT COLOR="RED">foo</font>', 'subclass output_start' );

=item output_text

Overriding output_text() to convert text to upper case

=cut

{
    package SubClass_output_text;
    use base qw(HTML::StripScripts);

    sub output_text {
        my ($self, $text) = @_;

    $self->output(uc $text);
    }
}
$f = SubClass_output_text->new;
$f->input_start_document;
$f->input_start('<font color=Red>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="Red">FOO</font>', 'subclass output_text' );

=item output_end

Overriding output_end() to convert end tags to upper case

=cut

{
    package SubClass_output_end;
    use base qw(HTML::StripScripts);

    sub output_end {
        my ($self, $text) = @_;

    $self->output(uc $text);
    }
}
$f = SubClass_output_end->new;
$f->input_start_document;
$f->input_start('<font color=Red>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="Red">foo</FONT>', 'subclass output_end' );

=item output

Overriding output() to convert all output to upper case

=cut

{
    package SubClass_output;
    use base qw(HTML::StripScripts);

    sub output {
        my ($self, $text) = @_;

    $self->SUPER::output(uc $text);
    }
}
$f = SubClass_output->new;
$f->input_start_document;
$f->input_start('<font color=Red>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<FONT COLOR="RED">FOO</FONT>', 'subclass output' );

=item reject_start

Overriding reject_start() so that rejected start tags are escaped rather than
replaced with HTML comments.

=cut

{
    package SubClass_reject_start;
    use base qw(HTML::StripScripts);

    sub reject_start {
        my ($self, $text) = @_;

    $self->output_text( $self->escape_html_metachars($text) );
    }
}
$f = SubClass_reject_start->new;
$f->input_start_document;
$f->input_start('<foo type=bar>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '&lt;foo type=bar&gt;foo', 'subclass reject start' );

=item reject_end

Overriding reject_end() so that rejected end tags are escaped rather than
replaced with HTML comments.

=cut

{
    package SubClass_reject_end;
    use base qw(HTML::StripScripts);

    sub reject_end {
        my ($self, $text) = @_;

    $self->output_text( $self->escape_html_metachars($text) );
    }
}
$f = SubClass_reject_end->new;
$f->input_start_document;
$f->input_text('foo');
$f->input_end('</i>');
$f->input_end_document;
is( $f->filtered_document, 'foo&lt;/i&gt;', 'subclass reject end' );

=item reject_text

Overriding reject_text() so that rejected non-tag text is replaced with
a different HTML comment than the default.

=cut

{
    package SubClass_reject_text;
    use base qw(HTML::StripScripts);

    sub reject_text {
        my ($self, $text) = @_;

    $self->output_comment('<!--foo-->');
    }
}
$f = SubClass_reject_text->new({ Context => 'Document' });
$f->input_start_document;
$f->input_start('<html>');
$f->input_start('<head>');
$f->input_text('bah');
$f->input_end('</head>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<html><head><!--foo--></head><body>foo</body></html>',
                           'subclass reject_text' );

=item reject_decalaration

Overriding reject_decalaration() so that rejected declarations are replaced
with custom text.

=cut

{
    package SubClass_reject_declaration;
    use base qw(HTML::StripScripts);

    sub reject_declaration {
        my ($self, $text) = @_;

    $self->output_declaration('<! FOO >');
    }
}
$f = SubClass_reject_declaration->new;
$f->input_start_document;
$f->input_declaration('<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<! FOO >foo', 'subclass reject_decalaration' );

=item reject_comment

Overriding reject_comment() so that rejected HTML comments are replaced
with custom text.

=cut

{
    package SubClass_reject_comment;
    use base qw(HTML::StripScripts);

    sub reject_comment {
        my ($self, $text) = @_;

    $self->output_comment('<!--foo-->');
    }
}
$f = SubClass_reject_comment->new;
$f->input_start_document;
$f->input_text('foo');
$f->input_comment('<!--# exec foo -->');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, 'foo<!--foo-->foo', 'subclass reject_comment' );

=item reject_process

Overriding reject_process() so that rejected processing instructions are
replaced with custom text.

=cut

{
    package SubClass_reject_process;
    use base qw(HTML::StripScripts);

    sub reject_process {
        my ($self, $text) = @_;

    $self->output_process('<? FOO ?>');
    }
}
$f = SubClass_reject_process->new;
$f->input_start_document;
$f->input_process('<?xml version="1.0" encoding="iso-8859-1"?>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<? FOO ?>foo', 'subclass reject_process' );

=item init_context_whitelist

Overriding init_context_whitelist() so that the filter will allow C<ins>
tags only at C<Flow> level.


=cut

{
    package SubClass_init_context_whitelist;
    use base qw(HTML::StripScripts);

    use vars qw(%_Context);
    %_Context = %{ __PACKAGE__->SUPER::init_context_whitelist };

    foreach my $ctx (keys %_Context) {
        next if $ctx eq 'Flow';
        next unless exists $_Context{$ctx}{'ins'};

        # Found a context other than 'Flow' that allows ins tags.  Take
        # a deeper copy of this part of the context hash before deleting
        # 'ins' from it, to avoid messing with the readonly structure we
        # were passed.
        $_Context{$ctx} = { %{ $_Context{$ctx} } };
        delete $_Context{$ctx}{'ins'};
    }

    sub init_context_whitelist {
        my ($self) = @_;

    return \%_Context;
    }
}
$f = SubClass_init_context_whitelist->new;
$f->input_start_document;
$f->input_start('<ins>');
$f->input_text('foo');
$f->input_end('</ins>');
$f->input_start('<i>');
$f->input_start('<ins>');
$f->input_text('foo');
$f->input_end('</ins>');
$f->input_end_document;
is( $f->filtered_document, '<ins>foo</ins><i></i><ins>foo</ins>', 'subclass init_context_whitelist' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<ins>');
$f->input_text('foo');
$f->input_end('</ins>');
$f->input_start('<i>');
$f->input_start('<ins>');
$f->input_text('foo');
$f->input_end('</ins>');
$f->input_end_document;
is( $f->filtered_document, '<ins>foo</ins><i><ins>foo</ins></i>',
                           "subclass init_context_whitelist didn't break superclass" );

=item init_attrib_whitelist

Overriding init_attrib_whitelist() so that the filter will not allow C<br>
tags to have the C<clear> attribute.

=cut

{
    package SubClass_init_attrib_whitelist;
    use base qw(HTML::StripScripts);

    use vars qw(%_Attrib);
    %_Attrib = %{ __PACKAGE__->SUPER::init_attrib_whitelist };
    $_Attrib{'br'} = { %{ $_Attrib{'br'} } };
    delete $_Attrib{'br'}{'clear'};

    sub init_attrib_whitelist {
        my ($self) = @_;

        return \%_Attrib;
    }
}
$f = SubClass_init_attrib_whitelist->new;
$f->input_start_document;
$f->input_start('<br clear="left">');
$f->input_end_document;
is( $f->filtered_document, '<br />', 'subclass init_attrib_whitelist' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<br clear="left">');
$f->input_end_document;
is( $f->filtered_document, '<br clear="left" />', "subclass init_attrib_whitelist didn't break superclass" );

=item init_attval_whitelist

Overriding init_attval_whitelist() so that the color value C<pink> is replaced
with C<blue>.

=cut

{
    package SubClass_init_attval_whitelist;
    use base qw(HTML::StripScripts);

    use vars qw(%_AttVal);
    %_AttVal = %{ __PACKAGE__->SUPER::init_attval_whitelist };
    my $super = $_AttVal{'color'};
    $_AttVal{'color'} = sub {
        my ($filter, $tag, $attname, $attval) = @_;
    $attval =~ s/pink/blue/i;
    &{ $super }($filter, $tag, $attname, $attval);
    };

    sub init_attval_whitelist {
        my ($self) = @_;

        return \%_AttVal;
    }
}
$f = SubClass_init_attval_whitelist->new;
$f->input_start_document;
$f->input_start('<font color=pink>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="blue">foo</font>', 'subclass init_attval_whitelist' );

$f->input_start_document;
$f->input_start('<font color="&#112;&#x69;&#0110;&#X00006B;">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="blue">foo</font>', 'subclass init_attval_whitelist deobfuscate pink' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<font color=pink>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="pink">foo</font>', "subclass init_attval_whitelist didn't break superclass" );

=item init_style_whitelist

Overriding init_style_whitelist() so that the C<background-color> style
attribute is not allowed.

=cut

{
    package SubClass_init_style_whitelist;
    use base qw(HTML::StripScripts);

    use vars qw(%_Style);
    %_Style = %{ __PACKAGE__->SUPER::init_style_whitelist };
    delete $_Style{'background-color'};

    sub init_style_whitelist {
        my ($self) = @_;

        return \%_Style;
    }
}
$f = SubClass_init_style_whitelist->new;
$f->input_start_document;
$f->input_start('<span style="background-color: #ffffff; color: pink">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<span style="color:pink">foo</span>', 'subclass init_style_whitelist' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<span style="background-color: #ffffff; color: pink">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<span style="background-color:#ffffff; color:pink">foo</span>',
                           "subclass init_style_whitelist didn't break superclass" );

=item init_deinter_whitelist

Overriding init_deinter_whitelist() so that the C<font> tag will not be
autodeinterleaved.

=cut

{
    package SubClass_init_deinter_whitelist;
    use base qw(HTML::StripScripts);

    use vars qw(%_DeInter);
    %_DeInter = %{ __PACKAGE__->SUPER::init_deinter_whitelist };
    delete $_DeInter{'font'};

    sub init_deinter_whitelist {
        my ($self) = @_;

        return \%_DeInter;
    }
}
$f = SubClass_init_deinter_whitelist->new;
$f->input_start_document;
$f->input_start('<i>');
$f->input_text('foo');
$f->input_start('<font size=4>');
$f->input_text('bar');
$f->input_end('</i>');
$f->input_text('baz');
$f->input_end_document;
is( $f->filtered_document, '<i>foo<font size="4">bar</font></i>baz', 'subclass init_deinter_whitelist' );

$f = HTML::StripScripts->new;
$f->input_start_document;
$f->input_start('<i>');
$f->input_text('foo');
$f->input_start('<font size=4>');
$f->input_text('bar');
$f->input_end('</i>');
$f->input_text('baz');
$f->input_end_document;
is( $f->filtered_document, '<i>foo<font size="4">bar</font></i><font size="4">baz</font>',
                           "subclass init_style_whitelist didn't break superclass" );

=item validate_href_attribute

Overriding validate_href_attribute() so that relative as well as absolute
links will be accepted.

=cut

{
    package SubClass_validate_href_attribute;
    use base qw(HTML::StripScripts);

    sub validate_href_attribute {
        my ($self, $text) = @_;

        $text =~ m#^([\w\./\-]{2,100})$# ? $1 :
    $self->SUPER::validate_href_attribute($text);
    }
}
$f = SubClass_validate_href_attribute->new({ AllowHref => 1 });
$f->input_start_document;
$f->input_start('<a href="/foo.htm">');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<a href="/foo.htm">foo</a>', 'subclass validate_href_attribute' );

=item filter_text

Overriding filter_text() to convert text to upper case

=cut

{
    package SubClass_filter_text;
    use base qw(HTML::StripScripts);

    sub filter_text {
        my ($self, $text) = @_;

    return uc $text;
    }
}
$f = SubClass_filter_text->new;
$f->input_start_document;
$f->input_start('<font color=Red>');
$f->input_text('foo');
$f->input_end_document;
is( $f->filtered_document, '<font color="Red">FOO</font>', 'subclass filter_text' );

=item escape_html_metachars

Overriding escape_html_metachars() to convert escape more aggressively

=cut

{
    package SubClass_escape_html_metachars;
    use base qw(HTML::StripScripts);

    sub escape_html_metachars {
        my ($self, $text) = @_;

    $text =~ s|([<>"'&\200-\377])| sprintf '&#%d;', ord $1 |ge;
    return $text;
    }
}
$f = SubClass_escape_html_metachars->new;
$f->input_start_document;
$f->input_start(qq{<img alt="<foo \xff>" />});
$f->input_end_document;
is( $f->filtered_document, '<img alt="&#60;foo &#255;&#62;" />', 'subclass escape_html_metachars' );

=item strip_nonprintable

Overriding strip_nonprintable() to strip more aggressively

=back

=cut

{
    package SubClass_strip_nonprintable;
    use base qw(HTML::StripScripts);

    sub strip_nonprintable {
        my ($self, $text) = @_;

    $text =~ tr#\000-\007# #s;
    return $text;
    }
}
$f = SubClass_strip_nonprintable->new;
$f->input_start_document;
$f->input_start(qq{<img alt="<foo \xff\x01\x05>" />});
$f->input_end_document;
is( $f->filtered_document, qq{<img alt="&lt;foo \xff &gt;" />}, 'subclass escape_html_metachars' );

