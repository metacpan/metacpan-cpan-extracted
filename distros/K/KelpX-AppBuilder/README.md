# NAME

KelpX::AppBuilder - Create re-usable apps with Kelp

# SYNOPSIS

KelpX::AppBuilder makes it trivial to reuse your entire route map and views in an entirely new Kelp application. You create a base app, which can still be run normally, and from there you can start a new project and reuse everything from your base app without duplicating things.

# USAGE

## Create a base application

This launches your main application, allowing you to attach other ones onto it

```perl
package BaseApp;

use KelpX::AppBuilder;

sub build {
    my ($self) = @_;
    my $routes = $self->routes;

    # The only thing we need to do is tell KelpX::AppBuilder what
    # apps we want to load. Their routes will be added onto BaseApps.

    $r->kelpx_appbuilder->apps(
        'TestApp',
        'TestApp2'
    );

    # Then load the main ones as normal

    $r->add('/' => BaseApp::Controller::Root->can('index'));
    $r->add('/login' => BaseApp::Controller::Auth->can('login'));
    $r->add('/accounts/manage/:id' => {
        to      => BaseApp::Controller::Accounts->can('manage'),
        bridge  => 1
    });
    $r->add('/accounts/manage/:id/view', BaseApp::Controller::Accounts->can('view'));
}

1;
```

## Creating an app for your base

We'll call our new app 'TestApp' (original, eh?).
All your app really needs to provide is a function called `maps`. This should 
return a hash reference of your routes.
Don't forget to include the absolute path to your controllers (ie: Using the + symbol)

```perl
package TestApp;

use KelpX::AppBuilder;

sub maps {
    {
        '/testapp/welcome', '+TestApp::Controller::Root::welcome'
    }
}

1;
```

And that's all there is to it.

## Using templates from apps

One thing you're probably going to want to do is use something like Template::Toolkit to process 
your views in apps that aren't the base. Fortunately `KelpX::AppBuilder::Utils` will deploy 
`module_dir` from [File::ShareDir](https://metacpan.org/pod/File::ShareDir) for you, so in your controllers something like this could happen:

```perl
package TestApp::Controller::Root;

use KelpX::AppBuilder::Utils;

# create some way to access the view path globally
# so you don't have to keep writing it
sub view_path { module_dir('TestApp') . '/views/' }

sub index {
    my ($self) = @_;
    $self->template(view_path() . 'index.tt');
}
```

So now when the index method is called from TestApp, it'll search `lib/auto/TestApp/views` for its 
templates.

This is probably your best option for now, as KelpX::AppBuilder does not have a safe way to load app 
configuration just yet (working on it!).

# PLEASE NOTE

This module is still a work in progress, so I would advise against using KelpX::AppBuilder in a production environment. I'm still looking at ways to make KelpX::AppBuilder more user friendly, but unfortunately reusing an application is not a simple process :-)

# AUTHOR

Brad Haywood <brad@geeksware.com>

# LICENSE

You may distribute this code under the same terms as Perl itself.
