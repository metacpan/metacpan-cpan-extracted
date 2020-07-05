# -*- perl -*-

# t/010_parse_compose_loglines.t - check module loading and parse/compose log lines

use Test::More tests => 15;
use Mail::Exim::MainLogParser;

# BEGIN { use_ok( 'Mail::Exim::MainLogParser' ); }

my $object = Mail::Exim::MainLogParser->new ();

my $count=0;
my $total=0;
my $line_description="";
my $checkIfParsedCorrectly=sub ($) {
    my $parsed = shift;
    my $message = "unknown";
    return (0,"Not a HASH")
             unless (ref $parsed eq "HASH");
    return (0,"Missing date or time")
             if ((!exists $parsed->{'date'}) &&
                 (!exists $parsed->{'time'}));
    # checking lins with exim id
    # date time eximid flag address
    return 1 if ((exists $parsed->{'eximid'}) &&
                 (exists $parsed->{'flag'}) &&
                 (exists $parsed->{'address'}));
    # date time eximid ** message
    return 1 if ((exists $parsed->{'eximid'}) &&
                 (exists $parsed->{'flag'}) &&
                 ($parsed->{'flag'} eq '**') &&
                 (exists $parsed->{'message'}));
    # date time eximid F=V
    return 1 if ((exists $parsed->{'eximid'}) &&
                 (ref $parsed->{'args'} eq "ARRAY") &&
                 (scalar @{$parsed->{'args'}} >= 1) &&
                 (!exists $parsed->{'flag'}));
    # date time eximid message
    return 1 if ((exists $parsed->{'eximid'}) &&
                 (exists $parsed->{'message'}) &&
                 (!exists $parsed->{'flag'}));
    return (0,"eximid exists without flag, address, or message")
             if (exists $parsed->{'eximid'});
    # checking lins without exim id
    # date time H=value
    return 1 if ((!exists $parsed->{'eximid'}) &&
                 (ref $parsed->{'args'} eq "ARRAY") &&
                 (scalar @{$parsed->{'args'}} >= 1) &&
                 (exists $parsed->{'args'}->[0]->{'H'}));
    # date time message
    return 1 if ((!exists $parsed->{'eximid'}) &&
                 (exists $parsed->{'message'}));
    return (0,"uncaught/unexpected log line format");
};
open(EXIMLOG,"cat t/010_parse_compose_loglines.log |");
while (my $line = <EXIMLOG>) {
    chomp ($line);
    #print ">> $line\n";
    next unless length $line >= 1;
    if ($line =~ /^\#description:\s?(.+)/) {
        $line_description=(" ".$1);
        next;
    }
    $count++;
    # Test Parse
    my $parsed = $object->parse($line) || undef;
    if ((length $line_description < 1) && (ref $parsed eq "HASH")) {
        $line_description.=(" ".$parsed->{'flag'})     if exists $parsed->{'flag'};
        $line_description.=(" ".$parsed->{'address'})  if exists $parsed->{'address'};
        $line_description.=(" ".$parsed->{'message'})  if exists $parsed->{'message'};
    }
    my ($trueParsed,$parseError) = $checkIfParsedCorrectly->($parsed);
    my $reasonDesc=$parseError; # Will overwrite later as needed
    my $trueComposed = 0;
    my $composed;
    if ($trueParsed) {
        # Test Compose
        $composed = $object->compose($parsed) || undef;
        # Parse/Compose cuts off any trailing whitespace, do the same to $line
        $line =~ s/\s$//;
        $trueComposed = ("$composed" eq "$line");
        unless ($trueComposed) {
            $reasonDesc = ("compose test failed");
        }
    } else {
        $reasonDesc = ("parse test failed: ".$parseError."; compose test skipped");
    }

    ok ( ($trueParsed && $trueComposed),
         ("MainLogParser parse/compose - ($count)".$line_description)
         ) || diag explain ( ("Reason: ".$reasonDesc."\noriginal: ".$line."\n"), ("composed: ".$composed."\n"), $parsed );

    $line_description="";
    $total++;
}
close(EXIMLOG);

#isa_ok ($count, $total);


