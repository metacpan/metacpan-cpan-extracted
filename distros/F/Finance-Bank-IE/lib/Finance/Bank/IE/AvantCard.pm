=head1 NAME

Finance::Bank::IE::AvantCard - Finance::Bank interface for AvantCard (Ireland)

=cut
package Finance::Bank::IE::AvantCard;

use base qw( Finance::Bank::IE );

our $VERSION = "0.30";

use warnings;
use strict;
use HTML::TokeParser;

my %pages = (
             login => {
                       url => 'https://onlinebanking.avantcard.ie/Enrolment/Login',
                       sentinel => 'enter your login details below',
                      },
             login2 => {
                        url => 'https://onlinebanking.avantcard.ie/Enrolment/Memorable',
                        sentinel => 'Please enter the following characters from your memorable word.',
                       },
             accounts => {
                          url => 'https://onlinebanking.avantcard.ie/Overview/Overview',
                          sentinel => 'Overview',
                         },
             expired => {
                         url => 'https://onlinebanking.avantcard.ie/Errors/Http450',
                         sentinel => 'Your Online Banking session has expired.',
                        },
             sitedown => {
                          sentinel => 'not available at this time',
                         },
            );

# XXX this needs to be everywhere, but have access to %pages
sub _pages {
    my $self = shift;
    return \%pages;
}

sub _submit_first_login_page {
    my $self = shift;
    my $confref = shift || $self->cached_config();
    my $form = $self->_agent()->current_form();
    $self->_agent()->field( "UserName", $confref->{user} );
    $self->_agent()->field( "Password", $confref->{password});
    return $self->_agent()->submit_form();
}

sub _submit_second_login_page {
    my $self = shift;
    my $confref = shift || $self->cached_config();

    my $word = $confref->{memorable};
    my $content = $self->_agent()->content();
    my $parser = new HTML::TokeParser( \$content );

    while ( my $tag = $parser->get_tag( "div" )) {
        next unless $tag->[1]{class} eq 'memorableInput';
        while ( my $text = $parser->get_trimmed_text("input")) {
            my ( $card ) = $text =~ /^(\d+)/;
            if ( !defined( $card )) {
                die "unable to get a card out of $text\n";
            }
            $tag = $parser->get_tag("input");
            $self->_agent()->field($tag->[1]{name},
                                   substr( $word, $card - 1, 1 ));
            last if $tag->[1]{name} eq 'MemorableWords4';
        }
    }
    return $self->_agent()->submit_form();
}

sub _parse_account_balance_page {
    my $self = shift;
    my $content = $self->_agent()->content();
    my $parser = new HTML::TokeParser( \$content );

    my @accounts;

  SELECTS:
    while ( my $tag = $parser->get_tag( "select" )) {
        if ( $tag->[1]{id} eq 'CreditCardSelection' ) {
            while ( $tag = $parser->get_tag( "option", "/select" )) {
                if ( $tag->[0] eq '/select' ) {
                    last SELECTS;
                } else {
                    my %account;
                    my $detail = $parser->get_trimmed_text("/option");
                    ( $account{nick}, $account{account_no},
                      $account{status}, $account{balance},
                      $account{limit} ) = split( /__+/, $detail );
                    $account{type} = $account{nick};
                    $account{currency} = "EUR";
                    $account{balance} =~ s/[^0-9.]//g;
                    push @accounts, bless \%account,
                      "Finance::Bank::IE::AvantCard::Account";
                }
            }
        }
    }

    return @accounts;
}

# XXX promote
package Finance::Bank::IE::AvantCard::Account;

no strict;
sub AUTOLOAD { my $self=shift; $AUTOLOAD =~ s/.*:://; $self->{$AUTOLOAD} }

1;
