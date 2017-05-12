package FormValidator::Simple::ArrayList;
use strict;
use base qw/Class::Accessor::Fast/;
use FormValidator::Simple::Iterator;

__PACKAGE__->mk_accessors(qw/records/);

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->records( [ ] );
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, @args) = @_;
}

sub append {
    my ($self, $record) = @_;
    push @{ $self->records }, $record;
}

sub get_record_at {
    my ($self, $index) = @_;
    return $self->records->[$index];
}

sub records_count {
    my $self = shift;
    return scalar @{ $self->records };
}

sub iterator {
    my $self = shift;
    return FormValidator::Simple::Iterator->new($self);
}

1;
__END__

