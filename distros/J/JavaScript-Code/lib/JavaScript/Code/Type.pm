package JavaScript::Code::Type;

use strict;
use vars qw[ $VERSION ];
use base qw[
  JavaScript::Code::Accessor
  JavaScript::Code::Value
];

use overload '""' => sub { shift->output };

__PACKAGE__->mk_accessors(qw[ type value ]);

use JavaScript::Code::String ();
use JavaScript::Code::Number ();
use JavaScript::Code::Array  ();
use JavaScript::Code::Hash   ();

$VERSION = '0.08';

=head1 NAME

JavaScript::Code::Type - A JavaScript Type

=head1 SYNOPSIS

    #!/usr/bin/perl

    use strict;
    use warnings;
    use JavaScript::Code::Type;

    my $type = JavaScript::Code::Type->new({ type => 'String' })->value("Go for it!");

    print $type->output;


=head1 METHODS

=head2 JavaScript::Code::Type->new( )

=cut

sub new {
    my $this  = shift;
    my $class = ref($this) || $this;

    return $class->SUPER::new(@_)
      unless $class eq __PACKAGE__;

    my $args = shift;

    my $via = lc( delete $args->{type} || '' )
      or die "No type provided.";

    $via = ucfirst $via;
    $via = "JavaScript::Code::$via";

    eval "require $via";    # make sure, it is loaded
    die $@ if $@;

    return $via->new( $args, @_ );
}

=head2 $self->type( )

Returns a string that represents the underlaying type.

=cut

=head2 $self->value( $value )

Gets or sets the associated value.

=head2 $self->build( )

=cut

sub build {
    my $this  = shift;
    my $class = ref($this) || $this;

    my $ref = @_ ? Scalar::Util::reftype( $_[0] ) || '' : '';

    my %args  = $ref eq 'HASH' ? %{ shift() } : @_;
    my $value = $args{value};

    my $object;
    if ( defined $value ) {

        my $reftype = ref $value;

        if ( $reftype eq 'ARRAY' ) {
            $object = JavaScript::Code::Array->new( { value => $value } );
        }
        elsif ( $reftype eq 'HASH' ) {
            $object = JavaScript::Code::Hash->new( { value => $value } );
        }
        elsif ( $reftype eq 'SCALAR' or $reftype eq '' ) {
            $value = $reftype eq 'SCALAR' ? ${$value} : $value;
            $object =
              Scalar::Util::looks_like_number($value)
              ? JavaScript::Code::Number->new( { value => $value } )
              : JavaScript::Code::String->new( { value => $value } );
        }
        elsif ( $value->isa('JavaScript::Code::Value') ) {
            $object = $value;
        }

        die "Unexpected type '$reftype'." unless defined $object;
    }

    return $object;
}

=head2 $self->output( )

Returns the javascript-code for that type.

=cut

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

