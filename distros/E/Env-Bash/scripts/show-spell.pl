#!/usr/bin/perl

use warnings;
use strict;
use Env::Bash;
use Data::Dumper;
use Getopt::Std;

my %opt;
unless (getopts('dl', \%opt)) {
    usage();
}

# tie a hash to /etc/sorcery/config, no ForceArray
my %env = ();
tie %env, "Env::Bash", Source => "/etc/sorcery/config",
    Debug => $opt{d};

# find the GRIMOIRE directory
my $grimoire = $env{GRIMOIRE} || die "cannot find GRIMOIRE\n";

# display spells in the grimoire if option -l
if( $opt{l} ) {
    print "---spells in grimoire-------------------------\n";
    my @spells = ();
    for my $spell( <$grimoire/*> ) {
        $spell =~ s,.*/,,;
        push @spells, $spell;
    }
    print "$_\n" for sort @spells;
}

# show spells on command line, or linux if none given
show_spell( $_ ) for @ARGV;
show_spell( 'linux' ) unless @ARGV || $opt{l};

sub show_spell
{
    my $spell = shift;

    # find the spell and DETAILS
    unless( -e "$grimoire/$spell" ) {
        warn "Spell '$spell' not found.\n";
        return;
    }
    my $details = -d _ ? "$grimoire/$spell/DETAILS" : "$grimoire/$spell";
    unless( -e "$details" ) {
        warn "Spell '$spell' DETAILS not found.\n";
        return;
    }

    # tie a hash to /etc/sorcery/config and DETAILS w/ForceArray
    my %env = ();
    tie %env, "Env::Bash",
    [],
    Source => [ "/etc/sorcery/config", $details ],
    Debug => $opt{d};

    print "---$spell-------------------------------------\n";
    show_detail( VERSION   => \%env );
    show_detail( CATEGORY  => \%env );
    show_detail( ATTRIBUTE => \%env );
    show_detail( SOURCE    => \%env );
    show_detail( URL       => \%env );
    show_detail( HOMEPAGE  => \%env );
    show_detail( REQ       => \%env );
    show_detail( PROTECT   => \%env );
    show_detail( ESTIMATE  => \%env );
    show_detail( DESC      => \%env );
}

sub show_detail
{
    my( $name, $env ) = @_;

    # get the requested detail ( return is an array because the
    # the $env hash was tied with ForceArray ( [] ).
    my $values = $env->{$name};

    # print each detail
    my $eq = '=';
    for my $value( @$values ) {
        $value = join( "\n".' ' x 14, split /\n/, $value )
            if $value =~ /\n/s;
        printf "%12s%1s\"%s\"\n", $name, $eq, $value;
        $name = $eq = '';
    }
}

sub usage
{
    my $progname = $0;
    $progname =~ s,.*/,,;    # only basename left in progname
    die "Usage: $progname [-d] [-l] <spell> [<spell> ...]\n";
}

__END__
