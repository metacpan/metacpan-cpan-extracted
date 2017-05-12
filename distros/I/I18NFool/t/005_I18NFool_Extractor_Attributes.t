#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use I18NFool::Extractor;

use Test::More 'no_plan';

# okay, first let us test the namespace support...
my $xml = <<EOF;
  <input
    type="text"
    size="12"
    name="q"
    id="q"
    value="Keyword(s)"
    onblur="if(this.value=='')this.value='Keyword(s)';"
    onfocus="if(this.value=='Keyword(s)')this.value='';"
    title="Enter your search term(s) here [ Accesskey 4 ]"
    accesskey="4"
    i18n:attributes="title search-input-title;
                     onblur search-input-onblur;
                     onfocus search-input-onfocus;
                     value search-input;"
  />
EOF

my $res = I18NFool::Extractor->process ($xml);
ok ($res);
ok ($res->{default});
ok ($res->{default}->{'search-input'});
ok ($res->{default}->{'search-input-title'});
ok ($res->{default}->{'search-input-onfocus'});
ok ($res->{default}->{'search-input-onblur'});


1;

__END__
