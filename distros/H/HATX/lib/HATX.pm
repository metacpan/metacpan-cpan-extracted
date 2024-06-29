package HATX;

use strict; use warnings; use utf8; use 5.10.0;
use Exporter 'import';
use Carp;
use Clone qw/clone/;

our $VERSION = '0.0.3';
our @EXPORT_OK = qw/hatx/;

=head1 NAME

HATX - A fluent interface for Hash and Array Transformations

=cut
=head1 SYNOPSIS

  use HATX qw/hatx/;

  # Multiple versions of journal.html and projmgmt.html
  my $files = [
    'journal-v1.0.tar.gz  1201',
    'journal-v1.1.tar.gz  1999',
    'journal-v1.2.tar.gz  3100',
    'projmgmt-v0.1.tar.gz  250',
    'projmgmt-v0.2.tar.gz  350'
  ];

  # Declare a helper object
  my $max = { journal => '0.0', projmgmt => '0.0' };

  # hatx($obj) clones $obj; no clobbering
  my $h = hatx($files)
    # Internal object becomes equivalent to:
    # [ 'journal-v1.0.tar.gz  1201',
    #   'journal-v1.1.tar.gz  1999',
    #   'journal-v1.2.tar.gz  3100',
    #   'projmgmt-v0.1.tar.gz  250',
    #   'projmgmt-v0.2.tar.gz  350' ]

   # Extract components: file, version, bytes
   ->map(sub {
      $_[0] =~ /(journal|projmgmt)-v(.+).tar.gz\s+(\d+)/;
      return [$1, $2, $3];      # e.g. ['journal', '1.0', 1201]
    })
    # Internal object becomes equivalent to:
    # [ ['journal', '1.0', 1201]
    #   ['journal', '1.1', 1999]
    #   ['journal', '1.2', 3100]
    #   ['projmgmt', '0.1', 250]
    #   ['projmgmt', '0.2', 350] ]

  # Accumulate file count and file sizes
  ->apply(sub {
      my ($v, $res) = @_;
      $res->{count}++;
      $res->{bytes} += $v->[2];
    }, my $stats = { count => 0, bytes => 0 })
    # Internal object unchanged
    # The $stats variable becomes { count => 5, bytes => 6900 }

  # Determine the max version of each file, store into $max
  ->apply(sub {
      my ($v, $res) = @_;
      my ($file, $ver, $size) = @$v;
      if ($ver gt $res->{$file}) { $res->{$file} = $ver }
    }, $max)
    # Internal object unchanged
    # $max variable becomes { journal => '1.2', projmgmt => '0.2' }

  # Keep only the max version
  ->grep(sub {
      my ($v, $res) = @_;
      my ($file, $ver, $size) = @$v;
      return $ver eq $res->{$file};
    }, $max)
    # Internal object reduced to:
    # [ ['journal', '1.2', 3100]
    #   ['projmgmt', '0.2', 350] ]
  ;

=cut
=head1 METHODS
=cut


# Create from existing object without clobbering
sub from_obj {
    my ($o, $obj) = @_;

    $o->{H} = clone($obj) if ref($obj) eq 'HASH';
    $o->{A} = clone($obj) if ref($obj) eq 'ARRAY';

    return $o;
}

# Default constructor
sub new {
    my $class = shift;
    my $self = {H => undef, A => undef };
    bless $self, $class;

    my $obj = shift;
    $self->from_obj($obj) if defined $obj;

    return $self;
}

# Helper to quickly create a hatx object
sub hatx {
    return HATX->new(@_);
}

# Converts object into underlying href or aref
sub to_obj {
    my $o = shift;
    return clone($o->{H}) if defined $o->{H};
    return clone($o->{A}) if defined $o->{A};
}

=head2 map

Apply the given function to each item in the href/aref.

The given function has the following signature:

    fn($k,$v) -> ($k,$v)    # Applied to href
    fn($v)    -> ($v)       # Applied to aref

The internal href/aref IS modified.

=cut
sub map {
    my $o = shift;
    my $fn = shift;     # H: fn->($key,$val)
                        # A: fn->($val)
    my @args = @_;

    if (defined($o->{H})) {
        my $new_H = {};
        foreach my $k (keys %{$o->{H}}) {
            my ($k2,$v2) = $fn->($k,$o->{H}{$k},@args);
            $new_H->{$k2} = $v2;
        }
        $o->{H} = $new_H;
    }
    if (defined($o->{A})) {
        my $new_A = [];
        foreach my $v (@{$o->{A}}) {
            push @$new_A, $fn->($v,@args);
        }
        $o->{A} = $new_A;
    }

    return $o;
}

=head2 grep

Apply the given function to each item in the href/aref.

The given function has the following signature:

    fn->($k,$v[,@args]) -> BOOLEAN     # Applied to hashref
    fn->($v[,@args])    -> BOOLEAN     # Applied to arrayref

    WHERE
      fn     A function reference that returns a boolean value
      $k,$v  The key-value pair of a hash
      $v     An item of an array
      @args  An optional list of user variables

Items where the fn returns a True value are kept.

=cut
sub grep {
    my $o = shift;
    my $fn = shift;     # H: fn->($key,$val) -> BOOL
                        # A: fn->($val)      -> BOOL
    my @args = @_;

    if (defined($o->{H})) {
        my $new_H = {};
        foreach my $k (keys %{$o->{H}}) {
            delete $o->{H}{$k} unless $fn->($k,$o->{H}{$k},@args);
        }
    }
    if (defined($o->{A})) {
        my $new_A = [];
        foreach my $v (@{$o->{A}}) {
            push @$new_A, $v if $fn->($v,@args);
        }
        $o->{A} = $new_A;
    }

    return $o;
}

=head2 sort( $fn )

DESCRIPTION

    Sorts contents of arrayref. Hashrefs are unmodified.

ARGUMENTS

    $fn - A function reference with prototype ($$). See https://perldoc.perl.org/functions/sort.

EXAMPLES

    # Sort descending alphabetically
    hatx($aref)->sort(sub ($$) { $_[1] cmp $_[0] });

    # Sort ascending numerically
    hatx($aref)->sort(sub ($$) { $_[0] <=> $_[1] });

    # Sort descending numerically
    hatx($aref)->sort(sub ($$) { $_[1] <=> $_[0] });

=cut
sub sort ($&) {
    my $o = shift;
    my $fn = shift;     # A: $fn is a BLOCK

    if (defined($o->{H})) {
        # do nothing
    }
    if (defined($o->{A})) {
        $o->{A} = defined $fn ? [ sort $fn @{$o->{A}} ]
                              : [ sort @{$o->{A}} ];
    }

    return $o;
}

=head2 to_href

Convert internal aref to href using the given function.

    $fn->($val) -> ($key, $val)
    $fn is a FUNCTIONREF that takes a single value and returns two values
=cut
sub to_href {
    my ($o,$fn) = @_;
    $o->map($fn);
    carp 'HATX/to_href: Not an array' unless ref($o->{A}) eq 'ARRAY';
    $o->{H} = {@{$o->{A}}};
    $o->{A} = undef;

    return $o;
}

=head2 to_aref( $fn [,@args] )

DESCRIPTION

    Convert internal hashref to an arrayref.

ARGUMENTS

    $fn - A user-provided function reference with signature:

      $fn->($hkey, $hval [,@args]) return ($val)

      WHERE
        $hkey   Key of source hashref pair
        $hval   Value of source hashref pair
        @args   Optional user variables
        $val    An element of the target arrayref

    @args - Optional arguments that are passed through to $fn

=cut
sub to_aref {
    my ($o,$fn,@args) = @_;

    if (defined($o->{H})) {
        my $new_A = [];
        foreach my $k (keys %{$o->{H}}) {
            push @$new_A, $fn->($k,$o->{H}{$k},@args);
        }
        $o->{A} = $new_A;
        $o->{H} = undef;
    } else {
        croak 'HATX/to_aref: No hashref to transform.';
    }

    return $o;
}

=head2 apply

Apply the given function to each item in the href/aref. Arguments can be
provided to store results of the function application e.g. finding the
max value.

The internal href/aref is not modified.

    fn($k,$v,@args) -> ()
    fn($v,@args)    -> ()

=cut
sub apply {
    my ($o,$fn,@args) = @_;

    if (defined($o->{H})) {
        foreach my $k (keys %{$o->{H}}) {
            $fn->($k,$o->{H}{$k},@args);
        }
    }
    if (defined($o->{A})) {
        foreach my $v (@{$o->{A}}) {
            $fn->($v,@args);
        }
    }

    return $o;
}

1;
__END__

=encoding utf-8

=head1 AUTHOR

Hoe Kit CHEW E<lt>hoekit@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2024- Hoe Kit CHEW

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
