package Font::Fontconfig;

use strict;
use warnings;

use Font::Fontconfig::Pattern;

our $VERSION = '0.01';

# list
#
# Returns a list of `Font::Fontconfig::Pattern`s that match the search criteria,
# or all installed ones if no criteria are given
#
sub list {
    my $class = shift;
    my @options = @_;
    
    my @results = _execute_list( @options );
    
    return map {
        Font::Fontconfig::Pattern->new_from_string( $_ )
    } @results
}



sub _execute_list {
    my @options = @_;
    
    my $filters = _list_filters( \@options );
    my $include = _list_include( \@options );
    
    my $command =
        join( q{ }, 'fc-list', $filters )
        .
        q{ : }
        .
        join( q{ }, @$include )
    ;
    
    my @results = _execute( $command );
    
    return @results
}



sub _execute {
    my $command = shift;

    my @results = `$command`;
    
    return @results
}



sub _list_filters {
    my $options = shift;
    
    my $font_family = _shell_escape(shift @$options );
    
    return $font_family
}



sub _list_include {
    return [ @Font::Fontconfig::Pattern::_internal_attributes ]
}



sub _shell_escape {
    my $text = shift // '';
    
    $text =~ s/ /\\ /g;
    
    return $text
}



1;
