Finance::Symbology
===================
#### Common US Stock market convention swapper / tester

### SYNOPSIS

    use Finance::Symbology;

    my $converter = Finance::Symbology->new();

    my $symbols = [ 'AAPL WI', 'C PR', 'TEST A' ];
    my $symbol = 'TEST A';

    # Valid convention options CMS, CQS, NASIntegrated

    # Fidessa convention sheet is included but not implemented as the spec given had a bug

    my $converted_symbols =  $converter->convert($symbols, 'CMS', 'CQS' );
    my $converted_symbol  = $converter->convert($symbol, 'CMS', 'CQS' );


    my $what_is = $converter->what($symbol);

### DESCRIPTION

Finance::Symbology is a module that can convert valid symbol syntaxes across 
popular formats from the US Domestic markets. Converter can also test symbols
to provide information about it, such as type, class, and underyling symbol

### USAGE

#### convert(symbol(s), FROM, TO)

Converts a symbol from a convetion to another convention

##### Example:

    $converter->convert('AAPL PR', 'CMS', 'CQS');

    output: AAPLp

    $converter->convert(['AAPL PR', 'C PRA'], 'CMS', 'CQS');

    output: ['AAPLp', 'CpA'];


#### what(symbol)

Tests a symbol of any convention and breaks down its convention if valid


##### Example:

    $converter->what('AAPLp');

    output:

    'CQS' => {
        'symbol' => 'AAPL',
        'suffix' => 'p',
        'type' => 'Preferred'
    }

#### Author

George Tsafas <elb0w@elbowrage.com>


#### Support

elb0w on irc.freenode.net #perl



