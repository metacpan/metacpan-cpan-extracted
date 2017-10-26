package ETL::Yertl::Util;
our $VERSION = '0.036';
# ABSTRACT: Utility functions for Yertl modules

#pod =head1 SYNOPSIS
#pod
#pod =head1 DESCRIPTION
#pod
#pod =head1 SEE ALSO
#pod
#pod =cut

use ETL::Yertl;
use Exporter qw( import );
use Module::Runtime qw( use_module compose_module_name );

our @EXPORT_OK = qw(
    load_module pairs pairkeys firstidx
);

#pod =sub load_module
#pod
#pod     $class = load_module( format => $format );
#pod     $class = load_module( protocol => $proto );
#pod     $class = load_module( database => $db );
#pod
#pod Load a module of the given type with the given name. Throws an exception if the
#pod module is not found or the module cannot be loaded.
#pod
#pod This function should be used to load modules that the user requests. The error
#pod messages are suitable for user consumption.
#pod
#pod =cut

sub load_module {
    my ( $type, $name ) = @_;

    die "$type is required\n" unless $name;
    my $class = eval { compose_module_name( 'ETL::Yertl::' . ucfirst $type, $name ) };
    if ( $@ ) {
        die "Unknown $type '$name'\n";
    }

    eval {
        use_module( $class );
    };
    if ( $@ ) {
        if ( $@ =~ /^Can't locate \S+ in \@INC/ ) {
            die "Unknown $type '$name'\n";
        }
        die "Could not load $type '$name': $@";
    }

    return $class;
}

#pod =sub pairs
#pod
#pod     my @pairs = pairs @array;
#pod
#pod Return an array of arrayrefs of pairs from the given even-sized array.
#pod
#pod =cut

# This duplicates List::Util pair, but this is not included in Perl 5.10
sub pairs(@) {
    my ( @array ) = @_;
    my @pairs;
    while ( @array ) {
        push @pairs, [ shift( @array ), shift( @array ) ];
    }
    return @pairs;
}

#pod =sub pairkeys
#pod
#pod     my @keys = pairkeys @array;
#pod
#pod Return the first item of every pair of items in an even-sized array.
#pod
#pod =cut

# This duplicates List::Util pairkeys, but this is not included in Perl 5.10
sub pairkeys(@) {
    return map $_[$_], grep { $_ % 2 == 0 } 0..$#_;
}

#pod =sub firstidx
#pod
#pod     my $i = firstidx { ... } @array;
#pod
#pod Return the index of the first item that matches the code block, or C<-1> if
#pod none match
#pod
#pod =cut

# This duplicates List::Util firstidx, but this is not included in Perl 5.10
sub firstidx(&@) {
    my $code = shift;
    for my $i ( 0 .. @_ ) {
        local $_ = $_[ $i ];
        return $i if $code->();
    }
    return -1;
}

1;

__END__

=pod

=head1 NAME

ETL::Yertl::Util - Utility functions for Yertl modules

=head1 VERSION

version 0.036

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES

=head2 load_module

    $class = load_module( format => $format );
    $class = load_module( protocol => $proto );
    $class = load_module( database => $db );

Load a module of the given type with the given name. Throws an exception if the
module is not found or the module cannot be loaded.

This function should be used to load modules that the user requests. The error
messages are suitable for user consumption.

=head2 pairs

    my @pairs = pairs @array;

Return an array of arrayrefs of pairs from the given even-sized array.

=head2 pairkeys

    my @keys = pairkeys @array;

Return the first item of every pair of items in an even-sized array.

=head2 firstidx

    my $i = firstidx { ... } @array;

Return the index of the first item that matches the code block, or C<-1> if
none match

=head1 SEE ALSO

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
