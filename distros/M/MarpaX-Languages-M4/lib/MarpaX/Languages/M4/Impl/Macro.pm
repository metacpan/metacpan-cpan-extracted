use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Macro

# ABSTRACT: M4 Macro generic implementation

class MarpaX::Languages::M4::Impl::Macro {

    our $VERSION = '0.020'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    use MarpaX::Languages::M4::Role::Macro;
    use MarpaX::Languages::M4::Type::Macro -all;
    use MooX::HandlesVia;
    use Types::Common::Numeric -all;

    has name => (
        is       => 'rw',
        isa      => Str,
        required => 1
    );
    has stub => (
        is          => 'rw',
        isa         => CodeRef,
        required    => 1,
        handles_via => 'Code',
        handles     => { macro_execute => 'execute' }
    );
    has expansion => (
        is       => 'rw',
        isa      => Undef | Str,
        required => 1
    );
    has needParams => (
        is      => 'rw',
        isa     => Bool,
        default => false
    );
    has paramCanBeMacro => (
        is      => 'rw',
        isa     => HashRef [ PositiveOrZeroInt | Enum [qw/*/] ],
        default => sub {
            {};
        },
        handles_via => 'Hash',
        handles     => {
            _paramCanBeMacro_get    => 'get',
            _paramCanBeMacro_exists => 'exists',
            #
            # We do not hold references in values, so shallow_clone
            # is a real clone
            #
            _paramCanBeMacro_clone => 'shallow_clone'
        }
    );
    has postMatchLength => (
        is      => 'rw',
        isa     => CodeRef,
        default => sub {
            sub { return 0; }
        },
        handles_via => 'Code',
        handles     => { macro_postMatchLengthExecute => 'execute' }
    );

    method macro_name (--> Str) {
        return $self->name;
    }

    method macro_expansion (--> Undef | Str) {
        return $self->expansion;
    }

    method macro_needParams (--> Bool ) {
        return $self->needParams;
    }

    method macro_isBuiltin (--> Bool) {
        return Undef->check( $self->expansion );
    }

    method macro_paramCanBeMacro (PositiveOrZeroInt $paramPos --> Bool) {
        if ((      $self->_paramCanBeMacro_exists($paramPos)
                && $self->_paramCanBeMacro_get($paramPos)
            )
            || (   $self->_paramCanBeMacro_exists('*')
                && $self->_paramCanBeMacro_get('*') )
            )
        {
            return true;
        }
        else {
            return false;
        }
    }

    method macro_clone (Str $name --> M4Macro) {
        my $macro = __PACKAGE__->new(
            name       => $name,
            stub       => $self->stub,
            needParams => $self->needParams,
            #
            # Cloning a builtin is a builtin
            #
            expansion => $self->expansion,
            #
            # No need of clone: the hash is ro once created
            #
            paramCanBeMacro => $self->_paramCanBeMacro_clone,
            postMatchLength => $self->postMatchLength
        );

        return $macro;
    }

    with 'MarpaX::Languages::M4::Role::Macro';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Macro - M4 Macro generic implementation

=head1 VERSION

version 0.020

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
