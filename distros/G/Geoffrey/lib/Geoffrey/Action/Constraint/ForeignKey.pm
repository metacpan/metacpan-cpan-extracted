package Geoffrey::Action::Constraint::ForeignKey;

use utf8;
use 5.016;
use strict;
use warnings;

$Geoffrey::Action::Constraint::ForeignKey::VERSION = '0.000206';

use parent 'Geoffrey::Role::Action';

sub add {
    my ($self, $hr_params) = @_;
    require Ref::Util;
    if (!Ref::Util::is_hashref($hr_params)) {
        require Geoffrey::Exception::General;
        Geoffrey::Exception::General::throw_wrong_ref(__PACKAGE__ . '::add', 'hash');
    }
    if (!$self->converter->foreign_key) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_foreignkey('add', $self->converter);
    }
    if (!exists $hr_params->{table}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_table_name();
    }
    if (   !exists $hr_params->{column}
        || !exists $hr_params->{reftable}
        || !exists $hr_params->{refcolumn})
    {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_reftable_missing($hr_params->{table})
            if (!exists $hr_params->{reftable});
        Geoffrey::Exception::RequiredValue::throw_refcolumn_missing($hr_params->{table})
            if (!exists $hr_params->{refcolumn});
        Geoffrey::Exception::RequiredValue::throw_table_column($hr_params->{table})
            if (!exists $hr_params->{column});
    }
    $hr_params->{reftable} =~ s/"//g;
    $hr_params->{table} =~ s/"//g;
    require Geoffrey::Utils;
    my $s_sql = Geoffrey::Utils::replace_spare(
        $self->converter->foreign_key->add,
        [
            $hr_params->{column},
            (exists $hr_params->{schema} ? $hr_params->{schema} . q/./ : q//)
                . $hr_params->{reftable},
            $hr_params->{refcolumn},
            qq~fkey_$hr_params->{table}~ . q~_~ . time
        ]);
    return $s_sql if $self->for_table;
    return $self->do($s_sql);

}

sub alter {
    my ($self, $hr_params) = @_;
    if (!exists $hr_params->{name}) {
        require Geoffrey::Exception::RequiredValue;
        Geoffrey::Exception::RequiredValue::throw_index_name(__PACKAGE__ . '::alter');
    }
    if (!$self->converter->foreign_key) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_foreignkey('alter', $self->converter);
    }
    return [$self->drop($hr_params), $self->add($hr_params),];
}

sub drop {
    my ($self, $hr_params) = @_;
    if (!$self->converter->foreign_key) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_foreignkey('drop',
            $self->converter->foreign_key);
    }
    require Geoffrey::Utils;
    my $s_sql = Geoffrey::Utils::replace_spare($self->converter->foreign_key->drop,
        [$hr_params->{table}, $hr_params->{name}]);
    return $s_sql if $self->for_table;
    return $self->do($s_sql);
}

sub list_from_schema {
    my ($self, $schema) = @_;
    my $converter = $self->converter;
    if (!$self->converter->foreign_key) {
        require Geoffrey::Exception::NotSupportedException;
        Geoffrey::Exception::NotSupportedException::throw_foreignkey('list', $self->converter);
    }
    return $converter->foreignkey_information(
        $self->do_arrayref($self->converter->foreign_key->list($schema)));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Constraint::ForeignKey - Action handler for foreign keys

=head1 VERSION

Version 0.000206

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

=head2 alter

=head2 drop

=head2 list_from_schema 
    
Not needed!

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
