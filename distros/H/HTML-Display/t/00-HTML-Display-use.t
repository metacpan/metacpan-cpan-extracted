use strict;
use Test::More tests => 16;
use vars qw( $display $captured_html );

{
  package HTML::Display::Capture;
  use parent 'HTML::Display::Common';
  sub display_html { $::captured_html = $_[1]; };
};

sub display_ok {
  my ($html,$base,$expected,$name) = @_;
  undef $captured_html;
  $display->display( html => $html, location => $base);
  is($captured_html,$expected,$name);
};

SKIP: {
  use_ok("HTML::Display");

  $display = HTML::Display->new();
  isa_ok($display,"HTML::Display::Common","Default class");

  $display = HTML::Display->new( class => 'HTML::Display::Capture' );
  isa_ok($display,"HTML::Display::Common");

  # Now check our published API :
  for my $meth (qw( display )) {
    can_ok($display,$meth);
  };

  # Now check the handling of base tags :
  display_ok("<html><head></head><p></p></html>","http://example.com",'<html><head><base href="http://example.com/" /></head><p></p></html>',"Empty head");
  display_ok("<html><head></head><p></p></html>","http://example.com",'<html><head><base href="http://example.com/" /></head><p></p></html>',"Empty head without trailing slash");
  display_ok('<html><head><base href="http://example.net/" /></head><p></p></html>',"http://example.com",'<html><head><base href="http://example.net/" /></head><p></p></html>',"Existing head");
  display_ok('<html><head><base href="http://example.net/" /></head><p></p></html>',"http://example.com",'<html><head><base href="http://example.net/" /></head><p></p></html>',"Existing head");
  display_ok('<html><head><base href="http://example.net/" /></head><p></p></html>',"http://example.com/file.html",'<html><head><base href="http://example.net/" /></head><p></p></html>',"Existing head 2");
  display_ok('<html><head></head><p></p></html>',"http://example.com/file.html",'<html><head><base href="http://example.com/" /></head><p></p></html>',"Filename in base");
  display_ok('<html><head></head><p></p></html>',"http://example.com:666/file.html",'<html><head><base href="http://example.com:666/" /></head><p></p></html>',"Port");
  display_ok('<html><head></head><p></p></html>','http://super:secret@example.com/file.html','<html><head><base href="http://super:secret@example.com/" /></head><p></p></html>',"Basic authentification");
  display_ok('<html><head><base target="_blank" /></head><p></p></html>','http://example.com/','<html><head><base target="_blank" href="http://example.com/" /></head><p></p></html>',"'target' attribute");
  display_ok('<html><p></p></html>','http://example.com/','<html><head><base href="http://example.com/" /></head><p></p></html>',"No <head> tag");
  display_ok('<html><head><title>foo</title></head><p></p></html>','http://example.com/','<html><head><base href="http://example.com/" /><title>foo</title></head><p></p></html>',"No <base> tag");
  display_ok('<html><head /><p></p></html>','http://example.com/','<html><head><base href="http://example.com/" /></head><p></p></html>',"Single <head /> tag");
};
