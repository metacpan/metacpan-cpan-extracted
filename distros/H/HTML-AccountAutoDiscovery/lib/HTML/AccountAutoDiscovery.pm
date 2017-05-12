#$Id: AccountAutoDiscovery.pm,v 1.9 2005/09/02 02:59:30 naoya Exp $
package HTML::AccountAutoDiscovery;
use strict;
use base qw ( Class::ErrorHandler );
use LWP::UserAgent;

use vars qw ( $VERSION );
our $VERSION = '0.06';
my $MAX_SIZE = 1000000; # 1mb
my $TIME_OUT = 10;

sub find {
    my ($class, $uri) = @_;
    my $ua = LWP::UserAgent->new;
    $ua->agent(join '/', $class, $class->VERSION);
    $ua->timeout($TIME_OUT);
    $ua->max_size($MAX_SIZE);
    $ua->parse_head(0);
    my $req = HTTP::Request->new(GET => $uri);
    my @result;
    my $res = $ua->request($req);
    return $class->error($res->status_line) unless $res->is_success;
    $class->find_in_html(\$res->content);
}

sub find_in_html {
    my ($class, $html) = @_;
    my @result;
    $class->each_account(
        sub {
            my( $srvname, $account ) = @_;
            push @result, { service => $srvname, account => $account };
        }, $html
    );
    @result;
}

sub each_account {
    my( $self, $yield, $sp ) = @_;
    ref( $yield ) eq 'CODE'
        or die __PACKAGE__ . "\:\:each_account needs CODE_REF\n";
    my $foafuri = "http://xmlns\\.com/foaf/0\\.1/";
    while ( $$sp =~ m{(<rdf:RDF.*?</rdf:RDF>)}sg) {
        my $rdf = $1;
        my $foaf = '';
        if ( $rdf =~ m{xmlns:(\w+)="$foafuri"}o ) {
            $foaf = $1 . ':';
        } elsif ( $rdf =~ m{xmlns="$foafuri"}o ) {
            $foaf = '';
        } else {
            next;
        }
        while ( $rdf =~ m{<(${foaf}holdsAccount)(.*?)</\1>}sg ) {
            my $onlineaccount = $2;
            my( $servicehomepage, $accountname );
            if ( $onlineaccount =~ m{
                                     <${foaf}accountServiceHomepage[^>]+rdf:resource="(.*)"
                                 }xs ) {
                $servicehomepage = $1;
            }
            if ( $onlineaccount =~ m{
                                     <${foaf}accountName>[\s\n]*([^<>]+)[\s\n]*</${foaf}accountName>
                                 }xs ) {
                $accountname = $1;
            }
            if ( $onlineaccount =~ m{${foaf}accountName="([^<>]+?)"} ) {
                $accountname = $1;
            }
            if ( defined( $servicehomepage ) && defined( $accountname ) ) {
                $yield->( $servicehomepage, $accountname );
            }
        }
    }
}

1;
__END__

=head1 NAME

HTML::AccountAutoDiscovery - finding online account names in HTML

=head1 SYNOPSIS

  use HTML::AccountAutoDiscovery;
  my @account = HTML::AccountAutoDiscovery->find('http://www.example.com');

  ## OR

  my @account = HTML::AccountAutoDiscovery->find_in_html(\$html);

  print $account[0]->{account}; # account name
  print $account[0]->{service}; # service URI or literal

=head1 DESCRIPTION

I<HTML::AccountAutoDiscovery> implements Account Auto-Discovery from given a URI or a HTML document.

Account Auto-Discovery is a spec for searching account names of some online services in the HTML. You can see the document of the spec at I<http://b.hatena.ne.jp/help?mode=tipjar#autodiscovery> (But only for Japanese.)

If you want to show your online accounts on your HTML or XHTML as metadata, you can write looks like this:

  <rdf:RDF
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:foaf="http://xmlns.com/foaf/0.1/">
  <rdf:Description rdf:about="http://d.hatena.ne.jp/naoya/20050804/1123142579">
    <foaf:maker rdf:parseType="Resource">
      <foaf:holdsAccount>
        <foaf:OnlineAccount foaf:accountName="naoya">
          <foaf:accountServiceHomepage rdf:resource="http://www.hatena.ne.jp/" />
        </foaf:OnlineAccount>
      </foaf:holdsAccount>
    </foaf:maker>
  </rdf:Description>
  </rdf:RDF>

HTML::AccountAutoDiscovery module can find this RDF and parse it, then return account name of the service and URI.

=head1 AUTHOR

Naoya Ito E<lt>naoya@naoya.dyndns.orgE<gt>, MIZUTANI Tociyuki E<lt>http://tociyuki.cool.ne.jpE<gt>


This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Feed::Find> - The implementation of HTML::AccountAutoDiscovery reffered to this module.

=cut
