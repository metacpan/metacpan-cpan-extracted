package HTML::WikiConverter::WebApp;
use base 'CGI::Application';

use HTML::WikiConverter;
use XML::Writer;
use Tie::IxHash;
use Encode;

=head1 NAME

HTML::WikiConverter::WebApp - Web interface to HTML::WikiConverter

=head1 SYNOPSIS

Inside the index.cgi instance script (which is included with this
distribution):

  #!/usr/bin/perl
  use HTML::WikiConverter::WebApp;
  
  my %config = (
    template_path => '/path/to/web/templates',
  );

  HTML::WikiConverter::WebApp->new( PARAMS => \%config )->run;

=head1 DESCRIPTION

This module provides a L<CGI::Application> interface to
L<HTML::WikiConverter> and all installed dialect modules.

Refer to the INSTALL file for installation instructions.

=head1 QUERY PARAMETERS

This application accepts a number of query parameters to control its
behavior. The most basic is the run mode parameter, C<m>. This
application can be in one of two run modes: C<"new"> or C<"convert">.
(These correspond to the C<new_page()> and C<output_page()> methods,
respectively.) C<"new"> causes a new page to be displayed, while
C<"convert"> displays the results of html-to-wiki conversion.

Additional query parameters can be passed independent of run mode:

=over 4

=item * source_type

One of C<"raw_html">, C<"from_uri">, or C<"sample_html">.

=item * dialect

Any installed dialect, eg C<"MediaWiki">.

=item * base_uri

Base URL to be used for converting relative links to absolute ones.

=item * wiki_uri

Template for wiki URLs. When scanning the HTML source, if a URL (as in
an C<a href> or C<img src> attribute value) is found matching this
template, it will be treated to a link to a wiki
article/image. Consult L<HTML::WikiConverter/ATTRIBUTES> for more
information.

Note that this is a bit less flexible than using the C<wiki_uri>
attribute directly in L<HTML::WikiConverter>. That attribute allows
multiple templates, allows coderefs, and regexps, etc. This option
only accepts a single scalar representing a very simple wiki URL
template.

=item * show_parsed_html

If enabled, an additional textarea containing the parsed HTML will be
displayed.

=item * escape_entities

If enabled, unsafe HTML entities ("E<lt>", "E<gt>", and "E<amp>") will
be encoded using L<HTML::Entities>.

=item * format

One of C<"html"> or C<"xml">. Determines the type of output displayed
by this application.

=back

=head1 METHODS

=head2 setup

Sets up the app for L<CGI::Application>.

=cut

sub setup {
  my $self = shift;
  $self->error_mode( 'display_error' );
  $self->tmpl_path( $self->param('template_path') );
  $self->mode_param( 'm' );
  $self->start_mode( 'new' );
  $self->run_modes(
    new     => 'new_page',
    convert => 'output_page',
  );
  $self->header_add( -charset => 'utf-8' );
}

=head2 new_page

Corresponds to the C<new> run mode. Returns a blank form. If arguments
are available on the CGI query string, these are used as default
values for the form fields.

=cut

sub new_page {
  my $self = shift;
  my $q = $self->query;

  my $tmpl = $self->load_template( 'main.html' );
  $tmpl->param(
    $self->_default_template_params,
  );

  $tmpl->output;
}

=head2 output_page

Corresponds to the C<convert> run mode. Same as C<new_page()> but returns
the wiki markup for the provided html as well.

=cut

sub output_page {
  my $self = shift;
  my $q = $self->query;

  my $source_type = $q->param('source_type') or die "need source_type";
  my $dialect = $q->param('dialect') or die "need dialect";

  die "unknown source_type '$source_type'" unless $self->_known_source_type( $q->param('source_type') );

  my %source;
  SWITCH: {
    %source = ( html => $q->param('html') ),   last if $source_type eq 'raw_html';
    %source = ( html => $self->_sample_html ), last if $source_type eq 'sample_html';
    %source = ( uri  => $q->param('uri') ),    last if $source_type eq 'from_uri';
  };

  die sprintf( "no %s was provided", (keys %source)[0] ) unless ( (values %source)[0] );

  my $wc = new HTML::WikiConverter(
    dialect         => $dialect,
    base_uri        => $q->param('base_uri'),
    wiki_uri        => $q->param('wiki_uri'),
    escape_entities => $q->param('escape_entities'),
  );

  my $wiki = $wc->html2wiki( %source );
  my $parsed_html = $wc->parsed_html;

  $source{html} = decode( $wc->encoding, $source{html} ) if $source{html};
  $wiki         = decode( $wc->encoding, $wiki )         if $wiki;

  my $format = $q->param('format') || 'html';
  if( $format eq 'xml' ) {
    tie( my %default_template_params, 'Tie::IxHash' );
    %default_template_params = $self->_default_template_params;

    my %ignore_params = map { $_ => 1 } qw(
      dialects
      error
      raw_html
      from_uri
      sample_html
      uri
    );

    my $xml = '';
    my $writer = new XML::Writer( OUTPUT => \$xml, DATA_MODE => 1, DATA_INDENT => 2 );
    $writer->xmlDecl('utf-8');
    $writer->startTag( 'wikitool', application => 'html2wiki' );
    
    $writer->startTag( 'query' );
      $writer->startTag( 'source', type => $source_type );
      $writer->characters( (values %source)[0] );
      $writer->endTag();

      $writer->startTag( 'options' );
      while( my( $f, $v ) = each %default_template_params ) {
        next if $ignore_params{$f};
        $writer->startTag( $f );
        $writer->characters( $v );
        $writer->endTag();
      }
      $writer->endTag();
    $writer->endTag();

    $writer->startTag( 'response' );
      if( $q->param('show_parsed_html') ) {
        $writer->startTag( 'parsed_html' );
        $writer->characters( $parsed_html );
        $writer->endTag();
      }

      $writer->startTag( 'wiki_markup' );
      $writer->characters( $wiki );
      $writer->endTag();

      $writer->endTag();
    $writer->endTag();

    $self->header_add( -type => 'text/xml' );
    return $xml;
  }

  my $temp = $self->load_template( 'main.html' );
  $temp->param(
    $self->_default_template_params,
    uri         => $source{uri},
    html        => $source{html},
    parsed_html => $parsed_html,
    wiki_markup => $wiki,
  );

  return $temp->output;
}

sub _default_template_params {
  my $self = shift;
  my $q = $self->query;

  my $source_type = $self->_known_source_type( $q->param('source_type') ) ? $q->param('source_type') : 'raw_html';

  return (
    dialect => $q->param('dialect') || '',
    $source_type => 1,

    uri => $q->param('uri') || '',

    base_uri => $q->param('base_uri') || '',
    wiki_uri => $q->param('wiki_uri') || '',

    show_parsed_html => $q->param('show_parsed_html') || 0,
    escape_entities  => $q->param('escape_entities') || 0,

    dialects => $self->_dialects,
    error => '',
  );
}

my %known_source_types = map { $_ => 1 } qw(
  from_uri
  raw_html
  sample_html
);

sub _known_source_type {
  my( $self, $type ) = @_;
  return exists $known_source_types{$type};
}

sub _dialects {
  my $self = shift;
  my $q = $self->query;

  my $selected_dialect = $q->param('dialect') || '';

  my @dialects;
  my %seen;
  foreach my $dialect ( HTML::WikiConverter->available_dialects ) {
    next if $seen{$dialect}++;
    push @dialects, { dialect => $dialect, selected => ( $selected_dialect eq $dialect ) };
  }

  return \@dialects;
}

=head2 load_template

Loads the specified L<HTML::Template> template.

=cut

sub load_template {
  my( $self, $file ) = @_;
  return $self->load_tmpl( $file, die_on_bad_params => 1, loop_context_vars => 1, cache => 1 );
}

sub _sample_html {
  my $self = shift;
  return $self->load_template( 'sample_html.html' )->output;
}

=head2 display_error

Error-catching method called by L<CGI::Application> if a run mode
fails for any reason. Displays a basic form with a styled error
message up top.

=cut

sub display_error {
  my( $self, $error ) = @_;

  if( $error =~ /Dialect .* could not be loaded/ ) {
    $error = sprintf q{The "%s" dialect either doesn't exist or has not been installed.}, $self->query->param('dialect');
  }

  $error =~ s{(.*?) at \S+ line \d+\.}{$1.};
  $error = ucfirst $error;

  my $tmpl = $self->load_template( 'main.html' );
  $tmpl->param(
    $self->_default_template_params,
    error => $error
  );

  return $tmpl->output;
}

=head1 AUTHOR

David J. Iberri, C<< <diberri at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-html-wikiconverter
at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTML-WikiConverter>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc HTML::WikiConverter::WebApp

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTML-WikiConverter-WebApp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTML-WikiConverter-WebApp>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-WikiConverter-WebApp>

=item * Search CPAN

L<http://search.cpan.org/dist/HTML-WikiConverter-WebApp>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) David J. Iberri, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
