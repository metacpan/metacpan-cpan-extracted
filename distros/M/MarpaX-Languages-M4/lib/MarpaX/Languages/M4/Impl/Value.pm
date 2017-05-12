use Moops;

# PODNAME: MarpaX::Languages::M4::Impl::Value

# ABSTRACT: M4 Macro Parse Value generic implementation

class MarpaX::Languages::M4::Impl::Value {
    use MarpaX::Languages::M4::Role::Value;
    use MarpaX::Languages::M4::Type::Macro -all;
    use MarpaX::Languages::M4::Type::Value -all;
    use MooX::HandlesVia;
    use Types::Common::Numeric -all;

    our $VERSION = '0.017'; # VERSION

    our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

    has _value => (
        is          => 'rw',
        isa         => ArrayRef [ Str | M4Macro ],
        default     => sub { [] },
        handles_via => 'Array',
        handles     => {
            _value_push     => 'push',
            _value_get      => 'get',
            _value_count    => 'count',
            _value_grep     => 'grep',
            _value_elements => 'elements'
        }
    );

    #
    # perltidier does not like around BUILDARGS(CodeRef $orig: ClassName $class, @args)
    #
    around BUILDARGS(CodeRef $orig: ClassName $class, @args) {
        if ( @args ) {
            return $class->$orig( _value => \@args );
        }
        else {
            return $class->$orig();
        }
    };

    method value_elements {
        return $self->_value_elements;
    }

    method value_firstElement {
        return $self->_value_get(0);
    }

    method value_push (Str|M4Macro @elements --> M4Value) {
        $self->_value_push(@elements);
        return $self;
    }

    method value_concat (Undef|M4Macro $macro?, Undef|PositiveOrZeroInt $paramPos? --> M4Value) {
        if ( $self->_value_count <= 0 ) {
            $self->_value( [''] );
            return $self;
        }

        if ( M4Macro->check($macro) ) {
         #
         # If we are providing a macro parameter, then a M4Macro is allowed if
         # it is the first element
         #
            my $firstElement = $self->_value_get(0);
            $paramPos //= 0;
            if ( M4Macro->check($firstElement)
                && $macro->macro_paramCanBeMacro($paramPos) )
            {
                #
                # Return first M4Macro element
                #
                $self->_value( [$firstElement] );
            }
            else {
                #
                # Skip all M4Macro elements
                #
                $self->_value(
                    [   join( '',
                            $self->_value_grep( sub { Str->check($_) } ) )
                    ]
                );
            }
        }
        else {
            #
            # Skip all M4Macro elements
            #
            $self->_value(
                [ join( '', $self->_value_grep( sub { Str->check($_) } ) ) ]
            );
        }

        return $self;
    }

    with 'MarpaX::Languages::M4::Role::Value';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::Languages::M4::Impl::Value - M4 Macro Parse Value generic implementation

=head1 VERSION

version 0.017

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
