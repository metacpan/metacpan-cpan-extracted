package MetaStore::Base;

=head1 NAME

MetaStore::Base - base class.

=head1 SYNOPSIS

    use MetaStore::Base;
    use base qw/MetaStore::Base/

=head1 DESCRIPTION

Base class.

=head1 METHODS

=cut


use Data::Dumper;
use Time::Local;
use Template;
use Template::Plugin::Date;
use WebDAO::Base;
use strict;
use warnings;
use base qw/WebDAO::Base/;
our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = {};
    my $stat;
    bless( $self, $class );
    return ( $stat = $self->_init(@_) ) ? $self : $stat;
}


sub _init {
    my $self = shift;
    return $self->init(@_);
}

sub init{ 1 };

sub time2mysql {
    my ( $self, $time ) = @_;
    $time = time() unless defined($time);
    my ( $sec, $min, $hour, $day, $month, $year ) = ( localtime($time) )[ 0, 1, 2, 3, 4, 5 ];
    $year  += 1900;
    $month += 1;
    $time = sprintf( '%.4d-%.2d-%.2d %.2d:%.2d:%.2d', $year, $month, $day, $hour, $min, $sec );
    return $time;
}

sub mysql2time {
    my ( $self, $time ) = @_;
    return time() unless $time;
    my ( $year, $month, $day, $hour, $min, $sec ) = $time =~ m/(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)/;
    return '0' unless ( $year + $month + $day + $hour + $min + $sec );
    $year  -= 1900;
    $month -= 1;
    $time = timelocal( $sec, $min, $hour, $day, $month, $year );
    return $time;
}

1;
__END__

=head1 SEE ALSO

MetaStore, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

