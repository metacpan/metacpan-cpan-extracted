package FU::XMLWriter 1.2;
use v5.36;
use Carp 'confess';
use Exporter 'import';

our $XSPRINT;
BEGIN { require FU::XS unless $XSPRINT }

my @NORMAL_TAGS = qw/
    a_ abbr_ address_ article_ aside_ audio_ b_ bb_ bdo_ blockquote_ body_
    button_ canvas_ caption_ cite_ code_ colgroup_ datagrid_ datalist_ dd_ del_
    details_ dfn_ dialog_ div_ dl_ dt_ em_ fieldset_ figure_ footer_ form_ h1_
    h2_ h3_ h4_ h5_ h6_ head_ header_ i_ iframe_ ins_ kbd_ label_ legend_ li_
    main_ map_ mark_ menu_ meter_ nav_ noscript_ object_ ol_ optgroup_ option_
    output_ p_ pre_ progress_ q_ rp_ rt_ ruby_ samp_ script_ section_ select_
    small_ span_ strong_ style_ sub_ summary_ sup_ table_ tbody_ td_ textarea_
    tfoot_ th_ thead_ time_ title_ tr_ ul_ var_ video_
/;

my @SELFCLOSE_TAGS = qw/
    area_ base_ br_ col_ command_ embed_ hr_ img_ input_ link_ meta_ param_
    source_
/;

# Used by FU.xs to generate an XS function for each tag.
# (Wrapping tag_() within Perl is slow, using ALIAS is possible but still benefits from code gen)
if ($XSPRINT) {
    sub f($name, $selfclose) {
        my $tag = $name =~ s/_$//r;
        my $len = length $tag;
        printf <<~_;
          void $name(...)
            CODE:
              if (!fuxmlwr_tail) fu_confess("No active FU::XMLWriter instance");
              fuxmlwr_tag(aTHX_ fuxmlwr_tail, ax, 0, items, $selfclose, "$tag", $len);

          _
    }
    f $_, 0 for @NORMAL_TAGS;
    f $_, 1 for @SELFCLOSE_TAGS;
}


our %EXPORT_TAGS = (
    html5_ => [ qw/tag_ html_ lit_ txt_/, @NORMAL_TAGS, @SELFCLOSE_TAGS ],
    xml_ => [ qw/xml_ tag_ lit_ txt_/ ],
);

our @EXPORT_OK = (
    qw/fragment xml_ xml_escape/,
    @{$EXPORT_TAGS{html5_}},
);

my %XML = qw/& &amp; < &lt; " &quot;/;
sub xml_escape($s) {
    return '' if !defined $s;
    $s =~ s/([&<"])/$XML{$1}/gr;
}

sub fragment :prototype(&) ($f) {
    my $wr = _new();
    $f->();
    $wr->_done;
}

sub html_(@arg) {
    fragment {
        lit_("<!DOCTYPE html>\n");
        tag_('html', @arg);
    }
}

sub xml_ :prototype(&) ($f) {
    fragment {
        lit_(qq{<?xml version="1.0" encoding="UTF-8"?>\n});
        $f->();
    }
}

1;
__END__
=head1 NAME

FU::XMLWriter - Convenient and efficient XML and HTML generator.

=head1 SYNOPSIS

  use FU::XMLWriter ':html5_';

  my $html_string = html_ sub {
    head_ sub {
      title_ 'Document title!';
    };
    body_ sub {
      h1_ 'Main title!';
      p_ class => 'description', sub {
        txt_ 'Here we have <textual> data.';
        br_;
        a_ href => '/path', 'And a link.';
      };
    };
  };

  # Or XML:

  use FU::XMLWriter ':xml_';

  my $xml_string = xml_ sub {
    tag_ feed => xmlns => 'http://www.w3.org/2005/Atom',
        'xml:lang' => 'en', 'xml:base' => 'https://mywebsite/atom.feed', sub {
      tag_ title => 'My awesome Atom feed';
      # etc
    };
  };

=head1 DESCRIPTION

This is a convenient XML writer that provides an imperative API to generating
dynamic XML.  It just so happens that XML syntax is also completely valid for
HTML5, so this module is primarily abused for that purpose.

As a naming convention, all XML/HTML output functions are suffixed with an
underscore (C<_>) to make their functionality easy to identify and avoid
potential naming collisions. You are encouraged to follow this convention in
your own code. For example, if you have a function to convert some data into a
nicely formatted table, you could name it C<info_table_()> or something. It's
like having composable custom HTML elements, but in the backend!

Generating HTML is something that website backends tend to do a I<lot>, but
calling tons of Perl functions is generally not very fast. For that reason,
this is an XS module implemented in C. It compares favorably against a few
other XML writing modules on CPAN that I tried, but whether this approach is
faster than typical templating solutions... I've no idea. Check out
L<FU::Benchmarks> for some benchmarks.

=head1 Top-level functions

These functions all return a byte string with (UTF-8) encoded XML.

=over

=item fragment($block)

Executes C<$block> and captures the output of all L</"Output functions">
called within the same scope into a string. This function can be safely nested:

  my $string = fragment {
    p_ 'Stuff here';

    my $subfragment = fragment {
      div_ 'More stuff here';
    };
    # $subfragment = '<div>More stuff here</div>'
  };
  # $string = '<p>Stuff here</p>'

=item xml_($block)

Like C<fragment()> but adds a C<< <?xml ..> >> declaration.

=item html_(@args)

Like C<fragment()> but adds a suitable DOCTYPE of HTML5. The C<@args> are
passed to the C<tag_()> call for the top-level C<< <html> >> element.

=back

=head1 Output functions

=over

=item tag_($name, @attrs, $content)

This is the meat of this module. Output an XML element with the given C<$name>.
C<$content> can either be C<undef> to create a self-closing tag:

  tag_ 'br', undef;
  # <br />

Or a string:

  tag_ 'title', 'My title & stuff';
  # <title>My title &amp; stuff</title>

Or a subroutine:

  tag_ 'div', sub {
    tag_ 'br', undef;
  };
  # <div><br /></div>

Attributes can be given as key/value pairs:

  tag_ 'a', href => '/?f&c', title => 'Homepage', 'link';
  # <a href="/f&amp;c" title="Homepage">link</a>

An C<undef> value causes the attribute to be ignored:

  tag_ 'option', selected => time % 2 == 0 ? 'selected' : undef, '';
  # Depending on the time:
  #   <option></option>
  # Or
  #   <option selected="selected"></option>

A C<'+'> attribute name can be used to append a string to the previously given
attribute:

  tag_ 'div', class => $is_hidden ? 'hidden' : undef,
             '+'    => $is_warning ? 'warning' : undef, 'Text';
  # Results in either:
  #   <div>Text</div>
  #   <div class="hidden">Text</div>
  #   <div class="warning">Text</div>
  #   <div class="hidden warning">Text</div>

=item txt_($string)

Takes a Unicode string and outputs it, escaping any special XML characters in
the process.

=item lit_($string)

Takes a Unicode string and outputs it literally, i.e. without any XML escaping.

=item <html-tag>_(@attrs, $content)

This module provides a short-hand function for every HTML5 tag. Using these is
less typing and also slightly more performant than calling C<tag_()>. The
following C<tag_()>-like wrapper functions are provided:

    a_ abbr_ address_ article_ aside_ audio_ b_ bb_ bdo_ blockquote_ body_
    button_ canvas_ caption_ cite_ code_ colgroup_ datagrid_ datalist_ dd_ del_
    details_ dfn_ dialog_ div_ dl_ dt_ em_ fieldset_ figure_ footer_ form_ h1_
    h2_ h3_ h4_ h5_ h6_ head_ header_ i_ iframe_ ins_ kbd_ label_ legend_ li_
    main_ map_ mark_ menu_ meter_ nav_ noscript_ object_ ol_ optgroup_ option_
    output_ p_ pre_ progress_ q_ rp_ rt_ ruby_ samp_ script_ section_ select_
    small_ span_ strong_ style_ sub_ summary_ sup_ table_ tbody_ td_ textarea_
    tfoot_ th_ thead_ time_ title_ tr_ ul_ var_ video_

Additionally, the following self-closing-tag functions are provided:

    area_ base_ br_ col_ command_ embed_ hr_ img_ input_ link_ meta_ param_
    source_

The self-closing functions do not require a C<$content> argument; if none is
provided it defaults to C<undef>.

=back

=head1 Utility function

=over

=item xml_escape($string)

Return the XML-escaped version of C<$string>. The characters C<&>, C<E<lt>>,
and C<"> are replaced with their XML entity.

=back

=head1 Import options

All of the functions mentioned in this document can be imported individually.
There are also two import groups:

  use FU::XMLWriter ':html5_';

Exports C<tag_()>, C<html_()>, C<lit_()>, C<txt_()> and all of the C<<
<html-tag>_ >> functions mentioned above.

  use FU::XMLWriter ':xml_';

Exports C<xml_()>, C<tag_()>, C<lit_()> and C<txt_()>.

=head1 SEE ALSO

This module is part of the L<FU> framework, although it can be used
independently of it.

This module was based on L<TUWF::XML>, which was in turn inspired by
L<XML::Writer>, which is more powerful but less convenient.

There's also L<DSL::HTML>, a slightly more featureful, heavyweight and
opinionated HTML-templating-inside-Perl module, based on L<HTML::Tree>.

And there's L<HTML::Declare>, which is conceptually simpler than both this and
L<DSL::HTML>, but its syntax isn't quite as nice.

And there's also L<HTML::FromArrayref>, L<HTML::Tiny>, L<HTML::Untidy> and many
more modules on CPAN. In fact I don't know why you should use this module
instead of whatever is available on CPAN.

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
