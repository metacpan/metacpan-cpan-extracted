use strict;
use warnings;

package Footprintless::Plugin::Database::PreparedStatementTemplate;
$Footprintless::Plugin::Database::PreparedStatementTemplate::VERSION = '1.04';
use Carp;
use Carp 'verbose';
use Data::Dumper;
use Log::Any;

my $logger = Log::Any->get_logger();

sub new {
    my $self = bless( {}, shift );
    $self->_init(@_);
}

sub _init {
    my ( $self, $sql_template, %bindings ) = @_;
    my @binding_keys =
        sort { ( length($b) <=> length($a) ) || ( $a cmp $b ) }
        keys(%bindings);
    my @split_text;
    my @index_to_key;
    $self->{bindings} =
        { map { $_ => _transform_binding( $_, $bindings{$_} ) } @binding_keys };
    _dice( _remove_comments($sql_template), \@split_text, \@index_to_key, @binding_keys );
    $self->{prepared_statement} = join( '?', @split_text );
    $self->{parameter_bindings} =
        [ map { $self->{bindings}->{$_} } @index_to_key ];

    my %used_keys = map { $_ => 1 } @index_to_key;
    foreach my $unused_key ( grep { !$used_keys{$_} } @binding_keys ) {
        $logger->warn("Template var [$unused_key] is never used!");
        delete( $self->{bindings}->{$unused_key} );
    }
    return $self;
}

sub _bind {
    my ( $binding, $context ) = @_;
    if ( defined( my $key = $binding->{key} ) ) {
        eval { $binding->{value} = $context->$key() }
            if ( !defined( $binding->{value} = $context->{$key} ) );
        croak(
            "Cannot bind template var [$binding->{template_key}] - property [$key] cannot be bound in context"
        ) unless defined( $binding->{value} );
    }
    elsif ( defined( my $reference = $binding->{reference} ) ) {
        croak("Cannot bind template var [$binding->{template_key}] - reference to undefined")
            unless defined( $binding->{value} = $$reference );
    }
    elsif ( defined( my $code = $binding->{code} ) ) {
        croak("Cannot bind template var [$binding->{template_key}] - code returns undefined")
            unless defined( $binding->{value} = $code->() );
    }
}

sub _dice {
    my ( $text, $split_text, $index_to_key, $key, @keys ) = @_;
    if ( !$key ) {
        push( @$split_text, $text );
    }
    else {
        my $add_ix = 0;

        # We need at least one element with a blank string in split...
        foreach ( $text ? split( /\Q$key\E/, $text, -1 ) : ('') ) {
            push( @$index_to_key, $key ) if ( $add_ix++ );
            _dice( $_, $split_text, $index_to_key, @keys );
        }
    }
}

sub query {
    my ( $self, $context ) = @_;
    my $query = { sql => $self->{prepared_statement} };
    if ( %{ $self->{bindings} } ) {
        foreach ( values( %{ $self->{bindings} } ) ) { _bind( $_, $context ) }
        $query->{parameters} =
            [ map { $_->{value} } @{ $self->{parameter_bindings} } ];
        foreach ( values( %{ $self->{bindings} } ) ) { _unbind( $_, $context ) }
    }
    return $query;
}

sub _remove_comments {
    my ($sql) = @_;
    my $sql_out;
    open( my $fh, '>', \$sql_out ) || croak("Cannot write to string!");
    my ( $in_block_comment, $in_line_comment, $in_quote ) = ( 0, 0, 0 );
    for ( my $ix = 0; $ix < length($sql); ++$ix ) {
        if ($in_block_comment) {
            if ( substr( $sql, $ix, 2 ) eq '*/' ) {
                $in_block_comment = 0;
                ++$ix;
            }
        }
        elsif ($in_line_comment) {
            if ( substr( $sql, $ix, 1 ) eq "\n" ) {
                $in_line_comment = 0;
                print $fh ("\n");
            }
        }
        else {
            my $char = substr( $sql, $ix, 1 );
            if ( !$in_quote && $char eq '/' && substr( $sql, $ix + 1, 1 ) eq '*' ) {
                $in_block_comment = 1;
                ++$ix;
            }
            elsif ( !$in_quote && $char eq '-' && substr( $sql, $ix + 1, 1 ) eq '-' ) {
                $in_line_comment = 1;
                ++$ix;
            }
            else {
                $in_quote = !$in_quote if ( $char eq "'" );
                print $fh ($char);
            }
        }
    }
    close $fh;
    return $sql_out;
}

sub _transform_binding {
    my ( $template_key, $binding ) = @_;
    my $ref = ref($binding);
    my $new_binding = { template_key => $template_key };
    if ( my $key = ( ( !$ref && $binding ) || ( $ref eq 'HASH' && $binding->{key} ) ) ) {
        $new_binding->{key} = $key;
    }
    elsif ( my $reference =
        ( ( $ref eq 'SCALAR' && $binding ) || ( $ref eq 'HASH' && $binding->{reference} ) ) )
    {
        croak(
            "Template var [$template_key] - 'reference' property of binding is not a 'SCALAR' ref"
        ) unless ref($reference) eq 'SCALAR';
        $new_binding->{reference} = $reference;
    }
    elsif ( $ref eq 'HASH' && defined( $binding->{value} ) ) {
        croak("'Template var [$template_key] - value' property of binding is a ref")
            if ref( $binding->{value} );
        $new_binding->{value} = $binding->{value};
    }
    elsif ( my $code =
        ( ( $ref eq 'CODE' && $binding ) || ( $ref eq 'HASH' && $binding->{code} ) ) )
    {
        croak("Template var [$template_key] - 'code' property of binding is not a 'CODE' ref")
            unless ref($code) eq 'CODE';
        $new_binding->{code} = $code;
    }
    else {
        croak( "Template var [$template_key] - binding [%s] is invalid", Dumper($binding) );
    }
    return $new_binding;
}

sub _unbind {
    my ($binding) = @_;
    delete( $binding->{value} )
        if defined( $binding->{key} )
        || defined( $binding->{reference} )
        || defined( $binding->{code} );
}

1;

__END__

=pod

=head1 NAME

Footprintless::Plugin::Database::PreparedStatementTemplate

=head1 VERSION

version 1.04

=head1 SYNOPSIS

    use Footprintless::Plugin::Database::PreparedStatementTemplate;
    
    my $second_fruit;
    my $statement = Footprintless::Plugin::Database::PreparedStatementTemplate->new(
        "SELECT * FROM fruit_basket WHERE fruit IN ('_FRUIT_1_', '_FRUIT_2_', '_FRUIT_3_')",
        _FRUIT_1_ => 'first_fruit',
        _FRUIT_2_ => sub { $second_fruit },
        _FRUIT_3_ => { value => 'banana' }
    );
    
    my $context = { first_fruit => 'grape' };
    $second_fruit = 'apple';
    
    my $query1 = $statement->query($context);
    croak("query1 SQL bad")
      unless $query1->{sql} eq
      "SELECT * FROM fruit_basket WHERE fruit IN ('?', '?', '?')";
    croak("query1, param[0] bad") unless $query1->{parameters}->[0] eq 'grape';
    croak("query1, param[1] bad") unless $query1->{parameters}->[1] eq 'apple';
    croak("query1, param[2] bad") unless $query1->{parameters}->[2] eq 'banana';
    
    $context->{first_fruit} = 'pear';
    $second_fruit = 'strawberry';
    
    my $query2 = $statement->query($context);
    croak("query2 SQL bad")
      unless $query2->{sql} eq
      "SELECT * FROM fruit_basket WHERE fruit IN ('?', '?', '?')";
    croak("query2, param[0] bad") unless $query2->{parameters}->[0] eq 'pear';
    croak("query2, param[1] bad") unless $query2->{parameters}->[1] eq 'strawberry';
    croak("query2, param[2] bad") unless $query2->{parameters}->[2] eq 'banana';

=head1 DESCRIPTION

Footprintless::Plugin::Database::PreparedStatementTemplate

Prepared statements are a best practice, yet they are a pain in the neck, since
every parameter is represented by a '?' and the parameters are provided in an
array of values that correspond to the '?' in the prepared statement. This
class allows the user to create these painful prepared statements using named
parameters AND binding them to a context either by properties, hard-coded values,
and/or closures.

=head1 CONSTRUCTORS

=head2 C<new($sql_template, %bindings)>

Creates the prepared statement template with the given bindings. The key of each
binding is the string to replace in the C<$sql_template> and the value of each binding
tells this prepared statement template how to bind values to each of the parameters.
The binding value may be one of the following:

=over 4

=item B<key>

To bind a property from a context, the binding value should be a simple string with
the property name, or a hash-ref like this: C<{ key => 'property_name' }> 

=item B<code>

To bind a property to a value returned from a closure, the binding value should be
a CODE (subroutine) ref, or a hash-ref like this: C<{ code => sub {...} }>

=item B<reference>

To bind a property to a reference (variable), the binding value should be a
scalar-ref, or a hash-ref like this: C<{ reference => \$variable }>

=item B<value>

To bind a property to a constant value, the binding value should be a hash-ref like
this: C<{ value => 'constant_value' }>

=back

=head1 METHODS

=head2 C<query($context)>

Generate a query acceptable to the C<Footprintless::Plugin::Database::AbstractProvider>
using this prepared statement template and a context to bind to. The context is either
a class instance or hash-ref that has the properties identified in the bindings passed
to the constructor. Properties are primarily a property of the hash-ref, but if it is
not defined, the prepared statement template will attempt to call a no-arg method that
has the name of the property to extract it's value.

=head1 AUTHOR

Lucas Theisen <lucastheisen@pastdev.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Lucas Theisen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Footprintless::Plugin::Database|Footprintless::Plugin::Database>

=item *

L<C<Footprintless::Plugin::Database::AbstractProvider>|C<Footprintless::Plugin::Database::AbstractProvider>>

=back

=cut
