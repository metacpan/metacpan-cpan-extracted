package Dokuwiki::RPC::XML::Client;
# ABSTRACT: Dokuwiki::RPC::XML::Client - A RPC::XML::Client for dokuwiki (https://www.dokuwiki.org)
use strict;
use warnings;
use parent 'RPC::XML::Client';
our $VERSION = '0.2';
our %API = qw<
getPagelist dokuwiki.getPagelist
getVersion dokuwiki.getVersion
getTime dokuwiki.getTime
getXMLRPCAPIVersion dokuwiki.getXMLRPCAPIVersion
login dokuwiki.login
search dokuwiki.search
getTitle dokuwiki.getTitle
appendPage dokuwiki.appendPage
setLocks dokuwiki.setLocks
getRPCVersionSupported wiki.getRPCVersionSupported
aclCheck wiki.aclCheck
getPage wiki.getPage
getPageVersion wiki.getPageVersion
getPageVersions wiki.getPageVersions
getPageInfo wiki.getPageInfo
getPageInfoVersion wiki.getPageInfoVersion
getPageHTML wiki.getPageHTML
getPageHTMLVersion wiki.getPageHTMLVersion
putPage wiki.putPage
listLinks wiki.listLinks
getAllPages wiki.getAllPages
getBackLinks wiki.getBackLinks
getRecentChanges wiki.getRecentChanges
getRecentMediaChanges wiki.getRecentMediaChanges
getAttachments wiki.getAttachments
getAttachment wiki.getAttachment
getAttachmentInfo wiki.getAttachmentInfo
putAttachment wiki.putAttachment
deleteAttachment wiki.deleteAttachment
addAcl plugin.acl.addAcl
delAcl plugin.acl.delAcl >; 

sub _reach_arguments {
    if    ( $_[1] eq 'url' )  { splice @_, 1, 1; return }
    elsif ( $_[1] eq 'base' ) { splice @_, 1, 1 }
    $_[1].='lib/exe/xmlrpc.php';
}

sub reach {
    &_reach_arguments;
    my ( $class, $url, %options ) = @_;
    $options{file} //= "$ENV{HOME}/.dokuwiki.cookies.txt";
    $class->new
    ( $url 
    , useragent => [ cookie_jar => { file => $options{file} } ]
    , error_handler => sub { die $_[0] }
    , fault_handler => sub { die $_[0]->string } );
}

{ no strict 'refs';
    while ( my($method, $call) = each %API ) {
        *{__PACKAGE__."::$method"} = sub {
            my $client = shift;
            $client->send_request( $call, @_ )->value
        }
    }
};

1;

=head1 NAME

Dokuwiki::RPC::XML::Client - A RPC::XML::Client for L<dokuwiki|https://www.dokuwiki.org>.

=head1 SYNOPSIS

L<Dokuwiki::RPC::XML::Client> extends the L<RPC::XML::Client> with the Dokuwiki
XML-RPC methods (without namespace) described in the
L<dokuwiki xml-rpc page|https://www.dokuwiki.org/devel:xmlrpc>.

As example, a call to 
L<wiki.getVersion|https://www.dokuwiki.org/devel:xmlrpc#dokuwikigetversion>
(which also require a call to
L<dokuwiki.login|https://www.dokuwiki.org/devel:xmlrpc#dokuwikilogin>) is: 

    use Dokuwiki::RPC::XML::Client;
    use Modern::Perl;

    my $wiki =
        Dokuwiki::RPC::XML::Client 
        -> reach('https://wiki.example.com/');

    $wiki->login(qw( editor s3cr3t ))->value or die;
    say $wiki->getVersion->value;

=head1 the C<reach> constructor

to use the C<RPC::XML::Client::new> constructor directly, you have to remember the url of the RPC server 
and how to setup a cookie file so you stay connected after the 
L<dokuwiki.login|https://www.dokuwiki.org/devel:xmlrpc#dokuwikilogin>) was called. 

So, as explained in
L<http://stackoverflow.com/questions/16572903/logging-into-dokuwiki-using-perls-rpcxmlclient-or-alternately-how-can-i-re>, 
calling the constructor would be: 

    my $client =
        RPC::XML::Client->new
        ('http://example.com/wikiname/lib/exe/xmlrpc.php'
        , useragent => [ cookie_jar => { file => "$ENV{HOME}/.cookies.txt" }] );

But you don't want to write it down? don't you? L<Dokuwiki::RPC::XML::Client> comes with a
wrapper called C<reach $class $url %options>; possible calls are

        Dokuwiki::RPC::XML::Client->reach
        ('http://example.com/wikiname/' );

        Dokuwiki::RPC::XML::Client->reach
        ( base => 'http://example.com/wikiname/' );

        Dokuwiki::RPC::XML::Client->reach
        ( url => 'http://example.com/wikiname/lib/exe/xmlrpc.php' );

        Dokuwiki::RPC::XML::Client->reach
        ('http://example.com/wikiname/'
        , file => '/tmp/dokukookies.txt' );

=head1 METHODS, INTROSPECTION

C<%Dokuwiki::RPC::XML::Client::API> is a hash where keys are the
C<Dokuwiki::RPC::XML::Client> methods and values are the Dokuwiki XML-RPC
methods. So you can have the list of the mapped functions with:

    perl -MDokuwiki::RPC::XML::Client -E'
        say for keys %Dokuwiki::RPC::XML::Client::API 

but please refer to the 
L<dokuwiki xml-rpc page|https://www.dokuwiki.org/devel:xmlrpc> for more details.

=head1 A REAL WORLD EXAMPLE USING C<~/.netrc>

getting the login and password from C<STDIN>, C<@ARGV> or hardcoded in your
source file is B<always> a bad idea. so this is an example to get things done
using the god damn old and good C<~/.netrc> file.

    use Dokuwiki::RPC::XML::Client;
    use Modern::Perl;
    use Net::Netrc;
    my $base = 'https://example.com/';
    my $host = 'company';

    my $wiki =
        Dokuwiki::RPC::XML::Client 
        -> reach('https://wiki.example.com/');

    my $credentials = Net::Netrc->lookup($host)
        or die "please add a fake $host machine in your ~/.netrc";

    my ( $l, $p ) = $credentials->lpa;

    $wiki->login( $l, $p )->value 
        or die "can't authenticate with $l";

    say $wiki->getVersion->value;

=head1 FUTURE

i'm still experimenting to make my mind up about the right way to do it. it would
be nice to have both a raw C<RPC::XML::Client> as a singleton. then we could have
something usable in both way

    use aliased qw<Dokuwiki::RPC::XML::Client::Singleton D>;
    D::netrc 'unistra';
    D::login 'https://di.u-strasbg.fr';
    say "connected to dokuwiki version ". D::getVersion;
    say for grep /^metiers:/, ids_of D::getAllPages; 

or

    use Dokuwiki::RPC::XML::Client::Singleton ':all';
    netrc 'unistra';
    login 'https://di.u-strasbg.fr';
    say "connected to dokuwiki version ". getVersion;
    say for grep /^metiers:/, ids_of getAllPages;

=cut
