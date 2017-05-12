package Dist::Maker::Logger;
use Mouse::Role;

sub _log_form {
    my($self, $prefix, @args) = @_;
    (my $id = ref($self)) =~ s/\A Dist::Maker:: //xms;

    return join '', $prefix, $id, ': ', @args;
}

sub info :method {
    my $self = shift;
    print STDOUT $self->_log_form(">  ", @_) if $self->verbose >= 4;
    return;
}

sub note :method {
    my $self = shift;
    print STDOUT $self->_log_form(">> ", @_) if $self->verbose >= 3;
    return;
}

sub warn :method {
    my $self = shift;
    print STDERR $self->_log_form("!  ", @_) if $self->verbose >= 2;
    return;
}

sub diag :method {
    my $self = shift;
    print STDERR $self->_log_form("!! ", @_) if $self->verbose >= 1;
    return;
}

no Mouse::Role;
1;
__END__

=head1 NAME

Dist::Maker::Logger - The logger role

=cut

