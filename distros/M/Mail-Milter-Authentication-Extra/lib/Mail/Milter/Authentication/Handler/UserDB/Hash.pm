package Mail::Milter::Authentication::Handler::UserDB::Hash;
use strict;
use warnings;
use base 'Mail::Milter::Authentication::Handler::UserDB';
use version; our $VERSION = version->declare('v1.1.3');

use DB_File;

sub new {
    my ( $class, $file ) = @_;

    my $self = {
        'file'         => $file . '.db',
        'checked_time' => 0,
        'table'        => undef,
        'table_stamp'  => 0,
    };

    bless $self, $class;
    return $self;
}

sub preload {
    my ( $self ) = @_;
    $self->{'checked_time'} = time;
    my $null = $self->get_table();
    return;
}

sub check_reload {
    my ( $self ) = @_;
    my $now = time;
    my $check_time = 60*10; # Check no more often than every 10 minutes
    if ( $now > $self->{'checked_time'} + $check_time ) {
        $self->{'checked_time'} = $now;
        return $self->check_table();
    }
    return 0;
}

sub get_user_from_address {
    my ( $self, $address ) = @_;
    $address =~ s/\+.*@/@/;
    my $table = $self->get_table();
    if ( exists $table->{ lc $address } ) {
        return $table->{ lc $address };
    }
    return;
}

sub get_table {
    my ( $self ) = @_;
    return $self->{'table'} if $self->{'table'};
    my $file = $self->{'file'};
    return if not $file;
    if ( ! -e $file ) {
        warn "UserDB File $file does not exist";
        return;
    }
    $self->{'table_stamp'} = ( stat( $file ) )[9];
    my %h;
    tie %h, 'DB_File', $file, O_RDONLY, undef, $DB_HASH;
    my $table = {};
    foreach my $k ( keys %h ) {
        my $user= $h{$k};
        if ( !( $user =~ /\@/ )) {
            $user =~ s/\x00//g;
            $k    =~ s/\x00//g;
            $table->{ lc $k } = $user;
        }
    }
    $self->{'table'} = $table;
    return $table;
}

sub check_table {
    my ( $self ) = @_;
    my $file = $self->{'file'};
    return if not $file;
    my $new_table_stamp = ( stat( $file ) )[9];
    if ( $new_table_stamp != $self->{'table_stamp'} ) {
        delete $self->{'table'};
        my $null = $self->get_table();
        return 1;
    }
    return 0;
}


1;
