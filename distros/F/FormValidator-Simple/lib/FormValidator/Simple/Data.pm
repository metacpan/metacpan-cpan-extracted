package FormValidator::Simple::Data;
use strict;
use Scalar::Util;
use FormValidator::Simple::Exception;
use FormValidator::Simple::Constants;

sub new {
    my $class = shift;
    my $self  = bless { }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, $input) = @_;
    $self->{_records} = {};
    my $errmsg = qq/Set input data as a hashref or object that has the method 'param()'./;
    if ( Scalar::Util::blessed($input) ) {
        unless ( $input->can('param') ) {
            FormValidator::Simple::Exception->throw($errmsg);
        }
        foreach my $key ( $input->param ) {
            my @v = $input->param($key);
            $self->{_records}{$key} = scalar(@v) > 1 ? \@v : $v[0];
        }
    }
    elsif ( ref $input eq 'HASH' ) {
        $self->{_records} = $input;
    }
    else {
        FormValidator::Simple::Exception->throw($errmsg);
    }
}

sub has_key {
    my ($self, $key) = @_;
    return exists $self->{_records}{$key} ? TRUE : FALSE;
}

sub param {
    my ($self, $keys) = @_;
    my @values = map {
        exists $self->{_records}{$_}
             ? $self->{_records}{$_}
             : ''
             ;
    } @$keys;
    return wantarray ? @values : \@values;
}

1;
__END__

