=head1 NAME

Finance::Bank::IE::AIB - Finance::Bank interface for Allied Irish Bank

=cut
package Finance::Bank::IE::AIB;

use base qw( Finance::Bank::IE );

use warnings;
use strict;

our $VERSION = '0.30';

my %pages = (
             login => {
                       url => 'https://aibinternetbanking.aib.ie/inet/roi/login.htm',
                       sentinel => 'Log In.*Step 1 of 2',
                      },
             login2 => {
                        url => '',
                        sentinel => 'Log In.*Step 2 of 2',
                       },
             accounts => {
                          url => 'https://aibinternetbanking.aib.ie/inet/roi/accountoverview.htm',
                          sentinel => 'your accounts',
                         },
            );

sub _pages {
    my $self = shift;
    return \%pages;
}


sub _submit_first_login_page {
    my $self = shift;
    my $confref = shift || $self->cached_config();
    my $form = $self->_agent()->form_name('form1');
    $self->_agent()->field( "regNumber", $confref->{reg_no} );
    return $self->_agent()->submit_form();
}

sub _submit_second_login_page {
    my $self = shift;
    my $confref = shift || $self->cached_config();

    my $form = $self->_agent()->form_name('loginstep2');
    for my $digit ( 1..3 ) {
        (my $wanted = $self->_agent()->content()) =~ s/^.*for="digit$digit">//s;
        $wanted =~ s/^.*?Digit //s;
        $wanted =~ s/<.*$//s;
        $self->_dprintf("Setting digit $digit to char $wanted of PIN\n");
        $self->_agent()->field( "pacDetails.pacDigit$digit", substr( $confref->{pin}, $wanted - 1, 1 ));
    }

    if ( $self->_agent()->content() =~ /last four digits/ ) {
        $self->_agent()->field("challengeDetails.challengeEntered", $confref->{phone});
    } else {
        die "asked for unknown challenge - failed";
    }

    return $self->_agent()->submit_form();
}

sub _parse_account_balance_page {
    my $self = shift;
    my $content = $self->_agent()->content();
    my $parser = new HTML::TokeParser( \$content );

    my @accounts;

    while ( my $tag = $parser->get_tag("div")) {
        if ( $self->_streq( $tag->[1]{class}, 'account-overview' )) {
            my %account;
            $parser->get_tag("span");
            $account{nick} = $parser->get_trimmed_text("/span");
            $parser->get_tag("h3");
            $account{balance} = $parser->get_trimmed_text("/h3");

            # wiggly
            $account{currency} = 'EUR';
            ( $account{type}, $account{account_no}) = split( /-/, $account{nick});

            $account{balance} = "-" . $account{balance} if $account{balance} =~ /DR/;
            $account{balance} =~ s/[^0-9.-]//g;

            push @accounts, bless \%account,
              "Finance::Bank::IE::AIB::Account";
        }
    }

    return @accounts;
}

package Finance::Bank::IE::AIB::Account;

no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;
