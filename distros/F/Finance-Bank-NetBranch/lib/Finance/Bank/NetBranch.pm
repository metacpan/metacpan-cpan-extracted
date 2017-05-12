=head1 NAME

Finance::Bank::NetBranch - Manage your NetBranch accounts with Perl

=cut
package Finance::Bank::NetBranch;

use strict;
use warnings;

use Alias 'attr';
use Carp;
use Date::Parse;
use DateTime;
use HTML::Entities qw(%entity2char _decode_entities);
use HTML::TreeBuilder;
use WWW::Mechanize;
$Alias::AttrPrefix = "main::";	# make use strict 'vars' palatable

=head1 VERSION

Version 0.07

=cut

our $VERSION = 0.07;

=head1 SYNOPSIS

  use Finance::Bank::NetBranch;
  my $nb = Finance::Bank::NetBranch->new(
      url      => 'https://nbp1.cunetbranch.com/valley/',
      account  => '12345',
      password => 'abcdef',
  );

  my @accounts = $nb->accounts;

  foreach (@accounts) {
      printf "%20s : %8s : USD %9.2f of %9.2f\n",
          $_->name, $_->account_no, $_->available, $_->balance;
      my $days = 20;
      for ($_->transactions(from => time - (86400 * $days), to => time)) {
          printf "%10s | %20s | %80s : %9.2f, %9.2f\n",
              $_->date->ymd, $_->type, $_->description, $_->amount, $_->balance;
      }
  }

=head1 DESCRIPTION

This module provides a rudimentary interface to NetBranch online banking. This
module was originally implemented to interface with Valley Communities Credit
Union's page at C<https://nbp1.cunetbranch.com/valley/>, but the behavior of
the module is theoretically generalized to "NetBranch" type online access.
However, I do not have access to another NetBranch account with another bank,
and so any feedback on the actual behavior of this module would be greatly
appreciated.

You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work.

=head1 CLASS METHODS

=head2 Finance::Bank::NetBranch

=over 4

=item new

Creates a new C<Finance::Bank::NetBranch> object; does not connect to the server.

=cut
sub new {
	my $type = shift;
	bless {	@_ }, $type;
}

=back

=head1 OBJECT METHODS

=head2 Finance::Bank::NetBranch

=over 4

=item accounts

Retrieves cached accounts information, connecting to the server if necessary.

=cut
sub accounts {
	my $self = attr shift;
	@::accounts || @{ $self->_get_balances }
}

=item _login

Logs into the NetBranch site (internal use only)

=cut
sub _login {
	my $self = attr shift;

	$::mech ||= WWW::Mechanize->new;
	$::mech->get($::url)
		or die "Could not fetch login page URL '$::url'";
	my $result = $::mech->submit_form(
		form_name => 'frmLogin',
		fields	=> {
			USERNAME	=> $::account,
			password	=> $::password,
		},
		button    => 'Login'
	) or die "Could not submit login form as account '$::account'";

	$::mech->uri =~ /welcome/i
		or die "Failed to log in as account '$::account'";

	$::logged_in = 1;
	$result;
}

=item _logout

Logs out of the NetBranch site (internal use only)

=cut
sub _logout {
	my $self = attr shift;
	$::mech->follow_link(text_regex => qr/Logo(ut|ff)/i)
		or die "Failed to log out";
	$::logged_in = 0;
}

=item _get_balances

Gets account balance information (internal use only)

=cut
sub _get_balances {
	my $self = attr shift;

	my $result = $self->_login unless $::logged_in;

	# Change to use HTML::TreeBuilder
	my ($user, undef, $private) = $result->content =~ m!
		<h3>welcome\s*([^<]+)</h3>member\s*\#(\d+)\s*\(<b>([^<]+)</b>\)<br>
	!imox;
	_decode_entities($user, +{ %entity2char, nbsp => ' ' });

	my $t = HTML::TreeBuilder->new;
	my @accounts = map {
		my ($name, $bal, $avail) = map { $_->as_text } $_->find('td');
		($name, my $account_no) = ($name =~ m/^([^(]+)\(([^)]+)\).*$/);
		$avail =~ s/\$//; $bal =~ s/\$//; # get rid of currency sign
		$avail =~ s/,//g; $bal =~ s/,//g; # Get rid of thousands separators
		bless {
			account_no	=> $account_no,
			# Detect trailing parenthesis (negative number)
			available	=> ($avail	=~ /([\d+.]+)\)/) ? -$1 : $avail,
			balance		=> ($bal	=~ /([\d+.]+)\)/) ? -$1 : $bal,
			name		=> $name,
			parent		=> $self,
			sort_code	=> $name,
			transactions	=> [],
		}, "Finance::Bank::NetBranch::Account";
	} do {
		$t->parse($result->content);
		$t->eof;

		$t->look_down(
			_tag => 'table',
			sub {
				my $table = $_[0];
				$table->look_down(
					_tag => 'th',
					class => 'ColumnTitle',
					sub { grep { /Balance/i } $_[0]->content_list },
					sub { $_[0]->depth - $table->depth < 3 },
				)
			},
		)->look_down(
			_tag => 'tr',
			sub { !$_[0]->find('th') },
			sub { !grep { $_->as_text =~ /Total/i } $_[0]->content_list },
		)
	};
	$t->delete;
	$self->_logout;
	$self->{accounts} = \@accounts
}

=item _get_transactions

Gets transaction information, given start and end dates (internal use only)

=cut
sub _get_transactions {
	my $self = attr shift;
	my ($account, %args) = @_;

	$self->_login unless $::logged_in;
	$::mech->follow_link(text_regex => qr/Account History/)
		or die "Failed to open account history mech";

	my $result = $::mech->follow_link(
		text_regex => qr/\($account->{account_no}\)/
	) or die "Failed to open history for account '$account->{account_no}'";

	# Convert dates into DateTime objects if necessary
	my ($from, $to) = map {
		ref($_) eq 'DateTime'
			? $_
			: DateTime->from_epoch(epoch => $_)
	} @args{qw(from to)};

=item _pad0

Pads a number to two digits with zeroes

=cut

	sub _pad0 { sprintf "%0.2d", shift }

	$::mech->form_name('HistReq');

	$::mech->select('FM', _pad0($from->month));
	$::mech->select('FD', $from->day);
	$::mech->select('FY', $from->year);

	$::mech->select('TM', _pad0($to->month));
	$::mech->select('TD', $to->day);
	$::mech->select('TY', $to->year);

	$result = $::mech->submit
		or die "Could not submit history request form";

	my $t = HTML::TreeBuilder->new;
	# Reverse to put oldest transactions first
	my @transactions = reverse map {
		my ($date, $type, $desc, $amount, $bal) = map { $_->as_text } $_->find('td');
		$date = DateTime->from_epoch(epoch => str2time($date));
		$amount =~ s/\$//; $bal =~ s/\$//; # get rid of currency sign
		$amount =~ s/,//g; $bal =~ s/,//g; # Get rid of thousands separators
		$desc =~ s/\x{A0}/ /g;
		bless {
			# Detect trailing parenthesis (negative number)
			amount		=> ($amount	=~ /([\d+.]+)\)/) ? -$1 : $amount,
			balance		=> ($bal	=~ /([\d+.]+)\)/) ? -$1 : $bal,
			date		=> $date,
			description	=> $desc,
			parent		=> $account,
			type		=> $type,
		}, "Finance::Bank::NetBranch::Transaction";
	} do {
		$t->parse($result->content);
		$t->eof;

		$t->look_down(
			_tag => 'table',
			sub {
				my $table = $_[0];
				$table->look_down(
					_tag => 'th',
					class => 'ColumnTitle',
					sub { grep { /New Balance/i } $_[0]->content_list },
					sub { $_[0]->depth - $table->depth < 3 },
				)
			},
		)->look_down(
			_tag => 'tr',
			sub { !$_[0]->find('th') },
		)
	};
	$t->delete;
	$self->_logout;
	$self->{transactions} = \@transactions
}

=back

=head2 Finance::Bank::NetBranch::Account

=over 4

=item name

=item sort_code

=item account_no

Return the account name, sort code or account number. The sort code is just the
name in this case, but it has been included for consistency with other
Finance::Bank::* modules.

=item balance

=item available

Return the account balance or available amount as a signed floating point value.

=cut

package Finance::Bank::NetBranch::Account;
use Alias 'attr';
use Carp;

no strict;

=item AUTOLOAD

Provides accessors (from Finance::Card::Citibank)

=cut
sub AUTOLOAD { my $self = shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

=item transactions(from => $start_date, to => $end_date)

Retrieves C<Finance::Bank::NetBranch::Transaction> objects for the specified
account object between two dates (unix timestamps or DateTime objects).

=back

=cut
sub transactions ($%) {
	my $self = attr shift;
	my (%args) = @_;
	$args{from} && $args{to}
		or croak "Must supply from and to dates";
	@::transactions =
		(@::transactions || @{ $::parent->_get_transactions($self, %args) });
}

=head2 Finance::Bank::NetBranch::Transaction

=over 4

=item date

=item type

=item description

=item amount

=item balance

Return appropriate data from this transaction.

=cut
package Finance::Bank::NetBranch::Transaction;
no strict;

=item AUTOLOAD

Provides accessors (from Finance::Card::Citibank)

=back

=cut
sub AUTOLOAD { my $self = shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;

__END__

=head1 WARNING

This warning is verbatim from Simon Cozens' C<Finance::Bank::LloydsTSB>,
and certainly applies to this module as well.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 BUGS

Probably, but moreso lack of such incredibly dangerous features as transfers,
scheduled transfers, etc., coming in a future release. Maybe.

Please report any bugs or feature requests to
C<bug-finance-bank-netbranch at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Bank-NetBranch>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Bank::NetBranch

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Bank-NetBranch>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Bank-NetBranch>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-NetBranch>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Bank-NetBranch>

=back


=head1 THANKS

Mark V. Grimes for C<Finance::Card::Citibank>. The pod was taken from Mark's
module.

=head1 AUTHOR

Darren M. Kulp C<< <darren@kulp.ch> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Darren Kulp

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

