package Lemonldap::NG::Manager::Conf::Parser;

# This module is called either to parse a new configuration in JSON format (as
# posted by the web interface) and test a new configuration object.
#
# The new object must be built with the following properties:
#  - refConf: the actual configuration
#  - req    : the Lemonldap::NG::Common::PSGI::Request
#  - tree   : the new configuration in JSON format
#   or
#  - newConf: the configuration to test
#
# The main method is check() which calls:
#  - scanTree() if configuration is not parsed (JSON string)
#  - testNewConf()
#
# It returns a boolean. Errors, warnings and changes are stored as array
# containing `{ message => 'Explanation' }. A main message is stored in
# `message` property.

use strict;
use utf8;
use Crypt::URandom;
use Mouse;
use JSON 'to_json';
use Lemonldap::NG::Common::Conf::ReConstants;
use Lemonldap::NG::Manager::Attributes;

our $VERSION = '2.0.12';

extends 'Lemonldap::NG::Common::Conf::Compact';

# High debugging for developers, set this to 1
use constant HIGHDEBUG => 0;

# Messages storage
has errors => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { return [] }
);
has warnings => (
    is      => 'rw',
    isa     => 'ArrayRef',
    default => sub { return [] },
    trigger => sub {
        hdebug( 'warnings contains', $_[0]->{warnings} );
    }
);
has changes => ( is => 'rw', isa => 'ArrayRef', default => sub { return [] } );
has message => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub {
        return join( ', ', map { $_->{message} } @{ $_[0]->errors } );
    },
    trigger => sub {
        hdebug( "Message becomes " . $_[0]->{message} );
    }
);
has needConfirmation =>
  ( is => 'rw', isa => 'ArrayRef', default => sub { return [] } );

# Booleans
has confChanged => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
    trigger => sub {
        hdebug( "condChanged: " . $_[0]->{confChanged} );
    }
);

# Properties required during build
has refConf => ( is => 'ro', isa      => 'HashRef', required => 1 );
has req     => ( is => 'ro', required => 1 );
has newConf => ( is => 'rw', isa      => 'HashRef' );
has tree    => ( is => 'rw', isa      => 'ArrayRef' );

# High debug method
sub hdebug {
    if (HIGHDEBUG) {
        foreach my $d (@_) {
            if ( ref $d ) {
                require Data::Dumper;
                $Data::Dumper::Useperl = 1;
                print STDERR Data::Dumper::Dumper($d);
            }
            else { print STDERR "$d\n" }
        }
    }
    undef;
}

##@method boolean check()
# Main method
#@return result
sub check {
    my ( $self, $localConf ) = @_;

    hdebug("# check()");
    unless ( $self->newConf ) {
        return 0 unless ( $self->scanTree );
    }
    unless ( $self->testNewConf($localConf) ) {
        hdebug("  testNewConf() failed");
        return 0;
    }
    my $separator = $self->newConf->{multiValuesSeparator} || '; ';
    hdebug("  tests succeed");
    my %conf          = %{ $self->newConf };
    my %compactedConf = %{ $self->compactConf( $self->newConf ) };
    my @removedKeys   = ();
    unless ( $self->confChanged ) {
        hdebug("  no change detected");
        $self->message('__confNotChanged__');
        return 0;
    }

    # Return removed keys if conf compacted
    @removedKeys = map { exists $compactedConf{$_} ? () : $_ } sort keys %conf
      if ( $self->newConf->{compactConf} );
    push @{ $self->changes },
      (
        $self->{newConf}->{compactConf}
        ? {
            confCompacted => '1',
            removedKeys   => join( $separator, @removedKeys )
          }
        : { confCompacted => '0' }
      );

    return 1;
}

##@method boolean scanTree()
# Methods to build new conf from JSON string
#@result true if succeed
sub scanTree {
    my $self = shift;
    hdebug("# scanTree()");
    $self->newConf( {} );
    $self->_scanNodes( $self->tree ) or return 0;

    # Set cfgNum to ref cfgNum (will be changed when saving), set other
    # metadata and set a value to the key if empty
    $self->newConf->{cfgNum} = $self->req->params('cfgNum');
    $self->newConf->{cfgAuthor} =
      $self->req->userData->{ Lemonldap::NG::Handler::Main->tsv->{whatToTrace}
          || '_whatToTrace' } // $self->req->env->{REMOTE_USER}
      // $ENV{REMOTE_USER} // "anonymous";
    $self->newConf->{cfgAuthorIP} = $self->req->address;
    $self->newConf->{cfgAuthorIP} .=
      ' (maybe '
      . (    $self->req->env->{'X-Real-IP'}
          || $self->req->env->{HTTP_X_FORWARDED_FOR} )
      . ')'
      if $self->req->env->{'X-Real-IP'}
      or $self->req->env->{HTTP_X_FORWARDED_FOR};
    $self->newConf->{cfgDate}    = time;
    $self->newConf->{cfgVersion} = $Lemonldap::NG::Manager::VERSION;
    $self->newConf->{key} ||= join( '',
        map { chr( int( ord( Crypt::URandom::urandom(1) ) * 94 / 256 ) + 33 ) }
          ( 1 .. 16 ) );

    return 1;
}

use feature 'state';

##@method private boolean _scanNodes()
# Recursive JSON parser
#@result true if succeed
sub _scanNodes {
    my ( $self, $tree, ) = @_;
    hdebug("# _scanNodes()");
    state( $knownCat, %newNames );
    unless ( ref($tree) eq 'ARRAY' ) {
        print STDERR 'Fatal: node is not an array';
        push @{ $self->errors }, { message => 'Fatal: node is not an array' };
        return 0;
    }
    unless (@$tree) {
        hdebug('  empty tree !?');
    }
    foreach my $leaf (@$tree) {
        my $name = $leaf->{title};
        hdebug("Looking to $name");

        # subnode
        my $subNodes     = $leaf->{nodes}      // $leaf->{_nodes};
        my $subNodesCond = $leaf->{nodes_cond} // $leaf->{_nodes_cond};

        ##################################
        # VirtualHosts and SAML partners #
        ##################################

        # Root nodes
        if ( $leaf->{id} =~ /^($specialNodeKeys)$/io ) {
            hdebug("Root special node detected $leaf->{id}");

            # If node has not been opened
            if ( $leaf->{cnodes} ) {
                hdebug("  not opened");
                foreach my $k ( @{ $specialNodeHash->{ $leaf->{id} } } ) {
                    hdebug("  copying $k");
                    $self->newConf->{$k} = $self->refConf->{$k};
                }
                next;
            }
            $self->_scanNodes($subNodes);

            # Check deleted keys
            my $field = $specialNodeHash->{ $leaf->{id} }->[0];
            my @old   = keys %{ $self->refConf->{$field} };
            foreach my $k ( keys %{ $self->newConf->{$field} } ) {
                @old = grep { $_ ne $k } @old;
            }
            if (@old) {
                hdebug( "Keys detected as removed:", \@old );
                $self->confChanged(1);
                foreach my $deletedHost (@old) {
                    push @{ $self->changes },
                      { key => $leaf->{id}, old => $deletedHost };
                }
            }
            next;
        }

        # 1st sublevel
        elsif ( $leaf->{id} =~ /^($specialNodeKeys)\/([^\/]+)$/io ) {
            hdebug("Special node chield detected $leaf->{id}");
            my ( $base, $host ) = ( $1, $2 );

            # Check hostname/partner name changes (id points to the old name)
            $newNames{$host} = $leaf->{title};
            if ( $newNames{$host} ne $host and $host !~ /^new__/ ) {
                hdebug("  $host becomes $newNames{$host}");
                $self->confChanged(1);
                push @{ $self->changes },
                  { key => $base, old => $host, new => $newNames{$host} };
            }

            $self->_scanNodes($subNodes);
            next;
        }

        # Other sub levels
        elsif ( $leaf->{id} =~
            /^($specialNodeKeys)\/([^\/]+)\/([^\/]+)(?:\/(.*))?$/io )
        {
            my ( $base, $key, $oldName, $target, $h ) =
              ( $1, $newNames{$2}, $2, $3, $4 );
            hdebug(
                "Special node chield subnode detected $leaf->{id}",
                "  base $base, key $key, target $target, h "
                  . ( $h ? $h : 'undef' )
            );

            # VirtualHosts
            if ( $base eq 'virtualHosts' ) {
                hdebug("  virtualhost");
                if ( $target =~ /^(?:locationRules|exportedHeaders|post)$/ ) {
                    if ( $leaf->{cnodes} ) {
                        hdebug('    unopened subnode');
                        $self->newConf->{$target}->{$key} =
                          $self->refConf->{$target}->{$oldName} // {};
                    }

                    elsif ($h) {
                        hdebug('    4 levels');
                        if ( $target eq 'locationRules' ) {
                            hdebug('    locationRules');
                            my $k =
                              $leaf->{comment}
                              ? "(?#$leaf->{comment})$leaf->{re}"
                              : $leaf->{re};
                            $k .= "(?#AuthnLevel=$leaf->{level})"
                              if $leaf->{level};
                            $self->set( $target, $key, $k, $leaf->{data} );
                        }
                        else {
                            hdebug('    other than locationrules');
                            $self->set( $target, $key, $leaf->{title},
                                $leaf->{data} );
                        }
                    }

                    # Unless $h is set, scan subnodes and check changes
                    else {
                        hdebug('    3 levels only (missing $h)');
                        if ( ref $subNodes ) {
                            hdebug('    has subnodes');
                            $self->_scanNodes($subNodes)
                              or return 0;
                        }
                        if ( exists $self->refConf->{$target}->{$key}
                            and %{ $self->refConf->{$target}->{$key} } )
                        {
                            hdebug('    old conf subnode has values');
                            my $c = $self->newConf->{$target};
                            foreach my $k (
                                keys %{ $self->refConf->{$target}->{$key} } )
                            {
                                unless ( defined $c->{$key}->{$k} ) {
                                    hdebug('      missing value in old conf');
                                    $self->confChanged(1);
                                    push @{ $self->changes },
                                      {
                                        key => "$target, $key",
                                        old => $k,
                                      };
                                }
                            }
                        }
                        elsif ( exists $self->newConf->{$target}->{$key}
                            and %{ $self->newConf->{$target}->{$key} } )
                        {
                            hdebug("    '$key' has values");
                            $self->confChanged(1);
                            push @{ $self->changes },
                              { key => "$target", new => $key };
                        }
                    }
                }
                elsif ( $target =~ /^$virtualHostKeys$/o ) {
                    $self->set( 'vhostOptions', [ $oldName, $key ],
                        $target, $leaf->{data} );
                }
                else {
                    push @{ $self->errors },
                      { message => "Unknown vhost key $target" };
                    return 0;
                }
                next;
            }

            # SAML
            elsif ( $base =~ /^saml(?:S|ID)PMetaDataNodes$/ ) {
                hdebug('SAML');
                if ( defined $leaf->{data}
                    and ref( $leaf->{data} ) eq 'ARRAY' )
                {
                    hdebug("  SAML data is an array, serializing");
                    $leaf->{data} = join ';', @{ $leaf->{data} };
                }
                if ( $target =~
                    /^saml(?:S|ID)PMetaData(?:ExportedAttributes|Macros)$/ )
                {
                    if ( $leaf->{cnodes} ) {
                        hdebug("  $target: unopened node");
                        $self->newConf->{$target}->{$key} =
                          $self->refConf->{$target}->{$oldName} // {};
                    }
                    elsif ($h) {
                        hdebug("  $target: opened node");
                        $self->confChanged(1);
                        $self->set( $target, $key, $leaf->{title},
                            $leaf->{data} );
                    }
                    elsif ( !@$subNodes ) {
                        hdebug("  $target: no subnodes");
                        $self->confChanged(1);
                    }
                    else {
                        hdebug("  $target: scanning subnodes");
                        $self->_scanNodes($subNodes);
                    }
                }
                elsif ( $target =~ /^saml(?:S|ID)PMetaDataXML$/ ) {
                    hdebug("  $target");
                    $self->set( $target, [ $oldName, $key ],
                        $target, $leaf->{data} );
                }
                elsif ( $target =~ /^saml(?:ID|S)PMetaDataOptions/ ) {
                    my $optKey = $&;
                    hdebug("  $base sub key: $target");
                    if ( $target =~
                        /^(?:$samlIDPMetaDataNodeKeys|$samlSPMetaDataNodeKeys)/o
                      )
                    {
                        $self->set(
                            $optKey, [ $oldName, $key ],
                            $target, $leaf->{data}
                        );
                    }
                    else {
                        push @{ $self->errors },
                          { message => "Unknown SAML metadata option $target" };
                        return 0;
                    }
                }
                else {
                    push @{ $self->errors },
                      { message => "Unknown SAML key $target" };
                    return 0;
                }
                next;
            }

            # OIDC
            elsif ( $base =~ /^oidc(?:O|R)PMetaDataNodes$/ ) {
                hdebug('OIDC');
                if ( $target =~ /^oidc(?:O|R)PMetaDataOptions$/ ) {
                    hdebug("  $target: looking for subnodes");
                    $self->_scanNodes($subNodes);
                    $self->set( $target, $key, $leaf->{title}, $leaf->{data} );
                }
                elsif ( $target =~ /^oidcOPMetaData(?:JSON|JWKS)$/ ) {
                    hdebug("  $target");
                    $self->set( $target, $key, $leaf->{data} );
                }
                elsif ( $target =~ /^oidcRPMetaDataExportedVars$/ ) {
                    hdebug("  $target");
                    if ( $leaf->{cnodes} ) {
                        hdebug('    unopened');
                        $self->newConf->{$target}->{$key} =
                          $self->refConf->{$target}->{$oldName} // {};
                    }
                    elsif ($h) {
                        hdebug('    opened');
                        $self->confChanged(1);
                        my $tmp = $leaf->{data};
                        if ( ref( $leaf->{data} ) eq 'ARRAY' ) {

                            # Forward compatibility. If Type and Array have
                            # default values, store in old format
                            if (    $leaf->{data}->[1] eq "string"
                                and $leaf->{data}->[2] eq "auto" )
                            {
                                $tmp = $leaf->{data}->[0];
                            }
                            else {
                                $tmp = join ';', @{ $leaf->{data} };
                            }
                        }
                        $self->set( $target, $key, $leaf->{title}, $tmp );
                    }
                    elsif ( !@$subNodes ) {
                        hdebug("  $target: no subnodes");
                        $self->confChanged(1);
                    }
                    else {
                        hdebug("  $target: scanning subnodes");
                        $self->_scanNodes($subNodes);
                    }
                }
                elsif ( $target =~
                    /^oidc(?:O|R)PMetaData(?:ExportedVars|Macros|ScopeRules)$/ )
                {
                    hdebug("  $target");
                    if ( $leaf->{cnodes} ) {
                        hdebug('    unopened');
                        $self->newConf->{$target}->{$key} =
                          $self->refConf->{$target}->{$oldName} // {};
                    }
                    elsif ($h) {
                        hdebug('    opened');
                        $self->confChanged(1);
                        $self->set( $target, $key, $leaf->{title},
                            $leaf->{data} );
                    }
                    elsif ( !@$subNodes ) {
                        hdebug("  $target: no subnodes");
                        $self->confChanged(1);
                    }
                    else {
                        hdebug("  $target: scanning subnodes");
                        $self->_scanNodes($subNodes);
                    }
                }
                elsif ( $target =~ /^oidc(?:O|R)PMetaDataOptions/ ) {
                    my $optKey = $&;
                    hdebug "  $base sub key: $target";
                    if ( $target eq 'oidcRPMetaDataOptionsExtraClaims' ) {
                        if ( $leaf->{cnodes} ) {
                            hdebug('    unopened');
                            $self->newConf->{$target}->{$key} =
                              $self->refConf->{$target}->{$oldName} // {};
                        }
                        elsif ($h) {
                            hdebug('    opened');
                            $self->set( $target, $key, $leaf->{title},
                                $leaf->{data} );
                        }
                        elsif ( !@$subNodes ) {
                            hdebug("  $target: no subnodes");
                            $self->confChanged(1);
                        }
                        else {
                            hdebug("  $target: scanning subnodes");
                            $self->_scanNodes($subNodes);
                        }
                    }
                    elsif ( $target =~
                        /^(?:$oidcOPMetaDataNodeKeys|$oidcRPMetaDataNodeKeys)/o
                      )
                    {
                        $self->set(
                            $optKey, [ $oldName, $key ],
                            $target, $leaf->{data}
                        );
                    }
                    else {
                        push @{ $self->errors },
                          { message => "Unknown OIDC metadata option $target" };
                        return 0;
                    }
                }
                else {
                    push @{ $self->errors },
                      { message => "Unknown OIDC key $target" };
                    return 0;
                }
                next;
            }

            # CAS
            elsif ( $base =~ /^cas(?:App|Srv)MetaDataNodes$/ ) {
                my $optKey = $&;
                hdebug('CAS');
                if ( $target =~ /^cas(?:App|Srv)MetaDataOptions$/ ) {
                    hdebug("  $target: looking for subnodes");
                    $self->_scanNodes($subNodes);
                    $self->set( $target, $key, $leaf->{title}, $leaf->{data} );
                }
                elsif ( $target =~
                    /^cas(?:App|Srv)MetaData(?:ExportedVars|Macros)$/ )
                {
                    hdebug("  $target");
                    if ( $leaf->{cnodes} ) {
                        hdebug('    unopened');
                        $self->newConf->{$target}->{$key} =
                          $self->refConf->{$target}->{$oldName} // {};
                    }
                    elsif ($h) {
                        hdebug('    opened');
                        $self->confChanged(1);
                        $self->set( $target, $key, $leaf->{title},
                            $leaf->{data} );
                    }
                    elsif ( !@$subNodes ) {
                        hdebug("  $target: no subnodes");
                        $self->confChanged(1);
                    }
                    else {
                        hdebug("  $target: scanning subnodes");
                        $self->_scanNodes($subNodes);
                    }
                }
                elsif ( $target =~ /^cas(?:Srv|App)MetaDataOptions/ ) {
                    my $optKey = $&;
                    hdebug "  $base sub key: $target";
                    if ( $target eq 'casSrvMetaDataOptionsProxiedServices' ) {
                        if ( $leaf->{cnodes} ) {
                            hdebug('    unopened');
                            $self->newConf->{$target}->{$key} =
                              $self->refConf->{$target}->{$oldName} // {};
                        }
                        elsif ($h) {
                            hdebug('    opened');
                            $self->set( $target, $key, $leaf->{title},
                                $leaf->{data} );
                        }
                        elsif ( !@$subNodes ) {
                            hdebug("  $target: no subnodes");
                            $self->confChanged(1);
                        }
                        else {
                            hdebug("  $target: scanning subnodes");
                            $self->_scanNodes($subNodes);
                        }
                    }
                    elsif ( $target =~
                        /^(?:$casSrvMetaDataNodeKeys|$casAppMetaDataNodeKeys)/o
                      )
                    {
                        $self->set(
                            $optKey, [ $oldName, $key ],
                            $target, $leaf->{data}
                        );
                    }
                    else {
                        push @{ $self->errors },
                          { message => "Unknown CAS metadata option $target" };
                        return 0;
                    }
                }
                else {
                    push @{ $self->errors },
                      { message => "Unknown CAS option $target" };
                    return 0;
                }
                next;
            }
            else {
                push @{ $self->errors },
                  { message => "Fatal: unknown special sub node $base" };
                return 0;
            }
        }

        ####################
        # Application list #
        ####################

        # Application list root node
        elsif ( $leaf->{title} eq 'applicationList' ) {
            hdebug( $leaf->{title} );
            if ( $leaf->{cnodes} ) {
                hdebug('  unopened');
                $self->newConf->{applicationList} =
                  $self->refConf->{applicationList} // {};
            }
            else {
                $self->_scanNodes($subNodes) or return 0;

                # Check for deleted
                my @listCatRef =
                  map { $self->refConf->{applicationList}->{$_}->{catname} }
                  keys %{ $self->refConf->{applicationList} };
                my @listCatNew =
                  map { $self->newConf->{applicationList}->{$_}->{catname} }
                  keys(
                    %{
                        ref $self->newConf->{applicationList}
                        ? $self->newConf->{applicationList}
                        : {}
                    }
                  );

                @listCatRef = map { $_ ? $_ : () } @listCatRef;
                @listCatNew = map { $_ ? $_ : () } @listCatNew;
                @listCatRef = sort @listCatRef;
                @listCatNew = sort @listCatNew;
                hdebug( '# @listCatRef : ', \@listCatRef );
                hdebug( '# @listCatNew : ', \@listCatNew );

                # Check for deleted
                my @diff =
                  grep !${ { map { $_, 1 } @listCatNew } }{$_}, @listCatRef;
                if ( scalar @diff ) {
                    $self->confChanged(1);
                    push @{ $self->changes },
                      {
                        new => join( ', ', 'categoryList',      @listCatNew ),
                        key => join( ', ', 'Deletes in cat(s)', @diff ),
                        old => join( ', ', 'categoryList',      @listCatRef ),
                      };
                }
            }
            next;
        }

        # Application list sub nodes
        elsif ( $leaf->{id} =~ /^applicationList\/(.+)$/ ) {
            hdebug('Application list subnode');
            use feature 'state';
            my @cats = split /\//, $1;
            my $app  = pop @cats;
            $self->newConf->{applicationList} //= {};

            # $cn is a pointer to the parent
            my $cn  = $self->newConf->{applicationList};
            my $cmp = $self->refConf->{applicationList};
            my @path;

            # Makes $cn point to the parent
            foreach my $cat (@cats) {
                hdebug("  looking to cat $cat");
                unless ( defined $knownCat->{$cat} ) {
                    push @{ $self->{errors} },
                      { message =>
                          "Fatal: sub cat/app before parent ($leaf->{id})" };
                    return 0;
                }
                $cn = $cn->{ $knownCat->{$cat} };
                push @path, $cn->{catname};
                $cmp->{$cat} //= {};
                $cmp = $cmp->{$cat};
            }

            my $newapp = $app;

         # Compute a nice name for new nodes, taking care of potential conflicts
         # For some reason, the manager sends /nNaN sometimes
            if ( $newapp =~ /^n(\d+|NaN)$/ ) {

                # Remove all special characters
                my $baseName = $leaf->{title} =~ s/\W//gr;
                $baseName = lc $baseName;
                $newapp   = $baseName;
                my $cnt = 1;
                while ( exists $cn->{$newapp} ) {
                    $newapp = "${baseName}_" . $cnt++;
                }
            }

            # Create new category
            #
            # Note that this works because nodes are ordered so "cat/cat2/app"
            # is looked after "cat" and "cat/cat2"
            if ( $leaf->{type} eq 'menuCat' ) {
                hdebug('  menu cat');
                $knownCat->{__id}++;
                $knownCat->{$app} = $newapp;
                $cn->{$newapp}    = {
                    catname => $leaf->{title},
                    type    => 'category',
                    order   => $knownCat->{__id}
                };
                unless ($cmp->{$app}
                    and $cmp->{$app}->{catname} eq $cn->{$newapp}->{catname} )
                {
                    $self->confChanged(1);
                    push @{ $self->changes },
                      {
                        key => join(
                            ', ', 'applicationList', @path, $leaf->{title}
                        ),
                        new => $cn->{$newapp}->{catname},
                        old => (
                            $cn->{$newapp} ? $cn->{$newapp}->{catname} : undef
                        )
                      };
                }
                if ( ref $subNodes ) {
                    $self->_scanNodes($subNodes) or return 0;
                }
                my @listCatRef = keys %{ $cmp->{$app} };
                my @listCatNew = keys %{ $cn->{$newapp} };

                # Check for deleted
                unless ( @listCatRef == @listCatNew ) {
                    $self->confChanged(1);
                    push @{ $self->changes },
                      {
                        key => join( ', ', 'applicationList', @path ),
                        new => 'Changes in cat(s)/app(s)',
                      };
                }
            }

            # Create new apps
            if ( $leaf->{type} eq 'menuApp' ) {
                hdebug('  new app');
                $knownCat->{__id}++;
                $cn->{$newapp} = {
                    type    => 'application',
                    options => $leaf->{data},
                    order   => $knownCat->{__id}
                };
                $cn->{$newapp}->{options}->{name} = $leaf->{title};
                unless ( $cmp->{$app} ) {
                    $self->confChanged(1);
                    push @{ $self->changes },
                      {
                        key => join( ', ', 'applicationList', @path ),
                        new => $leaf->{title},
                      };
                }
                else {
                    # Check for change in ordering
                    if ( ( $cn->{$newapp}->{order} || 0 ) !=
                        ( $cmp->{$newapp}->{order} || 0 ) )
                    {
                        $self->confChanged(1);
                    }

                    # Check for change in options
                    foreach my $k ( keys %{ $cn->{$newapp}->{options} } ) {
                        unless ( $cmp->{$app}->{options}->{$k} eq
                            $cn->{$newapp}->{options}->{$k} )
                        {
                            $self->confChanged(1);
                            push @{ $self->changes },
                              {
                                key => join( ', ',
                                    'applicationList', @path,
                                    $leaf->{title},    $k ),
                                new => $cn->{$newapp}->{options}->{$k},
                                old => $cmp->{$app}->{options}->{$k}
                              };
                        }
                    }
                }
            }
            next;
        }
        elsif ( $leaf->{id} eq 'grantSessionRules' ) {
            hdebug('grantSessionRules');
            if ( $leaf->{cnodes} ) {
                hdebug('  unopened');
                $self->newConf->{$name} = $self->refConf->{$name} // {};
            }
            else {
                hdebug('  opened');
                $subNodes //= [];
                my $count = 0;
                my $ref   = $self->refConf->{grantSessionRules};
                my $new   = $self->newConf->{grantSessionRules};
                my @old   = ref $ref ? keys %$ref : ();
                $self->newConf->{grantSessionRules} = {};
                foreach my $n (@$subNodes) {
                    hdebug("  looking at $n subnode");
                    my $k =
                      $n->{re} . ( $n->{comment} ? "##$n->{comment}" : '' );
                    $self->newConf->{grantSessionRules}->{$k} = $n->{data};
                    $count++;
                    unless ( defined $ref->{$k} ) {
                        $self->confChanged(1);
                        push @{ $self->changes },
                          { keys => 'grantSessionRules', new => $k };
                    }
                    elsif ( $ref->{$k} ne $n->{data} ) {
                        $self->confChanged(1);
                        push @{ $self->changes },
                          {
                            key => "grantSessionRules, $k",
                            old => $self->refConf->{grantSessionRules}->{$k},
                            new => $n->{data}
                          };
                    }
                    @old = grep { $_ ne $k } @old;
                }
                if (@old) {
                    $self->confChanged(1);
                    push @{ $self->changes },
                      { key => 'grantSessionRules', old => $_, }
                      foreach (@old);
                }
            }
            next;
        }

        # openIdIDPList: data is splitted by Conf.pm into a boolean and a
        # string
        elsif ( $name eq 'openIdIDPList' ) {
            hdebug('openIdIDPList');
            if ( $leaf->{data} ) {
                unless ( ref $leaf->{data} eq 'ARRAY' ) {
                    push @{ $self->{errors} },
                      { message => 'Malformed openIdIDPList ' . $leaf->{data} };
                    return 0;
                }
                $self->set( $name, join( ';', @{ $leaf->{data} } ) );
            }
            else {
                $self->set( $name, undef );
            }
            next;
        }

        ####################
        # Other hash nodes #
        ####################
        elsif ( $leaf->{title} =~ /^$simpleHashKeys$/o
            and not $leaf->{title} eq 'applicationList' )
        {
            hdebug( $leaf->{title} );

            # If a `cnodes` key is found, keep old key unchanges
            if ( $leaf->{cnodes} ) {
                hdebug('  unopened');
                $self->newConf->{$name} = $self->refConf->{$name} // {};
            }
            else {
                hdebug('  opened');

                # combModules: just to replace "over" key
                if ( $name eq 'combModules' ) {
                    hdebug('     combModules');
                    $self->newConf->{$name} = {};
                    foreach my $node ( @{ $leaf->{nodes} } ) {
                        my $tmp;
                        $tmp->{$_} = $node->{data}->{$_} foreach (qw(type for));
                        $tmp->{over} = {};
                        foreach ( @{ $node->{data}->{over} } ) {
                            $tmp->{over}->{ $_->[0] } = $_->[1];
                        }
                        $self->newConf->{$name}->{ $node->{title} } = $tmp;
                    }

                    # TODO: check changes
                    $self->confChanged(1);
                    next;
                }

                # sfExtra: just to replace "over" key
                if ( $name eq 'sfExtra' ) {
                    hdebug('     sfExtra');
                    $self->newConf->{$name} = {};
                    foreach my $node ( @{ $leaf->{nodes} } ) {
                        my $tmp;
                        $tmp->{$_} = $node->{data}->{$_}
                          foreach (qw(type rule logo level label));
                        $tmp->{register} = $node->{data}->{register} ? 1 : 0;
                        $tmp->{over}     = {};
                        foreach ( @{ $node->{data}->{over} } ) {
                            $tmp->{over}->{ $_->[0] } = $_->[1];
                        }
                        $self->newConf->{$name}->{ $node->{title} } = $tmp;
                    }

                    # TODO: check changes
                    $self->confChanged(1);
                    next;
                }

                $subNodes //= [];
                my $count = 0;
                my @old   = (
                    ref( $self->refConf->{$name} )
                    ? ( keys %{ $self->refConf->{$name} } )
                    : ()
                );
                $self->newConf->{$name} = {};
                foreach my $n (@$subNodes) {
                    hdebug("  looking at $n subnode");
                    if ( ref $n->{data} and ref $n->{data} eq 'ARRAY' ) {

                        # authChoiceModules
                        if ( $name eq 'authChoiceModules' ) {
                            hdebug('     authChoiceModules');
                            if ( ref( $n->{data}->[5] ) eq 'ARRAY' ) {
                                $n->{data}->[5] = to_json(
                                    { map { @$_ } @{ $n->{data}->[5] } } );
                            }
                            else {
                                $n->{data}->[5] = '{}';
                            }
                        }

                        $n->{data} = join ';', @{ $n->{data} };
                    }
                    $self->newConf->{$name}->{ $n->{title} } = $n->{data};
                    $count++;
                    unless ( defined $self->refConf->{$name}->{ $n->{title} } )
                    {
                        $self->confChanged(1);
                        push @{ $self->changes },
                          { key => $name, new => $n->{title}, };
                    }
                    elsif (
                        $self->refConf->{$name}->{ $n->{title} } ne $n->{data} )
                    {
                        $self->confChanged(1);
                        push @{ $self->changes },
                          {
                            key => "$name, $n->{title}",
                            old => $self->refConf->{$name}->{ $n->{title} },
                            new => $n->{data}
                          };
                    }
                    @old = grep { $_ ne $n->{title} } @old;
                }
                if (@old) {
                    $self->confChanged(1);
                    push @{ $self->changes }, { key => $name, old => $_, }
                      foreach (@old);
                }
            }
            next;
        }

        # Double hash nodes
        elsif ( $leaf->{title} =~ /^$doubleHashKeys$/ ) {
            hdebug( $leaf->{title} );
            my @oldHosts = (
                ref( $self->refConf->{$name} )
                ? ( keys %{ $self->refConf->{$name} } )
                : ()
            );
            $self->newConf->{$name} = {};
            unless ( defined $leaf->{data} ) {
                hdebug('  unopened');
                $self->newConf->{$name} = $self->refConf->{$name} || {};
                next;
            }
            foreach my $getHost ( @{ $leaf->{data} } ) {
                my $change = 0;
                my @oldKeys;
                my $host = $getHost->{k};
                hdebug("  looking at host: $host");
                $self->newConf->{$name}->{$host} = {};
                unless ( defined $self->refConf->{$name}->{$host} ) {
                    $self->confChanged(1);
                    $change++;
                    push @{ $self->changes }, { key => $name, new => $host };
                    hdebug("    $host is new");
                }
                else {
                    @oldHosts = grep { $_ ne $host } @oldHosts;
                    @oldKeys  = keys %{ $self->refConf->{$name}->{$host} };
                }
                foreach my $prm ( @{ $getHost->{h} } ) {
                    $self->newConf->{$name}->{$host}->{ $prm->{k} } =
                      $prm->{v};
                    if (
                        !$change
                        and (
                            not defined(
                                $self->refConf->{$name}->{$host}->{ $prm->{k} }
                            )
                            or $self->newConf->{$name}->{$host}->{ $prm->{k} }
                            ne $self->refConf->{$name}->{$host}->{ $prm->{k} }
                        )
                      )
                    {
                        $self->confChanged(1);
                        hdebug("    key $prm->{k} has been changed");
                        push @{ $self->changes },
                          { key => "$name/$host", new => $prm->{k} };
                    }
                    elsif ( !$change ) {
                        @oldKeys = grep { $_ ne $prm->{k} } @oldKeys;
                    }
                }
                if (@oldKeys) {
                    $self->confChanged(1);
                    hdebug( "  old keys: " . join( ' ', @oldKeys ) );
                    push @{ $self->changes },
                      { key => "$name/$host", old => $_ }
                      foreach (@oldKeys);
                }
            }
            if (@oldHosts) {
                $self->confChanged(1);
                hdebug( "  old hosts " . join( ' ', @oldHosts ) );
                push @{ $self->changes }, { key => "$name", old => $_ }
                  foreach (@oldHosts);
            }
            next;
        }

        ###############
        # Other nodes #
        ###############

        # Check if subnodes
        my $n = 0;
        if ( ref $subNodesCond ) {
            hdebug('  conditional subnodes detected');

            # Bad idea,subnode unopened are not read
            #$subNodesCond = [ grep { $_->{show} } @$subNodesCond ];
            $self->_scanNodes($subNodesCond) or return 0;
            $n++;
        }
        if ( ref $subNodes ) {
            hdebug('  subnodes detected');
            $self->_scanNodes($subNodes) or return 0;
            $n++;
        }
        if ($n) {
            next;
        }
        if ( defined $leaf->{data} and ref( $leaf->{data} ) eq 'ARRAY' ) {
            if ( ref( $leaf->{data}->[0] ) eq 'HASH' ) {
                hdebug("  array found");
                $self->_scanNodes( $leaf->{data} ) or return 0;
            }
            else {
                $self->set( $name, join( ';', @{ $leaf->{data} } ) );
            }
        }

        # Grouped nodes not opened
        elsif ( $leaf->{get} and ref $leaf->{get} eq 'ARRAY' ) {
            hdebug("  unopened grouped node");
            foreach my $subkey ( @{ $leaf->{get} } ) {
                $self->set( $subkey, undef );
            }
        }

        # Normal leaf
        else {
            $self->set( $name, $leaf->{data} );
        }
    }
    return 1;
}

##@method private void set($target, @path, $data)
# Store a value in the $target key (following subkeys if @path is set)
sub set {
    my $self  = shift;
    my $data  = pop;
    my @confs = ( $self->refConf, $self->newConf );
    my @path;
    while ( @_ > 1 ) {
        my $tmp = shift;
        push @path, $tmp;
        foreach my $i ( 0, 1 ) {
            my $v = ref($tmp) ? $tmp->[$i] : $tmp;
            $confs[$i]->{$v} //= {};
            $confs[$i] = $confs[$i]->{$v};
        }
    }
    my $target = shift;
    hdebug( "# set() called:",
        { data => $data, path => \@path, target => $target } );
    die @path unless ($target);

    # Check new value
    if ( defined $data ) {
        hdebug("  data defined");

        # TODO: remove if $data == default value
        $confs[1]->{$target} = $data;
        eval {
            unless (
                $target eq 'cfgLog'
                or ( defined $confs[0]->{$target}
                    and $confs[0]->{$target} eq $data )
                or (   !defined $confs[0]->{$target}
                    and defined $self->defaultValue($target)
                    and $data eq $self->defaultValue($target) )
              )
            {
                $self->confChanged(1);
                push @{ $self->changes },
                  {
                    key => join( ', ', @path, $target ),
                    old => $confs[0]->{$target} // $self->defaultValue($target),
                    new => $confs[1]->{$target}
                  };
            }
        };
    }

    # Set old value if exists
    else {
        hdebug("  data undefined");
        if ( exists $confs[0]->{$target} ) {
            hdebug("    old value exists");
            $confs[1]->{$target} = $confs[0]->{$target};
        }
        else {
            hdebug("    no old value, skipping");
        }
    }
}

sub defaultValue {
    my ( $self, $target ) = @_;
    hdebug("# defaultValue($target)");
    die unless ($target);
    my $res = eval {
        &Lemonldap::NG::Manager::Attributes::attributes()->{$target}
          ->{'default'};
    };
    return $res;
}

##@method boolean testNewConf()
# Launch _unitTest() and _globaTest()
#
#@return true if tests succeed
sub testNewConf {
    my ( $self, $localConf ) = @_;

    hdebug('# testNewConf()');
    return $self->_unitTest( $self->newConf(), $localConf )
      && $self->_globalTest($localConf);
}

##@method private boolean _unitTest()
# Launch unit tests declared in Lemonldap::NG::Manager::Build::Attributes file
#
#@return true if tests succeed
sub _unitTest {
    my ( $self, $conf, $localConf ) = @_;
    hdebug('# _unitTest()');
    my $types = &Lemonldap::NG::Manager::Attributes::types();
    my $attrs = &Lemonldap::NG::Manager::Attributes::attributes();
    my $res   = 1;

    foreach my $key ( keys %$conf ) {
        if (    $localConf
            and $localConf->{skippedUnitTests}
            and $localConf->{skippedUnitTests} =~ /\b$key\b/ )
        {
            $localConf->logger->debug("-> Ignore test for $key\n");
            next;
        }
        hdebug("Testing $key");
        my $attr = $attrs->{$key};
        my $type = $types->{ $attr->{type} } if $attr;
        unless ( $type or $attr->{test} ) {
            $localConf->logger->debug("Unknown attribute $key, deleting it\n")
              if $localConf;
            delete $conf->{$key};
            next;
        }

        # Vhost, CAS, SAML, OIDC options
        if ( $key =~
/^(?^:(?:(?:(?:saml(?:ID|S)|oidc[OR])P|cas(?:App|Srv))MetaData|vhost)Options)$/
          )
        {

            # Iterate on vhost names, or saml/cas/oidc configuration keys
            for my $vhost ( keys %{ $conf->{$key} } ) {
                my $options = $conf->{$key}->{$vhost};
                if ( ref($options) eq "HASH" ) {

                    # Recurse on option list,
                    # FIXME this does check for oidcRPMetaDataOptionsXXX
                    # appearing under samlSPMetadataOptions
                    $res = 0
                      unless $self->_unitTest( $options, $localConf,
                        "$key/$vhost/" );
                }
            }
        }

        else {

            # Check if key exists
            unless ($attr) {
                push @{ $self->errors }, { message => "__unknownKey__: $key" };
                $res = 0;
                next;
            }

            # Hash parameters
            if ( $key =~ /^$simpleHashKeys$/o ) {
                $conf->{$key} //= {};
                unless ( ref $conf->{$key} eq 'HASH' ) {
                    push @{ $self->errors },
                      { message => "$key is not a hash ref" };
                    $res = 0;
                    next;
                }
            }
            elsif ( $attr->{type} =~ /Container$/ ) {

                #TODO
            }
            if (   $key =~ /^(?:$simpleHashKeys|$doubleHashKeys)$/o
                or $attr->{type} =~ /Container$/ )
            {
                $res = 0
                  unless (
                    $self->_execTest( {
                            keyTest    => $attr->{keyTest} // $type->{keyTest},
                            keyMsgFail => $attr->{keyMsgFail}
                              // $type->{keyMsgFail},
                            test    => $attr->{test}    // $type->{test},
                            msgFail => $attr->{msgFail} // $type->{msgFail},
                        },
                        $conf->{$key},
                        $key, $attr, undef, $conf
                    )
                  );
            }
            elsif ( defined $attr->{keyTest} ) {

                #TODO
            }
            else {
                my $msg = $attr->{msgFail} // $type->{msgFail};
                $res = 0
                  unless (
                    $self->_execTest(
                        $attr->{test} // $type->{test},
                        $conf->{$key}, $key, $attr, $msg, $conf
                    )
                  );
            }
        }
    }
    return $res;
}

##@method private boolean _execTest($test, $value)
# Execute the given test with value
#@param test that can be a code-ref, or a regexp
#@return result of test
sub _execTest {
    my ( $self, $test, $value, $key, $attr, $msg, $conf ) = @_;
    my $ref;
    die
"Malformed test for $key: only regexp ref or sub are accepted (type \"$ref\")"
      unless ( $ref = ref($test) and $ref =~ /^(CODE|Regexp|HASH)$/ );
    if ( $ref eq 'CODE' ) {
        my ( $r, $m ) = ( $test->( $value, $conf, $attr ) );
        if ($m) {
            push @{
                $self->{ (
                        $r > 0
                        ? 'warnings'
                        : ( $r < 0 ? 'needConfirmation' : 'errors' )
                    )
                }
              },
              { message => "$key: $m" };
        }
        elsif ( !$r ) {
            push @{ $self->{errors} }, { message => "$key: $msg" };
        }
        return $r;
    }
    elsif ( $ref eq 'Regexp' ) {
        my $r = $value =~ $test;
        push @{ $self->errors }, { message => "$key: $msg" } unless ($r);
        return $r;
    }

    # Recursive test (for locationRules,...)
    else {
        my $res = 1;
        return $res unless ( ref($value) eq 'HASH' );
        foreach my $k ( keys %$value ) {
            $res = 0
              unless (
                $self->_execTest(
                    $test->{keyTest}, $k,                  "$key/$k",
                    $attr,            $test->{keyMsgFail}, $conf
                )
                and $self->_execTest(
                    $test->{test}, $value->{$k},     "$key/$k",
                    $attr,         $test->{msgFail}, $conf
                )
              );
        }
        return $res;
    }
}

##@method private boolean _globalTest()
# Launch all tests declared in Lemonldap::NG::Manager::Conf::Tests::tests()
#
#@return true if tests succeed
sub _globalTest {
    my ( $self, $localConf ) = @_;

    require Lemonldap::NG::Manager::Conf::Tests;
    hdebug('# _globalTest()');
    my $result = 1;
    my $tests  = &Lemonldap::NG::Manager::Conf::Tests::tests( $self->newConf );

    foreach my $name ( keys %$tests ) {
        if (    $localConf
            and $localConf->{skippedGlobalTests}
            and $localConf->{skippedGlobalTests} =~ /\b$name\b/ )
        {
            $localConf->logger->debug("-> Ignore test for $name\n")
              if $localConf;
            next;
        }
        my $sub = $tests->{$name};
        my ( $res, $msg );
        eval {
            ( $res, $msg ) = $sub->();
            if ( $res == -1 ) {
                push @{ $self->needConfirmation }, { message => $msg };
            }
            elsif ($res) {
                if ($msg) {
                    push @{ $self->warnings }, { message => $msg };
                }
            }
            else {
                $result = 0;
                push @{ $self->errors }, { message => $msg };
            }
        };
        if ($@) {
            push @{ $self->warnings }, "Test $name failed: $@";
            $localConf->logger->debug("Test $name failed: $@\n") if $localConf;
        }
    }
    return $result;
}

1;
__END__

=head1 NAME

=encoding utf8

Lemonldap::NG::Manager::Conf::Parser - Perl extension for parsing new uploaded
configurations.

=head1 SYNOPSIS

  require Lemonldap::NG::Manager::Conf::Parser;
  my $parser = Lemonldap::NG::Manager::Conf::Parser->new(
      { tree => $new, refConf => $self->currentConf }
  );
  my $res = { result => $parser->check };
  $res->{message} = $parser->{message};
  foreach my $t (qw(errors warnings changes)) {
      push @{ $res->{details} }, { message => $t, items => $parser->$t }
        if ( @{$parser->$t} );
  }

=head1 DESCRIPTION

Lemonldap::NG::Manager::Conf::Parser checks new configuration

This package is used by Manager to examine uploaded configuration. It is
currently called using check() which return a boolean.
check() looks if a newConf is available. If not, it builds it from uploaded
JSON (using scanTree() subroutine)

Messages are stored in errors(), warnings() and changes() as arrays.

This interface uses L<Plack> to be compatible with CGI, FastCGI,...

=head1 SEE ALSO

L<Lemonldap::NG::Manager>, L<http://lemonldap-ng.org/>

=head1 AUTHORS

=over

=item LemonLDAP::NG team L<http://lemonldap-ng.org/team>

=back

=head1 BUG REPORT

Use OW2 system to report bug or ask for features:
L<https://gitlab.ow2.org/lemonldap-ng/lemonldap-ng/issues>

If you want to report a bug concerning configuration upload, please change
HIGHDEBUG constant value to produce more logs. Then post them in the Gitlab
ticket.

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
