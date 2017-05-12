package HTML::EscapeEvil;

use strict;
use base qw(HTML::Filter Class::Accessor);
use HTML::Element;
use Carp;

our ( $ENTITY_REGEXP, %JS_EVENT, $VERSION );

__PACKAGE__->mk_accessors(
    qw(allow_comment allow_declaration allow_process allow_entity_reference allow_script allow_style collection_process)
);
__PACKAGE__->mk_ro_accessors(qw(processes));

BEGIN {

    $VERSION = 0.05;

    my @allow_entity_references =
      ( "amp", "lt", "gt", "quot", "apos", "#039", "nbsp", "copy", "reg" );
    $ENTITY_REGEXP = "&amp;(" . ( join "|", @allow_entity_references ) . ")(;)";

# ============================================================================= #
# allow javascript event handler setting
# cite : javascript in href. e.g. <a href="javascript:alert('hello')">hello</a>
# ============================================================================= #
    %JS_EVENT = (
        cite        => 0,
        onblur      => 0,
        onchange    => 0,
        onclick     => 0,
        ondblclick  => 0,
        onerror     => 0,
        onfocus     => 0,
        onkeydown   => 0,
        onkeypress  => 0,
        onkeyup     => 0,
        onload      => 0,
        onmousedown => 0,
        onmousemove => 0,
        onmouseout  => 0,
        onmouseover => 0,
        onmouseup   => 0,
        onreset     => 0,
        onselect    => 0,
        onsubmit    => 0,
        onunload    => 0,
    );
}

sub new {

    my ( $class, %args ) = @_;
    my $self = $class->SUPER::new;

    foreach (
        qw(allow_comment allow_declaration allow_process allow_style allow_script collection_process)
      )
    {

        $self->{$_} = ( $args{$_} ) ? 1 : 0;
    }

    if (   $args{allow_entity_reference} ne ""
        && $args{allow_entity_reference} == 0 )
    {

        $self->{allow_entity_reference} = 0;
    }
    else {

        $self->{allow_entity_reference} = 1;
    }

    $self->{processes} = [];

    $self->{_content}    = [];
    $self->{_allow_tags} = {};

    bless $self, ref $class || $class;

    if ( $args{allow_tags} ) {

        $self->add_allow_tags( ( ref( $args{allow_tags} ) eq "ARRAY" )
            ? @{ $args{allow_tags} }
            : $args{allow_tags} );
    }

    return $self;
}

sub set_allow_tags {

    my $self = shift;
    $self->{_allow_tags}  = {};
    $self->{_current_tag} = undef;

    $self->{allow_script}           = 0;
    $self->{allow_style}            = 0;
    $self->{allow_comment}          = 0;
    $self->{allow_declaration}      = 0;
    $self->{allow_process}          = 0;
    $self->{allow_entity_reference} = 1;
    $self->{collection_process}     = 0;

    $self->clear_content;
    $self->clear_process;
    $self->add_allow_tags(@_);
}

sub add_allow_tags {

    my ( $self, @tags ) = @_;
    foreach my $tag (@tags) {

        $tag = lc $tag;
        if ( $tag eq "script" || $tag eq "style" ) {

            $self->{"allow_$tag"} = 1;
            next;
        }
        $self->{_allow_tags}->{$tag} = 1;
    }

}

sub deny_tags {

    my ( $self, @tags ) = @_;
    foreach my $tag (@tags) {

        $tag = lc $tag;
        if ( $tag eq "script" || $tag eq "style" ) {

            $self->{"allow_$tag"} = 0;
            next;
        }
        delete $self->{_allow_tags}->{$tag};
    }
}

sub get_allow_tags {

    my $self = shift;
    my @tags = keys %{ $self->{_allow_tags} };
    push @tags, "script" if $self->{allow_script};
    push @tags, "style"  if $self->{allow_style};
    return sort { $a cmp $b } @tags;
}

sub is_allow_tags {

    my ( $self, $tag ) = @_;
    my $flag;
    $tag = lc $tag;
    if ( $tag eq "script" || $tag eq "style" ) {

        $flag = $self->{"allow_$tag"};
    }
    else {

        $flag = ( exists $self->{_allow_tags}->{$tag} ) ? 1 : 0;
    }
    return ($flag) ? 1 : 0;
}

sub deny_all {

    my $self = shift;
    $self->{_allow_tags}            = {};
    $self->{_current_tag}           = undef;
    $self->{allow_script}           = 0;
    $self->{allow_style}            = 0;
    $self->{allow_comment}          = 0;
    $self->{allow_declaration}      = 0;
    $self->{allow_process}          = 0;
    $self->{allow_entity_reference} = 0;
}

sub filtered_html {

    my $self = shift;
    my $content = join "", @{ $self->{_content} };
    $self->clear_content;
    return $content;
}

sub filtered_file {

    my $self = shift;
    my $fh;
    ( ref( $_[0] ) eq "GLOB" || ref( \$_[0] ) eq "GLOB" )
      ? ( $fh = $_[0] )
      : ( open $fh, "> $_[0]" or croak($!) );
    print $fh $self->filtered_html;
    close $fh;
}

sub filtered {

    my $self = shift;
    my $content;
    if ( -e $_[0] || ref( $_[0] ) eq "GLOB" || ref( \$_[0] ) eq "GLOB" ) {

        $self->parse_file( $_[0] );
    }
    elsif ( $_[0] ne "" ) {

        $self->parse( $_[0] );
    }
    else {

        croak("content is empty");
    }

    if ( $_[1] ) {

        $self->filtered_file( $_[1] );
        $content = 1;
    }
    else {

        $content = $self->filtered_html;
    }

    $self->eof;
    $self->{_current_tag} = undef;

    return $content;
}

sub clear {

    my $self = shift;
    $self->eof;
    $self->clear_process;
    $self->clear_content;
    $self->{_current_tag} = undef;
}

sub clear_content {

    my $self = shift;
    $self->{_content} = [] if scalar @{ $self->{_content} };
}

sub clear_process {

    my $self = shift;
    $self->{processes} = [] if scalar @{ $self->{processes} };
}

sub DESTROY {

    my $self = shift;
    $self->clear;
}

sub _escape {

    my $string = shift;
    $string =~ s/&/&amp;/g;
    $string =~ s/</&lt;/g;
    $string =~ s/>/&gt;/g;
    $string =~ s/\"/&quot;/g;
    $string =~ s/\'/&#039;/g;
    return $string;
}

sub _unescape {

    my $string = shift;
    $string =~ s/&amp;/&/g;
    $string =~ s/&lt;/</g;
    $string =~ s/&gt;/>/g;
    $string =~ s/&quot;/\"/g;
    $string =~ s/&#039;/\'/g;
    $string =~ s/&apos;/\'/g;
    return $string;
}

sub _unescape_entities {

    my $string = shift;
    $string =~ s/$ENTITY_REGEXP/\&$1$2/g;
    return $string;
}

# ============================== override method start ============================== #

sub declaration {

    my ( $self, $declaration ) = @_;
    $declaration = "<!$declaration>";
    $self->output( ( $self->{allow_declaration} )
        ? $declaration
        : &_escape($declaration) );
}

sub process {

    my ( $self, $process, $process_text ) = @_;
    if ( $self->{collection_process} ) {

        my $tmp_process = $process;
        $tmp_process =~ s/\?$//;
        push @{ $self->{processes} }, $tmp_process;
    }
    $self->SUPER::process( $process,
        ( $self->{allow_process} ) ? $process_text : &_escape($process_text) );
}

sub start {

    my ( $self, $tagname, $attr, $attrseq, $text ) = @_;
    $self->{_current_tag} = lc $tagname;
    if ( $self->is_allow_tags($tagname) ) {

        if ( !$self->allow_script ) {
## change javascript event handler(1 : allow) e.g <body onload="alert(1)"> => <body onload="void(0)">
            foreach ( keys %{$attr} ) {

                my $event = lc $_;
                if ( exists $JS_EVENT{$event} && !$JS_EVENT{$event} ) {

                    #delete $attr->{$event};
                    $attr->{$event} = "void(0)";
                }
            }

## change javascript <a href="javascript:evil_script('evil')"> => <a href="javascript:void(0)">
            if ( !$JS_EVENT{cite} && $attr->{href} =~ /^(java|vb)script:/i ) {

                $attr->{href} = "javascript:void(0)";
            }
## tag is generated again
            my $element = HTML::Element->new( $tagname, %{$attr} );
            $text = $element->starttag;
            $element->delete;
            $element = undef;
        }
    }
    else {
        $text = &_escape($text);
    }
    $self->SUPER::start( $tagname, $attr, $attrseq, $text );
}

sub end {

    my ( $self, $tagname, $text ) = @_;
    $self->{_current_tag} = undef;
    $text = &_escape($text) if !$self->is_allow_tags($tagname);
    $self->SUPER::end( $tagname, $text );
}

sub comment {

    my ( $self, $comment ) = @_;
    $comment = "<!--$comment-->";
    $self->output( ( $self->{allow_comment} ) ? $comment : &_escape($comment) );
}

sub text {

    my ( $self, $text, $is_cdata ) = @_;
    $text = &_escape($text);
    $text = &_unescape_entities($text) if $self->{allow_entity_reference};
    $text = &_unescape($text)
      if $is_cdata
      && $self->{_current_tag} eq "script"
      && $self->{allow_script};
    $text = &_unescape($text)
      if $is_cdata && $self->{_current_tag} eq "style" && $self->{allow_style};
    $self->SUPER::text( $text, $is_cdata );
}

sub output {

    my ( $self, $content ) = @_;
    push @{ $self->{_content} }, $content;
}

1;

__END__

=head1 NAME

HTML::EscapeEvil - Escape tag

=head1 VERSION

0.05

=head1 SYNPSIS

    use HTML::EscapeEvil;
    my $escapeevil = HTML::EscapeEvil->new;
    my $evil_html = <<HTML;
    <script type="text/javascript">
    <!--
    alert("script is evil tags!!");
    //-->
    </script>
    <iflame src="deny.html" width="100" height="100"></iframe>
    HTML

    $escapeevil->parse($html); #from string
    $escapeevil->parse_file($html_file); #from file or file handle

    my $clean_html = $escapeevil->filtered_html;
    $escapeevil->clear;

=head1 DESCRIPTION

The tag that doesn't want to permit escapes all.

=head1 METHOD

=head2 new

create instance

Example : 

    my $escapeevil = HTML::EscapeEvil->new(
                                         allow_comment => 1,
                                         allow_declaration => 0,
                                         allow_process => 0,
                                         allow_tags => [qw(a l l o w t a g s)],
                                         #allow_tags => "one",# OK
                                        );

Option :

allow_comment          : allow comment. default 0.

allow_declaration      : allow_declaration. default 0.

allow_process          : allow_process. default 0.

allow_tags             : set allow tags

allow_script           : allow script tag. default 0(is_allow_tags("script") OK)

allow_style            : allow style tag. default 0(is_allow_tags("style") OK)

allow_entity_reference : allow entity reference. default 1

collection_process     : collection process. default 0

When tag is not specified for allow_tags, default makes all tag invalid. 

=head2 set_allow_tags

The setting is returned to default. 

Example : 

    $escapeevil->set_allow_tags(qw(t a g s));

=head2 add_allow_tags

The tag that wants to permit is added. 

Example : 

    $escapeevil->add_allow_tags(qw(t a g s));

=head2 deny_tags

The specified tag is not permitted.

Example : 

    $escapeevil->deny_tags(qw(t a g s));

=head2 get_allow_tags

The list of the tag that has been permitted is returned. 

Example : 

    my @list = $escapeevil->get_allow_tags;

=head2 is_allow_tags

Whether it is tag that has been permitted is checked. 

Example : 

    print 'script is ', ($escapeevil->is_allow_tags('script')) ? 'allowed' : 'not allowed';

=head2 deny_all

No permission of all

Example : 

    $escapeevil->deny_all;

=head2 allow_comment

Whether the comment has been permitted is checked. Or, the setting change of the comment permission. 

Example : 

    print 'comment is ', ($escapeevil->allow_comment) ? 'allowed' : 'not allowed';
    $escapeevil->allow_comment(1); ## allow comment!

=head2 allow_declaration

Whether the DOCTYPE declaration has been permitted is checked. Or, the setting change of the DOCTYPE declaration permission. 

Example : 

    print 'declaration is ', ($escapeevil->allow_declaration) ? 'allowed' : 'not allowed';
    $escapeevil->allow_declaration(1); ## allow declaration!

=head2 allow_process

Whether the processing instruction has been permitted is checked. Or, the setting change of the processing instruction. 

Example : 

    print 'process is ', ($escapeevil->allow_process) ? 'allowed' : 'not allowed';
    $escapeevil->allow_process(1); ## allow process!

=head2 allow_entity_reference

Whether the substance reference has been permitted is checked. Or, the setting change of the substance reference. 

Example : 

    print 'entity_reference is ', ($escapeevil->allow_entity_reference) ? 'allowed' : 'not allowed';
    $escapeevil->allow_entity_reference(1); ## allow entity_reference!

=head2 allow_script

Whether it permits is checked script tag. Or, the setting change of script tag. 

Example : 

    print 'script is ', ($escapeevil->allow_script) ? 'allowed' : 'not allowed';
    $escapeevil->allow_script(1); ## allow script!

=head2 allow_style

Whether it permits is checked style tag. Or, the setting change of style tag. 

Example : 

    print 'style is ', ($escapeevil->allow_style) ? 'allowed' : 'not allowed';
    $escapeevil->allow_style(1); ## allow style!

=head2 collection_process

The setting change whether to collect process is done. Or, a present setting is acquired. 

Example : 

    print 'collection_process is ', ($escapeevil->collection_process) ? 'collection' : 'no collection';
    $escapeevil->collection_process(1); ##colloction process!

=head2 processes

The reference of the array of the processing instruction list is acquired. (reading exclusive use)

Example : 

    foreach(@{$escapeevil->processes}){

        my $process = $_;
        #example: eval $process ,system $process etc..
    }

=head2 filtered_html

HTML that escapes in the tag not permitted is returned. 

Example : 

    print $escapeevil->filetered_html;

=head2 filtered_file

HTML that escapes in the tag not permitted is written file. 

Example : 

    (e.g.1)
    $escapeevil->filtered_file("./filtered_file.html");
    (e.g.2)
    $escapeevil->filtered_file(*FILEHANDLE);

=head2 filtered

version 0.02 new method. parse(parse_file) and filtered_html(filtered_file) and eof,clear_process do.

Example : 

    my $html = "<script type=\"text/javascript\"><!--alert(\"hello!\");//--></script>";
    (e.g.1)
    my $cleanhtml = $escapeevil->filtered($html);
    (e.g.2)
    $escapeevil->filtered($html,"writefile.html");
    (e.g.3)
    open FILEHANDLE,"< evil.html" or die $!;
    $escapeevil->filtered(*FILEHANDLE,"writefile.html");

=head2 clear_process

Collected process is annulled.

Example : 

    $escapeevil->clear_process;

=head2 clear

Initialization of variable that liberates of HTML::Parser object and is internal. Please execute it when processing is completed. 

Example : 

    $escapeevil->clear;

=head1 NEW OPTION

VERSION 0.03.Javascript of event handler becomes invalid at allow_script(0) though event handler of javascript is defined in the tag that has been permitted, too. 

Example : 

    <a href="javascript:alert(1234)">hello</a> => <a href="javascript:void(0)">hello</a>
    <body onload="alert(5678)"> => <body onload="void(0)">

The definition of event handler is described in %HTML::Escape::JS_EVENT.

=head1 CAUTION

Please filtered_file must specify passing the file and specify the correct one. Die is executed when there are neither passing nor a writing authority that cannot be. 

Processes is a method only for reading. When the value is set, die is done. 

Carp http://search.cpan.org/~nwclark/perl-5.8.8/lib/Carp.pm

Class::Accessor http://search.cpan.org/~kasei/Class-Accessor-0.22/lib/Class/Accessor.pm

HTML::Element http://search.cpan.org/~petdance/HTML-Tree-3.1901/lib/HTML/Element.pm

HTML::Filter http://search.cpan.org/~gaas/HTML-Parser-3.46/lib/HTML/Filter.pm

HTML::Parser http://search.cpan.org/~gaas/HTML-Parser-3.46/Parser.pm

=head1 SEE ALSO

L<Carp> L<Class::Accessor> L<HTML::Element> L<HTML::Filter> L<HTML::Parser>

=head1 AUTHOR

Akira Horimoto <kurt0027@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2006 Akira Horimoto

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
