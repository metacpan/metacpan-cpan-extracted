# Copyright (c) 2008 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::DirectDebit;
use base qw(Class::Accessor);
__PACKAGE__->mk_ro_accessors(qw(payee reference)); ## no critic

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);

sub new
{
  my ($class, $row) = @_;

  croak 'No row data passed to '.__PACKAGE__.' constructor'
    if not defined $row;
  croak 'row data is not an array ref'
    if ref $row ne 'ARRAY';

  my $self = { payee     => _trim($row->[0]),
               reference => _trim($row->[1]) };
  bless $self, $class;

  return $self;
}

sub _trim
{
  my ($str) = @_;
  return if not defined $str;
  $str =~ s/[\x80-\xff]//gs;
  $str =~ s/\r//gs;
  $str =~ s/\s+/ /gs;
  $str =~ s/^\s+//gs;
  $str =~ s/\s+$//gs;
  return $str;
}

1;
__END__

=for stopwords Connell online

=head1 NAME

Finance::Bank::Cahoot::DirectDebit - Cahoot direct debit record

=head1 DESCRIPTION

This module describes describes the object that holds the information
contained in a single statement transaction.

=head1 SYNOPSIS

  my $cahoot = Finance::Bank::Cahoot->new(credentials => 'ReadLine');
  my @accounts = $cahoot->accounts;
  $cahoot->set_account($accounts->[0]->{account});
  my $debits = $cahoot->debits;
  foreach my $debit (@$debits) {
    print $debit->payee, q{,},
          $debit->reference || 0, qq{\n};
  }

=head1 METHODS

=over 4

=item B<new>

Create a new instance of a a Cahoot direct debit entry. It is unlikely that
the C<new> method should need to be called by anything other than
C<Finance::Bank::Cahoot>.

=item B<payee>

Returns the name of the recipients of the direct debit.

=item B<reference>

Returns the direct debit reference supplied to the payee.

=back

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems
just as apt here.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 NOTES

This has only been tested on my own accounts. I imagine it should work on any
account types, but I can't guarantee this.

=head1 AUTHOR

Jon Connell <jon@figsandfudge.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2008 by Jon Connell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
