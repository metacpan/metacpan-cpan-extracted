package JiftyTest::View;
our $VERSION = '0.07';

use strict;
use warnings;
use Jifty::View::Declare -base;
use Jifty::View::Declare::Helpers;

use JiftyX::ModelHelpers;

use Jifty::View::Declare::CRUD;

use Class::Inspector;

# use JiftyTest::View::Post;
# alias JiftyTest::View::Post under "/post";
# Jifty::View::Declare::CRUD->mount_view("Post",);

# alias Jifty::View::Declare::CRUD under "/p", {
#   object_type => "Post",
# };


template "/" => page {
  
   # redirect("/foo/bar");
   div {
    "application root"
   }

  span {
    Dumper( Class::Inspector->functions("JiftyTest::View") );
  }

   #div { 
   #  render_region(
   #    name => "foo-bar",
   #    path => "/foo/bar",
   #  );
   #};
};

template "/partial/sidebar" => sub {
  ul {
    li { "hello world" };
  }
};

template "/function/test" => page {
  h5 {"function test page"}
  div {
    hyperlink( label => "foo bar", url => "/foo/bar" );
  }
  p {
    my $p = Post(id => 1);
    span { $p->id }
    span { $p->title }
    span { $p->declarer }
  }
  div { attr { class => "partial" }
    show "/partial/sidebar" 
  }
};

template "/404.html" => sub {
  html { 
    body { "404 Not Found" }
  }
};

template "/foo/bar" => page {
  h5 { "Foo Bar Page" };
  # p { "this page is for application testing" }
  # hyperlink( label => "function test page", url => "/function/test" );
  hr {};

  use Data::Dumper;
  use JiftyTest::View::Post;
  use JiftyTest::View;

  div {
    span {Dumper(Class::Inspector->functions("JiftyTest::View"))}
    hr {};
    span { "admin mode => " . Jifty->config->stash->{framework}->{AdminMode} }; br{};
    span { "current template => " . current_template() }; br {};
    pre { "current user => " . Dumper( Jifty->web->current_user ) }; br {};
    span { "current user id => " . Jifty->web->current_user->id }; br {};
    my $u = JiftyTest::Model::User->new(current_user => Jifty->web->current_user);
    $u->load(1);
    pre { "user id:1 => " . Dumper $u }; br {};
  } hr {};

  div {
    Dumper(Class::Inspector->functions("JiftyTest::Dispatcher"));
  } hr {};

  div {
    "param: " . get("param");
  }; hr {};

  div {
    Dumper(Class::Inspector->functions("JiftyTest::Model::User"));
  } hr {};


  div {
    attr { class => "take-action" }
    div {"do nothing action"}
    my $action = new_action( class => "DoNothing" );
    form {
      render_action $action;
      form_submit( lable => "Do Nothing" );
    };
  };

};

template "/post/list" => page {
  div {
    my $posts = JiftyTest::Model::PostCollection->new;
    $posts->unlimit;

    my $page = get("page") || 1;
    $posts->set_page_info(
      current_page => $page,
      per_page => 100,
    );

    div { "current page => " . current_template() }
    br {};

    div {
      while ( my $p = $posts->next ) {
        span { $p->id    }
        span { $p->title }
        span { $p->content  }
        span { hyperlink( label => "show", url => "/post/show/".$p->id ) }
        br {};
      }
    }

    div {

        if ($posts->pager->last_page > 1) {
          p { "Page $page of " . $posts->pager->last_page }
        }

        if ($posts->pager->previous_page) {
          hyperlink(
            label => 'Previous Page',
            onclick => {
              args => {
                page => $posts->pager->previous_page,
              },
            },
          );
        }

        if ($posts->pager->next_page) {
          hyperlink(
            label => 'Next Page',
            onclick => {
              args => {
                page => $posts->pager->next_page,
              },
            },
          );
        }

    }

  }
};

template "/user/show" => page {
  my $u = JiftyTest::Model::User->new;
  $u->load(get("id"));
  div {
    span { $u->id }
    span { $u->account }
    span { $u->email }
    span { $u->privilege }
  }
};

template "/post/show" => page {
  my $p = JiftyTest::Model::Post->new;
  $p->load(get("id"));

  div {
    span { $p->id    }
    span { $p->title }
    span { $p->body  }
  }
};

template "/post/new" => page {
  div {
    my $action = new_action( class => "CreatePost" );
    form {
      form_next_page( url => "/post/create" );
      render_action $action;
      form_submit( label => "Create Post" );
    };
  }
};

template "/post/create" => page {
  my $action = new_action( class => "CreatePost" );
  redirect("/post/list");
};

1;
