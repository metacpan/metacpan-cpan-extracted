package FormValidator::Simple::Iterator;
use strict;

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, $records) = @_;
    $self->{_index}   = 0;
    $self->{_records} = $records;
}

sub reset {
    my $self = shift;
    $self->{_index} = 0;
}

sub next {
    my $self = shift;
    return unless ($self->{_records}->records_count > $self->{_index});
    my $record = $self->{_records}->get_record_at($self->{_index});
    $self->{_index}++;
    return $record;
}

1;
__END__

