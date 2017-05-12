# (X)Emacs mode: -*- cperl -*-

package File::Info;

=head1 NAME

File::Info - Store file information persistently for fast lookup

=head1 SYNOPSIS

  use File::Info qw( $PACKAGE $VERSION );

  my $info = File::Info->new($dir);
  # $fn is "basename"; contains no directory portion
  my $hex  = $info->md5hex($fn);  # Reads cached data if possible

=head1 DESCRIPTION

This package stores per-file information for speedy lookup later.  It is
intended to store file info that takes a significant time to determine ---
e.g., the MD5 sum of a large file, to avoid uneccessarily recalculation.  This
may be particularly helpful for searching across many files for some specific
property.

File statistics are recalculated on demand.  If the file size or modification
time have changed since the calculations were last made, then they will be
purged and recalculated.

File information is stored on a per-directory basis.  Each file info file is
stored in a directory; the files to which it refers are in the same directory,
and are referred as names without paths.

=cut

# ----------------------------------------------------------------------------

# Pragmas -----------------------------

use 5.005_62;
use strict;
use warnings;
use warnings::register;

# Inheritance -------------------------

use constant _TYPE_NAMES => qw( TYPE_JPEG TYPE_PAR TYPE_UNKNOWN );
use base qw( Exporter );
our @EXPORT_OK = (qw( $PACKAGE $VERSION ), _TYPE_NAMES);
our %EXPORT_TAGS = (
                    types => [_TYPE_NAMES],
                   );

# Utility -----------------------------

use Fcntl                  1.03 qw( O_CREAT O_RDWR );
use File::Basename          2.6 qw( );
use File::Spec             0.82 qw( );
use MLDBM                  2.00 qw( DB_File Storable );
use Storable              1.014 qw( );

# ----------------------------------------------------------------------------

# CLASS METHODS --------------------------------------------------------------

# -------------------------------------
# CLASS CONSTANTS
# -------------------------------------

=head1 CLASS CONSTANTS

Z<>

=cut

=head2 TYPE_CONSTANTS

As returned by the L<type|"type"> method.  These constants are exported by
request, either individually, or together with the ':types' tag.

=over 4

=item TYPE_UNKNOWN

File type not identified

=item TYPE_JPEG

A 'JPEG' image file.

=item TYPE_PAR

A 'par' (parity archive) file.

=back

=cut

use constant TYPE_JPEG    => 'jpeg';
use constant TYPE_PAR     => 'par';
use constant TYPE_UNKNOWN => 'unknown';

# -------------------------------------

use constant MD5HEX_TEMPLATE => '%02x' x 16;
use constant MD5BIN_TEMPLATE => 'C16';
use constant FILENAME        => '.fileinfo';
use constant FORBIDDEN_NAMES => { map { $_ => 1 }
                                  qw( add_local_lookup add_global_lookup
                                      isa import new dirname ) };
use constant S16K            => 2 ** 14;

# -------------------------------------

our $PACKAGE = 'File-Info';
our $VERSION = '1.02';

# -------------------------------------
# CLASS CONSTRUCTION
# -------------------------------------

# -------------------------------------
# CLASS COMPONENTS
# -------------------------------------

=head1 CLASS COMPONENTS

Z<>

=cut

my %local_names;

# -------------------------------------
# CLASS HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 CLASS HIGHER-LEVEL FUNCTIONS

Z<>

=cut

my $digestive;
sub _MD5 {
  my ($fn) = @_;

  unless ( defined $digestive ) {
    eval "use Digest::MD5 2.00 qw( )";
    croak $@ if $@;
    $digestive = Digest::MD5->new;
  }
  open my $fh, '<', $fn
    or Carp::croak "Failed to open $fn: $!\n";
  my $md5 = $digestive->addfile($fh)->digest;
  close $fh
    or Carp::croak "Failed to close $fn after copying: $!\n";
  return $md5;
}

# -------------------------------------

sub _MD5_16K {
  my ($fn) = @_;

  unless ( defined $digestive ) {
    eval "use Digest::MD5 2.00 qw( )";
    croak $@ if $@;
    $digestive = Digest::MD5->new;
  }

  open my $fh, '<', $fn
    or Carp::croak "Failed to open $fn: $!\n";
  my $buffy = "\0" x S16K;
  read $fh, $buffy, S16K;
  my $md5 = $digestive->add($buffy)->digest;
  close $fh
    or Carp::croak "Failed to close $fn after copying: $!\n";
  return $md5;
}

# -------------------------------------

sub _LINE_COUNT {
  my ($fn) = @_;
  open my $fh, '<', $fn
    or Carp::croak "Failed to open $fn: $!\n";
  local $/ = \65536;
  my $count = 0;
  while (<$fh>) {
    $count += tr/\n/\n/;
  }
  close $fh
    or Carp::croak "Failed to close $fn after copying: $!\n";
  return $count;
}

# -------------------------------------

sub _TYPE {
  my ($fn) = @_;

  my $type = TYPE_UNKNOWN;

  open my $fh, '<', $fn
    or Carp::croak "Failed to open $fn: $!\n";
  my $buffy = "\0" x 8;
  read $fh, $buffy, 8;
  if ( $buffy eq "PAR\0\0\0\0\0" ) {
    $type = TYPE_PAR;
  } elsif ( unpack('n', substr($buffy, 0, 2)) eq 0xffd8 ) {
    $type = TYPE_JPEG;
  }
  close $fh
    or Carp::croak "Failed to close $fn after copying: $!\n";

  return $type;
}

# -------------------------------------

sub _PAR_SET_HASH {
  my ($fn) = @_;

  if ( defined $Archive::Par::VERSION ) {
    Carp::croak "Archive::Par version 1.52 or above required\n"
      unless $Archive::Par::VERSION >= 1.52;
  } else {
    eval "use Archive::Par 1.52 qw( )";
    croak $@ if $@;
  }

  my $par = Archive::Par->new($fn);
  return $par->set_hash;
}

# -------------------------------------
# CLASS HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 CLASS HIGHER-LEVEL PROCEDURES

Z<>

=cut

# -------------------------------------

=head2 add_global_lookup

Add a lookup function to the.  A method with the same name will be created, to
provide the cached lookup.

=over 4

=item ARGUMENTS

=over 4

=item name

The name may consist only of letters, digits, and underscore characters.  The
first character must be a letter, and at least one digit or lower-case must be
present.

builtin names will always be lower-case.  If you stick to this, then you will
need to make no change if your identifier should get absorbed into the core.
On the other hand, if you use some upper-case letters (e.g., StudlyCaps), then
you are assured that you will never clash will internal names.

These other names are reserved:

  add_local_lookup add_global_lookup isa import new dirname

=item code

The code to call to calculate the value.  The code will be passed the absolute
name of the file to lookup, and is expected to return a suitable value.  The
value will be cached.

=back

=back

=cut

sub add_global_lookup {
  my $class = shift;
  my ($name, $code) = @_;

  Carp::croak
      "Lookup name $name must contain only alphanumerics and underscores\n"
    if $name =~ /[^A-Za-z0-9_]/;
  Carp::croak "Lookup name must begin with a letter\n"
    if $name !~ /^[A-Za-z]/;
  Carp::croak
      "Lookup name must contain at least one lowercase number or digit\n"
    unless $name =~ /[a-z0-9]/;

  Carp::croak "Name reserved: $name\n"
    if exists FORBIDDEN_NAMES->{$name};

  warnings::warnif("Name $name already in use; will supercede\n")
      if $class->can($name);

  my $subrname1 = join '::', $class, '_' . uc $name;
  my $subrname2 = join '::', $class, $name;
  {
    no strict 'refs';
    *{$subrname1} = $code;
  }
  $class->_make_class_ready($name, sub {$_[0]->_value($_[1], $name)});
}

# -------------------------------------

sub _make_class_ready {
  my $class = shift;
  my ($subrname, $subr) = @_;

  {
    no strict 'refs';
    if ( ! defined $subr ) {
      $subr = *{"${class}::${subrname}"}{CODE}
        or Carp::croak "Cannot locate subroutine $subrname in class $class\n";
    }

    no warnings 'redefine';

    my $file = __FILE__;
    my $warnhook = $SIG{__WARN__};
    my %redef_subr;

    local $SIG{__WARN__} = sub {
      # Nasty hack to avoid irritating mandatory redefine warnings bug
      return
        if ( ( $_[0] =~ /^Subroutine ([:\w]+) redefined at $file/ ) and 
             ( exists $redef_subr{$1} or 
               ( index($1,':') == -1 and exists $redef_subr{"main::$1"} )
             ) );
      my $message = join '', grep defined, @_;
      $warnhook->(@_)
        if defined $warnhook and UNIVERSAL::isa($warnhook, 'CODE');
    };

    $redef_subr{$subrname} = 1;
    *{"${class}::${subrname}"} =
      sub {
        if ( ref $_[0] ) {
          $_[0]->$subr(@_[1..$#_]);
        } else {
          Carp::croak
              (sprintf
               "File name (%s) must be absolute in class method call %s\n",
               $_[1], join '::', $class, $subrname)
            unless File::Spec->file_name_is_absolute($_[1]);
          my ($name, $path) = File::Basename::fileparse $_[1];
          $class->new($path)->$subr($name);
        }
      };
  }
}

# -------------------------------------
# CLASS UTILITY SUBROUTINES
# -------------------------------------

sub _md5hex {
  return sprintf MD5HEX_TEMPLATE, unpack MD5BIN_TEMPLATE, $_[0];
}

# INSTANCE METHODS -----------------------------------------------------------

# -------------------------------------
# INSTANCE CONSTRUCTION
# -------------------------------------

=head1 INSTANCE CONSTRUCTION

Z<>

=cut

=head2 new

Create & return a new thing.

=over 4

=item ARGUMENTS

=over 4

=item _dirname

Name of the directory represented

=cut

sub new {
  my $class = shift; $class = ref $class || $class;
  my ($dirname) = @_;

  tie(my %info, 'MLDBM',
      File::Spec->catfile($dirname, FILENAME), O_RDWR | O_CREAT, 0644);

  bless { _dirname      => File::Spec->rel2abs($dirname),
          _local_lookup => {},
          _info         => \%info,
        }, $class;
}

# -------------------------------------
# INSTANCE FINALIZATION
# -------------------------------------

sub DESTROY { untie %{$_[0]->{_info}}; }

# -------------------------------------
# INSTANCE COMPONENTS
# -------------------------------------

=head1 INSTANCE COMPONENTS

Z<>

=cut

sub _value {
  my $self = shift; my $class = ref $self;
  my ($fn, $type) = @_;

  my ($vol, $dir, $file) = File::Spec->splitpath($fn);

  Carp::croak "Filename includes path: $fn\n"
    if length $vol or length $dir;

  my $abs_fn         = File::Spec->catfile($self->{_dirname}, $fn);
  my ($size, $mtime) = (stat($abs_fn))[7,9];

  my $info = exists $self->{_info}->{$fn} ? $self->{_info}->{$fn} : undef;
  if ( defined $info            and
       $info->{size}  eq $size  and
       $info->{mtime} eq $mtime ) {
    return $info->{$type}
      if exists $info->{$type};
  } else {
    $info = { size => $size, mtime => $mtime };
  }

  my $subr;
  if ( exists $self->{_local_lookup}->{$type} ) {
    $subr = $self->{_local_lookup}->{$type};
  } else {
    $subr = $class->can(join '', '_', uc $type)
      or Carp::croak(exists $local_names{$type}                          ?
                     "Value type $type not supported on this instance\n" :
                     "Unknown value type: $type\n"                       );
  }

  $info->{$type} = my $Result = $subr->($abs_fn);

  # Careful!  Adding to hashref is not enough to cause a persistent update
  # with MLDBM; we must re-set the value to the persistent hash.
  $self->{_info}->{$fn} = $info;

  return $Result;
}

# -------------------------------------
# INSTANCE HIGHER-LEVEL FUNCTIONS
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL FUNCTIONS

=cut

=head2 dirname

The name of the directory to which this instance refers

=cut

sub dirname { $_[0]->{_dirname} };

# -------------------------------------
# STANDARD LOOKUPS
# -------------------------------------

=head1 STANDARD LOOKUPS

Each of the following functions takes a filename (without path, relative to
the directory of the instance), and returns the relevant value for the file.

Alternatively, they may be called as class methods, in which case the filename
value must be absolute.  This mode will never invoke a local method (see
L<add_local_lookup|"add_local_lookup">, and is less efficient if multiple
lookups are made on files in the same directory.

=head2 md5_hex

The MD5 signature of the file, as 16 pairs of hex characters.  The Digest::MD5
module (version 2 or above) is required to be present.

=head2 md5

The MD5 signature of the file, as a 16-byte binary value.  The Digest::MD5
module (version 2 or above) is required to be present.

=head2 md5_16khex

The MD5 signature of the first 16k of the file, as 16 pairs of hex characters.
The Digest::MD5 module (version 2 or above) is required to be present.

=head2 md5_16k

The MD5 signature of the first 16k of the file, file, as a 16-byte binary
value.  The Digest::MD5 module (version 2 or above) is required to be present.

=cut

sub md5hex { _md5hex($_[0]->_value($_[1], 'md5')) }
sub md5_16khex { _md5hex($_[0]->_value($_[1], 'md5_16k')) }

=head2 line_count

The number of lines in the file.  More acurrately, the number of "\n"
characters in the file (as for C<wc>).  No attempt is made to guess the line
terminator of the running system; for that would lead to inconsistent results
on the same file on a (say) Samba-mounted drive accessed from both Windoze and
UN*X.

=head2 type

The file type, as determined by reading the file itself.  This is similar in
intent to the C<file> command under UN*X, with the following distinctions:

=over 4

=item *

The means of identification is consistent across all systems, rather than
relying on a system-specific magic file

=item *

The type is returned as a constant (which happens to be a simple string),
rather than having to parse the output of C<file>

=item *

This method only returns the basic type, not any details about versions,
bitrates, sizes, etc.  This is a feature.  Other details may be queried
elsewhere with the same module.

=item *

The file database is considerably less big.  Of course, if you submit some
additions, it will grow 8*).

=back

The returned value is a C<TYPE_x> constant.

=head2 par_set_hash

Behaviour is defined only for files whose L<type|"type"> is C<TYPE_PAR>.

This is the hash used to identify par files that belong to a single set.  It
is a 16-byte binary file.

=head2 par_set_hash_hex

Behaviour is defined only for files whose L<type|"type"> is C<TYPE_PAR>.

As for L<par_set_hash|"par_set_hash">, but a 16 pairs of hex characters
representing the 16 bytes.

=cut

sub par_set_hash_hex { _md5hex($_[0]->_value($_[1], 'par_set_hash')) }

# -------------------------------------
# INSTANCE HIGHER-LEVEL PROCEDURES
# -------------------------------------

=head1 INSTANCE HIGHER-LEVEL PROCEDURES

Z<>

=cut

=head2 add_local_lookup

Add a lookup function to this instance only.  A method with the same name will
be created, to provide the cached lookup.

This method will only work on this instance.  Any other instances with their
own local methods will be respected.  The local method will override any
global method of the same name.  However, using the class interface (e.g., C<<
File::Info->local($absname) >> will I<always> invoke the global instance, if
any (and fail, if not).

=over 4

=item ARGUMENTS

=over 4

=item name

The name may consist only of letters, digits, and underscore characters.  The
first character must be a letter, and at least one digit or lower-case must be
present.

builtin names will always be lower-case.  If you stick to this, then you will
need to make no change if your identifier should get absorbed into the core.
On the other hand, if you use some upper-case letters (e.g., StudlyCaps), then
you are assured that you will never clash will internal names.

These other names are reserved:

  add_local_lookup add_global_lookup isa import new dirname

=item code

The code to call to calculate the value.  The code will be passed the absolute
name of the file to lookup, and is expected to return a suitable value.  The
value will be cached.

=back

=back

=cut

sub add_local_lookup {
  my $self = shift; my $class = ref $self;
  my ($name, $code) = @_;

  Carp::croak "Lookup name $name must contain only alphanumerics and underscores\n"
    if $name =~ /[^A-Za-z0-9_]/;
  Carp::croak "Lookup name must begin with a letter\n"
    if $name !~ /^[A-Za-z]/;
  Carp::croak "Lookup name must contain at least one lowercase number or digit\n"
    unless $name =~ /[a-z0-9]/;

  Carp::croak "Name reserved: $name\n"
    if exists FORBIDDEN_NAMES->{$name};

  $self->{_local_lookup}->{$name} = $code;
  $local_names{$name} = 1;

  my $methname = join '::', $class, $name;
  {
    no strict 'refs';

    if ( ! defined *{$methname}{CODE} ) {
      *{$methname} =
        sub {
          my ($vol, $path) = File::Spec->splitpath($_[1]);
          Carp::croak("Local function $name may not be invoked " .
                      "with file with path: $_[1]\n")
            if length $vol or length $path;
          $_[0]->_value($_[1], $name);
        };
    }
  }
}

# ----------------------------------------------------------------------------

CHECK {
  no strict 'refs';
  # Ensure that every existing method (with a lowercase initial letter, not a
  # reserved name) handles class invocation
  __PACKAGE__->_make_class_ready($_)
    for grep(/^[a-z]/ && ! exists FORBIDDEN_NAMES->{$_},
             keys %{__PACKAGE__ . '::'});
  # If a method of the form _MD5 exists with no corresponding md5, fake up
  # the latter.
  for my $name (map(lc(substr $_,1),
                    grep( /^_(?!_)[A-Z0-9_]+$/            &&
                          ! exists FORBIDDEN_NAMES->{$_},
                          keys %{__PACKAGE__ . '::'}))) {
    __PACKAGE__->_make_class_ready($name, sub { $_[0]->_value($_[1], $name) });
  }
}

=head1 EXAMPLES

Z<>

=head1 BUGS

Z<>

=head1 REPORTING BUGS

Email the author.

=head1 AUTHOR

Martyn J. Pearce C<fluffy@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2003 Martyn J. Pearce.  This program is free software; you
can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

Z<>

=cut

1; # keep require happy.

__END__
