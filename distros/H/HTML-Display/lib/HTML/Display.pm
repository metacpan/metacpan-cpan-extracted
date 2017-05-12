package HTML::Display;
use strict;
use HTML::TokeParser;
use Carp qw( croak );
use vars qw( $VERSION );
$VERSION='0.40';

=head1 NAME

HTML::Display - display HTML locally in a browser

=head1 SYNOPSIS

=for example
  my $html = "foo\n";
  %HTML::Display::os_default = ();
  delete $ENV{PERL_HTML_DISPLAY_CLASS};

=for example begin

  use strict;
  use HTML::Display;

  # guess the best value from $ENV{PERL_HTML_DISPLAY_CLASS}
  # or $ENV{PERL_HTML_DISPLAY_COMMAND}
  # or the operating system, in that order
  my $browser = HTML::Display->new();
  warn "# Displaying HTML using " . ref $browser;
  my $location = "http://www.google.com/";
  $browser->display(html => $html, location => $location);

  # Or, for a one-off job :
  display("<html><body><h1>Hello world!</h1></body></html>");

=for example end

=for example_testing
  is($::_STDOUT_,"foo\n<html><body><h1>Hello world!</h1></body></html>");

=head1 DESCRIPTION

This module abstracts the task of displaying HTML to the user. The
displaying is done by launching a browser and navigating it to either
a temporary file with the HTML stored in it, or, if possible, by
pushing the HTML directly into the browser window.

The module tries to automagically select the "correct" browser, but
if it dosen't find a good browser, you can modify the behaviour by
setting some environment variables :

  PERL_HTML_DISPLAY_CLASS

If HTML::Display already provides a class for the browser you want to
use, setting C<PERL_HTML_DISPLAY_CLASS> to the name of the class will
make HTML::Display use that class instead of what it detects.

  PERL_HTML_DISPLAY_COMMAND

If there is no specialized class yet, but your browser can be controlled
via the command line, then setting C<PERL_HTML_DISPLAY_COMMAND> to the
string to navigate to the URL will make HTML::Display use a C<system()>
call to the string. A C<%s> in the value will be replaced with the name
of the temporary file containing the HTML to display.

=cut

use vars qw( @ISA @EXPORT %os_default );
require Exporter;
@ISA='Exporter';

@EXPORT = qw( display );

=head2 %HTML::Display::os_default

The hash C<%HTML::Display::os_default> contains pairs of class names
for the different operating systems and routines that test whether
this script is currently running under it. If you you want to dynamically
add a new class or replace a class (or the rule), modify C<%os_default> :

=for example begin

  # Install class for MagicOS
  $HTML::Display::os_default{"HTML::Display::MagicOS"}
    = sub { $^O =~ qr/magic/i };

=for example end

=cut

%os_default = (
  "HTML::Display::Win32::IE"    => sub {
  																	 my $have_ole;
  																	 eval {
  																		 require Win32::OLE;
  																		 Win32::OLE->import();
  																		 $have_ole = 1;
  																	 };
  																	 $have_ole and $^O =~ qr/mswin32/i
  																 },
  "HTML::Display::Debian" 		=> sub { -x "/usr/bin/x-www-browser" },
  "HTML::Display::OSX"				=> sub { $^O =~ qr/darwin/i },
);

=head2 __PACKAGE__->new %ARGS

=cut

sub new {
  my $class = shift;
  my (%args) = @_;

  # First see whether the programmer or user specified a class
  my $best_class = delete $args{class} || $ENV{PERL_HTML_DISPLAY_CLASS};

  # Now, did they specify a command?
  unless ($best_class) {
    my $command = delete $args{browsercmd} || $ENV{PERL_HTML_DISPLAY_COMMAND};
    if ($command) {
      $best_class = "HTML::Display::TempFile";
      $args{browsercmd} = $command;
      @_ = %args;
    };
  };

  unless ($best_class) {
    for my $class (sort keys %os_default) {
      $best_class = $class
        if $os_default{$class}->();
    };
  };
  $best_class ||= "HTML::Display::Dump";

  { no strict 'refs';
    undef $@;    
    eval "use $best_class;"
      unless ( @{"${best_class}::ISA"}
              or defined *{"${best_class}::new"}{CODE} 
              or defined *{"${best_class}::AUTOLOAD"}{CODE});
    croak "While trying to load $best_class: $@" if $@;
  };
  return $best_class->new(@_);
};

=head2 $browser-E<gt>display( %ARGS )

Will display the HTML. The following arguments are valid :

  base     => Base to which all relative links will be resolved
  html     => Scalar containing the HTML to be displayed
  file     => Scalar containing the name of the file to be displayed
  						This file will possibly be copied into a temporary file!

  location    (synonymous to base)

If only one argument is passed, then it is taken as if

  html => $_[0]

was passed.

=cut

sub display {
  my %args;
  if (scalar @_ == 1) {
    %args = ( html => @_ )
  } else {
    %args = @_
  };
  HTML::Display->new()->display( %args );
};

=head1 EXPORTS

The subroutine C<display> is exported by default

=head1 COMMAND LINE USAGE

Display some HTML to the user :

  perl -MHTML::Display -e "display '<html><body><h1>Hello world</body></html>'"

Display a web page to the user :

  perl -MLWP::Simple -MHTML::Display -e "display get 'http://www.google.com'"

Display the same page with the images also working :

  perl -MLWP::Simple -MHTML::Display -e "display html => get('http://www.google.com'),
                                                 location => 'http://www.google.com'"

=head1 AUTHOR

Copyright (c) 2004-2007 Max Maischein C<< <corion@cpan.org> >>

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut


1;
