# Copyright (c) 2012-2017 Martin Becker, Blaubeuren.  All rights reserved.
# This package is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

package Math::Logic::Ternary::Calculator::Mode;

use 5.008;
use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.004';

use constant _NAME    => 0;
use constant _ORDINAL => 1;
use constant _SUFFIX  => 2;
use constant _LSUFFIX => 3;

my @modes =
my ($balanced, $unbalanced, $negative_base) = map { bless $_ } (
    ['balanced',   0,  '',   ''],
    ['unbalanced', 1, 'u', '_u'],
    ['base(-3)',   2, 'v', '_v'],
);
my %from_string = (
    b => $balanced,
    map {($_->name => $_, $_->ordinal => $_, $_->suffix => $_)} @modes
);

sub balanced      { $balanced         }
sub unbalanced    { $unbalanced       }
sub negative_base { $negative_base    }
sub modes         { @modes            }

sub from_string   { $from_string{$_[1]} }

sub name          { $_[0]->[_NAME]    }
sub ordinal       { $_[0]->[_ORDINAL] }
sub suffix        { $_[0]->[_SUFFIX]  }
sub lsuffix       { $_[0]->[_LSUFFIX] }

sub is_equal      { $_[0]->[_ORDINAL] == $_[1]->[_ORDINAL] }
sub is_balanced   { !$_[0]->[_ORDINAL] }

sub suffix_for    { $_[0]->[(0 <= index $_[1], '_')? _LSUFFIX: _SUFFIX] }

sub apply {
    my ($this, $op) = @_;
    return $op . $this->suffix_for($op);
}

sub unapply {
    my ($this, $op) = @_;
    foreach my $sfx ($this->lsuffix, $this->suffix) {
        return $op if $op =~ s/$sfx\z//;
    }
    my $sfx  = $this->suffix_for($op);
    my $name = $this->name;
    croak qq{$op: does not have suffix "$sfx" matching mode "$name"};
}

1;
__END__
=head1 NAME

Math::Logic::Ternary::Calculator::Mode - calculator arithmetic operation mode

=head1 VERSION

This documentation refers to version 0.004 of
Math::Logic::Ternary::Calculator::Mode.

=head1 SYNOPSIS

  use Math::Logic::Ternary::Calculator::Mode;
  use constant MODE => Math::Logic::Ternary::Calculator::Mode::;

  $mode = MODE->from_string('balanced');
  $mode = MODE->balanced;       # same thing
  $name = $mode->name;          # 'balanced'

  $mode = MODE->unbalanced;
  $op   = $mode->apply('Cmp');  # 'Cmpu'
  $bop  = $mode->unapply($op);  # 'Cmp'

=head1 DESCRIPTION

TODO

=head2 Exports

None.

=head1 SEE ALSO

=over 4

=item L<Math::Logic::Ternary::Calculator>

=back

=head1 AUTHOR

Martin Becker E<lt>becker-cpan-mpE<64>cozap.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2012-2017 by Martin Becker, Blaubeuren.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
