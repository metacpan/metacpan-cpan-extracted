package Jorge::DBEntity;

use Date::Manip;
use Jorge::DB;

use warnings;
use strict;

=head1 NAME

Jorge::DBEntity - Base class for single Jorge Objects.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

my $db;

sub new {
    my $class  = shift;
    my %params = @_;
    my $self   = bless {}, $class;
    my @fields = @{ $self->_fields->[0] };
    foreach my $key ( keys %params ) {
        $self->$key( $params{$key} ) if grep { $_ eq $key } @fields;
    }
    return $self;
}

sub _db {
    unless ($db) {
        $db = new Jorge::DB;
    }
    return $db;
}

sub _load {
    my $self = shift;
    my $row  = shift;

    my @fields = @{ $self->_fields->[0] };
    my %fields = %{ $self->_fields->[1] };

    for ( keys %$row ) {
        unless ( $fields{$_}->{class} ) {
            $self->{$_} = $row->{$_};
            next;
        }

        my $obj = $fields{$_}->{class};
        $obj->get_from_db( $row->{$_} );
        $self->{$_} = $obj;
    }
}

sub _pk {
    my $self = shift;
    my @pk;

    my @fields = @{ $self->_fields->[0] };
    my %fields = %{ $self->_fields->[1] };

    for (@fields) {
        next unless $fields{$_}->{pk};
        push @pk, $_;
    }

    return \@pk;
}

sub _params {
    my $self      = shift;
    my $not_nulls = shift;

    my @params;

    my @fields = @{ $self->_fields->[0] };
    my %fields = %{ $self->_fields->[1] };

    for (@fields) {
        next if $fields{$_}->{pk};
        next if $fields{$_}->{timestamp};
        next if $not_nulls && !$self->{$_};

        if ( $fields{$_}->{datetime} ) {
            push @params, UnixDate( $self->{$_}, '%Y-%m-%d %H:%M:%S' );
            next;
        }

        unless ( $fields{$_}->{class} ) {
            push @params, $self->{$_};
            next;
        }

        push @params, $self->{$_}->{ $self->{$_}->_pk->[0] };
    }

    return @params;
}

sub get_from_db {
    my $self = shift;
    my $id   = shift;

    return 0 unless $id;

    my @fields     = @{ $self->_fields->[0] };
    my %fields     = %{ $self->_fields->[1] };
    my $table_name = $self->_fields->[2];

    my @pk = grep { $fields{$_}->{pk} } keys %fields;

    my $query = 'SELECT ';
    $query .= join( ',', @fields );
    $query .= ' FROM ' . $table_name . ' WHERE ' . $pk[0] . ' = ' . $id;

    my $sth;
    unless ( $sth = $self->_db->execute($query) ) { return 0 }
    $self->_load( $sth->fetchrow_hashref );

    return $self->{ $pk[0] };
}

sub insert {
    my $self = shift;

    my @fields     = @{ $self->_fields->[0] };
    my %fields     = %{ $self->_fields->[1] };
    my $table_name = $self->_fields->[2];

    $self->before_insert();
    $self->before_save();

    my $query = 'INSERT INTO ' . $table_name;
    $query .= ' ('
      . join( ',',
        grep { !$fields{$_}->{pk} && !$fields{$_}->{timestamp} && $self->{$_} }
          @fields )
      . ')';
    $query .= ' VALUES (' . join( ',', map { '?' } $self->_params(1) ) . ')';
    if ( $self->_db->execute( $query, $self->_params(1) ) ) {
        $self->get_from_db( $self->_db->get_last_insert_id );
        return $self->{ $self->_pk->[0] };
    }
    else {
        return 0;
    }
}

sub update {
    my $self = shift;

    my @fields     = @{ $self->_fields->[0] };
    my %fields     = %{ $self->_fields->[1] };
    my $table_name = $self->_fields->[2];

    my @pk = grep { $fields{$_}->{pk} } keys %fields;

    $self->before_update();
    $self->before_save();

    my $query = 'UPDATE ' . $table_name;
    $query .= ' SET ';
    $query .= join( ',',
        map { $_ . ' = ?' }
          grep { !$fields{$_}->{pk} && !$fields{$_}->{timestamp} } @fields );
    $query .= ' WHERE ' . $pk[0] . ' = ?';
    if ( $self->_db->execute( $query, $self->_params, $self->{ $pk[0] } ) ) {
        return $self->{ $pk[0] };
    }
    else {
        return 0;
    }
}

sub delete {
    my $self = shift;

    my @fields     = @{ $self->_fields->[0] };
    my %fields     = %{ $self->_fields->[1] };
    my $table_name = $self->_fields->[2];

    my @pk = grep { $fields{$_}->{pk} } keys %fields;

    $self->before_delete();

    my $query = 'DELETE FROM ' . $table_name;
    $query .= ' WHERE ' . $pk[0] . ' = ?';
    if ( $self->_db->execute( $query, $self->{ $pk[0] } ) ) {
        return 1;
    }
    else {
        return 0;
    }
}

sub get_by {
    my ( $self, @params ) = @_;

    return 0 unless @params;

    my $table_name = $self->_fields->[2];
    my %fields     = %{ $self->_fields->[1] };

    my @cols;
    my @vals;

    foreach my $col (@params) {
        push( @cols, "$col = ?" );
        my $v;

        #Porta
        #Allows to use a object as a param for get_by method
        if ( $fields{$col}->{class} ) {
            my $p = $self->{$col}->_pk;
            my $o = $self->{$col};
            $v = $o->{ $$p[0] };
        }
        else {
            $v = $self->{$col};
        }
        push( @vals, $v );
    }

    my $columns = join( ' AND ', @cols );
    my $query = "SELECT * FROM $table_name WHERE ($columns)";

    my $return = $self->_db->prepare($query);
    my $sth = $self->_db->execute_prepared( $return, @vals );

    $self->_load( $sth->fetchrow_hashref );

    return $self;
}

sub AUTOLOAD {
    our $AUTOLOAD;
    return if $AUTOLOAD =~ /::DESTROY$/;

    my ( $self, $value ) = @_;
    die "not an object" unless ref($self);

    my $field = [ split( /::/, $AUTOLOAD ) ]->[-1];

    my @fields = @{ $self->_fields->[0] };
    my %fields = %{ $self->_fields->[1] };

    die "method \"$field\" doesn't exist" unless grep { $_ eq $field } @fields;

    if ( $fields{$field}->{read_only} ) { return $self->{$field} }

    return $self->{$field} unless defined $value;

    for ($value) {

        if ( $fields{$field}->{values} ) {
            last unless grep { $_ eq $value } @{ $fields{$field}->{values} };
        }

        if ( $fields{$field}->{class} ) {
            last unless ref($value) eq ref( $fields{$field}->{class} );
        }

        $self->{$field} = $value;
    }

    return $self->{$field};
}

sub before_insert {
    my $self = shift;
    return 1;
}

sub before_update {
    my $self = shift;
    return 1;
}

sub before_save {
    my $self = shift;
    return 1;
}

sub before_delete {
    my $self = shift;
    return 1;
}

=head1 SYNOPSIS

Please, refer to Jorge docs
    perldoc Jorge


=head1 AUTHORS

Mondongo, C<< <mondongo at gmail.com> >> Did the important job and started 
this beauty.

Julian Porta, C<< <julian.porta at gmail.com> >> took the code and tried 
to make it harder, better, faster, stronger.

=head1 BUGS

Please report any bugs or feature requests to C<bug-jorge at rt.cpan.org>,
or through the web interface at 
 L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Jorge>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Jorge


You can also look for information at:

=over 4

=item * Github Project Page

L<http://github.com/Porta/Jorge/tree/master>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Jorge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Jorge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Jorge>

=item * Search CPAN

L<http://search.cpan.org/dist/Jorge/>

=back


=head1 ACKNOWLEDGEMENTS

Mondongo C<< <mondongo at gmail.com> >> For starting this.

=head1 COPYRIGHT & LICENSE

Copyright 2009 Julian Porta, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of Jorge::::DBEntity

