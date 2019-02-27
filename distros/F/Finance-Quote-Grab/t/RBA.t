#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2015, 2019 Kevin Ryde

# This file is part of Finance-Quote-Grab.
#
# Finance-Quote-Grab is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Finance-Quote-Grab is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Finance-Quote-Grab.  If not, see <http://www.gnu.org/licenses/>.


use strict;
use Test::More tests => 22;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Finance::Quote::RBA;

# uncomment this to run the ### lines
#use Smart::Comments;

## no critic (ProtectPrivateSubs)

#------------------------------------------------------------------------------
my $want_version = 15;
is ($Finance::Quote::RBA::VERSION, $want_version,
    'VERSION variable');
is (Finance::Quote::RBA->VERSION,  $want_version,
    'VERSION class method');
{ ok (eval { Finance::Quote::RBA->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Finance::Quote::RBA->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#------------------------------------------------------------------------------
# _name_extract_time

foreach my $elem ([ 'Abc def',        'Abc def', '16:00' ],
                  [ 'Abc def (12am)', 'Abc def', '00:00' ],
                  [ 'Abc def (1am)',  'Abc def', '01:00' ],
                  [ 'Abc def (11am)', 'Abc def', '11:00' ],
                  [ 'Abc def (Noon)', 'Abc def', '12:00' ],
                  [ 'Abc def (12pm)', 'Abc def', '12:00' ],
                  [ 'Abc def (1pm)',  'Abc def', '13:00' ],
                  [ 'Abc def (11pm)', 'Abc def', '23:00' ],
                 ) {
  my ($input_name, $want_name, $want_time) = @$elem;

  require Finance::Quote;
  my $fq = Finance::Quote->new('RBA');

  my ($got_name, $got_time)
    = Finance::Quote::RBA::_name_extract_time ($fq, $input_name);
  is ($got_name, $want_name, "name from '$input_name'");
  is ($got_time, $want_time, "name from '$input_name'");
}

#------------------------------------------------------------------------------
# _parse

{ my $html = <<'HERE';
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<body>
<table><tbody>
<caption>Units of Foreign Currencies per Australian Dollar</caption>
<thead>
<tr>
  <td></td>
  <td>02 Jan 2009</td>
  <td>03 Jan 2009</td>
  <td>04 Jan 2009</td>
</tr>
<tr id="USD">
  <td>United States dollar</td>
  <td>0.6810</td>
  <td>0.6840</td>
  <td>0.6830</td>
</tr>
<tr id="TWI">
  <td>Trade Weighted Index (4pm)</td>
  <td>70</td>
  <td>71</td>
  <td>72</td>
</tr>
<tr id="FOO">
  <td>Foo money (Noon)</td>
  <td>100</td>
  <td>101</td>
  <td>102</td>
</tr>
</tbody></table>
</body>
</html>
HERE

  require Finance::Quote;
  require HTTP::Request;
  require HTTP::Response;

  my $req = HTTP::Request->new();
  $req->uri('...');

  my $resp = HTTP::Response->new;
  $resp->request ($req);
  $resp->content($html);
  $resp->content_type('text/html');
  $resp->{'_rc'} = 200;

  my $fq = Finance::Quote->new('RBA');
  my %quotes;
  Finance::Quote::RBA::_parse ($fq, $resp, \%quotes,
                               ['AUDUSD','AUDTWI','AUDFOO']);
  ### %quotes
  is_deeply (\%quotes,
             { "AUDUSD$;success"  => 1,
               "AUDUSD$;method"   => 'rba',
               "AUDUSD$;source"   => 'Finance::Quote::RBA',
               "AUDUSD$;isodate"  => '2009-01-04',
               "AUDUSD$;name"     => 'United States dollar',
               "AUDUSD$;copyright_url" => Finance::Quote::RBA::COPYRIGHT_URL(),
               "AUDUSD$;last"     => '0.6830',
               "AUDUSD$;close"    => '0.6840',  # prev
               "AUDUSD$;date"     => '01/04/2009',
               "AUDUSD$;time"     => '16:00',
               "AUDUSD$;currency" => 'AUDUSD',

               "AUDTWI$;success"  => 1,
               "AUDTWI$;method"   => 'rba',
               "AUDTWI$;source"   => 'Finance::Quote::RBA',
               "AUDTWI$;isodate"  => '2009-01-04',
               "AUDTWI$;name"     => 'Trade Weighted Index',
               "AUDTWI$;copyright_url" => Finance::Quote::RBA::COPYRIGHT_URL(),
               "AUDTWI$;last"     => '72',
               "AUDTWI$;close"    => '71',  # prev
               "AUDTWI$;date"     => '01/04/2009',
               "AUDTWI$;time"     => '16:00',
               "AUDTWI$;currency" => 'AUDTWI',

               "AUDFOO$;success"  => 1,
               "AUDFOO$;method"   => 'rba',
               "AUDFOO$;source"   => 'Finance::Quote::RBA',
               "AUDFOO$;isodate"  => '2009-01-04',
               "AUDFOO$;name"     => 'Foo money',
               "AUDFOO$;copyright_url" => Finance::Quote::RBA::COPYRIGHT_URL(),
               "AUDFOO$;last"     => '102',
               "AUDFOO$;close"    => '101',  # prev
               "AUDFOO$;date"     => '01/04/2009',
               "AUDFOO$;time"     => '12:00',
               "AUDFOO$;currency" => 'AUDFOO',
             },
             '_parse() on sample html');

  # in the parsed quotes
  my @q_labels = map { key_to_label($_) } keys %quotes;
  @q_labels = do { my %uniq; @uniq{@q_labels} = (); keys %uniq };
  @q_labels = sort @q_labels;

  # in the rba labels() code
  my %sub_labels = Finance::Quote::RBA::labels();
  my @rba_labels = @{$sub_labels{'rba'}};
  @rba_labels = grep {$_ ne 'errormsg'} @rba_labels;
  @rba_labels = sort @rba_labels;

  is_deeply (\@q_labels,
             \@rba_labels,
             'labels() matches what _parse() returns');
}

sub key_to_label {
  my ($str) = @_;
  $str =~ s/.*\Q$;\E//;
  return $str;
}
exit 0;
