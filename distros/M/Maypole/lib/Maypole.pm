package Maypole;
use base qw(Class::Accessor::Fast Class::Data::Inheritable);
use UNIVERSAL::require;
use strict;
use warnings;
use Data::Dumper;
use Maypole::Config;
use Maypole::Constants;
use Maypole::Headers;
use URI();
use URI::QueryParam;
use NEXT;
use File::MMagic::XS qw(:compat);

our $VERSION = '2.13';
our $mmagic = File::MMagic::XS->new();

# proposed privacy conventions:
# - no leading underscore     - public to custom application code and plugins
# - single leading underscore - private to the main Maypole stack - *not*
#     including plugins
# - double leading underscore - private to the current package

=head1 NAME

Maypole - MVC web application framework

=head1 SYNOPSIS

The canonical example used in the Maypole documentation is the beer database:

    package BeerDB;
    use strict;
    use warnings; 
    
    # choose a frontend, initialise the config object, and load a plugin
    use Maypole::Application qw/Relationship/;

    # set everything up
    __PACKAGE__->setup("dbi:SQLite:t/beerdb.db");
    
    # get the empty config object created by Maypole::Application
    my $config = __PACKAGE__->config;
    
    # basic settings
    $config->uri_base("http://localhost/beerdb");
    $config->template_root("/path/to/templates");
    $config->rows_per_page(10);
    $config->display_tables([qw/beer brewery pub style/]);

    # table relationships
    $config->relationships([
        "a brewery produces beers",
        "a style defines beers",
        "a pub has beers on handpumps",
        ]);
        
    # validation
    BeerDB::Brewery->untaint_columns( printable => [qw/name notes url/] );
    BeerDB::Pub->untaint_columns( printable => [qw/name notes url/] );
    BeerDB::Style->untaint_columns( printable => [qw/name notes/] );
    BeerDB::Beer->untaint_columns(
        printable => [qw/abv name price notes/],
        integer => [qw/style brewery score/],
        date => [ qw/date/],
    );

    # note : set up model before calling this method
    BeerDB::Beer->required_columns([qw/name/]); 

    1;    

=head1 DESCRIPTION

This documents the Maypole request object. See the L<Maypole::Manual>, for a
detailed guide to using Maypole.

Maypole is a Perl web application framework similar to Java's struts. It is 
essentially completely abstracted, and so doesn't know anything about
how to talk to the outside world.

To use it, you need to create a driver package which represents your entire
application. This is the C<BeerDB> package used as an example in the manual.

This needs to first use L<Maypole::Application> which will make your package
inherit from the appropriate platform driver such as C<Apache::MVC> or
C<CGI::Maypole>. Then, the driver calls C<setup>. This sets up the model classes
and configures your application. The default model class for Maypole uses
L<Class::DBI> to map a database to classes, but this can be changed by altering
configuration (B<before> calling setup.)


=head1 DOCUMENTATION AND SUPPORT

Note that some details in some of these resources may be out of date.

=over 4

=item The Maypole Manual

The primary documentation is the Maypole manual. This lives in the 
C<Maypole::Manual> pod documents included with the distribution. 

=item Embedded POD

Individual packages within the distribution contain (more or less) detailed
reference documentation for their API.

=item Mailing lists

There are two mailing lists - maypole-devel and maypole-users - see
http://maypole.perl.org/?MailingList

=item The Maypole Wiki

The Maypole wiki provides a useful store of extra documentation -
http://maypole.perl.org

In particular, there's a FAQ (http://maypole.perl.org/?FAQ) and a cookbook
(http://maypole.perl.org/?Cookbook). Again, certain information on these pages
may be out of date.

=item Web applications with Maypole

A tutorial written by Simon Cozens for YAPC::EU 2005 -
http://www.aarontrevena.co.uk/opensource/maypole/maypole-tutorial.pdf [228KB].

=item A Database-Driven Web Application in 18 Lines of Code

By Paul Barry, published in Linux Journal, March 2005.

http://www.linuxjournal.com/article/7937

"From zero to Web-based database application in eight easy steps".

Maypole won a 2005 Linux Journal Editor's Choice Award
(http://www.linuxjournal.com/article/8293) after featuring in this article. 

=item Build Web apps with Maypole

By Simon Cozens, on IBM's DeveloperWorks website, May 2004.

http://www-128.ibm.com/developerworks/linux/library/l-maypole/

=item Rapid Web Application Deployment with Maypole

By Simon Cozens, on O'Reilly's Perl website, April 2004.

http://www.perl.com/pub/a/2004/04/15/maypole.html

=item Authentication

Some notes written by Simon Cozens. A little bit out of date, but still 
very useful: http://www.aarontrevena.co.uk/opensource/maypole/authentication.html

=item CheatSheet

There's a refcard for the Maypole (and Class::DBI) APIs on the wiki -
http://maypole.perl.org/?CheatSheet. Probably a little out of date now - it's a
wiki, so feel free to fix any errors!

=item Plugins and add-ons

There are a large and growing number of plugins and other add-on modules
available on CPAN - http://search.cpan.org/search?query=maypole&mode=module

=item del.icio.us

You can find a range of useful Maypole links, particularly to several thoughtful
blog entries, starting here: http://del.icio.us/search/?all=maypole

=item CPAN ratings

There are a couple of short reviews here:
http://cpanratings.perl.org/dist/Maypole

=back

=cut

__PACKAGE__->mk_classdata($_) for qw( config init_done view_object model_classes_loaded);

__PACKAGE__->mk_accessors(
    qw( params query objects model_class template_args output path
        args action template error document_encoding content_type table
        headers_in headers_out stash status parent build_form_elements
        user session)
);

__PACKAGE__->config( Maypole::Config->new({additional => { }, request_options => { }, view_options => { },}) );

__PACKAGE__->init_done(0);

__PACKAGE__->model_classes_loaded(0);

=head1 HOOKABLE METHODS

As a framework, Maypole provides a number of B<hooks> - methods that are
intended to be overridden. Some of these methods come with useful default
behaviour, others do nothing by default. Hooks include:

    Class methods
    -------------
    debug 
    setup 
    setup_model 
    load_model_subclass
    init
    
    Instance methods
    ----------------
    start_request_hook
    is_model_applicable
    get_session
    authenticate
    exception
    additional_data
    preprocess_path

=head1 CLASS METHODS

=over 4

=item debug

    sub My::App::debug {1}

Returns the debugging flag. Override this in your application class to
enable/disable debugging.

You can also set the C<debug> flag via L<Maypole::Application>.

Some packages respond to higher debug levels, try increasing it to 2 or 3.


=cut

sub debug { 0 }

=item config

Returns the L<Maypole::Config> object

=item setup

   My::App->setup($data_source, $user, $password, \%attr);

Initialise the Maypole application and plugins and model classes.
Your application should call this B<after> setting up configuration data via
L<"config">.

It calls the hook  C<setup_model> to setup the model. The %attr hash contains
options and arguments used to set up the model. See the particular model's
documentation. However here is the most usage of setup where
Maypole::Model::CDBI is the base class.

 My::App->setup($data_source, $user, $password,
       {  options => {  # These are DB connection options
               AutoCommit => 0,
               RaiseError => 1,
               ...
          },
          # These are Class::DBI::Loader arguments.
          relationships  => 1,
          ...
       }
 );

Also, see  L<Maypole::Manual::Plugins>.

=cut


sub setup
{
    my $class = shift;
    
    $class->setup_model(@_);	
}

=item setup_model

Called by C<setup>. This method builds the Maypole model hierarchy. 

A likely target for over-riding, if you need to build a customised model.

This method also ensures any code in custom model classes is loaded, so you
don't need to load them in the driver.

=cut

sub setup_model {
  my $class = shift;
  $class = ref $class if ref $class;
  my $config = $class->config;
  $config->model || $config->model('Maypole::Model::CDBI');
  $config->model->require or die sprintf
    "Couldn't load the model class %s: %s", $config->model, $@;

  # among other things, this populates $config->classes
  $config->model->setup_database($config, $class, @_);

  $config->model->add_model_superclass($config);

  # Load custom model code, if it exists - nb this must happen after the
  # adding the model superclass, to allow code attributes to work, but before adopt(),
  # in case adopt() calls overridden methods on $subclass
  foreach my $subclass ( @{ $config->classes } ) {
    $class->load_model_subclass($subclass) unless ($class->model_classes_loaded());
    $config->model->adopt($subclass) if $config->model->can("adopt");
  }

}

=item load_model_subclass($subclass)

This method is called from C<setup_model()>. It attempts to load the
C<$subclass> package, if one exists. So if you make a customized C<BeerDB::Beer>
package, you don't need to explicitly load it. 

If automatic loading causes problems, Override load_model_subclass in your driver.

sub load_model_subclass {};

Or perhaps during development, if you don't want to load up custom classes, you 
can override this method and load them manually. 

=cut

sub load_model_subclass {
  my ($class, $subclass) = @_;

  my $config = $class->config;

  # Load any external files for the model base class or subclasses
  # (e.g. BeerDB/DBI.pm or BeerDB/Beer.pm) based on code borrowed from
  # Maypole::Plugin::Loader and Class::DBI.
  if ( $subclass->require ) {
    warn "Loaded external module for '$subclass'\n" if $class->debug > 1;
  } else {
    (my $filename = $subclass) =~ s!::!/!g;
    die "Loading '$subclass' failed: $@\n"
      unless $@ =~ /Can\'t locate \Q$filename\E\.pm/;
    warn "No external module for '$subclass'"
      if $class->debug > 1;
  }
}

=item init

Loads the view class and instantiates the view object.

You should not call this directly, but you may wish to override this to add
application-specific initialisation - see L<Maypole::Manual::Plugins>.

=cut

sub init 
{
    my $class  = shift;
    my $config = $class->config;
    $config->view || $config->view("Maypole::View::TT");
    $config->view->require;
    die "Couldn't load the view class " . $config->view . ": $@" if $@;
    $config->display_tables
      || $config->display_tables( $class->config->tables );
    $class->view_object( $class->config->view->new );
    $class->init_done(1);
}

=item new

Constructs a very minimal new Maypole request object.

=cut

sub new
{
    my ($class) = @_;
    my $self = bless {
        config        => $class->config,
    }, $class;

    $self->stash({});
    $self->params({});
    $self->query({});
    $self->template_args({});
    $self->args([]);
    $self->objects([]);
    return $self;
}

=item view_object

Get/set the Maypole::View object

=back

=head1 INSTANCE METHODS

=head2 Workflow

=over 4

=item handler

This method sets up the class if it's not done yet, sets some defaults and
leaves the dirty work to C<handler_guts>.

=cut

# handler() has a method attribute so that mod_perl will invoke
# BeerDB->handler() as a method rather than a plain function
# BeerDB::handler() and so this inherited implementation will be
# found. See e.g. "Practical mod_perl" by Bekman & Cholet for
# more information <http://modperlbook.org/html/ch25_01.html>
sub handler : method  {
  # See Maypole::Workflow before trying to understand this.
  my ($class, $req) = @_;
    
  $class->init unless $class->init_done;

  my $self = $class->new;
    
  # initialise the request
  $self->headers_out(Maypole::Headers->new);
  $self->get_request($req);

  $self->parse_location;

  # hook useful for declining static requests e.g. images, or perhaps for 
  # sanitizing request parameters
  $self->status(Maypole::Constants::OK()); # set the default
  $self->__call_hook('start_request_hook');
  return $self->status unless $self->status == Maypole::Constants::OK();
  die "status undefined after start_request_hook()" unless defined
    $self->status;

  my $session = $self->get_session;
  $self->session($self->{session} || $session);
  my $user = $self->get_user;
  $self->user($self->{user} || $user);

  my $status = $self->handler_guts;
  return $status unless $status == OK;
  # TODO: require send_output to return a status code
  $self->send_output;
  return $status;
}

=item component

  Run Maypole sub-requests as a component of the request

  [% request.component("/beer/view_as_component/20") %]

  Allows you to integrate the results of a Maypole request into an existing
request. You'll need to set up actions and templates
which return fragments of HTML rather than entire pages, but once you've
done that, you can use the C<component> method of the Maypole request object
to call those actions. You may pass a query string in the usual URL style.

You should not fully qualify the Maypole URLs.

Note: any HTTP POST or URL parameters passed to the parent are not passed to the
component sub-request, only what is included in the url passed as an argument
to the method

=cut

sub component {
    my ( $r, $path ) = @_;
    my $self = bless { parent => $r, config => $r->{config}, } , ref $r;
    $self->stash({});
    $self->params({});
    $self->query({});
    $self->template_args({});
    $self->args([]);
    $self->objects([]);

    $self->session($self->get_session);
    $self->user($self->get_user);

    my $url = URI->new($path);
    $self->{path} = $url->path;
    $self->parse_path;
    $self->params( $url->query_form_hash );
    $self->handler_guts;
    return $self->output;
}

sub get_template_root {
    my $self = shift;
    my $r    = shift;
    return $r->parent->get_template_root if $r->{parent};
    return $self->NEXT::DISTINCT::get_template_root( $r, @_ );
}

sub view_object {
    my $self = shift;
    my $r    = shift;
    return $r->parent->view_object if $r->{parent};
    return $self->NEXT::DISTINCT::view_object( $r, @_ );
}

# Instead of making plugin authors use the NEXT::DISTINCT hoopla to ensure other 
# plugins also get to call the hook, we can cycle through the application's 
# @ISA and call them all here. Doesn't work for setup() though, because it's 
# too ingrained in the stack. We could add a run_setup() method, but we'd break 
# lots of existing code.
sub __call_hook
{
    my ($self, $hook) = @_;
    
    my @plugins;
    {
        my $class = ref($self);
        no strict 'refs';
        @plugins = @{"$class\::ISA"};
    }
    
    # this is either a custom method in the driver, or the method in the 1st 
    # plugin, or the 'null' method in the frontend (i.e. inherited from 
    # Maypole.pm) - we need to be careful to only call it once
    my $first_hook = $self->can($hook);
    $self->$first_hook;  
    
    my %seen = ( $first_hook => 1 );

    # @plugins includes the frontend
    foreach my $plugin (@plugins)
    {
        next unless my $plugin_hook = $plugin->can($hook);
        next if $seen{$plugin_hook}++;
        $self->$plugin_hook;
    }
}

=item handler_guts

This is the main request handling method and calls various methods to handle the
request/response and defines the workflow within Maypole.

=cut

# The root of all evil
sub handler_guts {
  my ($self) = @_;
  $self->build_form_elements(1) unless (defined ($self->config->build_form_elements) && $self->config->build_form_elements == 0);
  $self->__load_request_model;

  my $applicable = $self->is_model_applicable == OK;

  my $status;

  # handle authentication
  eval { $status = $self->call_authenticate };
  if ( my $error = $@ ) {
    $status = $self->call_exception($error, "authentication");
    if ( $status != OK ) {
      $self->warn("caught authenticate error: $error");
      return $self->debug ? 
	$self->view_object->error($self, $error) : ERROR;
    }
  }
  if ( $self->debug and $status != OK and $status != DECLINED ) {
    $self->view_object->error( $self,
			       "Got unexpected status $status from calling authentication" );
  }

  return $status unless $status == OK;

  # We run additional_data for every request
  $self->additional_data;

  # process request with model if applicable and template not set.
  if ($applicable) {
    unless ($self->{template}) {
      eval { $self->model_class->process($self) };
      if ( my $error = $@ ) {
	$status = $self->call_exception($error, "model");
	if ( $status != OK ) {
	  $self->warn("caught model error: $error");
	  return $self->debug ? 
	    $self->view_object->error($self, $error) : ERROR;
	}
      }
    }
  } else {
    $self->__setup_plain_template;
  }

  # less frequent path - perhaps output has been set to an error message
  if ($self->output) {
    $self->{content_type}      ||= $self->__get_mime_type();
    $self->{document_encoding} ||= "utf-8";
    return OK;
  }

  # normal path - no output has been generated yet
  my $processed_view_ok = $self->__call_process_view;

  $self->{content_type}      ||= $self->__get_mime_type();
  $self->{document_encoding} ||= "utf-8";

  return $processed_view_ok;
}

my %filetypes = (
		 'js' => 'text/javascript',
		 'css' => 'text/css',
		 'htm' => 'text/html',
		 'html' => 'text/html',
		);

sub __get_mime_type {
  my $self = shift;
  my $type = 'text/html';
  if ($self->path =~ m/.*\.(\w{2,4})$/) {
    $type = $filetypes{$1};
  } else {
    my $output = $self->output;
    if (defined $output) {
      $type = $mmagic->checktype_contents($output);
    }
  }
  return $type;
}

sub __load_request_model
{
    my ($self) = @_;
	# We may get a made up class from class_of
    my $mclass = $self->config->model->class_of($self, $self->table);
    if ( eval {$mclass->isa('Maypole::Model::Base')} ) {
        $self->model_class( $mclass );
    }
    elsif ($self->debug > 1) {
      $self->warn("***Warning:  No $mclass class appropriate for model. @_");
    }
}


# is_applicable() returned false, so set up a plain template. Model processing 
# will be skipped, but need to remove the model anyway so the template can't 
# access it. 
sub __setup_plain_template
{
    my ($self) = @_;

    # It's just a plain template
    $self->build_form_elements(0);
    $self->model_class(undef);

    unless ($self->template) {
      # FIXME: this is likely to be redundant and is definately causing problems.
      my $path = $self->path;
      $path =~ s{/$}{};    # De-absolutify
      $self->path($path);
      $self->template($self->path);
    }
}

# The model has been processed or skipped (if is_applicable returned false), 
# any exceptions have been handled, and there's no content in $self->output
sub __call_process_view {
  my ($self) = @_;

  my $status = eval { $self->view_object->process($self) };

  my $error = $@ || $self->{error};

  if ( $error ) {
    $status = $self->call_exception($error, "view");

    if ( $status != OK ) {
      warn "caught view error: $error" if $self->debug;
      return $self->debug ? 
	$self->view_object->error($self, $error) : ERROR;
    }
  }

  return $status;
}

=item warn

$r->warn('its all gone pete tong');

Warn must be implemented by the backend, i.e. Apache::MVC
and warn to stderr or appropriate logfile.

You can also over-ride this in your Maypole driver, should you
want to use something like Log::Log4perl instead.

=cut

sub warn { }

=item build_form_elements

$r->build_form_elements(0);

Specify (in an action) whether to build HTML form elements and populate
the cgi element of classmetadata in the view.

You can set this globally using the accessor of the same name in Maypole::Config,
this method allows you to over-ride that setting per action.

=cut

=item get_request

You should only need to define this method if you are writing a new
Maypole backend. It should return something that looks like an Apache
or CGI request object, it defaults to blank.

=cut

sub get_request { }

=item parse_location

Turns the backend request (e.g. Apache::MVC, Maypole, CGI) into a Maypole
request. It does this by setting the C<path>, and invoking C<parse_path> and
C<parse_args>.

You should only need to define this method if you are writing a new Maypole
backend.

=cut

sub parse_location 
{
    die "parse_location is a virtual method. Do not use Maypole directly; " . 
    		"use Apache::MVC or similar";
}

=item start_request_hook

This is called immediately after setting up the basic request. The default
method does nothing. 

The value of C<< $r->status >> is set to C<OK> before this hook is run. Your 
implementation can change the status code, or leave it alone. 

After this hook has run, Maypole will check the value of C<status>. For any
value other than C<OK>, Maypole returns the C<status> immediately. 

This is useful for filtering out requests for static files, e.g. images, which
should not be processed by Maypole or by the templating engine:

    sub start_request_hook
    {
        my ($r) = @_;
	
        $r->status(DECLINED) if $r->path =~ /\.jpg$/;
    }
    
Multiple plugins, and the driver, can define this hook - Maypole will call all
of them. You should check for and probably not change any non-OK C<status>
value:

    package Maypole::Plugin::MyApp::SkipFavicon;
    
    sub start_request_hook
    {
        my ($r) = @_;
        
        # check if a previous plugin has already DECLINED this request
        # - probably unnecessary in this example, but you get the idea
        return unless $r->status == OK;
        
        # then do our stuff
        $r->status(DECLINED) if $r->path =~ /favicon\.ico/;
    }        
     
=cut

sub start_request_hook { }

=item is_applicable

B<This method is deprecated> as of version 2.11. If you have overridden it,
please override C<is_model_applicable> instead, and change the return type
from a Maypole:Constant to a true/false value.

Returns a Maypole::Constant to indicate whether the request is valid.

=cut

sub is_applicable { return shift->is_model_applicable(@_); }

=item is_model_applicable

Returns true or false to indicate whether the request is valid.

The default implementation checks that C<< $r->table >> is publicly
accessible and that the model class is configured to handle the
C<< $r->action >>.

=cut

sub is_model_applicable {
    my ($self) = @_;

    # Establish which tables should be processed by the model
    my $config = $self->config;
    
    $config->ok_tables || $config->ok_tables( $config->display_tables );
    
    $config->ok_tables( { map { $_ => 1 } @{ $config->ok_tables } } )
        if ref $config->ok_tables eq "ARRAY";
        
    my $ok_tables = $config->ok_tables;
      
    # Does this request concern a table to be processed by the model?
    my $table = $self->table;
    
    my $ok = 0;
    
    if (exists $ok_tables->{$table}) 
    {
        $ok = 1;
    } 

    if (not $ok) 
    {
        $self->warn ("We don't have that table ($table).\n"
            . "Available tables are: "
            . join( ",", keys %$ok_tables ))
                if $self->debug and not $ok_tables->{$table};
                
        return DECLINED;
    }
    
    # Is the action public?
    my $action = $self->action;
    return OK if $self->model_class->is_public($action);
    
    $self->warn("The action '$action' is not applicable to the table '$table'")
         if $self->debug;
    
    return DECLINED;
}

=item get_session

Called immediately after C<start_request_hook()>.

This method should return a session, which will be stored in the request's
C<session> attribute.

The default method is empty. 

=cut

sub get_session { }

=item get_user

Called immediately after C<get_session>.

This method should return a user, which will be stored in the request's C<user>
attribute.

The default method is empty.

=cut

sub get_user {}

=item call_authenticate

This method first checks if the relevant model class
can authenticate the user, or falls back to the default
authenticate method of your Maypole application.

=cut

sub call_authenticate 
{
    my ($self) = @_;

    # Check if we have a model class with an authenticate() to delegate to
    return $self->model_class->authenticate($self) 
        if $self->model_class and $self->model_class->can('authenticate');
    
    # Interface consistency is a Good Thing - 
    # the invocant and the argument may one day be different things 
    # (i.e. controller and request), like they are when authenticate() 
    # is called on a model class (i.e. model and request)
    return $self->authenticate($self);   
}

=item authenticate

Returns a Maypole::Constant to indicate whether the user is authenticated for
the Maypole request.

The default implementation returns C<OK>

=cut

sub authenticate { return OK }


=item call_exception

This model is called to catch exceptions, first after authenticate, then after
processing the model class, and finally to check for exceptions from the view
class.

This method first checks if the relevant model class
can handle exceptions the user, or falls back to the default
exception method of your Maypole application.

=cut

sub call_exception 
{
    my ($self, $error, $when) = @_;

    # Check if we have a model class with an exception() to delegate to
    if ( $self->model_class && $self->model_class->can('exception') )
    {
        my $status = $self->model_class->exception( $self, $error, $when );
        return $status if $status == OK;
    }
    
    return $self->exception($error, $when);
}


=item exception

This method is called if any exceptions are raised during the authentication or
model/view processing. It should accept the exception as a parameter and return
a Maypole::Constant to indicate whether the request should continue to be
processed.

=cut

sub exception { 
    my ($self, $error, $when) = @_;
    if (ref $self->view_object && $self->view_object->can("report_error") and $self->debug) {
        $self->view_object->report_error($self, $error, $when);
        return OK;
    }
    return ERROR;
}

=item additional_data

Called before the model processes the request, this method gives you a chance to
do some processing for each request, for example, manipulating C<template_args>.

=cut

sub additional_data { }

=item send_output

Sends the output and additional headers to the user.

=cut

sub send_output {
    die "send_output is a virtual method. Do not use Maypole directly; use Apache::MVC or similar";
}


=back

=head2 Path processing and manipulation

=over 4

=item path

Returns the request path

=item parse_path

Parses the request path and sets the C<args>, C<action> and C<table>
properties. Calls C<preprocess_path> before parsing path and setting properties.

=cut

sub parse_path {
    my ($self) = @_;

    # Previous versions unconditionally set table, action and args to whatever 
    # was in @pi (or else to defaults, if @pi is empty).
    # Adding preprocess_path(), and then setting table, action and args 
    # conditionally, broke lots of tests, hence this:
    $self->$_(undef) for qw/action table args/;
    $self->preprocess_path;

    # use frontpage template for frontpage
    unless ($self->path && $self->path ne '/') {
      $self->path('frontpage');
    }

    my @pi = grep {length} split '/', $self->path;

    $self->table  || $self->table(shift @pi);
    $self->action || $self->action( shift @pi or 'index' );
    $self->args   || $self->args(\@pi);
}

=item preprocess_path

Sometimes when you don't want to rewrite or over-ride parse_path but
want to rewrite urls or extract data from them before it is parsed,
the preprocess_path/location methods allow you to munge paths and urls
before maypole maps them to actions, classes, etc.

This method is called after parse_location has populated the request
information and before parse_path has populated the model and action
information, and is passed the request object.

You can set action, args or table in this method and parse_path will
then leave those values in place or populate them based on the current
value of the path attribute if they are not present.

=cut

sub preprocess_path { };

=item preprocess_location

This method is called at the start of parse_location, after the headers in, and allows you
to rewrite the url used by maypole, or dynamically set configuration
like the base_uri based on the hostname or path.

=cut

sub preprocess_location { };

=item make_path( %args or \%args or @args )

This is the counterpart to C<parse_path>. It generates a path to use
in links, form actions etc. To implement your own path scheme, just override
this method and C<parse_path>.

    %args = ( table      => $table,
              action     => $action,        
              additional => $additional,    # optional - generally an object ID
              );
              
    \%args = as above, but a ref
    
    @args = ( $table, $action, $additional );   # $additional is optional

C<id> can be used as an alternative key to C<additional>.

C<$additional> can be a string, an arrayref, or a hashref. An arrayref is
expanded into extra path elements, whereas a hashref is translated into a query
string. 

=cut


sub make_path
{
    my $r = shift;
    
    my %args;
    
    if (@_ == 1 and ref $_[0] and ref $_[0] eq 'HASH')
    {
        %args = %{$_[0]};
    }
    elsif ( @_ > 1 and @_ < 4 )
    {
        $args{table}      = shift;
        $args{action}     = shift;
        $args{additional} = shift;
    }
    else
    {
        %args = @_;
    }
    
    do { die "no $_" unless $args{$_} } for qw( table action );    

    my $additional = $args{additional} || $args{id};
    
    my @add = ();
    
    if ($additional)
    {
        # if $additional is a href, make_uri() will transform it into a query
        @add = (ref $additional eq 'ARRAY') ? @$additional : ($additional);
    }    
    
    my $uri = $r->make_uri($args{table}, $args{action}, @add);
    
    return $uri->as_string;
}



=item make_uri( @segments )

Make a L<URI> object given table, action etc. Automatically adds
the C<uri_base>. 

If the final element in C<@segments> is a hash ref, C<make_uri> will render it
as a query string.

=cut

sub make_uri
{
    my ($r, @segments) = @_;

    my $query = (ref $segments[-1] eq 'HASH') ? pop(@segments) : undef;
    
    my $base = $r->config->uri_base; 
    $base =~ s|/$||;
    
    my $uri = URI->new($base);
    $uri->path_segments($uri->path_segments, grep {length} @segments);
    
    my $abs_uri = $uri->abs('/');
    $abs_uri->query_form($query) if $query;
    return $abs_uri;
}

=item parse_args

Turns post data and query string paramaters into a hash of C<params>.

You should only need to define this method if you are writing a new Maypole
backend.

=cut 

sub parse_args
{
    die "parse_args() is a virtual method. Do not use Maypole directly; ".
            "use Apache::MVC or similar";
}

=item get_template_root

Implementation-specific path to template root.

You should only need to define this method if you are writing a new Maypole
backend. Otherwise, see L<Maypole::Config/"template_root">

=cut

=back

=head2 Request properties

=over 4

=item model_class

Returns the perl package name that will serve as the model for the
request. It corresponds to the request C<table> attribute.


=item objects

Get/set a list of model objects. The objects will be accessible in the view
templates.

If the first item in C<$self-E<gt>args> can be C<retrieve()>d by the model
class, it will be removed from C<args> and the retrieved object will be added to
the C<objects> list. See L<Maypole::Model> for more information.


=item object

Alias to get/set the first/only model object. The object will be accessible
in the view templates.

When used to set the object, will overwrite the request objects
with a single object.

=cut

sub object {
  my ($r,$object) = @_;
  $r->objects([$object]) if ($object);
  return undef unless $r->objects();
  return $r->objects->[0];
}

=item template_args

    $self->template_args->{foo} = 'bar';

Get/set a hash of template variables.

Maypole reserved words for template variables will over-ride values in template_variables.

Reserved words are : r, request, object, objects, base, config and errors, as well as the
current class or object name.

=item stash

A place to put custom application data. Not used by Maypole itself.

=item template

Get/set the template to be used by the view. By default, it returns
C<$self-E<gt>action>


=item error

Get/set a request error

=item output

Get/set the response output. This is usually populated by the view class. You
can skip view processing by setting the C<output>.

=item table

The table part of the Maypole request path

=item action

The action part of the Maypole request path

=item args

A list of remaining parts of the request path after table and action
have been
removed

=item headers_in

A L<Maypole::Headers> object containing HTTP headers for the request

=item headers_out

A L<HTTP::Headers> object that contains HTTP headers for the output

=item document_encoding

Get/set the output encoding. Default: utf-8.

=item content_type

Get/set the output content type. Default: text/html

=item get_protocol

Returns the protocol the request was made with, i.e. https

=cut

sub get_protocol {
  die "get_protocol is a virtual method. Do not use Maypole directly; use Apache::MVC or similar";
}

=back

=head2 Request parameters

The source of the parameters may vary depending on the Maypole backend, but they
are usually populated from request query string and POST data.

Maypole supplies several approaches for accessing the request parameters. Note
that the current implementation (via a hashref) of C<query> and C<params> is
likely to change in a future version of Maypole. So avoid direct access to these
hashrefs:

    $r->{params}->{foo}      # bad
    $r->params->{foo}        # better

    $r->{query}->{foo}       # bad
    $r->query->{foo}         # better

    $r->param('foo')         # best

=over 4

=item param

An accessor (get or set) for request parameters. It behaves similarly to
CGI::param() for accessing CGI parameters, i.e.

    $r->param                   # returns list of keys
    $r->param($key)             # returns value for $key
    $r->param($key => $value)   # returns old value, sets to new value

=cut

sub param 
{ 
    my ($self, $key) = (shift, shift);
    
    return keys %{$self->params} unless defined $key;
    
    return unless exists $self->params->{$key};
    
    my $val = $self->params->{$key};
    
    if (@_)
    {
        my $new_val = shift;
	$self->params->{$key} = $new_val;
    }
    
    return (ref $val eq 'ARRAY') ? @$val : ($val) if wantarray;
        
    return (ref $val eq 'ARRAY') ? $val->[0] : $val;
}


=item params

Returns a hashref of request parameters. 

B<Note:> Where muliple values of a parameter were supplied, the C<params> value
will be an array reference.

=item query

Alias for C<params>.

=back

=head3 Utility methods

=over 4

=item redirect_request

Sets output headers to redirect based on the arguments provided

Accepts either a single argument of the full url to redirect to, or a hash of
named parameters :

$r->redirect_request('http://www.example.com/path');

or

$r->redirect_request(protocol=>'https', domain=>'www.example.com', path=>'/path/file?arguments', status=>'302', url=>'..');

The named parameters are protocol, domain, path, status and url

Only 1 named parameter is required but other than url, they can be combined as
required and current values (from the request) will be used in place of any
missing arguments. The url argument must be a full url including protocol and
can only be combined with status.

=cut

sub redirect_request {
  die "redirect_request is a virtual method. Do not use Maypole directly; use Apache::MVC or similar";
}

# =item redirect_internal_request
#
# =cut
#
# sub redirect_internal_request {
#
# }


=item make_random_id

returns a unique id for this request can be used to prevent or detect repeat
submissions.

=cut

# Session and Repeat Submission Handling
sub make_random_id {
    use Maypole::Session;
    return Maypole::Session::generate_unique_id();
}

=back

=head1 SEQUENCE DIAGRAMS

See L<Maypole::Manual::Workflow> for a detailed discussion of the sequence of 
calls during processing of a request. This is a brief summary:

    INITIALIZATION
                               Model e.g.
         BeerDB           Maypole::Model::CDBI
           |                        |
   setup   |                        |
 o-------->||                       |
           || setup_model           |     setup_database() creates
           ||------+                |      a subclass of the Model
           |||<----+                |        for each table
           |||                      |                |
           |||   setup_database     |                |
           |||--------------------->|| 'create'      *
           |||                      ||----------> $subclass
           |||                      |                  |
           ||| load_model_subclass  |                  |
 foreach   |||------+  ($subclass)  |                  |
 $subclass ||||<----+               |    require       |
           ||||--------------------------------------->|
           |||                      |                  |
           |||   adopt($subclass)   |                  |
           |||--------------------->||                 |
           |                        |                  |
           |                        |                  |
           |-----+ init             |                  |
           ||<---+                  |                  |
           ||                       |     new          |     view_object: e.g.
           ||---------------------------------------------> Maypole::View::TT
           |                        |                  |          |
           |                        |                  |          |
           |                        |                  |          |
           |                        |                  |          |
           |                        |                  |          |
           


    HANDLING A REQUEST


          BeerDB                                Model  $subclass  view_object
            |                                      |       |         |
    handler |                                      |       |         |
  o-------->| new                                  |       |         |
            |-----> r:BeerDB                       |       |         |
            |         |                            |       |         |
            |         |                            |       |         |
            |         ||                           |       |         |
            |         ||-----+ parse_location      |       |         |
            |         |||<---+                     |       |         |
            |         ||                           |       |         |
            |         ||-----+ start_request_hook  |       |         |
            |         |||<---+                     |       |         |
            |         ||                           |       |         |
            |         ||-----+ get_session         |       |         |
            |         |||<---+                     |       |         |
            |         ||                           |       |         |
            |         ||-----+ get_user            |       |         |
            |         |||<---+                     |       |         |
            |         ||                           |       |         |
            |         ||-----+ handler_guts        |       |         |
            |         |||<---+                     |       |         |
            |         |||     class_of($table)     |       |         |
            |         |||------------------------->||      |         |
            |         |||       $subclass          ||      |         |
            |         |||<-------------------------||      |         |
            |         |||                          |       |         |
            |         |||-----+ is_model_applicable|       |         |
            |         ||||<---+                    |       |         |
            |         |||                          |       |         |
            |         |||-----+ call_authenticate  |       |         |
            |         ||||<---+                    |       |         |
            |         |||                          |       |         |
            |         |||-----+ additional_data    |       |         |
            |         ||||<---+                    |       |         |
            |         |||             process      |       |         |
            |         |||--------------------------------->||  fetch_objects
            |         |||                          |       ||-----+  |
            |         |||                          |       |||<---+  |
            |         |||                          |       ||        |
            |         |||                          |       ||   $action
            |         |||                          |       ||-----+  |
            |         |||                          |       |||<---+  |            
            |         |||         process          |       |         |
            |         |||------------------------------------------->|| template
            |         |||                          |       |         ||-----+
            |         |||                          |       |         |||<---+
            |         |||                          |       |         |
            |         ||     send_output           |       |         |
            |         ||-----+                     |       |         |
            |         |||<---+                     |       |         |
   $status  |         ||                           |       |         |
   <------------------||                           |       |         |
            |         |                            |       |         |
            |         X                            |       |         |           
            |                                      |       |         |
            |                                      |       |         |
            |                                      |       |         |
           
           

=head1 SEE ALSO

There's more documentation, examples, and information on our mailing lists
at the Maypole web site:

L<http://maypole.perl.org/>

L<Maypole::Application>, L<Apache::MVC>, L<CGI::Maypole>.

=head1 AUTHOR

Maypole is currently maintained by Aaron Trevena.

=head1 AUTHOR EMERITUS

Simon Cozens, C<simon#cpan.org>

Simon Flack maintained Maypole from 2.05 to 2.09

Sebastian Riedel, C<sri#oook.de> maintained Maypole from 1.99_01 to 2.04

=head1 THANKS TO

Sebastian Riedel, Danijel Milicevic, Dave Slack, Jesse Sheidlower, Jody Belka,
Marcus Ramberg, Mickael Joanne, Randal Schwartz, Simon Flack, Steve Simms,
Veljko Vidovic and all the others who've helped.

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;

__END__

 =item register_cleanup($coderef)

Analogous to L<Apache>'s C<register_cleanup>. If an Apache request object is
available, this call simply redispatches there. If not, the cleanup is
registered in the Maypole request, and executed when the request is
C<DESTROY>ed.

This method is only useful in persistent environments, where you need to ensure
that some code runs when the request finishes, no matter how it finishes (e.g.
after an unexpected error). 

 =cut

{
    my @_cleanups;

    sub register_cleanup
    {
        my ($self, $cleanup) = @_;
        
        die "register_cleanup() is an instance method, not a class method" 
            unless ref $self;
        die "Cleanup must be a coderef" unless ref($cleanup) eq 'CODE';
        
        if ($self->can('ar') && $self->ar)
        {
            $self->ar->register_cleanup($cleanup);
        }
        else
        {
            push @_cleanups, $cleanup;
        }
    }

    sub DESTROY
    {
        my ($self) = @_;
        
        while (my $cleanup = shift @_cleanups)
        {
            eval { $cleanup->() };
            if ($@)
            {
                warn "Error during request cleanup: $@";
            }
        }        
    }    
}
    
