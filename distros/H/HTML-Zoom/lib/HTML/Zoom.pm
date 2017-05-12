package HTML::Zoom;

use strictures 1;

use HTML::Zoom::ZConfig;
use HTML::Zoom::ReadFH;
use HTML::Zoom::Transform;
use HTML::Zoom::TransformBuilder;
use Scalar::Util ();

our $VERSION = '0.009009';

$VERSION = eval $VERSION;

sub new {
  my ($class, $args) = @_;
  my $new = {};
  $new->{zconfig} = HTML::Zoom::ZConfig->new($args->{zconfig}||{});
  bless($new, $class);
}

sub zconfig { shift->_self_or_new->{zconfig} }

sub _self_or_new {
  ref($_[0]) ? $_[0] : $_[0]->new
}

sub _with {
  bless({ %{$_[0]}, %{$_[1]} }, ref($_[0]));
}

sub from_events {
  my $self = shift->_self_or_new;
  $self->_with({
    initial_events => shift,
  });
}

sub from_html {
  my $self = shift->_self_or_new;
  $self->from_events($self->zconfig->parser->html_to_events($_[0]))
}

sub from_file {
  my $self = shift->_self_or_new;
  my $filename = shift;
  $self->from_html(do { local (@ARGV, $/) = ($filename); <> });
}

sub to_stream {
  my $self = shift;
  die "No events to build from - forgot to call from_html?"
    unless $self->{initial_events};
  my $sutils = $self->zconfig->stream_utils;
  my $stream = $sutils->stream_from_array(@{$self->{initial_events}});
  $stream = $_->apply_to_stream($stream) for @{$self->{transforms}||[]};
  $stream
}

sub to_fh {
  HTML::Zoom::ReadFH->from_zoom(shift);
}

sub to_events {
  my $self = shift;
  [ $self->zconfig->stream_utils->stream_to_array($self->to_stream) ];
}

sub run {
  my $self = shift;
  $self->to_events;
  return
}

sub apply {
  my ($self, $code) = @_;
  local $_ = $self;
  $self->$code;
}

sub apply_if {
  my ($self, $predicate, $code) = @_;
  if($predicate) {
    local $_ = $self;
    $self->$code;
  }
  else {
    $self;
  }
}

sub to_html {
  my $self = shift;
  $self->zconfig->producer->html_from_stream($self->to_stream);
}

sub memoize {
  my $self = shift;
  ref($self)->new($self)->from_html($self->to_html);
}

sub with_transform {
  my $self = shift->_self_or_new;
  my ($transform) = @_;
  $self->_with({
    transforms => [
      @{$self->{transforms}||[]},
      $transform
    ]
  });
}
  
sub with_filter {
  my $self = shift->_self_or_new;
  my ($selector, $filter) = @_;
  $self->with_transform(
    HTML::Zoom::Transform->new({
      zconfig => $self->zconfig,
      selector => $selector,
      filters => [ $filter ]
    })
  );
}

sub select {
  my $self = shift->_self_or_new;
  my ($selector) = @_;
  return HTML::Zoom::TransformBuilder->new({
    zconfig => $self->zconfig,
    selector => $selector,
    proto => $self
  });
}

# There's a bug waiting to happen here: if you do something like
#
# $zoom->select('.foo')
#      ->remove_attribute(class => 'foo')
#      ->then
#      ->well_anything_really
#
# the second action won't execute because it doesn't match anymore.
# Ideally instead we'd merge the match subs but that's more complex to
# implement so I'm deferring it for the moment.

sub then {
  my $self = shift;
  die "Can't call ->then without a previous transform"
    unless $self->{transforms};
  $self->select($self->{transforms}->[-1]->selector);
}

sub AUTOLOAD {
  my ($self, $selector, @args) = @_;
  my $sel = $self->select($selector);
  my $meth = our $AUTOLOAD;
  $meth =~ s/.*:://;
  if (ref($selector) eq 'HASH') {
    my $ret = $self;
    $ret = $ret->_do($_, $meth, @{$selector->{$_}}) for keys %$selector;
    $ret;
  } else {
    $self->_do($selector, $meth, @args);
  }
}

sub _do {
  my ($self, $selector, $meth, @args) = @_;
  my $sel = $self->select($selector);
  if( my $cr = $sel->_zconfig->filter_builder->can($meth)) {
    return $sel->$meth(@args);
  } else {
    die "We can't do $meth on ->select('$selector')";
  }
}

sub DESTROY {}

1;

=head1 NAME

HTML::Zoom - selector based streaming template engine

=head1 SYNOPSIS

  use HTML::Zoom;

  my $template = <<HTML;
  <html>
    <head>
      <title>Hello people</title>
    </head>
    <body>
      <h1 id="greeting">Placeholder</h1>
      <div id="list">
        <span>
          <p>Name: <span class="name">Bob</span></p>
          <p>Age: <span class="age">23</span></p>
        </span>
        <hr class="between" />
      </div>
    </body>
  </html>
  HTML

  my $output = HTML::Zoom
    ->from_html($template)
    ->select('title, #greeting')->replace_content('Hello world & dog!')
    ->select('#list')->repeat_content(
        [
          sub {
            $_->select('.name')->replace_content('Matt')
              ->select('.age')->replace_content('26')
          },
          # alternate form
          sub {
            $_->replace_content({'.name' => ['Mark'],'.age' => ['0x29'] })
          },
          #alternate alternate form
          sub {
            $_->replace_content('.name' => 'Epitaph')
              ->replace_content('.age' => '<redacted>')
          },
        ],
        { repeat_between => '.between' }
      )
    ->to_html;

will produce:

=begin testinfo

  my $expect = <<HTML;

=end testinfo

  <html>
    <head>
      <title>Hello world &amp; dog!</title>
    </head>
    <body>
      <h1 id="greeting">Hello world &amp; dog!</h1>
      <div id="list">
        <span>
          <p>Name: <span class="name">Matt</span></p>
          <p>Age: <span class="age">26</span></p>
        </span>
        <hr class="between" />
        <span>
          <p>Name: <span class="name">Mark</span></p>
          <p>Age: <span class="age">0x29</span></p>
        </span>
        <hr class="between" />
        <span>
          <p>Name: <span class="name">Epitaph</span></p>
          <p>Age: <span class="age">&lt;redacted&gt;</span></p>
        </span>
        
      </div>
    </body>
  </html>

=begin testinfo

  HTML
  is($output, $expect, 'Synopsis code works ok');

=end testinfo

=head1 DANGER WILL ROBINSON

This is a 0.9 release. That means that I'm fairly happy the API isn't going
to change in surprising and upsetting ways before 1.0 and a real compatibility
freeze. But it also means that if it turns out there's a mistake the size of
a politician's ego in the API design that I haven't spotted yet there may be
a bit of breakage between here and 1.0. Hopefully not though. Appendages
crossed and all that.

Worse still, the rest of the distribution isn't documented yet. I'm sorry.
I suck. But lots of people have been asking me to ship this, docs or no, so
having got this class itself at least somewhat documented I figured now was
a good time to cut a first real release.

=head1 DESCRIPTION

HTML::Zoom is a lazy, stream oriented, streaming capable, mostly functional,
CSS selector based semantic templating engine for HTML and HTML-like
document formats.

Which is, on the whole, a bit of a mouthful. So let me step back a moment
and explain why you care enough to understand what I mean:

=head2 JQUERY ENVY

HTML::Zoom is the cure for JQuery envy. When your javascript guy pushes a
piece of data into a document by doing:

  $('.username').replaceAll(username);

In HTML::Zoom one can write

  $zoom->select('.username')->replace_content($username);

which is, I hope, almost as clear, hampered only by the fact that Zoom can't
assume a global document and therefore has nothing quite so simple as the
$() function to get the initial selection.

L<HTML::Zoom::SelectorParser> implements a subset of the JQuery selector
specification, and will continue to track that rather than the W3C standards
for the forseeable future on grounds of pragmatism. Also on grounds of their
spec is written in EN_US rather than EN_W3C, and I read the former much better.

I am happy to admit that it's very, very much a subset at the moment - see the
L<HTML::Zoom::SelectorParser> POD for what's currently there, and expect more
and more to be supported over time as we need it and patch it in.

=head2 CLEAN TEMPLATES

HTML::Zoom is the cure for messy templates. How many times have you looked at
templates like this:

  <form action="/somewhere">
  [% FOREACH field IN fields %]
    <label for="[% field.id %]">[% field.label %]</label>
    <input name="[% field.name %]" type="[% field.type %]" value="[% field.value %]" />
  [% END %]
  </form>

and despaired of the fact that neither the HTML structure nor the logic are
remotely easy to read? Fortunately, with HTML::Zoom we can separate the two
cleanly:

  <form class="myform" action="/somewhere">
    <label />
    <input />
  </form>

  $zoom->select('.myform')->repeat_content([
    map { my $field = $_; sub {

     $_->select('label')
       ->add_to_attribute( for => $field->{id} )
       ->then
       ->replace_content( $field->{label} )
       ->add_to_attribute(
        input => { 
         name => $field->{name},
         type => $field->{type},
         value => $field->{value}
       })
    } } @fields
  ]);

This is, admittedly, very much not shorter. However, it makes it extremely
clear what's happening and therefore less hassle to maintain. Especially
because it allows the designer to fiddle with the HTML without cutting
himself on sharp ELSE clauses, and the developer to add available data to
the template without getting angle bracket cuts on sensitive parts.

Better still, HTML::Zoom knows that it's inserting content into HTML and
can escape it for you - the example template should really have been:

  <form action="/somewhere">
  [% FOREACH field IN fields %]
    <label for="[% field.id | html %]">[% field.label | html %]</label>
    <input name="[% field.name | html %]" type="[% field.type | html %]" value="[% field.value | html %]" />
  [% END %]
  </form>

and frankly I'll take slightly more code any day over *that* crawling horror.

(addendum: I pick on L<Template Toolkit|Template> here specifically because
it's the template system I hate the least - for text templating, I don't
honestly think I'll ever like anything except the next version of Template
Toolkit better - but HTML isn't text. Zoom knows that. Do you?)

=head2 PUTTING THE FUN INTO FUNCTIONAL

The principle of HTML::Zoom is to provide a reusable, functional container
object that lets you build up a set of transforms to be applied; every method
call you make on a zoom object returns a new object, so it's safe to do so
on one somebody else gave you without worrying about altering state (with
the notable exception of ->next for stream objects, which I'll come to later).

So:

  my $z2 = $z1->select('.name')->replace_content($name);

  my $z3 = $z2->select('.title')->replace_content('Ms.');

each time produces a new Zoom object. If you want to package up a set of
transforms to re-use, HTML::Zoom provides an 'apply' method:

  my $add_name = sub { $_->select('.name')->replace_content($name) };
 
  my $same_as_z2 = $z1->apply($add_name);

=head2 LAZINESS IS A VIRTUE

HTML::Zoom does its best to defer doing anything until it's absolutely
required. The only point at which it descends into state is when you force
it to create a stream, directly by:

  my $stream = $zoom->to_stream;

  while (my $evt = $stream->next) {
    # handle zoom event here
  }

or indirectly via:

  my $final_html = $zoom->to_html;

  my $fh = $zoom->to_fh;

  while (my $chunk = $fh->getline) {
    ...
  }

Better still, the $fh returned doesn't create its stream until the first
call to getline, which means that until you call that and force it to be
stateful you can get back to the original stateless Zoom object via:

  my $zoom = $fh->to_zoom;

which is exceedingly handy for filtering L<Plack> PSGI responses, among other
things.

Because HTML::Zoom doesn't try and evaluate everything up front, you can
generally put things together in whatever order is most appropriate. This
means that:

  my $start = HTML::Zoom->from_html($html);

  my $zoom = $start->select('div')->replace_content('THIS IS A DIV!');

and:

  my $start = HTML::Zoom->select('div')->replace_content('THIS IS A DIV!');

  my $zoom = $start->from_html($html);

will produce equivalent final $zoom objects, thus proving that there can be
more than one way to do it without one of them being a
L<bait and switch|Switch>.

=head2 STOCKTON TO DARLINGTON UNDER STREAM POWER

HTML::Zoom's execution always happens in terms of streams under the hood
- that is, the basic pattern for doing anything is -

  my $stream = get_stream_from_somewhere

  while (my ($evt) = $stream->next) {
    # do something with the event
  }

More importantly, all selectors and filters are also built as stream
operations, so a selector and filter pair is effectively:

  sub next {
    my ($self) = @_;
    my $next_evt = $self->parent_stream->next;
    if ($self->selector_matches($next_evt)) {
      return $self->apply_filter_to($next_evt);
    } else {
      return $next_evt;
    }
  }

Internally, things are marginally more complicated than that, but not enough
that you as a user should normally need to care.

In fact, an HTML::Zoom object is mostly just a container for the relevant
information from which to build the final stream that does the real work. A
stream built from a Zoom object is a stream of events from parsing the
initial HTML, wrapped in a filter stream per selector/filter pair provided
as described above.

The upshot of this is that the application of filters works just as well on
streams as on the original Zoom object - in fact, when you run a
L</repeat_content> operation your subroutines are applied to the stream for
that element of the repeat, rather than constructing a new zoom per repeat
element as well.

More concretely:

  $_->select('div')->replace_content('I AM A DIV!');

works on both HTML::Zoom objects themselves and HTML::Zoom stream objects and
shares sufficient of the implementation that you can generally forget the
difference - barring the fact that a stream already has state attached so
things like to_fh are no longer available.

=head2 POP! GOES THE WEASEL

... and by Weasel, I mean layout.

HTML::Zoom's filehandle object supports an additional event key, 'flush',
that is transparent to the rest of the system but indicates to the filehandle
object to end a getline operation at that point and return the HTML so far.

This means that in an environment where streaming output is available, such
as a number of the L<Plack> PSGI handlers, you can add the flush key to an
event in order to ensure that the HTML generated so far is flushed through
to the browser right now. This can be especially useful if you know you're
about to call a web service or a potentially slow database query or similar
to ensure that at least the header/layout of your page renders now, improving
perceived user responsiveness while your application waits around for the
data it needs.

This is currently exposed by the 'flush_before' option to the collect filter,
which incidentally also underlies the replace and repeat filters, so to
indicate we want this behaviour to happen before a query is executed we can
write something like:

  $zoom->select('.item')->repeat(sub {
    if (my $row = $db_thing->next) {
      return sub { $_->select('.item-name')->replace_content($row->name) }
    } else {
      return
    }
  }, { flush_before => 1 });

which should have the desired effect given a sufficiently lazy $db_thing (for
example a L<DBIx::Class::ResultSet> object).

=head2 A FISTFUL OF OBJECTS

At the core of an HTML::Zoom system lurks an L<HTML::Zoom::ZConfig> object,
whose purpose is to hang on to the various bits and pieces that things need
so that there's a common way of accessing shared functionality.

Were I a computer scientist I would probably call this an "Inversion of
Control" object - which you'd be welcome to google to learn more about, or
you can just imagine a computer scientist being suspended upside down over
a pit. Either way works for me, I'm a pure maths grad.

The ZConfig object hangs on to one each of the following for you:

=over 4

=item * An HTML parser, normally L<HTML::Zoom::Parser::BuiltIn>

=item * An HTML producer (emitter), normally L<HTML::Zoom::Producer::BuiltIn>

=item * An object to build event filters, normally L<HTML::Zoom::FilterBuilder>

=item * An object to parse CSS selectors, normally L<HTML::Zoom::SelectorParser>

=item * An object to build streams, normally L<HTML::Zoom::StreamUtils>

=back

In theory you could replace any of these with anything you like, but in
practice you're probably best restricting yourself to subclasses, or at
least things that manage to look like the original if you squint a bit.

If you do something more clever than that, or find yourself overriding things
in your ZConfig a lot, please please tell us about it via one of the means
mentioned under L</SUPPORT>.

=head2 SEMANTIC DIDACTIC

Some will argue that overloading CSS selectors to do data stuff is a terrible
idea, and possibly even a step towards the "Concrete Javascript" pattern
(which I abhor) or Smalltalk's Morphic (which I ignore, except for the part
where it keeps reminding me of the late, great Tony Hart's plasticine friend).

To which I say, "eh", "meh", and possibly also "feh". If it really upsets
you, either use extra classes for this (and remove them afterwards) or
use special fake elements or, well, honestly, just use something different.
L<Template::Semantic> provides a similar idea to zoom except using XPath
and XML::LibXML transforms rather than a lightweight streaming approach -
maybe you'd like that better. Or maybe you really did want
L<Template Toolkit|Template> after all. It is still damn good at what it does,
after all.

So far, however, I've found that for new sites the designers I'm working with
generally want to produce nice semantic HTML with classes that represent the
nature of the data rather than the structure of the layout, so sharing them
as a common interface works really well for us.

In the absence of any evidence that overloading CSS selectors has killed
children or unexpectedly set fire to grandmothers - and given microformats
have been around for a while there's been plenty of opportunity for
octagenarian combustion - I'd suggest you give it a try and see if you like it.

=head2 GET THEE TO A SUMMARY!

Erm. Well.

HTML::Zoom is a lazy, stream oriented, streaming capable, mostly functional,
CSS selector based semantic templating engine for HTML and HTML-like
document formats.

But I said that already. Although hopefully by now you have some idea what I
meant when I said it. If you didn't have any idea the first time. I mean, I'm
not trying to call you stupid or anything. Just saying that maybe it wasn't
totally obvious without the explanation. Or something.

Er.

Maybe we should just move on to the method docs.

=head1 METHODS

=head2 new

  my $zoom = HTML::Zoom->new;

  my $zoom = HTML::Zoom->new({ zconfig => $zconfig });

Create a new empty Zoom object. You can optionally pass an
L<HTML::Zoom::ZConfig> instance if you're trying to override one or more of
the default components.

This method isn't often used directly since several other methods can also
act as constructors, notable L</select> and L</from_html>

=head2 zconfig

  my $zconfig = $zoom->zconfig;

Retrieve the L<HTML::Zoom::ZConfig> instance used by this Zoom object. You
shouldn't usually need to call this yourself.

=head2 from_html

  my $zoom = HTML::Zoom->from_html($html);

  my $z2 = $z1->from_html($html);

Parses the HTML using the current zconfig's parser object and returns a new
zoom instance with that as the source HTML to be transformed.

=head2 from_file

  my $zoom = HTML::Zoom->from_file($file);

  my $z2 = $z1->from_file($file);

Convenience method - slurps the contents of $file and calls from_html with it.

=head2 from_events

  my $zoom = HTML::Zoom->from_events($evt);

Create a new Zoom object from collected events

=head2 to_stream

  my $stream = $zoom->to_stream;

  while (my ($evt) = $stream->next) {
    ...

Creates a stream, starting with a stream of the events from the HTML supplied
via L</from_html> and then wrapping it in turn with each selector+filter pair
that have been applied to the zoom object.

=head2 to_fh

  my $fh = $zoom->to_fh;

  call_something_expecting_a_filehandle($fh);

Returns an L<HTML::Zoom::ReadFH> instance that will create a stream the first
time its getline method is called and then return all HTML up to the next
event with 'flush' set.

You can pass this filehandle to compliant PSGI handlers (and probably most
web frameworks).

=head2 run

  $zoom->run;

Runs the zoom object's transforms without doing anything with the results.

Normally used to get side effects of a zoom run - for example when using
L<HTML::Zoom::FilterBuilder/collect> to slurp events for scraping or layout.

=head2 apply

  my $z2 = $z1->apply(sub {
    $_->select('div')->replace_content('I AM A DIV!') })
  });

Sets $_ to the zoom object and then runs the provided code. Basically syntax
sugar, the following is entirely equivalent:

  my $sub = sub {
    shift->select('div')->replace_content('I AM A DIV!') })
  };

  my $z2 = $sub->($z1);

=head2 apply_if

  my $z2 = $z1->apply_if($cond, sub {
    $_->select('div')->replace_content('I AM A DIV!') })
  });

->apply but will only run the tranform if $cond is true

=head2 to_html

  my $html = $zoom->to_html;

Runs the zoom processing and returns the resulting HTML.

=head2 memoize

  my $z2 = $z1->memoize;

Creates a new zoom whose source HTML is the results of the original zoom's
processing. Effectively syntax sugar for:

  my $z2 = HTML::Zoom->from_html($z1->to_html);

but preserves your L<HTML::Zoom::ZConfig> object.

=head2 with_filter

  my $zoom = HTML::Zoom->with_filter(
    'div', $filter_builder->replace_content('I AM A DIV!')
  );

  my $z2 = $z1->with_filter(
    'div', $filter_builder->replace_content('I AM A DIV!')
  );

Lower level interface than L</select> to adding filters to your zoom object.

In normal usage, you probably don't need to call this yourself.

=head2 select

  my $zoom = HTML::Zoom->select('div')->replace_content('I AM A DIV!');

  my $z2 = $z1->select('div')->replace_content('I AM A DIV!');

Returns an intermediary object of the class L<HTML::Zoom::TransformBuilder>
on which methods of your L<HTML::Zoom::FilterBuilder> object can be called.

In normal usage you should generally always put the pair of method calls
together; the intermediary object isn't designed or expected to stick around.

=head2 then

  my $z2 = $z1->select('div')->add_to_attribute(class => 'spoon')
                             ->then
                             ->replace_content('I AM A DIV!');

Re-runs the previous select to allow you to chain actions together on the
same selector.

=head1 AUTOLOAD METHODS

L<HTML::Zoom> AUTOLOADS methods against L</select> so that you can reduce a
certain amount of boilerplate typing.  This allows you to replace:

  $z->select('div')->replace_content("Hello World");
  
With:

  $z->replace_content(div => "Hello World");
  
Besides saving a few keys per invocations, you may feel this looks neater
in your code and increases understanding.

=head1 AUTHOR

mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 CONTRIBUTORS

Oliver Charles

Jakub Nareski

Simon Elliott

Joe Highton

John Napiorkowski

Robert Buels

David Dorward

=head1 COPYRIGHT

Copyright (c) 2010-2011 the HTML::Zoom L</AUTHOR> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

