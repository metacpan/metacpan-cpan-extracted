# Copyright (c) 2007 Jon Connell.
# All Rights Reserved.
#
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Finance::Bank::Cahoot::Statement;

use strict;
use warnings 'all';
use vars qw($VERSION);

$VERSION = '1.07';

use Carp qw(croak);
use Finance::Bank::Cahoot::Statement::Entry;

sub new
{
  my ($class, $statement) = @_;

  croak 'No statement table passed to '.__PACKAGE__.' constructor'
    if not defined $statement;
  croak 'statement is not an array ref'
    if ref $statement ne 'ARRAY';

  my $self = [ ];
  bless $self, $class;

  foreach my $row (@{$statement}) {
    push @{$self}, Finance::Bank::Cahoot::Statement::Entry->new($row);
  }
  return $self;
}

sub rows
{
  my $self = shift;
  return [ @{$self} ];
}

1;

__END__

=for stopwords Connell online

=head1 NAME

Finance::Bank::Cahoot::Statement - Cahoot statement object

=head1 DESCRIPTION

This module describes describes the object that holds the information
contained in a single statement returned by the C<Finance::Bank::Cahoot>
C<statement> and C<snapshot> methods.

=head1 SYNOPSIS

  my $cahoot = Finance::Bank::Cahoot->new(credentials => 'ReadLine');
  my @accounts = $cahoot->accounts;
  $cahoot->set_account($accounts->[0]->{account});
  my $snapshot = $cahoot->snapshot;
  foreach my $transaction (@$snapshot) {
    print $transaction->date, q{,},
          $transaction->details, q{,},
          $transaction->credit || 0, q{,},
          $transaction->debit || 0, qq{\n};
  }

=head1 METHODS

=over 4

=item B<new>

Create a new instance of a a Cahoot statement. It is unlikely that the
C<new> method should need to be called by anything other than
C<Finance::Bank::Cahoot>.

=item B<rows>

Returns a list reference containing a statement data with one transaction
per row, represented by a C<Finance::Bank::Cahoot::Statement::Entry> object.

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

Copyright 2007 by Jon Connell

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
