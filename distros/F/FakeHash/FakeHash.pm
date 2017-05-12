
=head1 NAME

FakeHash - Simulate the behavior of a Perl hash variable

=head1 SYNOPSIS

	use FakeHash;
	my $hash = FakeHash->new;
	$hash->store($key, $value);     # analogous to $h{$key} = $value
	@keys = $hash->keys;            # analogous to @keys = keys %h
	$hash->delete($key);		# analogous to delete $h{$key}
	$value = $hash->fetch($key);    # analogous to $value = $h{$key}
	$string = $hash->scalarval;     # analogous to $string = %h
	$string = $hash->clear;         # analogous to %h = ()

	$hash->iterate(...);            # Invoke callbacks for each bucket and node
	
        # Caution: Not tested
	my $hash = tie %h => FakeHash;  # $hash will mirror the changes to %h

	use FakeHash 'hashval';
	$n = hashval($string);          # hash value for string

	FakeHash->version(5.005);       # Use Perl 5.005 hashval function
	$version = FakeHash->version;   # Return Perl version currently in force

=head1 DESCRIPTION

C<FakeHash> simulates the behavior of a Perl hash variable,
maintaining a synthetic data structure that mirrors the true data
structure inside of Perl.  This can be used to investigate hash
performance or behavior.  For example, see the C<FakeHash::DrawHash>
class, described below, which draws a box-and-arrow diagram
representing the memory layout of a hash.

The C<store>, C<fetch>, C<keys>, and C<delete> methods perform the
corresponding operations on the simulated hash.

The C<iterate> method iterates over the simulated structure and
invokes user-supplied callbacks.  The arguments to C<iterate> are a
hash of I<actions>, and an optional I<user parameter>.

The C<actions> hash may have any or all of the following keys:

=over

=item B<prebucket>

A function that is called once for each bucket in the hash, prior to
iterating over the nodes in the bucket.  The arguments to the
C<prebucket> function are: the bucket number; a C<FakeHash::Node>
object representing the first node in the bucket (or an undefined
value of the bucket is empty,) and the user parameter.

=item B<prebucket>

The same, except that the function is called after iterating over the
nodes in the bucket.

=item B<node>

A function that is called once for each node (key-value pair) in the
hash.  The node function is called for a node after the C<prebucket>
function and before the C<postbucket> function is called for the
node's bucket.

The arguments to the C<node> function are: The bucket number; a
C<FakeHash::Node> object representing the first node in the bucket;
the node's number within the bucket (0 for the first node in the
bucket); the node itself; and the user parameter.

=item B<maxbucket>

If this is a number, say I<n>, C<iterate> will only iterate over the
first I<n> buckets, and will skip the later buckets and their
contents.  If this is a function, C<iterate> will call it once, with
the user paramater as its argument, and will expect it to return a
number I<n> to be used as above.  If it is omitted, C<iterate> will
iterate over all buckets and their contents.

=back

For example, the C<keys> method is implemented as a call to C<iterate>, as follows:

	sub keys {
	  my $self = shift;
	  my @r;
	  $self->iterate({node => sub { my ($i, $b, $n, $node) = @_;
	                                push @r, $node->key;
	                              },
	                 });
	  @r;
	}

=head2 Other Methods

C<FakeHash-E<gt>DEBUG> will return the current setting of the C<DEBUG>
flag, and will change the value of the flag if given an argument.
When the C<DEBUG> flag is set to a true value, the module may emit
diagnostic messages to C<STDERR>.

Each C<FakeHash> object may carry auxiliary information.  Auxiliary
information is not used by C<FakeHash> but may be used by subclasses.
C<$hash-E<gt>set_defaults(key, value, key, value,...)> sets the
specified auxiliariy data values for the C<FakeHash> object.  A
hashref may be passed instead; its contents will be appended to the
values already installed.  To query the currently-set values, use
C<$hash-E<gt>defaults(key, key, ...)>, which will return a list of the
corresponding values, or, in scalar context, a reference to an array
of the corresponding values.

C<$hash-E<gt>size> retrieves the number of buckets in the
hash.

The Perl hash function changed between versions 5.005 and 5.6, so the
behavior of Perl hashes changed at the same time.  By default,
C<FakeHash> will emulate the behavior of whatever version of Perl it
is running under.  To change this, use the C<version> method.  Its
argument is the version of Perl that you would like to emulate.  It
returns the version number prior to setting.

=cut

package FakeHash;
$VERSION = '0.80';
use strict 'vars', 'refs';
sub croak;

my $DEBUG = 0;
my $VERSION = $];
my $INIT_SIZE = 8;  # Do not touch

sub import {
  my $caller = caller;
  my $class = shift;
  for (@_) {
    unless ($_ eq 'hashval') {
      croak "$_ not exported by FakeHash";
    }
    no strict 'refs';
    *{"$caller\::$_"} = \&{"$class\::$_"};
  }
}

# I am a constant-like subroutine *and* a class method
sub DEBUG {
  shift;                        # class name
  my $old_debug = $DEBUG;
  $DEBUG = shift if @_;
  $old_debug;
}

sub version {
  shift;                        # class name
  my $old_version = $VERSION;
  $VERSION = shift if @_;
  $old_version;
}

sub new {
  my $self = { B => [(undef) x $INIT_SIZE], 
               K => 0, 
               S => $INIT_SIZE,
               D => {},
             };
  bless $self, shift();
}

sub set_defaults {
  my $self = shift;
  my $kvps;
  if (@_ == 1) {
    $kvps = shift;
  } elsif (@_ % 2 == 0) {
    my %kvps = @_;
    $kvps = \%kvps;
  } else {
    croak "usage: \$fakehash->default(\$hashref) or \$fakehash->default(key, val, ...)";
  }
  while (my ($k => $v) = each %$kvps) {
    $self->{D}{$k} = $v;
  }
}

sub defaults {
  my ($self) = shift;
  my @r ;
  for (@_) {
    push @r, $self->{D}{$_};
  }
  wantarray ? @r : \@r;
}

sub TIEHASH {
  my ($pack) = @_;
  $pack->new();
}

sub FETCH {
  my ($self, $k) = @_;
  $self->fetch($k);
}

sub STORE {
  my ($self, $k, $v) = @_;
  $self->store($k, $v);
}

sub DELETE {
  my ($self, $k) = @_;
  $self->delete($k);
}

sub CLEAR {
  my ($self) = @_;
  $self->clear();
}

sub scalarval {
  my ($self) = @_;
  my $n = grep defined, @{$self->{B}};
  my $d = $self->size;
  "$n/$d";
}

sub size {
  my $self = shift;
  my $old_size = $self->{S};
  if (@_) {
    $self->{S} = round_up(shift());
    $#{$self->{B}} = $self->{S} - 1;
  }
  $old_size;
}


sub iterate {
  my ($self, $actions, $u) = @_;
  my $s = $actions->{maxbucket};
  if (ref $s) {
    $s = $s->($u);
  } elsif (! defined $s) {
    $s = $self->size;
  }
  for (my $i=0;
       $i < $s;
       $i++) {
    my $b = $self->_bucket($i);
    $actions->{prebucket}->($i, $b, $u) if exists $actions->{prebucket};
    my $nodeno = 0;
    for (my $node = $b;
         $node;
         $node = $node->next) {
      $actions->{node}->($i, $b, $nodeno++, $node, $u) if exists $actions->{node};
    }
    $actions->{postbucket}->($i, $b, $nodeno, $u) if exists $actions->{postbucket};
  }
}

sub store {
  my ($self, $key, $value) = @_;
  my $hash = hashval($key);
  my $bucket = $hash % $self->size;
  $self->h_insert_h($key, $value, $hash, $bucket);
}

sub h_insert_h {
  my ($self, $key, $value, $hash, $bucket) = @_;
  if (my $node = $self->_search_bucket($bucket, $key, $hash)) {
    $node->value($value);
  } else {
    my $head_node = $self->_bucket($bucket);
    $self->_append_bucket($bucket, FakeHash::Node->new($key, $value, $hash));
    ++$self->{K};  ## MOVE ME
    $self->double_size() if $self->is_full && ! $head_node;
  }
}

sub keys {
  my $self = shift;
  my @r;
  $self->iterate({node => sub { my ($i, $b, $n, $node) = @_;
                                push @r, $node->key;
                              },
                 });
  @r;
}

sub is_full {
  my $self = shift;
  $self->{K} >= $self->{S};
}


sub clone {
  my $self = shift;
  my $new = (ref $self)->new;
  $new->{S} = $self->{S};
  $new->{K} = $self->{K};
  $new->{B} = [@{$self->{B}}];
  bless $new => (ref $self);
}

sub double_size {
  my ($self) = @_;
  my $os = $self->size;
  my $ns = $os * 2;
  print STDERR "Reconstructing from $os -> $ns\n" if DEBUG
  $self->size($ns);

  # copied and translated from 5.6.0 hv.c:892 ff
  for (my $i=0; $i< $os; $i++) {
    print STDERR "Bucket #$i:\n" if DEBUG;
    my $prev;
    for (my $entry = $self->_bucket($i); 
         $entry; 
         $entry = $prev ? $prev->next : $self->_bucket($i)) {
      print STDERR "  entry($entry->[0])\n" if DEBUG;
      my $hash = $entry->hash;
      print STDERR "  hash = $hash, ", "lowbits = ", $hash & ($ns-1), "\n" 
        if DEBUG;
      if (($hash & ($ns - 1)) != $i) { # $entry needs to move
        print STDERR " RELOCATING\n" if DEBUG;

        # fix pointer that was *to* $entry
        if ($prev) {
          $prev->next($entry->next);
        } else {
          $self->_bucket($i, $entry->next);
        }
        
        # fix pointer *from* $entry
        # and insert $entry at beginning of bucket b
        $entry->next($self->_bucket($i + $os)); 
        $self->_bucket($i + $os, $entry);
      } else {
        $prev = $entry;
      }
    }
  }
}

sub clear {
  my $self = shift;
  my $size = $self->size;
  @{$self->{B}} = (undef) x $size;
}

sub _search_bucket {
  my ($self, $b, $k, $h) = @_;
  for (my $node = $self->_bucket($b);
       $node;
       $node = $node->next) {
    return $node if $h == $node->hash && $k eq $node->key;
  }
  return;
}

sub _append_bucket {
  my ($self, $b, $node) = @_;
  $node->next($self->_bucket($b));
  $self->_bucket($b, $node);
}

sub _bucket {
  my ($self, $b, $new) = @_;
  my $old = $self->{B}[$b];
  $self->{B}[$b] = $new if @_ > 2;
  $old;
}

sub delete {
  my ($self, $key) = @_;
  my $h = hashval($key);
  my $s = $self->size;
  my $b = $h & ($s-1);
  my ($prev, $cur);
  for ($cur = $self->_bucket($b);
       $cur;
       $prev = $cur, $cur = $cur->next) {
    next unless $cur->hash == $h && $cur->key eq $key;
    if ($prev) {
      $prev->next($cur->next);
    } else {
      $self->_bucket($b, $cur->next);
    }
  }
}

sub fetch {
  my ($self, $key) = @_;
  my $h = hashval($key);
  my $s = $self->size;
  my $b = $self->_bucket($h & ($s-1));
  $self->_search_bucket($b, $key, $h);
}

sub clear {
  my $self = shift;
  %$self = %{$self->new};
}

sub croak {
  require Carp;
  Carp::croak(@_);
}

# thanks to I0 from perlmonks for this
# extremely clever solution
sub round_up {
  my $x = shift;
  return $x unless $x & ($x-1);
  for (1, 2, 4, 8, 16) {
    $x |= $x >> $_;
  }
  ++$x;
}

# sub round_up {
#   my $z = my $x = shift;
#   return $x unless $x & ($x-1);
#   while ($x) {
#     $z = $x;
#     $x &= $x-1;
#   }
#   $z<<1;
# }

sub _B32 () { 2**32 - 1}  # constant

# i am not a method
sub hashval {
  use integer;
  my ($string) = @_;
  my $h = 0;
  for my $c (split //, $string) {
    $h = ($h * 33 + ord($c));
  }
  $h += $h >> 5 if $VERSION >= 5.006;
#  print STDERR "HASH $string => $h ($VERSION)\n";
  return $h;
}


=head1 NAME

FakeHash::DrawHash - Draw a C<pic> diagram of the internal structure of a hash

=head1 SYNOPSIS

        my $hash = FakeHash::DrawHash->new;
        
        # see L<FakeHash> for more details

        $hash->draw($filehandle);  #  Print 'pic' commands to filehandle

=head1 DESCRIPTION

C<FakeHash::DrawHash> is a subclass of C<FakeHash> that can draw a
picture of the internal structure of a Perl hash variable.  It emits
code suitable for the Unix C<pic> drawing program.

C<FakeHash::DrawHash> provides the following methods:

=head2 draw

Emit C<pic> code for a box-and-arrow diagram that represents the
current state of the simulated hash.  A filehandle argument may be
provided to receive the output.  If omitted, output goes to C<STDOUT>.
Additionally, a user parameter argument may be provided, which will be
passed to the other C<draw_*> methods.

=head2 draw_param

Set or retrieve various parameters dermining box size and layout.
Takes a name and an optional value argument and returns the old value
associated with the name.  If the value is provided, sets the new
value.  Valid names are:

=over 4

=item B<BUCKET>

Determines the size of the boxes used to represent each hash bucket.
The value should be a reference to an array of the height and width,
in inches.

Defaults to C<[1, 0.55]>, or one inch wide by 0.55 inches tall.

=item B<BUCKETSPACE>

Amount of horizontal space,in inches, between the box that represents
a bucket and the bixes that represent the bucket contents.  If zero,
the buckets will abut their contents.

Defaults to 1/5 inch.

=item B<KVP>

The size of the boxes used to represent each key-value node.  The
value should be a reference to an array of the height and width, in
inches.

Defaults to C<[1, 0.5]>, or one inch wide by half an inch tall.

=back 

=head2 draw_start

Called once, each time drawing commences.  Arguments: The filehandle
and user parameter, if any, that were passed to C<draw>.

=head2 draw_end

Called once, just at the end of each call to C<draw>.  Arguments: The
filehandle and user parameter, if any, that were passed to C<draw>.

=head2 draw_bucket

Called each time C<draw> needs to draw a single bucket.  

Arguments: The filehandle that was passed to C<draw>; the bucket
number (starting from 0) of the current bucket; a boolean value which
is true if and only if the bucket is nonempty; and the user parameter
that was passed to C<draw>.

=head2 draw_node

Called each time C<draw> needs to draw a single key-value node.  

Arguments: The filehandle that was passed to C<draw>; the bucket
number (starting from 0) of the bucket in which the current node
resides; the number of the node in the current bucket (the first node
is node zero); a C<FakeHash::Node> object representing the node
itself; and the user parameter that was passed to C<draw>.

=head1 IDEA

The theory here is that it should be easy to override these methods
with corresponding methods that draw the diagram in PostScript or GD
or whatever.

If you do this, please send me the code so that I can distribute it.

=cut

package FakeHash::DrawHash;

BEGIN { @FakeHash::DrawHash::ISA = 'FakeHash' }

my %defaults = ( BUCKET => [1, 0.55],
                 KVP => [1, 0.5],
                 BUCKETSPACE => 0.2,
               );

sub new {
  my $class = shift;
  my $self = $class->SUPER::new(@_);
  $self->set_defaults(\%defaults);
  $self;
}

sub draw_param {
  my ($self, $key, $value) = @_;
  my ($old) = $self->defaults($key);

  if (defined $value) {
    $self->set_defaults($key, $value);
  } 

  $old;
}

sub draw {
  my ($self, $fh, $u) = @_;
  local *FH;
  if (! defined $fh) {
    $fh = \*STDOUT;
  } elsif (! defined fileno $fh) {
    FakeHash::croak "Couldn't open file $fh" unless open FH, "< $fh";
    $fh = \*FH;
  }
    
  $self->draw_start($fh, $u);
  $self->iterate({ prebucket => sub {
                     my ($b, $bucket) = @_;
                     $self->draw_bucket($fh, $b, defined $bucket, $u);
                   },
                   node => sub {
                     my ($b, $bucket, $n, $node) = @_;
                     $self->draw_node($fh, $b, $n, $node, $u);
                   },
                 });
  $self->draw_end($fh, $u);
}

sub draw_bucket {
  my ($self, $fh, $bucket_no, $nonempty) = @_;
  my ($wd, $ht) = @{$self->draw_param('BUCKET')};
  my $bs = $self->draw_param('BUCKETSPACE');
  print $fh "boxwid:=$wd; boxht:=$ht\n";
  printf $fh "B%02d: box ", $bucket_no;
  printf $fh "with .n at B%02d.s", $bucket_no-1 if $bucket_no > 0;
  printf $fh "\n";
  if ($nonempty) {
    printf $fh "circle at B%02d.c rad 0.1 filled\n", $bucket_no;
    printf $fh "arrow from B%02d.c right boxwid/2 + $bs\n", $bucket_no;
  }
}

# this method assumes that the current 'pic' position is already 
# correct, which might not be true if one of the other methods is
# overriden.  Fix it.
sub draw_node {
  my ($self, $fh, $bucket_no, $node_index, $node) = @_;
  my ($k, $v, $h, $next) = @$node;
  my ($wd, $ht) = @{$self->draw_param('KVP')};
  print $fh "boxwid:=$wd; boxht:=$ht\n";
  printf $fh qq{N%02d%02d: box "%s" "%s" "%u(%u)"\n}, $bucket_no, $node_index, $k, $v, $h, $h&($self->size * 2  - 1);
}

sub draw_start {
  my ($self, $fh) = @_;
  print $fh ".PS\n";
}

sub draw_end {
  my ($self, $fh) = @_;
  print $fh ".PE\n";
}


=head1 NAME

FakeHash::Node - Class used internally by C<FakeHash> to represent key-value pairs

=head1 SYNOPSIS

        $key   = $node->key;
        $value = $node->value;
        $hash  = $node->hash;
        $next  = $node->next;

=head1 DESCRIPTION

C<FakeHash::Node> is used internally by C<FakeHash> for various
purposes.  For example, the C<FakeHash::iterate> function invokes a
user-supplied callback for each key-value pair, passing it a series of
C<FakeHash::Node> objects that represent the key-value pairs.

The C<key> and C<value> methods retrieve the key and value of a node.
The C<hash> method retrieves the key's hash value.  

C<$node-E<gt>next> method retrieves the node that follows C<$node> in
its bucket, or an undefined value if C<$node> is last in its bucket.

If any of these methods is passed an additional argument, it will set
the corresponding value.  It will return the old value in any case.

=cut

package FakeHash::Node;

sub new {
  my ($class, @data) = @_;
  bless \@data => $class;
}

sub _access {
  my $self = shift;
  my $index = shift;
  my $oldval = $self->[$index];
  $self->[$index] = shift if @_;
  $oldval;
}

sub key {
  my $self = shift;
  $self->_access(0, @_);
}

sub value {
  my $self = shift;
  $self->_access(1, @_);
}

sub hash {
  my $self = shift;
  $self->_access(2, @_);
}

sub next {
  my $self = shift;
  $self->_access(3, @_);
}

1;

=head1 AUTHOR

Mark-Jason Dominus (C<mjd-perl-fakehash+@plover.com>)

=head1 COPYRIGHT

C<FakeHash.pm> is a Perl module that simulates the behavior of a Perl hash
variable.  C<FakeHash::DrawHash> renders a diagram of a simulated hash.

Copyright (C) 200 Mark-Jason Dominus

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 2 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc., 675
Mass Ave, Cambridge, MA 02139, USA.

=cut
