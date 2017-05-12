#line 1
package Path::Class::Dir;

use strict;
use Path::Class::File;
use Path::Class::Entity;
use Carp();
use base qw(Path::Class::Entity);

use IO::Dir ();
use File::Path ();

sub new {
  my $self = shift->SUPER::new();
  my $s = $self->_spec;
  
  my $first = (@_ == 0     ? $s->curdir :
	       $_[0] eq '' ? (shift, $s->rootdir) :
	       shift()
	      );
  
  ($self->{volume}, my $dirs) = $s->splitpath( $s->canonpath($first) , 1);
  $self->{dirs} = [$s->splitdir($s->catdir($dirs, @_))];

  return $self;
}

sub is_dir { 1 }

sub as_foreign {
  my ($self, $type) = @_;

  my $foreign = do {
    local $self->{file_spec_class} = $self->_spec_class($type);
    $self->SUPER::new;
  };
  
  # Clone internal structure
  $foreign->{volume} = $self->{volume};
  my ($u, $fu) = ($self->_spec->updir, $foreign->_spec->updir);
  $foreign->{dirs} = [ map {$_ eq $u ? $fu : $_} @{$self->{dirs}}];
  return $foreign;
}

sub stringify {
  my $self = shift;
  my $s = $self->_spec;
  return $s->catpath($self->{volume},
		     $s->catdir(@{$self->{dirs}}),
		     '');
}

sub volume { shift()->{volume} }

sub file {
  local $Path::Class::Foreign = $_[0]->{file_spec_class} if $_[0]->{file_spec_class};
  return Path::Class::File->new(@_);
}

sub dir_list {
  my $self = shift;
  my $d = $self->{dirs};
  return @$d unless @_;
  
  my $offset = shift;
  if ($offset < 0) { $offset = $#$d + $offset + 1 }
  
  return wantarray ? @$d[$offset .. $#$d] : $d->[$offset] unless @_;
  
  my $length = shift;
  if ($length < 0) { $length = $#$d + $length + 1 - $offset }
  return @$d[$offset .. $length + $offset - 1];
}

sub subdir {
  my $self = shift;
  return $self->new($self, @_);
}

sub parent {
  my $self = shift;
  my $dirs = $self->{dirs};
  my ($curdir, $updir) = ($self->_spec->curdir, $self->_spec->updir);

  if ($self->is_absolute) {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}};
    return $parent;

  } elsif ($self eq $curdir) {
    return $self->new($updir);

  } elsif (!grep {$_ ne $updir} @$dirs) {  # All updirs
    return $self->new($self, $updir); # Add one more

  } elsif (@$dirs == 1) {
    return $self->new($curdir);

  } else {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}};
    return $parent;
  }
}

sub relative {
  # File::Spec->abs2rel before version 3.13 returned the empty string
  # when the two paths were equal - work around it here.
  my $self = shift;
  my $rel = $self->_spec->abs2rel($self->stringify, @_);
  return $self->new( length $rel ? $rel : $self->_spec->curdir );
}

sub open  { IO::Dir->new(@_) }
sub mkpath { File::Path::mkpath(shift()->stringify, @_) }
sub rmtree { File::Path::rmtree(shift()->stringify, @_) }

sub remove {
  rmdir( shift() );
}

sub recurse {
  my $self = shift;
  my %opts = (preorder => 1, depthfirst => 0, @_);
  
  my $callback = $opts{callback}
    or Carp::croak( "Must provide a 'callback' parameter to recurse()" );
  
  my @queue = ($self);
  
  my $visit_entry;
  my $visit_dir = 
    $opts{depthfirst} && $opts{preorder}
    ? sub {
      my $dir = shift;
      $callback->($dir);
      unshift @queue, $dir->children;
    }
    : $opts{preorder}
    ? sub {
      my $dir = shift;
      $callback->($dir);
      push @queue, $dir->children;
    }
    : sub {
      my $dir = shift;
      $visit_entry->($_) foreach $dir->children;
      $callback->($dir);
    };
  
  $visit_entry = sub {
    my $entry = shift;
    if ($entry->is_dir) { $visit_dir->($entry) } # Will call $callback
    else { $callback->($entry) }
  };
  
  while (@queue) {
    $visit_entry->( shift @queue );
  }
}

sub children {
  my ($self, %opts) = @_;
  
  my $dh = $self->open or Carp::croak( "Can't open directory $self: $!" );
  
  my @out;
  while (my $entry = $dh->read) {
    # XXX What's the right cross-platform way to do this?
    next if (!$opts{all} && ($entry eq '.' || $entry eq '..'));
    push @out, $self->file($entry);
    $out[-1] = $self->subdir($entry) if -d $out[-1];
  }
  return @out;
}

sub next {
  my $self = shift;
  unless ($self->{dh}) {
    $self->{dh} = $self->open or Carp::croak( "Can't open directory $self: $!" );
  }
  
  my $next = $self->{dh}->read;
  unless (defined $next) {
    delete $self->{dh};
    return undef;
  }
  
  # Figure out whether it's a file or directory
  my $file = $self->file($next);
  $file = $self->subdir($next) if -d $file;
  return $file;
}

sub subsumes {
  my ($self, $other) = @_;
  die "No second entity given to subsumes()" unless $other;
  
  $other = $self->new($other) unless UNIVERSAL::isa($other, __PACKAGE__);
  $other = $other->dir unless $other->is_dir;
  
  if ($self->is_absolute) {
    $other = $other->absolute;
  } elsif ($other->is_absolute) {
    $self = $self->absolute;
  }

  $self = $self->cleanup;
  $other = $other->cleanup;

  if ($self->volume) {
    return 0 unless $other->volume eq $self->volume;
  }

  # The root dir subsumes everything (but ignore the volume because
  # we've already checked that)
  return 1 if "@{$self->{dirs}}" eq "@{$self->new('')->{dirs}}";
  
  my $i = 0;
  while ($i <= $#{ $self->{dirs} }) {
    return 0 unless exists $other->{dirs}[$i];
    return 0 if $self->{dirs}[$i] ne $other->{dirs}[$i];
    $i++;
  }
  return 1;
}

sub contains {
  my ($self, $other) = @_;
  return !!(-d $self and (-e $other or -l $other) and $self->subsumes($other));
}

1;
__END__

#line 596
