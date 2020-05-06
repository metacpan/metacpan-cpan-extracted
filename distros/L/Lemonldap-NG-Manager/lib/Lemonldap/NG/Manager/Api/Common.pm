package Lemonldap::NG::Manager::Api::Common;

our $VERSION = '2.0.8';

package Lemonldap::NG::Manager::Api;

use Lemonldap::NG::Manager::Build::Attributes;
use Lemonldap::NG::Manager::Build::CTrees;

# use Scalar::Util 'weaken'; ?

sub _isSimpleKeyValueHash {
    my ( $self, $hash ) = @_;
    return 0 if ( ref($hash) ne "HASH" );

    foreach ( keys %$hash ) {
        return 0 if ( ref( $hash->{$_} ) ne '' || ref($_) ne '' );
    }

    return 1;
}

sub _getDefaultValues {
    my ( $self, $rootNode ) = @_;
    my @allAttrs     = $self->_listAttributes($rootNode);
    my $defaultAttrs = Lemonldap::NG::Manager::Build::Attributes::attributes();
    my $attrs        = {};

    foreach $attr (@allAttrs) {
        $attrs->{$attr} = $defaultAttrs->{$attr}->{default}
          if ( defined $defaultAttrs->{$attr}
            && defined $defaultAttrs->{$attr}->{default} );
    }

    return $attrs;
}

sub _hasAllowedAttributes {
    my ( $self, $attributes, $rootNode ) = @_;
    my @allowedAttributes = $self->_listAttributes($rootNode);

    foreach $attribute ( keys %{$attributes} ) {
        if ( length( ref($attribute) ) ) {
            return {
                res => "ko",
                msg => "Invalid input: Attribute $attribute is not a string."
            };
        }
        unless ( grep { $_ eq $attribute } @allowedAttributes ) {
            return {
                res => "ko",
                msg => "Invalid input: Attribute $attribute does not exist."
            };
        }
    }

    return { res => "ok" };
}

sub _listAttributes {
    my ( $self, $rootNode ) = @_;
    my $mainTree   = Lemonldap::NG::Manager::Build::CTrees::cTrees();
    my $rootNodes  = [ grep { ref($_) eq "HASH" } @{ $mainTree->{$rootNode} } ];
    my @attributes = map { $self->_listNodeAttributes($_) } @$rootNodes;

    return @attributes;
}

sub _listNodeAttributes {
    my ( $self, $node ) = @_;
    my @attributes =
      map { ref($_) eq "HASH" ? $self->_listNodeAttributes($_) : $_ }
      @{ $node->{nodes} };

    return @attributes;
}

sub _translateOptionApiToConf {
    my ( $self, $optionName, $prefix ) = @_;

    # For consistency
    $optionName =~ s/^clientId$/clientID/;

    return $prefix . "MetaDataOptions" . ( ucfirst $optionName );
}

sub _translateOptionConfToApi {
    my ( $self, $optionName ) = @_;
    $optionName =~ s/^(\w+)MetaDataOptions//;

    $optionName = lcfirst $optionName;

    # iDToken looks ugly
    $optionName =~ s/^iDToken/IDToken/;

    # For consistency
    $optionName =~ s/^clientID/clientId/;
    return $optionName;
}

sub _getRegexpFromPattern {
    my ( $self, $pattern ) = @_;
    return unless ( $pattern =~ /[\w\.\-\*]+/ );

    # . is allowed, and must be escaped
    $pattern =~ s/\./\\\./g;
    $pattern =~ s/\*/\.\*/g;

    # anchor string, unless * was provided
    $pattern = "^$pattern\$" if ( $pattern =~ /\*/ );

    return qr/$pattern/;
}

1;
