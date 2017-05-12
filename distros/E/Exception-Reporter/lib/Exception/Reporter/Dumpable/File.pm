use strict;
use warnings;
package Exception::Reporter::Dumpable::File;
# ABSTRACT: a dumpable object for a file on disk
$Exception::Reporter::Dumpable::File::VERSION = '0.014';
#pod =head1 SYNOPSIS
#pod
#pod   $reporter->report_exception(
#pod     [
#pod       ...,
#pod       [ import_file => Exception::Reporter::Dumpable::File->new(
#pod                          $path_to_file,
#pod                          { mimetype => 'text/csv', charset => 'us-ascii' },
#pod                        ) ],
#pod     ]
#pod   );
#pod
#pod This class exists to provide a simple way to tell Exception::Reporter to
#pod include a file from disk.  To make this useful, you should also include
#pod L<Exception::Reporter::Summarizer::File> in your summarizers.
#pod
#pod Right now, file content is read as soon as the file is constructed.  This may
#pod change in the future.
#pod
#pod =cut

sub _err_msg {
  my ($class, $path, $msg) = @_;
  return "(file at <$path> was requested for dumping, but $msg)";
}

#pod =method new
#pod
#pod   my $file_dumpable = Exception::Reporter::Dumpable::File->new(
#pod     $path,
#pod     \%arg,
#pod   );
#pod
#pod Useful arguments are:
#pod
#pod   mimetype - defaults to a guess by extension or application/octet-stream
#pod   charset  - defaults to utf-8 for text, undef otherwise
#pod   max_size - the maximum size to include; if the file is larger, a placeholder
#pod              will be included instead
#pod
#pod If the file object can't be constructed, B<the method does not die>.  This to
#pod avoid requiring exception handling in your exception handling.  Instead, C<new>
#pod I<will return a string> which will then be summarized as any other string.
#pod
#pod Maybe this will change in the future, and the file summarizer will know how to
#pod expect File::Error objects, or something like that.
#pod
#pod =cut

sub new {
  my ($class, $path, $arg) = @_;
  $arg ||= {};

  return $class->_err_msg($path, 'does not exist') unless -e $path;

  my $realpath = -l $path ? readlink $path : $path;

  return $class->_err_msg($path, 'is not a normal file') unless -f $realpath;

  return $class->_err_msg($path, "can't be read") unless -r $realpath;

  if ($arg->{max_size}) {
    my $size = -s $realpath;
    if ($size > $arg->{max_size}) {
      return $class->_err_msg(
        $path,
        "its size $size " . "exceeds maximum allowed size $arg->{max_size}"
      );
    }
  }

  my $guts = { path => $path };

  $guts->{mimetype} = $arg->{mimetype}
                   || $class->_mimetype_from_filename($path)
                   || 'application/octet-stream';

  $guts->{charset} = $arg->{charset}
                  || $guts->{mimetype} =~ m{\Atext/} ? 'utf-8' : undef;

  open my $fh, '<', $path
    or return $class->_err_msg("there was an error reading it: $!");

  my $contents = do { local $/; <$fh> };

  $guts->{contents_ref} = \$contents;

  bless $guts => $class;
}

sub path     { $_[0]->{path} }
sub mimetype { $_[0]->{mimetype} }
sub charset  { $_[0]->{charset} }
sub contents_ref { $_[0]->{contents_ref} }

# replace with MIME::Type or something -- rjbs, 2012-07-03
my %LOOKUP = (
  txt  => 'text/plain',
  html => 'text/html',
);

sub _mimetype_from_filename {
  my ($class, $filename) = @_;

  my ($extension) = $filename =~ m{\.(.+?)\z};
  return unless $extension;

  return $LOOKUP{ $extension };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Exception::Reporter::Dumpable::File - a dumpable object for a file on disk

=head1 VERSION

version 0.014

=head1 SYNOPSIS

  $reporter->report_exception(
    [
      ...,
      [ import_file => Exception::Reporter::Dumpable::File->new(
                         $path_to_file,
                         { mimetype => 'text/csv', charset => 'us-ascii' },
                       ) ],
    ]
  );

This class exists to provide a simple way to tell Exception::Reporter to
include a file from disk.  To make this useful, you should also include
L<Exception::Reporter::Summarizer::File> in your summarizers.

Right now, file content is read as soon as the file is constructed.  This may
change in the future.

=head1 METHODS

=head2 new

  my $file_dumpable = Exception::Reporter::Dumpable::File->new(
    $path,
    \%arg,
  );

Useful arguments are:

  mimetype - defaults to a guess by extension or application/octet-stream
  charset  - defaults to utf-8 for text, undef otherwise
  max_size - the maximum size to include; if the file is larger, a placeholder
             will be included instead

If the file object can't be constructed, B<the method does not die>.  This to
avoid requiring exception handling in your exception handling.  Instead, C<new>
I<will return a string> which will then be summarized as any other string.

Maybe this will change in the future, and the file summarizer will know how to
expect File::Error objects, or something like that.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
