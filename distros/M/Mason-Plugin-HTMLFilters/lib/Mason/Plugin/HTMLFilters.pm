package Mason::Plugin::HTMLFilters;
BEGIN {
  $Mason::Plugin::HTMLFilters::VERSION = '0.03';
}
use Moose;
with 'Mason::Plugin';

1;

__END__

=head1 NAME

Mason::Plugin::HTMLFilters - Filters related to HTML generation

=head1 FILTERS

=over

=item HTML or H

Do a basic HTML escape on the content - just the characters '&', '>', '<', and
'"'.

    <input name="company" value="<% $company | H %>">

=item HTMLEntities

Do a comprehensive HTML escape on the content, using
HTML::Entities::encode_entities.

=item URI or U

URI-escape the content.

    <a href="<% $url | U %>">

=item HTMLPara

Formats a block of text into HTML paragraphs.  A sequence of two or more
newlines is used as the delimiter for paragraphs which are then wrapped in HTML
""<p>""...""</p>"" tags. Taken from L<Template::Toolkit|Template>. e.g.

    % $.HTMLPara {{
    First paragraph.
      
    Second paragraph.
    % }}
    
outputs:

    <p>
    First paragraph.
    </p>
      
    <p>
    Second paragraph.
    </p>

=item HTMLParaBreak

Similar to HTMLPara above, but uses the HTML tag sequence "<br><br>" to join
paragraphs. Taken from L<Template::Toolkit|Template>. e.g.

    % $.HTMLPara {{
    First paragraph.
      
    Second paragraph.
    % }}
    
outputs:

    First paragraph.
    <br><br>
    Second paragraph.

=item FillInForm ($form_data, %options)

Uses L<HTML::FillInForm|HTML::FillInForm> to fill in the form with the
specified I<$form_data> and I<%options>.

    % $.FillInForm($form_data, target => 'form1') {{
    ...
    <form name='form1'>
    ...
    % }}

=back

=head1 SUPPORT

The mailing list for Mason and Mason plugins is
L<mason-users@lists.sourceforge.net>. You must be subscribed to send a message.
To subscribe, visit
L<https://lists.sourceforge.net/lists/listinfo/mason-users>.

You can also visit us at C<#mason> on L<irc://irc.perl.org/#mason>.

Bugs and feature requests will be tracked at RT:

    http://rt.cpan.org/NoAuth/Bugs.html?Dist=Mason-Plugin-HTMLFilters
    bug-mason-plugin-htmlfilters@rt.cpan.org

The latest source code can be browsed and fetched at:

    http://github.com/jonswar/perl-mason-plugin-htmlfilters
    git clone git://github.com/jonswar/perl-mason-plugin-htmlfilters.git

=head1 SEE ALSO

L<Mason|Mason>

