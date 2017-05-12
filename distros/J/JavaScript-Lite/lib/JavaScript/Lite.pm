package JavaScript::Lite;

use 5.006;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('JavaScript::Lite', $VERSION);

return 1;

sub new {
  my $class = shift;
  my $maxmem = shift || 1048576;
  my $self = $class->create($maxmem);
  return bless $self, $class;
}

sub eval_file {
  my($self, $file) = @_;
  my $fh;
  open($fh, '<', $file) or croak "$file: $!";
  my $script = join('', <$fh>);
  return $self->eval($script, $file);
}

sub eval_file_void {
  my($self, $file) = @_;
  my $fh;
  open($fh, '<', $file) or croak "$file: $!";
  my $script = join('', <$fh>);
  $self->eval_void($script, $file);
}

sub eval {
  my($self, $code, $file) = @_;
  $file ||= "(eval)";
  $self->eval_js($code, $file);
}

=pod

=head1 NAME

JavaScript::Lite - Bare-bones interface to SpiderMonkey ECMAscript API

=head1 SYNOPSIS

  use JavaScript::Lite;
  
  my $js = JavaScript::Lite->new;
  $js->assign(numbers => [ 2, 4, 6, 8, 10 ]);
  $js->assign(start => 1);
  $js->eval(q{
    function add_next() {
      var n;
      if(n = numbers.shift()) {
        start = start + n;
        return start;
      } else {
        return;
      }
    }
  });
  
  while(my $next = $js->invoke("add_next")) {
    print "$next\n";
  }

=head1 DESCRIPTION

C<JavaScript::Lite> is a bare-bones interface to the SpiderMonkey
ECMAscript engine. It aims to provide as little functionality (and
therefore as little overhead) as is neccessary to connect perl with
ECMAscript. Efficiency is the goal here; the intended environments
are places where you are going to be calling from perl into
ECMAscript thousands (or millions) of times in succession (such as
using ECMAscript to drive the NPC logic in a perl-based MMORPG,
or writing a spam filter in perl where the end users can write
custom spam rules in ECMAscript, or...)

B<NOTE:> This is very, very alpha software. I intend to keep the
API more-or-less stable, but there may be quirks, and new features
will be added in future releases (so long as they do not slow the
existing features down!).

=head1 FEATURES

=over

=item Does not bind perl variables to ECMA variables.

=item Does not bind perl objects / classes to ECMA objects / classes; only copying of structures from perl to ECMA is supported.

=item Only allows ECMAscript to return scalars to perl (no complex data structures).

=item Does not allow ECMAscript to invoke perl.

=item Does not allow ECMA method calls from perl - only global function calls.

=item Does not run ECMAscript's garbage collection automatically.

=back

If you want powerful, flexible, full-featured blending of ECMAscript with
perl, please see the L<JavaScript> package. So why would you want to use
C<JavaScript::Lite>?

C<JavaScript::Lite> can run much, much faster than the L<JavaScript>
distribution. This is because the flexibility that L<JavaScript>
offers you comes at a cost; class/object translations are expensive,
and due to the fact that each language has different memory management, allowing
B<both> perl to call ECMA, and ECMA to call perl can cause irrecoverable
memory leaks (as can allowing complex data structures to flow in both
directions); the ECMA garbage collector can be expensive to run
(even in "maybe" mode), and just the additional overhead of tracking
all of this object/function binding/linking can be expensive.

In other words, here are some more features;

=over

=item Does not juggle two garbage collectors, therefore no memory leaks.

=item Does not track object bindings between two languages, therefore no slowdown over time.

=item Does not wrap every call in translation logic, therefore little overhead.

=back

=head1 METHODS

=over

=item new([$max_mem])

Constructor; creates and returns a new JavaScript::Lite object
(and underlying runtime/context). C<$max_mem> is the maximum
memory (in bytes) the JavaScript environment should be allowed to
consume. Defaults to 1MB.

(If you go over this limit, C<JavaScript::Lite> B<should> raise
an exception. Unfortunately, it doesn't yet... it causes a
segmentation fault instead. :-( So be careful.)

=item eval($code[, $filename])

Evaluate a block of JavaScript code, returning the result as a
scalar. If C<$filename> is specified, tells the javascript
interpreter that the code came from this file. Otherwise,
the default filename "(eval)" is used.

If the code fails to compile, an exception is raised, which must
be cleared if you want to keep using your JavaScript context;
see "C<clear_error>" below.

Note that this will not return JavaScript objects/structures;
only strings, numbers, or undef.

=item eval_void($code, $filename)

Evaluate a block of ECMAscript, returning nothing.
If you don't care about the return value of the script, this
method works slightly faster than C<eval> above. C<$filename>
is required.

=item eval_file($filename)

Reads the file C<$filename> from your filesystem and evaluates
it as ECMAscript, returning any scalar result.

=item eval_file_void($filename)

Same as C<eval_file>, except that no result is returned to perl.

=item invoke($name)

Invoke the global ECMAscript function called C<$name>.
Invoking methods on ECMAscript objects is not yet supported.
Passing arguments into the ECMAscript function is not yet
supported, but should be in the next release.

Like C<eval>, returns any scalar return value that the
function may have returned.

=item collect()

Tell the SpiderMonkey garbage collector that it may run if
it so wishes. If you don't do this every so often, your
ECMAscript context will run out of memory and crash.
This is not done automatically because even I<considering>
running the garbage collector can add significant overhead.

=item clear_error()

Clear any error condition that may have been raised in
ECMAscript. You must do this if you want to continue using your
C<JavaScript::Lite> object after an C<eval> or C<invoke> raises
an error.

=item assign($name, $value)

Assign C<$value> to the global ECMAscript variable C<$name>.
C<$value> may be a scalar, hashref, arrayref, or any nested
combination. The entire structure passed into C<$value> will
be B<copied> into ECMAscript. Globs and coderefs are not supported.
C<$value> must not be a self-referencing structure, or else
C<JavaScript::Lite> will crash (see BUGS below).

=item assign_property($object, $name, $value)

Assign C<$value> to the property C<$name> on the global
ECMAscript object called C<$object>. As with C<assign>,
C<$value> may be a scalar, hashref, arrayref, or any nested
combination.

C<$object> must be a top-level ECMAscript global object.
Nesting more than one layer deep (eg; "some_object.some.deep.property")
is not supported. For that functionality, see the L<JavaScript>
distribution.

=item branch_callback($callback[, $interval])

Run C<$callback> every C<$interval> branches in the javascript.
Branches are caused by things such as for() or while() loop invocation.
C<$callback> should a a subroutine reference; if the subroutine returns
a true value, the javascript will continue running. If it returns a false
value or dies, the javascript will terminate and an exception will be thrown.

If you do not specify C<$interval>, the callback will be executed during
every branch in javascript. This will slow down the script considerably;
for best results, you should use a value at least in the several thousands.

=item clear_branch_counter

Explicitly resets the branch counter to zero

=back

=head1 BUGS

If your C<JavaScript::Lite> object runs out of memory (as defined by
C<$max_mem> when you create the object), it can cause a
segmentation fault. I I<want> it to raise an exception instead,
I just haven't figured out how yet. :-(

C<JavaScript::Lite> does not detect self-referencing
data structures. And since it tries to make a B<copy> of the data
you pass in, if you pass in a self-referencing structure, it
will consume all available memory until it crashes. For example,
this will always crash:

  my $insane_hash = { foo => "bar" };
  $insane_hash->{baz} = $insane_hash;
  $cx->assign(insane_hash => $insane_hash);

I haven't quite decided if this is a bug or a feature yet... there is
RAM and CPU overhead in tracking self-referencing structures,
so doing so would slow C<JavaScript::Lite> down. If you need to use
them, use the L<JavaScript> module instead, which will let you
bind directly to them instead of copying.

=head1 THANKS

=over

=item Claes Jakobsson

for the original L<JavaScript> module.

=item Miron Cuperman

for creating a situation where I would need to write this.

=item The Chicago Perl Mongers

for hosting YAPC::NA 2008, where this was hacked together.

=back

=head1 LICENSE

This is free software, you may use and distribute it under the
same terms as perl itself.

This software uses mozilla's SpiderMonkey JSAPI for it's
ECMAscript implementation, so in order for it to be useful to you,
you must accept the terms of the mozilla license as well.

=head1 AUTHOR

Tyler "Crackerjack" MacDonald <japh@crackerjack.net>

=head1 SEE ALSO

L<JavaScript>, L<http://developer.mozilla.org/en/docs/SpiderMonkey>

=cut
