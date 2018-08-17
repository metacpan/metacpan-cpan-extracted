package FFI::Build::File::Object;

use strict;
use warnings;
use 5.008001;
use base qw( FFI::Build::File::Base );
use constant default_encoding => ':raw';
use Carp ();

# ABSTRACT: Class to track object file in FFI::Build
our $VERSION = '0.03'; # VERSION


sub default_suffix
{
  shift->platform->object_suffix;
}

sub build_item
{
  my($self) = @_;
  unless(-f $self->path)
  {
    Carp::croak "File not built"
  }
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

FFI::Build::File::Object - Class to track object file in FFI::Build

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use FFI::Build::File::Object;
 my $o = FFI::Build::File::Object->new('src/_build/foo.o');

=head1 DESCRIPTION

This class represents an object file.  You normally do not need
to use it directly.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
