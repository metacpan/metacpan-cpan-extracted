#!/usr/bin/perl
use strict;
use warnings;
use Devel::Memalyzer::Combine qw/combine/;

if ( grep { m/^-+h(elp)?$/ } @ARGV ) {
    print <<EOT;
Usage: $0 output.file

    This script will combine output.file.head and output.file.raw into
    output.file. The final output file will be a csv file where the first line
    is all the headers.
EOT
exit;
}

my ($output ) = shift( @ARGV );
combine( $output, keep_files => 1 );

__END__

=head1 AUTHORS

Chad Granum L<exodist7@gmail.com>

=head1 COPYRIGHT

Copyright (C) 2010 Rentrak Corperation

