package Koha::Contrib::Tamil::Zebra::Clouder;
# ABSTRACT: Class generating keywords clouds from Koha Zebra indexes
$Koha::Contrib::Tamil::Zebra::Clouder::VERSION = '0.066';
use Moose;
use Carp;

extends 'AnyEvent::Processor';

my $MAX_OCCURENCE = 1000000000;

has koha => ( is => 'rw', isa => 'Koha::Contrib::Tamil::Koha' );

has index => (
    is => 'rw',
    isa => 'Str',
    trigger => sub {
        my ($self, $name) = @_;
        my $zc = $self->koha->zbiblio;
        eval {
            $zc->scan_pqf('@attr 1=' . $name . ' @attr 4=1 @attr 6=3 "a"');
        };
        croak "Invalid Zebra index: ", $name if $@;
        return $name;
    }
);

has levels_cloud => ( 
    is => 'rw', 
    isa => 'Int',
    default => 24
);

has max_terms => ( 
    is => 'rw', 
    isa => 'Int'
);

has number_of_terms => ( 
    is => 'rw', 
    isa => 'Int', 
    default => 0
); 

has terms => ( 
    is => 'rw', 
    isa => 'ArrayRef'
);

has min_occurence_index => (
    is => 'rw', 
    isa => 'Int', 
    default => -1
);

has min_occurence => ( 
    is => 'rw', 
    isa => 'Int', 
    default => 0
);

has from => (
    is => 'rw', 
    isa => 'Str', 
    default => '0'
);


#
# run 
#   Scan zebra index and populate an array of top terms
#
# PARAMETERS:
#   $max_terms    Max number of top terms
#
# RETURN:
#   A 4-dimensionnal array in $self->{terms}
#   [0] term
#   [1] term number of occurences
#   [2] term proportional relative weight in terms set E[0-1]
#   [3] term logarithmic relative weight E [0-levels_cloud]
#   
#   This array is sorted alphabetically by terms ([0])
#   It can be easily sorted by occurences:
#     @t = sort { $a[1] <=> $a[1] } @{$self->{top_terms}};
#
sub run {
    my $self = shift;
    $self->max_terms( shift );    
    $self->SUPER::run();
}


############################################################################
# Usage :   $zebra_index->process()
# Purpose : Do a Zebra ZOOM scan and keep top keywords
# Returns : TRUE(1) if end of index isn't reached, otherwise FALSE(0)
#
sub process {    
    my $self                = shift;
    my $max_terms           = $self->max_terms;    
    my $levels_cloud        = $self->levels_cloud;
    my $zbiblio             = $self->koha->zbiblio;
    my $number_of_terms     = $self->number_of_terms;
    my @terms               = $self->terms ? @{$self->terms} : ();
    my $min_occurence_index = $self->min_occurence_index;
    my $min_occurence       = $self->min_occurence;
    my $from                = $self->from;

    my $ss;
    SCAN:
    while (1) {
        eval {
            #print "$from\n" if $verbose;
            $from =~ s/\"/\\\"/g;
            my $query = '@attr 1=' . $self->index . ' @attr 4=1 @attr 6=3 "'
                        . $from . 'a"';
            $ss = $zbiblio->scan_pqf( $query );
        };
        if ($@) {
            chop $from;
            next SCAN;
        }
        last SCAN;
    }
    $ss->option( rpnCharset => 'UTF-8' );
    if ( $ss->size() == 0 ) { # End
        # Sort array of array by terms weight
        #@terms = sort { @{$a}[1] <=> @{$b}[1] } @terms;
    
        # A relatif weight to other set terms is added to each term
        my $min     = $terms[0][1];
        my $log_min = log( $min );
        my $max     = $terms[$#terms][1];
        my $log_max = log( $max );
        my $delta   = $max - $min;
        $delta = 1 if $delta == 0; # Very unlikely
        my $factor;
        if ($log_max - $log_min == 0) {
            $log_min = $log_min - $levels_cloud;
            $factor = 1;
        } 
        else {
            $factor = $levels_cloud / ($log_max - $log_min);
        }
    
        foreach my $term ( @terms ) {
            my $count      = @$term[1];
            my $weight     = ( $count - $min ) / $delta;
            my $log_weight = int( (log($count) - $log_min) * $factor);
            push @$term, $weight, $log_weight;
        }
        # Sort array of array by terms alphabetical order
        @terms = sort { @{$a}[0] cmp @{$b}[0] } @terms;
        $self->terms( \@terms );
        return 0;
    }
    else {
        my $term = '';
        my $occ = 0;
        $self->count( $self->count + $ss->size() );
        for my $index ( 0..$ss->size()-1 ) {
            ($term, $occ) = $ss->display_term($index);
            if ( $number_of_terms < $max_terms ) {
                push( @terms, [ $term, $occ ] ); 
                ++$number_of_terms;
                if ( $number_of_terms == $max_terms ) {
                    $min_occurence = $MAX_OCCURENCE;
                    for (0..$number_of_terms-1) {
                        my @term = @{ $terms[$_] };
                        if ( $term[1] <= $min_occurence ) {
                            $min_occurence       = $term[1];
                            $min_occurence_index = $_;
                        }
                    }
                }
            }
            else {
                if ( $occ > $min_occurence) {
                    @{ $terms[$min_occurence_index] }[0] = $term;
                    @{ $terms[$min_occurence_index] }[1] = $occ;
                    $min_occurence = $MAX_OCCURENCE;
                    for (0..$max_terms-1) {
                        my @term = @{ $terms[$_] };
                        if ( $term[1] <= $min_occurence ) {
                            $min_occurence       = $term[1];
                            $min_occurence_index = $_;
                        }
                    }
                }
            }
        }
        $self->number_of_terms(     $number_of_terms     ); 
        $self->terms(               \@terms              );
        $self->min_occurence_index( $min_occurence_index );
        $self->min_occurence(       $min_occurence       );
        $self->from(                $term                );
        return 1;
    }
}


sub process_message {
    my $self = shift;
    my $from = $self->from;
    $from = substr($from, 0, 70) . "..." if length($from) > 70;
    print sprintf("  %#6d", $self->count), " - ", $from, "\n";    
}


#
# Returns a HTML version of index top terms formated
# as a 'tag cloud'.
#
sub html_cloud {
    my $self = shift;
    my $koha_index = shift;
    my $withcss = shift;
    my @terms = @{ $self->terms() };
    my $html = '';
    if ( $withcss ) {
        $html = <<EOS;
<style>
.subjectcloud {
    text-align:  center; 
    line-height: 16px; 
    margin: 20px;
    background: #f0f0f0;
    padding: 3%;
}
.subjectcloud a {
    font-weight: lighter;
    text-decoration: none;
}
span.tagcloud0  { font-size: 12px;}
span.tagcloud1  { font-size: 13px;}
span.tagcloud2  { font-size: 14px;}
span.tagcloud3  { font-size: 15px;}
span.tagcloud4  { font-size: 16px;}
span.tagcloud5  { font-size: 17px;}
span.tagcloud6  { font-size: 18px;}
span.tagcloud7  { font-size: 19px;}
span.tagcloud8  { font-size: 20px;}
span.tagcloud9  { font-size: 21px;}
span.tagcloud10 { font-size: 22px;}
span.tagcloud11 { font-size: 23px;}
span.tagcloud12 { font-size: 24px;}
span.tagcloud13 { font-size: 25px;}
span.tagcloud14 { font-size: 26px;}
span.tagcloud15 { font-size: 27px;}
span.tagcloud16 { font-size: 28px;}
span.tagcloud17 { font-size: 29px;}
span.tagcloud18 { font-size: 30px;}
span.tagcloud19 { font-size: 31px;}
span.tagcloud20 { font-size: 32px;}
span.tagcloud21 { font-size: 33px;}
span.tagcloud22 { font-size: 34px;}
span.tagcloud23 { font-size: 35px;}
span.tagcloud24 { font-size: 36px;}
</style>
<div class="subjectcloud">
EOS
    }
    for (0..$#terms) {
        my @term = @{ $terms[$_] };
        my $uri = $term[0];
        $uri =~ s/\(//g;
        #print "  0=", $term[0]," - 1=", $term[1], " - 2=", $term[2], " - 3=", $term[3],"\n";
        $html = $html
            . '<span class="tagcloud'
            . $term[3]
            . '">'
            . '<a href="/cgi-bin/koha/opac-search.pl?q='
            . $koha_index
            . '%3A'
            . $uri
            . '">'
            . $term[0]
            . "</a></span>\n";
    }
    $html .= "</div>\n";
    return $html;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Koha::Contrib::Tamil::Zebra::Clouder - Class generating keywords clouds from Koha Zebra indexes

=head1 VERSION

version 0.066

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2021 by Fréderic Démians.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
