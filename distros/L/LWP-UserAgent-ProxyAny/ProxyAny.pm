package LWP::UserAgent::ProxyAny;
use strict;
use warnings;
our $VERSION = "1.01";
use base qw(LWP::UserAgent);

sub env_proxy {
    my ( $this ) = @_;

    # Call real env_proxy of LWP UserAgent
    $this->SUPER::env_proxy;

    # Try to get IE proxy setttings, return if not Win32 or not set
    my $ie_proxy_no = "";
    my $ie_proxy_server = $this->get_ie_proxy( $ie_proxy_no );
    return if $ie_proxy_server eq "";

    # Set LWP proxy
    if( $ie_proxy_server=~/;/ ) {
        #Multiple proxies, such as ftp=192.168.1.3:8080;...;https=192.168.1.3:8080
        map /^(.*?)=(.*?)$/ && $this->proxy( $1, "http://$2/" ), split( /;/, $ie_proxy_server );
    }else{
        #Single proxy, such as 192.168.1.3:8080
        $this->proxy( ['http','https','ftp','gopher'], "http://$ie_proxy_server/" );
    }

    # Set LWP no_proxy
    $this->no_proxy( map( /<local>/i ? "localhost" : $_, split( /;/, $ie_proxy_no ) ) )
        if $ie_proxy_no ne "";
}

sub get_ie_proxy {
    return "" unless $^O eq 'MSWin32';
    my %RegHash;
    eval 'use Win32::TieRegistry(Delimiter=>"/", TiedHash=>\%RegHash);';
    return get_ie_proxy_with_registry() if $@;
    my $iekey = $RegHash{"CUser/Software/Microsoft/Windows/CurrentVersion/Internet Settings/"} or return "";
    my $ie_proxy_enable = $iekey->{"/ProxyEnable"} or return "";
    my $ie_proxy_server = $iekey->{"/ProxyServer"} or return "";
    my $ie_proxy_no = $iekey->{"/ProxyOverride"};
    $_[1]=$ie_proxy_no if defined($ie_proxy_no);
    return $ie_proxy_enable=~/1$/ ? $ie_proxy_server : "";
}

sub get_ie_proxy_with_registry {
    return "" unless $^O eq 'MSWin32';
    eval 'use Win32::Registry;';
    return "" if $@;
    my ( $iekey, $type, $ie_proxy_enable, $ie_proxy_server, $ie_proxy_no );
    no warnings;
    $::HKEY_CURRENT_USER->Open( "SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Internet Settings", $iekey ) or return "";
    use warnings;
    $iekey->QueryValueEx( "ProxyEnable", $type, $ie_proxy_enable );
    $iekey->QueryValueEx( "ProxyServer", $type, $ie_proxy_server );
    $iekey->QueryValueEx( "ProxyOverride", $type, $ie_proxy_no );
    $iekey->Close;
    $_[1]=$ie_proxy_no if defined($ie_proxy_no);
    return defined($ie_proxy_enable) && $ie_proxy_enable=~/1$/ && defined($ie_proxy_server)
        ? $ie_proxy_server : "";
}

sub set_proxy_by_name {
    my ( $this, $proxy_name ) = @_;
    $proxy_name=~s/ //g;    # Remove spaces

    #Don't use proxy
    return if $proxy_name=~/^No$/i or $proxy_name eq "";

    # Use default proxy
    if( $proxy_name=~/^(System|Default)/i ) {
        $this->env_proxy;
        return;
    }

    # Set user-defined proxy
    $proxy_name =~ s/^http:\/\///i;
    $this->proxy( ['http','https','ftp','gopher'], "http://$proxy_name" );
}

1;
__END__

=head1 NAME

LWP::UserAgent::ProxyAny - A LWP UserAgent supports both HTTP_PROXY and IE proxy

=head1 SYNOPSIS

  use LWP::UserAgent::ProxyAny;

  my $ua = LWP::UserAgent::ProxyAny->new;
  $ua->env_proxy;   # visit url with HTTP_PROXY or Win32 IE proxy settings

  my $response = $ua->get('http://sourceforge.net/projects/bookbot');
  if ($response->is_success) {
      print $response->content;  # or whatever
  }
  else {
      die $response->status_line;
  }

  # Or set proxy by specified name

  $ua->set_proxy_by_name("No");              # No Proxy
  $ua->set_proxy_by_name("Default");         # $ua->env_proxy
  $ua->set_proxy_by_name("127.0.0.1:8080");  # set proxy as http://127.0.0.1:8080

=head1 ABSTRACT

Extended LWP::UserAgent, which supports both HTTP_PROXY and IE proxy setting.

=head1 DESCRIPTION

This class is an extended LWP UserAgent, which can support both traditional
HTTP_PROXY settings and proxy settings of Microsoft Windows Internet Explorer.

=item $ua->env_proxy

Read proxy settings from HTTP_PROXY or CGI_HTTP_PROXY or win32 IE proxy settings.

=item $ua->set_proxy_by_name($name)

Set proxy settings from $name.

  $name = "No";            # No Proxy
  $name = "Default";       # $ua->env_proxy
  $name = "Others...";     # set proxy as http://Others...

=item my $ie_proxy_server = $this->get_ie_proxy( $ie_proxy_no )

Return current IE proxy settings and set $ie_proxy_no as proxy override settings.

=head1 BUGS, REQUESTS, COMMENTS

Please report any requests, suggestions or bugs via
http://sourceforge.net/projects/bookbot
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-UserAgent-ProxyAny

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2004 Qing-Jie Zhou E<lt>qjzhou@hotmail.comE<gt>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut