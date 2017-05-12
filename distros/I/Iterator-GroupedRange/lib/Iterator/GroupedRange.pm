package Iterator::GroupedRange;

use strict;
use warnings;

our $VERSION = '0.08';

sub new {
    my $class = shift;
    my ( $code, $range, $opts ) = @_;

    $range ||= 1000;
    $opts  ||= {};

    %$opts = (
        rows => undef,
        %$opts,
    );

    if ( ref $code eq 'ARRAY' ) {
        my @ds = @$code;
        $opts->{rows} = scalar @ds;
        $code = sub {
            @ds > 0 ? [ splice( @ds, 0, $range ) ] : undef;
        };
    }

    return bless {
        code           => $code,
        range          => $range,
        is_last        => 0,
        rows           => $opts->{rows},
        _has_next      => undef,
        _buffer        => [],
        _append_buffer => [],
    } => $class;
}

sub has_next {
    my $self = shift;
    return 0 if ( $self->{is_last} );
    return 1 if ( $self->{_has_next} );
    $self->{_buffer} = $self->{code}->();
    if ( defined $self->{_buffer} ) {
        $self->{_has_next} = 1;
        return 1;
    }
    else {
        return 0;
    }
}

sub next {
    my $self = shift;

    return if ( $self->{is_last} );
    return unless ( defined $self->{_buffer} );

    my @buffer = @{ $self->{_buffer} };

    while ( @buffer < $self->{range} ) {
        my $rv = $self->{code}->();
        unless ( defined $rv ) {
            if ( @{$self->{_append_buffer}} > 0 ) {
                my @append_buffer = @{$self->{_append_buffer}};

                $self->{code} = sub {
                    return @append_buffer > 0 ?
                        [ splice( @append_buffer, 0, $self->{range} ) ] : undef;
                };

                $self->{_buffer}   = [ @buffer ];
                $self->{_append_buffer} = [];

                return $self->next;
            }
            else {
                $self->{is_last} = 1;
                last;
            }
        }
        push( @buffer, @$rv );
    }

    my @rs = splice( @buffer, 0, $self->{range} );

    $self->{_buffer}   = [ @buffer ];
    $self->{_has_next} = @buffer > 0 ? 1 : 0;

    return @rs ? \@rs : ();
}

sub append {
    my $self = shift;
    my $rows = ( @_ == 1 && ref $_[0] eq 'ARRAY' ) ? $_[0] : [ @_ ];

    if ( defined $self->{rows} ) {
        $self->{rows} += scalar @$rows;
    }

    push(@{$self->{_append_buffer}}, @$rows);

    if (!$self->{_has_next} && @{$self->{_append_buffer}}) {
        $self->{_has_next} = 1;
    }

    return scalar @$rows;
}

sub is_last {
    $_[0]->{is_last};
}

sub rows {
    if ( @_ == 2 ) {
        $_[0]->{rows} = $_[1];
    }
    else {
        return $_[0]->{rows};
    }
}

sub range {
    return $_[0]->{range} = $_[1] if @_ == 2;
    shift->{range};
}

1;
__END__

=head1 NAME

Iterator::GroupedRange - Iterates retrieving a set of specified number rows

=head1 SYNOPSIS

  use Iterator::GroupedRange;

  my @ds = (
    [ 1 .. 6 ],
    [ 7 .. 11 ],
    [ 11 .. 25 ],
  );

  my $i1 = Iterator::GroupedRange->new( sub { shift @ds; }, 10 );
  $i1->next; # [ 1 .. 10 ]
  $i1->next; # [ 11 .. 20 ]
  $i1->next; # [ 21 .. 25 ]

  my $i2 = Iterator::GroupedRange->new( [ 1 .. 25 ], 10 );
  $i2->next; # [ 1 .. 10 ]
  $i2->next; # [ 11 .. 20 ]
  $i2->next; # [ 21 .. 25 ]

=head1 DESCRIPTION

Iterator::GroupedRange is module to iterate retrieving a set of specified number rows.
Code reference or list reference becomes provider of sets.

It accepts other iterator to get rows, or list.

=head1 METHODS

=head2 new( \&provider[, $range, \%opts] )

=head2 new( \@list[, $range, \%opts] )

Return new instance. Arguments details are:

=over

=item &provider

The code reference must be taking a list reference or undef.
If the return value is undef or empty array reference, L<#has_next()> will return false value.

=item @list

This list reference will be code reference that will be return a set of specified number rows.

=item $range

Most number of retrieving rows by each iteration. Default value is 1000.

=item %opts

=over

=item range

Grouped size.

=item rows

Number of rows. For example, using L<DBI>'s statement handle:

  my $sth = $dbh->prepare('SELECT blah FROM example');
  $sth->execute;
  my $iter; $iter = Iterator::GroupedRange->new(sub {
      if ( my $ids = $sth->fetchrow_arrayref( undef, $iter->range ) ) {
          return [ map { $_->[0] } @$ids ];
      }
      else {
          return;
      }
  }, { rows => $sth->rows, range => 1000 });

=back

=back

=head2 has_next()

Return which the iterator has next rows or not.

=head2 next()

Return next rows.

=head2 is_last()

Return which the iterator becomes ended of iteration or not.

=head2 append(@items)

=head2 append(\@items)

Append new items.

=head2 range()

Return grouped size.

=head2 rows()

Return total rows.

=head1 AUTHOR

Toru Yamaguchi E<lt>zigorou@cpan.orgE<gt>

=head1 SEE ALSO

=over

=item L<List::MoreUtils>

L<List::MoreUtils> has C<natatime> subroutine looks like this module.
The C<natatime> subroutine can treat only list.

=item L<DBI>

L<DBI>'s fetchall_arrayref can accepts max_rows argument.
This feature is similar to this module. For example:

  use DBI;
  use Data::Dumper;

  my $sth = $dbh->prepare('SELECT id FROM people');
  while ( my $ids = $sth->fetchall_arrayref(undef, 100) ) {
      $ids = [ map { $_->[0] } @$ids ];
      warn Dumper($ids);
  }

=back

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
