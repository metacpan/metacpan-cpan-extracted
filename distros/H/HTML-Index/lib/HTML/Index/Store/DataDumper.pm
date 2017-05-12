package HTML::Index::Store::DataDumper;

#------------------------------------------------------------------------------
#
# Modules
#
#------------------------------------------------------------------------------

use Data::Dumper;
use File::Path;
use Carp;

require HTML::Index::Store;
use vars qw( @ISA );
@ISA = qw( HTML::Index::Store );

#------------------------------------------------------------------------------
#
# Initialization public method
#
#------------------------------------------------------------------------------

sub init
{
    my $self = shift;

    croak "No DB\n" unless defined $self->{DB};
    $self->{MODE} ||= 'rw';
    unless ( -d $self->{DB} )
    {
        mkpath( $self->{DB} ) or croak "can't mkpath ", $self->{DB}, ": $!\n";
    }
    $self->SUPER::init();
    return $self;
}

sub create_table
{
    my $self = shift;
    my $table = shift;

    my $path = $self->{DB} . "/$table.pl";
    if ( -e $path )
    {
        if ( $self->{REFRESH} ) { unlink( $path ); }
        else { $self->{$table} = do $path; }
    }
    $self->{PATH}{$table} = $path;
}

#------------------------------------------------------------------------------
#
# Destructor
#
#------------------------------------------------------------------------------

sub DESTROY
{
    my $self = shift;

    return unless $self->{MODE} =~ /w/;
    for my $table ( keys %{$self->{PATH}} )
    {
        my $hash = $self->{$table};
        my $path = $self->{PATH}{$table};
        open( FH, ">$path" ) or die "Can't write to $path\n";
        print FH Dumper( $hash );
        close( FH );
    }
}

#------------------------------------------------------------------------------
#
# True
#
#------------------------------------------------------------------------------

1;

__END__

=head1 NAME

HTML::Index::Store::DataDumper - subclass of
L<HTML::Index::Store|HTML::Index::Store> using Data::Dumper.

=head1 SYNOPSIS

    my $store = HTML::Index::Store::DataDumper->new( 
        DB => $path_to_data_dumper_file_directory
    );

=head1 DESCRIPTION

This module is a subclass of the L<HTML::Index::Store|HTML::Index::Store>
module, that uses Data::Dumper files to store the inverted index.

=head1 SEE ALSO

=over 4

=item L<HTML::Index|HTML::Index>
=item L<HTML::Index::Store|HTML::Index::Store>

=back

=head1 AUTHOR

Ave Wrigley <Ave.Wrigley@itn.co.uk>

=head1 COPYRIGHT

Copyright (c) 2001 Ave Wrigley. All rights reserved. This program is free
software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut
