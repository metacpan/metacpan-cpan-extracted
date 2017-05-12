package HTML::Index::Store::BerkeleyDB;

#------------------------------------------------------------------------------
#
# Modules
#
#------------------------------------------------------------------------------

use BerkeleyDB;
use Fcntl;
use File::Path;
use Carp;

require HTML::Index::Store;
use vars qw( @ISA );
@ISA = qw( HTML::Index::Store );

#------------------------------------------------------------------------------
#
# Initialization public method
#
#------------------------------------------------------------------------------

sub init
{
    my $self = shift;

    croak "No DB\n" unless defined $self->{DB};
    unless ( -d $self->{DB} )
    {
        mkpath( $self->{DB} ) or croak "can't mkpath $self->{DB}: $!\n";
    }
    $self->{MODE} ||= 'rw';
    $self->SUPER::init();
    return $self;
}

sub create_table
{
    my $self = shift;
    my $table = shift;
    my $type = shift;

    $self->{TYPE}{$table} = $type;
    my $flags = $self->{MODE} eq 'r' ? DB_RDONLY : DB_CREATE;
    my $db_path = "$self->{DB}/$table.db";
    if ( -e $db_path and $self->{REFRESH} )
    {
        unlink( $db_path ) or croak "Can't remove $db_path\n";
    }
    $self->{PATH}{$table} = $db_path;
    if ( $type eq 'ARRAY' )
    {
        $self->{$table} = new BerkeleyDB::Recno(
            '-Filename'        => $db_path, 
            '-Flags'           => $flags,
        ) or croak "Cannot tie to $db_path ($flags): $!\n";
    }
    elsif ( $type eq 'HASH' )
    {
        $self->{$table} = new BerkeleyDB::Hash(
            '-Filename'        => $db_path, 
            '-Flags'           => $flags,
            '-Pagesize'        => 512,
        ) or croak "Cannot tie to $db_path ($flags): $!\n";
    }
    warn "$table of type $type - $self->{$table}\n" if $self->{VERBOSE};
}

#------------------------------------------------------------------------------
#
# Destructor
#
#------------------------------------------------------------------------------

sub DESTROY
{
    my $self = shift;

    for my $table ( keys %{$self->{PATH}} )
    {
        undef( $self->{$table} );
    }
}

#------------------------------------------------------------------------------
#
# Public methods
#
#------------------------------------------------------------------------------

sub put
{
    my $self = shift;
    my $table = shift;
    croak "put called before init\n" unless defined $self->{TYPE};
    my $type = $self->{TYPE}{$table};
    unless ( $type )
    {
        croak 
            "Can't put $table (not one of ", 
            join( ',', keys %{$self->{TYPE}}) , 
            ")\n"
        ;
    }
    my $key = shift;
    my $val = shift;
    croak "Putting undef into $table $key\n" unless defined $val;
    my $status = $self->{$table}->db_put( $key, $val );
    croak "Can't db_put $val into the $key field of $table: $status\n" if $status;
}

sub get
{
    my $self = shift;
    my $table = shift;
    croak "get called before init\n" unless defined $self->{TYPE};
    my $type = $self->{TYPE}{$table};
    unless ( $type )
    {
        croak 
            "Can't get $table (not one of ", 
            join( ',', keys %{$self->{TYPE}}) , 
            ")\n"
        ;
    }
    my $key = shift;
    my $val;

    my $status = $self->{$table}->db_get( $key, $val );
    croak "Can't get $key key of $table: $status\n" 
        unless 
            $status == 0 ||
            $status == DB_NOTFOUND
    ;
    return $val;
}

sub get_keys
{
    my $self = shift;
    my $table = shift;

    croak "each called before init\n" unless defined $self->{TYPE};
    my $type = $self->{TYPE};
    my $cursor = $self->{$table}->db_cursor();
    my ( $key, $val ) = ( $type eq 'ARRAY' ? 1 : '', 0 );
    my @keys;
    while ( $cursor->c_get( $key, $val, DB_NEXT ) == 0 )
    {
        push( @keys, $key );
    }
    return @keys;
}

sub nkeys
{
    my $self = shift;
    my $table = shift;

    croak "nkeys called before init\n" unless defined $self->{TYPE};
    my $db_stat = $self->{$table}->db_stat();
    return $db_stat->{bt_nkeys} if defined $db_stat->{bt_nkeys};
    return $db_stat->{hash_nkeys} if defined $db_stat->{hash_nkeys};
    return $db_stat->{qs_nkeys} if defined $db_stat->{hash_nkeys};
    return undef;
}

#------------------------------------------------------------------------------
#
# True
#
#------------------------------------------------------------------------------

1;

__END__

=head1 NAME

HTML::Index::Store::BerkeleyDB - subclass of
L<HTML::Index::Store|HTML::Index::Store> using BerkeleyDB.

=head1 SYNOPSIS

    my $store = HTML::Index::Store::BerkeleyDB->new( 
        COMPRESS => 1,
        DB => $path_to_dbfile_directory,
        STOP_WORD_FILE => $swf,
    );
    $store->init();

=head1 DESCRIPTION

This module is a subclass of the L<HTML::Index::Store|HTML::Index::Store>
module, that uses Berkeley DB files to store the inverted index.

=head1 SEE ALSO

=over 4

=item L<HTML::Index|HTML::Index>

=item L<HTML::Index::Store|HTML::Index::Store>

=back

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
