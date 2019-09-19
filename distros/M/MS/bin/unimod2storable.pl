#!/usr/bin/perl

use strict;
use warnings;

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

my ($fn_in, $fn_out, $dump) = @ARGV;

my $unimod = {};
$twig->parsefile($fn_in);

if ($dump) {
    use Data::Dumper;
    local $Data::Dumper::Indent   = 1;
    local $Data::Dumper::Terse    = 1;
    local $Data::Dumper::Sortkeys = 1;
    print Dumper $unimod;
    exit;
}

nstore $unimod => $fn_out or die "Error writing Storable to disk: $@\n";

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
    my $id = $attrs->{record_id};

    my $delta = $elt->first_child('umod:delta')
        or die "failed to find delta elt";
    my $mono  = $delta->att('mono_mass');
    my $avg   = $delta->att('avge_mass');
    die "Error parsing delta masses for mod $id\n"
        if (! defined $mono || !  defined $avg);

    # parse element composition
    for my $atom ($delta->children('umod:element')) {
        my $attrs = $atom->atts;
        for (qw/symbol number/) {
            die "Missing meta $_ for elt\n" if (! defined $attrs->{$_});
        }
        $unimod->{$tag}->{$id}->{atoms}->{ $attrs->{symbol} }
            = $attrs->{number};
    }

    $unimod->{$tag}->{$id}->{mono_mass} = $mono;
    $unimod->{$tag}->{$id}->{avge_mass} = $avg;
    $unimod->{$tag}->{$id}->{full_name} = $attrs->{full_name};
    $unimod->{$tag}->{$id}->{title}     = $attrs->{title};

    # store mappings of record_id to title
    $unimod->{mod_index}->{$attrs->{title}} = $id;

    $unimod->{$tag}->{$id}->{hashref} = $elt->simplify(
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
