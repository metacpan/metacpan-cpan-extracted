#
# This file is part of Games-Pandemic
#
# This software is Copyright (c) 2009 by Jerome Quelin.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 2, June 1991
#
use 5.010;
use strict;
use warnings;

package Games::Pandemic::Role::Medic;
{
  $Games::Pandemic::Role::Medic::VERSION = '1.120510';
}
# ABSTRACT: medic pandemic role

use Moose::Role;
use Games::Pandemic::I18n      qw{ T };
use Games::Pandemic::Utils;


around auto_clean_on_cure => sub { 1 };
around treat_all          => sub { 1 };
sub color { '#e48006'  }
sub role  { T('Medic') }
sub _role { 'medic'    }


no Moose::Role;
# moose::role cannot be made immutable
#__PACKAGE__->meta->make_immutable;

1;


=pod

=head1 NAME

Games::Pandemic::Role::Medic - medic pandemic role

=head1 VERSION

version 1.120510

=for Pod::Coverage color
    role

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Jerome Quelin.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut


__END__

