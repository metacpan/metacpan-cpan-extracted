package KiokuDB::Cmd::Command::Nav;
use Moose;

use KiokuDB::Navigator;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

extends 'KiokuDB::Cmd::Base';
   with 'KiokuDB::Cmd::WithDSN::Read';

# the classname of a typemap
has typemap => (
    traits        => [ 'Getopt' ],
    is            => 'ro',
    isa           => 'Str',
    predicate     => 'has_typemap',
    cmd_aliases   => 'T',
    documentation => 'backend typemap',
);

sub _get_extra_arguments {
    my $self = shift;
    if ( $self->has_typemap ) {
       my $class = $self->typemap;
       Class::MOP::load_class( $class );
       return ( typemap => $class->new );
    }
    else {
       return ();
    }
}


augment 'run' => sub {
    my $self = shift;

    KiokuDB::Navigator->new(
        db => KiokuDB->new(
            backend => $self->backend,
            $self->_get_extra_arguments
        ),
    )->run;
};

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

KiokuDB::Cmd::Command::Nav - KiokuDB::Cmd extension for KiokuDB::Navigator

=head1 SYNOPSIS

  % kioku nav --dsn bdb:dir=root/db [ --typemap MyApp::TypeMap ]

=head1 DESCRIPTION

This is a KiokuDB::Cmd class to provide access to a KiokuDB::Navigator.

=head1 OPTIONS

=over 4

=item I<--dsn>

This is the KiokuDB dsn string and it is required.

=item I<--typemap>

This is the classname of the KiokuDB typemap and it is optional.

=back

=head1 METHODS

=over 4

=item B<run>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
