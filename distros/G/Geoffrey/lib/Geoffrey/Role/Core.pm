package Geoffrey::Role::Core;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Role::Core::VERSION = '0.000103';

sub new {
    my $class = shift;
    my $self  = {@_};

    # make dbh required
    if (!$self->{dbh}) {
        require Geoffrey::Exception::Database;
        Geoffrey::Exception::Database::throw_no_dbh();
    }

    # be sure thet dbh is realy a DBI::db object or a test DBI
    if (!$self->{dbh}->isa('DBI::db') && !$self->{dbh}->isa('Test::Mock::Geoffrey::DBI')) {
        require Geoffrey::Exception::Database;
        Geoffrey::Exception::Database::throw_not_dbh();
    }
    return bless $self, $class;
}

sub converter_name {
    $_[0]->{converter_name} //= 'SQLite';
    return $_[0]->{converter_name};
}

sub io_name {
    $_[0]->{io_name} //= 'None';
    return $_[0]->{io_name};
}
sub dbh                { return $_[0]->{dbh} }
sub schema             { return $_[0]->{schema} }
sub environment_system { return $_[0]->{system} // 'main'; }
sub disconnect         { return $_[0]->{dbh}->disconnect; }

sub converter {
    my ($self) = @_;
    require Geoffrey::Utils;
    $self->{converter} //= Geoffrey::Utils::converter_obj_from_name($self->converter_name);
    return $self->{converter};
}

sub changelog_io {
    my ($self) = @_;
    require Geoffrey::Utils;
    $self->{changelog_io} //= Geoffrey::Utils::changelog_io_from_name($self->io_name);
    $self->{changelog_io}->converter($self->converter) if $self->{changelog_io}->needs_converter;
    $self->{changelog_io}->dbh($self->dbh)             if $self->{changelog_io}->needs_dbh;
    $self->{changelog_io}->schema($self->schema)       if $self->schema;
    return $self->{changelog_io};
}

1;    # End of Geoffrey::Role::Core

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Role::Core - Abstract core class.

=head1 VERSION

Version 0.000103

=head1 DESCRIPTION

=head1 SYNOPSIS

    package My::Class;

    use parent 'Geoffrey::Role::Core';

    1;
    
    my $obj = My::Class->new();
    $obj->converter();

=head1 SUBROUTINES/METHODS

=head2 new

Role constructor

=head2 changelog_table

Returns the dbchangelog table name if none is set then
'geoffrey_changelogs' is used for it

=head2 environment_table

Returns the table name for the possible environments if none is set then
'geoffrey_environments' is used for it

Returns the dbchangelog table column names for insert db logs

=head2 converter

Instantiates Geoffrey::Converter::... object if none is the in the internal key 'converter'
and returns it. converter SQLite is default if no changeset_converter is given in the constructor.

=head2 io_name

Returns the file type if none is set then 'None' is used for it

=head2 dbh

Contains the given dbi session

=head2 disconnect

Disconnects the current dbi session

=head2 changelog_io

Instantiates Geoffrey::Changelog::... object if none is the in the internal key 'changelog_io'
and returns it 

=head2 converter_name

=head2 environment_system

=head2 schema

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

After installing, you can find documentation for this module with the
perldoc command.

    perldoc Geoffrey

You can also look for information at:

    RT, CPAN's request tracker (report bugs here)
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=Geoffrey

    AnnoCPAN, Annotated CPAN documentation
        http://annocpan.org/dist/Geoffrey

    CPAN Ratings
        http://cpanratings.perl.org/d/Geoffrey

    Search CPAN
        http://search.cpan.org/dist/Geoffrey/

=head1 AUTHOR

Mario Zieschang, C<< <mziescha at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Mario Zieschang.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, trade name, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANT ABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
