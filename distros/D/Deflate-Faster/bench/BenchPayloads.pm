package BenchPayloads;
use strict;
use warnings;
use Exporter qw(import);

our @EXPORT_OK = qw(make_payloads);

# Returns 8 distinct, realistic payloads of the exact requested byte size
# to prevent microbenchmark cache-locality and branch-prediction bias.
sub make_payloads {
    my ($target_size) = @_;

    my @generators = (
        # 1. JSON API payload
        sub {
            my $b = "{\"status\":\"ok\",\"timestamp\":1727864441,\"items\":[";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq({"id":%d,"sku":"SKU-%05d","name":"Product %d","price":%.2f,"in_stock":%s},),
                    $i, $i * 17 % 10000, $i, ($i * 3.14) % 100, $i % 3 ? "true" : "false");
                $i++;
            }
            $b .= "]}";
            return substr($b, 0, $target_size);
        },
        # 2. HTML / DOM markup
        sub {
            my $b = "<!DOCTYPE html><html><head><title>Dashboard</title></head><body><main>";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(<div class="card-%d" id="n-%d"><h3>H%d</h3><p>Desc %d tok=%x</p><a href="/item/%d">View</a></div>\n),
                    $i % 10, $i, $i, $i, ($i * 2654435761) & 0xffffffff, $i);
                $i++;
            }
            $b .= "</main></body></html>";
            return substr($b, 0, $target_size);
        },
        # 3. Source code (C / XS)
        sub {
            my $b = "/* Module code */\n#include <stdio.h>\n#include <stdlib.h>\n";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(static int proc_rec_%d(const char *k, int flags, double w) {\n    if (!k || flags & 0x%02x) return -1;\n    return %d;\n}\n),
                    $i, $i % 16, $i);
                $i++;
            }
            return substr($b, 0, $target_size);
        },
        # 4. HTTP / Web access log
        sub {
            my $b = "";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(192.168.%d.%d - - [02/Oct/2026:10:%02d:%02d +0000] "GET /api/v1/%d?s=%x HTTP/1.1" %d %d\n),
                    $i % 255, ($i * 7) % 255, $i % 60, ($i * 3) % 60, $i, ($i * 1103515245) & 0x7fffffff, ($i % 10 ? 200 : 404), ($i * 123) % 50000);
                $i++;
            }
            return substr($b, 0, $target_size);
        },
        # 5. English prose
        sub {
            my @s = (
                "The morning mist began to clear as the train slowly pulled out of the quiet valley station.",
                "Several passengers looked up from their morning newspapers, wondering if the scheduled arrival was delayed.",
                "Engineers gathered in the observation deck to monitor the newly installed pressure instrumentation.",
                "A gentle hum from the electric motors indicated that power delivery remained stable under increased load.",
                "Outside the wide panoramic windows, autumn foliage covered the rolling hills in deep shades of crimson.",
                "Data collection across all telemetry channels proceeded without interruption throughout the journey."
            );
            my $b = "";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= $s[$i % @s] . " ";
                $i++;
            }
            return substr($b, 0, $target_size);
        },
        # 6. SQL database transactions
        sub {
            my $b = "-- DB Log\nBEGIN TRANSACTION;\n";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(INSERT INTO metrics (id, tenant, name, val) VALUES (%d, %d, "p%02d", %.4f);\n),
                    $i, $i % 50 + 1, $i % 100, (($i * 13) % 1000) / 10.0);
                $i++;
            }
            $b .= "COMMIT;\n";
            return substr($b, 0, $target_size);
        },
        # 7. Key-Value configuration
        sub {
            my $b = "# Cluster state\n";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(node.%03d.host = "worker-%03d.internal"\nnode.%03d.port = %d\nnode.%03d.role = "%s"\nnode.%03d.enabled = %s\n),
                    $i, $i, $i, 8000 + ($i % 1000), $i, ($i % 3 ? "replica" : "primary"), $i, ($i % 5 ? "true" : "false"));
                $i++;
            }
            return substr($b, 0, $target_size);
        },
        # 8. CSV tabular records
        sub {
            my $b = "index,timestamp,uuid,action,duration_ms,status_code\n";
            my $i = 0;
            while (length($b) < $target_size) {
                $b .= sprintf(qq(%d,1727864%04d,"usr_%08x","act_%s",%.2f,%d\n),
                    $i, $i % 10000, ($i * 1664525) & 0xffffffff, ($i % 2 ? "read" : "write"), (($i * 37) % 500) / 10.0, ($i % 20 ? 200 : 500));
                $i++;
            }
            return substr($b, 0, $target_size);
        },
    );

    return map { $_->() } @generators;
}

1;
