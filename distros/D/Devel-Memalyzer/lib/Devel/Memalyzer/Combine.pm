package Devel::Memalyzer::Combine;
use strict;
use warnings;

use IO qw/Handle File Pipe/;

our @EXPORT_OK = qw/combine/;
use base 'Exporter';

sub combine {
    my ( $dest, %specs ) = @_;
    die( "No headers found" )
        unless -e "$dest.head";
    die( "No data found" )
        unless -e "$dest.raw";

    open( my $header_file, '<', "$dest.head" ) || die( "header error: $!" );
    open( my $data_file, '<', "$dest.raw" ) || die( "data error: $!" );
    open( my $out_file, '>', $dest ) || die( "output file error: $!" );

    my @header_lines = <$header_file>;
    chomp( @header_lines );
    my @header_sets = map {[split(',', $_ )]} @header_lines;
    my @headers = merge_headers( @header_sets );

    print $out_file join(',', @headers) . "\n";
    my $header_set = shift @header_sets;
    while( my $line = <$data_file> ) {
        if ( $line eq "\n" ) {
            $header_set = shift @header_sets;
            next;
        }
        chomp( $line );
        my @data = split( ',', $line );
        my %data_hash = map {( $header_set->[$_] => $data[$_] )} 0 .. (@data - 1);
        print $out_file join(',', map { $_ || '' } @data_hash{@headers}) . "\n";
    }

    close( $out_file );
    close( $header_file );
    close( $data_file );
    unless( $specs{ keep_files }) {
        unlink( "$dest.head" );
        unlink( "$dest.raw" );
    }
}

sub merge_headers {
    my %seen = map {( map {( $_ => 1 )} @$_ )} @_;
    return reverse sort keys %seen;
}

1;

__END__

=head1 NAME

Devel::Memalyzer::Combine - Combine .head and .raw files into a proper csv file

=head1 DESCRIPTION

optionally exports the combine() function.

=head1 SYNOPSYS

    use Devel::Memalyzer::Combine qw/combine/;
    combine( $output_file );

=head1 FUNCTIONS

=over 4

=item combine( $file )

=item combine( $file, keep_files => 1 )

Combines "$file.head" and "$file.raw" into "$file". Will remove the .head and
.raw files unless called with keep_files => 1.

=back

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

