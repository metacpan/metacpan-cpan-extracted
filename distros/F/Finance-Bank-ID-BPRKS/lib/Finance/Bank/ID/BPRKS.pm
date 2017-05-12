package Finance::Bank::ID::BPRKS;

our $DATE = '2015-12-16'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use Moo;
use DateTime;
use Log::Any::IfLOG '$log';

use Parse::Number::ID qw(parse_number_id);

extends 'Finance::Bank::ID::Base';

has _variant => (is => 'rw'); # 'individual' only, for now
###bca
###has skip_NEXT => (is => 'rw');

sub BUILD {
    my ($self, $args) = @_;

    $self->site("https://ib.bprks.co.id") unless $self->site;
    $self->https_host("ib.bprks.co.id")   unless $self->https_host;
}

sub _req {
    my ($self, @args) = @_;

    # 2012-03-12 - KlikBCA server since a few week ago rejects TE request
    # header, so we do not send them.
    ###bca
    ###local @LWP::Protocol::http::EXTRA_SOCK_OPTS =
    ###    @LWP::Protocol::http::EXTRA_SOCK_OPTS;
    ###push(@LWP::Protocol::http::EXTRA_SOCK_OPTS, SendTE => 0);
    #$log->tracef("EXTRA_SOCK_OPTS=%s", \@LWP::Protocol::http::EXTRA_SOCK_OPTS);

    $self->SUPER::_req(@args);
}

# XXX tmp, should be in an indo date utility module
sub _parse_mon {
    my $self = shift;
    local $_ = lc(shift);
    if (/^(?:jan|januar[iy])$/) {
        return 1;
    } elsif (/^(?:[fp]eb|[fp]ebruar[iy])$/) {
        return 2;
    } elsif (/^(?:mar|mrt|maret|march)$/) {
        return 3;
    } elsif (/^(?:apr|april)$/) {
        return 4;
    } elsif (/^(?:mei|may)$/) {
        return 5;
    } elsif (/^(?:jun|jun[eiy])$/) {
        return 6;
    } elsif (/^(?:jul|jul[iy])$/) {
        return 7;
    } elsif (/^(?:agu|aug|ags?t|august|agustus)$/) {
        return 8;
    } elsif (/^(?:sep|september)$/) {
        return 9;
    } elsif (/^(?:o[kc]t|o[ct]ober)$/) {
        return 10;
    } elsif (/^(?:no[pv]|no[pv]ember)$/) {
        return 11;
    } elsif (/^(?:de[sc]|de[sc]ember)$/) {
        return 12;
    } else {
        die "Can't parse month: $_";
        #return 0;
    }
}

sub _parse_num {
    my ($self, $s) = @_;
    my $neg = $s =~ s/^\((.+)\)$/$1/;
    my $n = parse_number_id(text => $s);
    $neg ? -$n : $n;
}

sub login {
    die "Not yet implemented";
    my ($self) = @_;
    my $s = $self->site;

    return 1 if $self->logged_in;
    die "400 Username not supplied" unless $self->username;
    die "400 Password not supplied" unless $self->password;

    $self->logger->debug('Logging in ...');
    $self->_req(get => [$s]);
    $self->_req(submit_form => [
                                form_number => 1,
                                fields => {'value(user_id)'=>$self->username,
                                           'value(pswd)'=>$self->password,
                                           },
                                button => 'value(Submit)',
                                ],
                sub {
                    my ($mech) = @_;
                    $mech->content =~ /var err='(.+?)'/ and return $1;
                    $mech->content =~ /=logout"/ and return;
                    "unknown login result page";
                }
                                );
    $self->logged_in(1);
    $self->_req(get => ["$s/authentication.do?value(actions)=welcome"]);
    #$self->_req(get => ["$s/nav_bar_indo/menu_nav.htm"]); # failed?
}

sub logout {
    die "Not yet implemented";
    my ($self) = @_;

    return 1 unless $self->logged_in;
    $self->logger->debug('Logging out ...');
    $self->_req(get => [$self->site . "/authentication.do?value(actions)=logout"]);
    $self->logged_in(0);
}

sub _menu {
    my ($self) = @_;
    my $s = $self->site;
    $self->_req(get => ["$s/nav_bar_indo/account_information_menu.htm"]);
}

sub list_cards {
    die "Not yet implemented";
    my ($self) = @_;
    $self->login;
    $self->logger->info("Listing ATM cards");
    map { $_->{account} } $self->_check_balances;
}

sub _check_balances {
    my ($self) = @_;
    my $s = $self->site;

    my $re = qr!
<tr>\s*
  <td[^>]+>\s*<div[^>]+>\s*<font[^>]+>\s*(\d+)\s*</font>\s*</div>\s*</td>\s*
  <td[^>]+>\s*<div[^>]+>\s*<font[^>]+>\s*([^<]*?)\s*</font>\s*</div>\s*</td>\s*
  <td[^>]+>\s*<div[^>]+>\s*<font[^>]+>\s*([A-Z]+)\s*</font>\s*</div>\s*</td>\s*
  <td[^>]+>\s*<div[^>]+>\s*<font[^>]+>\s*([0-9,.]+)\.(\d\d)\s*</font>\s*</div>\s*</td>
!x;

    $self->login;
    $self->_menu;
    $self->_req(post => ["$s/balanceinquiry.do"],
                sub {
                    my ($mech) = @_;
                    $mech->content =~ $re or
                        return "can't find balances, maybe page layout changed?";
                    '';
                }
    );

    my @res;
    my $content = $self->mech->content;
    while ($content =~ m/$re/og) {
        push @res, { account => $1,
                     account_type => $2,
                     currency => $3,
                     balance => $self->_stripD($4) + 0.01*$5,
                 };
    }
    @res;
}

sub check_balance {
    die "Not yet implemented";
    my ($self, $account) = @_;
    my @bals = $self->_check_balances;
    return unless @bals;
    return $bals[0]{balance} if !$account;
    for (@bals) {
        return $_->{balance} if $_->{account} eq $account;
    }
    return;
}

sub get_statement {
    die "Not yet implemented";
    my ($self, %args) = @_;
    my $s = $self->site;
    my $max_days = 31;

    $self->login;
    $self->_menu;
    $self->logger->info("Getting statement for ".
        ($args{account} ? "account `$args{account}'" : "default account")." ...");
    $self->_req(post => ["$s/accountstmt.do?value(actions)=acct_stmt"],
                sub {
                    my ($mech) = @_;
                    $mech->content =~ /<form/i or
                        return "no form found, maybe we got logged out?";
                    '';
                });

    my $form = $self->mech->form_number(1);

    # in the site this is done by javascript onSubmit(), so we emulate it here
    $form->action("$s/accountstmt.do?value(actions)=acctstmtview");

    # in the case of the current date being a saturday/sunday/holiday, end
    # date will be forwarded 1 or more days from the current date by the site,
    # so we need to know end date and optionally forward start date when needed,
    # to avoid total number of days being > 31.

    my $today = DateTime->today;
    my $max_dt = DateTime->new(day   => $form->value("value(endDt)"),
                               month => $form->value("value(endMt)"),
                               year  => $form->value("value(endYr)"));
    my $cmp = DateTime->compare($today, $max_dt);
    my $delta_days = $cmp * $today->subtract_datetime($max_dt, $today)->days;
    if ($delta_days > 0) {
        $self->logger->warn("Something weird is going on, end date is being ".
                            "set less than today's date by the site (".
                            $self->_fmtdate($max_dt)."). ".
                            "Please check your computer's date setting. ".
                            "Continuing anyway.");
    }
    my $min_dt = $max_dt->clone->subtract(days => ($max_days-1));

    my $end_dt = $args{end_date} || $max_dt;
    my $start_dt = $args{start_date} ||
        $end_dt->clone->subtract(days => (($args{days} || $max_days)-1));
    if (DateTime->compare($start_dt, $min_dt) == -1) {
        $self->logger->warn("Start date ".$self->_fmtdate($start_dt)." is less than ".
                            "minimum date ".$self->_fmtdate($min_dt).". Setting to ".
                            "minimum date instead.");
        $start_dt = $min_dt;
    }
    if (DateTime->compare($start_dt, $max_dt) == 1) {
        $self->logger->warn("Start date ".$self->_fmtdate($start_dt)." is greater than ".
                            "maximum date ".$self->_fmtdate($max_dt).". Setting to ".
                            "maximum date instead.");
        $start_dt = $max_dt;
    }
    if (DateTime->compare($end_dt, $min_dt) == -1) {
        $self->logger->warn("End date ".$self->_fmtdate($end_dt)." is less than ".
                            "minimum date ".$self->_fmtdate($min_dt).". Setting to ".
                            "minimum date instead.");
        $end_dt = $min_dt;
    }
    if (DateTime->compare($end_dt, $max_dt) == 1) {
        $self->logger->warn("End date ".$self->_fmtdate($end_dt)." is greater than ".
                            "maximum date ".$self->_fmtdate($max_dt).". Setting to ".
                            "maximum date instead.");
        $end_dt = $max_dt;
    }
    if (DateTime->compare($start_dt, $end_dt) == 1) {
        $self->logger->warn("Start date ".$self->_fmtdate($start_dt)." is greater than ".
                            "end date ".$self->_fmtdate($end_dt).". Setting to ".
                            "end date instead.");
        $start_dt = $end_dt;
    }

    my $select = $form->find_input("value(D1)");
    my $d1 = $select->value;
    if ($args{account}) {
        my @d1 = $select->possible_values;
        my @accts = $select->value_names;
        for (0..$#accts) {
            if ($args{account} eq $accts[$_]) {
                $d1 = $d1[$_];
                last;
            }
        }
    }

    $self->_req(submit_form => [
                                form_number => 1,
                                fields => {
                                    "value(D1)" => $d1,
                                    "value(startDt)" => $start_dt->day,
                                    "value(startMt)" => $start_dt->month,
                                    "value(startYr)" => $start_dt->year,
                                    "value(endDt)" => $end_dt->day,
                                    "value(endMt)" => $end_dt->month,
                                    "value(endYr)" => $end_dt->year,
                                          },
                                ],
                sub {
                    my ($mech) = @_;
                    ''; # XXX check for error
                });
    my $parse_opts = $args{parse_opts} // {};
    my $resp = $self->parse_statement($self->mech->content, %$parse_opts);
    return if !$resp || $resp->[0] != 200;
    $resp->[2];
}

sub _ps_detect {
    my ($self, $page) = @_;
    unless ($page =~ />Detail Informasi Mutasi Rekening</) {
        return "No BPR KS statement page signature found";
    }
    $self->_variant('individual');
    "";
}

sub _ps_get_metadata {
    my ($self, $page, $stmt) = @_;

    unless ($page =~ m!<label[^>]*>No\. Rekening</label></td>\s*<td[^>]*>(\d+)</td>!s) {
        return "can't get account number";
    }
    $stmt->{account} = $1;

    my $adv1 = "probably the statement format changed, or input incomplete";

    unless ($page =~ m!<label[^>]*>Periode Mutasi Rekening</label></td>\s*<td>\s*(?<d1>\d{1,2})-(?<m1>\w+)-(?<y1>\d{4})\s*s/d\s*(?<d2>\d{1,2})-(?<m2>\w+)-(?<y2>\d{4})\s*</td>!s) {
        return "can't get statement period, $adv1";
    }
    $stmt->{start_date} = DateTime->new(day=>$+{d1}, month=>$self->_parse_mon($+{m1}), year=>$+{y1});
    $stmt->{end_date}   = DateTime->new(day=>$+{d2}, month=>$self->_parse_mon($+{m2}), year=>$+{y2});

    unless ($page =~ m!<label[^>]*>Mata Uang</label></td>\s*<td[^>]*>(\w+)</td>!s) {
        return "can't get currency, $adv1";
    }
    $stmt->{currency} = ($1 eq 'Rp' ? 'IDR' : $1);

    unless ($page =~ m!<label[^>]*>Nama</label></td>\s*<td[^>]*>([^<]+?)\s*</td>!s) {
        return "can't get account holder, $adv1";
    }
    $stmt->{account_holder} = $1;

    # additional: Tipe: Tabungan

    unless ($page =~ m!<label[^>]*>Mutasi Kredit</label></td>\s*<td[^>]*>([^<]+)</td>!s) {
        return "can't get total credit, $adv1";
    }
    $stmt->{_total_credit_in_stmt}  = $self->_parse_num($1);
    # no _num_credit_tx_in_stmt, pity cause it's required for proper checking

    unless ($page =~ m!<label[^>]*>Mutasi Debet</label></td>\s*<td[^>]*>([^<]+)</td>!s) {
        return "can't get total credit, $adv1";
    }
    $stmt->{_total_debit_in_stmt}  = -$self->_parse_num($1);
    # no _num_debit_tx_in_stmt, pity cause it's required for proper checking
    "";
}

sub _ps_get_transactions {
    my ($self, $page, $stmt) = @_;

    my @e;
    while ($page =~ m!
<tr \s+ class="(?:odd|even)" \s+ id="informal_(?<seq>\d+)"[^>]*>\s*
  <td[^>]+>\s* (?<date>\d\d/\d\d/\d\d\d\d) \s*</td>\s*
  <td[^>]+>\s* (?<desc>[^<]+?) \s*</td>\s*
  <td[^>]+>\s* (?<ref>[^<]+?) \s*</td>\s*
  <td[^>]+>\s* (?<amt>[^<]+?) \s*</td>\s*
  <td[^>]+>\s* (?<bal>[^<]+?) \s*</td>\s*
</tr>!sxg) {
        my %m = %+;
        push @e, \%m;
    }

    my @tx;
    my @skipped_tx;
    my $last_date;
    my $seq;
    my $i = 0;
    for my $e (@e) {
        $i++;
        my $tx = {};
        #$tx->{stmt_start_date} = $stmt->{start_date};

        ### bca
        ###if ($e->{date} =~ /NEXT/) {
        ###    $tx->{date} = $stmt->{end_date};
        ###    $tx->{is_next} = 1;
        ###} elsif ($e->{date} =~ /PEND/) {
        ###    $tx->{date} = $stmt->{end_date};
        ###    $tx->{is_pending} = 1;
        ###} else {
        my ($day, $mon, $year) = split m!/!, $e->{date};
        my $last_nonpend_date = DateTime->new(
            year => $year,
            month => $mon,
            day => $day);
        $tx->{date} = $last_nonpend_date;
        ###$tx->{is_pending} = 0;
        ###}

        $tx->{description} = $e->{desc};

        $tx->{amount}  = $self->_parse_num($e->{amt});
        $tx->{balance} = $self->_parse_num($e->{bal});

        ### bca
        ###if ($tx->{is_next} && $self->skip_NEXT) {
        ###}

        if (!$last_date || DateTime->compare($last_date, $tx->{date})) {
            $seq = 1;
            $last_date = $tx->{date};
        } else {
            $seq++;
        }
        $tx->{seq} = $seq;

        ### bca
        ###if ($self->_variant eq 'individual' &&
        ###    $tx->{date}->dow =~ /6|7/ &&
        ###    $tx->{description} !~ /^(BIAYA ADM|BUNGA|CR KOREKSI BUNGA|PAJAK BUNGA)$/) {
        ###    return "check failed in tx#$i: In KlikBCA Perorangan, all ".
        ###        "transactions must not be in Sat/Sun except for Interest and ".
        ###        "Admin Fee";
        ###    # note: in Tahapan perorangan, BIAYA ADM is set on
        ###    # Fridays, but for Tapres (?) on last day of the month
        ###}

        ###if ($self->_variant eq 'bisnis' &&
        ###    $tx->{date}->dow =~ /6|7/ &&
        ###    $tx->{description} !~ /^(BIAYA ADM|BUNGA|CR KOREKSI BUNGA|PAJAK BUNGA)$/) {
        ###    return "check failed in tx#$i: In KlikBCA Bisnis, all ".
        ###        "transactions must not be in Sat/Sun except for Interest and ".
        ###        "Admin Fee";
        ###    # note: in KlikBCA bisnis, BIAYA ADM is set on the last day of the
        ###    # month, regardless of whether it's Sat/Sun or not
        ###}

        ###if ($tx->{is_next} && $self->skip_NEXT) {
        ###    push @skipped_tx, $tx;
        ###    $seq--;
        ###} else {
        push @tx, $tx;
        ###}
    }
    $stmt->{transactions} = \@tx;
    $stmt->{skipped_transactions} = \@skipped_tx;
    "";
}

1;
# ABSTRACT: Check your BPR KS accounts from Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Bank::ID::BPRKS - Check your BPR KS accounts from Perl

=head1 VERSION

This document describes version 0.05 of Finance::Bank::ID::BPRKS (from Perl distribution Finance-Bank-ID-BPRKS), released on 2015-12-16.

=head1 SYNOPSIS

    use Finance::Bank::ID::BPRKS;

    # FBI::BPRKS uses Log::Any. to show logs using, e.g., Log4perl:
    use Log::Log4perl qw(:easy);
    use Log::Any::Adapter;
    Log::Log4perl->easy_init($DEBUG);
    Log::Any::Adapter->set('Log4perl');

    my $ibank = Finance::Bank::ID::BPRKS->new(
        username => 'ABCDEFGH1234', # opt if only using parse_statement()
        password => '123456',       # idem
        verify_https => 1,          # default is 0
        #https_ca_dir => '/etc/ssl/certs', # default is already /etc/ssl/certs
    );

    eval {
        $ibank->login(); # dies on error

        my @cards = $ibank->list_cards();

        my $bal = $ibank->check_balance($card); # $card is optional

        my $stmt = $ibank->get_statement(
            card       => ..., # opt, default card will be used if undef
            days       => 30,  # opt
            start_date => DateTime->new(year=>2012, month=>6, day=>1),
                               # opt, takes precedence over 'days'
            end_date   => DateTime->today, # opt, takes precedence over 'days'
        );

        print "Transactions: ";
        for my $tx (@{ $stmt->{transactions} }) {
            print "$tx->{date} $tx->{amount} $tx->{description}\n";
        }
    };

    # remember to call this, otherwise you will have trouble logging in again
    # for some time
    if ($ibank->logged_in) { $ibank->logout() }

    # utility routines
    my $res = $ibank->parse_statement($html);

Also see the examples/ subdirectory in the distribution for a sample script
using this module.

=head1 DESCRIPTION

B<RELEASE NOTE: This is an early release. Only parse_statement() for a single
statement page is implemented.>

This module provide a rudimentary interface to the web-based online banking
interface of the Indonesian B<BPR Karyajatnika Sadaya> (BPR KS, BPRKS) at
https://ib.bprks.co.id. You will need either L<Crypt::SSLeay> or
L<IO::Socket::SSL> installed for HTTPS support to work (and strictly
Crypt::SSLeay to enable certificate verification). L<WWW::Mechanize> is required
but you can supply your own mech-like object.

This module can only login to the individual edition of the site. I haven't
checked out the other versions.

Warning: This module is neither offical nor is it tested to be 100% safe!
Because of the nature of web-robots, everything may break from one day to the
other when the underlying web interface changes.

=head1 WARNING

This warning is from Simon Cozens' C<Finance::Bank::LloydsTSB>, and seems just
as apt here.

This is code for B<online banking>, and that means B<your money>, and that means
B<BE CAREFUL>. You are encouraged, nay, expected, to audit the source of this
module yourself to reassure yourself that I am not doing anything untoward with
your banking data. This software is useful to me, but is provided under B<NO
GUARANTEE>, explicit or implied.

=head1 ERROR HANDLING AND DEBUGGING

Most methods die() when encountering errors, so you can use eval() to trap them.

Full response headers and bodies are dumped to a separate logger. See
documentation on C<new()> below and the sample script in examples/ subdirectory
in the distribution.

=head1 ATTRIBUTES

=head2 skip_NEXT => BOOL

If set to true, then statement with NEXT status will be skipped.

=head1 METHODS

=for Pod::Coverage BUILD

=head2 new(%args)

Create a new instance. %args keys:

=over 4

=item * username

Optional if you are just using utility methods like C<parse_statement()> and not
C<login()> etc.

=item * password

Optional if you are just using utility methods like C<parse_statement()> and not
C<login()> etc.

=item * mech

Optional. A L<WWW::Mechanize>-like object. By default this module instantiate a
new L<Finance::BankUtils::ID::Mechanize> (a WWW::Mechanize subclass) object to
retrieve web pages, but if you want to use a custom/different one, you are
allowed to do so here. Use cases include: you want to retry and increase timeout
due to slow/unreliable network connection (using
L<WWW::Mechanize::Plugin::Retry>), you want to slow things down using
L<WWW::Mechanize::Sleepy>, you want to use IE engine using
L<Win32::IE::Mechanize>, etc.

=item * verify_https

Optional. If you are using the default mech object (see previous option), you
can set this option to 1 to enable SSL certificate verification (recommended for
security). Default is 0.

SSL verification will require a CA bundle directory, default is /etc/ssl/certs.
Adjust B<https_ca_dir> option if your CA bundle is not located in that
directory.

=item * https_ca_dir

Optional. Default is /etc/ssl/certs. Used to set HTTPS_CA_DIR environment
variable for enabling certificate checking in Crypt::SSLeay. Only used if
B<verify_https> is on.

=item * logger

Optional. You can supply a L<Log::Any>-like logger object here. If not
specified, this module will use a default logger.

=item * logger_dump

Optional. You can supply a L<Log::Any>-like logger object here. This is just
like C<logger> but this module will log contents of response here instead of to
C<logger> for debugging purposes. You can configure using something like
L<Log::Dispatch::Dir> to save web pages more conveniently as separate files. If
unspecified, the default logger is used (same as C<logger>).

=back

=head2 login()

Login to the net banking site. You actually do not have to do this explicitly as
login() is called by other methods like C<check_balance()> or
C<get_statement()>.

If login is successful, C<logged_in> will be set to true and subsequent calls to
C<login()> will become a no-op until C<logout()> is called.

Dies on failure.

=head2 logout()

Logout from the net banking site. You need to call this at the end of your
program, otherwise the site will prevent you from re-logging in for some time
(e.g. 10 minutes).

If logout is successful, C<logged_in> will be set to false and subsequent calls
to C<logout()> will become a no-op until C<login()> is called.

Dies on failure.

=head2 list_accounts()

Return an array containing all account numbers that are associated with the
current net banking login.

=head2 check_balance([$account])

Return balance for specified account, or the default account if C<$account> is
not specified.

=head2 list_cards()

List ATM cards. Not yet implemented.

=head2 get_statement(%args) => $stmt

Get account statement. %args keys:

=over 4

=item * account

Optional. Select the account to get statement of. If not specified, will use the
already selected account.

=item * days

Optional. Number of days between 1 and 30. If days is 1, then start date and end
date will be the same. Default is 30.

=item * start_date

Optional. Default is end_date - days.

=item * end_date

Optional. Default is today (or some 1+ days from today if today is a
Saturday/Sunday/holiday, depending on the default value set by the site's form).

=back

See parse_statement() on structure of $stmt.

=head2 parse_statement($html, %opts) => $res

Given the HTML text of the account statement results page, parse it into
structured data:

 $stmt = {
    start_date     => $start_dt, # a DateTime object
    end_date       => $end_dt,   # a DateTime object
    account_holder => STRING,
    account        => STRING,    # account number
    currency       => STRING,    # 3-digit currency code
    transactions   => [
        # first transaction
        {
          date        => $dt,  # a DateTime obj, book date ("tanggal pembukuan")
          seq         => INT,  # a number >= 1 which marks the sequence of
                               # transactions for the day
          amount      => REAL, # a real number, positive means credit (deposit),
                               # negative means debit (withdrawal)
          description => STRING,
          #is_pending  => BOOL,
          branch      => STRING, # a 4-digit branch/ATM code
          balance     => REAL,
        },
        # second transaction
        ...
    ]
 }

$html is the HTML text. Since there can be multiple pages, $html can also be an
arrayref of HTML texts (this is not yet implemented).

Returns:

 [$status, $err_details, $stmt]

C<$status> is 200 if successful or some other 3-digit code if parsing failed.
C<$stmt> is the result (structure as above, or undef if parsing failed).

Options (%opts):

=over 4

=item * return_datetime_obj => BOOL

Default is true. If set to false, the method will return dates as strings with
this format: 'YYYY-MM-DD HH::mm::SS' (produced by DateTime->dmy . ' ' .
DateTime->hms). This is to make it easy to pass the data structure into YAML,
JSON, MySQL, etc. Nevertheless, internally DateTime objects are still used.

=back

Additional notes:

The method can also handle some copy-pasted text from the GUI browser, but this
is no longer documented or guaranteed to keep working.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Bank-ID-BPRKS>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Bank-ID-BPRKS>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-ID-BPRKS>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
