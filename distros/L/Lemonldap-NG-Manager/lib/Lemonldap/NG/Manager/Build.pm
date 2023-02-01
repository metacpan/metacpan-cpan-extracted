package Lemonldap::NG::Manager::Build;

use strict;
use utf8;
use Mouse;
use Lemonldap::NG::Manager::Build::Attributes;
use Lemonldap::NG::Manager::Build::Tree;
use Lemonldap::NG::Manager::Build::CTrees;
use Lemonldap::NG::Manager::Build::PortalConstants;
use Lemonldap::NG::Manager::Conf::Zero;
use Data::Dumper;
use Regexp::Common 'URI';
use Regexp::Assemble;
use JSON;
use Getopt::Std;
use IO::String;

has structFile                 => ( isa => 'Str', is => 'ro', required => 1 );
has confTreeFile               => ( isa => 'Str', is => 'ro', required => 1 );
has managerConstantsFile       => ( isa => 'Str', is => 'ro', required => 1 );
has managerAttributesFile      => ( isa => 'Str', is => 'ro', required => 1 );
has defaultValuesFile          => ( isa => 'Str', is => 'ro', required => 1 );
has confConstantsFile          => ( isa => 'Str', is => 'ro', required => 1 );
has firstLmConfFile            => ( isa => 'Str', is => 'ro', required => 1 );
has reverseTreeFile            => ( isa => 'Str', is => 'ro', required => 1 );
has portalConstantsFile        => ( isa => 'Str', is => 'ro', required => 1 );
has handlerStatusConstantsFile => ( isa => 'Str', is => 'ro', required => 1 );
has docConstantsFile           => ( isa => 'Str', is => 'ro', required => 1 );

my @managerAttrKeys = qw(keyTest keyMsgFail select type test msgFail default);
my $format          = 'Creating %-69s: ';
my $reIgnoreKeys    = qr/^$/;
my $module          = __PACKAGE__;

my @angularScopeVars;
my @bool;
my @arrayParam;
my @cnodesKeys;
my %cnodesRe;
my @ignoreKeys;
my $ignoreKeys;
my $mainTree;
my @sessionTypes;
my @simpleHashKeys;
my @doubleHashKeys;
my $authParameters;
my $issuerParameters;
my $samlServiceParameters;
my $oidcServiceParameters;
my $casServiceParameters = [];
my $defaultValues;

my $attributes = Lemonldap::NG::Manager::Build::Attributes::attributes();
my $jsonEnc    = JSON->new()->allow_nonref;
$jsonEnc->canonical(1);

$Data::Dumper::Sortkeys = sub {
    my ($hash) = @_;
    return [
        ( defined $hash->{id}    ? ('id')       : () ),
        ( defined $hash->{title} ? ( 'title', ) : () ),
        (
            grep { /^(?:id|title)$/ ? 0 : 1 }
              sort {
                return 1
                  if ( $a =~ /node/ and $b !~ /node/ );
                return -1 if ( $b =~ /node/ );
                lc($a) cmp lc($b);
              } keys %$hash
        )
    ];
};

$Data::Dumper::Deparse  = 1;
$Data::Dumper::Deepcopy = 1;

sub run {
    my $self = shift;
    $self = $module->new(@_) unless ref $self;

    # 1. confTree.js
    printf STDERR $format, $self->confTreeFile;
    $mainTree = Lemonldap::NG::Manager::Build::CTrees::cTrees();

    my $script = 'function templates(tpl,key) {
    var ind;
    var scalarTemplate = function(r) {
    return {
      "id": tpl+"s/"+(ind++),
      "title": r,
      "get": tpl+"s/"+key+"/"+r
    };
  };
  switch(tpl){
';

    my $reverseScanResult =
      $self->reverseScan( Lemonldap::NG::Manager::Build::Tree::tree(), '', {} );

    # To build confTree.js, each special node is scanned from
    # Lemonldap::NG::Manager::Build::CTrees
    foreach my $node ( sort keys %$mainTree ) {
        @cnodesKeys = ();
        my $jsonTree = [];
        $self->scanTree( $mainTree->{$node}, $jsonTree, '__KEY__', '' );
        $jsonEnc->pretty(1);
        my $tmp = $jsonEnc->encode($jsonTree);
        $tmp =~ s!"__KEY__!tpl+"s/"+key+"/"+"!mg;
        $tmp =~ s/"(true|false)"/$1/sg;
        $tmp =~ s/:\s*"(\d+)"\s*(["\}])/:$1$2/sg;
        $script .= "  case '$node':
    return $tmp;
";

        # Second step, Manager/Constants.pm file will contain data issued from
        # this scan
        my $ra = Regexp::Assemble->new;

        # Build $oidcOPMetaDataNodeKeys, $samlSPMetaDataNodeKeys,...
        foreach my $r (@cnodesKeys) {
            $ra->add($r);
        }
        $cnodesRe{$node} = $ra->as_string;

        push @ignoreKeys, $node;
    }
    $script .= "  default:\n    return [];\n  }\n}";
    open F, ">", $self->confTreeFile or die $!;
    print F $script;
    close F;
    print STDERR "done\n";
    my $ra = Regexp::Assemble->new;
    foreach my $re (@ignoreKeys) {
        $ra->add($re);
    }
    $ignoreKeys   = $ra->as_string;
    $reIgnoreKeys = $ra->re;

    # Reinitialize $defaultValues
    $defaultValues = {};

    # 2. struct.json
    printf STDERR $format, $self->structFile;
    $mainTree = Lemonldap::NG::Manager::Build::Tree::tree();
    my $jsonTree = [];
    $self->scanTree( $mainTree, $jsonTree, '', '' );
    $script = "\n\nfunction setScopeVars(scope) {\n";
    foreach my $v (@angularScopeVars) {
        $script .=
          "  scope.$v->[0] = scope$v->[1];\n  scope.getKey(scope.$v->[0]);\n";
    }
    $script .= "}";
    open F, ">>", $self->confTreeFile || die $!;
    print F $script;
    close F;
    open F, ">", $self->structFile || die $!;
    $jsonEnc->pretty(0);
    my $tmp = $jsonEnc->encode($jsonTree);
    $tmp =~ s/"(true|false)"/$1/sg;
    $tmp =~ s/:\s*"(\d+)"\s*(["\}])/:$1$2/sg;
    print F $tmp;
    close F;
    print STDERR "done\n";
    $tmp = undef;

    printf STDERR $format, $self->managerConstantsFile;

    open F, ">", $self->managerConstantsFile or die($!);
    my $exportedVars = '$'
      . join( 'Keys $',
        'simpleHash', 'doubleHash', 'specialNode', sort keys %cnodesRe )
      . 'Keys $specialNodeHash $authParameters $issuerParameters $samlServiceParameters $oidcServiceParameters $casServiceParameters';
    print F <<EOF;
# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Common::Conf::ReConstants;

use strict;
use Exporter 'import';
use base qw(Exporter);

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

our %EXPORT_TAGS = ( 'all' => [qw($exportedVars)] );
our \@EXPORT_OK   = ( \@{ \$EXPORT_TAGS{'all'} } );
our \@EXPORT      = ( \@{ \$EXPORT_TAGS{'all'} } );

our \$specialNodeHash = {
    virtualHosts         => [qw(exportedHeaders locationRules post vhostOptions)],
    samlIDPMetaDataNodes => [qw(samlIDPMetaDataXML samlIDPMetaDataExportedAttributes samlIDPMetaDataOptions)],
    samlSPMetaDataNodes  => [qw(samlSPMetaDataXML samlSPMetaDataExportedAttributes samlSPMetaDataOptions samlSPMetaDataMacros)],
    oidcOPMetaDataNodes  => [qw(oidcOPMetaDataJSON oidcOPMetaDataJWKS oidcOPMetaDataOptions oidcOPMetaDataExportedVars)],
    oidcRPMetaDataNodes  => [qw(oidcRPMetaDataOptions oidcRPMetaDataExportedVars oidcRPMetaDataOptionsExtraClaims oidcRPMetaDataMacros oidcRPMetaDataScopeRules)],
    casSrvMetaDataNodes  => [qw(casSrvMetaDataOptions casSrvMetaDataExportedVars)],
    casAppMetaDataNodes  => [qw(casAppMetaDataOptions casAppMetaDataExportedVars casAppMetaDataMacros)],
};

EOF

    # Reinitialize $attributes
    $attributes = Lemonldap::NG::Manager::Build::Attributes::attributes();

    $ra = Regexp::Assemble->new;
    foreach (@doubleHashKeys) {
        $ra->add($_);
    }
    print F "our \$doubleHashKeys = '" . $ra->as_string . "';\n";
    $ra = Regexp::Assemble->new;
    foreach (@simpleHashKeys) {
        $ra->add($_);
    }
    print F "our \$simpleHashKeys = '"
      . $ra->as_string . "';\n"
      . "our \$specialNodeKeys = '${ignoreKeys}s';\n";
    foreach ( sort keys %cnodesRe ) {
        print F "our \$${_}Keys = '$cnodesRe{$_}';\n";
    }
    print F "\n";

    foreach (qw(authParameters issuerParameters)) {
        $tmp = "our \$$_ = {\n";
        no strict 'refs';
        foreach my $k ( sort keys %$$_ ) {
            my $v = $$_->{$k};
            $tmp .= "  $k => [qw(" . join( ' ', @$v ) . ")],\n";
        }
        print F "$tmp};\n";
    }
    foreach (qw(samlServiceParameters oidcServiceParameters)) {
        no strict 'refs';
        $tmp = "our \$$_ = [qw(" . join( ' ', @$$_ ) . ")];\n";
        print F "$tmp";
    }

    print F "\n1;\n";
    close F;
    print STDERR "done\n";

    printf STDERR $format, $self->defaultValuesFile;
    $defaultValues->{locationRules} = $attributes->{locationRules}->{default};
    foreach ( keys %$attributes ) {
        if (    not /(?:MetaData|vhost)/
            and $attributes->{$_}->{default}
            and not $reverseScanResult->{$_} )
        {
            $defaultValues->{$_} = $attributes->{$_}->{default};
        }
    }
    my $defaultAttr = mydump( $defaultValues, 'defaultValues' );
    $defaultAttr = "# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Common::Conf::DefaultValues;

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

$defaultAttr}

1;
";

    my $dst;

    eval {
        require Perl::Tidy;
        Perl::Tidy::perltidy(
            source      => IO::String->new($defaultAttr),
            destination => \$dst
        );
    };
    $dst = $defaultAttr if ($@);

    open( F, ">", $self->defaultValuesFile ) or die($!);
    print F $dst;
    close F;
    print STDERR "done\n";

    printf STDERR $format, $self->confConstantsFile;
    $ra = Regexp::Assemble->new;
    foreach ( @simpleHashKeys, @doubleHashKeys, sort keys %cnodesRe ) {
        $ra->add($_);
    }
    foreach ( qw(
        exportedHeaders locationRules post vhostOptions
        samlIDPMetaDataXML samlIDPMetaDataExportedAttributes
        samlIDPMetaDataOptions samlSPMetaDataXML
        samlSPMetaDataExportedAttributes samlSPMetaDataMacros
        samlSPMetaDataOptions oidcOPMetaDataJSON
        oidcOPMetaDataJWKS oidcOPMetaDataOptions
        oidcOPMetaDataExportedVars oidcRPMetaDataOptions
        oidcRPMetaDataExportedVars oidcRPMetaDataOptionsExtraClaims
        oidcRPMetaDataMacros oidcRPMetaDataScopeRules
        casAppMetaDataExportedVars casAppMetaDataOptions casAppMetaDataMacros
        casSrvMetaDataExportedVars casSrvMetaDataOptions
        )
      )
    {
        $ra->add($_);
    }

    my $sessionTypes = join( "', '", @sessionTypes );
    my $confConstants =
      "our \$hashParameters = qr/^" . $ra->as_string . "\$/;\n";
    $ra = Regexp::Assemble->new;
    foreach (@arrayParam) {
        $ra->add($_);
    }

    # Not in Tree.pm
    foreach (qw(mySessionAuthorizedRWKeys)) {
        $ra->add($_);
    }
    $confConstants .=
      "our \$arrayParameters = qr/^" . $ra->as_string . "\$/;\n";
    $ra = Regexp::Assemble->new;
    foreach (@bool) {
        $ra->add($_);
    }
    $confConstants .= "our \$boolKeys = qr/^" . $ra->as_string . "\$/;\n";
    open( F, ">", $self->confConstantsFile ) or die($!);
    print F <<EOF;
# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Common::Conf::Constants;

use strict;
use Exporter 'import';
use base qw(Exporter);

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

# CONSTANTS

use constant CONFIG_WAS_CHANGED => -1;
use constant UNKNOWN_ERROR      => -2;
use constant DATABASE_LOCKED    => -3;
use constant UPLOAD_DENIED      => -4;
use constant SYNTAX_ERROR       => -5;
use constant DEPRECATED         => -6;
use constant DEFAULTCONFFILE => "/usr/local/lemonldap-ng/etc/lemonldap-ng.ini";
use constant DEFAULTSECTION  => "all";
use constant CONFSECTION     => "configuration";
use constant PORTALSECTION   => "portal";
use constant HANDLERSECTION  => "handler";
use constant MANAGERSECTION  => "manager";
use constant SESSIONSEXPLORERSECTION => "sessionsExplorer";
use constant APPLYSECTION            => "apply";

# Default configuration backend
use constant DEFAULTCONFBACKEND => "File";
use constant DEFAULTCONFBACKENDOPTIONS => (
    dirName => '/usr/local/lemonldap-ng/data/conf',
);
$confConstants
our \@sessionTypes = ( '$sessionTypes' );

sub NO {qr/^(?:off|no|0)?\$/i}

our %EXPORT_TAGS = (
    'all' => [
        qw(
          CONFIG_WAS_CHANGED
          UNKNOWN_ERROR
          DATABASE_LOCKED
          UPLOAD_DENIED
          SYNTAX_ERROR
          DEPRECATED
          DEFAULTCONFFILE
          DEFAULTSECTION
          CONFSECTION
          PORTALSECTION
          HANDLERSECTION
          MANAGERSECTION
          SESSIONSEXPLORERSECTION
          APPLYSECTION
          DEFAULTCONFBACKEND
          DEFAULTCONFBACKENDOPTIONS
          NO
          \$hashParameters
          \$arrayParameters
          \@sessionTypes
          \$boolKeys
          )
    ]
);
our \@EXPORT_OK   = ( \@{ \$EXPORT_TAGS{'all'} } );
our \@EXPORT      = ( \@{ \$EXPORT_TAGS{'all'} } );

1;
EOF
    close F;
    print STDERR "done\n";

    printf STDERR $format, $self->managerAttributesFile;
    my $managerAttr = {
        map {
            my @r;
            foreach my $f (@managerAttrKeys) {
                push @r, $f, $attributes->{$_}->{$f}
                  if ( defined $attributes->{$_}->{$f} );
            }
            ( $_ => {@r} );
        } keys(%$attributes)
    };
    $managerAttr = mydump( $managerAttr, 'attributes' );
    my $managerSub =
      Dumper( \&Lemonldap::NG::Manager::Build::Attributes::perlExpr );
    $managerSub =~ s/\$VAR1 = sub/sub perlExpr/s;
    $managerSub =~ s/^\s*(?:use strict;|package .*?;|)\n//gm;
    my $managerTypes =
      mydump( Lemonldap::NG::Manager::Build::Attributes::types(), 'types' );
    $managerAttr = "# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Manager::Attributes;

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

$managerSub

$managerTypes}

$managerAttr}

";
    eval {
        Perl::Tidy::perltidy(
            source      => IO::String->new($managerAttr),
            destination => \$dst
        );
    };
    $dst = $managerAttr if ($@);

    open( F, ">", $self->managerAttributesFile ) or die($!);
    print F $dst;
    close F;
    print STDERR "done\n";

    $self->buildZeroConf();

    printf STDERR $format, $self->reverseTreeFile;
    open( F, ">", $self->reverseTreeFile ) or die($!);
    $jsonEnc->pretty(0);
    print F $jsonEnc->encode($reverseScanResult);
    close F;

    print STDERR "done\n";
    $self->buildPortalConstants();
}

sub buildZeroConf {
    my $self = shift;
    $jsonEnc->pretty(1);
    printf STDERR $format, $self->firstLmConfFile;
    open( F, '>', $self->firstLmConfFile ) or die($!);
    my $tmp = Lemonldap::NG::Manager::Conf::Zero::zeroConf(
        '__DNSDOMAIN__',   '__SESSIONDIR__',
        '__PSESSIONDIR__', '__NOTIFICATIONDIR__',
        '__CACHEDIR__'
    );
    $tmp->{cfgNum} = 1;
    print F $jsonEnc->encode($tmp);
    close F;
    print STDERR "done\n";
}

sub buildPortalConstants() {
    my $self = shift;

    my %portalConstants =
      %{ Lemonldap::NG::Manager::Build::PortalConstants::portalConstants() };
    my %reverseConstants = reverse %portalConstants;
    die "Duplicate value in portal constants"
      unless %reverseConstants == %portalConstants;

    printf STDERR $format, $self->portalConstantsFile;
    open( F, '>', $self->portalConstantsFile ) or die($!);
    my $urire = $RE{URI}{HTTP}{ -scheme => qr/https?/ }{-keep};
    $urire =~ s/([\$\@])/\\$1/g;
    my $content = <<EOF;
# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Portal::Main::Constants;

use strict;
use Exporter 'import';

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

use constant HANDLER => 'Lemonldap::NG::Handler::PSGI::Main';
use constant URIRE => qr{$urire};
use constant {
EOF
    for my $pe (
        sort { $portalConstants{$a} <=> $portalConstants{$b} }
        keys %portalConstants
      )
    {
        my $str = $portalConstants{$pe};
        $content .= "    $pe => $str,\n";
    }

    my $exports = join ", ", map { "'$_'" }
      sort { $portalConstants{$a} <=> $portalConstants{$b} }
      keys %portalConstants;

    my $portalConstsStr .= mydump( \%reverseConstants, 'portalConsts' );
    $content .= <<EOF;
};

$portalConstsStr
}

# EXPORTER PARAMETERS
our \@EXPORT_OK = ( 'portalConsts', 'HANDLER', 'URIRE', $exports );
our %EXPORT_TAGS = ( 'all' => [ \@EXPORT_OK, 'import' ], );

our \@EXPORT = qw(import PE_OK);

1;
EOF

    my $dst;
    eval {
        Perl::Tidy::perltidy(
            source      => IO::String->new($content),
            destination => \$dst
        );
    };
    $dst = $content if ($@);
    open( F, '>', $self->portalConstantsFile ) or die($!);
    print F $dst;
    close F;
    print STDERR "done\n";

    printf STDERR $format, $self->handlerStatusConstantsFile;

    # Handler Status file
    $content = <<EOF;
# This file is generated by $module. Don't modify it by hand
package Lemonldap::NG::Handler::Lib::StatusConstants;

use strict;
use Exporter 'import';

our \$VERSION = '$Lemonldap::NG::Manager::Build::Attributes::VERSION';

$portalConstsStr
}

# EXPORTER PARAMETERS
our \@EXPORT_OK = ( 'portalConsts' );
our %EXPORT_TAGS = ( 'all' => [ \@EXPORT_OK, 'import' ], );

1;
EOF

    eval {
        Perl::Tidy::perltidy(
            source      => IO::String->new($content),
            destination => \$dst
        );
    };
    $dst = $content if ($@);
    open( F, '>', $self->handlerStatusConstantsFile ) or die($!);
    print F $dst;
    close F;
    print STDERR "done\n";

    printf STDERR $format, $self->docConstantsFile;

    # Doc error code list
    $content = <<EOF;
..
   This file is generated by $module. Don't modify it by hand

Error codes list
================

.. note::

    This page references all Portal error codes.

.. csv-table::
   :header: "Error label", "Error number"
   :delim: ;
   :widths: auto


EOF

    for my $key (
        sort { $portalConstants{$a} <=> $portalConstants{$b} }
        keys %portalConstants
      )
    {

        $content .= "    ``" . $key . "``;" . $portalConstants{$key} . "\n";
    }

    open( F, '>', $self->docConstantsFile ) or die($!);
    print F $content;
    close F;

    print STDERR "done\n";
}

sub mydump {
    my ( $obj, $subname ) = @_;
    my $t = Dumper($obj);
    $t =~ s/^\s*(?:use strict;|package .*?;|)\n//gm;
    $t =~ s/\n\s*BEGIN.*?\}\n/\n/sg;
    $t =~ s/^\$VAR1\s*=/sub $subname {\n    return/;
    return $t;
}

sub scanTree {
    my ( $self, $tree, $json, $prefix, $path ) = @_;
    unless ( ref($tree) eq 'ARRAY' ) {
        die 'Not an array';
    }
    $prefix //= '';
    my $ord      = -1;
    my $nodeName = $path ? '_nodes' : 'data';
    foreach my $leaf (@$tree) {
        $ord++;
        my $jleaf = {};

        # Grouped leaf
        if ( ref($leaf) and $leaf->{group} ) {
            die "'form' is required when using 'group'"
              unless ( $leaf->{form} );
            push @$json,
              {
                id    => "$prefix$leaf->{title}",
                title => $leaf->{title},
                type  => $leaf->{form},
                get   => $leaf->{group}
              };
        }

        # Subnode
        elsif ( ref($leaf) ) {
            $jleaf->{title} = $jleaf->{id} = $leaf->{title};
            $jleaf->{type}  = $leaf->{form} if ( $leaf->{form} );
            if ( $leaf->{title} =~ /^((?:oidc|saml|cas)Service)MetaData$/ ) {
                no strict 'refs';
                my @tmp = $self->scanLeaf( $leaf->{nodes} );
                ${ $1 . 'Parameters' } = \@tmp;
            }
            foreach my $n (qw(nodes nodes_cond)) {
                if ( $leaf->{$n} ) {
                    $jleaf->{"_$n"} = [];
                    $self->scanTree( $leaf->{$n}, $jleaf->{"_$n"}, $prefix,
                        "$path.$nodeName\[$ord\]" );
                    if ( (
                                $leaf->{title} eq 'authParams'
                            and $n eq 'nodes_cond'
                        )
                        or $leaf->{title} eq 'issuerParams'
                      )
                    {
                        my $vn = $leaf->{title};
                        $vn =~ s/Params$/Parameters/;
                        foreach my $sn ( @{ $leaf->{$n} } ) {
                            no strict 'refs';
                            my @cn = $self->scanLeaf( $sn->{nodes} );
                            ${$vn}->{ $sn->{title} } = \@cn;
                        }
                    }
                    elsif ( $leaf->{title} eq 'issuerParams' ) {
                    }
                    if ( $n eq 'nodes_cond' ) {
                        foreach my $sn ( @{ $jleaf->{"_$n"} } ) {
                            $sn->{show} = 'false';
                        }
                    }
                }
            }
            $jleaf->{help}          = $leaf->{help} if ( $leaf->{help} );
            $jleaf->{_nodes_filter} = $leaf->{nodes_filter}
              if ( $leaf->{nodes_filter} );
            push @$json, $jleaf;
        }

        # Leaf
        else {
            # Get data type and build tree
            #
            # Types : PerlModule array bool boolOrExpr catAndAppList file
            # hostname int keyTextContainer lmAttrOrMacro longtext
            # openidServerList oidcAttributeContainer pcre rulesContainer
            # samlAssertion samlAttributeContainer samlService select text
            # trool url virtualHostContainer word password

            if ( $leaf =~ s/^\*// ) {
                push @angularScopeVars, [ $leaf, "$path._nodes[$ord]" ];
            }
            push @sessionTypes, $1
              if ( $leaf =~ /^(.*)(?<!notification)StorageOptions$/ );
            my $attr = $attributes->{$leaf} or die("Missing attribute $leaf");

            #print STDERR "| $attr->{documentation}  |  $leaf  |\n";
            $jleaf = { id => "$prefix$leaf", title => $leaf };
            unless ( $attr->{type} ) {
                print STDERR "Fatal: no type: $leaf\n";
                exit;
            }

            # TODO: change this
            $attr->{type} =~
              s/^(?:url|word|pcre|lmAttrOrMacro|hostname|PerlModule)$/text/;
            $jleaf->{type} = $attr->{type} if ( $attr->{type} ne 'text' );
            foreach my $w (qw(default help select get template)) {
                $jleaf->{$w} = $attr->{$w} if ( defined $attr->{$w} );
            }
            if ( defined $jleaf->{default} ) {
                unless ( $attr->{type} eq 'bool' and $jleaf->{default} == 0 ) {
                    $defaultValues->{$leaf} = $jleaf->{default};
                }
                if ( ref( $jleaf->{default} ) ) {
                    $jleaf->{default} = [];
                    my $type = $attr->{type};
                    $type =~ s/Container//;
                    foreach my $k ( sort keys( %{ $attr->{default} } ) ) {

                        # Special handling for oidcAttribute
                        my $default = $attr->{default}->{$k};
                        if ( $attr->{type} eq 'oidcAttributeContainer' ) {
                            $default = [ $default, "string", "auto" ];
                        }

                        push @{ $jleaf->{default} },
                          {
                            id    => "$prefix$leaf/$k",
                            title => $k,
                            type  => $type,
                            data  => $default,
                            (
                                $type eq 'rule'
                                ? ( re => $k )
                                : ()
                            ),
                          };
                    }
                }
            }

            if ($prefix) {
                push @cnodesKeys, $leaf;
            }

   # issue 2439
   # FIXME: in future versions, oidcOPMetaDataJSON and samlIDPMetaDataXML should
   # behave the same
            if ( $leaf =~ /^oidcOPMetaData(?:JSON|JWKS)$/ ) {
                push @simpleHashKeys, $leaf;
            }

            if ( $attr->{type} =~ /^(?:catAndAppList|\w+Container)$/ ) {
                $jleaf->{cnodes} = $prefix . $leaf;
                unless ( $prefix or $leaf =~ $reIgnoreKeys ) {
                    push @simpleHashKeys, $leaf;
                }
            }
            elsif ( $attr->{type} eq 'doubleHash' and $leaf !~ $reIgnoreKeys ) {
                push @doubleHashKeys, $leaf;
            }
            else {
                if ( $prefix and !$jleaf->{get} ) {
                    $jleaf->{get} = $prefix . $jleaf->{title};
                }
                if ( $attr->{type} eq 'bool' ) {
                    push @bool, $leaf;
                }
                if ( $attr->{type} eq 'array' ) {
                    push @arrayParam, $leaf;
                }
            }
            push @$json, $jleaf;
        }
    }
}

sub scanLeaf {
    my ( $self, $tree ) = @_;
    my @res;
    foreach my $k (@$tree) {
        if ( ref $k ) {
            push @res, $self->scanLeaf1( $k->{nodes} || $k->{group} );
        }
        else {
            push @res, $k;
        }
    }
    return @res;
}

sub scanLeaf1 {
    my ( $self, $tree ) = @_;
    my @res;
    foreach my $k (@$tree) {
        if ( ref $k ) {
            push @res, $self->scanLeaf( $k->{nodes} || $k->{group} );
        }
        else {
            push @res, $k;
        }
    }
    return @res;
}

sub reverseScan {
    my ( $self, $tree, $path, $res ) = @_;
    foreach my $elem (@$tree) {
        $elem =~ s/^\*//;
        if ( ref($elem) eq 'HASH' ) {
            foreach (qw(nodes nodes_cond group)) {
                $self->reverseScan( $elem->{$_}, "$path$elem->{title}/", $res )
                  if ( $elem->{$_} );
            }
        }
        else {
            my $tmp = $path;
            $tmp =~ s#/$##;
            $res->{$elem} = $tmp;
        }
    }
    return $res;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Build - Static files generator of Lemonldap::NG Web-SSO
system.

=head1 SYNOPSIS

  use Lemonldap::NG::Manager::Build;
  
  Lemonldap::NG::Manager::Build->run(
    structFile            => "site/htdocs/static/struct.json",
    confTreeFile          => "site/htdocs/static/js/conftree.js",
    managerConstantsFile  => "lib/Lemonldap/NG/Common/Conf/ReConstants.pm",
    managerAttributesFile => 'lib/Lemonldap/NG/Manager/Attributes.pm',
    defaultValuesFile     => "lib/Lemonldap/NG/Common/Conf/DefaultValues.pm",
    firstLmConfFile       => "_example/conf/lmConf-1.json",
    reverseTreeFile       => "site/htdocs/static/reverseTree.json",
  );

=head1 DESCRIPTION

Lemonldap::NG::Manager::Build is only used to build javascript files and
Lemonldap::NG constants Perl files. It must be launched after each change.

=head2 DEVELOPER CORNER

To add a new parameter, you have to:

=over

=item declare it in Manager/Build/Attributes.pm;

=item declare its position in the tree in Manager/Build/Tree.pm (or
Manager/Build/CTrees.pm for complex nodes);

=item refresh files by using this (or launch any build makefile target at the
root of the Lemonldap::NG project sources).

=back

See below for details.

=head3 Files generated

`scripts/jsongenerator.pl` file uses Lemonldap::NG::Manager::Build::Attributes,
Lemonldap::NG::Manager::Build::Tree and Lemonldap::NG::Manager::Build::CTrees to generate

=over

=item `site/htdocs/static/struct.json`:

Main file containing the tree view;

=item `site/htdocs/static/js/conftree.js`:

generates Virtualhosts, SAML and OpenID-Connect partners sub-trees;

=item `site/htdocs/static/reverseTree.json`:

map used by manager diff to find attribute position in the tree;

=item `Lemonldap::NG::Manager::Constants`:

constants used by all Perl manager components;

=item `Lemonldap::NG::Common::Conf::DefaultValues`:

constants used to read configuration;

=item `Lemonldap::NG::Manager::Attributes`:

parameters attributes used by the manager during configuration upload;

=item lmConf-1.json:

first configuration in file format;

=back

=head3 Attribute declaration

set your new attribute as a key of attributes() function that points to a hash
ref containing:

=over

=item type (required):

content type must be declared in sub types() in the same file
(except if attribute embeds its own tests) and must match
to a form stored in static/forms/ directory;

=item help (optional):

Relative HTML path to help page (relative to
/doc/pages/documentation/<version>/);

=item default (recommended):

default value to set if not defined;

=item select (optional):

required only if type is `select`. In this case, it
must contain an array of { k => <keyName>, v => <display name> } hashref

=item documentation (recommended):

some words for other developers

=item test (optional):

if test is not defined for this type or if test must
be more restrictive, set here a regular expression or a subroutine. Arguments
passed to subroutine are (keyValue, newConf, currentKey). It returns 2
arguments: a boolean result and a message (if non empty message will be
displayed as warning or error depending of result);

=item msgFail (optional):

for regexp based tests, message to display in case of
error. Words to translate have to be written as so: __toTranslate__;

=item keyTest (optional):

for keys/values attributes, test to be applied on key;

=item keyMsgFail (optional):

for regexp based key tests, same as msgFail for keys test;

=back

If you want to declare a new type, you have to declare following
properties:

=over

=item test, msgFail, keyTest, keyMsgFail as shown above,

=item form: form to use if it doesn't have the same name.

=back

=head3 Tree location

The tree is now very simple: it contains nodes and leaves. Leaves are designed only
by their attribute name. All description must be done in the file described
above. Nodes are array member designed as this:

  {
    title => 'titleToTranslate',
    help  => 'helpUrl',
    form  => 'relativeUrl',
    nodes => [
      ... nodes or leaf ...
    ]
  }

Explanations:

=over

=item title (required):

it must contain an entry of static/languages/lang.json

=item help (recommended):

as above, the relative HTML path to the help page
(relative to /doc/pages/documentation/<version>/);

=item form (optional):

the name of a static/forms/<name>.html file

=item nodes:

array of sub nodes and leaf attached to this node

=item group:

must never be used in conjunction with nodes. Array of leaves only
to be displayed in the same form

=item nodes_cond:

array of sub nodes that will be displayed with a filter. Not yet
documented here, see the source code of site/htdocs/static/js/filterFunctions.js.

=item nodes_filter:

filter entry in site/htdocs/static/js/filterFunctions.js for the same feature.

=back

=head1 SEE ALSO

L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

Note that if you want to post a ticket for a conf upload problem, please
see L<Lemonldap::NG::Manager::Conf::Parser> before.

=head1 DOWNLOAD

Lemonldap::NG is available at
L<https://lemonldap-ng.org/download>

=head1 COPYRIGHT AND LICENSE

See COPYING file for details.

This library is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see L<http://www.gnu.org/licenses/>.

=cut
