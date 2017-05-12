package MasonX::Interp::WithCallbacks;

use strict;
use HTML::Mason qw(1.23);
use HTML::Mason::Interp;
use HTML::Mason::Exceptions ();
use Params::CallbackRequest;

use vars qw($VERSION @ISA);
@ISA = qw(HTML::Mason::Interp);
$VERSION = '1.19';

Params::Validate::validation_options
  ( on_fail => sub { HTML::Mason::Exception::Params->throw( join '', @_ ) } );


use HTML::Mason::MethodMaker(
    read_only  => [qw(cb_request)],
    read_write => [qw(comp_path)],
);

# We'll use this code reference to eval arguments passed in via httpd.conf
# PerlSetVar directives.
my $eval_directive = { convert => sub {
    return 1 if ref $_[0]->[0];
    for (@{$_[0]}) { $_ = eval $_ }
    return 1;
}};

__PACKAGE__->valid_params
  ( default_priority =>
    { type      => Params::Validate::SCALAR,
      parse     => 'string',
      default   => 5,
      descr     => 'Default callback priority'
    },

    default_pkg_key =>
    { type      => Params::Validate::SCALAR,
      parse     => 'string',
      default   => 'DEFAULT',
      descr     => 'Default package key'
    },

    callbacks =>
    { type      => Params::Validate::ARRAYREF,
      parse     => 'list',
      optional  => 1,
      callbacks => $eval_directive,
      descr     => 'Callback specifications'
    },

    pre_callbacks =>
    { type      => Params::Validate::ARRAYREF,
      parse     => 'list',
      optional  => 1,
      callbacks => $eval_directive,
      descr     => 'Callbacks to be executed before argument callbacks'
    },

    post_callbacks =>
    { type      => Params::Validate::ARRAYREF,
      parse     => 'list',
      optional  => 1,
      callbacks => $eval_directive,
      descr     => 'Callbacks to be executed after argument callbacks'
    },

    cb_classes =>
    { type      => Params::Validate::ARRAYREF | Params::Validate::SCALAR,
      parse     => 'list',
      optional  => 1,
      descr     => 'List of calback classes from which to load callbacks'
    },

    ignore_nulls =>
    { type      => Params::Validate::BOOLEAN,
      parse     => 'boolean',
      default   => 0,
      descr     => 'Execute callbacks with null values'
    },

    cb_exception_handler =>
    { type      => Params::Validate::CODEREF,
      parse     => 'code',
      optional  => 1,
      descr     => 'Callback execution exception handler'
    },
  );


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    # This causes everything to be validated twice, but it shouldn't matter
    # much, since interp objects won't be created very often.
    my $exh = delete $self->{cb_exception_handler};
    $self->{cb_request} = Params::CallbackRequest->new
      ( leave_notes => 1,
        ($exh ? (exception_handler => $exh) : ()),
       map { $self->{$_} ? ($_ => delete $self->{$_}) : () }
        keys %{ __PACKAGE__->valid_params }
    );
    $self;
}

sub make_request {
    my ($self, %p) = @_;
    # We have to grab the parameters and copy them into a hash.
    my %params = @{$p{args}};
    $self->{comp_path} = $p{comp};

    # Grab the apache request object, if it exists.
    my $apache_req = $p{apache_req}
      || $self->delayed_object_params('request', 'apache_req')
      || $self->delayed_object_params('request', 'cgi_request');

    # Execute the callbacks.
    my $ret =  $self->{cb_request}->request(
        \%params,
        requester => $self,
        $apache_req ? ( apache_req => $apache_req ) : (),
    );

    # Abort the request if that's what the callbacks want.
    unless (ref $ret) {
        $self->{cb_request}->clear_notes;
        HTML::Mason::Exception::Abort->throw(
            error         => 'Callback->abort was called',
            aborted_value => $ret,
        );
    }

    # Copy the parameters back -- too much copying!
    $p{args} = [%params];
    $p{comp} = $self->{comp_path};

    # Get the request, copy the notes, and continue.
    my $req = $self->SUPER::make_request(%p);
    # Should I use the same reference?
    %{$req->notes} = %{$self->{cb_request}->notes};
    return $req;
}

# We override this method in order to clear out all the callback notes
# at the end of the Mason request.
sub purge_code_cache {
    my $self = shift;
    $self->{cb_request}->clear_notes;
    $self->SUPER::purge_code_cache;
}

1;
__END__

=head1 NAME

MasonX::Interp::WithCallbacks - Mason callback support via Params::CallbackRequest.

=head1 SYNOPSIS

In your Mason component:

  % if (exists $ARGS{answer}) {
  <p><b>Answer: <% $ARGS{answer} %></b></p>
  % } else {
  <form>
    <p>Enter an epoch time: <input type="text" name="epoch_time" /><br />
      <input type="submit" name="myCallbacker|calc_time_cb" value="Calculate" />
    </p>
  </form>
  % }

In F<handler.pl>:

  use strict;
  use MasonX::Interp::WithCallbacks;

  sub calc_time {
      my $cb = shift;
      my $params = $cb->params;
      my $val = $cb->value;
      $params->{answer} = localtime($val || time);
  }

  my $ah = HTML::Mason::ApacheHandler->new
    ( interp_class => 'MasonX::Interp::WithCallbacks',
      callbacks => [ { cb_key  => 'calc_time',
                       pkg_key => 'myCallbacker',
                       cb      => \&calc_time } ]
    );

  sub handler {
      my $r = shift;
      $ah->handle_request($r);
  }

Or, in a subclass of Params::Callback:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'myCallbacker' );

  sub calc_time : Callback {
      my $self = shift;
      my $params = $self->params;
      my $val = $cb->value;
      $params->{answer} = localtime($val || time);
  }

And then, in F<handler.pl>:

  # Load order is important here!
  use MyApp::CallbackHandler;
  use MasonX::Interp::WithCallbacks;

  my $ah = HTML::Mason::ApacheHandler->new
    ( interp_class => 'MasonX::Interp::WithCallbacks',
      cb_classes => [qw(myCallbacker)] );

  sub handler {
      my $r = shift;
      $ah->handle_request($r);
  }

Or, just use MasonX::Interp::WithCallbacks directly:

  use MyApp::CallbackHandler;
  use MasonX::Interp::WithCallbacks;
  my $interp = MasonX::Interp::WithCallbacks->new
    ( cb_classes => [qw(myCallbacker)] );
  $interp->exec($comp, %args);


=begin comment

=head1 ABSTRACT

MasonX::Interp::WithCallbacks subclasses HTML::Mason::Interp in order to
provide functional and object-oriented callbacks via Params::CallbackRequest.
Callbacks are executed at the beginning of a request, just before Mason
creates and executes the request component stack.

=end comment

=head1 DESCRIPTION

MasonX::Interp::WithCallbacks subclasses HTML::Mason::Interp in order to
provide a Mason callback system built on
L<Params::CallbackRequest|Params::CallbackRequest>. Callbacks may be either
code references provided to the C<new()> constructor, or methods defined in
subclasses of Params::Callback. Callbacks are triggered either for every
request or by specially named keys in the Mason request arguments, and all
callbacks are executed at the beginning of a request, just before Mason
creates and executes the request component stack.

This module brings support for a sort of plugin architecture based on
Params::CallbackRequest to Mason. Mason then executes code before executing
any components. This approach allows you to carry out logical processing of
data submitted from a form, to affect the contents of the Mason request
arguments (and thus the C<%ARGS> hash in components), and even to redirect or
abort the request before Mason handles it.

Much of the documentation here is based on that in
L<Params::CallbackRequest|Params::CallbackRequest>, although it prefers using
HTML form fields for its examples rather than Perl hashes. But see the
Params::CallbackRequest documentation for the latest on its interface.

=head1 JUSTIFICATION

Why would you want to do this? Well, there are a number of reasons. Some I can
think of offhand include:

=over 4

=item Stricter separation of logic from presentation

Most application logic handled in Mason components takes place in
C<< <%init> >> blocks, often in the same component as presentation logic. By
moving the application logic into Perl modules and then directing Mason to
execute that code as callbacks, you obviously benefit from a cleaner
separation of application logic and presentation.

=item Widgitization

Thanks to their ability to preprocess arguments, callbacks enable developers
to develop easier-to-use, more dynamic widgets that can then be used in any
and all Mason component, or even with other templating systems. For example, a
widget that puts many related fields into a form (such as a date selection
widget) can have its fields preprocessed by a callback (for example, to
properly combine the fields into a unified date field) before the Mason
component that responds to the form submission gets the data. See
L<Params::Callback|Params::Callback/"Subclassing Examples"> for an example
solution for this very problem.

=item Shared Memory

Callbacks are just Perl subroutines in modules, and are therefore loaded at
server startup time in a mod_perl environment. Thus the memory they consume is
all in the Apache parent process, and shared by the child processes. For code
that executes frequently, this can be much less resource-intensive than code
in Mason components, since components are loaded separately in each Apache
child process (unless they're preloaded via the C<preloads> parameter to the
HTML::Mason::Interp constructor).

=item Performance

Since they're executed before Mason creates a component stack and executes the
components, callbacks have the opportunity to short-circuit the Mason
processing by doing something else. A good example is redirection. Often the
application logic in callbacks does its thing and then redirects the user to a
different page. Executing the redirection in a callback eliminates a lot of
extraneous processing that would otherwise be executed before the redirection,
creating a snappier response for the user.

=item Testing

Mason components are not easy to test via a testing framework such as
Test::Harness. Subroutines in modules, on the other hand, are fully
testable. This means that you can write tests in your application test suite
to test your callback subroutines.

=back

And if those aren't enough reasons, then just consider this: Callbacks are
just I<way cool.>

=head1 USAGE

MasonX::Interp::WithCallbacks uses Params::CallbackRequest for its callback
architecture, and therefore supports its two different types of callbacks:
those triggered by a specially named key in the Mason request arguments hash,
and those executed for every request.

=head2 Argument-Triggered Callbacks

Argument-triggered callbacks are triggered by specially named request argument
keys. These keys are constructed as follows: The package name followed by a
pipe character ("|"), the callback key with the string "_cb" appended to it,
and finally an optional priority number at the end. For example, if you
specified a callback with the callback key "save" and the package key "world",
a callback field might be added to an HTML form like this:

  <input type="button" value="Save World" name="world|save_cb" />

This field, when submitted to the Mason server, would trigger the callback
associated with the "save" callback key in the "world" package. If such a
callback hasn't been configured, then Params::CallbackRequest will throw a
Params::CallbackReuest::Exception::InvalidKey exception. Here's how to
configure a functional callback when constructing your
MasonX::Interp::WithCallbacks object so that that doesn't happen:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( callbacks => [ { pkg_key => 'world',
                       cb_key  => 'save',
                       cb      => \&My::World::save } ] );

With this configuration, the request argument created by the above HTML form
field will trigger the execution of the C<&My::World::save> subroutine.

=head3 Functional Callback Subroutines

Functional callbacks use a code reference for argument-triggered callbacks,
and Params::CallbackRequest executes them with a single argument, a
Params::Callback object. Thus, a callback subroutine will generally look
something like this:

  sub foo {
      my $cb = shift;
      # Do stuff.
  }

The Params::Callback object provides accessors to data relevant to the
callback, including the callback key, the package key, and the request
arguments (or parameters). It also includes C<redirect()> and C<abort()>
methods. See the L<Params::Callback|Params::Callback> documentation for all
the goodies.

Note that all callbacks are executed in a C<eval {}> block, so if any of your
callback subroutines C<die>, Params::CallbackRequest will throw an
Params::CallbackRequest::Exception::Execution exception If you don't like
this, use the C<cb_exception_handler> parameter to C<new()> to install your
own exception handler.

=head3 Object-Oriented Callback Methods

Object-oriented callback methods are defined in subclasses of
Params::Callback. Unlike functional callbacks, they are not called with a
Params::Callback object, but with an instance of the callback subclass. These
classes inherit all the goodies provided by Params::Callback, so you can
essentially use their instances exactly as you would use the Params::Callback
object in functional callback subroutines. But because they're subclasses, you
can add your own methods and attributes. See
L<Params::Callback|Params::Callback> for all the gory details on subclassing,
along with a few examples. Generally, callback methods will look like this:

  sub foo : Callback {
      my $self = shift;
      # Do stuff.
  }

As with functional callback subroutines, method callbacks are executed in a
C<eval {}> block. Again, see the C<cb_exception_handler> parameter to install
your own exception handler.

B<Note:> It's important that you C<use> any and all MasonX::Callback
subclasses I<before> you C<use MasonX::Interp::WithCallbacks> or C<use
Params::CallbackRequest>. This is to get around an issue with identifying the
names of the callback methods in mod_perl. Read the comments in the
MasonX::Callback source code if you're interested in learning more.

=head3 The Package Key

The use of the package key is a convenience so that a system with many
functional callbacks can use callbacks with the same keys but in different
packages. The idea is that the package key will uniquely identify the module
in which each callback subroutine is found, but it doesn't necessarily have to
be so. Use the package key any way you wish, or not at all:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( callbacks => [ { cb_key  => 'save',
                       cb      => \&My::World::save } ] );

But note that if you don't use the package key at all, you'll still need to
provide one in the parameters to be submitted to C<exec()> By default, that
key is "DEFAULT". Such a callback field in an HTML form would then look like
this:

  <input type="button" value="Save World" name="DEFAULT|save_cb" />

If you don't like the "DEFAULT" package name, you can set an alternative
default using the C<default_pkg_name> parameter to C<new()>:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( callbacks        => [ { cb_key  => 'save',
                              cb      => \&My::World::save } ],
      default_pkg_name => 'MyPkg' );

Then, of course, any callbacks without a specified package key of their own
will then use the custom default:

  <input type="button" value="Save World" name="MyPkg|save_cb" />

=head3 The Class Key

The class key is essentially a synonym for the package key, but applies more
directly to object-oriented callbacks. The difference is mainly that it
corresponds to an actual class, and that all Params::Callback subclasses are
I<required> to have a class key; it's not optional as it is with functional
callbacks. The class key may be declared in your Params::Callback subclass
like so:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'MyCBHandler' );

The class key can also be declared by implementing a C<CLASS_KEY()> method,
like so:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass;
  use constant CLASS_KEY => 'MyCBHandler';

If no class key is explicitly defined, Params::Callback will use the subclass
name, instead. In any event, the C<register_callback()> method B<must> be
called to register the subclass with Params::Callback. See the
L<Params::Callback|Params::Callback/"Callback Class Declaration">
documentation for complete details.

=head3 Priority

Sometimes one callback is more important than another. For example, you might
rely on the execution of one callback to set up variables needed by another.
Since you can't rely on the order in which callbacks are executed (the Mason
request arguments are stored in a hash, and the processing of a hash is, of
course, unordered), you need a method of ensuring that the setup callback
executes first.

In such a case, you can set a higher priority level for the setup callback
than for callbacks that depend on it. For functional callbacks, you can do it
like this:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( callbacks        => [ { cb_key   => 'setup',
                              priority => 3,
                              cb       => \&setup },
                            { cb_key   => 'save',
                              cb       => \&save }
                          ] );

For object-oriented callbacks, you can define the priority right in the
callback method declaration:

  sub setup : Callback( priority => 3 ) {
      my $self = shift;
      # ...
  }

  sub save : Callback {
      my $self = shift;
      # ...
  }

In these examples, the "setup" callback has been configured with a priority
level of "3". This ensures that it will always execute before the "save"
callback, which has the default priority of "5". This is true regardless of
the order of the fields in the corresponding HTML::Form:

  <input type="button" value="Save World" name="DEFAULT|save_cb" />
  <input type="hidden" name="DEFAULT|setup_cb" value="1" />

Despite the fact that the "setup" callback field appears after the "save"
field (and will generally be submitted by the browser in that order), the
"setup" callback will always execute first because of its higher priority.

Although the "save" callback got the default priority of "5", this too can be
customized to a different priority level via the C<default_priority> parameter
to C<new()> for functional callbacks and the C<default_priority> to the class
declaration for object-oriented callbacks For example, this functional
callback configuration:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( callbacks        => [ { cb_key   => 'setup',
                              priority => 3,
                              cb       => \&setup },
                            { cb_key   => 'save',
                              cb       => \&save }
                          ],
      default_priority => 2 );

And this Params::Callback subclass declaration:

  package MyApp::CallbackHandler;
  use base qw(Params::Callback);
  __PACKAGE__->register_subclass( class_key => 'MyCBHandler',
                                  default_priority => 2 );

Will cause the "save" callback to always execute before the "setup" callback,
since its priority level will default to "2".

In addition, the priority level can be overridden via the form submission field
itself by appending a priority level to the end of the callback field
name. Hence, this example:

  <input type="button" value="Save World" name="DEFAULT|save_cb2" />
  <input type="hidden" name="DEFAULT|setup_cb" value="1" />

Causes the "save" callback to execute before the "setup" callback by
overriding the "save" callback's priority to level "2". Of course, any other
form field that triggers the "save" callback without a priority override will
still execute "save" at its configured level.

=head2 Request Callbacks

Request callbacks come in two separate flavors: those that execute before the
argument-triggered callbacks, and those that execute after the
argument-triggered callbacks. All of them execute before the Mason component
stack executes. Functional request callbacks may be specified via the
C<pre_callbacks> and C<post_callbacks> parameters to C<new()>, respectively:

  my $interp = MasonX::Interp::WithCallbacks->new
    ( pre_callbacks  => [ \&translate, \&foobarate ],
      post_callbacks => [ \&escape, \&negate ] );

Object-oriented request callbacks may be declared via the C<PreCallback> and
C<PostCallback> method attributes, like so:

  sub translate : PreCallback { ... }
  sub foobarate : PreCallback { ... }
  sub escape : PostCallback { ... }
  sub negate : PostCallback { ... }

In these examples, the C<translate()> and C<foobarate()> subroutines or
methods will execute (in that order) before any argument-triggered callbacks
are executed (none will be in these examples, since none are specified).

Conversely, the C<escape()> and C<negate()> subroutines or methods will be
executed (in that order) after all argument-triggered callbacks have been
executed. And regardless of what argument-triggered callbacks may be
triggered, the request callbacks will always be executed for I<every> request.

Although they may be used for different purposes, the C<pre_callbacks> and
C<post_callbacks> functional callback code references expect the same argument
as argument-triggered functional callbacks: a Params::Callback object:

  sub foo {
      my $cb = shift;
      # Do your business here.
  }

Similarly, object-oriented request callback methods will be passed an object
of the class defined in the class key portion of the callback trigger --
either an object of the class in which the callback is defined, or an object
of a subclass:

  sub foo : PostCallback {
      my $self = shift;
      # ...
  }

Of course, the attributes of the Params::Callback or subclass object will be
different than in argument-triggered callbacks. For example, the C<priority>,
C<pkg_key>, and C<cb_key> attributes will naturally be undefined. It will,
however, be the same instance of the object passed to all other functional
callbacks -- or to all other class callbacks with the same class key -- in a
single request.

Like the argument-triggered callbacks, request callbacks are executed in a
C<eval {}> block, so if any of them C<die>s, an
Params::CallbackRequest::Exception::Execution exception will be thrown. Use
the C<cb_exception_handler> parameter to C<new()> if you don't like this.

=head1 INTERFACE

=head2 Parameters To The C<new()> Constructor

In addition to those offered by the HTML::Mason::Interp base class, this
module supports a number of its own parameters to the C<new()> constructor
based on those required by Params::CallbackRequest. Each also has a
corresponding F<httpd.conf> variable as well, so, if you really want to, you
can use MasonX::Interp::WithCallbacks right in your F<httpd.conf> file:

  PerlModule MasonX::Interp::WithCallbacks
  PerlSetVar MasonInterpClass MasonX::Interp::WithCallbacks
  SetHandler perl-script
  PerlHandler HTML::Mason::ApacheHandler

The parameters to C<new()> and their corresponding F<httpd.conf> variables are
as follows:

=over 4

=item C<callbacks>

Argument-triggered functional callbacks are configured via the C<callbacks>
parameter. This parameter is an array reference of hash references, and each
hash reference specifies a single callback. The supported keys in the callback
specification hashes are:

=over 4

=item C<cb_key>

Required. A string that, when found in a properly-formatted Mason request
argument key, will trigger the execution of the callback.

=item C<cb>

Required. A reference to the Perl subroutine that will be executed when the
C<cb_key> has been found in a Mason request argument key. Each code reference
should expect a single argument: a Params::Callback object. The same
instance of a Params::Callback object will be used for all functional
callbacks in a single request.

=item C<pkg_key>

Optional. A key to uniquely identify the package in which the callback
subroutine is found. This parameter is useful in systems with many callbacks,
where developers may wish to use the same C<cb_key> for different subroutines
in different packages. The default package key may be set via the
C<default_pkg_key> parameter.

=item C<priority>

Optional. Indicates the level of priority of a callback. Some callbacks are
more important than others, and should be executed before the others.
Params::CallbackRequest supports priority levels ranging from "0" (highest
priority) to "9" (lowest priority). The default priority for functional
callbacks may be set via the C<default_priority> parameter.

=back

The <callbacks> parameter can also be specified via the F<httpd.conf>
configuration variable C<MasonCallbacks>. Use C<PerlSetVar> to specify
several callbacks; each one should be an C<eval>able string that converts into
a hash reference as specified here. For example, to specify two callbacks, use
this syntax:

  PerlAddVar MasonCallbacks "{ cb_key  => 'foo', cb => sub { ... }"
  PerlAddVar MasonCallbacks "{ cb_key  => 'bar', cb => sub { ... }"

Note that the C<eval>able string must be entirely on its own line in the
F<httpd.conf> file.

=item C<pre_callbacks>

This parameter accepts an array reference of code references that should be
executed for I<every> request I<before> any other callbacks. They will be
executed in the order in which they're listed in the array reference. Each
code reference should expect a single Params::Callback argument. The same
instance of a Params::Callback object will be used for all functional
callbacks in a single request. Use pre-argument-triggered request callbacks
when you want to do something with the arguments submitted for every request,
such as convert character sets.

The <pre_callbacks> parameter can also be specified via the F<httpd.conf>
configuration variable C<MasonPreCallbacks>. Use multiple C<PerlAddVar> to
add multiple pre-request callbacks; each one should be an C<eval>able string
that converts into a code reference:

  PerlAddVar MasonPreCallbacks "sub { ... }"
  PerlAddVar MasonPreCallbacks "sub { ... }"

=item C<post_callbacks>

This parameter accepts an array reference of code references that should be
executed for I<every> request I<after> all other callbacks have been
called. They will be executed in the order in which they're listed in the
array reference. Each code reference should expect a single Params::Callback
argument. The same instance of a Params::Callback object will be used for all
functional callbacks in a single request. Use post-argument-triggered request
callbacks when you want to do something with the arguments submitted for every
request, such as HTML-escape their values.

The <post_callbacks> parameter can also be specified via the F<httpd.conf>
configuration variable C<MasonPostCallbacks>. Use multiple C<PerlAddVar> to
add multiple post-request callbacks; each one should be an C<eval>able string
that converts into a code reference:

  PerlAddVar MasonPostCallbacks "sub { ... }"
  PerlAddVar MasonPostCallbacks "sub { ... }"

=item C<cb_classes>

An array reference listing the class keys of all of the Params::Callback
subclasses containing callback methods that you want included in your
MasonX::Interp::WithCallbacks object. Alternatively, the C<cb_classes>
parameter may simply be the word "ALL", in which case I<all> Params::Callback
subclasses will have their callback methods registered with your
MasonX::Interp::WithCallbacks object. See the
L<Params::Callback|Params::Callback> documentation for details on creating
callback classes and methods.

B<Note:> Be sure to C<use MasonX::Interp::WithCallbacks> or C<use
Params::CallbackRequest> I<only> after you've C<use>d all of the
Params::Callback subclasses you need or else you won't be able to use their
callback methods.

The <cb_classes> parameter can also be specified via the F<httpd.conf>
configuration variable C<MasonCbClasses>. Use multiple C<PerlAddVar> to add
multiple callback class keys. But, again, be sure to load
MasonX::Interp::WithCallbacks or Params::CallbackRequest I<only> after you've
loaded all of your MasonX::Callback handler subclasses:

  PerlModule My::CBClass
  PerlModule Your::CBClass
  PerlSetVar MasonCbClasses myCBClass
  PerlAddVar MasonCbClasses yourCBClass
  # Load MasonX::Interp::WithCallbacks last!
  PerlModule MasonX::Interp::WithCallbacks

=item C<default_priority>

The priority level at which functional callbacks will be executed. Does not
apply to object-oriented callbacks. This value will be used in each hash
reference passed via the C<callbacks> parameter to C<new()> that lacks a
C<priority> key. You may specify a default priority level within the range of
"0" (highest priority) to "9" (lowest priority). If not specified, it defaults
to "5".

Use the C<MasonDefaultPriority> variable to set the the C<default_priority>
parameter in your F<httpd.conf> file:

  PerlSetVar MasonDefaultPriority 3

=item C<default_pkg_key>

The default package key for functional callbacks. Does not apply to
object-oriented callbacks. This value that will be used in each hash reference
passed via the C<callbacks> parameter to C<new()> that lacks a C<pkg_key>
key. It can be any string that evaluates to a true value, and defaults to
"DEFAULT" if not specified.

Use the C<MasonDefaultPkgKey> variable to set the the C<default_pkg_key>
parameter in your F<httpd.conf> file:

  PerlSetVar MasonDefaultPkgKey CBFoo

=item C<ignore_nulls>

By default, Params::CallbackRequest will execute all request
callbacks. However, in many situations it may be desirable to skip any
callbacks that have no value for the callback field. One can do this by simply
checking C<< $cb->value >> in the callback, but if you need to disable the
execution of all callbacks, pass the C<ignore_nulls> parameter with a true
value. It is set to a false value by default.

Use the C<MasonIgnoreNulls> variable to set the the C<ignore_nulls> parameter
in your F<httpd.conf> file:

  PerlSetVar MasonIgnoreNulls 1

=item C<cb_exception_handler>

When Params::CallbackRequest encounters an exception during the execution of
callbacks, it normally calls
C<Params::CallbackRequest::Exceptions::rethrow_exception> to handle the
exception. But if you throw your own exceptions in your callbacks, and want to
handle them differently (say, to handle them and then let the request
continue), pass the C<cb_exception_handler> parameter a code reference to do
what you need.

Use the C<MasonCbExceptionHandler> variable to set the C<cb_exception_handler>
parameter in your F<httpd.conf> file:

  MasonCbExceptionHandler "sub {...}"

B<Note:> This is the only parameter that differs in name from the same
parameter to C<< Params::CallbackRequest->new >>. This is so that it can be
easily distinguished from the possible addition of a C<exception_handler>
parameter to a future version of Mason.

=back

=head2 Accessor Methods

All of the above parameters to C<new()> are passed to the
Params::CallbackRequest constructor and deleted from the
MasonX::Interp::WithCallbacks object. MasonX::Interp::WithCallbacks then
contains a Params::CallbackRequest object that it uses to handle the execution
of all callbacks for each request.

=head3 cb_request

  my $interp = MasonX::Interp::WithCallbacks->new;
  my $cb_request = $interp->cb_request;

Returns the Params::CallbackRequest object in use during the execution of
C<make_request()>.

=head3 comp_path

  my $comp_path = $interp->comp_path;
  $interp->comp_path($comp_path);

Returns the component path resolved by Mason during the execution of
C<handle_request()>. The cool thing is that it can be changed during the
execution of callback methods:

  sub change_path :Callback {
      my $cb = shift;
      my $interp = $cb->requester;
      $inpter->comp_path($some_other_path);
  }

In this example, we have overridden the component path determined by the
Mason resolver in favor of an alternate component, which will be executed,
instead.

=head2 Requester

The MasonX::Interp::WithCallbacks object is available in all callback methods
via the C<requester()> accessor:

  sub access_interp :Callback {
      my $cb = shift;
      my $interp = $cb->requester;
      # ...
  }

=head2 Notes

  $interp->cb_request->notes($key => $value);
  my $note = $interp->cb_request->notes($key);
  my $notes = $interp->cb_request->notes;

The Params::CallbackRequest notes interface remains available via the
C<notes()> method of both Params::CallbackRequest and Params::Callback. Notes
stored via this interface will be copied to the HTML::Mason::Request
C<notes()> interface before the execution of the request, I<and> continue to
be available for the lifetime of the Mason request via
C<< $interp->cb_request->notes >>. Notes will be cleared out at the end of the
request, just as with C<< $r->pnotes >>.

=head1 SUPPORT

This module is stored in an open L<GitHub
repository|http://github.com/theory/masonx-interp-withcallbacks/>. Feel free
to fork and contribute!

Please file bug reports via L<GitHub
Issues|http://github.com/theory/masonx-interp-withcallbacks/issues/> or by
sending mail to
L<bug-MasonX-Interp-WithCallbacks.cpan.org|mailto:bug-MasonX-Interp-WithCallbacks.cpan.org>.

=head1 SEE ALSO

L<Params::CallbackRequest|Params::CallbackRequest> handles the processing of
the Mason request arguments and the execution of callbacks. See its
documentation for the most up-to-date documentation of the underlying callback
architecture.

L<Params::Callback|Params::Callback> objects get passed as the sole argument
to all functional callbacks, and offer access to data relevant to the
callback. Params::Callback also defines the object-oriented callback
interface, making its documentation a must-read for anyone who wishes to
create callback classes and methods.

This module works with L<HTML::Mason|HTML::Mason> by subclassing
L<HTML::Mason::Interp|HTML::Mason::Interp>. Inspired by the implementation of
callbacks in Bricolage (L<http://bricolage.cc/>), it is however a completely
new code base with a rather different approach.

=head1 AUTHOR

David E. Wheeler <david@justatheory.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2011 by David E. Wheeler. Some Rights Reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
