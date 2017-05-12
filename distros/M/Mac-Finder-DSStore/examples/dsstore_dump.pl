#
#  "Symbolic" dump of records to stdout
#
#  This does not precisely reproduce its input, but should be
#  equivalent (some probably-meaningless fields are not preserved)
#

use Mac::Finder::DSStore::BuddyAllocator;
use Mac::Finder::DSStore;
use IO::File;
use Data::Dumper;
use Getopt::Long;
use Config;

our($opt_aliases) = 'p';
our($opt_plists) = 'p';
GetOptions('resolve-aliases' => sub { $opt_aliases = 'r'; },
           'parse-aliases' => sub { $opt_aliases = 'p'; },
           'raw-aliases' => sub { $opt_aliases = 'n'; },
           'parse-plists' => sub { $opt_plists = 'p'; },
           'raw-plists' => sub { $opt_plists = 'n'; })
    or &usage;
( @ARGV == 1 ) or &usage;

sub usage {
    print STDERR <<"EOM";
Usage: $0 [options] /path/to/.DS_Store > result.pl
\t--raw-aliases\tDo not interpret alias data
\t--resolve-aliases\tResolve aliases to filenames using Mac OS calls
\t--parse-aliases\tParse aliases using Mac::Alias::Parse
\t--raw-plists\tDo not interpret bplist data
\t--parse-plists\tParse bplists using Mac::PropertyList

The default alias handling is --resolve-aliases, but this requires
the Mac::Files module to be installed.
EOM
    exit 1;
}

%byFilename = ( );
$want_alias = '';
$want_plist = '';

$filename = $ARGV[0];
die "$0: $filename: not a file?\n" unless -f $filename;
$store = Mac::Finder::DSStore::BuddyAllocator->open(new IO::File $filename, '<');
foreach my $rec (&Mac::Finder::DSStore::getDSDBEntries($store)) {
    push(@{$byFilename{$rec->filename}}, $rec);
    $want_alias = $opt_aliases if $rec->strucId eq 'pict';
    $want_plist = $opt_plists  if $rec->strucId =~ /^(bwsp|lsvp|lsvP|icvp)$/;
}
undef $store;

if ($want_alias eq 'r') {
    eval {
        require Mac::Files;
        Mac::Files->import( );
        require Mac::Memory;
    } or die "Could not load Mac::Files. Unable to resolve aliases.\n";
}
if ($want_alias eq 'p') {
    eval {
        require Mac::Alias::Parse;  # No imports
    } or die "Could not load Mac::Alias::Parse. Unable to parse aliases.\n";
}
if ($want_plist eq 'p') {
#    eval {
        require Mac::PropertyList::ReadBinary;
        Mac::PropertyList::ReadBinary->import( );
#    } or die "Could not load Mac::PropertyList::ReadBinary. Unable to parse plists.\n";
    eval {
        require Mac::PropertyList::WriteBinary;
    } or warn "Could not find Mac::PropertyList::WriteBinary. Dumped records will not be loadable.\n";
}

print "#!" . $Config{perlpath} . " -w\n\n";

print "use Mac::Finder::DSStore qw( writeDSDBEntries makeEntries );\n";

if ($want_alias eq 'r') {
    # Older MacPerls have some sort of problem autoloading Handle if you
    # don't explicitly import Mac::Memory
    print "use Mac::Memory qw( );\n";
    print "use Mac::Files qw( NewAliasMinimal );\n";
}
if ($want_alias eq 'p') {
    print "use Mac::Alias::Parse qw( packAliasRec );   # Pure-Perl alias record\n";
}
if ($want_plist eq 'p') {
    print "use Mac::PropertyList::WriteBinary qw ( );"
}

print "\n";

print '&writeDSDBEntries(', &repr($filename);

foreach $fn (sort keys %byFilename) {
    my(%recs) = map { $_->strucId, $_->value } @{$byFilename{$fn}};
    my(@lines);

    if (!exists($recs{'BKGD'})) {
        # pass
    } elsif ($recs{'BKGD'} =~ /^DefB/ ) {
        push(@lines, 'BKGD_default');
        delete $recs{'BKGD'};
    } elsif ($recs{'BKGD'} =~ /^ClrB/ ) {
        my(@rgb) = unpack('x4 nnn', $recs{'BKGD'});
        push(@lines, sprintf("BKGD_color => '#%02X%02X%02X'", @rgb));
        delete $recs{'BKGD'};
    } elsif ($recs{'BKGD'} =~ /^PctB/ && exists($recs{'pict'})) {
        my($l, $a, $b) = unpack('x4 N nn', $recs{'BKGD'});
        if($l == length($recs{'pict'})) {
            my($user, $alias_len) = unpack('Nn', $recs{'pict'});
            warn "Possible extra data in BKGD alias entry: udata=$user, ".($l - $alias_len)." bytes trailing data\n"
                if ($user != 0 or $alias_len != $l);
            my($repr);
            if ($opt_aliases eq 'r') {
                $repr = &as_resolved_alias($recs{'pict'});
            } elsif ($opt_aliases eq 'p') {
                $repr = &as_parsed_alias($recs{'pict'});
            }
            if (defined($repr)) {
                push(@lines, $repr);
                delete $recs{'BKGD'};
                delete $recs{'pict'};
            }
        }
    }

    if(exists($recs{'Iloc'})) {
        my(@xyn) = unpack('NNnnnn', $recs{'Iloc'});
        &pop_matching(\@xyn, 65535, 65535, 65535, 0);
        push(@lines, 'Iloc_xy => '.&repr(\@xyn, 1));
        delete $recs{'Iloc'};
    }

    if(exists($recs{'icvo'}) && $recs{'icvo'} =~ /^icv4/) {
        push(@lines, "icvo => ".&as_unpacked('A4 n A4 A4 n*', $recs{'icvo'}));
        delete $recs{'icvo'};
    }

    if(exists($recs{'fwi0'}) && length($recs{'fwi0'}) == 16) {
        my(@flds) = unpack('n4 A4 n*', $recs{'fwi0'});
        push(@lines, 'fwi0_flds => '.&repr(\@flds, 1));
        delete $recs{'fwi0'};
    }

    for my $struc ('lsvp', 'lsvP', 'bwsp', 'icvp') {
        if(exists($recs{$struc})) {
            my(@r) = &as_bplist($recs{$struc});
            $r[0] = "$struc => ".$r[0];
            push(@lines, @r);
            delete $recs{$struc};
        }
    }

    foreach my $k (keys %recs) {
        my($qqv) = &repr($recs{$k});
        my($hexv) = "'" . unpack('H*', $recs{$k}) . "'";

        push(@lines,
             ((length($qqv) > length($hexv)) ? "${k}_hex => $hexv" : "$k => $qqv"));
    }

    print ",\n    &makeEntries(", &repr($fn);
    if (1 == @lines and length($lines[0]) < 50) {
        print ", ", $lines[0], ")";
    } else {
        print ",\n        $_" foreach sort @lines;
        print "\n    )";
    }
}
print "\n);\n\n";

sub pop_matching {
    my($from, @what) = @_;

    while(@$from && @what && ($from->[$#$from] == $what[$#what])) {
        pop(@$from);
        pop(@what);
    }
}

sub repr {
    my($v, $pack) = @_;
    my($dumper) = Data::Dumper->new([ $v ]);
    $dumper->Useqq(1);
    $dumper->Terse(1);
    my($repr) = $dumper->Dump;
    chomp $repr;
    $repr =~ s/\s*\n\s+/ /g if $pack;
    $repr;
}

sub as_unpacked {
    my($fmt, $buf) = @_;

    my(@flds) = unpack($fmt, $buf);
    return "pack('$fmt', ".join(', ', map { &repr($_, 1) } @flds).')';
}

sub as_resolved_alias {
    my($pict) = @_;
    my($hdl) = new Handle( $pict );
    my($unalias) = Mac::Files::ResolveAliasRelative($filename, $hdl);
    if ($unalias) {
        return 'BKGD_alias => NewAliasMinimal('.&repr($unalias).')';
    }
    return undef;
}

sub as_parsed_alias {
    my($pict) = @_;
    
    my($parsed) = Mac::Alias::Parse::unpackAliasRec($pict);
    my(@keys) = sort { $a cmp $b } keys %$parsed;
    my($dumper) = Data::Dumper->new([ @{$parsed}{@keys} ]);
    $dumper->Pad( ' ' x 12 );
    $dumper->Useqq(1);
    $dumper->Terse(1);
    $dumper->Quotekeys(0);
    $dumper->Sortkeys(1);
    my(@dumped) = $dumper->Dump();
    my($result) = '';
    foreach my $ix (0 .. $#keys) {
        my($s) = $dumped[$ix];
        $s =~ s/^( {0,12})/$1 . $keys[$ix] . ' => '/e;
        $s =~ s/\n$//;
        $s .= ",\n" if $ix < $#keys;
        $result .= $s;
    }
    return "BKGD_alias => &packAliasRec(\n$result)";
}

sub as_bplist {
    my($bplist) = @_;
    my($val) = Mac::PropertyList::parse_plist($bplist);
    my($dumper) = Data::Dumper->new([ $val ]);
    $dumper->Useqq(1);
    $dumper->Terse(1);
    my($repr) = $dumper->Dump;
    chomp $repr;
    "Mac::PropertyList::WriteBinary::as_string($repr)";
}
