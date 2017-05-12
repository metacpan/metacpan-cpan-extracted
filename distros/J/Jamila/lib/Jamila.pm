package Jamila;
use strict;
use warnings;
use utf8;
use CGI;
use JSON;
use LWP;
our $oCgi;
our $VERSION = '0.03';

#--------------------------------------------------------------------
# _disp: display about processing class
#--------------------------------------------------------------------
sub _disp($$$)
{
  my ($sClass, $sUrl, $sMod) = @_;
  binmode STDOUT, ':utf8';
  print "Content-Type: text/html\n\n";
  print<<EOD;
<HTML>
<HEAD>
<TITLE>$sClass ($sMod) </TITLE>
</HEAD>
<BODY>
<H1>This is $sClass !</H1>
for : $sMod at $sUrl
</BODY>
</HTML>
EOD
}
#--------------------------------------------------------------------
# proc
#--------------------------------------------------------------------
sub proc($$)
{
  my($sClass, $sMod) = @_;
  $oCgi = new CGI();
  my $sPrm = $oCgi->param('_prm');
  #1. No '_prm' means default display
  return $sClass->_disp($oCgi->url(), $sMod) if(!defined($sPrm) || $sPrm eq '');

  #2. _RAW_
  utf8::decode($sPrm); #become with utf8-flag
  my $oRes = '';
  my $sMsg = '';

  if($sPrm eq '_RAW_')
  {
    my $sMethod = '_raw_' . ($oCgi->param('_method') || '');
    eval
    {
      $oRes = $sMod->$sMethod($oCgi);
    };
    return unless($@);
    $sMsg = $@;
  }
  else
  {
    if($sPrm)
    {
      my $raData = from_json($sPrm);
      my ($sMethod, @aPrm) = @$raData;
      if(substr($sMethod, 0, 1) ne '_')
      {
        eval
        {
          $oRes = $sMod->$sMethod(@aPrm);
        };
        if($@)
        {
          eval
          {
            eval "require $sMod; import $sMod;";
            $oRes = $sMod->$sMethod(@aPrm);
          };
          if($@)
          {
            $sMsg = $@;
            $oRes = '';
          }
        }
      }
      else
      {
        $sMsg = "Jamila:: can't call $sMethod";
      }
    }
    else
    {
      $sMsg = 'Jamila:: NO PARAM';
    }
  }
  binmode STDOUT, ':utf8';
  print "Content-Type: text/plain; charset=UTF-8\n\n" . 
      to_json({
                error  => $sMsg,
                result => $oRes,
              });
}
#---------------------------------------------------------------------
# new : mainly for request
#---------------------------------------------------------------------
sub new($$)
{
  my($sClass, $sUrl) = @_;
  my $oUa = LWP::UserAgent->new();
  $oUa->env_proxy();
  return
    bless {
      URL => $sUrl,
      _lwpUa => $oUa,
      }, $sClass;
}
#---------------------------------------------------------------------
# _buildParam : for request
#---------------------------------------------------------------------
sub _buildParam($%)
{
    my($oSelf, %hParam) = @_;
    my $sPrm = '';
    if(%hParam)
    {
        while(my($sKey, $sVal) = each(%hParam))
        {
            $sPrm .= '&' if($sPrm ne '');
            $sVal = ($sVal)? URI::Escape::uri_escape_utf8($sVal) : '';
            $sPrm .= "$sKey=$sVal";
        }
    }
    return $sPrm;
}
#---------------------------------------------------------------------
# call : 
#---------------------------------------------------------------------
sub call($@)
{
  my($oSelf, @aPrm) = @_;
  if(ref($oSelf->{URL}) ne '')
  {
    my $sFunc = shift(@aPrm);
    return $oSelf->{URL}->$sFunc(@aPrm);
  }
  else
  {
    my %hPrm;
    if(@aPrm)
    {
      $hPrm{_prm} = to_json(\@aPrm);
    }
    my $sPrm = $oSelf->_buildParam(%hPrm);
    my $oReq = new HTTP::Request('POST', $oSelf->{URL});
    $oReq->header('Content-Type',  
          'application/x-www-form-urlencoded; charset=UTF-8');
    $oReq->header('Accept-Charset',  'UTF-8');
    $oReq->add_content($sPrm . "\x0d\x0a");
    my $oRes = $oSelf->{_lwpUa}->request($oReq);
    if ($oRes->is_success)
    {
        my $rhRes = from_json($oRes->content);
        die($rhRes->{error}) if($rhRes->{error});
        return $rhRes->{result};
    }
    else
    {
        die($oRes->as_string);
    }
  }
}
1;
__END__

=head1 NAME

Jamila - Perl extension for JSON Approach to Make Integration Linking Applications

=head1 SYNOPSIS

 1. Receive Mode:
 1.1 Perl sample(testJamila.pl)
  #!/usr/bin/perl
  use strict;
  package Smp;
  sub echo($$)
  {
    my($sClass, $sPrm) = @_;
    return "Welcome to Jamila! ( $sPrm )";
  }
  package main;
  use Jamila;
  Jamila->proc('Smp');

 1.2 Call from JavaScript
  var oJmR  = new Jamila(
                       '/cgi-bin/jamila/testJamila.pl',
                       null, null,
                       function(sMsg) { alert("ERROR:" + sMsg);});
 alert(oJmR.call('echo', 'Call FROM JavaScript' ));

 var oLocal = {
    echo: function (sPrm) { return "LOCAL CALL:" + sPrm;},
 };
 var oJmL  = new Jamila(oLocal,
                       null, null,
                       function(sMsg) { alert("ERROR:" + sMsg);});
 alert(oJmL.call('echo', 'Call FROM JavaScript(LOCAL)' ));

 2. Call Mode:
  use strict;
  package SmpLocal;
  sub echo($$)
  {
    my($sClass, $sPrm) = @_;
    return "LOCAL: Welcome to Jamila! ( $sPrm )";
  }
  
  package main;
  use Jamila;
  use Data::Dumper;
  #(1) Call Remote
  my $oJm = Jamila->new(
    'http://hippo2000.atnifty.com/cgi-bin/jamila/testJamila.pl');
  print $oJm->call('echo', 'Test for Remote') . "\n";
  
  #(2) Call Local
  my $oJmL = Jamila->new(bless {}, 'SmpLocal');
  print $oJmL->call('echo', 'How is local?') . "\n";


=head1 DESCRIPTION

Jamila is yet another RPC using JSON and HTTP(CGI).
Jamila stands for JSON Approach to Make Integration Linking Applications.

Jamila has 2 modes; recieve and call.

=head2 proc

 Jamila->proc(I<$sModule>);

In receive mode, this is the only method to call.
When this method is called, Jamila will get parameters from CGI parameters.
And it will call the function specified in a parameter.


=head2 new

 I<$oJml> = Jamila->new(I<$sUrl>);

Constructor for call mode.
You can set I<$sUrl> as a URL or a local object.

=head2 call

 I<$oJml>->call(I<$sUrl>);

If you set a URL in "new" method, "call" will POST to that URL.
If you set a local object in "new" method, "call" will perform a function of 
the specified object.

=head1 SEE ALSO

This distribution has sample HTML + JavaScript and perl script.

- 1. Put jamila.html and Jamila.js into a htdocs/jamila directory.
- 2. Put testJamila.pl into a cgi-bin/jamila directory. And set to run that script.
- 3. Run perl function from jamila.html

=head1 AUTHOR

KAWAI,Takanori E<lt>kwitknr@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by KAWAI,Takanori

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
