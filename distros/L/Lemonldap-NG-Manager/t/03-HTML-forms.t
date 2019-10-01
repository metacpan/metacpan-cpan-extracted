# Check that HTML forms exists for all types of parameter and that no HTML
# forms are unused

use Test::More;
use Data::Dumper;
use strict;

my $formDir = 'site/htdocs/static/forms';

my $count = 0;
use_ok('Lemonldap::NG::Manager::Build::Tree');
use_ok('Lemonldap::NG::Manager::Build::CTrees');
use_ok('Lemonldap::NG::Manager::Build::Attributes');
$count += 3;

ok( opendir( D, $formDir ), 'Found forms dir' );
my %forms = map { s/\.html$// ? ( $_ => 1 ) : () } readdir D;
close D;

delete $forms{white};
delete $forms{mini};
delete $forms{restore};

my ( @types, $attr, $tree, $ctrees );
ok( $tree   = Lemonldap::NG::Manager::Build::Tree::tree(),     'Get tree' );
ok( $ctrees = Lemonldap::NG::Manager::Build::CTrees::cTrees(), 'Get cTrees' );
ok( $attr   = Lemonldap::NG::Manager::Build::Attributes::attributes(),
    'Get attributes' );
$count += 4;

my %types = %{ getTypes( $tree, values(%$ctrees), $attr ) };

foreach (qw(home homeViewer menuCat menuApp authParamsTextContainer)) {
    ok( $forms{$_}, "Found $_ form" );
    $count++;
    delete $forms{$_};
}

foreach my $type ( keys %types ) {
    delete $types{$type};
    if ( $type =~
/^(?:array|authParamsText|url|PerlModule|hostname|pcre|lmAttrOrMacro|subContainer|RSAP(?:ublic|rivate)Key(?:OrCertificate)?)$/
      )
    {
        delete $forms{$type};
        next;
    }
    ok( $forms{$type}, "Found $type" );
    delete $forms{$type};
    $count++;
    if ( $type =~ s/Container$// ) {
        next if ( $type eq 'simpleInput' );
        ok( $forms{$type}, "Found $type" );
        delete $forms{$type};
        $count++;
    }
}
ok( !%forms, "No unused forms" ) or print "Found:\n" . Dumper( \%forms );
$count++;

done_testing($count);

sub getTypes {
    my @trees = @_;
    my $res   = { 'text' => 1 };
    foreach my $t (@trees) {
        if ( ref($t) eq 'HASH' ) {
            foreach my $a ( values %$t ) {

                my $tmp = $a->{type};
                $res->{$tmp}++ if ($tmp);
            }
        }
        else {
            _getTypes( $t, $res );
        }
    }
    return $res;
}

sub _getTypes {
    my ( $tree, $res ) = splice @_;
    $tree = [$tree] unless ( ref($tree) );
    foreach my $k (@$tree) {
        if ( ref($k) ) {
            _getTypes( $k->{nodes},      $res ) if ( $k->{nodes} );
            _getTypes( $k->{nodes_cond}, $res ) if ( $k->{nodes_cond} );
            $res->{ $k->{form} }++ if ( $k->{form} );
        }
    }
}
