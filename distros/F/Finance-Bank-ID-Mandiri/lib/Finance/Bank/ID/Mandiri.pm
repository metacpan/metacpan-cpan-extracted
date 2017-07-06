package Finance::Bank::ID::Mandiri;

our $DATE = '2017-07-03'; # DATE
our $VERSION = '0.35'; # VERSION

use 5.010001;

use Moo;
use DateTime;

use HTTP::Headers;
use HTTP::Headers::Patch::DontUseStorable -load_target=>0;
extends 'Finance::Bank::ID::Base';

has _variant => (is => 'rw');
has _re_tx   => (is => 'rw');

my $re_acc         = qr/(?:\d{13})/;
my $re_currency    = qr/(?:\w{3})/;
my $re_money       = qr/(?:\d+(?:\.\d\d?)?)/;
my $re_moneymin    = qr/(?:-?\d+(?:\.\d\d?)?)/; # allow negative
my $re_date1       = qr!(?:\d{2}/\d{2}/\d{4})!; # 25/12/2010
my $re_txcode      = qr!(?:\d{4})!;

# original version when support first added
our $re_mcm_v201009 = qr!^(?<acc>$re_acc);(?<currency>$re_currency);
                         (?<date_d>\d\d)/(?<date_m>\d\d)/(?<date_y>\d\d\d\d)
                         (?<txcode>$re_txcode);
                         (?<desc1>[^;]+);(?<desc2>.*?);
                         (?<amount>$re_money)(?<amount_dbmarker>DR)?;
                         (?<bal>$re_money)(?<bal_dbmarker>DR)?$!mx;
# what's new: third line argument
our $re_mcm_v201103 = qr!^(?<acc>$re_acc);(?<currency>$re_currency);
                         (?<date_d>\d\d)/(?<date_m>\d\d)/(?<date_y>\d\d\d\d)
                         (?<txcode>$re_txcode);
                         (?<desc1>[^;]+);(?<desc2>[^;]*);(?:(?<desc3>.*?);)?
                         (?<amount>$re_money)(?<amount_dbmarker>DR)?;
                         (?<bal>$re_money)(?<bal_dbmarker>DR)?$!mx;
# what's new: txcode moved to 3rd column, credit & debit amount split into 2
# fields
our $re_mcm_v201107 = qr!^(?<acc>$re_acc);(?<currency>$re_currency);
                         (?<txcode>$re_txcode);
                         (?<date_d>\d\d)/(?<date_m>\d\d)/(?<date_y>\d\d\d\d);
                         (?<desc1>[^;]+);(?<desc2>[^;]*);(?:(?<desc3>.*?);)?
                         (?<amount_db>$re_money);
                         (?<amount_cr>$re_money);
                         (?<bal>$re_moneymin)!mx; # maybe? no more DR marker

sub _make_readonly_inputs_rw {
    my ($self, @forms) = @_;
    for my $f (@forms) {
        for my $i (@{ $f->{inputs} }) {
            $i->{readonly} = 0 if $i->{readonly};
        }
    }
}

sub BUILD {
    my ($self, $args) = @_;

    $self->site("https://ib.bankmandiri.co.id") unless $self->site;
    $self->https_host("ib.bankmandiri.co.id") unless $self->https_host;
}

sub login {
    my ($self) = @_;

    return 1 if $self->logged_in;
    die "400 Username not supplied" unless $self->username;
    die "400 Password not supplied" unless $self->password;

    $self->logger->debug('Logging in ...');
    $self->_req(get => [$self->site . "/retail/Login.do?action=form&lang=in_ID"],
                {
                    id => 'login_form',
                    after_request => sub {
                        my ($mech) = @_;
                        $mech->content =~ /LoginForm/ or return "no login form";
                        "";
                    },
                });
    $self->mech->set_visible(
                             $self->username,
                             $self->password,
                             [image=>"x"]);
    $self->_req(submit => [],
                {
                    id => 'login',
                    after_request => sub {
                        my ($mech) = @_;
                        $mech->content =~ m!<font class="errorMessage">(.+?)</font>! and return $1;
                        $mech->content =~ /<frame\s.+Welcome/ and return; # success
                        $mech->content =~ m!<font class="alert">(\w.+?)</font>! and return $1;
                        $mech->content =~ /LoginForm/ and
                            return "submit failed, still getting login form, probably problem with image button";
                        "unknown login result page";
                    },
                });
    $self->_req(get => [$self->site . "/retail/Welcome.do?action=result"],
                {
                    id => 'welcome',
                    after_request => sub {
                        my ($mech) = @_;
                        $mech->content !~ /SELAMAT DATANG/ and
                            return "failed getting welcome screen";
                        "";
                    },
                });
    $self->logged_in(1);
}

sub logout {
    my ($self) = @_;

    return 1 unless $self->logged_in;
    $self->logger->debug('Logging out ...');
    $self->_req(get => [$self->site . "/retail/Logout.do?action=result"],
                {id => 'logout'});
    $self->logged_in(0);
}

sub _parse_accounts {
    my ($self, $retrieve) = @_;
    $self->login;
    $self->logger->debug("Parsing accounts from transaction history form page ...");
    $self->_req(get => [$self->site . "/retail/TrxHistoryInq.do?action=form"],
            {id => 'txhist_form-parse_accounts'}) if $retrieve;
    my $ct = $self->mech->content;
    $ct =~ /(HISTORI TRANSAKSI|MUTASI REKENING)/ or
        die "failed getting transaction history form page";
    $ct =~ m!<select name="fromAccountID">(.+?)</select>!si or
        die "failed getting the list of accounts select box (fromAccountID)";
    my $opts = $1;
    my $accts = {};
    while ($opts =~ /<option value="(\d+)">(\d+)/g) {
        $accts->{$2} = $1;
    }
    $accts;
}

# if $account is not supplied, will choose the first id
sub _get_an_account_id {
    my ($self, $account, $retrieve) = @_;
    my $accts = $self->_parse_accounts($retrieve);
    for (keys %$accts) {
        if (!$account || $_ eq $account) {
            return $accts->{$_};
        }
    }
    die "cannot find any account ID";
}

sub list_accounts {
    my ($self) = @_;
    keys %{ $self->_parse_accounts(1) };
}

sub check_balance {
    my ($self, $account) = @_;
    my $s = $self->site;

    $self->login;
    my $acctid = $self->_get_an_account_id($account, 1);
    my $bal;
    $self->_req(get => ["$s/retail/AccountDetail.do?action=result&ACCOUNTID=$acctid"],
                {
                    id => "check_balance",
                    after_request => sub {
                        my ($mech) = @_;
                        $mech->content =~ m!>Informasi Saldo(?:<[^>]+>\s*)*:\s*(?:<[^>]+>\s*)*(?:Rp\.)&nbsp;([0-9.]+),(\d+)\s*<!s
                            or return "cannot grep balance in result page";
                        $bal = $self->_stripD($1)+0.01*$2;
                        "";
                    },
                });
    $bal;
}

sub get_statement {
    my ($self, %args) = @_;
    my $s = $self->site;

    $self->login;

    $self->logger->debug('Getting statement ...');
    my $mech = $self->mech;
    $self->_req(get => ["$s/retail/TrxHistoryInq.do?action=form"],
                {id=>"txhist_form-get_statement"});

    my $today = DateTime->today;
    my $end_date = $args{end_date} || $today;
    my $start_date = $args{start_date};
    if (!$start_date) {
        if (defined $args{days}) {
            $start_date = $end_date->clone->subtract(days=>($args{days}-1));
            $self->logger->debugf(
                'Setting start_date to %04d-%02d-%02d (end_date - %d days)',
                $start_date->year, $start_date->month, $start_date->day,
                $args{days});
        } else {
            $start_date = $end_date->clone->subtract(months=>1);
            $self->logger->debugf(
                'Setting start_date to %04d-%02d-%02d (end_date - 1mo)',
                $start_date->year, $start_date->month, $start_date->day);
        }
    }

    $mech->set_fields(
        fromAccountID => $self->_get_an_account_id($args{account}, 0),
        fromDay   => $start_date->day,
        fromMonth => $start_date->month,
        fromYear  => $start_date->year,
        toDay     => $end_date->day,
        toMonth   => $end_date->month,
        toYear    => $end_date->year,
    );

    # to shut up HTML::Form's read-only warning
    $self->_make_readonly_inputs_rw($mech->forms);

    $mech->set_fields(action => "result");

    $self->_req(submit => [],
                {
                    id => "get_statement",
                    after_request => sub {
                        my ($mech) = @_;
                        $mech->content =~ />Keterangan Transaksi</ and return "";
                        $mech->content =~ m!<font class="alert">(.+)</font>!
                            and return $1;
                        return "failed getting statement";
                    },
                });

    my $resp = $self->parse_statement($self->mech->content);
    return if !$resp || $resp->[0] != 200;
    $resp->[2];
}

sub _ps_detect {
    my ($self, $page) = @_;
    if ($page =~ /(?:^|"header">)(HISTORI TRANSAKSI|MUTASI REKENING)/m) {
        $self->_variant('ib');
        return '';
    } elsif ($page =~ /^CMS-Mandiri/ms) {
        $self->_variant('cms');
        return '';
    #} elsif ($page =~ /$re_mcm_v201009/) {
    #    $self->_variant('mcm-v201009');
    #    $self->_re_tx($re_mcm_v201009);
    #    return '';
    } elsif ($page =~ /$re_mcm_v201103/) {
        $self->_variant('mcm-v201103');
        $self->_re_tx($re_mcm_v201103);
        return '';
    } elsif ($page =~ /$re_mcm_v201107/) {
        $self->_variant('mcm-v201107');
        $self->_re_tx($re_mcm_v201107);
        return '';
    } else {
        return "No Mandiri statement page signature found";
    }
}

sub _ps_get_metadata {
    my ($self, @args) = @_;
    if ($self->_variant eq 'ib') {
        $self->_ps_get_metadata_ib(@args);
    } elsif ($self->_variant eq 'cms') {
        $self->_ps_get_metadata_cms(@args);
    } elsif ($self->_variant =~ /^mcm/) {
        $self->_ps_get_metadata_mcm(@args);
    } else {
        return "internal bug: _variant not yet set";
    }
}

sub _ps_get_metadata_ib {
    my ($self, $page, $stmt) = @_;

    unless ($page =~ /Tampilkan Berdasarkan(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)Tanggal(?:\s+|(?:<[^>]+>\s*)*)Urutkan Berdasarkan(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)Mulai dari yang kecil/s) {
      return "currently only support descending order ('Mulai dari yang kecil')";
    }

    my $adv1 = "maybe statement format changed or input incomplete";

    unless ($page =~ /(?:^|>)Nomor Rekening(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)(\d+) (Rp\.|[A-Z]+)/m) {
      return "can't get account number, $adv1";
    }
    $stmt->{account} = $1;
    $stmt->{currency} = ($2 eq 'Rp.' ? 'IDR' : $2);

    my $empty_stmt = $page =~ />Tidak ditemukan catatan</ ? 1:0;

    # check completeness, because the latest transactions are displayed first
    unless ($empty_stmt ||
                $page =~ /(?:|>)Saldo Akhir(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)\d/m) {
      return "statement page probably truncated in the middle, try to input the whole page";
    }

    # along with their common misspellings, these are not in DateTime::Locale
    my %shortmon_id = (Jan=>1, Feb=>2, Peb=>2, Mar=>3, Apr=>4, Mei=>5, Jun=>6,
                       Jul=>7, Agu=>8, Agt=>8, Agus=>8, Agust=>8, Sep=>9,
                       Sept=>9, Okt=>10, Nov=>11, Nop=>11, Des=>12);
    my %shortmon_en = (Jan=>1, Feb=>2, Mar=>3, Apr=>4, May=>5, Jun=>6,
                       Jul=>7, Aug=>8, Sep=>9, Oct=>10, Nov=>11, Dec=>12);
    my %shortmon = (%shortmon_id, %shortmon_en);
    my $shortmon_re = join "|", keys(%shortmon);
    $shortmon_re = qr/(?:$shortmon_re)/;

    unless ($page =~ m!(?:^|>)Periode Transaksi(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)(\d\d?) ($shortmon_re) (\d\d\d\d)\s*-\s*(\d\d?) ($shortmon_re) (\d\d\d\d)!m) {
      return "can't get period, $adv1";
    }
    return "can't parse month name: $2" unless $shortmon{$2};
    return "can't parse month name: $5" unless $shortmon{$5};
    $stmt->{start_date} = DateTime->new(day=>$1, month=>$shortmon{$2}, year=>$3);
    $stmt->{end_date}   = DateTime->new(day=>$4, month=>$shortmon{$5}, year=>$6);

    # for safety, but i forgot why
    my $today = DateTime->today;
    if (DateTime->compare($stmt->{start_date}, $today) == 1) {
        $stmt->{start_date} = $today;
    }
    if (DateTime->compare($stmt->{end_date}, $today) == 1) {
        $stmt->{end_date} = $today;
    }

    if ($empty_stmt) {
        $stmt->{_total_credit_in_stmt} = 0;
        $stmt->{_total_debit_in_stmt}  = 0;
    } else {
        unless ($page =~ /(?:^|>)Total Kredit(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)([0-9,.]+)[.,](\d\d)/m) {
            return "can't get total credit, $adv1";
        }
        $stmt->{_total_credit_in_stmt} = $self->_stripD($1) + 0.01*$2;

        unless ($page =~ /(?:^|>)Total Debet(?:\s+|(?:<[^>]+>\s*)*):(?:\s+|(?:<[^>]+>\s*)*)([0-9,.]+)[.,](\d\d)/m) {
            return "can't get total debit, $adv1";
        }
        $stmt->{_total_debit_in_stmt} = $self->_stripD($1) + 0.01*$2;
    }

    "";
}

sub _ps_get_metadata_cms {
    my ($self, $page, $stmt) = @_;

    unless ($page =~ /^- End Of Statement -/m) {
        return "statement page truncated in the middle, please input the whole page";
    }

    unless ($page =~ /^Account No\s*:\s*(\d+)/m) {
        return "can't get account number";
    }
    $stmt->{account} = $1;

    unless ($page =~ /^Account Name\s*:\s*(.+?)[\012\015]/m) {
        return "can't get account holder";
    }
    $stmt->{account_holder} = $1;

    unless ($page =~ /^Currency\s*:\s*([A-Z]+)/m) {
        return "can't get account holder";
    }
    $stmt->{currency} = $1;

    my $adv1 = "maybe statement format changed, or input incomplete";

    unless ($page =~ m!Period\s*:\s*(\d\d?)/(\d\d?)/(\d\d\d\d)\s*-\s*(\d\d?)/(\d\d?)/(\d\d\d\d)!m) {
        return "can't get statement period, $adv1";
    }
    $stmt->{start_date} = DateTime->new(day=>$1, month=>$2, year=>$3);
    $stmt->{end_date}   = DateTime->new(day=>$4, month=>$5, year=>$6);

    # for safety, but i forgot why
    my $today = DateTime->today;
    if (DateTime->compare($stmt->{start_date}, $today) == 1) {
        $stmt->{start_date} = $today;
    }
    if (DateTime->compare($stmt->{end_date}, $today) == 1) {
        $stmt->{end_date} = $today;
    }

    # Mandiri sucks, doesn't provide total credit/debit in statement
    my $n = 0;
    while ($page =~ m!^\d\d?/\d\d?\s!mg) { $n++ }
    $stmt->{_num_tx_in_stmt} = $n;
    "";
}

sub _ps_get_metadata_mcm {
    my ($self, $page, $stmt) = @_;

    my $re_tx = $self->_re_tx;

    $page =~ m!$re_tx!
        or return "can't get account number & currency & date";
    $stmt->{account} = $+{acc};
    $stmt->{currency} = $+{currency};
    $stmt->{start_date} = DateTime->new(
        day=>$+{date_d}, month=>$+{date_m}, year=>$+{date_y});

    # we'll just assume the first and last transaction date to be start and
    # end date of statement, because the semicolon format doesn't include
    # any other metadata.
    $page =~ m!.*$re_tx!s or return "can't get end date";
    $stmt->{end_date} = DateTime->new(
        day=>$+{date_d}, month=>$+{date_m}, year=>$+{date_y});

    # Mandiri sucks, doesn't provide total credit/debit in statement
    my $n = 0;
    while ($page =~ m!^\d{13};!mg) { $n++ }
    $stmt->{_num_tx_in_stmt} = $n;
    "";
}

sub _ps_get_transactions {
    my ($self, @args) = @_;
    if ($self->_variant eq 'ib') {
        $self->_ps_get_transactions_ib(@args);
    } elsif ($self->_variant eq 'cms') {
        $self->_ps_get_transactions_cms(@args);
    } elsif ($self->_variant =~ /^mcm/) {
        $self->_ps_get_transactions_mcm(@args);
    } else {
        return "internal bug: _variant not yet set";
    }
}

sub _ps_get_transactions_ib {
    my ($self, $page, $stmt) = @_;

    my @tx;
    my @skipped_tx;

    goto DONE if $page =~ m!>Tidak ditemukan catatan<!;

    my @e;
    # text version
    while ($page =~ m!^(\d\d)/(\d\d)/(\d\d\d\d)\s*\t\s*((?:[^\t]|\n)*?)\s*\t\s*([0-9.]+),(\d\d)\s*\t\s*([0-9.]+),(\d\d)!mg) {
        push @e, {day=>$1, mon=>$2, year=>$3, desc=>$4, db=>$5, dbf=>$6, cr=>$7, crf=>$8};
    }
    if (!@e) {
        # HTML version
        while ($page =~ m!^\s+<tr[^>]*>\s*
<td[^>]+> (\d\d)/(\d\d)/(\d\d\d\d) \s* </td>\s*
<td[^>]+> ((?:[^\t]|\n)*?)     </td>\s*
<td[^>]+> ([0-9.]+),(\d\d)     </td>\s*
<td[^>]+> ([0-9.]+),(\d\d)     </td>\s*
</tr>!smxg) {
          push @e, {day=>$1, mon=>$2, year=>$3, desc=>$4, db=>$5, dbf=>$6, cr=>$7, crf=>$8};
        }
        for (@e) { $_->{desc} =~ s!<br ?/?>!\n!ig }
    }

    # when they say "kecil ke besar" they actually mean showing the latest transactions first
    @e = reverse @e;

    my $seq;
    my $i = 0;
    my $last_date;
    for my $e (@e) {
        $i++;
        my $tx = {};
        $tx->{date} = DateTime->new(day=>$e->{day}, month=>$e->{mon}, year=>$e->{year});
        $tx->{description} = $e->{desc};
        my $db = $self->_stripD($e->{db}) + 0.01*$e->{dbf};
        my $cr = $self->_stripD($e->{cr}) + 0.01*$e->{crf};
        if ($db == 0) { $tx->{amount} = $cr }
        elsif ($cr == 0) { $tx->{amount} = -$db }
        else { return "check failed in tx#$i: debit and credit both exist" }

        if (!$last_date || DateTime->compare($last_date, $tx->{date})) {
            $seq = 1;
            $last_date = $tx->{date};
        } else {
            $seq++;
        }
        $tx->{seq} = $seq;

        # skip reversal pair (tx + tx') because tx' is just a correction
        # reversal and the pair will be removed anyway by Mandiri in the next
        # day's statement. currently can only handle pair in the same day and in
        # succession.
        if ($seq > 1 && $tx->{description} =~ /^Reversal \(Error Correction\)/ &&
            $tx->{amount} == -$tx[-1]{amount}) {
            push @skipped_tx, pop(@tx);
            push @skipped_tx, $tx;
            $seq -= 2;
        } else {
            push @tx, $tx;
        }
    }

  DONE:
    $stmt->{transactions} = \@tx;
    $stmt->{skipped_transactions} = \@skipped_tx;
    "";
}

sub _ps_get_transactions_cms {
    my ($self, $page, $stmt) = @_;

    if ($page =~ /<br|<p/i) {
        return "sorry, HTML version is not yet supported";
    }

    my @e;
    # text version
    while ($page =~ m!^(\d\d?)/(\d\d?)\s+(\d\d?)/(\d\d?)\s+(.*?)\t(.*)\s+([0-9.]+),(\d\d) ([CD])\s+([0-9.]+),(\d\d) ([CD])!mg) {
        # date (=tgl transaksi), value date (=tgl pembukuan?), description ("Setor Tunai"), description 2 ("DARI Andi Budi"), amount, balance
        push @e, {daytx=>$1, montx=>$2, daybk=>$3, monbk=>$4, desc1=>$5, desc2=>$6,
                  amt=>$7, amtf=>$8, amtc=>$9, bal=>$10, balf=>11, balc=>12};
    }

    my @tx;
    my $seq;
    my $last_date;
    for my $e (@e) {
        my $tx = {};
        $tx->{tx_date} = DateTime->new(
            day   => $e->{daytx},
            month => $e->{montx},
            year  => (($e->{montx} <  $stmt->{start_date}->mon ||
                       $e->{montx} == $stmt->{start_date}->mon && $e->{daytx} == $stmt->{start_date}->day) ?
                      $stmt->{end_date}->year : $stmt->{start_date}->year)
        );
        $tx->{book_date} = DateTime->new(
            day   => $e->{daybk},
            month => $e->{monbk},
            year  => (($e->{monbk} <  $stmt->{start_date}->mon ||
                       $e->{monbk} == $stmt->{start_date}->mon && $e->{daybk} == $stmt->{start_date}->day) ?
                      $stmt->{end_date}->year : $stmt->{start_date}->year)
        );
        $tx->{date} = $tx->{book_date};

        $tx->{amount}  = ($e->{amtc} eq 'C' ? 1:-1) * $self->_stripD($e->{amt}) + 0.01 * $e->{amtf};
        $tx->{balance} = ($e->{balc} eq 'C' ? 1:-1) * $self->_stripD($e->{bal}) + 0.01 * $e->{balf};
        $tx->{description} = $e->{desc1} . "\n" . $e->{desc2};

        if (!$last_date || DateTime->compare($last_date, $tx->{date})) {
            $seq = 1;
            $last_date = $tx->{date};
        } else {
            $seq++;
        }
        $tx->{seq} = $seq;

        push @tx, $tx;
    }
    $stmt->{transactions} = \@tx;
    "";
}

sub _ps_get_transactions_mcm {
    my ($self, $page, $stmt) = @_;

    my $re_tx = $self->_re_tx;

    my @rows;
    my $i = 0;
    for (split /\r?\n/, $page) {
        $i++;
        next unless /\S/;
        m!$re_tx! or die "Invalid data in line $i: '$_' doesn't match pattern".
            " (variant = ".$self->_variant.")";
        my $row = {
            account   => $+{acc},
            currency  => $+{currency},
            txcode    => $+{txcode},
            day       => $+{date_d},
            month     => $+{date_m},
            year      => $+{date_y},
            desc1     => $+{desc1},
            desc2     => $+{desc2},
        };
        $row->{desc3}   = $+{desc3} if defined($+{desc3});
        if ($+{amount_cr}) {
            my $cr = $+{amount_cr}+0;
            my $dr = $+{amount_db}+0;
            $row->{amount} = $cr ? $cr : -$dr;
        } else {
            $row->{amount} = $+{amount} * ($+{amount_dbmarker} ? -1 : 1);
        }
        $row->{balance} = $+{bal} * ($+{bal_dbmarker} ? -1 : 1);
        push @rows, $row;
    }

    my @tx;
    my $seq;
    my $last_date;
    for my $row (@rows) {
        my $tx = {};

        $row->{account} eq $stmt->{account} or
            return "Can't handle multiple accounts in transactions yet";
        $row->{currency} eq $stmt->{currency} or
            return "Can't handle multiple currencies in transactions yet";

        $tx->{date} = DateTime->new(
            day=>$row->{day}, month=>$row->{month}, year=>$row->{year});

        $tx->{txcode} = $row->{txcode};

        $tx->{description} = $row->{desc1} .
            ($row->{desc2} ? "\n" . $row->{desc2} : "") .
                ($row->{desc3} ? "\n" . $row->{desc3} : "");

        $tx->{amount}  = $row->{amount}+0;

        if (!$last_date || DateTime->compare($last_date, $tx->{date})) {
            $seq = 1;
            $last_date = $tx->{date};
        } else {
            $seq++;
        }
        $tx->{seq} = $seq;

        push @tx, $tx;
    }
    $stmt->{transactions} = \@tx;
    "";
}

1;
# ABSTRACT: Check your Bank Mandiri accounts from Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Finance::Bank::ID::Mandiri - Check your Bank Mandiri accounts from Perl

=head1 VERSION

This document describes version 0.35 of Finance::Bank::ID::Mandiri (from Perl distribution Finance-Bank-ID-Mandiri), released on 2017-07-03.

=head1 SYNOPSIS

If you just want to download banking statements, and you use Linux/Unix, you
might want to use the L<download-mandiri> script instead of having to deal with
this library directly.

If you want to use the library in your Perl application:

    use Finance::Bank::ID::Mandiri;

    # FBI::Mandiri uses Log::ger. to show logs, use something like:
    use Log::ger::Output 'Screen';

    my $ibank = Finance::Bank::ID::Mandiri->new(
        username => '....', # optional if you're only using parse_statement()
        password => '....', # idem
        verify_https => 1,          # default is 0
        #https_ca_dir => '/etc/ssl/certs', # default is already /etc/ssl/certs
    );

    eval {
        $ibank->login(); # dies on error

        my $accts = $ibank->list_accounts();

        my $bal = $ibank->check_balance($acct); # $acct is optional

        my $stmt = $ibank->get_statement(
            account    => ..., # opt, default account used if not undef
            days       => 30,  # opt
            start_date => DateTime->new(year=>2009, month=>10, day=>6),
                               # opt, takes precedence over 'days'
            end_date   => DateTime->today, # opt, takes precedence over 'days'
        );

        print "Transactions: ";
        for my $tx (@{ $stmt->{transactions} }) {
            print "$tx->{date} $tx->{amount} $tx->{description}\n";
        }
    };
    warn if $@;

    # remember to call this, otherwise you will have trouble logging in again
    # for some time
    $ibank->logout;

Utility routines:

    # parse HTML statement directly
    my $res = $ibank->parse_statement($html);

=head1 DESCRIPTION

This module provide a rudimentary interface to the web-based online banking
interface of the Indonesian B<Bank Mandiri> at https://ib.bankmandiri.co.id
(henceforth IB). You will need either L<Crypt::SSLeay> or L<IO::Socket::SSL>
installed for HTTPS support to work (and strictly L<Crypt::SSLeay> to enable
certificate verification). L<WWW::Mechanize> is required but you can supply your
own mech-like object.

Aside from the above site for invididual accounts, there are also 2 other sites
for corporate accounts: https://cms.bankmandiri.co.id/ecbanking/ (henceforth
CMS) and https://mcm.bankmandiri.co.id/ (henceforth MCM). CMS is the older
version and as of the end of Sept, 2010 has been discontinued.

This module currently can only login to IB and not CMS/MCM, but this module can
parse statement page from all 3 sites. For CMS version, only text version [copy
paste result] is currently supported and not HTML. For MCM, only semicolon
format is currently supported.

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

=head1 METHODS

=head2 new(%args)

Create a new instance. %args keys:

=over

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

Optional. You can supply a L<Log::Any>-like object here. If not specified,
this module will use a default logger.

=item * logger_dump

Optional. You can supply a L<Log::Any>-like object here. This is just
like C<logger> but this module will log contents of response bodies
here for debugging purposes. You can use with something like
L<Log::Dispatch::Dir> to save web pages more conveniently as separate
files.

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

=head2 check_balance([$acct])

=head2 get_statement(%args) => $stmt

Get account statement. %args keys:

=over

=item * account

Optional. Select the account to get statement of. If not specified, will use the
already selected account.

=item * days

Optional. Number of days. If days is 1, then start date and end date will be the
same.

=item * start_date

Optional. Default is C<end_date> - 1 month, which seems to be the current limit
set by the bank (for example, if C<end_date> is 2013-03-08, then C<start_date>
will be set to 2013-02-08). If not set and C<days> is set, will be set to
C<end_date> - C<days>.

=item * end_date

Optional. Default is today (or some 1+ days from today if today is a
Saturday/Sunday/holiday, depending on the default value set by the site's form).

=back

=head2 parse_statement($html, %opts) => $res

Given the HTML of the account statement results page, parse it into structured
data:

 $stmt = {
    start_date     => $start_dt, # a DateTime object
    end_date       => $end_dt,   # a DateTime object
    account_holder => STRING,
    account        => STRING,    # account number
    currency       => STRING,    # 3-digit currency code
    transactions   => [
        # first transaction
        {
          date        => $dt, # a DateTime object, book date ("tanggal pembukuan")
          seq         => INT, # a number >= 1 which marks the sequence of transactions for the day
          amount      => REAL, # a real number, positive means credit (deposit), negative means debit (withdrawal)
          description => STRING,
          branch      => STRING, # 4-digit branch/ATM code, only for MCM
        },
        # second transaction
        ...
    ]
 }

Returns:

 [$status, $err_details, $stmt]

C<$status> is 200 if successful or some other 3-letter code if parsing failed.
C<$stmt> is the result (structure as above, or undef if parsing failed).

Options:

=over 4

=item * return_datetime_obj => BOOL

Default is true. If set to false, the method will return dates as strings with
this format: 'YYYY-MM-DD HH::mm::SS' (produced by DateTime->dmy . ' ' .
DateTime->hms). This is to make it easy to pass the data structure into YAML,
JSON, MySQL, etc. Nevertheless, internally DateTime objects are still used.

=back

Additional notes:

The method can also (or used to) handle copy-pasted text from the GUI browser,
but this is no longer documented or guaranteed to keep working.

=head1 FAQ

=head2 (2014) I'm getting error message: "Can't connect to ib.bankmandiri.co.id:443 at ..."

Try upgrading your IO::Socket::SSL. It stalls with IO::Socket::SSL version 1.76,
but works with newer versions (e.g. 1.989).

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Finance-Bank-ID-Mandiri>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Finance-Bank-ID-Mandiri>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-ID-Mandiri>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2016, 2015, 2014, 2013, 2012, 2011, 2010 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
