package HTML::Display::Win32::IE;
use strict;
use Carp qw(carp);
use parent 'HTML::Display::Win32::OLE';
use vars qw($VERSION);
$VERSION='0.40';

=head1 NAME

HTML::Display::Win32::IE - use IE to display HTML pages

=head1 SYNOPSIS

=for example begin

  my $browser = HTML::Display->new(
    class => 'HTML::Display::Dump',
  );
  $browser->display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

This implementation avoids temporary files by using OLE to push
the HTML directly into the browser.

=cut

sub new {
  my ($class) = @_;
  my $self = $class->SUPER::new( app_string => "InternetExplorer.Application" );
  $self;
};

sub setup {
  my ($self,$control) = @_;
  #warn "Setting up browser";
  $control->{'Visible'} = 1;
  $control->Navigate('about:blank');
};

sub display_html {
  my ($self,$html) = @_;
  if ($html) {
    my $browser = $self->control;
    my $document = $browser->{Document};
    $document->open("text/html","replace");
    $document->write($html);
  } else {
    carp "No HTML given" unless $html;
  };
};

=head1 AUTHOR

Copyright (c) 2004-2007 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut

1;
