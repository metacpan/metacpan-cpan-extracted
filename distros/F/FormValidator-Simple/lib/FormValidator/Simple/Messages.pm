package FormValidator::Simple::Messages;
use strict;
use base 'Class::Accessor::Fast';
use YAML;
use FormValidator::Simple::Exception;

__PACKAGE__->mk_accessors(qw/decode_from/);
use Encode;

sub new {
    my $class = shift;
    my $self  = bless {
        _data   => undef,
        _format => "%s",
    }, $class;
    return $self;
}

sub format {
    my ($self, $format) = @_;
    if ($format) {
        $self->{_format} = $format;
    }
    $self->{_format};
}

sub load {
    my ($self, $data) = @_;
    if (ref $data eq 'HASH') {
        $self->{_data} = $data;
    }
    elsif (-e $data && -f _ && -r _) {
        eval {
        $self->{_data} = YAML::LoadFile($data);
        };
        if ($@) {
        FormValidator::Simple::Exception->throw(
        qq/failed to load YAML file. "$@"/
        );
        }
    }
    else {
        FormValidator::Simple::Exception->throw(
        qq/set hash reference or YAML file path./
        );
    }
}

sub get {
    my $self = shift;
    my $msg  = $self->_get(@_);
    if ($self->decode_from && !Encode::is_utf8($msg)) {
        $msg = Encode::decode($self->decode_from, $msg);
    }
    return sprintf $self->format, $msg;
}

sub _get {
    my ($self, $action, $name, $type) = @_;
    my $data = $self->{_data};
    unless ($data) {
        FormValidator::Simple::Exception->throw(
        qq/set messages before calling get()./
        );
    }

    unless ( $action && exists $data->{$action} ) {
        if ( exists $data->{DEFAULT} ) {
            if ( exists $data->{DEFAULT}{$name} ) {
                my $conf = $data->{DEFAULT}{$name};
                if ( exists $conf->{$type} ) {
                    return $conf->{$type};
                }
                elsif ( exists $conf->{DEFAULT} ) {
                    return $conf->{DEFAULT};
                }
            }
            else {
                return "$name is invalid.";
            }
        }
        else {
            return "$name is invalid.";
        }
    }
    if ( exists $data->{$action}{$name} ) {
        my $conf = $data->{$action}{$name};
        if ( exists $conf->{$type} ) {
            return $conf->{$type};
        }
        elsif ( exists $conf->{DEFAULT} ) {
            return $conf->{DEFAULT};
        }
        elsif ( exists  $data->{DEFAULT}
              && exists $data->{DEFAULT}{$name} ) {
            my $conf = $data->{DEFAULT}{$name};
            if ( exists $conf->{$type} ) {
                return $conf->{$type};
            }
            elsif ( exists $conf->{DEFAULT} ) {
                return $conf->{DEFAULT};
            }
        }
    }
    elsif ( exists $data->{DEFAULT}
         && exists $data->{DEFAULT}{$name} ) {
        my $conf = $data->{DEFAULT}{$name};
        if ( exists $conf->{$type} ) {
            return $conf->{$type};
        }
        elsif ( exists $conf->{DEFAULT} ) {
            return $conf->{DEFAULT};
        }
    }
    return "$name is invalid.";
}

1;
__END__

