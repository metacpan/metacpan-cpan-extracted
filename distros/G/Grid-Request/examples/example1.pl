#!/usr/bin/perl

use strict;
use Grid::Request;
use Log::Log4perl ':easy';

my $logger = get_logger;

my $request = Grid::Request->new (
                  opsys      => "Linux",
                  initialdir => "/path/to/initialdir",
                  project    => "someproject",
                  times      => "926",
                  priority   => "1",
                  command    => "/bin/ls",
                  error      => "/tmp/test.err",
                  output     => "/tmp/test.out",
                  input      => "/tmp/test.in",
              );

$request->add_param("/tmp");

# Instead of submitting the job. Let's examine the XML that is
# generated.
my $xml = $request->to_xml;
print "$xml";

exit;
