use strict;
use warnings;
use Melian;
use Test::More;
use Test::TCP;
use IO::Socket::INET;

my $schema_json = <<'JSON';
{
  "tables": [
    {
      "name": "table1",
      "id": 0,
      "period": 60,
      "indexes": [
        { "id": 0, "column": "id", "type": "int" }
      ]
    },
    {
      "name": "table2",
      "id": 1,
      "period": 60,
      "indexes": [
        { "id": 0, "column": "id", "type": "int" },
        { "id": 1, "column": "hostname", "type": "string" }
      ]
    }
  ]
}
JSON

my $table1_row = <<'JSON';
{"id":5,"name":"item_5","category":"alpha","value":"VAL_0005","description":"Mock description for item 5","created_at":"2025-10-30 14:26:47","updated_at":"2025-11-04 14:26:47","active":1}
JSON

my $table2_row = <<'JSON';
{"id":2,"hostname":"host-00002","ip":"10.0.2.0","status":"maintenance"}
JSON

test_tcp(
    client => sub {
        my $port = shift;
        my $dsn  = "tcp://127.0.0.1:$port";
        my $melian = Melian->new( 'dsn' => $dsn, 'timeout' => 1 );

        isa_ok( $melian, 'Melian' );
        isa_ok( $melian->{'schema'}, 'HASH' );

        my $schema = $melian->{'schema'};
        is( $schema->{'tables'}[0]{'name'}, 'table1', 'schema includes table1' );
        is( $schema->{'tables'}[1]{'name'}, 'table2', 'schema includes table2' );

        my $table1 = $schema->{'tables'}[0];
        my $table2 = $schema->{'tables'}[1];

        my $table1_row = $melian->fetch_json_by_id( $table1->{'id'}, $table1->{'indexes'}[0]{'id'}, 5 );
        is( $table1_row->{'name'}, 'item_5', 'table1 row fetched' );

        my $table2_id_row = $melian->fetch_json_by_id( $table2->{'id'}, $table2->{'indexes'}[0]{'id'}, 2 );
        is( $table2_id_row->{'hostname'}, 'host-00002', 'table2 by id' );

        my $table2_host_row = $melian->fetch_json( $table2->{'id'}, $table2->{'indexes'}[1]{'id'}, 'host-00002' );
        is( $table2_host_row->{'status'}, 'maintenance', 'table2 by hostname' );
    },
    server => sub {
        my $port = shift;
        my $listener = IO::Socket::INET->new(
            LocalAddr => '127.0.0.1',
            LocalPort => $port,
            Listen    => 5,
            Proto     => 'tcp',
            ReuseAddr => 1,
        ) or die "listen failed: $!";

        while (my $conn = $listener->accept) {
            $conn->autoflush(1);
            while (1) {
                my $hdr = read_exact($conn, 8) or last;
                my ($ver, $action, $table_id, $index_id, $len) = unpack('CCCCN', $hdr);
                my $key = $len ? read_exact($conn, $len) : '';
                if ($action == ord('D')) {
                    write_frame($conn, $schema_json);
                } elsif ($action == ord('F')) {
                    my $payload = '';
                    if ($table_id == 0 && $index_id == 0) {
                        my $id = unpack('V', $key);
                        $payload = $id == 5 ? $table1_row : '';
                    } elsif ($table_id == 1 && $index_id == 0) {
                        my $id = unpack('V', $key);
                        $payload = $id == 2 ? $table2_row : '';
                    } elsif ($table_id == 1 && $index_id == 1) {
                        $payload = $key eq 'host-00002' ? $table2_row : '';
                    }
                    write_frame($conn, $payload);
                } else {
                    write_frame($conn, '');
                }
            }
            close $conn;
        }
    },
);

done_testing();

sub read_exact {
    my ($fh, $len) = @_;
    my $buf = '';
    while (length($buf) < $len) {
        my $r = sysread($fh, my $chunk, $len - length($buf));
        return unless defined $r && $r > 0;
        $buf .= $chunk;
    }
    return $buf;
}

sub write_frame {
    my ($fh, $payload) = @_;
    my $frame = pack('N', length($payload)) . $payload;
    syswrite($fh, $frame);
}
