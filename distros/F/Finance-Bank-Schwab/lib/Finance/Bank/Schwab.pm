package Finance::Bank::Schwab;

# ABSTRACT: Check your account balances at Charles Schwab

use strict;
use warnings;

use Carp;
use WWW::Mechanize;
use HTML::TableExtract;

our $VERSION = '2.03';

our $ua = WWW::Mechanize->new(
    env_proxy  => 1,
    keep_alive => 1,
    timeout    => 30,
    cookie_jar => {},
);

# Debug logging:
# $ua->default_header( 'Accept-Encoding' => scalar HTTP::Message::decodable() );
# $ua->add_handler( "request_send",  sub { shift->dump; return } );
# $ua->add_handler( "response_done", sub { shift->dump; return } );

sub check_balance {
    my ( $class, %opts ) = @_;

    my $content = retrieve_summary_page(%opts);

    my $te = HTML::TableExtract->new(
        headers => [
            'Account',                       'Name',
            '(?:Value|Available\s+Balance)', '(?:Cash|Balance\sOwed)'
        ],
        keep_html => 1,
        ## decode    => 0,
    );

    {    # HTML::TableExtract warns about undef value with keep_html option
        $SIG{__WARN__} = sub {
            warn @_ unless $_[0] =~ /uninitialized value in subroutine entry/;
        };
        $te->parse($content);
    }

    my @accounts;
    for my $ts ( $te->tables ) {

        # print "Table (", join( ',', $ts->coords ), "):\n";

        for my $row ( $ts->rows ) {
            next if $row->[1] =~ /Totals/;    # Skip total rows

            ## strip_superscript( @$row[0..3] );
            strip_html( @$row[ 0 .. 3 ] );
            trim_whitespace(@$row);
            remove_currency_symbol( @$row[ 2 .. 3 ] );
            $row->[0] =~ s{^([\d.-]+).*$}{$1}s;    # Strip all but num from name

            # If this is an account with positions, go grab that data.
            # If not it is probably a bank account, ignore for now.
            my @positions =
              ( $row->[0] =~ /\d{4}-\d{4}/ )
              ? get_positions( $row->[0], %opts )
              : ();

            push @accounts, (
                bless {
                    cash       => $row->[3],
                    balance    => $row->[2],
                    name       => $row->[1],
                    sort_code  => $row->[1],
                    account_no => $row->[0],
                    statement  => undef,
                    positions  => \@positions,
                    ## parent       => $self,
                },
                "Finance::Bank::Schwab::Account"
            );

            # print join( ',', @$row ), "\n";
        }
    }

    return @accounts;
}

sub retrieve_summary_page {
    my (%opts) = @_;

    # Use the stored page content if requested
    return slurp( $opts{content} ) if $opts{content};

    croak "Must provide a password" unless exists $opts{password};
    croak "Must provide a username" unless exists $opts{username};

    # Get the login page
    $ua->get('https://client.schwab.com/Login/SignOn/CustomerCenterLogin.aspx')
      or croak "couldn't load inital page";

    # Find the login form, change the action url, then set the username/
    # password and submit
    my $login_form = $ua->form_name('aspnetForm')
      or croak "Couldn't find the login form";
    $login_form->action('https://client.schwab.com/Login/SignOn/signon.ashx')
      or croak "Couldn't update the action url on login form";
    my $username_field =
      'ctl00$WebPartManager1$CenterLogin$LoginUserControlId$txtLoginID';
    $login_form->value( $username_field => $opts{username} );
    $login_form->value( 'txtPassword'   => $opts{password} );
    $ua->submit() or croak "couldn't sign on to account";

    my $content = $ua->content;

    # Dump to the filename passed in log
    spew( $opts{log}, $content ) if $opts{log};

    return $content;
}

sub get_positions {
    my ( $acct, %opts ) = @_;

    # Only retrieve positions if requested
    return () unless $opts{get_positions};

    $acct =~ s/-//;

    my $content = retrieve_account_page( $acct, %opts );
    my @positions = retrieve_account_positions($content);
}

sub retrieve_account_page {
    my ( $acct, %opts ) = @_;

    # Used the saved data if content was supplied
    return slurp("$opts{content}.$acct") if $opts{content};

    # Grab the data from the Schwab site
    $ua->get(
        "https://client.schwab.com/Accounts/Positions/AccountPositionsSummary.aspx?selAcct=$acct"
    ) or croak "couldn't load position page for $acct";
    my $content = $ua->content;

    # Dump the page to a log file if the log filename was provided
    spew( "$opts{log}.$acct", $content ) if $opts{log};
}

sub retrieve_account_positions {
    my ($content) = @_;

    my $te = HTML::TableExtract->new(
        headers   => [ 'Symbol', 'Quantity', 'Price', 'Change' ],
        keep_html => 1,
        ## decode    => 0,
    );

    {    # HTML::TableExtract warns about undef value with keep_html option
        $SIG{__WARN__} = sub {
            warn @_
              unless $_[0] =~ /uninitialized value in subroutine entry/;
        };
        $te->parse($content);
    }

    my @positions;
    for my $ts ( $te->tables ) {

        # print "Table (", join( ',', $ts->coords ), "):\n";
        no warnings 'uninitialized';

        for my $row ( $ts->rows ) {

            next if $row->[2] eq '';         # Skip empty rows
            next if $row->[0] =~ /Total/;    # Skip total rows

            strip_superscript( @$row[ 0 .. 3 ] );
            strip_html( @$row[ 0 .. 3 ] );
            trim_whitespace(@$row);
            remove_commas( $row->[1] );
            remove_currency_symbol( @$row[ 2, 3 ] );

            # Note if these are stocks/bonds/cash/unknown
            my $type;
          SWITCH: {
                local $_ = $row->[0];
                m/SymbolRouting/       and $type = 'Stock', last;
                m/TradeBondSuperPopUp/ and $type = 'Bond',  last;
                m/Cash/                and $type = 'Cash',  last;
                $type = 'Unknown';
            }

            # The "Cash & Cash Investments" line is screwy, where the value is
            # in the "Change" column. Let's correct it and set "price" to be 1,
            # and "shares" be value.
            if ( $row->[0] =~ m/Cash/ ) {
                $row->[0] = 'Cash';      # Trim "& Cash Investments"
                $row->[1] = $row->[3];
                $row->[2] = 1;
            }

            # The Bond types use funny math, where bond prices are shown per
            # 100 shares.  Correction is to divide price or quantity by 100.  I
            # elect price.
            if ( $type =~ m/Bond/ ) {
                $row->[2] = $row->[2] / 100;
            }

            push @positions,
              bless {
                symbol   => $row->[0],
                quantity => $row->[1],
                price    => $row->[2],
                type     => $type,
              },
              'Finance::Bank::Schwab::Account::Positions';
        }
    }
    return @positions;

}

sub strip_html {

    # Simple regex to strip html from cells. Not the best practice, but this is
    # certainly not the most fragile part of this module.
    s{<[^>]*>}{}mg for grep { defined } @_;
}

sub trim_whitespace {
    s{^\s*|\s*$}{}g for grep { defined } @_;
}

sub remove_commas {
    s/[,]//xg for grep { defined } @_;
}

sub remove_currency_symbol {
    s/[\$,]//xg for grep { defined } @_;
}

sub strip_superscript {
    s{<sup[^>]*>[^<]*</sup>}{}mg for grep { defined } @_;
}

sub spew {
    my ( $filename, $content ) = @_;

    open( my $fh, ">", $filename ) or confess;
    print $fh $content;
    close $fh;
}

sub slurp {
    my ($filename) = @_;

    open my $fh, "<", $filename or confess;
    my $content = do { local $/; <$fh> };
    close $fh;

    return $content;
}

package Finance::Bank::Schwab::Account;

# Basic OO smoke-and-mirrors Thingy
no strict;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://x;
    return $self->{$AUTOLOAD};
}

package Finance::Bank::Schwab::Account::Positions;

# Basic OO smoke-and-mirrors Thingy
no strict;

sub AUTOLOAD {
    my $self = shift;
    $AUTOLOAD =~ s/.*:://x;
    return $self->{$AUTOLOAD};
}

1;

__END__

=pod

=head1 NAME

Finance::Bank::Schwab - Check your account balances at Charles Schwab

=head1 VERSION

version 2.03

=head1 SYNOPSIS

  use Finance::Bank::Schwab;
  my @accounts = Finance::Bank::Schwab->check_balance(
      username     => "xxxxxxxxxxxx",
      password     => "12345",
      get_position => 1,
  );

  for ( @accounts ) {
      printf "%20s : %8s / %8s : USD %9.2f USD %9.2f\n",
          $_->name, $_->sort_code, $_->account_no, $_->cash, $_->balance;

      for my $position ( @{ $_->positions } ) {
          printf "# \t%-10s %-10s %10s Shares \@ \$%-15s\n",
            $position->type,
            $position->symbol,
            $position->quantity,
            $position->price;
      }
      print "\n";

  }

=head1 DESCRIPTION

This module provides a rudimentary interface to the Charles Schwab site.
You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL> installed 
for HTTPS support to work. C<WWW::Mechanize> is required.  If you encounter
odd errors, install C<Net::SSLeay> and it may resolve itself.

=head1 CLASS METHODS

=head2 check_balance()

  check_balance( usename => $u, password => $p, get_positions => 1 )

Return an array of account objects, one for each of your bank accounts. If 
the C<get_positions> flag is true then account positions (share counts,
prices, etc) will be retrieved as well.

=head1 OBJECT METHODS

  $ac->name
  $ac->sort_code
  $ac->account_no

Return the account name, sort code and the account number. The sort code is
just the name in this case, but it has been included for consistency with 
other Finance::Bank::* modules.

  $ac->balance

Return the account balance as a signed floating point value.

  $ac->cash

Return the cash balance as a signed floating point value. This is useful if
the account has margin borrowing as the balance alone doesn't do justice.

  $ac->positions

Returns a reference to an array of Finance::Bank::Schwab::Account::Positions
objects. Each provides the following method:

  $position->symbol      (String)
  $position->quantity    (Signed Float)
  $position->price       (Signed Float)
  $position->type        (Stock/Bond/Cash/Unknown)

=head1 WARNING

This warning is verbatim from Simon Cozens' C<Finance::Bank::LloydsTSB>,
and certainly applies to this module as well.

This is code for B<online banking>, and that means B<your money>, and
that means B<BE CAREFUL>. You are encouraged, nay, expected, to audit
the source of this module yourself to reassure yourself that I am not
doing anything untoward with your banking data. This software is useful
to me, but is provided under B<NO GUARANTEE>, explicit or implied.

=head1 THANKS

Simon Cozens for C<Finance::Bank::LloydsTSB>. The interface to this module,
some code and the pod were all taken from Simon's module.

Thanks to Ryan Clark <ryan.clark9@gmail.com> for contributing the initial
implementation of the share count/price/etc retrieval routines.

=head1 AUTHOR

Mark Grimes <mgrimes@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Grimes <mgrimes@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
