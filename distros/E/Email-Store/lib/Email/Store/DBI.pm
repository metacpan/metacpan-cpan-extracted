package Email::Store::DBI;
use strict;
use warnings;
use base 'Class::DBI';
require Class::DBI::DATA::Schema;

sub columns {
    my $self  = shift;

    if (@_ && $self->__driver && $self->__driver eq 'Pg') {
        #warn "do that sequence thing white boy";
        if ($_[0] eq 'Primary' or $_[0] eq 'All') {
            # Class::DBI::Pg does this properly, as part of its
            # set_up_table call, but that requires the table to exist
            # at compile time.  For the general case we can guess
            $self->sequence( $self->table . "_" . $_[1] . "_seq" );
        }
    }
    $self->SUPER::columns( @_ );
}

sub import {
    my ($self, @params) = @_;
    if (@params) {
        $self->set_db(Main => @params);
        $self->translate(mysql => $self->__driver);
        if ($self->__driver =~ /SQLite/) {
            $self->db_Main->{sqlite_handle_binary_nulls} = 1;
        } elsif ($self->__driver =~ /PostgreSQL|Pg|Oracle/) {
            $self->db_Main->{AutoCommit} = 1;
        }
    }
}

my %map = ( # Why SQL::Translator doesn't provide this I don't know
    mysql   => "MySQL",
    Pg      => "PostgreSQL",
    SQLite2 => "SQLite",
);

sub translate {
    my ($self, $from, $to) = @_;
    $from = exists $map{$from} ? $map{$from} : $from;
    $to   = exists $map{$to}   ? $map{$to}   : $to;
    Class::DBI::DATA::Schema->import(
        ($from eq $to) ? () :
            (translate => [$from => $to ],
             cache => "emailstore_sqlcache"
            )
    );
}

1;

=head1 NAME

Email::Store::DBI - Database backend to Email::Store

=head1 SYNOPSIS

 use Email::Store 'dbi:...';

=head1 DESCRIPTION

This class is a subclass of L<Class::DBI> and contains means for
C<Email::Store>-based programs to register what DSN they wish to use. It
also provides for building database tables from schemas embedded in the
DATA section of plug-in modules, using L<Class::DBI::DATA::Schema>.

=cut
