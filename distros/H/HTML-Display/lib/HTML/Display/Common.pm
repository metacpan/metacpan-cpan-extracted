package HTML::Display::Common;

=head1 NAME

HTML::Display::Common - routines common to all HTML::Display subclasses

=cut

use strict;
use HTML::TokeParser;
use URI::URL;
use vars qw($VERSION);
$VERSION='0.40';
use Carp qw( croak );

=head2 __PACKAGE__-E<gt>new %ARGS

Creates a new object as a blessed hash. The passed arguments are stored within
the hash. If you need to do other things in your constructor, remember to call
this constructor as well :

=for example
  no warnings 'redefine';
  *HTML::Display::WhizBang::display_html = sub {};

=for example begin

  package HTML::Display::WhizBang;
  use parent 'HTML::Display::Common';

  sub new {
    my ($class) = shift;
    my %args = @_;
    my $self = $class->SUPER::new(%args);

    # do stuff

    $self;
  };

=for example end

=for example_testing
  package main;
  use HTML::Display;
  my $browser = HTML::Display->new( class => "HTML::Display::WhizBang");
  isa_ok($browser,"HTML::Display::Common");

=cut

sub new {
  my ($class) = shift;
  #croak "Odd number" if @_ % 2;
  my $self = { @_ };
  bless $self,$class;
  $self;
};

=head2 $display->display %ARGS

This is the routine used to display the HTML to the user. It takes the
following parameters :

  html     => SCALAR containing the HTML
  file     => SCALAR containing the filename of the file to be displayed
  base     => optional base url for the HTML, so that relative links still work

  location    (synonymous to base)

=head3 Basic usage :

=for example
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };

=for example begin

  my $html = "<html><body><h1>Hello world!</h1></body></html>";
  my $browser = HTML::Display->new();
  $browser->display( html => $html );

=for example end

=for example_testing
  isa_ok($browser, "HTML::Display::Dump","The browser");
  is( $main::_STDOUT_,"<html><body><h1>Hello world!</h1></body></html>","HTML gets output");

=head3 Location parameter :

If you fetch a page from a remote site but still want to display
it to the user, the C<location> parameter comes in very handy :

=for example
  no warnings 'redefine';
  *HTML::Display::new = sub {
    my $class = shift;
    require HTML::Display::Dump;
    return HTML::Display::Dump->new(@_);
  };

=for example begin

  my $html = '<html><body><img src="/images/hp0.gif"></body></html>';
  my $browser = HTML::Display->new();

  # This will display part of the Google logo
  $browser->display( html => $html, base => 'http://www.google.com' );

=for example end

=for example_testing
  isa_ok($browser, "HTML::Display::Dump","The browser");
  is( $main::_STDOUT_,
  	'<html><head><base href="http://www.google.com/" /></head><body><img src="/images/hp0.gif"></body></html>',
  	"HTML gets output");
  $main::_STDOUT_ = "";
  $browser->display( html => $html, location => 'http://www.google.com' );
  is( $main::_STDOUT_,
  	'<html><head><base href="http://www.google.com/" /></head><body><img src="/images/hp0.gif"></body></html>',
  	"HTML gets output");

=cut

sub display {
  my ($self) = shift;
  my %args;
  if (scalar @_ == 1) {
    %args = ( html => $_[0] );
  } else {
    %args = @_;
  };

  if ($args{file}) {
    my $filename = delete $args{file};
    local $/;
    local *FILE;
    open FILE, "<", $filename
      or croak "Couldn't read $filename";
    $args{html} = <FILE>;
  };

  $args{base} = delete $args{location}
    if (! exists $args{base} and exists $args{location});

  my $new_html;
  if (exists $args{base}) {
    # trim to directory create BASE HREF
    # We are carefull to not trim if we just have http://domain.com
    my $location = URI::URL->new( $args{base} );
    my $path = $location->path;
    $path =~ s%(?<!/)/[^/]*$%/%;
    $location = sprintf "%s://%s%s", $location->scheme, $location->authority , $path;

    require HTML::TokeParser::Simple;
    my $p = HTML::TokeParser::Simple->new(\$args{html}) || die 'could not create HTML::TokeParser::Simple object';
    my ($has_head,$has_base);
    while (my $token = $p->get_token) {
      if ( $token->is_start_tag('head') ) {
        $has_head++;
      } elsif ( $token->is_start_tag('base')) {
        $has_base++;
        last;
      };
    };

    # restart parsing
    $p = HTML::TokeParser::Simple->new(\$args{html}) || die 'could not create HTML::TokeParser::Simple object';
    while (my $token = $p->get_token) {
      if ( $token->is_start_tag('html') and not $has_head) {
        $new_html .= $token->as_is . qq{<head><base href="$location" /></head>};
      } elsif ( $token->is_start_tag('head') and not $has_base) {
        # handle an empty <head /> :
        if ($token->as_is =~ m!^<\s*head\s*/>$!i) {
          $new_html .= qq{<head><base href="$location" /></head>}
        } else {
          $new_html .= $token->as_is . qq{<base href="$location" />};
        };
      } elsif ( $token->is_start_tag('base') ) {
        # If they already have a <base href>, give up
        if ($token->return_attr->{href}) {
          $new_html = $args{html};
          last;
        } else {
          $token->set_attr('href',$location);
          $new_html .= $token->as_is;
        };
      } else {
        $new_html .= $token->as_is;
      }
    };
  } else {
    $new_html = $args{html};
  };

  $self->display_html($new_html);
};

=head1 AUTHOR

Copyright (c) 2004-2013 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut


1;
