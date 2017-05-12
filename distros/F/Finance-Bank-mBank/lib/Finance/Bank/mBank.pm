package Finance::Bank::mBank;

our $VERSION = '0.02';

use warnings;
use strict;

use base 'Class::Accessor';

use Carp;
use Crypt::SSLeay;
use English '-no_match_vars';
use Web::Scraper;
use WWW::Mechanize;
use Exception::Base
    'Exception::Login',
    'Exception::Login::Scraping'    => { isa => 'Exception::Login' },
    'Exception::Login::Credentials' => { isa => 'Exception::Login' },
    'Exception::HTTP'               => { isa => 'Exception::Login' },
;

__PACKAGE__->mk_accessors(#{{{
qw/
    userid
    password
    _mech
    _is_logged_on
    _main_content
    _logged_userid
    _logged_password
/
);#}}}

=head1 NAME

Finance::Bank::mBank - Check mBank account balance

=head1 VERSION

Version 0.02

=cut

=head1 SYNOPSIS


    use Finance::Bank::mBank;

    my $mbank = Finance::Bank::mBank->new(
        userid   => 555123,
        password => 'loremipsum'
    );
    # There is no need to call ->login explicitly, but it is possible
    # $mbank->login
    for my $account ($mbank->accounts) {
        print "$account->{account_name}: $account->{balance}\n";
    }

=cut

sub new {#{{{
    my $class = shift;
    my %params = (ref $_[0] eq 'HASH' ? %{ $_[0] } : @_);

    my $self = $class->SUPER::new(\%params);

    use Data::Dumper;
    $self->_mech(
        WWW::Mechanize->new(
            autocheck       => 1,
            onerror         => sub { Exception::HTTP->throw(message => join(q{}, @_)) },
        )
    );

    return $self;
}#}}}
sub login {#{{{
    my $self = shift;

    return $self->_login(@_);
}#}}}
sub _login {#{{{
    my $self = shift;

    $self->_check_user_change;

    return if $self->_is_logged_on;
    
    if (!$self->userid or !$self->password) {
        Exception::Login::Credentials->throw( message => "No userid or password specified" );
    }

    my $mech = $self->_mech;

    $mech->get('https://www.mbank.com.pl/');

    if (!@{$mech->forms}) {
        Exception::Login::Scraping->throw(message => 'No forms found on login page');
    }
    
    # Login form
    my $form = $mech->form_number(1);
    if (not $form->find_input('customer') or not $form->find_input('password')) {
        Exception::Login::Scraping->throw( message => 'Wanted fields not found in form' );
    }
    $mech->field( customer => $self->userid );
    $mech->field( password => $self->password );
    $mech->submit;
    
    # Choose frame
    $mech->follow_link( name => "MainFrame" ) or Exception::Login::Scraping->throw(message => 'No FunctionFrame was found');
    
    if ($mech->content =~ /Nieprawid.owy identyfikator/) {
        Exception::Login::Credentials->throw( message => 'Invalid userid or password');
    }
    if ($mech->content =~ /B..d logowania/) {
        Exception::Login->throw( message => 'Unknown login error');
    }
    if ($mech->content !~ /Dost.pne rachunki/) {
        Exception::Login->throw( message => 'Unknown error')
    }

    $self->_main_content( $mech->content );
    $self->_logged_userid( $self->userid );
    $self->_logged_password( $self->password );
    $self->_is_logged_on(1);


}#}}}
sub accounts {#{{{
    my $self = shift;

    $self->_login;

    return __extract_accounts( $self->_main_content );
}#}}}
sub __extract_accounts {#{{{
    my $content = shift;

    my $account_scrap = scraper {
        process 'p.Account',            account_name    => 'TEXT';
        process 'p.Amount',             balance         => 'TEXT';
        process 'p.Amount + p.Amount',  available       => 'TEXT';
    };

    my $account_list_scrap = scraper {
        process '#AccountsGrid li',
            'accounts[]'        => $account_scrap;
        result 'accounts';
    };
    my $accounts = $account_list_scrap->scrape( $content );

    shift @{ $accounts }; # header row
    pop @{ $accounts }; # summary row

    for my $account ( @{$accounts} ) {
        $account->{balance}     = __process_money_amount( $account->{balance} );
        $account->{available}   = __process_money_amount( $account->{available} );
    }

    return @{ $accounts };

}#}}}
sub _check_user_change {#{{{
    my $self = shift;

    return if !$self->_is_logged_on;

    if ( ($self->userid ne $self->_logged_userid) or ($self->password ne $self->_logged_password) ) {
        $self->logout;
    }
}#}}}
sub logout {#{{{
    my $self = shift;
    
    $self->_is_logged_on(0);
    $self->_mech->get('https://www.mbank.com.pl/logout.aspx');
}#}}}
sub __process_money_amount {#{{{
    my $val = shift;

    return undef if not defined $val;

    $val =~ s/,/./;
    $val =~ s/\s//g;

    return $val;
}#}}}

=head1 AUTHOR

Bartek Jakubski, C<< <b.jakubski at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-finance-bank-mbank at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Bank-mBank>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Bank::mBank

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Bank-mBank>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Bank-mBank>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Bank-mBank>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Bank-mBank>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Bartek Jakubski, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Finance::Bank::mBank
