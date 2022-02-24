# Verify that all attributes are positionned in tree and that all leaf
# correspond to an attribute. Verify also that attributes and leafs are uniq

use strict;
use Test::More;
use Data::Dumper;

# CONSTANTS

# Node names used more than one time
my $usedMoreThanOneTimeInTree = qr/^(?:
  remoteCookieName
)$/x;

# Attributes not managed in web interface
my @notManagedAttributes = (

    # Complex nodes
    'samlSPMetaDataOptions', 'samlIDPMetaDataOptions', 'oidcRPMetaDataOptions',
    'oidcOPMetaDataOptions', 'casSrvMetaDataOptions',  'casAppMetaDataOptions',
    'vhostOptions',

    # Second factor engine, lists of 2F modules and other parameters
    'sfEngine', 'available2FSelfRegistration', 'available2F', 'max2FDevices',
    'max2FDevicesNameLength',

    # Handlers
    'handlerInternalCache', 'handlerServiceTokenTTL',

    # Metadatas (added by manager itself)
    'cfgAuthor', 'cfgAuthorIP', 'cfgNum', 'cfgDate', 'cfgLog', 'cfgVersion',

    # HTML template parameter (for PSGI) (must be set in lemonldap-ng.ini)
    'staticPrefix',

    # Loggers
    'log4perlConfFile', 'userSyslogFacility', 'logger', 'sentryDsn',
    'syslogFacility',   'userLogger',         'logLevel',

    # Plugins parameters
    'notificationsMaxRetrieve', 'persistentSessionAttributes',

    # PSGI/CGI protection (must be set in lemonldap-ng.ini)
    'protection',

    # SecureToken handler
    'secureTokenAllowOnError', 'secureTokenAttribute', 'secureTokenExpiration',
    'secureTokenHeader',       'secureTokenMemcachedServers', 'secureTokenUrls',

    # Sessions and OTT storage
    'configStorage', 'localStorageOptions', 'localStorage',
    'forceGlobalStorageUpgradeOTT', 'forceGlobalStorageIssuerOTT',

    # Viewer
    'viewerHiddenKeys', 'viewerAllowBrowser', 'viewerAllowDiff',

    # Zimbra handler
    'zimbraAccountKey', 'zimbraBy', 'zimbraPreAuthKey', 'zimbraSsoUrl',
    'zimbraUrl',

    # Other ini-only prms
    'checkTime',                 'status', 'soapProxyUrn',
    'impersonationPrefix',       'pdataDomain',
    'mySessionAuthorizedRWKeys', 'contextSwitchingPrefix'
);

# Words used either as attribute name and node title
my $doubleUsage = qr/^(?:
  samlSPMetaDataOptions|
  samlIDPMetaDataOptions|
  oidcRPMetaDataOptions|
  oidcOPMetaDataOptions|
  casSrvMetaDataOptions|
  casAppMetaDataOptions|
  vhostOptions
)$/x;

# TESTS

# 1 - Collect attributes

# Attributes.pm is parsed with open() and not loaded to detect double entries
ok( open( F, 'lib/Lemonldap/NG/Manager/Build/Attributes.pm' ),
    'open attributes file' );
my $count = 1;

while ( <F> !~ /sub\s+attributes/ ) { 1 }

my ( %h, %h2 );

while (<F>) {
    next unless /^\s{8}["']?(\w+)/;
    my $attr = $1;
    $h{$attr}++;
    ok( $h{$attr} == 1, "$attr is uniq" );
    $count++;
}
close F;

# 2 - Parse Tree.pm
use_ok('Lemonldap::NG::Manager::Build::Tree');
my $tree;
ok( $tree = Lemonldap::NG::Manager::Build::Tree::tree(), 'Get tree' );
$count += 3;
scanTree($tree);

# 3 - Parse CTrees.pm
use_ok('Lemonldap::NG::Manager::Build::CTrees');
ok( $tree = Lemonldap::NG::Manager::Build::CTrees::cTrees(),
    'Get conditional tree' );
$count++;
foreach my $t ( values %$tree ) {
    scanTree($t);
}

# 4 - Check that each leaf correspond to an attribute
foreach ( keys %h2 ) {
    s/^\*//;
    ok( defined( $h{$_} ), "Leaf $_ exists in attributes" );
    delete $h{$_};
    $count++;
}

# 5 - Check that attributes that must not be in manager tree are declared in
#     Attributes.pm
foreach (@notManagedAttributes) {
    ok( defined( $h{$_} ), "Unmanaged attribute '$_' is declared" );
    delete $h{$_};
    $count++;
}

# 6 - Verify that all attributes have been checked
ok( !%h, "No remaining attributes" )
  or print STDERR Dumper( { 'Remaining attributes' => [ keys %h ] } );
$count++;

done_testing($count);
exit;

# 21 / 31 recursive search for leafs
sub scanTree {
    my $tree = shift;

    # Lists of nodes must be arrays
    ok( ref($tree) eq 'ARRAY', 'Tree is an array' );
    $count++;
    foreach my $leaf (@$tree) {

        # Scan if sub element is a node or a leaf

        # Case 1: subnode
        if ( ref $leaf ) {

            # Nodes must be hash
            ok( ref($leaf) eq 'HASH' );
            my $name;

            # Nodes must have a title
            ok( $name = $leaf->{title}, "Node has a name" );
            ok( $name =~ /^\w+$/,       "Name is a string" );

            # Nodes must have leafs or subnodes
            ok( (
                         exists( $leaf->{nodes} )
                      or exists( $leaf->{nodes_cond} )
                      or exists( $leaf->{group} )
                ),
                "Node $name has leafs"
            );
            $count += 4;

            # Nodes must not use attributes name
            unless ( $name =~ $doubleUsage ) {
                ok( !exists( $h{$name} ),
                    "Node title ($name) must not be used as attribute name" );
                $count++;
            }

            foreach my $n (qw(nodes nodes_cond group)) {

                # Scan subnodes lists
                scanTree( $leaf->{$n} ) if ( exists $leaf->{$n} );
            }
        }

        # Case 2: leaf

        # Sub case 21: normal leaf
        elsif ( $leaf !~ $usedMoreThanOneTimeInTree ) {

            # Check that leaf is a string
            ok( $leaf =~ /^\*?\w+/, "Leaf is an attribute name ($leaf)" );
            $h2{$leaf}++;

            # Check that leaf appears for the first time
            ok( $h2{$leaf} == 1, "$leaf is uniq" );
            $count += 2;
        }

        # Sub case 22: $usedMoreThanOneTimeInTree contains leaf used more than
        #              one time in tree
        else {
            $h2{$leaf}++;
        }
    }
}
