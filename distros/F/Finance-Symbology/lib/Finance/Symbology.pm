package Finance::Symbology;

use strict;
use warnings;

use Finance::Symbology::Convention::CQS;
use Finance::Symbology::Convention::CMS;
use Finance::Symbology::Convention::Fidessa;
use Finance::Symbology::Convention::NASDAQ::Integrated;

BEGIN {

    our $VERSION = 0.4;

}


sub new {
    my ($class, $info) = @_;
   
    my $self = {
        Check => {
            CQS     => sub { my $x = shift; return Finance::Symbology::Convention::CQS->check($x); },
            CMS     => sub { my $x = shift; return Finance::Symbology::Convention::CMS->check($x); },
            FIDESSA => sub { my $x = shift; return Finance::Symbology::Convention::Fidessa->check($x); },
            NASINTEGRATED => sub { my $x = shift; return Finance::Symbology::Convention::NASDAQ::Integrated->check($x); }
        }, 
        Convert => {
            CQS => sub { my $x = shift; return Finance::Symbology::Convention::CQS->convert($x); },
            CMS => sub { my $x = shift; return Finance::Symbology::Convention::CMS->convert($x); },
            FIDESSA => sub { my $x = shift; return Finance::Symbology::Convention::Fidessa->convert($x); },
            NASINTEGRATED => sub { my $x = shift; return Finance::Symbology::Convention::NASDAQ::Integrated->convert($x); }
        }
    };

    bless ($self, $class);
    return $self;
}

sub what {
    my ($self, $symbol) = @_;
    
    my $returnObj;

    $returnObj->{CQS} = $self->{Check}{CQS}->($symbol);
    delete $returnObj->{CQS} unless defined $returnObj->{CQS};

    $returnObj->{CMS} = $self->{Check}{CMS}->($symbol);
    delete $returnObj->{CMS} unless defined $returnObj->{CMS};

    $returnObj->{FIDESSA} = $self->{Check}{FIDESSA}->($symbol);
    delete $returnObj->{FIDESSA} unless defined $returnObj->{FIDESSA};
    
    $returnObj->{NASINTEGRATED} = $self->{Check}{NASINTEGRATED}->($symbol);
    delete $returnObj->{NASINTEGRATED} unless defined $returnObj->{NASINTEGRATED};

    return $returnObj;
}

sub convert {
    my ($self, $symbols, $from, $to) = @_;


    if (ref $symbols eq 'ARRAY') {
        my @convertedsymbols; 
        for my $symbol (@{$symbols}){
            if ($symbol =~ m/^[A-Z]+$/) {
                push @convertedsymbols, $symbol;
            } else {
                my $fromobj = $self->{Check}{uc($from)}->($symbol);
                return "Invalid format for $from \($symbol\)" unless defined $fromobj;
                my $toobj = $self->{Convert}{uc($to)}->($fromobj);
                push @convertedsymbols, $toobj;
            }
        }
        return @convertedsymbols;
    } else {
        if ($symbols =~ m/^[A-Z]+$/) {
            return $symbols;
        } else {
            my $fromobj = $self->{Check}{uc($from)}->($symbols);
            return "Invalid format for $from \($symbols\)" unless defined $fromobj;
            my $toobj = $self->{Convert}{uc($to)}->($fromobj);
            return $toobj;
        }
    }
}



1;



=pod

=head1 NAME

Finance::Symbology - Common US Stock market convention swapper / tester

=head1 SYNOPSIS

    use Finance::Symbology;

    my $converter = Finance::Symbology->new();

    my $symbols = [ 'AAPL WI', 'C PR', 'TEST A' ];
    my $symbol = 'TEST A';

    # Valid convention options CMS, CQS, NASINTEGRATED, Fidessa

    my $converted_symbols =  $converter->convert($symbols, 'CMS', 'CQS' );
    my $converted_symbol  = $converter->convert($symbol, 'CMS', 'CQS' );


    my $what_is = $converter->what($symbol);

=head1 DESCRIPTION

Finance::Symbology is a module that can convert valid symbol syntaxes across 
popular formats from the US Domestic markets. Converter can also test symbols
to provide information about it, such as type, class, and underyling symbol

=head1 USAGE

=head2 convert(symbol(s), FROM, TO)

Converts a symbol from a convetion to another convention also works with lists

Example:

    $converter->convert('AAPL PR', 'CMS', 'CQS');

    output: AAPLp

    $converter->convert(['AAPL PR', 'C PRA'], 'CMS', 'CQS');

    output: ['AAPLp', 'CpA'];


=head2 what(symbol)

Tests a symbol of any convention and breaks down its convention if valid


Example:

    $converter->what('AAPLp');

    output:

    'CQS' => {
        'symbol' => 'AAPL',
        'suffix' => 'p',
        'type' => 'Preferred'
    }

=head1 Author

George Tsafas <elb0w@elbowrage.com>

=head1 Support

elb0w on irc.freenode.net #perl


=cut

__END__

