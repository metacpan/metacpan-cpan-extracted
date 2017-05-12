package File::Modified;
$File::Modified::VERSION = '0.10';
use 5.006;
use strict;
use warnings;

our @ISA;

sub new {
  my ($class, %args) = @_;

  my $method = $args{method} || "MD5";
  my $files = $args{files} || [];

  my $self = {
    Defaultmethod => $method,
    Files => {},
  };

  bless $self, $class;

  $self->addfile(@$files);

  return $self;
};

sub _make_digest_signature {
  my ($self,$digest) = @_;

  eval "use Digest::$digest";

  if (! $@) {
    no strict 'refs';
    if (@{"Digest::${digest}::ISA"}) {
      @{"File::Modified::Signature::${digest}::ISA"} = qw(File::Modified::Signature::Digest);
      return 1;
    };
  };
  return undef;
};

sub add {
  my ($self,$filename,$method) = @_;
  $method ||= $self->{Defaultmethod};

  my $signatureclass = "File::Modified::Signature::$method";
  my $s = eval { $signatureclass->new($filename) };
  if (! $@) {
    return $self->{Files}->{$filename} = $s;
  } else {
    # retry and try Digest::$method

    if ($self->_make_digest_signature($method)) {
      my $s = $signatureclass->new($filename);
      return $self->{Files}->{$filename} = $s;
    } else {
      return undef;
    };
  };
};

sub addfile {
  my ($self,@files) = @_;

  my @result;

  # We only return something if the caller wants it
  if (defined wantarray) {
    push @result, $self->add($_) for @files;
    return @result;
  } else {
    $self->add($_) for @files;
  };
};

sub update {
  my ($self) = @_;

  $_->initialize() for values %{$self->{Files}};
};

sub changed {
  my ($self) = @_;

  return map {$_->{Filename}} grep {$_->changed()} (values %{$self->{Files}});
};

1;

{
  package File::Modified::Signature;
$File::Modified::Signature::VERSION = '0.10';
  # This is a case where Python would be nicer. With Python, we could have (paraphrased)
  # class File::Modified::Signature;
  #       def initialize(self):
  #           self.hash = self.identificate()
  #           return self
  #       def signature(self):
  #           return MD5(self.filename)
  #       def changed(self):
  #           return self.hash != self.signature()
  # and it would work as expected, (almost) regardless of the structure that is returned
  # by self.signature(). This is some DWIMmery that I sometimes miss in Perl.
  # For now, only string comparisions are allowed.

  sub create {
    my ($class,$filename,$signature) = @_;

    my $self = {
      Filename => $filename,
      Signature => $signature,
    };

    bless $self, $class;
  };

  sub new {
    my ($class,$filename) = @_;

    my $self = $class->create($filename);
    $self->initialize();

    return $self;
  };

  sub initialize {
    my ($self) = @_;
    $self->{Signature} = $self->signature();
    return $self;
  };

  sub from_scalar {
    my ($baseclass,$scalar) = @_;
    die "Strange value in from_scalar: $scalar\n" unless $scalar =~ /^([^|]+)\|([^|]+)\|(.+)$/;
    my ($class,$filename,$signature) = ($1,$2,$3);
    return $class->create($filename,$signature);
  };

  sub as_scalar {
    my ($self) = @_;
    return ref($self) . "|" . $self->{Filename} . "|" . $self->{Signature};
  };

  sub changed {
    my ($self) = @_;
    my $currsig = $self->signature();

    # FIXME: Deep comparision of the two signatures instead of equality !
    # And what's this about string comparisions anyway ?
    if ((ref $currsig) or (ref $self->{Signature})) {
      die "Implementation error in $self : changed() can't handle references and complex structures (yet) !\n";
      #return $currsig != $self->{Signature};
    } else {
      return $currsig ne $self->{Signature};
    };
  };
};

{
  package File::Modified::Signature::mtime;
$File::Modified::Signature::mtime::VERSION = '0.10';
use base 'File::Modified::Signature';

  sub signature {
    my ($self) = @_;

    my @stat = stat $self->{Filename} or die "Couldn't stat '$self->{Filename}' : $!";

    return $stat[9];
  };
};

{
  package File::Modified::Signature::Checksum;
$File::Modified::Signature::Checksum::VERSION = '0.10';
use base 'File::Modified::Signature';

  sub signature {
    my ($self) = @_;
    my $result;
    if (-e $self->{Filename} and -r $self->{Filename}) {
      local *F;
      open F, $self->{Filename} or die "Couldn't read from file '$self->{Filename}' : $!";
      binmode F;

      my $buf;
      while (read(F,$buf,32768)) {
        $result += unpack("%32C*", $buf);
        $result %= 0xFFFFFFFF;
      };

      close F;
    };
    return $result;
  };
};

{
  package File::Modified::Signature::Digest;
$File::Modified::Signature::Digest::VERSION = '0.10';
use base 'File::Modified::Signature';

  sub digestname {
    my ($class) = @_;
    $class = ref $class || $class;
    return $1 if ($class =~ /^File::Modified::Signature::([^:]+)$/);
  };

  sub digest {
    my ($self) = @_;
    if (! exists $self->{Digest}) {
      my $digestclass = "Digest::" . $self->digestname;
      eval "use $digestclass";
      $self->{Digest} = $digestclass->new();
    };
    return $self->{Digest};
  };

  sub signature {
    my ($self) = @_;
    my $result;
    if (-e $self->{Filename} and -r $self->{Filename}) {
      local *F;
      open F, $self->{Filename} or die "Couldn't read from file '$self->{Filename}' : $!";
      binmode F;
      $result = $self->digest->addfile(*F)->b64digest();
      close F;
    };
    return $result;
  };
};

1;

__END__

=head1 NAME

File::Modified - checks intelligently if files have changed

=head1 SYNOPSIS

  use strict;
  use File::Modified;

  my $d = File::Modified->new(files=>['Import.cfg','Export.cfg']);

  while (1) {
    my (@changes) = $d->changed;

    if (@changes) {
      print "$_ was changed\n" for @changes;
      $d->update();
    };
    sleep 60;
  };

Second example - a script that knows when any of its modules have changed :

  use File::Modified;
  my $files = File::Modified->new(files=>[values %INC, $0]);

  # We want to restart when any module was changed
  exec $0, @ARGV if $files->changed();

=head1 DESCRIPTION

This module provides a simple mechanism for identifying when the contents
of one or more files have changed.
It was initially intended for programs to detect when their configuration
files (or the module they rely on) have changed.

There are currently two methods of change detection implemented,
C<mtime> and C<MD5>.
The C<MD5> method will fall back to use timestamps if the C<Digest::MD5> module
cannot be loaded.

There are a number of other modules on CPAN that provide
similar functionality;
they are listed in L</"SEE ALSO"> below.

=over 4

=item new %ARGS

Creates a new instance. The C<%ARGS> hash has two possible keys,
C<Method>, which denotes the method used for checking as default,
and C<Files>, which takes an array reference to the filenames to
watch.

=item add filename, method

Adds a new file to watch. C<method> is the method (or rather, the
subclass of C<File::Modified::Signature>) to use to determine whether
a file has changed or not. The result is either the C<File::Modified::Signature>
subclass or undef if an error occurred.

=item addfile LIST

Adds a list of files to watch. The method used for watching is the
default method as set in the constructor. The result is a list
of C<File::Modified::Signature> subclasses.

=item update

Updates all signatures to the current state. All pending changes
are discarded.

=item changed

Returns a list of the filenames whose files did change since
the construction or the last call to C<update> (whichever last
occurred).

=back

=head2 Signatures

The module also creates a new namespace C<File::Signature>, which sometime
will evolve into its own module in its own file. A file signature is most
likely of little interest to you; the only time you might want to access
the signature directly is to store the signature in a file for persistence
and easy comparision whether an index database is current with the actual data.

The interface is settled, there are two methods, C<as_scalar> and C<from_scalar>,
that you use to freeze and thaw the signatures. The implementation of these methods
is very frugal, there are no provisions made against filenames that contain weird
characters like C<\n> or C<|> (the pipe bar), both will be likely to mess up your
one-line-per-file database. An interesting method could be to URL-encode all filenames,
but I will visit this topic in the next release. Also, complex (that is, non-scalar)
signatures are handled rather ungraceful at the moment.

Currently, I'm planning to use L<Text::Quote> as a quoting mechanism to protect against
multiline filenames.

=head2 Adding new methods for signatures

Adding a new signature method is as simple as creating a new subclass
of C<File::Signature>. See C<File::Signature::Checksum> for a simple
example. There is one point of laziness in the implementation of C<File::Signature>,
the C<check> method can only compare strings instead of arbitrary structures (yes,
there ARE things that are easier in Python than in Perl). C<File::Signature::Digest>
is a wrapper for Gisle Aas' L<Digest> module and allows you to use any module below
the C<Digest> namespace as a signature, for example C<File::Signature::MD5> and
C<File::Signature::SHA1>.

=head2 TODO

* Make the simple persistence solution for the signatures better using L<Text::Quote>.

* Allow complex structures for the signatures.

* Document C<File::Modified::Signature> or put it down into another namespace.

* Extract the C<File::Modified::Signature> subclasses out into their own file.

* Create an easy option to watch a whole directory tree.

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<File::Monitor> will watch a file or directory,
invoking a callback when it changes.

L<File::Monitor::Lite> is similar to File::Monitor, but can also
let you know about new files being created.

L<File::Monitor::Simple> watches a directory for changes to any files
whose name matches a regular expression.

L<File::IfModified> provides a function that can be used to check
whether a file has been modified since the last time you checked.

L<File::ChangeNotify> provides an API for watching all files in
a given directory. It provides several mechanisms for doing this,
and a base-class that you can subclass to write your own watcher.

L<File::Signature> provides some lower-level functions than
File::Modified, which are used to identify whether a file has
changed by comparing its MD5 digest with an earlier snapshot.

L<File::Stat::Trigger> will invoke one of your callbacks if
the C<stat()> details of a file change.

L<Win32::FileSystem::Watcher> provides a Windows-specific
solution for watching for changes to a filesystem.
The documentation is extremely limited, so I can't tell if you
can limit it a specific directory.

L<App::watcher> comes with a script that will run a command if
any of the files in a directory are changed.

L<IO::Async::File> watches an open filehandle or 'named filesystem entity'
for changes in its C<stat()> fields.

L<POE::Component::DirWatch> watches a directory for new files or directories,
invoking a user-supplied callback function when one is seen.

L<WWW::Monitor> is similar to File::Monitor,
but checks URLs rather than files.

=head1 REPOSITORY

L<https://github.com/neilb/File-Modified>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

Copyright (C) 2002 Max Maischein

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

Please contact me if you find bugs or otherwise improve the module.
More tests are also very welcome !

=cut
