# $File: //member/autrijus/Finance-Bank-Fubon-TW/lib/Finance/Bank/Fubon/TW.pm $ $Author: autrijus $
# $Revision: #2 $ $Change: 5938 $ $DateTime: 2003/05/17 22:34:34 $

package Finance::Bank::Fubon::TW;
use strict;
use Carp;
our $VERSION = '0.01';
use WWW::Mechanize;
our $ua = WWW::Mechanize->new(
    env_proxy => 1, 
    keep_alive => 1, 
    timeout => 60,
); 

sub check_balance {
    my ($class, %opts) = @_;
    local $^W;

    croak "Must provide a password" unless exists $opts{password};
    croak "Must provide a username" unless exists $opts{username};

    my $self = bless { %opts }, $class;

    $ua->get('https://net.fubonbank.com.tw/ebank/nbssl/nbauth/loginmain.asp');
    $ua->field(USERID => $self->{username});
    $ua->field(PWD => $self->{password});
    $ua->submit;
    $ua->get('https://net.fubonbank.com.tw/ebank/nbssl/nbauth/QryMain.asp');

    my $html = $ua->content;

    my @accounts;
    while ($html =~ s!<TR.*?<br>(\d+)</td><td[^>]*>([^<]+)</td>!!) {
	my ($id, $balance) = ($1, $2);
	$balance =~ s!,!!g;
	$balance = 0 + $balance;
        push @accounts, (bless {
            balance    => $balance,
            name       => $id,
            account_no => $id,
            parent     => $self,
        }, "Finance::Bank::Fubon::TW::Account");
    }

    return @accounts;
}

package Finance::Bank::Fubon::TW::Account;
# Basic OO smoke-and-mirrors Thingy
no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

sub statement {
    my $ac = shift;
    my $code;

    $ua->get('https://net.fubonbank.com.tw/ebank/Nbssl/asp/VR002Htm.asp?acc=' . $ac->account_no);
    $ua->submit;

    my $html = $ua->content;
    my @transactions;
    while ($html =~ s!<tr >(.*?)</tr>!!s) {
	my @lines;
	foreach my $line (split(/\n/, $1)) {
	    next unless $line =~ /<td/;
	    $line =~ s/^\s+//;
	    $line =~ s/\s+$//;
	    $line =~ s/<[^>]+> ?//g;
	    $line =~ s/^&nbsp$//g;
	    if ( $line =~ s/,// ) {
		$line = 0 + $line;
	    }
	    push @lines, $line;
	}
	push @transactions, join(',', @lines) . "\n";
    }

    return join("", @transactions);
}

1;

__END__

=head1 NAME

Finance::Bank::Fubon::TW - Check Fubon eBank accounts from Perl

=head1 SYNOPSIS

    use Finance::Bank::Fubon::TW;
    foreach ( Finance::Bank::Fubon::TW->check_balance(
	username  => $username,
	password  => $password,
    )) {
	print "[", $_->name, ': $', $_->balance, "]\n";
	print join("\t", split(/,/, $_->statement));
    }

=head1 DESCRIPTION

This module provides a rudimentary interface to the Fubon eBank
banking system at L<http://www.fubonbank.com.tw/ebank.htm>.

You will need either B<Crypt::SSLeay> or B<IO::Socket::SSL> installed
for HTTPS support to work with LWP.

=head1 CLASS METHODS

    check_balance(username => $u, password => $p)

Return a list of account objects, one for each of your bank accounts.

=head1 ACCOUNT OBJECT METHODS

    $ac->name
    $ac->account_no

Return the name of the account and the account number.

    $ac->balance

Return the balance as a signed floating point value.

    $ac->statement

Return a mini-statement as a line-separated list of transactions.
Each transaction is a comma-separated list. B<WARNING>: this interface
is currently only useful for display, and hence may change in later
versions of this module.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 AUTHORS

Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>

Based on B<Finance::Bank::LloydTSB> by Simon Cozens C<simon@cpan.org>.

=head1 COPYRIGHT

Copyright 2003 by Autrijus Tang E<lt>autrijus@autrijus.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
