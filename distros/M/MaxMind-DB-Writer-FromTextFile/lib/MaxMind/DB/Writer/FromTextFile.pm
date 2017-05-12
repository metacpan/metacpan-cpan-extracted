package MaxMind::DB::Writer::FromTextFile;

use 5.008008;
use strict;
use warnings;
use Encode ();
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(mmdb_create);
our $VERSION   = '0.02';

sub mmdb_create {
    my $input_filename = shift;
    my $mmdb_filename  = shift;

    return 0 unless -s $input_filename;

    my $tree = MaxMind::DB::Writer::Tree->new(
        ip_version    => 4,
        record_size   => 24,
        database_type => 'MMDB',
        description   => {
            en => 'MaxMindDB',
        },
        map_key_type_callback => sub { 'utf8_string' },
    );
    open my $rfh, "<", $input_filename;
    while (<$rfh>) {
        chomp;
        my ( $iprange, $addr ) = split /\s/, $_;
        $addr =~ s/\"//g;
        $iprange = $iprange . "/32" unless $iprange =~ /\//;
        my $subnet = Net::Works::Network->new_from_string(
            string  => $iprange,
            version => 4,
        );

        $tree->insert_network(
            $subnet,
            {
                subnet => $subnet->as_string(),
                string => $addr,
            },
        );
    }

    open my $fh, '>', $mmdb_filename;
    $tree->write_tree($fh);
    return -s $mmdb_filename;
}

1;
__END__

=head1 NAME

MaxMind::DB::Writer::FromTextFile - Create MaxMind DB from text file

=head1 SYNOPSIS

  use MaxMind::DB::Writer::FromTextFile;
  mmdb_create($input_filename, $output_mmdb_filename);


=head1 INPUT FILE FORMAT

Input text file should looks like below.

  39.111.254.0/24 "hongkong|hongkong"
  39.111.255.0/24 "abroad|abroad"
  39.112.0.0/12 "abroad|abroad"
  39.128.0.0/11 "beijing|CM"
  39.160.0.0/12 "beijing|CM"
  39.176.0.0/14 "beijing|CM"
  39.180.0.0/14 "zhejiang|CM"
  39.184.0.0/13 "zhejiang|CM"
  39.192.0.0/10 "abroad|abroad"
  40.0.0.0/9 "abroad|USA"

=head2 EXPORT

None by default.

=head1 SEE ALSO

L<MaxMind::DB::Reader>, L<MaxMind::DB::Reader::XS>, L<MaxMind::DB::Writer>

=head1 AUTHOR

Chen Gang, E<lt>yikuyiku.com@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Chen Gang

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16.2 or,
at your option, any later version of Perl 5 you may have available.


=cut
