package Finance::Bank::Natwest;
use strict;
use vars qw( $VERSION );

use Carp;
use HTML::TokeParser;
use Finance::Bank::Natwest::Connection;

$VERSION = '0.05';

=head1 NAME

Finance::Bank::Natwest - Check your Natwest bank accounts from Perl

=head1 DESCRIPTION

This module provides a rudimentary interface to the Natwest online
banking system at C<https://www.nwolb.com/>. You will need
either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed for HTTPS
support to work with LWP.

=head1 SYNOPSIS

  my $nw = Finance::Bank::Natwest->new( credentials => 'Constant',
                                        credentials_options => {
					   dob => '010179',
					   uid => '0001',
					   password => 'Password',
					   pin => '4321' } );

  my @accounts = $nw->accounts;

  foreach (@accounts) {
        printf "%25s : %6s / %8s : GBP %8.2f\n",
          $_->{name}, $_->{sortcode}, $_->{account}, $_->{available};
  }

=head1 METHODS

=over 4 

=item B<new>

  my $nw = Finance::Bank::Natwest->new( credentials => 'Constant',
                                        credentials_options => {
					   dob => '010179',
					   uid => '0001',
					   password => 'Password',
					   pin => '4321' }
  );

  # Or create the credentials object ourselves
  my $credentials = Finance::Bank::Natwest::CredentialsProvider::Constant->new(
     dob => '010179', uid => '0001', password => 'Password', pin => '4321' );

  my $nw = Finance::Bank::Natwest->new( credentials => $credentials );


C<new> can be called in two different ways. It can take a single parameter,
C<credentials>, which will accept an already created credentials object, of type 
C<Finance::Bank::Natwest::CredentialsProvider::*>. Alternatively, it can take two
parameters, C<credentials> and C<credentials_options>. In this case 
C<credentials> is the name of a credentials class to create an instance of, and
C<credentials_options> is a hash of the options to pass-through to the
constructor of the chosen class.

If the second form of C<new> is being used, and the chosen class is I<not> one
of the ones supplied as standard then it will need to be C<required> first.

If any errors occur then C<new> will C<croak>.

=cut

use constant URL_ROOT => 'https://www.nwolb.com';
use constant DIR_BASE => '/secure/';

sub url_base { $_[0]->URL_ROOT . $_[0]->DIR_BASE };

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;

    {
       local $Carp::CarpLevel = $Carp::CarpLevel + 1;
       $self->{connection} = Finance::Bank::Natwest::Connection->new(
          %opts, url_base => $self->url_base
       );
    }

    $self->_load_accounts();
    
    return $self;
};

=item B<accounts>

  my @accounts = $nw->accounts;

  # Or get a list ref instead
  my $accounts = $nw->accounts;

Returns a list containing a summary of any accounts available from the
supplied credentials. Each item in the list is a hash reference that holds
summary information for a single account, and contains this data:

=over 4

=item B<name> - the name of the account

=item B<account> - the account number

=item B<sortcode>

=item B<balance>

=item B<available> - the currently available funds

=back

=cut

sub accounts {
   my $self = shift;
   
   return unless defined wantarray;

   return wantarray ? @{$self->{data}{accounts}} : $self->{data}{accounts};
}

sub _load_accounts {
   my $self = shift;

   my ($accountlist, $ministmt) = 
      ($self->{connection}->post("Balances.asp?0") =~ 
         /<form.*?>(.*?)<\/form>(.*?)<div class="smftr">/s);

   $self->{data}{accounts} = $self->_process_accountlist($accountlist);

}

sub _process_accountlist{
   my ($self, $accountlist) = @_;
   my (@accounts, $stream, $token);

   $stream = HTML::TokeParser->new(\$accountlist) or croak "$!, stopped";

   $stream->get_tag("tr");
   while ($token = $stream->get_tag("tr") and exists $token->[1]{class}) {
      $token = $stream->get_tag("td");

      my $name = $stream->get_trimmed_text("/td");
      $stream->get_tag("td"); $stream->get_tag("span");

      $name =~ s/\xa0+/ /;
      $name =~ s/^\s+//;
      $name =~ s/\s+$//;

      my $sortcode = $stream->get_trimmed_text("/span");
      $stream->get_tag("span");

      my $account = $stream->get_trimmed_text("/span");
      $stream->get_tag("td");

      my $balance = $stream->get_trimmed_text("/td");
      $stream->get_tag("td");

      $balance =~ s/\xa3//;
      $balance =~ s/,//g;

      my $available = $stream->get_trimmed_text("/td");
      $available =~ s/\xa3//;
      $available =~ s/,//g;

      push @accounts, {
         name      => $name,
         account   => $account,
         sortcode  => $sortcode,
         balance   => $balance,
         available => $available,
      };
   }

   return \@accounts;
};

1;
__END__

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

=head1 TODO

=over 4

=item B<convert remaining existing functionality>

I still have ministatement, direct debit and standing order functionality to copy
over from my earlier, unreleased version of this code, along with ways of
accessing accounts by name or account/sortcode alongside the list layout.

=item B<more tests>

=item B<add bill payments>

=item B<add statement querys>

=item B<add statement downloads>

=back

=head1 BUGS

There are sure to be some bugs lurking in here somewhere. If you find one, please
report it via RT

=head1 THANKS

Simon Cozens for C<Finance::Bank::LloydsTSB>. Various members of London.pm for
prodding me occasionally to come back to this and do some more on it.

=head1 AUTHOR

Jody Belka C<knew@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Jody Belka

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
