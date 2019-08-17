package Geoffrey::Changeset;

use utf8;
use 5.016;
use strict;
use warnings;
use Geoffrey::Utils;

$Geoffrey::Changeset::VERSION = '0.000201';

use parent 'Geoffrey::Role::Core';

sub action {
    my ( $self, $s_action ) = @_;
    return Geoffrey::Utils::action_obj_from_name(
        $s_action,
        dbh       => $self->dbh,
        converter => $self->converter,
        template  => $self->template,
    );
}

sub postfix {
    return $_[0]->{postfix} // q~~ if !defined $_[1];
    $_[0]->{postfix} = $_[1];
    return $_[0]->{postfix};
}

sub prefix {
    return $_[0]->{prefix} // q~~ if !defined $_[1];
    $_[0]->{prefix} = $_[1];
    return $_[0]->{prefix};
}

sub template {
    return $_[0]->{template} // q~~ if !defined $_[1];
    $_[0]->{template} = $_[1];
    return $_[0]->{template};
}

sub handle_entry {
    my ( $self, $hr_entry ) = @_;
    return unless $hr_entry;
    unless ( $hr_entry->{action} ) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_no_params( 'handle_entry', 'action', $hr_entry );
    }
    my ( $s_sub, $s_action ) = Geoffrey::Utils::parse_package_sub( delete $hr_entry->{action} );
    my $o_action = $self->action($s_action);
    if ( !$s_sub || !$o_action->can($s_sub) ) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_action_sub($s_action);
    }
    $o_action->dryrun(1) if delete $hr_entry->{dryrun};
    my $result = $o_action->$s_sub($hr_entry);
    $o_action->dryrun(0);
    return $result;

}

sub handle_entries {
    my ( $self, $ar_entries ) = @_;
    return unless $ar_entries;
    $self->handle_entry($_) for ( @{$ar_entries} );
    return scalar @{$ar_entries};
}

1;    # End of Geoffrey::Changeset

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Changeset - Handles action types.

=head1 VERSION

Version 0.000201

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 new

Run to check converter version with installed db converter.

Creates changelog table if it's not existing.

=head2 template

=head2 postfix

=head2 prefix

Read main changelog file and sub changelog files

=head2 handle_entries

Handles different changeset commands

=head2 constraints

=head2 entries

=head2 functions

=head2 indexes

=head2 sequences

=head2 sql

=head2 tables

=head2 trigger

=head2 views

=head2 foreignkey

=head2 action

=head2 handle_entry

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

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
