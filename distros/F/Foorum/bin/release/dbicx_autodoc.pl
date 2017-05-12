#!/usr/bin/perl -w

package DBICx::AutoDoc2;    ## no critic

use Moose;
extends 'DBICx::AutoDoc';

override 'filename_base' => sub {
    return 'Foorum-Schema';
};

1;

package main;

use strict;
use FindBin qw/$Bin/;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', '..', 'lib' );
use Data::Dumper;

my $ad = DBICx::AutoDoc2->new(
    schema => 'Foorum::Schema',
    output => File::Spec->catdir( $Bin, '..', '..', 'docs' ),
);

$ad->include_path( File::Spec->catdir( $Bin, 'autodoc-templates' ) );
$ad->fill_template('AUTODOC.html');

# rewrite the Schema pm POD
use Template;

my $tt2 = Template->new(
    { INCLUDE_PATH => $ad->include_path, POST_CHOMP => 0, PRE_CHOMP => 0 } );
my $vars = $ad->get_vars;

# first get the lists of all Foorum::Schema pm files
my @sources = @{ $vars->{sources} };
foreach my $source (@sources) {
    my $class = $source->{class};    # Foorum::Schema::User

    # make file dir
    my @parts_of_modules = split( '::', $class );
    $parts_of_modules[-1] .= '.pm';
    my $file_dir
        = File::Spec->catfile( $Bin, '..', '..', 'lib', @parts_of_modules );

    my $output;
    $tt2->process( 'pod.html', { source => $source }, \$output )
        || die $tt2->error(), "\n";

    # replace POD in real module
    open( my $fh, '<', $file_dir );
    local $/ = undef;
    my $in = <$fh>;
    close($fh);

    my ( $code, $pod ) = split( /\n1;\r?\n/, $in );
    open( my $fh2, '>', $file_dir );
    print $fh2 "$code\n1;\n__END__\n\n$output\n";
    close($fh2);

    print "working on $class\n";
}

print "Done\n";

1;
