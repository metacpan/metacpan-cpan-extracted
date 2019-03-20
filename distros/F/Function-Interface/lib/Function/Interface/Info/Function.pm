package Function::Interface::Info::Function;

use v5.14.0;
use warnings;

our $VERSION = "0.04";

sub new {
    my ($class, %args) = @_;
    bless \%args => $class;
}

sub subname() { $_[0]->{subname} }
sub keyword() { $_[0]->{keyword} }
sub params() { $_[0]->{params} }
sub return() { $_[0]->{return} }

sub definition() {
    my $self = shift;

    sprintf('%s %s(%s) :Return(%s)',
        $self->keyword,
        $self->subname,
        (join ', ', map {
            sprintf('%s %s%s%s',
                $_->type_display_name,
                $_->named ? ':' : '',
                $_->name,
                $_->optional ? '=' : ''
            )
        } @{$self->params}),
        (join ', ', map {
            $_->type_display_name,
        } @{$self->return}),
    );
}

sub positional_required() {
    my $self = shift;
    $self->{positional_required} //= [ grep { !$_->named && !$_->optional } @{$self->params} ]
}

sub positional_optional() {
    my $self = shift;
    $self->{positional_optional} //= [ grep { !$_->named && $_->optional } @{$self->params} ]
}

sub named_required() {
    my $self = shift;
    $self->{named_required} //= [ grep { $_->named && !$_->optional } @{$self->params} ]
}

sub named_optional() {
    my $self = shift;
    $self->{named_optional} //= [ grep { $_->named && $_->optional } @{$self->params} ]
}

1;
__END__

=encoding utf-8

=head1 NAME

Function::Interface::Info::Function - information about abstract function of interface package

=head1 METHODS

=head2 new

Constructor of Function::Interface::Info::Function. This is usually called at Function::Interface::info.

=head2 subname

Returns an abstract function name

=head2 keyword

Returns the keyword used to define the abstract function, i.e. C<fun> or C<method

=head2 params

Returns a list of L<Function::Interface::Info::Function::Param>

=head3 positional_required

Returns positional required params

=head3 positional_optional

Returns positional optional params

=head3 named_required 

Returns named required params

=head3 named_optional

Returns named optional params

=head2 return

Returns a list of L<Function::Interface::Info::Function::ReturnParam>

=head2 definition

Returns the abstract function declaration string. For example, "Str $msg"

=head1 SEE ALSO

L<Function::Interface::Info>

