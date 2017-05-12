# Copyrights 2008-2014 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Geo::GML;
use vars '$VERSION';
$VERSION = '0.16';

use base 'XML::Compile::Cache';

use Geo::GML::Util;

use Log::Report 'geo-gml', syntax => 'SHORT';
use XML::Compile::Util  qw/unpack_type pack_type type_of_node/;

# map namespace always to the newest implementation of the protocol
my %ns2version =
  ( &NS_GML    => '3.1.1'
  , &NS_GML_32 => '3.2.1'
  );

# list all available versions
my %info =
  ( '2.0.0'   => { prefixes => {gml => NS_GML_200}
                 , schemas  => [ 'gml2.0.0/*.xsd' ] }
  , '2.1.1'   => { prefixes => {gml => NS_GML_211}
                 , schemas  => [ 'gml2.1.1/*.xsd' ] }
  , '2.1.2'   => { prefixes => {gml => NS_GML_212}
                 , schemas  => [ 'gml2.1.2/*.xsd' ] }
  , '2.1.2.0' => { prefixes => {gml => NS_GML_2120}
                 , schemas  => [ 'gml2.1.2.0/*.xsd' ] }
  , '2.1.2.1' => { prefixes => {gml => NS_GML_2121}
                 , schemas  => [ 'gml2.1.2.1/*.xsd' ] }
  , '3.0.0'   => { prefixes => {gml => NS_GML_300, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.0.0/*/*.xsd' ] }
  , '3.0.1'   => { prefixes => {gml => NS_GML_301, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.0.1/*/*.xsd' ] }
  , '3.1.0'   => { prefixes => {gml => NS_GML_310, smil => NS_SMIL_20}
                 , schemas  => [ 'gml3.1.0/*/*.xsd' ] }
  , '3.1.1'   => { prefixes => {gml => NS_GML_311, smil => NS_SMIL_20
                               ,gmlsf => NS_GML_311_SF}
                 , schemas  => [ 'gml3.1.1/{base,smil,xlink}/*.xsd'
                               , 'gml3.1.1/profile/*/*/*.xsd' ] }
  , '3.2.1'   => { prefixes => {gml => NS_GML_321, smil => NS_SMIL_20 }
                 , schemas  => [ 'gml3.2.1/*.xsd', 'gml3.1.1/smil/*.xsd' ] }
  );

# This list must be extended, but I do not know what people need.
my @declare_always =
    qw/gml:TopoSurface/;

# for Geo::EOP and other stripped-down GML versions
sub _register_gml_version($$) { $info{$_[1]} = $_[2] }


sub new($@)
{   my ($class, $dir) = (shift, shift);
    $class->SUPER::new(direction => $dir, @_);
}

sub init($)
{   my ($self, $args) = @_;
    $args->{allow_undeclared} = 1
        unless exists $args->{allow_undeclared};

    $args->{opts_rw} = { @{$args->{opts_rw}} }
        if ref $args->{opts_rw} eq 'ARRAY';
    $args->{opts_rw}{key_rewrite} = 'PREFIXED';
    $args->{opts_rw}{mixed_elements} = 'STRUCTURAL';

    $args->{any_element}         ||= 'ATTEMPT';

    $self->SUPER::init($args);

    $self->{GG_dir} = $args->{direction} or panic "no direction";

    my $version     =  $args->{version}
        or error __x"GML object requires an explicit version";

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"GML version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{GG_version} = $version;    
    my $info    = $info{$version};

    $self->addPrefixes(xlink => NS_XLINK_1999, %{$info->{prefixes}});

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds    = map {glob "$xsd/$_"}
        @{$info->{schemas} || []}, 'xlink1.0.0/*.xsd';

    $self->importDefinitions(\@xsds);
    $self;
}

sub declare(@)
{   my $self = shift;

    my $direction = $self->direction;

    $self->declare($direction, $_)
        for @_, @declare_always;

    $self;
}


sub from($@)
{   my ($class, $data, %args) = @_;
    my $xml = XML::Compile->dataToXML($data);

    my $top = type_of_node $xml;
    my $ns  = (unpack_type $top)[0];

    my $version = $ns2version{$ns}
        or error __x"unknown GML version with namespace {ns}", ns => $ns;

    my $self = $class->new('READER', version => $version);
    my $r   = $self->reader($top, %args)
        or error __x"root node `{top}' not recognized", top => $top;

    ($top, $r->($xml));
}

#---------------------------------


sub version()   {shift->{GG_version}}
sub direction() {shift->{GG_dir}}

#---------------------------------


# just added as example, implemented in super-class

#------------------


sub printIndex(@)
{   my $self = shift;
    my $fh   = @_ % 2 ? shift : select;
    $self->SUPER::printIndex($fh
      , kinds => 'element', list_abstract => 0, @_); 
}

our $AUTOLOAD;
sub AUTOLOAD(@)
{   my $self = shift;
    my $call = $AUTOLOAD;
    return if $call =~ m/::DESTROY$/;
    my ($pkg, $method) = $call =~ m/(.+)\:\:([^:]+)$/;
    $method eq 'GPtoGML'
        or error __x"method {name} not implemented", name => $call;
    eval "require Geo::GML::GeoPoint";
    panic $@ if $@;
    $self->$call(@_);
}

1;
