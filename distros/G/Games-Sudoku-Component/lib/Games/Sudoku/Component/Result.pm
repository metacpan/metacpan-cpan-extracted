package Games::Sudoku::Component::Result;
{
  use strict;
  use warnings;
  use Carp;

  our $VERSION = '0.01';

  use overload
    '0+'  => \&result,
    '""'  => \&result,
    '<=>' => sub { $_[0]->result <=> $_[1] },
    'cmp' => sub { $_[0]->result cmp $_[1] };

  sub new {
    my $class = shift;
    my $this  = bless {}, (ref $class || $class);

    if (@_ == 1) {
      if (ref $_[0] eq 'HASH') {
        my %options = %{ $_[0] };
        $this->{result} = $options{result} || 0;
        $this->{reason} = $options{reason} || '';
      }
      else {
        $this->{result} = $_[0];
      }
    }
    else {
      my %options = @_;
      $this->{result} = $options{result} || 0;
      $this->{reason} = $options{reason} || '';
    }

    $this;
  }

  sub result { $_[0]->{result} }
  sub reason { $_[0]->{reason} }
}

1;
__END__

=head1 NAME

Games::Sudoku::Component::Result

=head1 SYNOPSIS

  use Games::Sudoku::Component::Result;

  # verbose
  my $verbose = 1;

  sub some_function {
    my $return_code = 1;

    if ($verbose) {
      return Games::Sudoku::Component::Result->new(
        result => $code,
        reason => 'more descriptive error message',
      );
    }
    else {
      return $code;
    }
  }

  # Then, check the result. 

  if (my $result = &some_function) {
    print ref $result ? $result->{reason} : 'something has happened';
  }

=head1 DESCRIPTION

This module is mainly for debugging. Use this for a normal scalar
return code, and you can get more detailed or additional information
about it.

=head1 METHODS

=head2 new (I<scalar> or I<hash> or I<hashref>)

Options are:

=over 4

=item result

Something you'd like to return.

=item reason

Debug message, error code, or something like that.

=back

If there is only one argument, it is supposed to be a result code.

=head2 result

=head2 reason

Returns the values stored when the object was created, respectively.

=head1 AUTHOR

Kenichi Ishigaki, E<lt>ishigaki@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Kenichi Ishigaki

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
