package Error::ROP::Imp;
use Moose;

has value => (is => 'ro', required => 0, default => undef);
has failure => (is => 'ro', required => 0, default => '');

sub is_valid {
    return shift->failure eq '';
}

sub _then_hash {
    my ($self, @then_clauses) = @_;
    my $either = $self;

    my $length = @then_clauses / 2;
    for(my $i = 0; $i < $length; $i++) {
        my $err = $then_clauses[2 * $i];
        my $fn = $then_clauses[2 * $i + 1];
        if ($either->is_valid) {
            local $_ = $either->value;
            my $res = eval {
                $fn->($_);
            };
            if ($@) {
                my $msg = length $err > 0 && $err ne 'undef' ? $err : $@;
                return Error::ROP::Imp->new(failure => $msg);
            }
            $either = Error::ROP::Imp->new(value => $res);
        }
    }

    return $either;
}

sub _then_list {
    my ($self, @then_clauses) = @_;
    my $either = $self;

    my $length = @then_clauses;
    for(my $i = 0; $i < $length; $i++) {
        my $fn = $then_clauses[$i];
        if ($either->is_valid) {
            local $_ = $either->value;
            my $res = eval {
                $fn->($_);
            };
            if ($@) {
                return Error::ROP::Imp->new(failure => $@);
            }
            $either = Error::ROP::Imp->new(value => $res);
        }
    }

    return $either;
}

sub _wrap_call_with_dollar {
    my $either = shift;
    my $fn = shift;
    if ($either->is_valid) {
        local $_ = $either->value;
        my $res = eval {
            $fn->($_);
        };
        if ($@) {
            return Error::ROP::Imp->new(failure => $@);
        }
        $either = Error::ROP::Imp->new(value => $res);
    }
}

sub then {
    my ($self, @then_clauses) = @_;

    if((scalar @then_clauses) % 2 == 0) {
        $self->_then_hash(@then_clauses);
    }
    else {
        $self->_then_list(@then_clauses);
    }
}

__PACKAGE__->meta->make_immutable;
1;
