package HTTP::Session::Store::DBI;

use Moose;
use Moose::Util::TypeConstraints;
use DBI;
use MIME::Base64;
use Storable qw/nfreeze thaw/;

our $VERSION   = '0.02';
our $AUTHORITY = 'cpan:FAYLAND';

subtype 'DBH'
     => as 'Object';

coerce 'DBH'
    => from 'ArrayRef'
    => via { DBI->connect(@$_) or die $DBI::errstr; };

has 'dbh' => ( is => 'ro', isa => 'DBH', coerce => 1, required => 1 );

has expires => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
    default  => 3600,
);

has 'sid_table' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default  => 'session',
);
has 'sid_col' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default  => 'sid',
);
has 'data_col' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default  => 'data',
);
has 'expires_col' => (
    is  => 'ro',
    isa => 'Str',
    required => 1,
    default  => 'expires',
);
has 'clean_thres' => (
    is  => 'ro',
    isa => 'Num',
    required => 1,
    default  => '0.001'
);

sub select {
    my ( $self, $session_id ) = @_;
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql = qq~SELECT $data_col, $expires_col FROM $sid_table WHERE $sid_col = ?~;
    my $sth = $dbh->prepare( $sql ); 
    $sth->execute( $session_id );
    my ($data, $expires) = $sth->fetchrow_array;
    
    return unless ($data);
    return unless ( $expires > time() );
    
    return thaw( decode_base64($data) );
}

sub insert {
    my ($self, $session_id, $data) = @_;
    
    $data = encode_base64( nfreeze($data) );
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~INSERT INTO $sid_table ($sid_col, $data_col, $expires_col) VALUES (?, ?, ?)~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $session_id, $data, time() + $self->expires );
}

sub update {
    my ($self, $session_id, $data) = @_;
    
    $data = encode_base64( nfreeze($data) );
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~UPDATE $sid_table SET $data_col = ?, $expires_col = ? WHERE $sid_col = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $data, time() + $self->expires, $session_id );
}

sub delete {
    my ($self, $session_id) = @_;
    
    my $dbh = $self->dbh;
    my $sid_table = $self->sid_table;
    my $sid_col   = $self->sid_col;
    my $data_col  = $self->data_col;
    my $expires_col  = $self->expires_col;
    my $sql =qq~DELETE FROM $sid_table WHERE $sid_col = ?~;
    my $sth = $dbh->prepare($sql);
    $sth->execute( $session_id );
    
    if ( rand() < $self->clean_thres ) {
        my $time_now = time();
        $dbh->do(qq~DELETE FROM $sid_table WHERE expires < $time_now~);
    }
}


no Moose;
no Moose::Util::TypeConstraints;

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

HTTP::Session::Store::DBI - store session data in DBI for L<HTTP::Session>

=head1 SYNOPSIS

    use HTTP::Session;
    
    my $session = HTTP::Session->new(
        store   => HTTP::Session::Store::DBI->new( {
            dbh => ["dbi:SQLite:dbname=xxx", '', '', {RaiseError => 1}]
        } ),
        state => ...,
        request => ...,
    );

=head1 DESCRIPTION

store session data in DBI. read L<HTTP::Session> for usage.

=head1 CONFIGURATION

=over 4

=item dbh

ArrayRef which passes to DBI->connect(@$_)

or Instance of DBI->connect

=item expires

session expire time(in seconds)

=item sid_table

the table name where session stores. default is 'session'

=item sid_col

the session_id column name. default is 'sid'

=item data_col

the data column name. default is 'data'

=item expires_col

the expires column name. default is 'expires'

=item clean_thres

default is '0.001'. because L<DBI> do NOT delete expired data itself, we have code in sub delete

    if ( rand() < $self->clean_thres ) {
        my $time_now = time();
        $dbh->do(qq~DELETE FROM $sid_table WHERE expires < $time_now~);
    } 

set it to 0 if we do NOT want it.

=back

=head1 TABLE SQL

SQLite:

    CREATE TABLE session (
        sid          VARCHAR(32) PRIMARY KEY,
        data         TEXT,
        expires      INTEGER UNSIGNED NOT NULL,
        UNIQUE(sid)
    );

=head1 METHODS

=over 4

=item select

=item update

=item delete

=item insert

for internal use only

=back

=head1 SEE ALSO

L<HTTP::Session>, L<DBI>

=head1 AUTHOR

Fayland Lam, C<< <fayland at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Fayland Lam, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
