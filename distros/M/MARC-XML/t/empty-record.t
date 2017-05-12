use strict;
use warnings;
use Test::More tests => 4;
use MARC::Record;
use MARC::File::XML;
use MARC::Batch;

foreach my $file (qw{t/empty-record.xml t/empty-record-2.xml}) {
    open my $IN, '<', $file;
    my $xml = join('', <$IN>);
    close $IN;
    my $r;
    eval { $r = MARC::Record->new_from_xml($xml, 'UTF-8'); };
    ok(!$@, "do not throw an exception when parsing an empty record ($file)");
    my @fields = $r->fields();
    is(@fields, 0, "MARC::Record object is empty ($file)");
}
