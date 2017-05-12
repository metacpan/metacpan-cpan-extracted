package Iterator::RoundRobin;

use strict;
use warnings;

our $VERSION = '0.2';

use overload
    'eq' => \&next,
    'ne' => \&next,
    "cmp" => \&next,
    "<=>" => \&next,
    '""' => \&next;

sub new {
    my ($class, @arr) = @_;
    my %args = (
        'arrays' => \@arr,
        'completed' => [],
        'max' => 0,
        'current' => 0,
        'cols' => 0,
        'track_completed' => 1,
    );
    my $self = bless { %args }, $class;
    for my $arr (@arr) {
      $self->{'cols'}++;
      my $count = scalar @{$arr};
      if ($count > $self->{'max'}) { $self->{'max'} = $count; }
    }
    if (! $self->{'col'}) { $self->{'col'} = 0; }
    return $self;
}

sub isempty {
    my ($self) = @_;
    if (scalar @{$self->{'arrays'}}) { return 0; }
    return 1;
}

sub next {
    my ($self) = @_;
    if ($self->isempty()) { return undef; }
    if (my $data = shift @{ $self->{'arrays'}->[$self->{'col'}] }) {
        my $oldcol = $self->{'col'};
        $self->{'col'}++;
        unless ( scalar @{ $self->{'arrays'}->[ $oldcol ] }) { $self->rebuildarrays(); $self->{'col'} = $oldcol; }
        if ($self->{'track_completed'}) {
            push @{ $self->{'completed'} }, $data;
        }
        if ($self->{'col'} == $self->{'cols'}) {
            $self->{'col'} = 0;
        }
        return $data;
    }
    return undef;
}

sub rebuildarrays {
    my ($self) = @_;
    my @arrays = ();
    $self->{'cols'} = 0;
    my $col = 1;
    for my $list (@{$self->{'arrays'}}) {
        my $count = scalar @{$list};
        if ($count) {
            push @arrays, $list; $self->{'cols'}++;
        }
        $col++;
    }
    $self->{'arrays'} = \@arrays;
    return 1;
}

1;
__END__

=pod

=head1 NAME

Iterator::RoundRobin - The great new Iterator::RoundRobin!

=head1 SYNOPSIS

Why? Because its Great! And New!

  use Iterator::RoundRobin;
  my $rr = Iterator::RoundRobin->new(
    [qw/usera-1 usera-2 usera-3/],
    [qw/userb-1 userb-2 userb-3/]
  );
  while (my $user = $rr->next()) {
    print "User $user.\n";
  }

=head1 FUNCTIONS

=head2 new

The new method returns an instantiated Iterator::RoundRobin object. This
method does require at least one or more array refs to be passed in. It
will fail (ungracefully) if those requirements are not met.

=head2 next

The next method returns the next item in the list. It does very little
voodoo to determine where it gets the thing to return. It handles uneven
lists and multiple lists fairly well.

=head2 isempty

This method is use internally to determine if there is anything left to
return.

=head2 rebuildarrays

This method is used internally to rebuild the index when a given list
is empty. Please don't call this outside of the object.

=head1 CAVEATS

This module keeps an internal list of items that have been marked
'completed' which may be a memory hog if you let it. To disable this
tracking set the internal variable 'track_completed' as false after
object creation.

  my $iter = Iterator::RoundRobin->new( ... );
  $iter->{'track_completed'} = 0;

=head1 AUTHOR

Nick Gerakines, C<< <nick at gerakines.net> >>

=head1 BUGS

Please report any bugs or feature requests to the author.

=head1 ACKNOWLEDGEMENTS

This module was inspired by Data::RoundRobin. Thanks.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Nick Gerakines, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
