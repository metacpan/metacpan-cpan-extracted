package HTML::Rebase;
use strict;
use URI::WithBase;
use URI::URL;
use Exporter 'import';
our $VERSION = '0.04';
our @EXPORT_OK= qw(rebase_html rebase_css rebase_html_inplace rebase_css_inplace);

=head1 NAME

HTML::Rebase - rewrite HTML links to be relative to a given URL

=head1 SYNOPSIS

  use HTML::Rebase qw(rebase_html rebase_css);
  my $html = <<HTML;
  <html>
  <head>
  <link rel="stylesheet" src="http://localhost:5000/css/site.css" />
  </head>
  <body>
  <a href="http://perlmonks.org">Go to Perlmonks.org</a>
  <a href="http://localhost:5000/index.html">Go to home page/a>
  </body>
  </html>
  HTML

  my $local_html = rebase_html( "http://localhost:5000/about.html", $html );
  print $local_html;
  __END__
  <html>
  <head>
  <link rel="stylesheet" src="css/site.css" />
  </head>
  <body>
  <a href="http://perlmonks.org">Go to Perlmonks.org</a>
  <a href="index.html">Go to home page/a>
  </body>
  </html>

=head2 C<< rebase_html >>

Rewrites all HTML links to be relative to the given URL. This
only rewrites things that look like C<< src= >> and C<< href= >> attributes.
Unquoted attributes will not be rewritten. This should be fixed.

=cut

sub rebase_html {
    my($url, $html)= @_;
    
    #croak "Can only rewrite relative to an absolute URL!"
    #    unless $url->is_absolute;
    
    # Rewrite absolute to relative
    rebase_html_inplace( $url, $html );
    
    $html
}

sub rebase_html_inplace {
    my $url = shift;
    $url = URI::URL->new( $url );
    
    #croak "Can only rewrite relative to an absolute URL!"
    #    unless $url->is_absolute;

    # Check if we have a <base> tag which should replace the user-supplied URL
    if( $_[0] =~ s!<\s*\bbase\b[^>]+\bhref=([^>]+)>!!i ) {
        # Extract the HREF:
        my $href= $1;
        if( $href =~ m!^(['"])(.*?)\1! ) {
            # href="..." , with quotes
            $href = $2;
        } elsif( $href =~ m!^([^>"' ]+)! ) {
            # href=... , without quotes
            $href = $1;
        } else {
            die "Should not get here, weirdo href= tag: [$href]"
        };
        
        my $old_url = $url;
        $url = relative_url( $url, $href );
        #warn "base: $old_url / $href => $url";
    };

    # Rewrite absolute to relative
    # Rewrite all tags with quotes
    $_[0] =~ s!((?:\bsrc|\bhref)\s*=\s*(["']))(.+?)\2!$1 . relative_url($url,"$3") . $2!ige;
    # Rewrite all tags without quotes
    $_[0] =~ s!((?:\bsrc|\bhref)\s*=\s*)([^>"' ]+)!$1 . '"' . relative_url($url,"$2") . '"'!ige;
}

=head2 C<< rebase_css >>

Rewrites all CSS links to be relative to the given URL. This
only rewrites things that look like C<< url( ... ) >> .

=cut

sub rebase_css {
    my($url, $css)= @_;
    
    #croak "Can only rewrite relative to an absolute URL!"
    #    unless $url->is_absolute;

    # Rewrite absolute to relative
    rebase_css_inplace( $url, $css );
    
    $css
}

sub rebase_css_inplace {
    my $url = shift;
    $url = URI::URL->new( $url );
    
    #croak "Can only rewrite relative to an absolute URL!"
    #    unless $url->is_absolute;

    # Rewrite absolute to relative
    $_[0] =~ s!(url\(\s*(["']?))([^)]+?)\2!$1 . relative_url($url,"$3") . $2!ige;
}

sub relative_url {
    my( $curr, $url ) = @_;
    my $res = URI::WithBase->new( $url, $curr );
    # Copy parts that URI::WithBase doesn't...
    for my $part (qw( scheme host port )) {
        if( ! defined $res->$part and defined $curr->$part ) {
            $res->$part( $curr->$part );
        };
    };
    $res = $res->rel();
    
    #warn "$curr / $url => $res";
    
    $res
};

=head1 CAVEATS

=head2 Does handle the C<< <base> >> tag in a specific way

If the HTML contains a C<< <base> >> tag, it's C<< href= >> attribute
is used as the page URL relative to which links are rewritten.

=head2 Uses regular expressions to do all parsing

Instead of parsing the HTML into a DOM, performing the modifications and
then writing the DOM back out, this module uses a simplicistic regular
expressions to recognize C<< href= >> and C<< src= >> attributes and
to rewrite them.

=head1 REPOSITORY

The public repository of this module is 
L<https://github.com/Corion/html-rebase>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=HTML-Rebase>
or via mail to L<html-rebase-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2015-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;