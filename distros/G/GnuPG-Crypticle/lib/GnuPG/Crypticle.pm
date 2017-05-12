package GnuPG::Crypticle;
$GnuPG::Crypticle::VERSION = '0.023';
# ABSTRACT: (DEPRECATED) use GnuPG::Interface instead!
# KEYWORDS: deprecated
use namespace::autoclean;
use Moose;
use Fcntl qw//;
use File::Copy qw//;
use File::stat;
use File::Path qw/make_path/;
use File::Spec qw//;
use IO::Handle;
has 'gpg_bin' => (
  is => 'ro',
  isa => 'Str',
  default => '/usr/bin/gpg',
  documentation => 'path to gpg binary',
);

has 'gpg_home' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
  lazy => 1,
  default => sub { return "$ENV{HOME}/.gnupg"; },
  documentation => 'Home directory for GnuPG files (pubring, secring, trustdb)',
);

has 'gpg_pass_file' => (
  is => 'ro',
  isa => 'Str|FileHandle',
  required => 0,
  predicate => 'has_gpg_pass_file',
  documentation => 'passphrase file for decrypting secret keys',
);

has 'gpg_temp_home' => (
  is => 'ro',
  isa => 'Str',
  required => 0,
  predicate => 'has_gpg_temp_home',
  documentation => 'path to temp home',
);

has '_passphrase_fh' => (
  is => 'ro',
  isa => 'FileHandle',
  lazy => 1,
  builder => '_open_passphrase_file',
  documentation => 'filehandle to passphrase file',
);
has '_null_fh' => (
  is => 'ro',
  isa => 'FileHandle',
  lazy => 1,
  builder => '_open_dev_null',
  documentation => 'filehandle to /dev/null',
);

sub BUILD {
  my $self = shift;
  if ($self->has_gpg_temp_home) {
    my $homedir = $self->gpg_home;
    my $gpgdir = $self->gpg_temp_home;
    my $cumask = umask(0077);
    my $mkpatherr;
    unless (
      (-d $gpgdir and -w $gpgdir) or
      File::Path::make_path($gpgdir, {error=>\$mkpatherr}) or
      (-d $gpgdir and -w $gpgdir)
    ) {
      umask($cumask);
      if ($mkpatherr) {
        # ugly but necessary, perldoc File::Path for info
        my $k = (keys %{$mkpatherr->[0]})[0];
        $mkpatherr = $mkpatherr->[0]->{$k};
      }
      else {
        $mkpatherr = "$!";
      }
      umask($cumask);
      die "Unable to create gpg_temp_home '$gpgdir': $mkpatherr";
    }
    for my $f (qw/secring.gpg trustdb.gpg pubring.gpg/) {
      my $file = File::Spec->catfile($homedir, $f);
      unless (File::Copy::cp($file, $gpgdir)) {
        umask($cumask);
        die "Failed to copy '$file' to '$gpgdir': $!";
      }
    }
    File::Copy::cp(File::Spec->catfile($homedir, 'gpg.conf'), $gpgdir);
    umask($cumask);
  }
}

sub decrypt {
  my ($self, %opts) = @_;
  $opts{gpg_args} ||= [];
  push(@{$opts{gpg_args}}, '-d');
  return $self->call_gpg(%opts);
}

sub encrypt {
  my ($self, %opts) = @_;
  $opts{gpg_args} ||= [];
  my $rcpt = delete $opts{rcpt};
  push(@{$opts{gpg_args}}, '-r', $rcpt, '-e');
  return $self->call_gpg(%opts);
}

sub detect_encryption {
  my ($self, %opts) = @_;
  my $fh;
  if (ref($opts{file}) and defined(fileno($opts{file}))) {
    $fh = $opts{file};
  }
  elsif (!open($fh, '<:raw', $opts{file})) {
    die "Failed detecting encryption: $!";
  }
  my $stat = stat($fh);
  # 100 is arbitrary, but if less than 100 bytes could it be an encrypted file?
  # don't go below what is read in for magic (64)
  if ($stat->size > 100) {
    # read in 64 bytes, long enough for the magic test
    my ($magic,$buffer,$bytes) = ('','',0);
    while ($bytes < 64) {
      $bytes += read($fh, $buffer, 64);
      if (!defined($bytes)) {
        die "Read error: $!";
      }
      elsif (!$bytes) {
        # old mcdonald had a farm, e i...
        $! = 5;
        die "Reached EOF on before 64 bytes, though stat said size over 100";
      }
      else {
        $magic .= $buffer;
      }
    }
    if (
      $magic =~ /^\xa6\x00/ or
      $magic =~ /^\x85[\x01\x02\x04]/ or
      $magic =~ /^-----BEGIN\x20PGP\x20(SIGNED\x20)?MESSAGE-/
    ) {
      return 1;
    }
  }
  return 0;
}

sub call_gpg {
  my ($self, %opts) = @_;
  my $dest = delete $opts{dst};
  my $error = delete $opts{err};
  my $source = delete $opts{src};
  my ($close_dest, $close_error, $close_source);
  # using std filehandles for i/o lets us completely ignore dealing with
  # close-on-exec
  my ($stdout,$stderr,$stdin);
  if ($dest) {
    if (defined(fileno($dest))) {
      unless(binmode($dest)) {
        die "Failed to flush dest handle to raw: $!";
      }
    }
    else {
      my $file = $dest;
      $dest = undef;
      unless (open($dest, '>:raw', $file)) {
        die "Failed to open dest file '$file': $!";
      }
      $close_dest = 1;
    }
    if (defined(fileno(STDOUT))) {
      unless (open($stdout, ">&", \*STDOUT)) {
        die "Failed to dup stdout: $!";
      }
    }
    unless (open(STDOUT, ">&", $dest)) {
      die "Failed to dup over STDOUT: $!";
    }
  }
  if ($error) {
    if (defined(fileno($error))) {
      unless (binmode($error)) {
        die "failed to flush error handle to raw: $!";
      }
    }
    else {
      my $file = $error;
      $error = undef;
      unless (open($error, '>>:raw', $file)) {
        die "Failed to open error file '$file': $!";
      }
      $close_error = 1;
    }
    if (defined(fileno(STDERR))) {
      unless (open($stderr, ">&", \*STDERR)) {
        die "Failed to dup stderr: $!";
      }
    }
    unless (open(STDERR, ">&", $error)) {
      die "Failed to dup over STDERR: $!";
    }
  }
  if ($source) {
    if (defined(fileno($source))) {
      unless (binmode($source)) {
        die "Failed to flush source handle to raw: $!";
      }
    }
    else {
      my $file = $source;
      $source = undef;
      unless (open($source, '<:raw', $file)) {
        die "Failed to open source file '$file': $!";
      }
      $close_source = 1;
    }
    if (defined(fileno(STDIN))) {
      unless (open($stdin, "<&", \*STDIN)) {
        die "Failed to dup stdin: $!";
      }
    }
    unless (open(STDIN, "<&", $source)) {
      die "Failed to dup over STDIN: $!";
    }
  }
  if ($self->has_gpg_pass_file) {
    unshift(@{$opts{gpg_args}}, '--passphrase-fd', fileno($self->_passphrase_fh));
  }
  else {
    unshift(@{$opts{gpg_args}}, '--passphrase-fd', fileno($self->_null_fh));
  }
  my $homedir;
  if ($self->has_gpg_temp_home) {
    unshift(@{$opts{gpg_args}}, '--homedir', $self->gpg_temp_home);
  }
  else {
    unshift(@{$opts{gpg_args}}, '--homedir', $self->gpg_home);
  }
  my $gpg_fail;
  unless (system($self->gpg_bin, '--batch', '--no-tty', @{$opts{gpg_args}}) == 0) {
    if ($! == 0) {
      $gpg_fail = "Failed to execute gpg: $?";
    }
    else {
      $gpg_fail = "gpg call failed: $?";
    }
  }
  if ($self->has_gpg_pass_file) {
    seek($self->_passphrase_fh, 0, 0);
  }
  if ($stdin) {
    unless (open(STDIN, "<&", $stdin)) {
      die "Failed to restore STDIN";
    }
  }
  close($source) if $close_source;
  if ($stderr) {
    unless (open(STDERR, ">&", $stderr)) {
      die "Failed to restore STDERR";
    }
  }
  close($error) if $close_error;
  if ($stdout) {
    unless (open(STDOUT, ">&", $stdout)) {
      die "Failed to restore STDOUT";
    }
  }
  close($dest) if $close_dest;
  die $gpg_fail if $gpg_fail;
  return 1;
}

sub _open_passphrase_file {
  my $self = shift;
  if (my $file = $self->gpg_pass_file) {
    if (ref($file)) {
      my $flags;
      unless ($flags = fcntl($file, Fcntl::F_GETFD, 0)) {
        die "fcntl F_GETFD failed: $!";
      }
      unless (fcntl($file, Fcntl::F_SETFD, $flags & ~Fcntl::FD_CLOEXEC)) {
        die "fcntl F_SETFD failed: $!";
      }
      return $file;
    }
    else {
      my $fh;
      unless (open($fh, '<', $file)) {
        die "Failed to open passphrase file: $!";
      }
      my $flags;
      unless ($flags = fcntl($fh, Fcntl::F_GETFD, 0)) {
        die "fcntl F_GETFD failed: $!";
      }
      unless (fcntl($fh, Fcntl::F_SETFD, $flags & ~Fcntl::FD_CLOEXEC)) {
        die "fcntl F_SETFD failed: $!";
      }
      return $fh;
    }
  }
}

sub _open_dev_null {
  my $fh;
  unless (open($fh, '<', File::Spec->devnull)) {
    die "Failed to open /dev/null: $!";
  }
  return $fh;
}

__PACKAGE__->meta->make_immutable();

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

GnuPG::Crypticle - (DEPRECATED) use GnuPG::Interface instead!

=head1 VERSION

version 0.023

=head1 SYNOPSIS

Stop reading here, and go use L<GnuPG::Interface> instead.

    use GnuPG::Crypticle;

    my $crypticle = GnuPG::Crypticle->new(gpg_home => /home/me/.gnupg);
    $crypticle->encrypt(src => '/tmp/sourcefile.txt', dst => '/tmp/destfile.gpg', rcpt => 'ABCD0123');
    ...

=head1 DEPRECATION

This module should be considered deprecated and unmaintained. It was a stop-gap
-- albeit not a very good one -- when the author had no better option to use
gpg2 (L<GnuPG> only works with gpg1). L<GnuPG::Interface> is a much better
option. Please use that module instead!

=head1 ATTRIBUTES

=head2 gpg_bin

full path to gpg binary

=head2 gpg_home

location of the .gnupg directory gpg should use

=head2 gpg_pass_file

plaintext file containing the passphrase used with any secret keys

=head2 gpg_temp_home

path to use as temporary home

=head1 METHODS

Parameters are passed to all methods as a key/value list (hash) e.g.,

subroutine(key1 => val1, key2 => val2);

=head2 BUILD

During object initialization, copies of master gpg keyrings are made in a
temporary directory to prevent locking and corruption problems. A restart of
the application is necessary if there are key ring changes. Dies on failure.

=head2 decrypt

Encrypts from a source to destination file. Croaks on decryption failure,
including signature failure.

parameters:

=over 2

=item src

file name or handle to be decrypted

=item dst

file name or handle to which decrypted output is sent

=back

returns:

=over 2

valid signature if present, or true

=back

=head2 encrypt

Dies on failure

parameters:

=over 2

=item src

file name or handle to be encrypted

=item dst

file name or handle to which encrypted output is sent

=item gpg_args

arguments passed directly to gpg execution

=back

returns:

=over 2

valid signature if present, or true

=back

=head2 detect_encryption

Dies on failure. Detects pgp or gpg decryption the same as mime magic does.

This is nowhere near complete or reliable. For best results, just try to
decrypt.

parameters:

=over 2

=item file

file name or handle from which to detect encryption

=back

=head2 call_gpg

(private) calls gpg command with necessary options

=head2 _open_passphrase_file

(private) Opens the passphrase file.

=head2 _open_dev_null

(private) returns a filehandle to /dev/null

=head1 SEE ALSO

This should be read "see instead." L<GnuPG::Interface>

=head1 AUTHOR

Brad Barden <b at 13os.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016 by Brad Barden.

This is free software, licensed under:

  The ISC License

=cut
