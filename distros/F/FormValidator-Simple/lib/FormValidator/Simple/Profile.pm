package FormValidator::Simple::Profile;
use strict;
use base qw/FormValidator::Simple::ArrayList/;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Iterator;

sub _init {
    my($self, $prof) = @_;
    for (my $i = 0; $i <= $#{$prof}; $i += 2) {
        my ($key, $constraints) = ($prof->[$i], $prof->[$i + 1]);
        my $record = FormValidator::Simple::Profile::Record->new;
        $record->set_keys($key);
        $record->set_constraints($constraints);
        $self->append($record);
    }
}

sub iterator {
    my $self = shift;
    return FormValidator::Simple::Profile::Iterator->new($self);
}

package FormValidator::Simple::Profile::Record;
use base qw/Class::Accessor::Fast/;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;
use FormValidator::Simple::Constraints;
use FormValidator::Simple::Constraint;

__PACKAGE__->mk_accessors(qw/name keys constraints/);

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    $self->name( q{ } );
    $self->keys( [] );
    $self->constraints( FormValidator::Simple::Constraints->new );
}

sub set_keys {
    my ($self, $keys) = @_;
    if (ref $keys) {
        if (ref $keys eq 'HASH') {
            my ($name) = keys %$keys;
            my $params = $keys->{$name};
            $self->name($name);
            if(ref $params) {
                $self->keys( $params   );
            }
            else {
                $self->keys( [$params] );
            }
        }
        else {
            FormValidator::Simple::Exception->throw(
                qq/set keys of profile as hashref or single scalar./
            );
        }
    }
    else {
        $self->name( $keys   );
        $self->keys( [$keys] );
    }
}

sub set_constraints {
    my ($self, $constraints) = @_;
    $self->constraints( FormValidator::Simple::Constraints->new );
    if (ref $constraints) {

        if (ref $constraints eq 'ARRAY') {

            SETTING:
            foreach my $setting ( @$constraints ) {
                my $const = FormValidator::Simple::Constraint->new($setting);
                if ($const->name eq 'NOT_BLANK') {
                    $self->constraints->needs_blank_check( TRUE );
                    next SETTING;
                }
                else {
                    $self->constraints->append($const);
                }
            }

        }
        else {
            FormValidator::Simple::Exception->throw(
                qq/set constraints as arrayref or single scalar./
            );
        }
    }
    else {
        my $const = FormValidator::Simple::Constraint->new($constraints);
        if ($const->name eq 'NOT_BLANK') {
            $self->constraints->needs_blank_check( TRUE );
        }
        else {
            $self->constraints->append($const);
        }
    }
}

package FormValidator::Simple::Profile::Iterator;
use base qw/FormValidator::Simple::Iterator/;

1;
__END__

