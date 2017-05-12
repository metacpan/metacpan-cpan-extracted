
package Test::XML::Canon;

use Test::Builder;
use Test::More;
use XML::LibXML;
use strict;
use warnings;

my $Test=Test::Builder->new();

sub import{
  my $self=shift;
  my $caller=caller;

  {
    no strict 'refs';
    *{$caller.'::is_xml_canon'}=\&is_xml_canon;
  }

  $Test->exported_to($caller);
  $Test->plan(@_);
}

{
  my($last_xml_in,$last_xml_canon)=('','');

  sub canon_xml {
    my($xml,$source)=@_;
    return $last_xml_canon if defined($xml) && $xml eq $last_xml_in;
    $source=$source ? " ($source)" : '';

    local $Test::Builder::Level=$Test::Builder::Level+1;
    return fail("XML$source is not defined") unless defined $xml;
    my $dom=eval{
      XML::LibXML->new->parse_string($xml);
    }
      or do {
        chomp(my $err=$@);
	$err=~s/:/$source:/;
	return fail($err);
      };
    $last_xml_in=$xml;
    $last_xml_canon=$dom->toStringC14N;
  }
}

sub is_xml_canon($$;$) {
  my($got,$expect,$comment)=@_;
  local $Test::Builder::Level=$Test::Builder::Level+1;

  my $got_canon=canon_xml($got,'got')
    or return 0;
  my $expect_canon=canon_xml($expect,'expect')
    or return 0;

  is($got_canon,$expect_canon,$comment);
}


1;

