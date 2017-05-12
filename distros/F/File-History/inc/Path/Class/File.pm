#line 1
package Path::Class::File;

use strict;
use Path::Class::Dir;
use Path::Class::Entity;
use base qw(Path::Class::Entity);

use IO::File ();

sub new {
  my $self = shift->SUPER::new;
  my $file = pop();
  my @dirs = @_;

  my ($volume, $dirs, $base) = $self->_spec->splitpath($file);
  
  if (length $dirs) {
    push @dirs, $self->_spec->catpath($volume, $dirs, '');
  }
  
  $self->{dir}  = @dirs ? Path::Class::Dir->new(@dirs) : undef;
  $self->{file} = $base;
  
  return $self;
}

sub as_foreign {
  my ($self, $type) = @_;
  local $Path::Class::Foreign = $self->_spec_class($type);
  my $foreign = ref($self)->SUPER::new;
  $foreign->{dir} = $self->{dir}->as_foreign($type) if defined $self->{dir};
  $foreign->{file} = $self->{file};
  return $foreign;
}

sub stringify {
  my $self = shift;
  return $self->{file} unless defined $self->{dir};
  return $self->_spec->catfile($self->{dir}->stringify, $self->{file});
}

sub dir {
  my $self = shift;
  return $self->{dir} if defined $self->{dir};
  return Path::Class::Dir->new($self->_spec->curdir);
}
BEGIN { *parent = \&dir; }

sub volume {
  my $self = shift;
  return '' unless defined $self->{dir};
  return $self->{dir}->volume;
}

sub basename { shift->{file} }
sub open  { IO::File->new(@_) }

sub openr { $_[0]->open('r') or die "Can't read $_[0]: $!"  }
sub openw { $_[0]->open('w') or die "Can't write $_[0]: $!" }

sub touch {
  my $self = shift;
  if (-e $self) {
    my $now = time();
    utime $now, $now, $self;
  } else {
    $self->openw;
  }
}

sub slurp {
  my ($self, %args) = @_;
  my $fh = $self->openr;

  if ($args{chomped} or $args{chomp}) {
    chomp( my @data = <$fh> );
    return wantarray ? @data : join '', @data;
  }

  local $/ unless wantarray;
  return <$fh>;
}

sub remove {
  my $file = shift->stringify;
  return unlink $file unless -e $file; # Sets $! correctly
  1 while unlink $file;
  return not -e $file;
}

1;
__END__

#line 311
