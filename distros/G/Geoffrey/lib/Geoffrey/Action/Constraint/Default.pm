package Geoffrey::Action::Constraint::Default;

use utf8;
use 5.016;
use strict;
use warnings;
use Geoffrey::Utils;
use Geoffrey::Exception::NotSupportedException;

use parent 'Geoffrey::Role::Action';

$Geoffrey::Action::Constraint::Default::VERSION = '0.000101';

sub add {
   my ($self, $params) = @_;
   Geoffrey::Exception::RequiredValue::throw_table_name() if !$params->{table};
   my $sequence = $self->converter->sequence;
   if (!$sequence->can('nextval')) {
      Geoffrey::Exception::NotSupportedException::throw_sequence('nextval', $self->converter);
   }

   my $s_table = $params->{table} =~ s/"//gr;
   $params->{name} =~ s/"//g;
   $params->{name} //= qq~seq_$s_table~ . q/_/ . time;
   my $sql = Geoffrey::Utils::replace_spare($sequence->add,
      [$params->{name}, 1, 1, $Geoffrey::Utils::INT_64BIT_SIGNED, 1, 1]);
   $self->do($sql);
   return Geoffrey::Utils::replace_spare($sequence->nextval, [$params->{name}]);
}

sub drop {
   my ($self, $name) = @_;
   my $sequence = $self->converter->sequence;
   if (!$sequence->can('drop')) {
      Geoffrey::Exception::NotSupportedException::throw_sequence('drop', $self->converter);
   }
   return $self->do(Geoffrey::Utils::replace_spare($sequence->drop, [$name]));
}

sub list_from_schema {
   my ($self, $schema) = @_;
   my $sequence = $self->converter->sequence;
   if (!$sequence->can('list')) {
      Geoffrey::Exception::NotSupportedException::throw_sequence('list', $self->converter);
   }
   return $self->converter->sequence_information($self->do_arrayref($sequence->list($schema), []));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Geoffrey::Action::Constraint::Default - Action handler for sequences

=head1 VERSION

Version 0.000101

=head1 DESCRIPTION

=head1 SYNOPSIS

=head1 SUBROUTINES/METHODS

=head2 add

Decides if autoincrement or to create a sequnece.
Add sequences if it's needed

=head2 drop

Not yet implemented!

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
