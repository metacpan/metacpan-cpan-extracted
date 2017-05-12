package Jorge::DB;

use DBI;
use Jorge::Config;

use warnings;
use strict;


=head1 NAME

Jorge::DB - Interface to Database. Currently suporting MySQL.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';
my $c = new Jorge::Config;

sub new {
	my $class = shift;
	my $db = $c->get_database;
	my $struct = {
		_dbh => DBI->connect(
						'dbi:mysql:database=' . $db->{db} . ';host=' . $db->{host} . ';port=3306',
						$db->{user},
						$db->{password}
					)
	};
    my $self = bless $struct, $class;
    return $self;
}

sub get_dbh {
    my $self = shift;
    return $self->{_dbh};
}

sub execute {
    my $self     = shift;
    my $db_query = shift;

    my @params = @_;

    my $dbh = $self->get_dbh;
    my $sth = $dbh->prepare($db_query);

    if ( $sth->execute(@params) ) {
        return $sth;
    }
    else {
        print STDERR $dbh->{err};
        return 0;
    }
}

sub prepare {
    my $self  = shift;
    my $query = shift;
    my $dbh   = $self->get_dbh;

    return $dbh->prepare($query);
}

sub get_last_insert_id {
    my $self = shift;
    my $dbh  = $self->get_dbh;
    return $dbh->{'mysql_insertid'};
}

sub execute_prepared {
    my $self = shift;
    my $sth  = shift;

    my @params = @_;
    $sth->execute(@params);
    if ( $self->{_dbh}->errstr ) {
        warn '***ERROR: ' . $self->{_dbh}->errstr . ' : ' . $sth->{Statement};
    }

    return $sth;
}

sub errstr {
    my $self = shift;
    return $self->{_dbh}->errstr;
}


=head1 SYNOPSIS

It is not expected accessing to this package directly. So, move to main
Jorge docs for reference.

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

1;    # End of Jorge::::DB
