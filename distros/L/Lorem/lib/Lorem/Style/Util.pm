package Lorem::Style::Util;
{
  $Lorem::Style::Util::VERSION = '0.22';
}
use strict;
use warnings;
use Carp 'confess';

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(parse_border parse_margin parse_padding parse_style);


sub parse_style {
    my $input = shift;
    my %parsed;
    my @pairs = split /;/, $input;
    
    for ( @pairs ) {
        next if /^\s*$/; 
        my ( $attr, $value ) = split /:/, $_;
        $attr =~ s/-/_/g;
        $_ =~ s/^\s*//g for $attr, $value;
        $_ =~ s/\s*$//g for $attr, $value;
        $parsed{ $attr } = $value;
    }
    
   
    return \%parsed;
}

sub parse_border {
    my $input = shift;
    my %parsed;
    @parsed{qw/width style color/} = $input =~ /^\s*(thin|thick|medium)?\s*(none|hidden|dotted|dashed|solid|groove|ridge|inset|outset)?\s*(#\d{1,6}|[-_a-z]+)?\s*$/;
    return \%parsed;
}

sub parse_margin {
    my $input = shift;
    my @input = $input =~ /^\s*(\d+)?\s*(\d+)?\s*(\d+)?\s*(\d+)?\s*$/;

    my %parsed;
    if ( defined $4 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $3, $4);
    }
    elsif ( defined $3 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $3, $2);
    }
    elsif ( defined $2 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $1, $2);
    }
    elsif ( defined $1 ) {
        @parsed{qw/top right bottom left/} = ($1, $1, $1, $1);
    }
    
    return \%parsed;
}

sub parse_padding {
    my $input = shift;
    my @input = $input =~ /^\s*(\d+)?\s*(\d+)?\s*(\d+)?\s*(\d+)?\s*$/;

    my %parsed;
    if ( defined $4 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $3, $4);
    }
    elsif ( defined $3 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $3, $2);
    }
    elsif ( defined $2 ) {
        @parsed{qw/top right bottom left/} = ($1, $2, $1, $2);
    }
    elsif ( defined $1 ) {
        @parsed{qw/top right bottom left/} = ($1, $1, $1, $1);
    }
    
    return \%parsed;
}






1;
