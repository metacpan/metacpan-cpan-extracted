package HTML::Lint::HTML4;

use warnings;
use strict;

=head1 NAME

HTML::Lint::HTML4 -- Rules for HTML 4 as used by HTML::Lint.

=head1 SYNOPSIS

Collection of tags and attributes for use by HTML::Lint.  You can add
your own tags and attributes if you like.

    # Add an attribute that your company uses.
    HTML::Lint::HTML4::add_attribute( 'body', 'proprietary-attribute' );

    # Add the HTML 5 <canvas> tag.
    HTML::Lint::HTML4::add_tag( 'canvas' );
    HTML::Lint::HTML4::add_attribute( 'canvas', $_ ) for qw( height width );

This must be done before HTML::Lint does any validation.  Note also that
this modifies a global table, and is not on a per-object basis.

=cut

use parent 'Exporter';
our @EXPORT_OK = qw( %isKnownAttribute %isRequired %isNonrepeatable %isObsolete );

sub _hash   { return { map { ($_ => 1) } @_ } }

our @physical   = qw( b big code i kbd s small strike sub sup tt u xmp );
our @content    = qw( abbr acronym cite code dfn em kbd samp strong var );

our @core   = qw( class id style title );
our @i18n   = qw( dir lang );
our @events = qw( onclick ondblclick onkeydown onkeypress onkeyup
                    onmousedown onmousemove onmouseout onmouseover onmouseup );
our @std    = (@core,@i18n,@events);

our %isRequired = %{_hash( qw( html body head title ) )};
our %isNonrepeatable = %{_hash( qw( html head base title body isindex ))};
our %isObsolete     = %{_hash( qw( listing plaintext xmp ) )};

# Some day I might do something with these.  For now, they're just comments.
sub _ie_only { return @_ }
sub _ns_only { return @_ }

our %isKnownAttribute = (
    # All the physical markup has the same
    (map { $_=>_hash(@std) } (@physical, @content) ),

    a           => _hash( @std, qw( accesskey charset coords href hreflang name onblur onfocus rel rev shape tabindex target type ) ),
    address     => _hash( @std ),
    applet      => _hash( @std ),
    area        => _hash( @std, qw( accesskey alt coords href nohref onblur onfocus shape tabindex target ) ),
    base        => _hash( qw( href target ) ),
    basefont    => _hash( qw( color face id size ) ),
    bdo         => _hash( @core, @i18n ),
    blockquote  => _hash( @std, qw( cite ) ),
    body        => _hash( @std,
                    qw( alink background bgcolor link marginheight marginwidth onload onunload text vlink ),
                    _ie_only( qw( bgproperties leftmargin topmargin ) ),
                    ),
    br          => _hash( @core, qw( clear ) ),
    button      => _hash( @std, qw( accesskey disabled name onblur onfocus tabindex type value ) ),
    caption     => _hash( @std, qw( align ) ),
    center      => _hash( @std ),
    cite        => _hash(),
    col         => _hash( @std, qw( align char charoff span valign width ) ),
    colgroup    => _hash( @std, qw( align char charoff span valign width ) ),
    del         => _hash( @std, qw( cite datetime ) ),
    div         => _hash( @std, qw( align ) ),
    dir         => _hash( @std, qw( compact ) ),
    dd          => _hash( @std ),
    dl          => _hash( @std, qw( compact ) ),
    dt          => _hash( @std ),
    embed       => _hash(
                    qw( align height hidden name palette quality play src units width ),
                    _ns_only( qw( border hspace pluginspage type vspace ) ),
                    ),
    fieldset    => _hash( @std ),
    font        => _hash( @core, @i18n, qw( color face size ) ),
    form        => _hash( @std, qw( accept-charset action enctype method name onreset onsubmit target ) ),
    frame       => _hash( @core, qw( frameborder longdesc marginheight marginwidth name noresize scrolling src ) ),
    frameset    => _hash( @core, qw( cols onload onunload rows border bordercolor frameborder framespacing ) ),
    h1          => _hash( @std, qw( align ) ),
    h2          => _hash( @std, qw( align ) ),
    h3          => _hash( @std, qw( align ) ),
    h4          => _hash( @std, qw( align ) ),
    h5          => _hash( @std, qw( align ) ),
    h6          => _hash( @std, qw( align ) ),
    head        => _hash( @i18n, qw( profile ) ),
    hr          => _hash( @core, @events, qw( align noshade size width ) ),
    html        => _hash( @i18n, qw( version xmlns xml:lang ) ),
    iframe      => _hash( @core, qw( align frameborder height longdesc marginheight marginwidth name scrolling src width ) ),
    img         => _hash( @std, qw( align alt border height hspace ismap longdesc name src usemap vspace width ) ),
    input       => _hash( @std, qw( accept accesskey align alt border checked disabled maxlength name onblur onchange onfocus onselect readonly size src tabindex type usemap value ) ),
    ins         => _hash( @std, qw( cite datetime ) ),
    isindex     => _hash( @core, @i18n, qw( prompt ) ),
    label       => _hash( @std, qw( accesskey for onblur onfocus ) ),
    legend      => _hash( @std, qw( accesskey align ) ),
    li          => _hash( @std, qw( type value ) ),
    'link'      => _hash( @std, qw( charset href hreflang media rel rev target type ) ),
    'map'       => _hash( @std, qw( name ) ),
    menu        => _hash( @std, qw( compact ) ),
    meta        => _hash( @i18n, qw( content http-equiv name scheme ) ),
    nobr        => _hash( @std ),
    noframes    => _hash( @std ),
    noscript    => _hash( @std ),
    object      => _hash( @std, qw( align archive border classid codebase codetype data declare height hspace name standby tabindex type usemap vspace width )),
    ol          => _hash( @std, qw( compact start type ) ),
    optgroup    => _hash( @std, qw( disabled label ) ),
    option      => _hash( @std, qw( disabled label selected value ) ),
    p           => _hash( @std, qw( align ) ),
    param       => _hash( qw( id name type value valuetype ) ),
    plaintext   => _hash(),
    pre         => _hash( @std, qw( width ) ),
    q           => _hash( @std, qw( cite ) ),
    script      => _hash( qw( charset defer event for language src type ) ),
    'select'    => _hash( @std, qw( disabled multiple name onblur onchange onfocus size tabindex ) ),
    span        => _hash( @std ),
    style       => _hash( @i18n, qw( media title type ) ),
    table       => _hash( @std,
                    qw( align bgcolor border cellpadding cellspacing datapagesize frame rules summary width ),
                    _ie_only( qw( background bordercolor bordercolordark bordercolorlight ) ),
                    _ns_only( qw( bordercolor cols height hspace vspace ) ),
                    ),
    tbody       => _hash( @std, qw( align char charoff valign ) ),
    td          => _hash( @std,
                    qw( abbr align axis bgcolor char charoff colspan headers height nowrap rowspan scope valign width ),
                    _ie_only( qw( background bordercolor bordercolordark bordercolorlight ) ),
                    ),
    textarea    => _hash( @std, qw( accesskey cols disabled name onblur onchange onfocus onselect readonly rows tabindex wrap ) ),
    th          => _hash( @std,
                    qw( abbr align axis bgcolor char charoff colspan headers height nowrap rowspan scope valign width ),
                    _ie_only( qw( background bordercolor bordercolordark bordercolorlight ) ),
                    ),
    thead       => _hash( @std, qw( align char charoff valign ) ),
    tfoot       => _hash( @std, qw( align char charoff valign ) ),
    title       => _hash( @i18n ),
    tr          => _hash( @std,
                    qw( align bgcolor char charoff valign ),
                    _ie_only( qw( bordercolor bordercolordark bordercolorlight nowrap ) ),
                    _ns_only( qw( nowrap ) ),
                ),
    ul          => _hash( @std, qw( compact type ) ),
);


=head1 FUNCTIONS

The functions below are very specifically not exported, and need to be
called with a complete package reference, so as to remind the programmer
that she is monkeying with the entire package.

=head2 add_tag( $tag );

Adds a tag to the list of tags that HTML::Lint knows about.  If you
specify a tag that HTML::Lint already knows about, then nothing is
changed.

    HTML::Lint::HTML4::add_tag( 'canvas' );

=cut

sub add_tag {
    my $tag = shift;

    if ( !$isKnownAttribute{ $tag } ) {
        $isKnownAttribute{ $tag } = {};
    }

    return;
}


=head2 add_attribute( $tag, $attribute );

Adds an attribute to a tag that HTML::Lint knows about.  The tag must
already be known to HTML::Lint or else this function will die.

    HTML::Lint::HTML4::add_attribute( 'canvas', $_ ) for qw( height width );

=cut

sub add_attribute {
    my $tag  = shift;
    my $attr = shift;

    my $attrs = $isKnownAttribute{ $tag } || die "Tag $tag is unknown";

    $isKnownAttribute{ $tag }->{ $attr } = 1;

    return;
}

1;

__END__

=head1 AUTHOR

Andy Lester C<andy at petdance.com>

=head1 COPYRIGHT

Copyright 2005-2018 Andy Lester.

This program is free software; you can redistribute it and/or modify it
under the terms of the Artistic License v2.0.

http://www.opensource.org/licenses/Artistic-2.0

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=cut
