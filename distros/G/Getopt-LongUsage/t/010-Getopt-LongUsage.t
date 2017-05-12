# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Getopt-LongUsage.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 16;
BEGIN { use_ok('Getopt::LongUsage') };
use_ok('Getopt::Long');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $glu = Getopt::LongUsage->new();

ok ( defined($glu) && ref $glu eq 'Getopt::LongUsage', 'new()' );

my $getoptlongconf = [
                \%options,
                'h|help',
                'isAvailable',
                'color=s',
                't|type=s',
                'secretAttr:i',
                'cityGrown=s@' ];
my $descriptions = [
                'isAvailable'   , "The apple type is available",
                'color'         , "The color of this apple type",
                'type'          , "The type of apple, i.e. Gala",
                'secretAttr'    , "You should not see this attribute",
                'cityGrown'     , "The city(s) in which this apple is grown",
                'help'          , "This help message" ];
my $usagetext = $glu->GetLongUsage (
        header          => "This is the header",
        footer          => "This is the footer",
        cli_use         => "This is the cli_use",
        descriptions    => $descriptions,
        Getopt_Long     => $getoptlongconf,
        hidden_opts     => [qw(secretAttr)]
);

# Test the usage message - parameter
ok ( ($usagetext =~ /\-\-cityGrown/) , 'GetLongUsage() - parameter' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - description
ok ( ($usagetext =~ /The city\(s\) in which this apple is grown/) , 'GetLongUsage() - description' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - hidden parameter
ok ( ($usagetext !~ /\-\-secretattr/i) , 'GetLongUsage() - hidden parameter' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - hidden description
ok ( ($usagetext !~ /You should not see this attribute/i) , 'GetLongUsage() - hidden description' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - header
ok ( ($usagetext =~ /This is the header/) , 'GetLongUsage() - header' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - footer
ok ( ($usagetext =~ /This is the footer/) , 'GetLongUsage() - footer' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - cli_use
ok ( ($usagetext =~ /This is the cli_use/) , 'GetLongUsage() - cli_use' ) || diag explain ( $getoptlongconf, $usagetext );

$usagetext = $glu->GetLongUsage (
        header          => "This is the header",
        footer          => "This is the footer",
        cli_use         => "This is the cli_use",
        descriptions    => $descriptions,
        Getopt_Long     => $getoptlongconf,
        hidden_opts     => [qw(secretAttr)],
        format          => [ tab => 4, indent => 5 ]
);

# Test the usage message - format:tab
ok ( ($usagetext =~ /\s{4}\-\-isAvailable\s{4}The apple type is available/) , 'GetLongUsage() - format:tab' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - format:indent
ok ( ($usagetext =~ /^\s{5}This is the header/) , 'GetLongUsage() - format:indent' ) || diag explain ( $getoptlongconf, $usagetext );

$usagetext = $glu->GetLongUsage (
        header          => "This is the header",
        footer          => "This is the footer",
        cli_use         => "This is the cli_use",
        descriptions    => $descriptions,
        Getopt_Long     => $getoptlongconf,
        hidden_opts     => [qw(secretAttr)],
        format          => [ tab => 4, indent => 5, longprefix => "ZZ", shortprefix => "A" ]
);

# Test the usage message - format:shortprefix
ok ( ($usagetext =~ /\s{4}ZZcolor\s{4}/) , 'GetLongUsage() - format:shortprefix' ) || diag explain ( $getoptlongconf, $usagetext );

# Test the usage message - format:lomgprefix
ok ( ($usagetext =~ /\s{4}At\, ZZtype\s{4}/) , 'GetLongUsage() - format:longprefix' ) || diag explain ( $getoptlongconf, $usagetext );

##
# Testing usage
# 1. with no descriptions
# 2. no option but with description
##

my %nd_options;
my $nd_getoptlongconf = [
                \%options,
                'h|help',
                'isAvailable',
                'color=s',
                't|type=s',
                'cityGrown=s@' ];
my $nd_usagetext = $glu->GetLongUsage (
        Getopt_Long     => $nd_getoptlongconf,
);

# Test the usage message, without description - parameter
ok ( ($nd_usagetext =~ /\-\-cityGrown/) , 'GetLongUsage() - call with no descriptions' ) || diag explain ( $nd_getoptlongconf, $nd_usagetext );


my $nd_stderr = '';
{
    local *STDERR;
    open STDERR, '>', \$nd_stderr;

    $nd_usagetext = $glu->GetLongUsage (
        descriptions    => ["notdefinedingetopt_long" => "option in descriptions, but not in Getopt_Long"],
        Getopt_Long     => $nd_getoptlongconf,
    );

    close STDERR;
}

# Test the usage message, having an option in description, but not Getopt_Long - parameter
ok ( ($nd_stderr =~ /Item \"notdefinedingetopt\_long\" in descriptions/) , 'GetLongUsage() - option not in Getop_Long, but in descriptions' ) || diag explain ( $nd_getoptlongconf, $nd_usagetext );
