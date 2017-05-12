package HTML::Template::Filter::URIdecode;
use strict;
use warnings;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
    $VERSION     = '1.00';
    @ISA         = qw(Exporter);
    #Give a hoot don't pollute, do not export more than needed by default
    @EXPORT      = qw(&ht_uri_decode);
    @EXPORT_OK   = qw();
    %EXPORT_TAGS = ();
}

=head1 NAME

HTML::Template::Filter::URIdecode - Allow tmpl_ tags to be URL-encoded.

=head1 SYNOPSIS

  use HTML::Template::Filter::URIdecode 'ht_uri_decode';

  my $t = HTML::Template->new(
    filename => 'zap.tmpl',
    filter   => \&ht_uri_decode
 );

=head1 DESCRIPTION

This filter primarily does URI-decoding of HTML::Template <tmpl_...> tags. It was designed
for use Dreamweaver. Sometimes a <tmpl_var> tag is used in a way that would be invalid HTML: 

 <a href="<tmpl_var my_url>"></a>

Dreamweaver fixes the invalid HTML in this case by URL encoding it. Rather than fight it,
I've used this filter for the last several years, and Dreamweavers practice of URL-encoding these 
tags has  never been a problem since. 

Dreamweaver may also automatically "fix" URLS like this by adding one or more "../" in front
of the <tmpl_var_> tag. This filter strips those as well. 

=head1 AUTHOR

    Mark Stosberg
    CPAN ID: MARKSTOS
    mark@summersault.com

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

perl(1).

L<HTML::Template>

L<CGI::Application> - a elegant web framework which integrates with HTML::Template. 

=cut

sub ht_uri_decode {
    my $text_ref = shift;
    require URI::Escape;
    import URI::Escape qw/uri_unescape/;
    # We also remove extra "../" that DW may put before a tmpl_var tag
$$text_ref =~ s!(?:\.\./)*%3C(?:%21--)?\s*[Tt][Mm][Pp][Ll]_[Vv][Aa][Rr]([^>]*?)(?:--)?%3E!'<TMPL_VAR'.uri_unescape($1).'>'!ge;
}

1; # The preceding line will help the module return a true value

