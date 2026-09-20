#!/usr/bin/perl

use strict;
use warnings;

use Storable qw/nstore_fd retrieve/;
use List::MoreUtils qw/any/;
use Getopt::Long;

my ($fn_ms, $fn_mod, $fn_mi, $fn_ims, $fn_uo, $dump) = (undef) x 6;
my $fn_existing;
my $force_new = 0;
my $old_fix = 0;

GetOptions(
    'ms=s'  => \$fn_ms,
    'mi=s'  => \$fn_mi,
    'mod=s' => \$fn_mod,
    'ims=s' => \$fn_ims,
    'uo=s'  => \$fn_uo,
    'dump'  => \$dump,
    'existing=s' => \$fn_existing,
    'force_new'  => \$force_new,
    'old_fix'    => \$old_fix,
);

my $existing;
if ($force_new) {
    warn "***You have requested to force a new constant table. This WILL likely break backward compatibility of the CV constants, as the OBOs change rapidly and clashing names may change. I hope you know what you are doing!!!***\n";
}
else {
    die "Must specify existing Storable file to verify that no constants have changed. If you REALLY know what you are doing, you may override this with '--force_new', but you may break backward compatibility of CV constants\n"
        if (! defined $fn_existing);
    $existing = retrieve($fn_existing);
}

my $terms;
my %used;

# NOTE: if you add to or change these overrides, be sure to update the
# corresponding documentation in the MS::CV POD
my $overrides = {
    'MS_M+H ION' => 'M_PLUS_H_ION',
    'MS_M-H ION' => 'M_MINUS_H_ION',
};

parse_obo($_) for (
    ['MS'   => $fn_ms  ],
    ['MI'   => $fn_mi  ],
    ['MOD'  => $fn_mod ],
    ['IMS'  => $fn_ims ],
    ['UO'   => $fn_uo  ],
);

#transfer regular expressions
for my $v (values %{ $terms }) {
    next if (! defined $v->{has_regexp});
    die "Multiple regular expressions not supported for $v->{name}\n"
        if (defined $v->{has_regexp}->[1]);
    my $re = $terms->{ $v->{has_regexp}->[0] }
        // die "Missing linked RE term for $v->{name}\n";
    die if (! length $re->{name});
    $v->{regexp} = $re->{name};
    delete $v->{has_regexp};
}

#remove partials and regexps
for my $k (keys %{ $terms }) {
    delete $terms->{$k}
        if (! defined $terms->{$k}->{constant});
}

if ($dump) {

        use Data::Dumper;
        local $Data::Dumper::Indent   = 1;
        local $Data::Dumper::Terse    = 1;
        local $Data::Dumper::Sortkeys = 1;
        print Dumper $terms;
        exit;

}

# check that nothing has changed from current constant table
my $old_constants = extract_constants($existing);
my $new_constants = extract_constants($terms);
for my $const (keys %{ $old_constants }) {
    # this block deals with a bug in previous versions that contained carriage
    # returns in the PSI-MOD file
    if ($old_fix && $const =~ /^MOD_/) {
        my $cn = $const;
        $cn =~ s/_$//;
        if (! defined $new_constants->{$cn}) {
            die "Missing $cn ($old_constants->{$const}) in new table\n"
        }
        elsif ($new_constants->{$cn} ne $old_constants->{$const}) {
            die "Mismatched $const (old: $old_constants->{$const},"
                . " new: $new_constants->{$cn})\n";
        }
    }
    else {
        if (! defined $new_constants->{$const}) {
            warn "Missing $const ($old_constants->{$const}) in new table\n";
            my $id = $old_constants->{$const};
            if (defined $terms->{$id}) {
                warn "Adding $const as alternative for $id\n";
                push @{ $terms->{$id}->{alt_constants} }, $const;
            }
            else {
                die "No place found to put constant $const\n";
            }
        }
        elsif ($new_constants->{$const} ne $old_constants->{$const}) {
            die "Mismatched $const (old: $old_constants->{$const},"
                . " new: $new_constants->{$const})\n";
        }
    }
}

# final check for clashing constants
my %used_final;
for my $id (keys %{ $terms }) {
    my $constant = $terms->{$id}->{constant}
        // die "Missing constant in final check for $id\n";
    die "Duplicate constant $constant ($id, $used_final{$constant})\n"
        if (defined $used_final{$constant});
    $used_final{$constant} = $id;
    my $alt = $terms->{$id}->{alt_constants};
    if (defined $alt) {
        for my $constant (@{ $alt }) {
            die "Duplicate constant $constant ($id, $used_final{$constant})\n"
                if (defined $used_final{$constant});
            $used_final{$constant} = $id;
        }
    }
}

binmode STDOUT;
nstore_fd $terms => \*STDOUT or die "Error writing Storable to disk: $@\n";

exit;

sub parse_obo {

    my ($prefix, $fn) = @{ $_[0] };

    open my $in, '<', $fn or die "Failed to open OBO file $fn for reading";

    my $is_term = 0;
    my $curr_term;

    LINE:
    while (my $line = <$in>) {

        chomp $line;
        next if ($line !~ /\S/);

        if ($line =~ /^\[([^\]]+)\]/) {
            $is_term = $1 eq 'Term';

            next LINE if (! defined $curr_term->{id});
            my $id = $curr_term->{id};
            delete $curr_term->{id};
            my $term_prefix = $prefix;
            if ($id =~ /^([^:]+):([^:]+)$/) {
                $term_prefix = $1;
            }
            else {
                die "Unable to parse term ID: $id\n";
            }

            my $tmp_term = $curr_term;
            $curr_term = {};
            $tmp_term->{cv} = $term_prefix;

            if (defined $terms->{$id}->{constant}) {
                warn "Found duplicate: $id (skipping)\n";
                next LINE;
            }
            #next LINE if ($tmp_term->{is_obsolete});


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

            my $const_name = uc($term_prefix . '_' . $tmp_term->{name} );

            if (! $is_regex && defined $const_name) {
               
                # handle special cases
                $const_name = $overrides->{$const_name}
                    if (defined $overrides->{$const_name});
                $const_name =~ s/\W/_/g;


                my $tmp = $const_name;
                if (defined $used{$const_name}) {
                    #next LINE if ($tmp_term->{is_obsolete});
                    warn "$tmp already used!\n";
                    my $id = $used{$const_name};
                    if (length($id)) {
                        $terms->{$id}->{constant} = $tmp . '_1'; 
                        if ($existing->{$id}->{constant} && $existing->{$id}->{constant} eq $tmp) {
                            push @{$terms->{$id}->{alt_constants}}, $tmp; 
                        }
                    }
                    $used{$const_name} = '';
                    $const_name .= '_2';
                }
                my $i = 3;
                while (defined $used{$const_name}) {
                    warn "$tmp already used!\n";
                    $const_name = $tmp . '_' . $i++;
                }
                 
                # for backward-compatibility
                if ($prefix ne $term_prefix) {
                    my $alt = $const_name;
                    $alt =~ s/^$term_prefix/$prefix/;
                    #push @{$terms->{$id}->{alt_constants}}, $alt;
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

    close $fn;

}

sub extract_constants {

    my ($ref) = @_;

    my %map;
    TERM:
    for my $term (keys %{$ref}) {
        my $t = $term;
        if ($old_fix) {
            $t =~ s/\s+$//; # handle old bug (for now)
        };
        my $c = $ref->{$term}->{constant};
        if (! defined $c) {
            warn "Missing constant for $term\n";
            next TERM;
        }
        $map{$c} = $t;
        if (defined $ref->{$term}->{alt_constants}) {
            for my $a (@{ $ref->{$term}->{alt_constants} }) {
                $map{$a} = $t;
            }
        }
    }
    return \%map;

}
