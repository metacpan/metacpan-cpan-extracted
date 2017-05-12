package Eidolon::Driver::DB::PostgreSQL;
# ==============================================================================
#
#   Eidolon
#   Copyright (c) 2009, Atma 7
#   ---
#   Eidolon/Driver/DB/PostgreSQL - PostgreSQL DBMS driver
#
# ==============================================================================

use base qw/Eidolon::Driver::DB/;
use warnings;
use strict;

our $VERSION = "0.01"; # 2008-08-23 14:21:27

# ------------------------------------------------------------------------------
# \% new()
# constructor
# ------------------------------------------------------------------------------
sub new
{
    my ($class, $db, $user, $password, $host, $port, $cfg, $self);

    ($class, $db, $user, $password, $host, $port, $cfg) = @_;

    $self = $class->SUPER::new
    (
        "Pg", $db, $user, $password, $host || "localhost", $port || "5432", $cfg
    );

    return $self;
}

# ------------------------------------------------------------------------------
# \@ call($function, @params)
# function/procedure call
# ------------------------------------------------------------------------------
sub call
{
    my ($self, $function, @params, $query);

    ($self, $function, @params) = @_;

    $query = sprintf
    (
        "SELECT * FROM $function(%s)",
        join(",", split(//, "?" x scalar @params))
    );

    return $self->execute($query, @params);
}

1;

__END__

=head1 NAME

Eidolon::Driver::DB::PostgreSQL - PostgreSQL database driver.

=head1 SYNOPSIS

Somewhere in application controller:

    my ($r, $db);

    $r  = Eidolon::Core::Registry->get_instance;
    $db = $r->loader->get_object("Eidolon::Driver::DB::PostgreSQL");

    $db->call("get_news", 12);
    $news = $db->fetch_all;

    foreach (@$news)
    {
        # ...
    }

    $db->free;

=head1 DESCRIPTION

The I<Eidolon::Driver::DB::PostgreSQL> is the PostgreSQL database driver for 
I<Eidolon>. PostgreSQL versions 8.0+ are supported. 

To use this driver you must have L<DBI> and L<DBD::Pg> packages 
installed. 

=head1 METHODS

=head2 new($dbd, $db, $user, $password, $host, $port, $cfg)

Class constructor. Sets initial class data. Only a wrapper over generic class
constructor - see 
L<Eidolon::Driver::DB/new($dbd, $db, $user, $password, $host, $port, $cfg)>
for more information.

=head2 execute($query, @params)

Inherited from L<Eidolon::Driver::DB/execute($query, @params)>.

=head2 execute_prepared(@params)

Inherited from L<Eidolon::Driver::DB/execute_prepared(@params)>.

=head2 fetch()

Inherited from L<Eidolon::Driver::DB/fetch()>.

=head2 fetch_all()

Inherited from L<Eidolon::Driver::DB/fetch_all()>.

=head2 free()

Inherited from L<Eidolon::Driver::DB/free()>.

=head2 call($function, @params)

Implementation of abstract method from
L<Eidolon::Driver::DB/call($function, @params)>.

=head1 SEE ALSO

L<Eidolon>, L<Eidolon::Driver::DB>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Anton Belousov, E<lt>abel@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (c) 2009, Atma 7, L<http://www.atma7.com>

=cut
