package IO::Socket::DNS::Server;

use strict;
use warnings;
use Carp qw(croak);
use IO::Socket;
use IO::Select;
use IO::Socket::DNS;
use base qw(Net::DNS::Nameserver);
use Data::Dumper; # Only for debugging

our $VERSION = '0.021';

# Maximum number of bytes to try to encode into the response packet
our $MAX_RETURN = 100;

# Probe "z" timeout for TCP socket reading (in seconds)
our $PROBE_TIMEOUT = 0.1;

# No semi-colon allowed in TXT value
# No non-printing characters allowed
# No newlines allowed
# No backslash allowed
# No double quotes allowed because it will be enclosed later
our $TXT = {
    ""      => q{dig +short TXT loader.$suffix},
    netdns  => q{{$b=chr(34)}while(++$a&&`nslookup -type=TXT netdns$a.$suffix. 2>&1`=~/$b([0-9a-f]+)$b/){$_.=$1} eval pack'H*',$_ or warn $@},
    netdns0 => "netdns_code",
    loader  => q{echo eval pack q/N6/,0x60404152,0x4756603d,0x7e2f2228,0x2e2a2922,0x2f3b6576,0x616c2431 | perl - nslookup -type=TXT unzip.$suffix.},
    unzip   => q{{$b=chr(34)}while(++$a&&`nslookup -type=TXT unzip$a.$suffix. 2>&1`=~/$b([0-9a-f]+)$b/){$_.=$1} eval pack'H*',$_ or warn qq{$_:$@}},
    unzip0  => "unzip_code",
    menu    => q{while(++$a and $b=eval{[Net::DNS::Resolver->new->query(qq(menu$a.$suffix),'TXT')->answer]->[0]->txtdata}){$_.=$b}eval pack'H*',$_ or warn$@},
    menu0   => "menu_code",
    client0 => "client_code",
    dnsc0   => "dnsc_code",
    dnsssh0 => "dnsssh_code",
    dnsnc0  => "dnsnc_code",
    # No double nor single quotes nor dollar sign nor backticks nor any shell metas allowed for this
    # special "nslookup" value in order to function under different environments and OSes and shells,
    # including Linux, Mac, Win32, Cygwin, Windows, DOS, CMD.EXE, bash, tcsh, csh, ksh, zsh, etc.
    nslookup=> q{echo eval pack q/N6/,0x60404152,0x4756603d,0x7e2f2228,0x2e2a2922,0x2f3b6576,0x616c2431 | perl - nslookup -type=TXT netdns.$suffix.},
};

# new
sub new {
    my $class = shift;

    my %args = @_;
    my $reply_handler = $args{ReplyHandler};
    $args{ReplyHandler} = sub { return "SERVFAIL", [], [], [] }; # Avoid: "No reply handler!";
    $args{Suffix} ||= $ENV{DNS_SUFFIX}
        or croak "Suffix is required";
    my $suffix = $args{Suffix} = lc $args{Suffix};
    $args{"Verbose"} ||= 0;
    $args{"Password"} = $ENV{DNS_PASSWORD} || $args{Password} || "";
    $args{"SOA"} ||= do {
        my $res = $args{net_dns} ||= eval {
            require Net::DNS::Resolver::Recurse;
            return Net::DNS::Resolver::Recurse->new;
        };
        my $soa = { lc($suffix) => 1 };
        my $ip = undef;
        my $bind_errors = {};
        $res->recursion_callback(sub {
            my $packet = shift;
            foreach my $rr ($packet->answer,$packet->authority,$packet->additional) {
                if ($rr->type eq "NS" && $soa->{lc $rr->name}) {
                    $soa->{lc $rr->nsdname} = 1;
                }
            }
            foreach my $rr ($packet->answer,$packet->authority,$packet->additional) {
                if ($rr->type eq "CNAME" && $soa->{lc $rr->name}) {
                    $soa->{lc $rr->nsdname} = 1;
                }
            }
            foreach my $rr ($packet->answer,$packet->authority,$packet->additional) {
                if ($rr->type eq "A" && $soa->{lc $rr->name}) {
                    my $try = $rr->rdatastr;
                    if (!$bind_errors->{$try}) {
                        warn "Testing $try ...\n" if $args{"Verbose"};
                        # Quick Ephermural Test to make sure this address is bindable.
                        if (IO::Socket::INET->new(LocalAddr => $try, Listen => 1)) {
                            $ip = $rr->rdatastr;
                            warn "Automatically determined DNS suffix [$suffix] to have SOA IP [$ip]\n" if $args{"Verbose"};
                            die "found winner $ip";
                        }
                        else {
                            $bind_errors->{$try} = $!;
                            warn "Unable to bind to $try: $!\n" if $args{"Verbose"};
                        }
                    }
                }
            }
        });

        my $num_soas = 0;
        while ($num_soas < scalar(keys %$soa)) {
            $num_soas = scalar keys %$soa;
            foreach my $auth (sort keys %$soa) {
                eval { $res->query_dorecursion($auth, "ANY") };
                last if $ip;
            }
            last if $ip;
        }

        if (!$ip) {
            ($ip) = keys %$bind_errors;
            if ($ip) {
                warn "Warning: Unable to bind to $ip but using it for the SOA IP anyway. Specify SOA manually if you don't like this.\n";
            }
            else {
                die "Unable to determine SOA IP using Suffix [$suffix]. Please correct the DNS authority entries or try another Suffix.\n";
            }
        }

        $ip;
    };
    $args{"LocalAddr"} ||= $args{"SOA"};

    my $self = $class->SUPER::new(%args);
    # Now swap in the real handler
    $self->{"ReplyHandler"} = $reply_handler || sub { ReplyHandler($self, @_); };

    warn "DEBUG: Launching with suffix [$args{Suffix}]\n" if $args{"Verbose"};
    return $self;
}

sub ReplyHandler {
    my $self = shift;
    my $suffix = $self->{"Suffix"} or croak "ReplyHandler: called incorrectly! Missing Suffix?";
    my ($qname, $qclass, $qtype, $peerhost, $query, $conn) = @_;
    my ($rcode, @ans, @auth, @add, $aa);

    $qname =~ y/A-Z/a-z/;
    warn "DEBUG: Q: $qname $qtype (from $peerhost)...\n" if $self->{"Verbose"};
    if ($qname =~ /(^|\.)$suffix/) {
        $aa = 1;
        if ($qtype eq "TXT") {
            my $ans = "";
            if ($qname =~ /^([a-z]*)\.?$suffix/ and
                my $static = $TXT->{$1}) {
                $ans = qq{"$static"};
                $ans =~ s/\$suffix/$suffix/g;
            }
            elsif ($qname =~ /^([a-z\-]+)(\d+)\.$suffix$/ and
                   my $method = $TXT->{$1."0"}) {
                my $prefix = $1;
                my $line_num = $2;
                my $codes_array_ref = $self->{"_code_array_cache_$prefix"} ||= eval {
                    my $code = ref($method) eq "CODE" ? $method->($self,$prefix) : $self->$method($prefix);
                    warn "DEBUG: $method string=[$code]\n" if $self->{"Verbose"};
                    my @encode = ();
                    while ($code =~ s/^(.{1,100})//s) {
                        my $chunk = $1;
                        push @encode, unpack "H*", $chunk;
                    }
                    warn Dumper [ code_array => \@encode ] if $self->{"Verbose"};
                    return \@encode;
                } || [];

                $ans = $line_num ? $codes_array_ref->[$line_num - 1] : scalar @$codes_array_ref if $line_num <= @$codes_array_ref;
            }
            # Check for TCP SYN Request
            elsif ($qname =~ /^([a-z0-9\-\.]+)\.t(\d+)\.(\w+)\.(0|z[0-9a-f]{26})\.$suffix$/i) {
                my $peerhost = $1;
                my $peerport = $2;
                my $ephid    = $3;
                my $code     = $4;
                if ($code ne $self->encrypt($peerhost, $peerport)) {
                    $IO::Socket::DNS::INVALID_PASS or die "Implementation fail: Sentinal value missing?";
                    $ans = "$ephid.$IO::Socket::DNS::INVALID_PASS";
                }
                elsif (my $prev = $self->{"_proxy"}->{$ephid}) {
                    $ans = "$ephid.0.$prev->{next_seqid}";
                    if (my $sent = $prev->{"sent"}) {
                        my $banner = $self->dnsencode($sent);
                        $banner =~ s/\.//g;
                        # Recreate original response exactly as before
                        $ans .= ".".length($banner).".$banner";
                    }
                }
                else {
                    warn "Sending TCP SYN to $peerhost:$peerport\n" if $self->{"Verbose"};
                    my $sock = new IO::Socket::INET
                        PeerAddr => $peerhost,
                        PeerPort => $peerport,
                        Timeout  => 30,
                        ;
                    my $errno = $sock ? 0 : ($! + 0) || -1;
                    $ans = "$ephid.$errno";
                    if (!$sock) {
                        warn "Failed to connect to $peerhost:$peerport (errno=$errno)\n" if $self->{"Verbose"};
                    }
                    else {
                        my $seqid = $self->gen_seqid;
                        $ans .= ".$seqid";
                        warn "Received ACK for $peerhost:$peerport (seqid=$seqid)\n" if $self->{"Verbose"};
                        # Disable blocking. Buffer data to ensure it all gets sent eventually.
                        $sock->blocking(0);
                        my $timeout = time()+120;
                        $self->{"_tcp"}->{$sock} = {
                            ephid  => $ephid,
                            seqid  => $seqid,
                            peer   => "tcp:$peerhost:$peerport",
                            state  => -1,
                            socket => $sock,
                            timeout=> $timeout,
                            inbuffer => "",
                        };
                        $self->{"_proxy"}->{$ephid} = {
                            socket   => $sock,
                            inbuffer => "",
                            sent     => "",
                            timeout  => $timeout,
                            next_seqid => $seqid,
                        };
                        $self->{"_proxy"}->{$seqid} = {
                            socket   => $sock,
                            inbuffer => "",
                            sent     => undef,
                            timeout  => $timeout,
                            ephid    => $ephid,
                            next_seqid => undef,
                        };
                        # Brief wait for a possible protocol banner
                        if (IO::Select->new($sock)->can_read(0.3)) {
                            # Found response. Grab what is available.
                            my $banner;
                            if (sysread($sock, $banner, $MAX_RETURN)) {
                                $self->{"_proxy"}->{$ephid}->{"sent"} = $banner;
                                $banner = $self->dnsencode($banner);
                                $banner =~ s/\.//g;
                                # Add content to the answer
                                $ans .= ".".length($banner).".$banner";
                            }
                        }
                        $self->{"select"}->add($sock);
                    }
                }
                #warn Dumper DEBUG => [ full_tcp => $self->{_tcp}, _proxy => $self->{_proxy}, ] if $self->{"Verbose"};
            }
            # Check for SEND
            elsif (($qname =~ /^([0-9a-w]{6})\.(\d+)\.([0-9a-w.]+)\.$suffix$/ && $2 == length($3)) ||
                   $qname =~ /^([0-9a-w]{6})\.()([xz])\.$suffix$/ and
                   my $proxy = $self->{"_proxy"}->{$1}) {
                my $seqid   = $1;
                my $encoded = $3;
                my $sock = $proxy->{"socket"};
                if ($encoded =~ /^[xz]$/) {
                    if ($encoded eq "x" and my $tcp = $self->{"_tcp"}->{$sock}) {
                        # Client wants to shutdown the connection
                        #shutdown($sock,1);
                        # Expire the connection immediately
                        $tcp->{"timeout"} = time() - 1;
                        $self->loop_once(0);
                    }
                    $encoded = "";
                }
                $ans = "$seqid-";
                my $next_seqid = $proxy->{"next_seqid"};
                if ($next_seqid) {
                    warn "DEBUG: ALREADY SENT TO [$seqid] PACKET [$encoded] (skipping this time)\n" if $self->{"Verbose"};
                    $ans .= "$next_seqid.";
                    my $sent = $proxy->{"sent"};
                    if (!defined $sent) {
                        $ans = "$seqid.0";
                    }
                    elsif (my $len = length $sent) {
                        $ans .= "$len.$sent";
                    }
                    else {
                        $ans .= "0";
                    }
                    warn "DEBUG: Repeating cached response [$ans]\n" if $self->{"Verbose"};
                }
                else {
                    warn "DEBUG: SENDING TO [$seqid] PACKET [$encoded]\n" if $self->{"Verbose"};
                    if (length $encoded) {
                        my $decoded = $self->dnsdecode($encoded);
                        $self->{"_tcp"}->{$sock}->{"outbuffer"} .= $decoded if $self->{"_tcp"}->{$sock};
                        $decoded =~ s/%/%25/g;
                        $decoded =~ s/([^\ -\~])/sprintf "%%%02X", ord $1/eg;
                        warn "DEBUG: JAMMED INTO SOCKET [$decoded]\n" if $self->{"Verbose"};
                    }
                    $self->loop_once($PROBE_TIMEOUT);
                    # Consume as much inbuffer as possible
                    # and save the rest for the next seqid.
                    my $buffer = $proxy->{"inbuffer"};
                    $proxy->{"inbuffer"} = "";
                    my $send = "";
                    my $len = length $buffer;
                    if (!$len && !$self->{"_tcp"}->{$sock}) {
                        # Socket has been shutdown and buffer is empty
                        $proxy->{"sent"} = undef;
                        $proxy->{"next_seqid"} = -1;
                        $ans = "$seqid.0";
                    }
                    else {
                        if ($len) {
                            my $consume = $len >= $MAX_RETURN ? $MAX_RETURN : $len;
                            $send = substr($buffer, 0, $consume, "");
                        }
                        if (defined (my $consumed = $send)) {
                            $consumed =~ s/%/%25/g;
                            $consumed =~ s/([^\ -\~])/sprintf "%%%02X", ord $1/eg;
                            warn "DEBUG: EXTRACTED FROM SOCKET [$consumed]\n" if $self->{"Verbose"};
                        }

                        $send = $self->dnsencode($send);
                        $len = length($send);
                        $proxy->{"sent"} = $send;

                        # Generate next seqid
                        $next_seqid = $self->gen_seqid;
                        $proxy->{"next_seqid"} = $next_seqid;
                        $ans .= "$next_seqid.$len";
                        $ans .= ".$send" if $len;
                        $self->{"_proxy"}->{$next_seqid} = {
                            socket   => $sock,
                            inbuffer => $buffer,
                            sent     => undef,
                            timeout  => time()+120,
                            ephid    => $proxy->{"ephid"},
                            next_seqid => undef,
                        };
                        # Update the seqid to point to the new one.
                        $self->{"_tcp"}->{$sock}->{"seqid"} = $next_seqid if $self->{"_tcp"}->{$sock};
                    }
                }
            }
            if ($ans) {
                warn "DEBUG: $qname RESPONSE [$ans]\n" if $self->{"Verbose"};
                push @ans, Net::DNS::RR->new(qq{$qname 60 $qclass $qtype $ans});
                $rcode = "NOERROR";
            }
        }
        elsif ($qtype eq "NS") {
            my $me = $self->{SOA};
            push @ans, Net::DNS::RR->new("$qname 60 $qclass $qtype dns.$suffix");
            push @auth, Net::DNS::RR->new("$qname 60 $qclass $qtype dns.$suffix");
            push @add, Net::DNS::RR->new("dns.$suffix 60 $qclass A $me");
            $rcode = "NOERROR";
        }
        elsif ($qtype =~ /^(A|CNAME)$/) {
            my $me = $self->{SOA};
            my $alias = "please-use-TXT-instead-of-$qtype-when-looking-up.loader.$suffix";
            if ($qname =~ /^(dns\.|)\Q$suffix\E$/) {
                push @ans, Net::DNS::RR->new("$qname 60 $qclass A $me");
            }
            elsif ($qname eq $suffix) {
                # It violates RFC to CNAME to subdomain of itself.
                push @ans, Net::DNS::RR->new("$qname 1 $qclass CNAME $alias");
                push @ans, Net::DNS::RR->new("$alias 1 $qclass A $me");
                push @add, Net::DNS::RR->new("dns.$suffix 60 $qclass A $me");
            }
            else {
                push @ans, Net::DNS::RR->new("$qname 10 $qclass CNAME $alias");
                push @ans, Net::DNS::RR->new("$alias 10 $qclass CNAME dns.$suffix");
                push @add, Net::DNS::RR->new("dns.$suffix 60 $qclass A $me");
            }
            push @auth, Net::DNS::RR->new("$suffix 60 $qclass NS dns.$suffix");
            $rcode = "NOERROR";
        }
    }
    else {
        push @auth, Net::DNS::RR->new(". 86400 IN NS a.root-servers.net");
        $rcode = "NOERROR";
    }

    $rcode ||= "NXDOMAIN";

    return ($rcode, \@ans, \@auth, \@add, { aa => $aa });
}

sub gen_seqid {
    my $seqid = "";
    for (1..6) {
        $seqid .= $IO::Socket::DNS::a32->[rand @$IO::Socket::DNS::a32];
    }
    return $seqid;
}

sub netdns_code {
    my $self = shift;
    my $suffix = $self->{"Suffix"};
    my $LOADER = $TXT->{"loader"};
    $LOADER =~ s/"(.+)"/$1/;
    my @modules = ();
    my $net_dns_handler = sub {
        my $self = shift;
        my $me = shift or die "netdns module is required";
        my $full_path = $self->{"_netdns_map"}->{$me} or die "$me: Installed handler, but no map?";
        warn "DEBUG: Loading [$full_path] ...\n" if $self->{"Verbose"};
        open my $fh, "<", $full_path or die "$full_path: Found in \%INC but unable to read?";
        my $code = "";
        while (<$fh>) {
            last if /^__END__/;
            $code .= $_;
        }
        close $fh;
        return $code;
    };
    # This is just a hack to allow a Non-Win32 server to still
    # download Win32.pm in case it is needed by a Win32 client:
    eval { require Net::DNS::Resolver::Win32 };
    foreach my $mod (sort keys %INC) {
        if ($mod =~ m{^Net/DNS}) {
            push @modules, $mod;
            my $p = lc $mod;
            $p =~ s/\.pm//;
            $p =~ s{/+}{-}g;
            $p =~ y/0-9//d;
            my $full_path = $INC{$mod};
            my $method = $p."0";
            print "INSTALLING HANDLER: $p\$n.$suffix => $full_path\n" if $self->{"Verbose"};
            $self->{"_netdns_map"}->{$p} = $full_path;
            $TXT->{$method} = $net_dns_handler;
        }
    }
    my $MODULES = "@modules";

    # Short Program to bootstrap Net::DNS onto the client
    my $code = q{
        use strict;
        # Hot flush STDOUT
        $| = 1;
        unshift @INC, "lib";
        # Stub program for testing purposes just for now.
        print "Loading Net::DNS::* modules through nslookup via netdns.$suffix ...\n";
        my @modules = qw($MODULES);
        my $downloaded = 0;
        foreach my $mod (@modules) {
            print "Testing: $mod ...\n";
            my $pre = lc $mod;
            $pre =~ s/\.pm//;
            $pre =~ s{/+}{-}g;
            $pre =~ y/0-9//d;
            my $file = "lib/$mod";
            if (eval "require '$mod'") {
                # Module loaded fine
            }
            elsif (-s $file) {
                # File already exists
                print "$file: File exists so refusing to download again.\n";
            }
            else {
                warn "FAILED: $@";
                my $dir = "";
                while ($file =~ m{([^/]+)/}g) {
                    $dir .= $1;
                    mkdir $dir, 0755;
                    $dir .= "/";
                }
                my $i = 0;
                my $contents = "";
                print "Downloading $file ...\n";
                $downloaded++;
                my $ticks = 0;
                while (1) {
                    `nslookup -type=TXT $pre$i.$suffix 2>&1` =~ /"(.+)"/ or
                    warn("**CHOKE1** $pre$i\n") && sleep(1) && `nslookup -type=TXT $pre$i.$suffix 2>&1` =~ /"(.+)"/ or
                    warn("**CHOKE2** $pre$i\n") && sleep(1) && `nslookup -type=TXT $pre$i.$suffix 2>&1` =~ /"(.+)"/;
                    my $txt = $1 or last;
                    if ($i) {
                        $contents .= $txt;
                        print sprintf "\r(%d/%d) %.1f%%", $i, $ticks, $i/$ticks*100;
                    }
                    elsif ($txt =~ /^\d+$/) {
                        $ticks = $txt;
                        print "\r0/$ticks";
                    }
                    else {
                        die "$pre$i: Invalid DNS cache: $txt\n";
                    }
                    $i++;
                    last if $i > $ticks;
                }
                print "\n";
                if ($i<$ticks) {
                    print "WARNING! Only downloaded $i/$ticks chunks do refusing to write $file\n";
                    next;
                }
                $contents = pack 'H*', $contents;
                if ($contents) {
                    open my $fh, ">", $file or die "$file: open: $!";
                    print $fh $contents;
                    close $fh;
                }
            }
        }

        if ($downloaded) {
            foreach my $mod (@modules) {
                next if $mod =~ /Win32/ and $^O !~ /Win32/;
                eval "require '$mod'" or die "$mod: Unable to download?: $@";
            }
        }
        else {
            warn "Congratulations! You already had Net::DNS installed.\n";
        }
        my $n = q{$LOADER};
        $n =~ s/\bperl\b/$^X/g;
        print "Now you are safe to run the following:\n\n$n\n\n";
        exit;
    };

    # Strip comments
    $code =~ s/\s+\#.*//g;
    # Fake interpolate $LOADER
    $code =~ s/\$LOADER/$LOADER/g;
    # Fake inerpolate $MODULES
    $code =~ s/\$MODULES/$MODULES/g;
    # Fake interpolate $suffix
    $code =~ s/\$suffix/$suffix/g;
    # Jam true VERSION
    $code =~ s/\$VERSION/$IO::Socket::DNS::VERSION/g;
    # Collapse to reduce transport code
    $code =~ s/\s+/ /g;
    return $code;
}

sub unzip_code {
    my $self = shift;
    my $suffix = $self->{"Suffix"};

    # Short program to CREATE the menu.pl program.
    my $code = q{
        $| = 1;
        use strict;
        use warnings;

        my $interp = $^X;
        if ($interp !~ m{[\\/]}) {
            # Make fully qualified absolute search path
            foreach my $path (split m/:/, $ENV{PATH}) {
                my $try = "$path/$interp";
                if (-e $try) {
                    $interp = $try;
                    last;
                }
            }
        }

        if (-e "menu.pl") {
            print "File menu.pl already exists. You must remove it to regenerate a fresh copy.\n";
        }
        else {
            print "Creating menu.pl ...\n";
            open my $fh, ">", "menu.pl" or die "menu.pl: open: $!\n";
            print $fh qq{\#!$interp -w\n};
            print $fh q{
                use strict;
                print "Loading MENU. Please wait...\n";
                my $res = eval {
                    require Net::DNS::Resolver;
                    Net::DNS::Resolver->new;
                };
                my $get_txt = $res ? sub {
                    my $q = shift;
                    # Fast method, but Net::DNS may not be installed.
                    return eval{[$res->query($q,'TXT')->answer]->[0]->txtdata};
                } : sub {
                    my $q = shift;
                    # Slower, but better than relying on Net::DNS to be installed.
                    return $1 if `nslookup -type=TXT $q. 2>&1`=~/"(.+)"/;
                    sleep 1;
                    return $1 if `nslookup -type=TXT $q. 2>&1`=~/"(.+)"/;
                    return undef;
                };
                $_="";
                my $i=0;
                while (++$i and my $b=$get_txt->("menu$i.$suffix")) {$_.=$b}
                $_=pack 'H*', $_;
                if (open my $fh, "+<", $0) {
                    # Self modifying code to spead up future executions.
                    print $fh "#!$^X -w\n";
                    print $fh $_;
                    close $fh;
                    exit if 0 == system $0;
                }
                eval or warn "$_:$@";
            };
            close $fh;
        }
        chmod 0755, "menu.pl";
        print "You can now run: ".($^O=~/Win32/i?"$interp -w ":"./")."menu.pl\n\n";
        exit;
    };
    # Strip comments
    $code =~ s/\s+\#.*//g;
    # Fake interpolate $suffix
    $code =~ s/\$suffix/$suffix/g;
    # Collapse to reduce transport code
    $code =~ s/\s+/ /g;
    return $code;
}

sub menu_code {
    my $self = shift;
    my $suffix = $self->{"Suffix"};

    # Short Menu Program
    my $code = q{
        use strict;
        $| = 1;
        print qq{MENU:\n0. Just print version and exit.\n1. Download IO::Socket::DNS module.\n2. Download dnsc proxy client software.\n3. Download dnsnetcat client software.\n4. Download dnsssh client software.\n5. Run ssh tunneled through dns now.\n6. Install Net::DNS (optional for better performance)\nPlease make your selection: [0] };
        use strict;
        use warnings;

        my $choice = <STDIN>;
        $choice =~ s/\s+$// if defined $choice;
        print "\n\n";
        if (!$choice or $choice < 1 or $choice > 6) {
            print "IO::Socket::DNS VERSION $VERSION\n";
            exit;
        }

        my $files = [
            # Query      File                      Mode
            [ client => "lib/IO/Socket/DNS.pm"  => 0644 ],
            [ dnsc   => "dnsc.pl"               => 0755 ],
            [ dnsnc  => "dnsnetcat.pl"          => 0755 ],
            [ dnsssh => "dnsssh.pl"             => 0755 ],
        ];

        use FindBin qw($Bin);
        if ($Bin) {
            chdir $Bin;
            unshift @INC, "$Bin/lib";
        }
        else {
            unshift @INC, "lib";
        }

        my $res = eval {
            require Net::DNS::Resolver;
            Net::DNS::Resolver->new;
        };
        my $get_txt = $res ? sub {
            my $q = shift;
            # Fast method, but Net::DNS may not be installed.
            return eval{[$res->query($q,'TXT')->answer]->[0]->txtdata};
        } : sub {
            my $q = shift;
            # Slower, but better than relying on Net::DNS
            return $1 if `nslookup -type=TXT $q. 2>&1`=~/"(.+)"/;
            warn "**CHOKE1** $q\n";
            sleep 1;
            return $1 if `nslookup -type=TXT $q. 2>&1`=~/"(.+)"/;
            warn "**CHOKE2** $q\n";
            sleep 1;
            return $1 if `nslookup -type=TXT $q. 2>&1`=~/"(.+)"/;
            warn "**CHOKE3** $q\n";
            return undef;
        };
        my $install = sub {
            my ($pre,$file,$mode) = @_;
            my $dir = "";
            while ($file =~ m{([^/]+)/}g) {
                $dir .= $1;
                mkdir $dir, 0755;
                $dir .= "/";
            }
            my $i = 0;
            my $contents = "";
            print "Downloading $file ...\n";
            my $ticks = 0;
            while (my $txt = $get_txt->("$pre$i.$suffix")) {
                if ($i) {
                    $contents .= $txt;
                    print sprintf "\r(%d/%d) %.1f%%", $i, $ticks, $i/$ticks*100;
                }
                elsif ($txt =~ /^\d+$/) {
                    $ticks = $txt;
                    print "\r0/$ticks";
                }
                else {
                    die "$pre$i: Invalid DNS cache: $txt\n";
                }
                $i++;
                last if $i > $ticks;
            }
            print "\n";
            $contents = pack 'H*', $contents;
            if ($contents) {
                open my $fh, ">", $file;
                if ($file =~ /\.pl$/) {
                    my $interp = $^X;
                    if ($interp !~ m{[\\/]}) {
                        # Make fully qualified absolute search path
                        foreach my $path (split m/:/, $ENV{PATH}) {
                            my $try = "$path/$interp";
                            if (-e $try) {
                                $interp = $try;
                                last;
                            }
                        }
                    }
                    unless ($contents =~ s{^\#\!/\S+}{\#\!$interp}) {
                        print $fh "#!$interp\n";
                    }
                }
                print $fh $contents;
            }
            chmod $mode, $file;
            return 1;
        };

        if ($choice == 6) {
            if (eval {
                require Net::DNS;
                require Net::DNS::Resolver;
            }) {
                warn "Congratulations! Net::DNS already works for you: $INC{'Net/DNS.pm'}\n";
            }
            else {
                my @PREREQ_PM = qw(
                    IO::Socket
                );
                if ($^O eq "MSWin32") {
                    push @PREREQ_PM, qw(
                        Win32::Registry
                        Win32::IPHelper
                    );
                }
                my %broken = ();
                foreach my $module (@PREREQ_PM) {
                    if (!eval "require $module") {
                        $broken{$module} = "$@";
                    }
                }
                if (scalar keys %broken) {
                    foreach my $broken (sort keys %broken) {
                        warn "Unable to install Net::DNS without Prerequisite Module $broken: $broken{$broken}\n";
                    }
                    exit;
                }
                warn "Please wait while Net::DNS is downloaded and installed ...\n";
                if (my $netdns = $get_txt->("netdns.$suffix")) {
                    eval $netdns or warn $@;
                }
            }
            exit;
        }

        for (my $i=0;$i<@$files;$i++) {
            if ($i<$choice) {
                my ($txt,$file,$mode) = @{ $files->[$i] };
                if ($i) {
                    # Don't bother downloading if it's already here.
                    next if -e $file;
                }
                else {
                    if (eval "require IO::Socket::DNS" and
                        $IO::Socket::DNS::VERSION eq "$VERSION") {
                        # Don't bother downloading if it's the same.
                        next;
                    }
                }
                $install->($txt,$file,$mode);
            }
        }

        if ($choice == 5) {
            # Pretent like regular ssh
            if (-x "dnsssh.pl") {
                print "Enter arguments for ssh:\n";
                print "ssh ";
                my $args = <STDIN>;
                chomp $args;
                exec "./dnsssh.pl --suffix=$suffix $args";
            }
            die "dnsssh.pl: Unable to launch fake ssh client: $!\n";
        }
        exit;
    };
    # Strip comments
    $code =~ s/\s+\#.*//g;
    # Fake interpolate $suffix
    $code =~ s/\$suffix/$suffix/g;
    # Jam true VERSION
    $code =~ s/\$VERSION/$IO::Socket::DNS::VERSION/g;
    # Collapse to reduce transport code
    $code =~ s/\s+/ /g;
    return $code;
}

sub client_code {
    my $self = shift;
    warn "DEBUG: Loading [$INC{'IO/Socket/DNS.pm'}] ...\n" if $self->{"Verbose"};
    open my $fh, $INC{"IO/Socket/DNS.pm"} or die "IO/Socket/DNS.pm loaded but not found?";
    my $code = join "", <$fh>;
    close $fh;
    return $code;
}

sub dnsc_code {
    my $self = shift;
    my $Suffix = $self->{"Suffix"};
    my $code = undef;
    foreach my $try (qw(bin/dnsc /bin/dnsc /usr/bin/dnsc /usr/local/bin/dnsc)) {
        if (open my $fh, "<$try") {
            local $/ = undef;
            $code = <$fh>;
            last;
        }
    }
    if (!$code) {
        warn "WARNING! Unable to locate the real dnsc code??\n";
        $code = <<'CODE';
use strict;
use lib qw(lib);
use IO::Socket::DNS;
our $suffix = shift || $ENV{DNS_SUFFIX} || "DNS_Suffix";
print "The IO::Socket::DNS client module has been downloaded correctly\n";
print "But the server was unable to locate the real dnsc source.\n";
print "In order to try again, you should first remove myself: rm $0\n";
CODE
    }
    $code =~ s/DNS_Suffix/$Suffix/g;
    return $code;
}

sub dnsnc_code {
    my $self = shift;
    my $Suffix = $self->{"Suffix"};
    my $code = undef;
    foreach my $try (qw(bin/dnsnetcat /bin/dnsnetcat /usr/bin/dnsnetcat /usr/local/bin/dnsnetcat)) {
        if (open my $fh, "<$try") {
            local $/ = undef;
            $code = <$fh>;
            last;
        }
    }
    if (!$code) {
        warn "WARNING! Unable to locate the real dnsnetcat code??\n";
        $code = <<'CODE';
use strict;
print "Unable to locate the real dnsnetcat source.\n";
print "In order to try again, you should first remove myself: rm $0\n";
CODE
    }
    $code =~ s/DNS_Suffix/$Suffix/g;
    return $code;
}

sub dnsssh_code {
    my $self = shift;
    my $Suffix = $self->{"Suffix"};
    my $code = undef;
    foreach my $try (qw(bin/dnsssh /bin/dnsssh /usr/bin/dnsssh /usr/local/bin/dnsssh)) {
        if (open my $fh, "<$try") {
            local $/ = undef;
            $code = <$fh>;
            last;
        }
    }
    if (!$code) {
        warn "WARNING! Unable to locate the real dnsssh code??\n";
        $code = <<'CODE';
use strict;
print "Unable to locate the real dnsssh source.\n";
print "In order to try again, you should first remove myself: rm $0\n";
CODE
    }
    $code =~ s/DNS_Suffix/$Suffix/g;
    return $code;
}

sub dnsencode { goto &IO::Socket::DNS::dnsencode; }
sub dnsdecode { goto &IO::Socket::DNS::dnsdecode; }
sub encrypt   { goto &IO::Socket::DNS::encrypt; }

sub loop_once {
    my $self = shift;
    $self->SUPER::loop_once(@_);

    my $now = time();
    # Check if any proxy connections have timed out
    foreach my $s (keys %{$self->{"_proxy"}}) {
        next if $self->{"_proxy"}->{$s}->{"timeout"} > $now;
        delete $self->{"_proxy"}->{$s};
    }

    return 1;
}

sub tcp_connection {
    my ($self, $sock) = @_;

    if (!$sock) {
        &Carp::cluck("BUG DETECTED! Found insanity. Why tcp_connection on nothing???");
        return 1;
    }
    #warn Dumper [ full_tcp => $self->{_tcp}, full_proxy => $self->{_proxy} ];
    if (not $self->{"_tcp"}->{$sock} or
        not $self->{"_tcp"}->{$sock}->{"seqid"}) {
        return $self->SUPER::tcp_connection($sock);
    }

    # Special proxy socket
    # Move everything into its storage
    my $buffer = $self->{"_tcp"}->{$sock}->{"inbuffer"};
    $buffer = "" if !defined $buffer;
    if (length $buffer) {
        my $seqid = $self->{"_tcp"}->{$sock}->{"seqid"};
        $self->{"_proxy"}->{$seqid}->{"inbuffer"} .= $buffer;
        $self->{"_proxy"}->{$seqid}->{"timeout"} = $self->{"_tcp"}->{$sock}->{"timeout"};
        $self->{"_tcp"}->{$sock}->{"inbuffer"} = "";
    }

    return 1;
}

1;
__END__

=head1 NAME

IO::Socket::DNS::Server - Net::DNS::Nameserver personality to handle IO::Socket::DNS client connections.

=head1 SYNOPSIS

  use IO::Socket::DNS::Server;

  my $server = new IO::Socket::DNS::Server
    Suffix    => $dns_suffix,
    LocalAddr => \@ips,
    LocalPort => $port,
    Password  => $secret,
    Verbose   => 5,
    IdleTimeout => $timeout,
      or die "Unable to start DNS server";

=head1 DESCRIPTION

Listens for DNS queries in order to proxy for use by IO::Socket::DNS clients.

=head1 CONSTRUCTOR

The "new" constructor takes arguments in key-value pairs:

  Suffix        Proxy DNS Suffix               Required.
  SOA           Authoritative IP for Suffix    Defaults to Suffix's authority
  LocalAddr     IP address on which to listen  Defaults to SOA IP
  LocalPort     Port on which to listen.       Defaults to 53.
  NotifyHandler NS_NOTIFY (RFC1996) handler    Optional.
  Password      Access password                <password>
  Verbose       Used for debugging             Defaults to 0 (off).

The "Suffix" argument is really the only requirement. This setting may also
be passed via the DNS_SUFFIX environment variable. It must be a domain or
subdomain for which queries will authoritatively arrive to the machine
running this IO::Socket::DNS::Server software.

The "SOA" argument is the IP that will be provided in the authority
records for all relevant DNS responses. If none is provided, then it
will attempt to automatically determine this based on Suffix by
resolving all its NS entries found in global propagation.

The "LocalAddr" argument may be one IP or an array ref of IP addresses
to bind to. This defaults to the SOA IP is none is supplied, instead of
the BINY_ANY address that the default Net::DNS::Nameserver uses.

The "NotifyHandler" code ref is the handler for NS_NOTIFY (RFC1996) queries.
This is just passed through to Net::DNS::Nameserver, but it is not required.

The "Password" setting is to ensure only approved IO::Socket::DNS
clients can connect to this server. Only the first 8 characters are used.
This setting may also be passed via the DNS_PASSWORD environment variable.
Default is no password.

If "Verbose" is specified, additional diagnostic information will be sent to STDOUT.

=head1 EXAMPLES

  my $server = IO::Socket::DNS::Server->new(
    Suffix    => "s.example.com",
    SOA       => "199.200.201.202",
    LocalAddr => "192.168.100.2",
    LocalPort => 5353,
    Password  => "No Geeks",
    Verbose   => 6,
  ) or die "connect: $!";

  $ENV{DNS_SUFFIX} = "s.example.com";
  my $server = new IO::Socket::DNS::Server;

  # Continuously handle requests
  $server->main_loop;


=head1 SEE ALSO

dnsd, Net::DNS::Nameserver, IO::Socket::DNS

=head1 AUTHOR

Rob Brown, E<lt>bbb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Rob Brown

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.9 or,
at your option, any later version of Perl 5 you may have available.

=cut
