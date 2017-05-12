# $Id: /mirror/perl/Iterator-File-Line/trunk/lib/Iterator/File/Line.pm 42691 2008-02-25T01:07:47.310615Z daisuke  $
#
# Copyright (c) 2008 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Iterator::File::Line;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);

our $VERSION = '0.00002';

__PACKAGE__->mk_accessors($_) for qw(source filter chomp encoding eol);

sub new
{
    my $class = shift;
    my %args  = @_;

    if ( $args{filename} ) {
        return $class->new_from_file( %args );
    } elsif ($args{fh}) {
        return $class->new_from_fh( %args );
    }

    die "Must provide filename or file handle";
}

sub new_from_file
{
    my $class = shift;
    my %args  = @_;

    my $filename = delete $args{filename};
    open(my $fh, '<', $filename) or die "Could not open $filename";

    $class->new_from_fh( %args, fh => $fh );
}

sub new_from_fh
{
    my $class = shift;
    my %args  = @_;
    my $fh = delete $args{fh};

    my $self = $class->SUPER::new( {
        filter   => $args{filter},
        chomp    => exists $args{chomp} ? $args{chomp} : 1,
        eol      => $args{eol},
        encoding => $args{encoding},
        source   => $fh,
    } );

    $self->_setup_layers();
    return $self;
}

sub next
{
    my $self = shift;
    my $fh   = $self->source;
    my $line = <$fh>;
    return  undef unless defined $line;
    chomp $line if $self->chomp;
    return $self->filter ? $self->filter->( $line ) : $line;
}

sub rewind
{
    my $self = shift;
    my $fh   = $self->source;
    seek($fh, 0, 0);
}

sub _setup_layers
{
    my $self = shift;
    my $fh   = $self->source;

    my @layers = ('', 'raw');
    if ($self->eol) {
        push @layers, sprintf('eol(%s)', $self->eol );
    }

    if ($self->encoding) {
        push @layers, sprintf('encoding(%s)', $self->encoding);
    }

    binmode($fh, join(':', @layers));
}

1;

__END__

=head1 NAME

Iterator::File::Line - Iterate A File By Line

=head1 SYNOPSIS

  use Iterator::File::Line;

  my $iter = Iterator::File::Line->new(
    filename => $filename,
  );
  my $iter = Iterator::File::Line->new_from_fh( );

  while ( my $line = $iter->next ) {
    # Do something with $line
  }

  # You want to parse TSV-ish content?
  my $iter = Iterator::File::Line->new(
    filename => "data.tsv",
    filter   => sub { return [ split(/\t/, $_[0]) ] }
  );

  while ( my $cols = $iter->next ) {
    print $cols->[0], "\n";
  }

=head1 DESCRRIPTION

Iterator::File::Line is a simple iterator that iterates over the contents of
a file, which must be a regular line-based text file.

=head1 METHODS

=head2 new

=head2 new_from_file

=head2 new_from_fh

  Iterator::File::Line->new( filename => $filename );
  Iterator::File::Line->new( fh => $open_file_handle );
  Iterator::File::Line->new_from_filename( filename => $filename );
  Iterator::File::Line->new_from_fh( fh => $open_file_handle );
  Iterator::File::Line->new(
    filename => $filename,
    filter   => \&sub,
    chomp    => $boolean,
    encoding => 'cp932',
    eol      => 'LF', # see PerlIO::eol
  );

Creates a new iterator instance. new_from_file requires a C<filename> argument, 
while new_from_Fh requires a C<fh> argument. new() accepts either.

If a C<filter> argument is given, then that coderef is used to filter the
incoming line. You can, for example, use this to deconstruct a CSV/TSV
content. However, do note that since this is a simple I<line> based
iterator, it won't work for multi-line CSV values.

If chomp is specified, the line's ending new line is chomped. By default
this is on.

If eol is specified, the line's ending new line is normalized to that
value. This is done via PerlIO::eol

If encoding is specified, the incoming data is decoded into perl's native
unicode. This is done via PerlIO::encoding

Please be careful with C<eol> and C<encoding>, as it will change the Perl IO
layer associated with that file handle. You are better off not sharing the
filehandle somewhere else in your code.

=head2 next

Returns the next chunk. If you specified a filter, this may be a structure.
otherwise it's the next line

=head2 rewind

Rewinds the iterator to the beginning of the buffer

=head1 AUTHOR

Copyright (c) 2008 Daisuke Maki E<lt>daisuke@endeworks.jpE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut