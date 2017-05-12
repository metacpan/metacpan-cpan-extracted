package Filter::Object::Simple;

use 5.008008;
use strict;
use warnings;
use Filter::Simple;
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Preloaded methods go here.
FILTER {
    s/%([a-z_]+?)\.(exists|defined|delete)\((.*?)\)/$2(\$$1\{$3\})/isg;
    s/(%[a-z_]+?)\.(each|keys|values)(\(\s*\))?/$2 $1 /isg;
};

FILTER {
    s/(@[a-z_]+?)\.(pop|reverse)\(\s*\)/$2($1)/isg;
    s/(@[a-z_]+?)\.(unshift|push|splice)\((.+?)\)/$2( $1 , $3 )/isg;
    s/([@%][a-z_]+?)  # function name
        \.(map|grep)\(
            (.+?)  # parameter
        \)/$2 $3 $1/isxg;
};


1;
__END__

=head1 NAME

Filter::Object::Simple - Binding the built-in functions with Array,Hash.

=head1 SYNOPSIS

    use Filter::Object::Simple;

    my %hash = ( 
        'abc' => 123, 
        'cba' => 456,
        'foo' => 'bar',
    );

    my @array = (1,2,3,4,5);

    %hash.exists( 'abc' );
    %hash.defined( 'cba' ) ;
    %hash.delete( 'abc' ) ;

    @keys = %hash.keys;
    @values = %hash.values;

    @keys = %hash.keys();
    @values = %hash.values();

    my @r_array = @array.reverse() ;

    @array.push(10) ;

    my $value = @array.pop() ;
    @array.unshift(10) ;

    @array.grep({ 
        !/1/ 
    });

    @array.map({ 
            $_++; 
    });

    @array.splice(3);


=head1 DESCRIPTION

This is a source filter , which provides a simple way to manipulate data of Hash and Array with built-in functions.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Filter::Simple
Filter::Simple::Compile

=head1 AUTHOR

Cornelius, E<lt>cornelius@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Cornelius

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
