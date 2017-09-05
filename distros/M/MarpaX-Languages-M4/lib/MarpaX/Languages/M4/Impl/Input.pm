use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Input

# ABSTRACT: M4 Input generic implementation

class MarpaX::Languages::M4::Impl::Input {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    use MarpaX::Languages::M4::Role::Input;
    use MarpaX::Languages::M4::Type::Input -all;
    use MooX::HandlesVia;
    use Types::Common::Numeric -all;

    has _name => (
        is          => 'rwp',
        isa         => ArrayRef[Str],
        default     => sub { [] },
        handles_via => 'Array',
        handles     => {
                        _name_push  => 'push',
                        _name_count => 'count',
                        _name_get   => 'get',
                        _name_set   => 'set',
        }
    );

    has _cumulStartPos => (
        is       => 'rwp',
        isa      => ArrayRef[Int],
        default  => sub { [] },
        handles_via => 'Array',
        handles     => {
                        _cumulStartPos_push => 'push',
                        _cumulStartPos_get  => 'get',
                        _cumulStartPos_get  => 'set'
        }
    );

    has _cumulEndPos => (
        is       => 'rwp',
        isa      => ArrayRef[Int],
        default  => sub { [] },
        handles_via => 'Array',
        handles     => {
                        _cumulEndPos_push => 'push',
                        _cumulEndPos_get  => 'get',
                        _cumulEndPos_set  => 'set'
        }
    );

    has _idx => (
        is       => 'rwp',
        isa      => PositiveOrZeroInt,
        default  => -1,
        handles_via => 'Number',
        handles     => {
                        _idx_add => 'add'
        }
    );

    method input_rename(Str $name) {
      $self->_name_set(-1, $name);
    }

    #
    # Change size of current input (i.e. the one at _idx).
    # Should (ahem MUST) be used only when original input is unknown (i.e. stdin).
    # Only a positive or zero number is possible (while original can be negative)
    #
    method input_resize(PositiveOrZeroInt $size) {
      $self->_cumulEndPos_set($self->_idx, $self->_cumulStartPos_get($self->_idx) + $size);
      foreach ($self->_idx + 1 .. $self->_name_count - 1) {
        my $originalSize = $self->_cumulEndPos_get($_) - $self->_cumulStartPos_get($_);
        $self->_cumulStartPos_set($_, $self->_cumulEndPos_get($_ - 1) + 1);
        $self->_cumulEndPos_set($_, $self->_cumulStartPos_get($_) + $originalSize);
      }
    }

    #
    # Unknown size should be a negative number (i.e. stdin)
    #
    method input_push(Str $name, Int $size) {
      $self->_name_push($name);
      if ($self->_idx < 0) {
        #
        # Very first input
        #
        $self->_cumulStartPos_push(0);
        $self->_cumulEndPos_push($size);
        $self->_set__idx(0);
      } else {
        $self->_cumulStartPos_push($self->_cumulEndPos_get(-1) + 1);
        #
        # If size is < 0, end will be < start, which is ok
        #
        $self->_cumulEndPos_push($self->_cumulStartPos_get(-1) + $size);
      }
    }

    #
    # We will have the internal of Perl for a number.
    # And I barely think this will always be enough.
    # If this is not the case, synchronization lines
    # will be affected.
    #
    has _consumed => (
        is          => 'rw',
        isa         => PositiveOrZeroInt,
        default     => 0,
        handles_via => 'Number',
        handles     => {
                        _consumed_add => 'add'
                       }
    );

    #
    # This method will return true of a synchronisation information
    # should be printed out
    #
    method input_consumed(Str $consumed, Str $produced --> Bool) {
      $self->_consumed_add(length($consumed));
      #
      # Adjust current index in the input array
      #
      if ($self->_consumed > $self->_cumulEndPos($self->_idx)) {
        #
        # If current input has end position < start position, its real size
        # is unknown, therefore any consumption belongs to it (i.e. stdin)
        #
        if ($self->_cumulEndPos($self->_idx) < $self->_cumulStartPos($self->_idx)) {
        } else {
          #
          # Scan the remaining start positions
          #
        }
      }
    }

    with 'MarpaX::Languages::M4::Role::Input';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Input - M4 Input generic implementation

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
