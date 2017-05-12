package Finance::Bank::SK::SLSP::Notification::Transaction;

use warnings;
use strict;
use utf8;

our $VERSION = '0.02';

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors(qw{
    original_text
}, ordered_attributes());

sub new {
    my ($class, %params) = @_;
    my $self  = $class->SUPER::new({ %params });
    return $self;
}

sub from_txt {
    my ($class, $txt) = @_;

    my ($transactions, $our_account1, $our_account2, @rest) =
        split(/_{10,}/, $txt);
    die 'failed parsing 1' unless $transactions || $our_account1 || $our_account2;
    my $our_account = $our_account1.$our_account2;
    die 'failed parsing 2' unless @rest == 1 || $rest[0] eq '';

    my @transactions;
    { # get transactions
        my @trans_lines = split(/\r?\n/, $transactions);
        if ($trans_lines[0] =~ m/^(\s+)\d/) {
            my $prefix_whitespace = $1;
            @trans_lines = map {
                length($_) >= length($prefix_whitespace)
                ? substr($_, length($prefix_whitespace))
                : ''
            } @trans_lines;
            my $current_transaction;
            foreach my $line (@trans_lines) {
                if ($line =~ m/^(\d+)\s/) {
                    push(@transactions, $current_transaction)
                        if $current_transaction;
                    $current_transaction = { original_text => '' };
                }
                $current_transaction->{original_text} .= $line."\n";
            }
            push(@transactions, $current_transaction)
                if $current_transaction;
        }
    }

    #parse transactions
    foreach my $transaction (@transactions) {
        my @lines = split(/\n/,$transaction->{original_text});

        my $info_line = shift(@lines);
        die 'failed parsing "'.$info_line.'"'
            unless $info_line =~ m/
                ^\d+ \s
                (.+?) \s+
                (\d{6}) \s+
                (\d{6}) \s+
                (-?\d+\.\d{2}) $
            /xms;
        $transaction->{display_name} = $1;
        $transaction->{date1} = $2;
        $transaction->{date2} = $3;
        $transaction->{amount} = $4;
        $transaction->{cent_amount} = $transaction->{amount};
        $transaction->{cent_amount} =~ s/[.]//;
        $transaction->{cent_amount} += 0;
        $transaction->{type} = ($transaction->{amount} > 0 ? 'credit' : 'payment');

        $transaction->{account_number} = '';
        $transaction->{account_name}   = '';
        my $account_line = shift(@lines);
        if ($account_line =~ m/
            ^\s
            (?:(\w{2} \d [^\s]{5,40}) \s)?    # IBAN should be max 34 chars wide but it depends on country
            ([^\s] .+)?
            $
        /xms) {
            $transaction->{account_number} = $1;
            $transaction->{account_name}   = $2;
            $transaction->{account_name}   =~ s/\s+$//;
        }

        my $symbols_line = shift(@lines);
        die 'failed parsing "'.$symbols_line.'"'
            unless $symbols_line =~ m/
                ^\s
                VS:(\d*) \s
                KS:(\d*) \s
                SS:(\d*)
                $
            /xms;
        $transaction->{vs} = $1 if length($1 // '');
        $transaction->{ks} = $2 if length($2 // '');
        $transaction->{ss} = $3 if length($3 // '');

        @lines =
            map { s/^\s+//;$_ }
            map { s/\s+$//;$_ }
            grep { $_ !~ m/^\s*$/ } @lines;
        $transaction->{description} = join("", @lines);
    }

    @transactions = map { $class->new(%{$_}) } @transactions;
    return @transactions;

}

sub as_text {
    my ($self) = @_;
    my $text = '';
    foreach my $attr ($self->ordered_attributes) {
        $text .= $attr.': '.(defined($self->$attr) ? $self->$attr : '')."\n";
    }
    return $text;
}

sub ordered_attributes {
    return qw(
        type
        display_name
        account_name
        account_number
        amount
        cent_amount
        date1
        date2
        vs
        ks
        ss
        description
    );
}

1;


__END__

=head1 NAME

Finance::Bank::SK::SLSP::Notification::Transaction - parse txt transaction

=head1 SYNOPSIS

    my $trans = Finance::Bank::SK::SLSP::Notification::Transaction->from_txt_file($str);
    say $trans->type;
    say $trans->account_number;
    say $trans->vs;
    say $trans->ks;
    say $trans->ss;

    say $trans->as_text;

=head1 DESCRIPTION

=head1 PROPERTIES

=head1 METHODS

=head2 new()

Object constructor.

=head1 AUTHOR

Jozef Kutej

=cut
