package JiftyTest::View::Page;
our $VERSION = '0.07';


use base Jifty::View::Declare::Page;
use Jifty::View::Declare::Helpers;

# use base qw(Jifty::Plugin::ViewDeclarePage::Page);
# This plugins is used for replace Jifty::View::Declare::Page
# try it later

use Class::Trigger;

sub render_page {
  my $self = shift;
  html {
    head {
      title { "title myself" }
    };
    body {
      div { attr { id => 'hd' }
        h3 {"Hello JiftyTest"};
        hr {};
        div { attr { class => "menu" }
          # show "/menu";
          # hyperlink( label => " [show post] ", url => "/post/show", class => "menu-item" );
          hyperlink( label => " [list post] ", url => "/post/list", class => "menu-item" );
          hyperlink( label => " [new post] ",  url => "/post/new" , class => "menu-item" );
          hyperlink( label => " [foo bar] ",  url => "/foo/bar" , class => "menu-item" );
          hyperlink( label => " [function test] ",  url => "/function/test" , class => "menu-item" );
        }
      }
      div { attr { id => "bd" }
        hr {};
        # no warnings qw( redefine once );
        local *is::title = $self->mk_title_handler();
        # $self->render_pre_content_hook();
        $self->content_code->();
        $self->render_header();
        # $self->render_jifty_page_detritus();
      }
      div { attr { id => 'ft' }
        hr {};
        span {"footer"};
      }
    };
  };
}


1;
