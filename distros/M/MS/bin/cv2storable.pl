#!/usr/bin/perl

use strict;
use warnings;

use Storable qw/nstore_fd/;
use List::Util qw/any/;
use Getopt::Long;

my ($fn_ms, $fn_mod, $fn_mi, $fn_ims, $fn_uo, $dump) = (undef) x 6;

GetOptions(
    'ms=s'  => \$fn_ms,
    'mi=s'  => \$fn_mi,
    'mod=s' => \$fn_mod,
    'ims=s' => \$fn_ims,
    'uo=s'  => \$fn_uo,
    'dump'  => \$dump,
);

my $terms;
my %used;

parse_obo($_) for (
    ['MS'   => $fn_ms  ],
    ['MI'   => $fn_mi  ],
    ['MOD'  => $fn_mod ],
    ['IMS'  => $fn_ims ],
    ['UO'   => $fn_uo  ],
);

if ($dump) {

        use Data::Dumper;
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        print Dumper $terms;
        exit;

}

binmode STDOUT;
nstore_fd $terms => \*STDOUT or die "Error writing Storable to disk: $@\n";

exit;



sub parse_obo {

    my ($prefix, $fn) = @{ $_[0] };

    open my $in, '<', $fn or die "Failed to open OBO file $fn for reading";

    my $is_term = 0;
    my $curr_term;

    no strict 'refs';

    LINE:
    while (my $line = <$in>) {

        chomp $line;
        next if ($line !~ /\S/);

        if ($line =~ /^\[([^\]]+)\]/) {
            $is_term = $1 eq 'Term';

            next LINE if (! defined $curr_term->{id});
            my $id = $curr_term->{id};
            delete $curr_term->{id};

            my $tmp_term = $curr_term;
            $curr_term = {};
            $tmp_term->{cv} = $prefix;

            next LINE if ($tmp_term->{is_obsolete});


            # special case - a special class of terms in the MS CV represent
            # regular expressions associated with cleavage reagents. It
            # doesn't make sense to autogenerate constants for these as their
            # names are in RE syntax. Track this and skip constant generation
            # for these.
            my $is_regex = 0;

            if (defined $tmp_term->{is_a}) {
                for my $parent (@{ $tmp_term->{is_a}}) {
                    $terms->{$parent}->{children}->{$id} = 1;

                    # special case for cleavage agent regular expressions
                    $is_regex = 1 if ($parent eq 'MS:1001180');
                }
            }

            my $const_name = uc($prefix . '_' . $tmp_term->{name} );

            if (! $is_regex && defined $const_name) {

                $const_name =~ s/\W/_/g;

                my $tmp = $const_name;
                if (defined $used{$const_name}) {
                    warn "$tmp already used!\n";
                    my $id = $used{$const_name};
                    if (length($id)) {
                       $terms->{$id}->{constant} = $tmp . '_1'; 
                    }
                    $used{$const_name} = '';
                    $const_name .= '_2';
                }
                my $i = 3;
                while (defined $used{$const_name}) {
                    warn "$tmp already used!\n";
                    $const_name = $tmp . '_' . $i++;
                }
                $used{$const_name} = $id;
                $tmp_term->{constant} = $const_name;

            }
            
            # copy values individually in case hash entry already exists
            $terms->{$id}->{$_} = $tmp_term->{$_}
                for (keys %{$tmp_term});

        }
        elsif ($is_term) {
            if ( $line =~ /^(\w+):\s*(.+)$/ ) {
                my $key = $1;
                next if (! any {$key eq $_} qw/id name def is_a is_obsolete relationship/);
                my $val = $2;
                $val =~ s/\s*(?<!\\)\!.*$//; # remove comments
                $val =~ s/\\\!/\!/g; # remove escaping
                if ($key eq 'is_a') {
                    push @{$curr_term->{$key}}, $val;
                }
                elsif ($key eq 'relationship') {
                    my ($type, $id) = split ' ', $val;
                    push @{$curr_term->{$type}}, $id;
                }
                else {
                    $curr_term->{$key} = $val;
                }
            }
        }

    } 

    use strict 'refs';

    close $fn;

}
