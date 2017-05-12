package Ledger::Parser;

our $DATE = '2016-01-12'; # DATE
our $VERSION = '0.05'; # VERSION

use 5.010001;
use strict;
use utf8;
use warnings;
use Carp;

use Math::BigFloat;
use Time::Moment;

use constant +{
    COL_TYPE => 0,

    COL_B_RAW => 1,

    COL_T_DATE    => 1,
    COL_T_EDATE   => 2,
    COL_T_WS1     => 3,
    COL_T_STATE   => 4,
    COL_T_WS2     => 5,
    COL_T_CODE    => 6,
    COL_T_WS3     => 7,
    COL_T_DESC    => 8,
    COL_T_WS4     => 9,
    COL_T_COMMENT => 10,
    COL_T_NL      => 11,
    COL_T_PARSE_DATE  => 12,
    COL_T_PARSE_EDATE => 13,
    COL_T_PARSE_TX    => 14,

    COL_P_WS1     => 1,
    COL_P_OPAREN  => 2,
    COL_P_ACCOUNT => 3,
    COL_P_CPAREN  => 4,
    COL_P_WS2     => 5,
    COL_P_AMOUNT  => 6,
    COL_P_WS3     => 7,
    COL_P_COMMENT => 8,
    COL_P_NL      => 9,
    COL_P_PARSE_AMOUNT  => 10,

    COL_C_CHAR    => 1,
    COL_C_COMMENT => 2,
    COL_C_NL      => 3,

    COL_TC_WS1     => 1,
    COL_TC_COMMENT => 2,
    COL_TC_NL      => 3,
};

# note: $RE_xxx is capturing, $re_xxx is non-capturing
our $re_date = qr!(?:\d{4}[/-])?\d{1,2}[/-]\d{1,2}!;
our $RE_date = qr!(?:(\d{4})[/-])?(\d{1,2})[/-](\d{1,2})!;

our $re_account_part = qr/(?:
                              [^\s:\[\(;]+?[ \t]??[^\s:\[\(;]*?
                          )+?/x; # don't allow double whitespace
our $re_account = qr/$re_account_part(?::$re_account_part)*/;
our $re_commodity = qr/[A-Z_]+[A-Za-z_]*|[\$£€¥]/;
our $re_amount = qr/(?:-?)
                    (?:$re_commodity)?
                    \s* (?:-?[0-9,]+\.?[0-9]*)
                    \s* (?:$re_commodity)?
                   /x;
our $RE_amount = qr/(-?)
                    ($re_commodity)?
                    (\s*) (-?[0-9,]+\.?[0-9]*)
                    (\s*) ($re_commodity)?
                   /x;

sub new {
    my ($class, %attrs) = @_;

    $attrs{input_date_format} //= 'YYYY/MM/DD';
    $attrs{year} //= (localtime)[5] + 1900;
    #$attrs{strict} //= 0; # check valid account names

    # checking
    $attrs{input_date_format} =~ m!\A(YYYY/MM/DD|YYYY/DD/MM)\z!
        or croak "Invalid input_date_format: choose YYYY/MM/DD or YYYY/DD/MM";

    bless \%attrs, $class;
}

sub _parse_date {
    my ($self, $str) = @_;
    return [400,"Invalid date syntax '$str'"] unless $str =~ /\A(?:$RE_date)\z/;

    my $tm;
    eval {
        if ($self->{input_date_format} eq 'YYYY/MM/DD') {
            $tm = Time::Moment->new(
                day => $3,
                month => $2,
                year => $1 || $self->{year},
            );
        } else {
            $tm = Time::Moment->new(
                day => $2,
                month => $3,
                year => $1 || $self->{year},
            );
        }
    };
    if ($@) { return [400, "Invalid date '$str': $@"] }
    [200, "OK", $tm];
}

sub _parse_amount {
    my ($self, $str) = @_;
    return [400, "Invalid amount syntax '$str'"]
        unless $str =~ /\A(?:$RE_amount)\z/;

    my ($minsign, $commodity1, $ws1, $num, $ws2, $commodity2) =
        ($1, $2, $3, $4, $5, $6);
    if ($commodity1 && $commodity2) {
        return [400, "Invalid amount '$str' (double commodity)"];
    }
    $num =~ s/,//g;
    $num *= -1 if $minsign;
    return [200, "OK", [
        Math::BigFloat->new($num), # number
        ($commodity1 || $commodity2) // '', # commodity
        $commodity1 ? "B$ws1" : "A$ws2", # format: B(efore)|A(fter) + spaces
    ]];
}

# this routine takes the raw parsed lines and parse a transaction data from it.
# the _ledger_raw keys are used when we transport the transaction data outside
# and back in again, we want to be able to reconstruct the original
# transaction/posting lines if they are not modified exactly (for round-trip
# purposes).
sub _parse_tx {
    my ($self, $parsed, $linum0) = @_;

    my $t_line = $parsed->[$linum0-1];
    my $tx = {
        date        => $t_line->[COL_T_PARSE_DATE],
        description => $t_line->[COL_T_DESC],
        _ledger_raw => $t_line,
        postings    => [],
    };
    $tx->{edate} = $t_line->[COL_T_PARSE_EDATE] if $t_line->[COL_T_EDATE];

    my $linum = $linum0;
    while (1) {
        last if $linum++ > @$parsed-1;
        my $line = $parsed->[$linum-1];
        my $type = $line->[COL_TYPE];
        if ($type eq 'P') {
            my $oparen = $line->[COL_P_OPAREN] // '';
            push @{ $tx->{postings} }, {
                account => $line->[COL_P_ACCOUNT],
                is_virtual => $oparen eq '(' ? 1 : $oparen eq '[' ? 2 : 0,
                amount => $line->[COL_P_PARSE_AMOUNT] ?
                    $line->[COL_P_PARSE_AMOUNT][0] : undef,
                commodity => $line->[COL_P_PARSE_AMOUNT] ?
                    $line->[COL_P_PARSE_AMOUNT][1] : undef,
                _ledger_raw => $line,
            };
        } elsif ($type eq 'TC') {
            # ledger associates a transaction comment with a posting that
            # precedes it. if there is a transaction comment before any posting,
            # we will stick it to the _ledger_raw_comments. otherwise, it will
            # goes to each posting's _ledger_raw_comments.
            if (@{ $tx->{postings} }) {
                push @{ $tx->{postings}[-1]{_ledger_raw_comments} }, $line;
            } else {
                push @{ $tx->{_ledger_raw_comments} }, $line;
            }
        } else {
            last;
        }
    }

    # some sanity checks for the transaction
  CHECK:
    {
        my $num_postings = @{$tx->{postings}};
        last CHECK if !$num_postings;
        if ($num_postings == 1 && !defined(!$tx->{postings}[0]{amount})) {
            #$self->_err("Posting amount cannot be null");
            # ledger allows this
            last CHECK;
        }
        my $num_nulls = 0;
        my %bals; # key = commodity
        for my $p (@{ $tx->{postings} }) {
            if (!defined($p->{amount})) {
                $num_nulls++;
                next;
            }
            $bals{$p->{commodity}} += $p->{amount};
        }
        last CHECK if $num_nulls == 1;
        if ($num_nulls) {
            $self->_err("There can only be one posting with null amount");
        }
        for (keys %bals) {
            $self->_err("Transaction not balanced, " .
                            (-$bals{$_}) . ($_ ? " $_":"")." needed")
                if $bals{$_} != 0;
        }
    }

    [200, "OK", $tx];
}

sub _err {
    my ($self, $msg) = @_;
    croak join(
        "",
        @{ $self->{_include_stack} } ? "$self->{_include_stack}[0] " : "",
        "line $self->{_linum}: ",
        $msg
    );
}

sub _push_include_stack {
    require Cwd;

    my ($self, $path) = @_;

    # included file's path is based on the main (topmost) file
    if (@{ $self->{_include_stack} }) {
        require File::Spec;
        my (undef, $dir, $file) =
            File::Spec->splitpath($self->{_include_stack}[-1]);
        $path = File::Spec->rel2abs($path, $dir);
    }

    my $abs_path = Cwd::abs_path($path) or return [400, "Invalid path name"];
    return [409, "Recursive", $abs_path]
        if grep { $_ eq $abs_path } @{ $self->{_include_stack} };
    push @{ $self->{_include_stack} }, $abs_path;
    return [200, "OK", $abs_path];
}

sub _pop_include_stack {
    my $self = shift;

    die "BUG: Overpopped _pop_include_stack" unless @{$self->{_include_stack}};
    pop @{ $self->{_include_stack} };
}

sub _init_read {
    my $self = shift;

    $self->{_include_stack} = [];
}

sub _read_file {
    my ($self, $filename) = @_;
    open my $fh, "<", $filename
        or die "Can't open file '$filename': $!";
    binmode($fh, ":utf8");
    local $/;
    return ~~<$fh>;
}

sub read_file {
    my ($self, $filename) = @_;
    $self->_init_read;
    my $res = $self->_push_include_stack($filename);
    die "Can't read '$filename': $res->[1]" unless $res->[0] == 200;
    $res =
        $self->_read_string($self->_read_file($filename));
    $self->_pop_include_stack;
    $res;
}

sub read_string {
    my ($self, $str) = @_;
    $self->_init_read;
    $self->_read_string($str);
}

sub _read_string {
    my ($self, $str) = @_;

    my $res = [];

    my $in_tx;

    my @lines = split /^/, $str;
    local $self->{_linum} = 0;
  LINE:
    for my $line (@lines) {
        $self->{_linum}++;

        # transaction is broken by an empty/all-whitespace line or a
        # non-indented line. once we found a complete transaction, parse it.
        if ($in_tx && ($line !~ /\S/ || $line =~ /^\S/)) {
            my $parse_tx = $self->_parse_tx($res, $in_tx);
            if ($parse_tx->[0] != 200) {
                $self->_err($parse_tx->[1]);
            }
            $res->[$in_tx - 1][COL_T_PARSE_TX] = $parse_tx->[2];
            $in_tx = 0;
        }

        # blank line (B)
        if ($line !~ /\S/) {
            push @$res, [
                'B',
                $line, # COL_B_RAW
            ];
            next LINE;
        }

        # transaction line (T)
        if ($line =~ /^\d/) {
            $line =~ m<^($re_date)                     # 1) actual date
                       (?: = ($re_date))?              # 2) effective date
                       (?: (\s+) ([!*]) )?             # 3) ws1 4) state
                       (?: (\s+) \(([^\)]+)\) )?       # 5) ws2 6) code
                       (\s+) (\S.*?)                   # 7) ws3 8) desc
                       (?: (\s{2,}) ;(\S.+?) )?        # 9) ws4 10) comment
                       (\R?)\z                         # 11) nl
                      >x
                          or $self->_err("Invalid transaction line syntax");
            my $parsed_line = ['T', $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11];

            my $parse_date = $self->_parse_date($1);
            if ($parse_date->[0] != 200) {
                $self->_err($parse_date->[1]);
            }
            $parsed_line->[COL_T_PARSE_DATE] = $parse_date->[2];

            if ($2) {
                my $parse_edate = $self->_parse_date($2);
                if ($parse_edate->[0] != 200) {
                    $self->_err($parse_edate->[1]);
                }
                $parsed_line->[COL_T_PARSE_EDATE] = $parse_edate->[2];
            }

            $in_tx = $self->{_linum};
            push @$res, $parsed_line;
            next LINE;
        }

        # comment line (C)
        if ($line =~ /^([;#%|*])(.*?)(\R?)\z/) {
            push @$res, ['C', $1, $2, $3];
            next LINE;
        }

        # transaction comment (TC)
        if ($in_tx && $line =~ /^(\s+);(.*?)(\R?)\z/) {
            push @$res, ['TC', $1, $2, $3];
            next LINE;
        }

        # posting (P)
        if ($in_tx && $line =~ /^\s/) {
            $line =~ m!^(\s+)                       # 1) ws1
                       (\[|\()?                     # 2) oparen
                       ($re_account)                # 3) account
                       (\]|\))?                     # 4) cparen
                       (?: (\s{2,})($re_amount) )?  # 5) ws2 6) amount
                       (?: (\s*) ;(.*?))?           # 7) ws3 8) comment
                       (\R?)\z                      # 9) nl
                      !x
                          or $self->_err("Invalid posting line syntax");
            # brace must match
            my ($oparen, $cparen) = ($2 // '', $4 // '');
            unless (!$oparen && !$cparen ||
                        $oparen eq '[' && $cparen eq ']' ||
                            $oparen eq '(' && $cparen eq ')') {
                $self->_err("Parentheses/braces around account don't match");
            }
            my $parsed_line = ['P', $1, $oparen, $3, $cparen,
                               $5, $6, $7, $8, $9];
            if (defined $6) {
                my $parse_amount = $self->_parse_amount($6);
                if ($parse_amount->[0] != 200) {
                    $self->_err($parse_amount->[1]);
                }
                $parsed_line->[COL_P_PARSE_AMOUNT] = $parse_amount->[2];
            }
            push @$res, $parsed_line;
            next LINE;
        }

        $self->_err("Invalid syntax");

    }

    if ($in_tx) {
        my $parse_tx = $self->_parse_tx($res, $in_tx);
        if ($parse_tx->[0] != 200) {
            $self->_err($parse_tx->[1]);
        }
        $res->[$in_tx - 1][COL_T_PARSE_TX] = $parse_tx->[2];
    }

    require Ledger::Journal;
    Ledger::Journal->new(_parser=>$self, _parsed=>$res);
}

sub _parsed_as_string {
    no warnings 'uninitialized';

    my ($self, $parsed) = @_;

    my @res;
    my $linum = 0;
    for my $line (@$parsed) {
        $linum++;
        my $type = $line->[COL_TYPE];
        if ($type eq 'B') {
            push @res, $line->[COL_B_RAW];
        } elsif ($type eq 'T') {
            push @res, join(
                "",
                $line->[COL_T_DATE],
                (length($line->[COL_T_EDATE]) ? "=".$line->[COL_T_EDATE] : ""),
                $line->[COL_T_WS1], $line->[COL_T_STATE],
                (length($line->[COL_T_CODE]) ? $line->[COL_T_WS2]."(".$line->[COL_T_CODE].")" : ""),
                $line->[COL_T_WS3], $line->[COL_T_DESC],
                (length($line->[COL_T_COMMENT]) ? $line->[COL_T_WS4]."(".$line->[COL_T_COMMENT].")" : ""),
                $line->[COL_T_NL],
            );
        } elsif ($type eq 'C') {
            push @res, join("", @{$line}[COL_C_CHAR .. COL_C_NL]);
        } elsif ($type eq 'TC') {
            push @res, join(
                "",
                $line->[COL_TC_WS1], ";",
                $line->[COL_TC_COMMENT],
                $line->[COL_TC_NL],
            );
        } elsif ($type eq 'P') {
            push @res, join(
                "",
                $line->[COL_P_WS1],
                $line->[COL_P_OPAREN],
                $line->[COL_P_ACCOUNT],
                $line->[COL_P_CPAREN],
                (length($line->[COL_P_AMOUNT]) ? $line->[COL_P_WS2].$line->[COL_P_AMOUNT] : ""),
                (length($line->[COL_P_COMMENT]) ? $line->[COL_P_WS3].";".$line->[COL_P_COMMENT] : ""),
                $line->[COL_P_NL],
            );
        } else {
            die "Bad parsed data (line #$linum): unknown type '$type'";
        }
    }
    join("", @res);
}

1;
# ABSTRACT: Parse Ledger journals

__END__

=pod

=encoding UTF-8

=head1 NAME

Ledger::Parser - Parse Ledger journals

=head1 VERSION

This document describes version 0.05 of Ledger::Parser (from Perl distribution Ledger-Parser), released on 2016-01-12.

=head1 SYNOPSIS

 use Ledger::Parser;
 my $ledgerp = Ledger::Parser->new(
     # year              => undef,        # default: current year
     # input_date_format => 'YYYY/MM/DD', # or 'YYYY/DD/MM',
 );

 # parse a file
 my $journal = $ledgerp->read_file("$ENV{HOME}/money.dat");

 # parse a string
 $journal = $ledgerp->read_string(<<EOF);
 ; -*- Mode: ledger -*-
 09/06 dinner
 Expenses:Food          $10.00
 Expenses:Tips         5000.00 IDR ; 5% tip
 Assets:Cash:Wallet

 2013/09/07 opening balances
 Assets:Mutual Funds:Mandiri  10,305.1234 MFEQUITY_MANDIRI_IAS
 Equity:Opening Balances

 P 2013/08/01 MFEQUITY_MANDIRI_IAS 1,453.8500 IDR
 P 2013/08/31 MFEQUITY_MANDIRI_IAS 1,514.1800 IDR
 EOF

See L<Ledger::Journal> for available methods for the journal object.

=head1 DESCRIPTION

This module parses Ledger journal into L<Ledger::Journal> object. See
http://ledger-cli.org/ for more on Ledger, the command-line double-entry
accounting system software.

Ledger 3 can be extended with Python, and this module only supports a subset of
Ledger syntax, so you might also want to take a look into the Python extension.
However, this module can also modify/write the journal, so it can be used e.g.
to insert transactions programmatically (which is my use case and the reason I
first created this module).

This is an inexhaustive list of things that are not currently supported:

=over

=item * Costs & prices

For example, things like:

 2012-04-10 My Broker
    Assets:Brokerage            10 AAPL @ $50.00
    Assets:Brokerage:Cash

=item * Automated transaction

=item * Periodic transaction

=item * Expression

=item * Various commands

Including but not limited to: assert, C (currency conversion), ...

=back

=head1 ATTRIBUTES

=head2 input_date_format => str ('YYYY/MM/DD' or 'YYYY/DD/MM')

Ledger accepts dates in the form of yearless (e.g. 01/02, 3-12) or with 4-digit
year (e.g. 2015/01/02, 2015-3-12). Month and day can be single- or
double-digits. Separator is either C<-> or C</>.

When year is omitted, year will be retrieved from the C<year> attribute.

The default format is month before day (C<YYYY/MM/DD>), but you can also use day
before month (C<YYYY/DD/MM>).

=head2 year => int (default: current year)

Only used when encountering a date without year.

=head2

=head1 METHODS

=head2 new(%attrs) => obj

Create a new parser instance.

=head2 $ledgerp->read_file($filename) => obj

=head2 $ledgerp->read_string($str) => obj

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Ledger-Parser>.

=head1 SOURCE

Source repository is at L<https://github.com/sharyanto/perl-Ledger-Parser>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Ledger-Parser>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
