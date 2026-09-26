#
#  This file is part of Docbook::Convert.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#

#
#
package Docbook::Convert;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTHORITY $AUTOLOAD);
use warnings;
no warnings qw(uninitialized utf8);
sub BEGIN {local $^W=0}


#  External modules
#
use Docbook::Convert::Constant;
use Docbook::Convert::Util;


#  External modules
#
use IO::File;
use XML::Twig;
use Data::Dumper;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$AUTHORITY='cpan:ASPEER';
$VERSION='1.012';


#===================================================================================================


sub data_ar {

    #  Container to hold node tree
    #
    my $self=shift();
    my @data=(
        shift() || undef,    # NODE_IX - tag name
        shift() || undef,    # CHLD_IX - array of child nodes
        shift() || undef,    # ATTR_IX - attributes
        shift() || undef,    # LINE_IX - line no this node was sourced from
        shift() || undef,    # COLM_IX - col no " "
        shift() || undef     # PRNT_IX - link to parent node
    );
    return \@data;

}


sub handler {


    #  Called by twig
    #
    my ($self, $data_ar, $twig_or, $elt_or)=@_;


    #  Don't process if not parent (i.e. until we have done all tags).
    #
    return if $elt_or->parent();


    #  Call parser now as we are on parent.
    #
    return $self->parse($data_ar, $elt_or);

}


sub parse {


    #  Parse and XML::Twig tree and produce a node tree
    #
    my ($self, $data_ar, $elt_or, $data_parent_ar)=@_;


    #  Get tag, any node attributes, line and col number
    #
    my $tag=$elt_or->tag();
    my $attr_hr=$elt_or->atts();
    my $line_no=delete $attr_hr->{'_line_no'};
    my $col_no=delete $attr_hr->{'_col_no'};
    $attr_hr=undef unless keys %{$attr_hr};


    #  Build array data
    #
    @{$data_ar}[$NODE_IX, $CHLD_IX, $ATTR_IX, $LINE_IX, $COLM_IX, $PRNT_IX]=
        ($tag, undef, $attr_hr, $line_no, $col_no, $data_parent_ar);    # Name, Child, Attr


    #  Go through children looking for any text nodes
    #
    foreach my $elt_child_or ($elt_or->children()) {

        #  Text ?
        #
        my $child_tag=$elt_child_or->tag();
        unless (($child_tag eq '#PCDATA') || ($child_tag eq '#CDATA')) {

            # No - recurse. Need new data container
            #
            debug("recurse for child tag: $child_tag");
            my $data_child_ar=$self->data_ar();
            $self->parse($data_child_ar, $elt_child_or, $data_ar);
            push @{$data_ar->[$CHLD_IX]}, $data_child_ar;
        }
        else {

            # Yes - store as text node. If para cleanup leading whitespace
            my $text=$elt_child_or->text();
            if ($tag eq 'para') {
                $text=&whitespace_clean($text);
            }
            debug("$tag: *$text*");
            my $data_child_ar=
                $self->data_ar('text', [$text], undef, undef, undef, $data_ar);
            push @{$data_ar->[$CHLD_IX]}, $data_child_ar;
        }
    }


    #  Done - return OK
    #
    return \undef;

}


sub process {


    #  Get self ref, file to process
    #
    my ($self, $xml, $param_hr)=@_;


    #  Create a hashed self ref to hold various info
    #
    ref($self) || do {
        $self=bless($param_hr ||= {handler => $HANDLER_DEFAULT}, ref($self) || $self)
    };


    #  Array to hold parsed data
    #
    my $data_ar=$self->data_ar();


    #  Load handler
    #
    my $handler=$param_hr->{'handler'} ||
        return err('no handler supplied');
    my $handler_module=$HANDLER_HR->{$handler} ||
        return err("unable to load handler: $handler, no module found");
    eval("use $handler_module") || do {
        return err("unable to load handler module: $handler_module, $@")
            if $@
    };


    #  Get XML::Twig object
    #
    my $xml_or=XML::Twig->new(
        'twig_handlers' => {
            '_all_' => sub {$self->handler($data_ar, @_)}
        },
        'start_tag_handlers' => {
            '_all_' => sub {$self->start_tag_handler($data_ar, @_)}
        },
        discard_all_spaces => 1,
    );


    #  Parse file which will fill $data_ar;
    #
    $xml_or->parse($xml);


    #  If we are dumping clean up a bit then spit out
    #
    if ($param_hr->{'dump'}) {
        return Dumper(dump_ar($data_ar));
    }


    #  And render
    #
    my $output=$self->render($data_ar, $handler_module);


    #  Done
    #
    return $output;

}


sub process_file {

    #  Open file we want to process
    #
    my ($self, $fn, $param_hr)=@_;
    my $fh=IO::File->new($fn, O_RDONLY) ||
        return err("unable to open file $fn, $!");
    return $self->process($fh, $param_hr);

}


sub render {


    #  Get self ref, node tree
    #
    my ($self, $data_ar, $handler)=@_;


    #  Get hander
    #
    my $render_or=$handler->new($self) ||
        return err("unable to initialise handler $handler");


    #  Call recurive render routine
    #
    my $output=$self->render_recurse($data_ar, $render_or) ||
        return err('unable to get ouput from render');


    #  Fix any anchors/links
    #
    $output=$render_or->_anchor_fix($output, $self->{'_id'});


    #  Any errors/warnings for unhandled tags ?
    #
    if ((my $hr=$render_or->{'_autoload'}) && !$self->{'no_warn_unhandled'}) {
        my @data_ar=sort {($a->[$NODE_IX] cmp $b->[$NODE_IX]) or ($a->[$LINE_IX] <=> $b->[$LINE_IX])} grep {$_} values(%{$hr});
        foreach my $data_ar (@data_ar) {
            my ($tag, $line_no, $col_no)=@{$data_ar}[$NODE_IX, $LINE_IX, $COLM_IX];
            warn("warning - unrendered tag $tag at line $line_no, column $col_no\n");
        }
    }
    if ((my $hr=$render_or->{'_autotext'}) && !$self->{'no_warn_unhandled'}) {
        my @data_ar=sort {($a->[$NODE_IX] cmp $b->[$NODE_IX]) or ($a->[$LINE_IX] <=> $b->[$LINE_IX])} grep {$_} values(%{$hr});
        foreach my $data_ar (@data_ar) {
            my ($tag, $line_no, $col_no)=@{$data_ar}[$NODE_IX, $LINE_IX, $COLM_IX];
            warn("warning - autotexted tag '$tag' at line $line_no, column $col_no\n");
            debug(Dumper($data_ar));
        }
    }


    #  Done
    #
    return $output;

}


sub render_recurse {


    #  Get self ref, node
    #
    my ($self, $data_ar, $render_or)=@_;


    #  Get tag name
    #
    my $tag=$data_ar->[$NODE_IX];


    #  Get attributes and look for anchor
    #
    my ($anchor_id, $anchor_title);
    my $attr_hr=$data_ar->[$ATTR_IX];
    if ($anchor_id=($attr_hr->{'id'} || $attr_hr->{'xml:id'})) {
        my ($title, $subtitle)=
            $render_or->find_node_tag_text($data_ar, 'title|subtitle', $NULL);
        $anchor_title=$title || $subtitle;
        $render_or->{'_id'}{$anchor_id}=($anchor_title);
        debug("anchor found: $anchor_title");
    }


    #  Does this tag turn on plaintext ? E.g. if withing screen/programlisting/commmand in Markdown no
    #  further markdown is needed
    #
    $render_or->{'_plaintext'}++ if
        $render_or->_plaintext($tag);
    debug('plaintext flag: %s', $render_or->{'_plaintext'});


    #  Render any children
    #
    if ($data_ar->[$CHLD_IX]) {
        foreach my $data_chld_ix (0..$#{$data_ar->[$CHLD_IX]}) {
            my $data_chld_ar=$data_ar->[$CHLD_IX][$data_chld_ix];
            if (ref($data_chld_ar)) {
                debug("rendering child $data_chld_ar");
                my $data=$self->render_recurse($data_chld_ar, $render_or);
                $data_ar->[$CHLD_IX][$data_chld_ix]=$data;
            }
        }
    }


    #  Clear plaintext
    #
    delete $render_or->{'_plaintext'}
        if $render_or->_plaintext($tag);


    #  Render this tag
    #
    my $render=$render_or->$tag($data_ar);
    debug("$tag *$render*") unless ref($render);


    #  Create anchor if needed
    #
    if ($anchor_id) {
        my $anchor=($render_or->_anchor($anchor_id, $anchor_title) . $CR2) unless $NO_HTML;
        debug("creating anchor: $anchor, render $render");
        if (ref($render)) {
            unless ($self->{'no_warn_unhandled'}) {
                warn("warning - unable to add anchor #${anchor_id} for unhandled tag: $tag\n");
            }
        }
        else {
            $render=join($CR2, $anchor, $render) unless ref($render);
        }
    }


    #  Done
    #
    return $render;

}


sub start_tag_handler {

    my ($self, $data_ar, $twig_or, $elt_or)=@_;
    $elt_or->set_att('_line_no', $twig_or->current_line());
    $elt_or->set_att('_col_no',  $twig_or->current_column());

}


sub AUTOLOAD {

    #  Catchall for handler shortcuts, e.g. Docbook::Convert->markdown();
    #
    my ($self, $xml, $param_hr)=@_;
    my ($handler)=($AUTOLOAD=~/::(\w+)$/);
    if ($handler=~s/_file$//) {
        return $self->process_file($xml, {%{$param_hr}, handler => $handler});
    }
    else {
        return $self->process($xml, {%{$param_hr}, handler => $handler});
    }
}


sub DESTROY {

    #  Stub so not invoked by AUTOLOAD

}

1;
__END__

=begin markdown

# NAME

Docbook::Convert - convert DocBook articles and reference pages to Markdown

# SYNOPSIS

For the retained custom renderer:

```perl
use Docbook::Convert;

my $markdown=Docbook::Convert->markdown_file('doc/guide.xml');
```

For guides using the packaged Pandoc pipeline:

```perl
use Docbook::Convert::Pandoc;

my $converter_or=Docbook::Convert::Pandoc->new();
my $output_fn=$converter_or->convert_file('doc/guide.xml');
```

# DESCRIPTION

`Docbook::Convert` retains the original Perl renderer for DocBook articles and
reference pages. `Docbook::Convert::Pandoc` is the preferred path for larger
guides: it expands local includes and preserves section identifiers,
admonitions and fenced-code attributes.

The converter produces Markdown. Perl documentation is subsequently handled by
`Markdown::Pod::Embed`; direct DocBook-to-POD conversion is retired.

# METHODS

## process($xml, \%options)

Converts an XML string or filehandle using the selected handler. Markdown is
the default output.

## process_file($filename, \%options)

Reads and converts a DocBook file.

## markdown($xml, \%options)

Converts an XML string or filehandle with the custom Markdown renderer.

## markdown_file($filename, \%options)

Reads a DocBook file and converts it with the custom Markdown renderer.

# OPTIONS

The custom renderer accepts `meta_display_top`, `meta_display_bottom`,
`meta_display_title`, `meta_display_title_h_style`, `no_html`,
`no_image_fetch`, and `no_warn_unhandled`. The matching uppercase environment
variables provide process-wide defaults.

# LIMITATIONS

The custom renderer supports the subset of DocBook used by the original module
and utility documentation. It is not a complete DocBook implementation. The
Pandoc pipeline is explicit and does not silently fall back to the custom
renderer when an external command fails.

# SEE ALSO

`Docbook::Convert::Pandoc`, `docbook-convert`, `Markdown::Pod::Embed`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE and COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>


=end markdown


=head1 NAME

Docbook::Convert - convert DocBook articles and reference pages to Markdown


=head1 SYNOPSIS

For the retained custom renderer:


 use Docbook::Convert;

 my $markdown=Docbook::Convert->markdown_file('doc/guide.xml');
For guides using the packaged Pandoc pipeline:


 use Docbook::Convert::Pandoc;

 my $converter_or=Docbook::Convert::Pandoc->new();
 my $output_fn=$converter_or->convert_file('doc/guide.xml');

=head1 DESCRIPTION

C<Docbook::Convert> retains the original Perl renderer for DocBook articles and
reference pages. C<Docbook::Convert::Pandoc> is the preferred path for larger
guides: it expands local includes and preserves section identifiers,
admonitions and fenced-code attributes.

The converter produces Markdown. Perl documentation is subsequently handled by
C<Markdown::Pod::Embed>; direct DocBook-to-POD conversion is retired.


=head1 METHODS


=head2 process($xml, \%options)

Converts an XML string or filehandle using the selected handler. Markdown is
the default output.


=head2 process_file($filename, \%options)

Reads and converts a DocBook file.


=head2 markdown($xml, \%options)

Converts an XML string or filehandle with the custom Markdown renderer.


=head2 markdown_file($filename, \%options)

Reads a DocBook file and converts it with the custom Markdown renderer.


=head1 OPTIONS

The custom renderer accepts C<meta_display_top>, C<meta_display_bottom>,
C<meta_display_title>, C<meta_display_title_h_style>, C<no_html>,
C<no_image_fetch>, and C<no_warn_unhandled>. The matching uppercase environment
variables provide process-wide defaults.


=head1 LIMITATIONS

The custom renderer supports the subset of DocBook used by the original module
and utility documentation. It is not a complete DocBook implementation. The
Pandoc pipeline is explicit and does not silently fall back to the custom
renderer when an external command fails.


=head1 SEE ALSO

C<Docbook::Convert::Pandoc>, C<docbook-convert>, C<Markdown::Pod::Embed>


=head1 AUTHOR

Andrew Speer L<mailto:andrew.speer@isolutions.com.au>


=head1 LICENSE AND COPYRIGHT

This file is part of Docbook::Convert.

This software is copyright (c) 2026 by Andrew Speer
L<mailto:andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under the same
terms as the Perl 5 programming language system itself.

=cut
