package FormValidator::Simple::Validator;
use strict;
use base qw/Class::Data::Inheritable/;

use FormValidator::Simple::Constants;
use FormValidator::Simple::Exception;
use Email::Valid;
use Email::Valid::Loose;
use Date::Calc;
use UNIVERSAL::require;
use List::MoreUtils;
use DateTime::Format::Strptime;

__PACKAGE__->mk_classdata( options => { } );

sub SP {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /\s/ ? TRUE : FALSE;
}

*SPACE = \&SP;

sub INT {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /^\-?[\d]+$/ ? TRUE : FALSE;
}

sub UINT {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /^\d+$/ ? TRUE : FALSE;
}

sub ASCII {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /^[\x21-\x7E]+$/ ? TRUE : FALSE;
}

sub DUPLICATION {
    my ($self, $params, $args) = @_;
    my $data1 = $params->[0];
    my $data2 = $params->[1];
    unless (defined $data1 && defined $data2) {
        FormValidator::Simple::Exception->throw(
        qq/validation "DUPLICATION" needs two keys of data./
        );
    }
    return $data1 eq $data2 ? TRUE : FALSE;
}

sub LENGTH {
    my ($self, $params, $args) = @_;
    unless ( scalar(@$args) > 0 ) {
        FormValidator::Simple::Exception->throw(
        qq/validation "LENGTH" needs one or two arguments./
        );
    }
    my $data   = $params->[0];
    my $length = length $data;
    my $min    = $args->[0];
    my $max    = $args->[1] || $min;
    $min += 0;
    $max += 0;
    return $min <= $length && $length <= $max ? TRUE : FALSE;
}

sub REGEX {
    my ($self, $params, $args) = @_;
    my $data  = $params->[0];
    my $regex = $args->[0];
    return $data =~ /$regex/ ? TRUE : FALSE;
}

sub EMAIL {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FALSE unless $data;
    return Email::Valid->address(-address => $data) ? TRUE : FALSE;
}

sub EMAIL_MX {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FALSE unless $data;
    return Email::Valid->address(-address => $data, -mxcheck => 1) ? TRUE : FALSE;
}

sub EMAIL_LOOSE {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FALSE unless $data;
    return Email::Valid::Loose->address($data) ? TRUE : FALSE;
}

sub EMAIL_LOOSE_MX {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return FALSE unless $data;
    return Email::Valid::Loose->address(-address => $data, -mxcheck => 1) ? TRUE : FALSE;
}

sub DATE {
    my ($self, $params, $args) = @_;
    my ($year, $month,  $day ) = @$params;
    my $result = Date::Calc::check_date($year, $month, $day) ? TRUE : FALSE;
    my $data;
    if ($result) {
        my $class = $self->options->{datetime_class} || '';
        if ($class eq 'DateTime') {
            $class->require;
            if ($@) {
            FormValidator::Simple::Exception->throw(
            qq/Validation DATE: failed to require $class. "$@"./
            );
            }
            my %date = (
                year  => $year,
                month => $month,
                day   => $day,
            );
            if ($self->options->{time_zone}) {
                $date{time_zone} = $self->options->{time_zone};
            }
            $data = $class->new(%date);
        }
        elsif ($class eq 'Time::Piece') {
            $data = sprintf "%04d-%02d-%02d 00:00:00", $year, $month, $day;
            $class->require;
            if ($@) {
            FormValidator::Simple::Exception->throw(
            qq/Validation DATE: failed to require $class. "$@"./
            );
            }
            $data = $class->strptime($data, "%Y-%m-%d %H:%M:%S");
        }
        else {
            $data = sprintf "%04d-%02d-%02d 00:00:00", $year, $month, $day;
        }
    }
    return ($result, $data);
}

sub TIME {
    my ($self, $params, $args) = @_;
    my ($hour, $min,    $sec ) = @$params;
    $hour ||= 0;
    $min  ||= 0;
    $sec  ||= 0;
    my $result = Date::Calc::check_time($hour, $min, $sec) ? TRUE : FALSE;
    my $time = $result ? sprintf("%02d:%02d:%02d", $hour, $min, $sec) : undef;
    return ($result, $time);
}

sub DATETIME {
    my ($self, $params, $args) = @_;
    my ($year, $month, $day, $hour, $min, $sec) = @$params;
    $hour ||= 0;
    $min  ||= 0;
    $sec  ||= 0;
    my $result = Date::Calc::check_date($year, $month, $day)
              && Date::Calc::check_time($hour, $min,   $sec) ? TRUE : FALSE;
    my $data;
    if ($result) {
        my $class = $self->options->{datetime_class} || '';
        if ($class eq 'DateTime') {
            $class->require;
            if ($@) {
            FormValidator::Simple::Exception->throw(
            qq/Validation DATETIME: failed to require $class. "$@"./
            );
            }
            my %date = (
                year   => $year,
                month  => $month,
                day    => $day,
                hour   => $hour,
                minute => $min,
                second => $sec,
            );
            if ($self->options->{time_zone}) {
                $date{time_zone} = $self->options->{time_zone};
            }
            $data = $class->new(%date);
        }
        elsif ($class eq 'Time::Piece') {
            $data = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
                $year, $month, $day, $hour, $min, $sec;
            $class->require;
            if ($@) {
            FormValidator::Simple::Exception->throw(
            qq/Validation DATETIME: failed to require $class. "$@"./
            );
            }
            $data = $class->strptime($data, "%Y-%m-%d %H:%M:%S");
        }
        else {
            $data = sprintf "%04d-%02d-%02d %02d:%02d:%02d",
                $year, $month, $day, $hour, $min, $sec;
        }
    }
    return ($result, $data);
}

sub ANY {
    my ($self, $params, $args) = @_;
    foreach my $param ( @$params ) {
        return TRUE if ( defined $param && $param ne '' );
    }
    return FALSE;
}

sub HTTP_URL {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    return $data =~ /^s?https?:\/\/[-_.!~*'()a-zA-Z0-9;\/?:\@&=+\$,%#]+$/ ? TRUE : FALSE;
}

sub SELECTED_AT_LEAST {
    my ($self, $params, $args) = @_;
    my $data     = $params->[0];
    my $selected = ref $data ? $data : [$data];
    my $num      = $args->[0] + 0;
    return scalar(@$selected) >= $num ? TRUE : FALSE;
}

sub GREATER_THAN {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    my $target = $args->[0];
    my $regex = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;
    unless ( defined $target && $target =~ /$regex/ ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation GREATER_THAN needs a numeric argument./
        );
    }
    return FALSE unless $data =~ /$regex/;
    return ( $data > $target ) ? TRUE : FALSE;
}

sub LESS_THAN {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    my $target = $args->[0];
    my $regex = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;
    unless ( defined $target && $target =~ /$regex/ ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation LESS_THAN needs a numeric argument./
        );
    }
    return FALSE unless $data =~ /$regex/;
    return ( $data < $target ) ? TRUE : FALSE;
}

sub EQUAL_TO {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    my $target = $args->[0];
    my $regex = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;
    unless ( defined $target && $target =~ /$regex/ ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation EQUAL_TO needs a numeric argument./
        );
    }
    return FALSE unless $data =~ /$regex/;
    return ( $data == $target ) ? TRUE : FALSE;
}

sub BETWEEN {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    my $start = $args->[0];
    my $end   = $args->[1];
    my $regex = qr/^[-+]?[0-9]+(:?\.[0-9]+)?$/;
    unless ( defined($start) && $start =~ /$regex/ && defined($end) && $end =~ /$regex/ ) {
        FormValidator::Simple::Exception->throw(
            qq/Validation BETWEEN needs two numeric arguments./
        );
    }
    return FALSE unless $data =~ /$regex/;
    return ( $data >= $start && $data <= $end ) ? TRUE : FALSE;
}

sub DECIMAL {
    my ($self, $params, $args) = @_;
    my $data = $params->[0];
    unless ( scalar(@$args) > 0 ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation DECIMAL needs one or two numeric arguments./
        );
    }
    my $digit1 = $args->[0];
    my $digit2 = $args->[1] || 0;
    unless ( $digit1 =~ /^\d+$/ && $digit2 =~ /^\d+$/ ) {
        FormValidator::Simple::Exception->throw(
        qq/Validation DECIMAL needs one or two numeric arguments./
        );
    }
    return FALSE unless $data =~ /^\d+(\.\d+)?$/;
    my $reg = qr/^\d{1,$digit1}(\.\d{0,$digit2})?$/;
    return $data =~ /$reg/ ? TRUE : FALSE;
}

sub ALL {
    my ($self, $params, $args) = @_;
    foreach my $param ( @$params ) {
        unless ( defined $param && $param ne '' ) {
            return FALSE;
        }
    }
    return TRUE;
}

sub IN_ARRAY {
    my ($class, $params, $args) = @_;
    my $data = defined $params->[0] ? $params->[0] : '';
    return (List::MoreUtils::any { $_ eq $data } @$args) ? TRUE : FALSE;
}

sub DATETIME_FORMAT {
    my ( $self, $params, $args ) = @_;
    my $date   = $params->[0];
    my $format = $args->[0];
    FormValidator::Simple::Exception->throw(
        qq/Validation DATETIME_FORMAT needs a format argument./)
      unless $format;

    my $module;
    if ( ref $format ) {
        $module = $format;
    }
    else {
        $module = "DateTime::Format::$format";
        $module->require
          or FormValidator::Simple::Exception->throw(
            qq/Validation DATETIME_FORMAT: failed to require $module. "$@"/ );
    }
    my $dt;
    eval {
        $dt = $module->parse_datetime($date);
    };
    my $result = $dt ? TRUE : FALSE;

    if ( $dt && $self->options->{time_zone} ) {
        $dt->set_time_zone( $self->options->{time_zone} );
    }
    return ($result, $dt);
}

sub DATETIME_STRPTIME {
    my ( $self, $params, $args ) = @_;
    my $date   = $params->[0];
    my $format = $args->[0];
    FormValidator::Simple::Exception->throw(
        qq/Validation DATETIME_STRPTIME needs a format argument./)
      unless $format;

    my $dt;
    eval{
        my $strp = DateTime::Format::Strptime->new(
            pattern => $format,
            on_error => 'croak'
        );
        $dt = $strp->parse_datetime($date);
    };

    my $result = $dt ? TRUE : FALSE;

    if ( $dt && $self->options->{time_zone} ) {
        $dt->set_time_zone( $self->options->{time_zone} );
    }
    return ($result, $dt);
}

1;
__END__

