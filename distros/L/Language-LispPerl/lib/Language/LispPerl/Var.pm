package Language::LispPerl::Var;
$Language::LispPerl::Var::VERSION = '0.007';
use Moose;
use Moose::Util::TypeConstraints;

use Language::LispPerl::Printer;
use Language::LispPerl::Reader;

has 'name' => ( is => 'ro', isa => 'Str', required => 1 );
has 'value' => ( is => 'rw' , isa => union(['Undef',
                                            'Str',
                                            class_type( 'Language::LispPerl::Atom'),
                                            class_type('Language::LispPerl::Seq') ] ) );

sub to_hash{
    my ($self) = @_;
    return {
        name => $self->name(),
        value => Language::LispPerl::Printer::to_perl( $self->value() ),
        __class => $self->blessed(),
    };
}

sub from_hash{
    my ($class, $hash) = @_;
    return $class->new({
        map{ $_ => Language::LispPerl::Reader::from_perl( $hash->{$_} ) } keys %$hash
    });
}

__PACKAGE__->meta()->make_immutable();
1;

=head1 NAME

Language::LispPerl::Var - A variable with a name (ro) and a value (rw)

=cut
