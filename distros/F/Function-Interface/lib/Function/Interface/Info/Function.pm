package Function::Interface::Info::Function;

use v5.14.0;
use warnings;

our $VERSION = "0.02";

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
