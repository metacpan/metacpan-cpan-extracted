package FormValidator::LazyWay::Rule::DateTime;

use strict;
use warnings;
use utf8;

use DateTime::Format::Strptime;

sub datetime {
    my ( $datetime, $args ) = @_;
    unless ( $args->{pattern} ) {
        $args->{pattern} = '%Y-%m-%d %H:%M:%S';
    }

    my $strp = DateTime::Format::Strptime->new( %{$args}  );
    my $dt = eval { $strp->parse_datetime($datetime) };
    return $dt ? 1 : 0;
}

sub date {
    my ( $date, $args ) = @_;
    unless ( $args->{pattern} ) {
        $args->{pattern} = '%Y-%m-%d';
    }
    
    my $strp = DateTime::Format::Strptime->new( %{$args}  );
    my $dt = eval { $strp->parse_datetime($date) };
    return $dt ? 1 : 0;
}

sub time {
    my ( $time, $args ) = @_;
    unless ( $args->{pattern} ) {
        $args->{pattern} = '%H:%M:%S';
    }

    my $strp = DateTime::Format::Strptime->new( %{$args}  );
    my $dt = eval { $strp->parse_datetime($time) };
    return $dt ? 1 : 0;
}

1;

__END__

=head1 NAME

FormValidator::LazyWay::Rule::DateTime - rule for DateTime

=head1 METHOD

=head2 boolean

=head1 AUTHOR

Daisuke Komatsu <vkg.taro@gmail.com>

=cut
