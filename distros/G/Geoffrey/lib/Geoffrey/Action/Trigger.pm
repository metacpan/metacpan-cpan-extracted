package Geoffrey::Action::Trigger;

use utf8;
use 5.016;
use strict;
use warnings;
use Geoffrey::Utils;
use Geoffrey::Exception::RequiredValue;
use Geoffrey::Exception::NotSupportedException;

$Geoffrey::Action::Trigger::VERSION = '0.000205';

use parent 'Geoffrey::Role::Action';

sub add {
    my ($self, $params, $options) = @_;
    my $trigger = $self->converter->trigger;

    Geoffrey::Exception::NotSupportedException::throw_action() if !$trigger || !$trigger->add;
    Geoffrey::Exception::RequiredValue::throw_trigger_name('for add trigger') if !$params->{name};
    Geoffrey::Exception::RequiredValue::throw_table_name('for add trigger')   if !$params->{event_object_table};
    Geoffrey::Exception::RequiredValue::throw_common('event_manipulation')    if !$params->{event_manipulation};
    Geoffrey::Exception::RequiredValue::throw_common('action_timing')         if !$params->{action_timing};
    Geoffrey::Exception::RequiredValue::throw_common('action_orientation')    if !$params->{action_orientation};
    Geoffrey::Exception::RequiredValue::throw_common('action_statement')      if !$params->{action_statement};

    my $result = $self->_find_same_trigger($params->{event_object_table}, $params->{name}, $params->{schema});

    if (@{$result} > 0) {
        $self->drop($params->{name}, $params->{event_object_table});
        $params->{event_manipulation} .= ' OR ' . $result->[0]->{event_manipulation};
    }

    my $sql = Geoffrey::Utils::replace_spare(
        $trigger->add($options),
        [
            $params->{name},               $params->{action_timing},      $params->{event_manipulation},
            $params->{event_object_table}, $params->{action_orientation}, $params->{action_statement},
        ]);
    return $self->do($sql);
}

sub alter {
    my ($self, $params, $options) = @_;
    my $trigger = $self->converter->trigger;
    Geoffrey::Exception::NotSupportedException::throw_action() if !$trigger || !$trigger->alter;
    Geoffrey::Exception::RequiredValue::throw_trigger_name('for drop trigger') if !$params->{name};
    Geoffrey::Exception::RequiredValue::throw_table_name('for drop trigger')   if !$params->{event_object_table};
    Geoffrey::Exception::RequiredValue::throw_common('event_manipulation')     if !$params->{event_manipulation};
    Geoffrey::Exception::RequiredValue::throw_common('action_timing')          if !$params->{action_timing};
    Geoffrey::Exception::RequiredValue::throw_common('action_orientation')     if !$params->{action_orientation};
    Geoffrey::Exception::RequiredValue::throw_common('action_statement')       if !$params->{action_statement};

    return [$self->drop($params, $options), $self->add($params, $options),];
}

sub drop {
    my ($self, $name, $table) = @_;
    my $trigger = $self->converter->trigger;
    Geoffrey::Exception::NotSupportedException::throw_action() if !$trigger || !$trigger->drop;
    Geoffrey::Exception::RequiredValue::throw_trigger_name('for drop trigger') if !$name;
    Geoffrey::Exception::RequiredValue::throw_table_name('for drop trigger')   if !$table;
    return $self->do(Geoffrey::Utils::replace_spare($trigger->drop, [$name, $table]));
}

sub list {
    my ($self, $schema) = @_;
    my $trigger = $self->converter->trigger;
    if (!$trigger || !$trigger->list) {
        Geoffrey::Exception::NotSupportedException::throw_action();
    }
    return $trigger->information($self->do_arrayref($trigger->list($schema)));
}

sub _find_same_trigger {
    my ($self, $table, $name, $schema) = @_;
    my $trigger = $self->converter->trigger;
    return [] if !$trigger->can('find_by_name_and_table');
    return $self->do_arrayref($trigger->find_by_name_and_table, [$table, $name, $schema]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Trigger - Action for triggers

=head1 VERSION

Version 0.000205

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Execute sql statements can lead very likely to incompatibilities.

=head2 alter

Not needed!

=head2 drop

Not needed!

=head2 list 
    
Get array about triggers from database

=head2 _find_same_trigger

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
