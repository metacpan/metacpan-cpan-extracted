package JavaScript::Code::Function;

use strict;
use vars qw[ $VERSION ];
use base qw[ JavaScript::Code::Element ];
use JavaScript::Code::Function::Result  ();
use JavaScript::Code::Function::BuildIn ();

__PACKAGE__->mk_accessors(qw[ name parameters is_buildin ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Function - A JavaScript Function

=head1 METHODS

=cut

=head2 $self->name( $name )

Sets or gets the function name.

=cut

=head2 $self->block( $block )

Sets or gets the code block of the function.

I<$block> must be a L<JavaScript::Code::Block>

=cut

sub block {
    my $self = shift;
    if (@_) {
        my $args = $self->args(@_);

        my $block = $args->{block} || shift;
        die "Block must be a 'JavaScript::Code::Block'."
          unless ref $block
          and $block->isa('JavaScript::Code::Block');

        $self->{block} = $block->clone->parent($self);

        return $self;
    }
    else {
        return $self->{block};
    }
}

=head2 $self->is_buildin( )

Returns whether or not the function is a build-in function

=cut

sub is_buildin { return 0; }

=head2 $self->check_name( )

=cut

sub check_name {
    my $self = shift;

    my $name = $self->name;
    die "A 'JavaScript::Code::Function' needs a name."
      unless $name;

    die "Not a valid 'JavaScript::Code::Function' name: '$name'"
      unless $self->is_valid_name($name, $self->is_buildin );

    return $name;
}

=head2 $self->call( )

Calls the functions. Returns a L<JavaScript::Code::Function::Result>.

=cut

sub call {
    my $self = shift;

    my $params = $self->args(@_)->{parameters} || $_[0] || [];
    my $name   = $self->check_name;

    $params = [$params] unless ref $params eq 'ARRAY';

    my $result = '';
    $result .= "$name ( ";
    $result .= join(", ", @{$params});
    $result .= " )";

    return JavaScript::Code::Function::Result->new( value => $result );
}

=head2 $self->output( )

=cut

sub output {
    my $self  = shift;
    my $scope = shift || 1;

    die "Can not defined a build-in function."
      if $self->is_buildin;

    my $name      = $self->check_name;
    my $indenting = $self->get_indenting($scope);
    my $output    = '';

    $output .= $indenting;
    $output .= "function $name ( ";

    $self->parameters( [] ) unless defined $self->parameters;

    $output .= join(
        ', ',
        map {
            die "Not a valid 'JavaScript::Code::Function' parameter name: '$_'"
              unless $self->is_valid_name($_);
            $_
          } @{ $self->parameters }
    );

    $output .= " )\n";

    if ( defined(my $block = $self->block) ) {
        $output .= $block->output($scope);
    }
    else {
        $output .= $indenting;
        $output .= "{\n";
        $output .= $indenting;
        $output .= "}\n";
    }

    return $output;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

1;
