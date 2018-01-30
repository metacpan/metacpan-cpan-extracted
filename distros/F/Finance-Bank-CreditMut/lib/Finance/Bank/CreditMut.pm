package Finance::Bank::CreditMut;
use strict;
use Carp qw(carp croak);
use WWW::Mechanize;
use HTML::TableExtract;
use XML::Twig;
use vars qw($VERSION);

$VERSION = 0.14;

=pod

=encoding utf8

=head1 NAME

Finance::Bank::CreditMut -  Check your Crédit Mutuel accounts from Perl

=head1 SYNOPSIS

 use Finance::Bank::CreditMut;

 my @accounts = Finance::Bank::CreditMut->check_balance(
    username => "$username",  # Be sure to put the numbers
    password => "$password",  # between quote.
 );

 foreach my $account ( @accounts ){
    local $\ = "\n";
    print "       Name ", $account->name;
    print " Account_no ", $account->account_no;
    print "  Statement\n";

    foreach my $statement ( $account->statements ){
        print $statement->as_string;
    }
 }

=head1 DESCRIPTION

This module provides a rudimentary interface to the CyberMut online banking
system at L<https://www.creditmutuel.fr/>. You will need either
Crypt::SSLeay or IO::Socket::SSL installed for HTTPS support to work with
LWP.

The interface of this module is directly taken from Briac Pilpré's
Finance::Bank::BNPParibas.

=head1 WARNING

This is code for B<online banking>, and that means B<your money>, and that
means B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source
of this module yourself to reassure yourself that I am not doing anything
untoward with your banking data. This software is useful to me, but is
provided under B<NO GUARANTEE>, explicit or implied.

=head1 METHODS

=head2 check_balance( username => $username, password => $password, ua => $ua )

Return a list of account (F::B::CM::Account) objects, one for each of your
bank accounts. You can provide to this method a WWW::Mechanize object as
third argument. If not, a new one will be created.

=cut

sub check_balance {
    my ( $class, %opts ) = @_;
    croak "Must provide a password" unless exists $opts{password};
    croak "Must provide a username" unless exists $opts{username};

    my @accounts;

    $opts{ua} ||= WWW::Mechanize->new(
        agent      => __PACKAGE__ . "/$VERSION ($^O)",
        cookie_jar => {},
    );

    my $self = bless {%opts}, $class;

    my $orig_r;
    my $count = 0;
    {
        $orig_r = $self->{ua}->get("https://www.creditmutuel.fr/fr/authentification.html");
        # loop detected, try again
        ++$count;
        redo unless $orig_r->content || $count > 13;
    }
    croak $orig_r->error_as_HTML if $orig_r->is_error;

    {
        local $^W;  # both fields_are read-only
        my $click_r = $self->{ua}->submit_form(
            form_id => 'bloc_ident',
            fields      => {
                _cm_user => $self->{username},
                _cm_pwd  => $self->{password},
            }
        );
        croak $click_r->error_as_HTML if $click_r->is_error;
    }   

    my $r = $self->{ua}->get("https://www.creditmutuel.fr/fr/banque/comptes-et-contrats.html");
    croak $r->error_as_HTML if $r->is_error;
    
    # The current page contains a table displaying the accounts and their
    # balances. 

    my $te = new HTML::TableExtract(keep_html => 1, headers => [
        qq{Contrat},
        qq{D\xe9bit},
        qq{Cr\xe9dit},
        qq{Actions},
    ]);
    $te->parse($self->{ua}->content());

    # The first column contains the name and number of each account, each in a
    # <span>. Let's use XML::Twig to parse this.
    my @field;
    my $twig = XML::Twig->new(twig_handlers => {
            span => sub { push @field, $_->text },
        });

    for my $ts ( $te->tables() ) {
        # The table contains several sections, the first one being the accounts
        # (then, the insurances, etc). We will detect the sections headers and
        # consider only the first one.
        my $header_count = 1;

        foreach ( $ts->rows() ) {

            if ( $_->[0] =~ /ei_decal_anchor/ ) {
                # section header detected
                $header_count--;
                next;
            }
            next if $header_count; # ignore all but the first section

            # Retrieve the account name and number from the <span>s in the
            # first column. The name is in the first <span>, the number in the
            # last one.
            @field = ();
            $twig->parse(shift @$_);
            my $name = join ' ' => @field[0, -1];

            my ($amount, $currency);
            for ( @$_ ) {
                next unless $_ && /ei_sdsf_montant/; # detect the column that contains the balance
                s{<span.*?>}{}; # remove HTML
                s{</span>}{};
                ($amount, $currency) = split / /;
                $amount =~ tr/0-9,-//cd; # remove everything but numbers, sign and decimal separator
                $amount =~ s/,/./;
                $amount += 0; # turn into a number
            }

            push @accounts, Finance::Bank::CreditMut::Account->new(
                $name,
                $currency,
                $amount,
                $self->{ua},
            );
        }
    }
    @accounts;
}

package Finance::Bank::CreditMut::Account;

=pod

=head1 Account methods

=head2 sort_code()

Return the sort code of the account. Currently, it returns an undefined
value.

=head2 name()

Returns the human-readable name of the account.

=head2 account_no()

Return the account number, in the form C<XXXXXXXXX YY>, where X and Y are
numbers.

=head2 balance()

Returns the balance of the account.

=head2 statements()

Return a list of Statement object (Finance::Bank::CreditMut::Statement).

=head2 currency()

Returns the currency of the account as a three letter ISO code (EUR, CHF,
etc.)

=cut

sub new {
    my $class = shift;
    my ($name, $currency, $balance, $ua, $url) = @_;
    $name =~ /(.*?)\s+(\d+.\d+(?:.\d+)?)/ or warn "!!";
    ($name, my $account_no) = ($1, $2);
    $account_no =~ s/\D/ /g; # remove non-breaking space.
    $account_no =~ s/^\d+.//; # remove leading agency number

    bless {
        name       => $name,
        account_no => $account_no,
        sort_code  => undef,
        date       => undef,
        balance    => $balance,
        currency   => $currency,
        ua         => $ua,
        url        => $url,
    }, $class;
}

sub sort_code  { undef }
sub name       { $_[0]->{name} }
sub account_no { $_[0]->{account_no} }
sub balance    { $_[0]->{balance} }
sub currency    { $_[0]->{currency} }
sub statements { 

    my $self = shift;

    @{
        $self->{statements} ||= do {
            $self->{ua}->get($self->{url});
            $self->{ua}->follow_link(text_regex => qr/XP/);
            chomp(my @content = split /\015\012/, $self->{ua}->content());
            shift @content;
            [map Finance::Bank::CreditMut::Statement->new($_), @content];
        };
    };
}

package Finance::Bank::CreditMut::Statement;

=pod

=head1 Statement methods

=head2 date()

Returns the date when the statement occured, in DD/MM/YY format.

=head2 description()

Returns a brief description of the statement.

=head2 amount()

Returns the amount of the statement (expressed in Euros or the account's
currency). Although the Crédit Mutuel website displays number in continental
format (i.e. with a coma as decimal separator), amount() returns a real
number.

=head2 as_string($separator)

Returns a tab-delimited representation of the statement. By default, it uses
a tabulation to separate the fields, but the user can provide its own
separator.

=cut

sub new {
    my $class     = shift;
    my $statement = shift;

    my ($date, undef, $withdrawal, $deposit, $comment) = split /;/, $statement;

    $date =~ s/\d\d(\d\d)$/$1/; # year on 2 digits only
    # negative number are displayed in a separate column. Move them to the same
    # one as positive numbers.
    my $amount = $withdrawal || $deposit || 0;
    $amount =~ s/,/./;
    $amount =~ tr/'//d; # remove thousand separators
    $amount += 0; # turn into a number

    bless [ $date, $comment, $amount ], $class;
}

sub date        { $_[0]->[0] }
sub description { $_[0]->[1] }
sub amount      { $_[0]->[2] }

sub as_string { join ( $_[1] || "\t", @{ $_[0] } ) }

1;

__END__

=head1 COPYRIGHT

Copyright 2002-2003, Cédric Bouvier. All Rights Reserved. This module can be
redistributed under the same terms as Perl itself.

=head1 AUTHOR

Cédric Bouvier <cbouvi@cpan.org>

Thanks to Simon Cozens for releasing Finance::Bank::LloydsTSB and to Briac
Pilpré for Finance::Bank::BNPParibas.

=head1 SEE ALSO

Finance::Bank::BNPParibas, WWW::Mechanize

=cut

