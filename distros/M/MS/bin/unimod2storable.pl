#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use HTTP::Tiny;
use JSON qw/decode_json/;
use XML::Twig;
use Storable qw/nstore/;

my $twig = XML::Twig->new(
    twig_roots => {
        'umod:elem'  => \&parse_simple,
        'umod:aa'    => \&parse_simple,
        'umod:brick' => \&parse_simple,
        'umod:mod'   => \&parse_mod,
    },
    start_tag_handlers => {
        'umod:unimod' => \&parse_meta,
    },

);

my $fi_unimod;
my $fi_elements;
my $fo_storable;
my $dump = 0;

GetOptions(
    'unimod=s'   => \$fi_unimod,
    'elements=s' => \$fi_elements,
    'out=s'      => \$fo_storable,
    'dump'       => \$dump,
);

my ($fn_in, $fn_out) = @ARGV;

my $unimod = {};
$twig->parsefile($fi_unimod);

fetch_missing_elements($unimod);

if ($dump) {
    use Data::Dumper;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    print Dumper $unimod;
}

nstore $unimod => $fo_storable or die "Error writing Storable to disk: $@\n";

exit;


sub parse_meta {

    my ($twig, $tag) = @_;

    my $attrs = $tag->atts;

    # check for presence of expected meta attributes
    for (qw/xmlns:umod majorVersion minorVersion/) {
        die "Missing expected meta $_\n" if (! defined $attrs->{$_});
    }

    # check namespace compatibility
    my $ns = $attrs->{'xmlns:umod'} // '';
    if ($ns ne 'http://www.unimod.org/xmlns/schema/unimod_2') {
        die "There is a mismatch between the namespace declaration in the"
            . " Unimod XML and that supported by this converter. This is"
            . " likely because the Unimod schema has been updated. Please"
            . " report this to the developers.\n";
    }

    $unimod->{db_version}
        = $attrs->{majorVersion} . '.' . $attrs->{minorVersion};

}
    


sub parse_simple {

    my ($twig, $elt) = @_;

    my $tag = $elt->tag;
    $tag =~ s/^umod://;

    # check for common attributes
    my $attrs = $elt->atts;
    for (qw/title full_name mono_mass avge_mass/) {
        die "Missing meta $_ for elt $tag\n" if (! defined $attrs->{$_});
    }

    # parse attributes
    my $title = $attrs->{title};
    delete $attrs->{title};
    $unimod->{$tag}->{$title} = $attrs;

    # parse element composition
    for my $atom ($elt->children('umod:element')) {
        my $attrs = $atom->atts;
        for (qw/symbol number/) {
            die "Missing meta $_ for elt\n" if (! defined $attrs->{$_});
        }
        $unimod->{$tag}->{$title}->{atoms}->{ $attrs->{symbol} }
            = $attrs->{number};
    }

    $twig->purge;
    return;

}

sub parse_mod {
    
    my ($twig, $elt) = @_;

    my $tag = $elt->tag;
    $tag =~ s/^umod://;

    my $attrs = $elt->atts;
    for (qw/title full_name record_id/) {
        die "Missing meta $_ for elt $tag\n" if (! defined $attrs->{$_});
    }
    my $title = $attrs->{title};

    my $delta = $elt->first_child('umod:delta')
        or die "failed to find delta elt";
    my $mono  = $delta->att('mono_mass');
    my $avg   = $delta->att('avge_mass');
    die "Error parsing delta masses for mod $title\n"
        if (! defined $mono || !  defined $avg);
    $unimod->{$tag}->{$title}->{mono_mass} = $mono;
    $unimod->{$tag}->{$title}->{avge_mass} = $avg;
    $unimod->{$tag}->{$title}->{full_name} = $attrs->{full_name};
    $unimod->{$tag}->{$title}->{record_id} = $attrs->{record_id};

    # store mappings of record_id to title
    $unimod->{mod_index}->{$attrs->{record_id}} = $title;

    # parse element composition
    for my $atom ($delta->children('umod:element')) {
        my $attrs = $atom->atts;
        for (qw/symbol number/) {
            die "Missing meta $_ for elt\n" if (! defined $attrs->{$_});
        }
        print STDERR "$attrs->{symbol} to $attrs->{number}\n";
        $unimod->{$tag}->{$title}->{atoms}->{ $attrs->{symbol} }
            = $attrs->{number};
    }

    $unimod->{$tag}->{$title}->{hashref} = $elt->simplify(
        forcearray => [qw/
            umod:element
            umod:specificity
            umod:Ignore
            umod:alt_name
            umod:xref
            umod:NeutralLoss
            umod:PepNeutralLoss
       /],
    );

    $twig->purge;
    return;

}

sub fetch_missing_elements {

    my ($unimod) = @_;

    my %elements;

    open my $in, '<', $fi_elements;
    while (my $line = <$in>) {

        next if ($line =~ /^\s*#/);
        chomp $line;
        my ($num, $sym, $name) = split ',', $line;
        $elements{$name} = $sym;

    }
    close $in;

    my $ua = HTTP::Tiny->new();

    ELEM:
    for my $el (keys %elements) {

        say STDERR "Fetching $el";

        my $url = sprintf
            "https://pubchem.ncbi.nlm.nih.gov/rest/pug/compound/fastformula/%s/JSON?MaxRecords=1",
            $elements{$el},
        ;

        my $res = $ua->get($url);

        if (! $res->{success}) {
            warn "Failed to fetch data for $el: $res->{reason}\n";
            next ELEM;
        }

        my $data = decode_json( $res->{content} );
        my @mono = grep {$_->{urn}->{label} eq 'Weight' && $_->{urn}->{name} eq 'MonoIsotopic'} @{ $data->{PC_Compounds}->[0]->{props} };
        die "Missing or too many mono masses for $el\n"
            if (scalar @mono != 1);
        my @avg = grep {$_->{urn}->{label} eq 'Molecular Weight' } @{ $data->{PC_Compounds}->[0]->{props} };
        die "Missing or too many avg masses for $elements{$el}\n"
            if (scalar @avg != 1);

        my $mass_avg = $avg[0]->{value}->{fval}
            // die "Missing avg mass for $el";
        my $mass_mono = $mono[0]->{value}->{fval}
            // die "Missing mono mass for $el";
        
        my $existing = $unimod->{elem}->{ $elements{$el} };
        if (defined $existing) {
            my $prev = $existing->{mono_mass};
            my $delta = abs($prev - $mass_mono);
            if ($delta > 0.01) {
                die "Disageement in mono mass: prev $prev, curr $mass_mono\n";
            }
        }
        else {
            $unimod->{elem}->{ $elements{$el} } = {
                full_name => $el,
                avge_mass => $mass_avg,
                mono_mass => $mass_mono,
            };
            say STDERR "\tAdded $el";
        }

    }

}

