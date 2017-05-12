#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Test::More;
use Test::Exception;

### test that we pass/fail the same specs as Getopt::Long (GoL)
### then test for semantic compliance, as much as possible

# The following specs are considered valid by GoL
my @GOOD_SPECS = (
    'foo|f!',
    'foo|f+',
    'foo|f=i',
    'foo|f:i',
    'foo|f:+',
    'foo|f:5',
    'foo',
    'foo|bar|f',
    '_foo|_bar',
    'foo|f',
    'foo|f|g|h',
    'bar|b=s@{1,5}',
    'bar|b=s@{1,}',
    'bar|b=s@{1}',
    'bar|b=s@{1}',
    'bar|b=s@{,5}',
    'bar|b=s%',

    # The following *should* be bad, but GoL doesn't reject them!?
    'bar|b=s@{,}',
    'bar|b=s@{}',

    # The following are just potiential corner cases I dreamed up
    'foo|f|no-foo|nofoo|nof|no-f!',
);

# The following specs are considered invalid by GoL
my @BAD_SPECS = ( 'foo=', 'foo:', 'foo=k', 'foo*', );

my $tests_per_spec  = 3;  ## KEEP THIS UP-TO-DATE!!!
my $spec_count      = @GOOD_SPECS + @BAD_SPECS;
my $spec_test_count = $spec_count * $tests_per_spec;
my $use_test_count  = 2;

plan( tests => $spec_test_count + $use_test_count );

my $CLASS = 'Getopt::Long::Spec::Parser';

use_ok( $CLASS ) or die "Couldn't compile [$CLASS]\n";
use_ok( 'Getopt::Long' ) or die "couldn't use [Getopt::Long]!\n";

# combining both good and bad sets in one loop 'cause I'm lazy...
# will separate if/when somebody needs it.
for my $spec ( @GOOD_SPECS, @BAD_SPECS ) {

    # if ! defined $opt_name, err msg is in $orig_opt_name. GoL May
    # throw warnings if duplicate opt names are already in %opctl.
    # (not a problem here, but can be in real-life use)
    my %opctl;
    my ( $opt_name, $orig_opt_name )
        = Getopt::Long::ParseOptionSpec( $spec, \%opctl );

    my $valid_test_descr   = "valid spec parses: [$spec]";
    my $invalid_test_descr = "invalid spec causes die(): [$spec]";
    defined $opt_name
        ? lives_ok( sub { $CLASS->parse( $spec ) }, $valid_test_descr )
        : dies_ok( sub { $CLASS->parse( $spec ) }, $invalid_test_descr );

    SKIP: {
        skip( "additional compliance tests not needed on invalid spec", 2 )
            unless defined $opt_name;

        ### write tests to verify that GoNE's parse
        ### semantically matches Getopt::Long
        ### like aliases et al...

        my %gone_data = $CLASS->parse( $spec );

        check_name_compliance( \%gone_data, \%opctl, $opt_name );
        check_value_type_compliance( \%gone_data, \%opctl );

    }

}

### Make sure GoNE figures out the same set of names as GoL.
sub check_name_compliance {
    my ( $gone_data, $opctl, $opt_name ) = @_;

    my $gone_name    = $gone_data->{long};
    my @gone_aliases = @{ $gone_data->{aliases} };

    my %gone_names =
        map  { $_ => 1 }
        grep { $_ and length $_ }
        $gone_name, @gone_aliases, $gone_data->{short}, @{$gone_data->{negations}};

#        print Dumper($gone_data, $opctl, $opt_name); exit;

    my @missing_from_gone
        = grep { !exists $gone_names{$_} } sort keys %$opctl;
    my @extra_from_gone = grep { !exists $opctl->{$_} } sort keys %gone_names;

    is_deeply( \@missing_from_gone, [],
        "no option names from GoL missing from GoNE" )
        or diag( "names missing from GoNE: [ "
            . join( ', ', @missing_from_gone )
            . " ]" );

    is_deeply( \@extra_from_gone, [],
        "no option names from GoNE missing from GoL" )
        or diag(
        "extra names in GoNE: [ " . join( ', ', @extra_from_gone ) . " ]" );
}

### Make sure GoNE figures out the same option type as GoL.
### TODO write this code :)
sub check_value_type_compliance {return}

