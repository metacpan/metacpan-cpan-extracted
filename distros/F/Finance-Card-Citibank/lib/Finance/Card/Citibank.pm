package Finance::Card::Citibank;

# ABSTRACT: Check your credit card balances.

use strict;
use warnings;

use Carp;
use LWP;
use DateTime;
use HTML::Parser;

our $VERSION = '2.02';

my $ua = LWP::UserAgent->new();

sub check_balance {
    my ( $class, %opts ) = @_;
    my $self = bless {%opts}, $class;

    my $position = 1;
    my @accounts;

    my @ofx_accounts = $self->_get_accounts;
    for my $accnt (@ofx_accounts) {

        my $acctid = $accnt->{ccacctinfo}{ccacctfrom}{acctid};
        my $desc   = $accnt->{desc};
        # print "id: $acctid\n";
        # print "desc: $desc\n";

        my $balance =
          $self->_get_account_balance(
            $accnt->{ccacctinfo}{ccacctfrom}{acctid} );
        # print "balance: $balance\n";

        push @accounts, (
            bless {
                balance    => $balance,
                name       => $desc,
                sort_code  => $acctid,
                account_no => $acctid,
                position =>
                  $position++,    # redundant since just = array index + 1
                statement => undef,
                ## parent => $self,
            },
            "Finance::Card::Citibank::Account"
        );

    }

    return @accounts;
}

sub _get_accounts {
    my $self = shift;

    my $content = $self->_retrive_accounts;

    my ( $ofx_header, $ofx_body ) = split /\n\n/, $content, 2;
    my $tree = $self->_parse( $content );

    my $accntinfo =
      $tree->{ofx}{signupmsgsrsv1}{acctinfotrnrs}{acctinfors}{acctinfo};
    my @accounts = ref $accntinfo eq 'ARRAY' ? @$accntinfo : $accntinfo;

    return @accounts;
}

sub _get_account_balance {
    my ( $self, $account ) = @_;

    my $content = $self->_retrive_account_balance($account);
    my $tree = $self->_parse( $content );

    exists $tree->{ofx}{creditcardmsgsrsv1}{ccstmttrnrs}{ccstmtrs}{ledgerbal}
      {balamt}
      or confess "Unable to find balance: $content";
    my $balance =
      $tree->{ofx}{creditcardmsgsrsv1}{ccstmttrnrs}{ccstmtrs}{ledgerbal}
      {balamt};

    return $balance;
}

sub _retrive_accounts {
    my $self = shift;

    if ( $self->{content} ) {

        # If we give it a file, use the file rather than downloading
        open my $fh, "<", $self->{content} or confess;
        my $content = do { local $/ = undef; <$fh> };
        close $fh;
        return $content;
    }

    croak "Must provide a password" unless exists $self->{password};
    croak "Must provide a username" unless exists $self->{username};

    my $r =
      HTTP::Request->new( POST =>
          'https://secureofx2.bankhost.com/citi/cgi-forte/ofx_rt?servicename=ofx_rt&pagename=ofx'
      );
    $r->content_type('application/x-ofx');
    $r->content( <<"ACCNT_REQ" );
OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>
    <SIGNONMSGSRQV1>
        <SONRQ>
            <DTCLIENT>@{[ DateTime->now->strftime('%Y%m%d%H%M%S.000') ]}
            <USERID>@{[ $self->{username } ]}
            <USERPASS>@{[ $self->{password} ]}
            <LANGUAGE>ENG
            <FI>
                <ORG>Citigroup
                <FID>24909
            </FI>
            <APPID>QWIN
            <APPVER>1800
        </SONRQ>
    </SIGNONMSGSRQV1>
    <SIGNUPMSGSRQV1>
        <ACCTINFOTRNRQ>
            <TRNUID>@{[ DateTime->now->strftime('%Y%m%d%H%M%S.000') ]}
            <CLTCOOKIE>1
            <ACCTINFORQ>
                <DTACCTUP>19691231
            </ACCTINFORQ>
        </ACCTINFOTRNRQ>
    </SIGNUPMSGSRQV1>
</OFX>
ACCNT_REQ

    # print "request: ", $r->as_string, "\n\n---\n\n";
    my $response = $ua->request($r);
    my $content  = $response->content;

    if ( $self->{log} ) {

        # Dump to the filename passed in log
        open( my $fh, ">", $self->{log} ) or confess;
        print $fh $content;
        close $fh;
    }

    return $content;

}

sub _retrive_account_balance {
    my ( $self, $account ) = @_;

    if ( $self->{content2} ) {

        # If we give it a file, use the file rather than downloading
        open my $fh, "<", $self->{content2} or confess;
        my $content = do { local $/ = undef; <$fh> };
        close $fh;
        return $content;
    }

    croak "Must provide a password" unless exists $self->{password};
    croak "Must provide a username" unless exists $self->{username};

    my $r =
      HTTP::Request->new( POST =>
          'https://secureofx2.bankhost.com/citi/cgi-forte/ofx_rt?servicename=ofx_rt&pagename=ofx'
      );
    $r->content_type('application/x-ofx');
    $r->content( <<"ACCNT_REQ" );
OFXHEADER:100
DATA:OFXSGML
VERSION:102
SECURITY:NONE
ENCODING:USASCII
CHARSET:1252
COMPRESSION:NONE
OLDFILEUID:NONE
NEWFILEUID:NONE

<OFX>
    <SIGNONMSGSRQV1>
        <SONRQ>
            <DTCLIENT>@{[ DateTime->now->strftime('%Y%m%d%H%M%S.000') ]}
            <USERID>@{[ $self->{username } ]}
            <USERPASS>@{[ $self->{password} ]}
            <LANGUAGE>ENG
            <FI>
                <ORG>Citigroup
                <FID>24909
            </FI>
            <APPID>QWIN
            <APPVER>1800
        </SONRQ>
    </SIGNONMSGSRQV1>
    <CREDITCARDMSGSRQV1>
        <CCSTMTTRNRQ>
            <TRNUID>@{[ DateTime->now->strftime('%Y%m%d%H%M%S.000') ]}
            <CLTCOOKIE>1
            <CCSTMTRQ>
                <CCACCTFROM>
                    <ACCTID>@{[ $account ]}
                </CCACCTFROM>
                <INCTRAN>
                    <DTSTART>19691231
                    <INCLUDE>N
                </INCTRAN>
            </CCSTMTRQ>
        </CCSTMTTRNRQ>
    </CREDITCARDMSGSRQV1>
</OFX>
ACCNT_REQ

    # print "request: ", $r->as_string, "\n\n---\n\n";
    my $response = $ua->request($r);
    my $content  = $response->content;

    if ( $self->{log2} ) {

        # Dump to the filename passed in log
        open( my $fh, ">", $self->{log2} ) or confess;
        print $fh $content;
        close $fh;
    }

    return $content;

}

sub _parse {
    my ($self,$content) = @_;

    my ( $ofx_header, $ofx_body ) = split /\n\n/, $content, 2;

    my @tree;
    my @stack;
    unshift @stack, \@tree;

    my $p = HTML::Parser->new(
        start_h => [
            sub {
                my $data = shift;

                my @content = ();
                push @{ $stack[0] }, { name => $data, content => \@content };
                unshift @stack, \@content;
            },
            'tagname'
        ],
        end_h => [
            sub {    # An end event unwinds the stack by one level
                shift(@stack);
            },
            ''
        ],
        text_h => [
            sub {
                my $data = shift;
                $data =~ s/^\s*//;    # Strip leading whitespace
                $data =~ s/\s*$//;    # Strip trailing whitespace
                return unless length $data;    # Ignore empty strings
                if ( scalar( @{ $stack[0] } ) ) {
                    print STDERR "Naked text\n";
                    return;
                }
                shift @stack;    # Unwind the vestigal array reference
                @{ $stack[0] }[-1]->{content} = $data;
            },
            'dtext'
        ] );
    $p->unbroken_text(1);   # Want element contents in single blocks to facilita
    $p->parse($ofx_body);

    my $tree = _collapse(\@tree);
    my $resp_code = $tree->{ofx}{signonmsgsrsv1}{sonrs}{status}{code};
    if ( undef $resp_code or $resp_code ) {    # Undef or not 0
        confess "Error in response from ofx server: $ofx_body";
    }

    return $tree;

}

sub _is_unique {
    my $a = shift;
    return undef unless ref($a) eq 'ARRAY';
    my %saw;
    $saw{ $_->{name} }++ || return 0 for @{$a};
    1;
}

sub _collapse {
    my $tree = shift;
    return $tree unless ref($tree) eq 'ARRAY';

    # Recurse on any elements that have arrays for content
    $_->{content} = _collapse( $_->{content} ) for ( @{$tree} );

    # The passed array can be converted to a hash if all of it's nodes have
    #  unique names
    my %a;
    if ( _is_unique($tree) ) {
        $a{ $_->{name} } = $_->{content} for ( @{$tree} );
    } else    # Duplicate names can be converted to an array
    {
        my %b;
        $b{ $_->{name} }++ for @{$tree};

        #	grep(!$b{$_->{name}}++, @{$tree});
        ( $b{$_} > 1 ) && ( $a{$_} = [] ) for keys %b;
        for ( @{$tree} ) {
            push( @{ $a{ $_->{name} } }, $_->{content} ), next
              if $b{ $_->{name} } > 1;
            $a{ $_->{name} } = $_->{content};

            #	    ($b{$_->{name}} > 1) ? push(@{$a{$_->{name}}}, $_->{content}) :
            #				   ($a{$_->{name}} = $_->{content});
        }
    }
    return \%a;
}

package Finance::Card::Citibank::Account;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(
    qw(balance name sort_code account_no position statement));

1;

__END__

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Finance::Card::Citibank - Check your Citigroup credit card accounts from Perl

=head1 SYNOPSIS

  use Finance::Card::Citibank;
  my @accounts = Finance::Card::Citibank->check_balance(
      username => "xxxxxxxxxxxx",
      password => "12345",
  );

  foreach (@accounts) {
      printf "%20s : %8s / %8s : USD %9.2f\n",
      $_->name, $_->sort_code, $_->account_no, $_->balance;
  }
  
=head1 DESCRIPTION

This module provides a rudimentary interface to Citigroup's credit card
balances.  You will need either C<Crypt::SSLeay> or C<IO::Socket::SSL>
installed for HTTPS support to work. Version 2.01 was a re-write to 
use the OFX interface rather than screen scraping. This should make
the module more stable as the screen scrapping method required updates
whenever there were changes to Citigroup's site.

=head1 CLASS METHODS

=head2 check_balance()

  check_balance( usename => $u, password => $p )

Return an array of account objects, one for each of your bank accounts.

=head1 OBJECT METHODS

  $ac->name
  $ac->sort_code
  $ac->account_no

Return the account name, sort code and the account number. The sort code is
just the name in this case, but it has been included for consistency with 
other Finance::Bank::* modules.

  $ac->balance

Return the account balance as a signed floating point value.

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

Brandon Fosdick's for his Finance::OFX module. I was unable to use the 
modules outright as their is quite a bit that differs between bank and
credit card OFX, but some of his parsing routines were very helpful.

Jon Keller added the ability to pull multiple accounts.

=head1 AUTHOR

Mark Grimes, E<lt>mgrimes@cpan.orgE<gt>

=for perl-template id="=head1 AUTHOR" md5sum=11d321cd698d426d0121184a785cc216

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Mark Grimes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.


=for perl-template id="=head1 COPYRIGHT" md5sum=ed388b67604798cc1cd58cb877f07020

=cut
