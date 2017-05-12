package GlbDNS::Zone;


use strict;
use warnings;
use Data::Dumper;
use Net::DNS::RR::A;


=head1 GlbDNS::Zone

Parsing zone files with LOC data

=head2 load_configs

    GlbDNS->load_configs($glbdns, $path);
    GlbDNS->load_configs($glbdns, $file);

=cut

sub load_configs {
    my $class = shift;
    my $glbdns = shift;
    my $path = shift;
    if (-d $path) {
        opendir(DIR, $path) || die "Cannot open directory '$path': $!\n";
        for my $file (readdir(DIR)) {
            next if (-d $file);
            next if ($file =~/^(\.|#)/);
            next if ($file =~/~$/);
            $class->parse($glbdns, "$path/$file");
        }
    } elsif (-f $path) {
        $class->parse($glbdns, $path);
    } else {
        die "Cannot find zone '$path'\n";
    }
    $class->geo_fix($glbdns);
}

=head2 parse

    GlbDNS->parse($glbdns, $file);

=cut

sub parse {
    my $class = shift;
    my $glbdns = shift;
    my $file = shift;

    open(my $fh, "<", "$file") || die "Cannot open file '$file': $!\n";
    my $mtime = @{[stat("$file")]}[9];

    my $error = sub {
        die "$_[0] at $file:$.\n";
    };



    my $base_fqdn;
    my $base;
    my $hosts = $glbdns->{hosts} ||= {};
    while(my $line = <$fh>) {
        chomp($line);
        next unless($line);
        next if($line =~ /^\s+$/);
        next if($line =~ /^;/);

        if($line =~/\$ORIGIN\s+([a-zA-Z.\-]+)/) {
            $base_fqdn = $1;
            ($base) = $base_fqdn =~/(.*)\.$/;
            $error->("'$base_fqdn' needs to be terminated with a . to be a FQDN") unless ($base);
            next;
        } elsif (!$base) {
            $error->("No \$ORIGIN domain has been specified, don't know what domain we are working on");
        }

        my @record = split /\s+/, $line;

        # if the first record is a DNS entry
        # then check if it is a FQDN and complete it
        # or use the default one
        if ($record[0] !~ /^\d+$/) {
                $record[0] = "$record[0].$base" if($record[0] !~ /\.$/);
        } else {
            unshift @record, $base;
        }

        # fully qualify CNAMEs
        if($record[3] eq 'CNAME' && $record[4] !~/\.$/) {
            $record[4] .= ".$base";
        }
        # fully qualify MX
        if($record[3] eq 'MX' && $record[5] !~/\.$/) {
            $record[5] .= ".$base";
        }


        my $add_host = sub {
            my $record = shift;
            my $host = $hosts->{$record->name} ||= {};
            my $records = $host->{$record->type} ||= [];
            $host->{__RECORD__} = $record->name;
            $host->{domain} = $host->{__DOMAIN__} = $base;
            push @$records, $record;
        };

        my $rr = Net::DNS::RR->new(join " ", @record);

        # autocreate PTR records for A records
        # there can be more than one
        if ($rr->type eq 'A') {
            my $address = join(".", reverse( split(/\./, $rr->address)) ) ;
            my $reverse = Net::DNS::RR->new("$address.in-addr.arpa. " . $rr->ttl . " IN PTR  " . $rr->name);
            $add_host->($reverse);
        }


        $add_host->($rr);





    }
    close($fh);
}

=head2 geo_fix

   GlbDNS::Zone->geo_fix($glbdns);

=cut

sub geo_fix {
    my $class = shift;
    my $glbdns = shift;
    my $hosts = $glbdns->{hosts};
    # now go through and fix up the geolocation ones
    foreach my $host (values %{$hosts}) {
        if ($host->{CNAME} && @{$host->{CNAME}} > 1) {
            # more than one cname is not allowed
            # so they have to point to geo tagged records
            # or we abort
            foreach my $cname (@{$host->{CNAME}}) {
                my $target = $hosts->{$cname->cname};
                die "Need record for " . $cname->cname . "\n" unless $target;
                die "Record " . $cname->name . " needs LOC data\n" unless $target->{LOC};

                my ($lat, $lon) = $target->{LOC}[0]->latlon;
                my $geo = $host->{__GEO__} ||= {};

                die "Trying to overwrite geo target $target->{__RECORD__}\n" if($geo->{$target->{__RECORD__}});
                my $geo_entry = $geo->{$target->{__RECORD__}} = {};

                $geo_entry->{lat} = $lat;
                $geo_entry->{lon} = $lon;
                $geo_entry->{hosts} = $target->{A} || $target->{CNAME} || die "Need A or CNAME for $target->{__RECORD__}\n";
                if ($target->{TXT}) {
                    foreach my $txt (@{$target->{TXT}}) {
                        my @txt = $txt->char_str_list;
                        if($txt[0] eq 'GlbDNS::RADIUS') {
                            $geo_entry->{radius} = $txt[1];
                        } elsif($txt[0] eq 'GlbDNS::CHECK') {
                            foreach my $check_host (@{$geo_entry->{hosts}}) {
                                $glbdns->{checks}->{$check_host->address} = {
                                    ip => $check_host->address,
                                    url => $txt[1],
                                    expect => $txt[2],
                                    interval => 5,
                                };
                            }
                        }
                    }
                }
                $geo_entry->{source}->{$host->{__RECORD__}} = $cname;
            }
            delete($host->{CNAME});
        }
    }
}


1;
