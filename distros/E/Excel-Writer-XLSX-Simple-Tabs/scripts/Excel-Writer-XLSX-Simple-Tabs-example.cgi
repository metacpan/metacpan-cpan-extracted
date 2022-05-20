#!/usr/bin/perl

=head1 NAME

Excel-Writer-XLSX-Simple-Tabs-example.cgi - Excel::Writer::XLSX::Simple::Tabs Simple CGI Example

=cut

use strict;
use warnings;
use Excel::Writer::XLSX::Simple::Tabs;
my $ss=Excel::Writer::XLSX::Simple::Tabs->new;
my @data=(
          ["Heading1", "Heading2"],
          ["data1",    "data2"   ],
          ["data3",    "data4"   ],
         );
$ss->add(Tab1=>\@data, Tab2=>\@data);
print $ss->header(filename=>"filename.xls"), $ss->content;
