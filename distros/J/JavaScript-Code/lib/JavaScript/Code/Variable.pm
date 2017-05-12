package JavaScript::Code::Variable;

use strict;
use vars qw[ $VERSION ];
use base qw[
  JavaScript::Code::Element
  JavaScript::Code::Value
  JavaScript::Code::Expression::Node::Arithmetic
];

use Scalar::Util           ();
use JavaScript::Code::Type ();

use overload
  '""' => sub { shift->full_name },
  'eq' => \&same,
  '==' => \&equal;

__PACKAGE__->mk_accessors(qw[ index name declared ref ]);

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Variable - A JavaScript Variable Element

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::Code::Variable;

    my $string = JavaScript::Code::Variable->new();
    $string->name( 'a' );
    $string->value( 'This is a Test!' );
    print $string->output;

    my $number = JavaScript::Code::Variable->new()->name('b')->value( 288957 );
    print $number->output;

    my $strnumber = JavaScript::Code::Variable->new( name => 'c' );
    $strnumber->value( JavaScript::Code::String->new(value => 288957) );
    print $strnumber->output;

    my $array = JavaScript::Code::Variable->new( { name => 'd' } );
    $array->value( [0, 1] );
    print $array->output;


=head1 DESCRIPTION

A JavaScript Variable Element Class

Example:

    var a = 42;      // Variable a with a nummeric value of 42
    var b = "Test!"; // Variable b with a string value of "Test!"

=head1 METHODS

=head2 new

=cut

sub new {
    my $obj   = shift;
    my $class = ref $obj || $obj;

    my $self = $class->SUPER::new(@_);
    $self->value( $self->{value} );

    return $self;
}

=head2 $self->name( $name )

Gets or sets the name of the variable.

=cut

=head2 $self->full_name( )

Gets the full name, that is, the name including the any index information

=cut

sub full_name {
    my $self = shift;

    my $name = $self->name;
    die "No name defined."
      unless $name;

    die "Not a valid 'JavaScript::Code::Variable' name: '$name'"
      unless $self->is_valid_name($name);

    $name .= "[" . $self->index . "]"
      if defined $self->index;

    return $name;
}

=head2 $self->value( $value )

Gets or sets the value of the variable.

=cut

sub value {
    my $self = shift;
    if (@_) {

        my %args = ();
        if ( @_ == 1 ) {
            if ( ref $_[0] eq 'HASH' ) {
                %args = %{ $_[0] };
            }
            else {
                $args{value} = $_[0];
            }
        }
        else {
            %args = @_;
        }

        $self->{value} =
          JavaScript::Code::Type->build( value => delete $args{value} );
        $self->{index} = $args{index} if exists $args{index};

        return $self;
    }
    else {

        my $value = $self->{value};
        $self->value($value)
          unless ref $value
          and $value->isa('JavaScript::Code::Value');
        return $self->{value};
    }
}

=head2 $self->declared( undef | 0 | 1 )

If set to undef, the module will check the scope to decide whether or not the variable should be declared.

If set to 0, the module is undeclared und will be declared in its context.

If set to 1, the variable will to be declared in its context.

=cut

=head2 $self->output( )

Returns the javascript-code for that variable.

=cut

sub output {
    my $self  = shift;
    my $scope = shift || 1;

    my $name = $self->full_name;
    die "A 'JavaScript::Code::Variable' needs a name."
      unless $name;

    my $indenting = $self->get_indenting($scope);
    my $output    = '';

    $self->declared(1)
      if $name =~ m!\[.*\]$!;

    my $declared =
      defined $self->declared
      ? $self->declared
      : $self->exists_in_parent($self);

    $output .= $indenting;
    $output .= 'var ' unless $declared;
    $output .= $name;

    if ( defined( my $value = $self->value ) ) {
        die "Not a 'JavaScript::Code::Value'."
          unless ref $value
          and $value->isa('JavaScript::Code::Value');
        $output .= ' = ';
        $output .= $value->output;
    }

    $output .= ";\n";

    return $output;
}

=head2 $self->same( $var )

Two variables are the same if they have the same name.

=cut

sub same {
    my ( $self, $other ) = @_;

    return 0 unless $other->isa('JavaScript::Code::Variable');
    return $self->name eq $other->name;
}

=head2 $self->equal( $var )

Two variables are equal if they have the same value.

=cut

sub equal {
    my ( $self, $other ) = @_;

    return 0 unless $other->isa('JavaScript::Code::Variable');
    return $self->value eq $other->value;
}

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
