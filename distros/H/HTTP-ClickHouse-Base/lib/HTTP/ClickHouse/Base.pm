package HTTP::ClickHouse::Base;

use 5.010000;
use strict;
use warnings FATAL => 'all';

use Scalar::Util qw/looks_like_number/;

=head1 NAME

HTTP::ClickHouse::Base - Base class for HTTP::ClickHouse modules

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

sub new {
#    my $baseclass = shift;
#    my $class = ref($baseclass) || $baseclass;  
    my $class = shift;    
    my $self = { @_ };
    $self = bless $self, $class;
#    $self->_init();
    return $self;
}

sub _init {
    my $self = shift;
    my %_attrs = (
        host        => '127.0.0.1',
        port        => 8123,
        database    => 'default',
        user        => undef,
        password    => undef,
        keep_alive  => 1,
        nb_timeout  => 25,
        debug       => 0
    );
    foreach my $_key ( keys %_attrs ) {
        unless ($self->{$_key}){
            $self->{$_key} = $_attrs{$_key};
        }
    }
}

sub data_prepare {
	my $self = shift;
    my @_rows = map { [@$_] } @_;
    foreach my $row (@_rows) {
        foreach my $val (@$row) {
            unless (defined ($val)) {
                $val = qq{''};
            }
            elsif (ref($val) eq 'ARRAY') {
                $val = q{'}.join ("','", @$val).q{'};
            }
            elsif (defined ($val) && !looks_like_number($val)) {
                $val =~  s/\\/\\\\/g;
                $val =~  s/'/\\'/g;
                $val = qq{'$val'};
            }
        }
    } 
    return scalar @_rows ? join ",", map { "(".join (",", @{ $_ }).")" } @_rows : "\n";	
}

sub body2array {
	my $self = shift;
	my @_response = @_;
	return [ map { [ split (/\t/) ] } @_response ];
}

sub array2hash {
    my $self = shift;
    my @_response = @_;
    my $response;
    my $key = shift @_response;
    for (0..$#_response) {
        my $row = $_;
        for (0..$#{$_response[$row]}) {
            my $col = $_;
            $response->[$row]->{"".$key->[$col].""} = $_response[$row][$_];
        }            
    }
    return $response;	
}

sub DESTROY {
}

1;

=head1 SYNOPSIS

    use IO::Compress::Base ;

=head1 DESCRIPTION

This module is not intended for direct use in application code. Its sole purpose is to be sub-classed by HTTP::ClickHouse modules.

=head1 SEE ALSO

L<HTTP::ClickHouse>

=head1 MODIFICATION HISTORY

=head1 AUTHOR

Maxim Motylkov

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Maxim Motylkov

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.