# Test llng-build-manager-files script with plugin extensions

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Copy;
use JSON;

my $count = 0;

# Create temporary directories
my $tmpdir     = tempdir( CLEANUP => 1 );
my $pluginsdir = "$tmpdir/plugins";
mkdir $pluginsdir or die "Cannot create plugins dir: $!";

# Create a test JSON plugin
my $plugin_content = {
    attributes => {
        oidcRPMetaDataOptionsTestParam => {
            type          => 'bool',
            default       => 0,
            documentation => 'Test parameter for plugin extension',
        },
        testTreeParam => {
            type          => 'text',
            default       => 'default_value',
            documentation => 'Test tree parameter',
        },

        # Existing attribute with a new select option to append
        authentication => {
            type   => 'select',
            select =>
              [ { k => 'MyCustomAuth', v => 'My Custom Auth Module' }, ],
        },
    },
    tree => {
        insert_into  => 'generalParameters/plugins',
        insert_after => 'stayConnected',
        nodes        => [ {
                title => 'testPluginNode',
                form  => 'simpleInputContainer',
                nodes => ['testTreeParam'],
            }
        ],
    },
    ctrees => {
        oidcRPMetaDataNode => {
            insert_into =>
              'oidcRPMetaDataOptions/oidcRPMetaDataOptionsAdvanced',
            insert_after => 'oidcRPMetaDataOptionsTokenXAuthorizedRP',
            nodes        => ['oidcRPMetaDataOptionsTestParam'],
        },
    },
    constants => {
        PE_TEST_PLUGIN_ERROR => 250,
    },
    lang => {
        testTreeParam => {
            en => 'Test tree parameter',
            fr => 'Paramètre de test',
        },
        oidcRPMetaDataOptionsTestParam => {
            en => 'Test OIDC parameter',
            fr => 'Paramètre OIDC de test',
        },
    },
};

# Write plugin file
my $plugin_file = "$pluginsdir/test-plugin.json";
open my $fh, '>', $plugin_file or die "Cannot write plugin: $!";
print $fh JSON->new->pretty->encode($plugin_content);
close $fh;
ok( -f $plugin_file, 'Plugin file created' );
$count++;

# Create temporary language directory with copies of real language files
my $langdir = "$tmpdir/languages";
mkdir $langdir or die "Cannot create lang dir: $!";
my $real_langdir = 'site/htdocs/static/languages';
if ( -d $real_langdir ) {
    opendir my $dh, $real_langdir or die "Cannot open $real_langdir: $!";
    for my $f ( grep { /\.json$/ } readdir $dh ) {
        copy( "$real_langdir/$f", "$langdir/$f" )
          or die "Cannot copy $f: $!";
    }
    closedir $dh;
}

# Output files
my $struct_file       = "$tmpdir/struct.json";
my $conftree_file     = "$tmpdir/conftree.js";
my $attributes_file   = "$tmpdir/Attributes.pm";
my $constants_file    = "$tmpdir/Constants.pm";
my $default_file      = "$tmpdir/DefaultValues.pm";
my $reconstants_file  = "$tmpdir/ReConstants.pm";
my $reverse_tree_file = "$tmpdir/reverseTree.json";
my $portal_const_file = "$tmpdir/PortalConstants.pm";
my $handler_const     = "$tmpdir/StatusConstants.pm";

# Run llng-build-manager-files
my $script = 'scripts/llng-build-manager-files';
ok( -f $script, 'Build script exists' );
$count++;

my $cmd = join( ' ',
    'perl',
    '-Ilib',
    '-I../lemonldap-ng-common/lib',
    '-I../lemonldap-ng-portal/lib',
    '-I../lemonldap-ng-handler/lib',
    $script,
    "--plugins-dir=$pluginsdir",
    "--struct-file=$struct_file",
    "--conftree-file=$conftree_file",
    "--manager-attributes-file=$attributes_file",
    "--conf-constants-file=$constants_file",
    "--default-values-file=$default_file",
    "--manager-constants-file=$reconstants_file",
    "--reverse-tree-file=$reverse_tree_file",
    "--portal-constants-file=$portal_const_file",
    "--handler-status-constants-file=$handler_const",
    "--lang-dir=$langdir",
    '2>&1' );

my $output = `$cmd`;
my $rc     = $? >> 8;
ok( $rc == 0, "Script executed successfully (rc=$rc)" )
  or diag("Output: $output");
$count++;

# Verify output files exist
ok( -f $struct_file,       'struct.json created' );
ok( -f $conftree_file,     'conftree.js created' );
ok( -f $attributes_file,   'Attributes.pm created' );
ok( -f $portal_const_file, 'PortalConstants.pm created' );
$count += 4;

# Test 1: Check that the new attribute is in Attributes.pm
{
    open my $fh, '<', $attributes_file or die "Cannot read Attributes.pm: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like(
        $content,
        qr/oidcRPMetaDataOptionsTestParam/,
        'oidcRPMetaDataOptionsTestParam found in Attributes.pm'
    );
    like( $content, qr/testTreeParam/, 'testTreeParam found in Attributes.pm' );
    $count += 2;
}

# Test 2: Check that the new attribute is in conftree.js (for oidcRP ctree)
{
    open my $fh, '<', $conftree_file or die "Cannot read conftree.js: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like(
        $content,
        qr/oidcRPMetaDataOptionsTestParam/,
        'oidcRPMetaDataOptionsTestParam found in conftree.js'
    );
    $count++;

# Verify it's in the right position (after oidcRPMetaDataOptionsTokenXAuthorizedRP)
    my $pos_token =
      index( $content, 'oidcRPMetaDataOptionsTokenXAuthorizedRP' );
    my $pos_test = index( $content, 'oidcRPMetaDataOptionsTestParam' );
    ok(
        $pos_token > 0 && $pos_test > $pos_token,
'oidcRPMetaDataOptionsTestParam is after oidcRPMetaDataOptionsTokenXAuthorizedRP'
    );
    $count++;
}

# Test 3: Check that the new tree node is in struct.json
{
    open my $fh, '<', $struct_file or die "Cannot read struct.json: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like( $content, qr/testPluginNode/, 'testPluginNode found in struct.json' );
    like( $content, qr/testTreeParam/,  'testTreeParam found in struct.json' );
    $count += 2;
}

# Test 4: Check that the new constant is in PortalConstants.pm
{
    open my $fh, '<', $portal_const_file
      or die "Cannot read PortalConstants.pm: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like( $content, qr/PE_TEST_PLUGIN_ERROR/,
        'PE_TEST_PLUGIN_ERROR found in PortalConstants.pm' );
    like( $content, qr/250/, 'Constant value 250 found in PortalConstants.pm' );
    $count += 2;
}

# Test 5: Check that the default value is in DefaultValues.pm
# Note: oidcRPMetaDataOptionsTestParam is a metadata parameter (per-RP),
# so it doesn't appear in DefaultValues.pm (only global parameters do)
{
    open my $fh, '<', $default_file or die "Cannot read DefaultValues.pm: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    like(
        $content,
        qr/testTreeParam.*default_value/s,
        'testTreeParam default value found in DefaultValues.pm'
    );
    $count++;
}

# Test 5b: Check that select options were appended (not replaced) for
# existing attribute "authentication"
{
    open my $fh, '<', $attributes_file or die "Cannot read Attributes.pm: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # Original core options must still be present
    like( $content, qr/'k'\s*=>\s*'LDAP'/,
        'authentication still has original "LDAP" option' );
    like( $content, qr/'k'\s*=>\s*'DBI'/,
        'authentication still has original "DBI" option' );

    # New option from extension must have been appended
    like( $content, qr/'k'\s*=>\s*'MyCustomAuth'/,
        'authentication has new "MyCustomAuth" option appended by extension' );
    $count += 3;
}

# Test 6: Check that translations were added to ALL language files
{
    my @lang_files = glob("$langdir/*.json");
    ok( scalar @lang_files > 0, 'Language files exist in temp dir' );
    $count++;

    # Expected translations per language code
    # Languages with specific translations get them; others fall back to English
    my %expected = (
        en => {
            testTreeParam                  => 'Test tree parameter',
            oidcRPMetaDataOptionsTestParam => 'Test OIDC parameter',
        },
        fr => {
            testTreeParam                  => "Param\x{e8}tre de test",
            oidcRPMetaDataOptionsTestParam => "Param\x{e8}tre OIDC de test",
        },
    );
    my $en_fallback = $expected{en};

    for my $lang_file ( sort @lang_files ) {
        ( my $lang_code = $lang_file ) =~ s{.*/(.+)\.json$}{$1};
        open my $fh, '<', $lang_file or die "Cannot read $lang_file: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        my $lang_data = JSON->new->utf8->decode($content);

        # Use specific expected values if available, otherwise English fallback
        my $expect = $expected{$lang_code} || $en_fallback;

        for my $key ( sort keys %$expect ) {
            is( $lang_data->{$key}, $expect->{$key},
                "[$lang_code] translation for $key" );
            $count++;
        }
    }
}

# Test 7: Test without plugins directory (should work without errors)
{
    my $empty_struct = "$tmpdir/empty_struct.json";
    my $cmd2         = join( ' ',
        'perl',
        '-Ilib',
        '-I../lemonldap-ng-common/lib',
        '-I../lemonldap-ng-portal/lib',
        '-I../lemonldap-ng-handler/lib',
        $script,
        "--struct-file=$empty_struct",
        "--conftree-file=$tmpdir/empty_conftree.js",
        "--manager-attributes-file=$tmpdir/empty_Attributes.pm",
        "--conf-constants-file=$tmpdir/empty_Constants.pm",
        "--default-values-file=$tmpdir/empty_DefaultValues.pm",
        "--manager-constants-file=$tmpdir/empty_ReConstants.pm",
        "--reverse-tree-file=$tmpdir/empty_reverseTree.json",
        "--portal-constants-file=$tmpdir/empty_PortalConstants.pm",
        "--handler-status-constants-file=$tmpdir/empty_StatusConstants.pm",
        '2>&1' );

    my $output2 = `$cmd2`;
    my $rc2     = $? >> 8;
    ok( $rc2 == 0, 'Script works without --plugins-dir' )
      or diag("Output: $output2");
    ok( -f $empty_struct, 'struct.json created without plugins' );
    $count += 2;
}

# Test 7: Test with non-existent plugins directory (should work without errors)
{
    my $nodir_struct = "$tmpdir/nodir_struct.json";
    my $cmd3         = join( ' ',
        'perl',
        '-Ilib',
        '-I../lemonldap-ng-common/lib',
        '-I../lemonldap-ng-portal/lib',
        '-I../lemonldap-ng-handler/lib',
        $script,
        "--plugins-dir=/nonexistent/path",
        "--struct-file=$nodir_struct",
        "--conftree-file=$tmpdir/nodir_conftree.js",
        "--manager-attributes-file=$tmpdir/nodir_Attributes.pm",
        "--conf-constants-file=$tmpdir/nodir_Constants.pm",
        "--default-values-file=$tmpdir/nodir_DefaultValues.pm",
        "--manager-constants-file=$tmpdir/nodir_ReConstants.pm",
        "--reverse-tree-file=$tmpdir/nodir_reverseTree.json",
        "--portal-constants-file=$tmpdir/nodir_PortalConstants.pm",
        "--handler-status-constants-file=$tmpdir/nodir_StatusConstants.pm",
        '2>&1' );

    my $output3 = `$cmd3`;
    my $rc3     = $? >> 8;
    ok( $rc3 == 0, 'Script works with non-existent plugins-dir' )
      or diag("Output: $output3");
    ok( -f $nodir_struct, 'struct.json created with non-existent plugins-dir' );
    $count += 2;
}

done_testing($count);
