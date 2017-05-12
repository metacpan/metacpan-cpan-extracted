# Copyrights 2008-2015 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.01.
use warnings;
use strict;

package Geo::EOP;
use vars '$VERSION';
$VERSION = '0.50';

use base 'Geo::GML';

use Geo::EOP::Util;   # all
use Geo::GML::Util  qw/:gml311/;

use Log::Report 'geo-eop', syntax => 'SHORT';
use XML::Compile::Util  qw/unpack_type pack_type type_of_node/;
use Math::Trig          qw/rad2deg deg2rad/;

# map namespace always to the newest implementation of the protocol
my %ns2version =
  ( &NS_HMA_ESA => '1.0'
  , &NS_EOP_ESA => '1.2.1'
  );

# list all available versions
# It is a pity that not all schema use the same prefixes... sometimes,
# the dafault prefix is used... therefore, we have to configure all that
# manually.

my @stdprefs =   # will be different in the future
 ( sar => NS_SAR_ESA
 , atm => NS_ATM_ESA
 , gml => NS_GML_311
 );

my %info =
  ( '1.0'     =>
      { prefixes    => {hma => NS_HMA_ESA, ohr => NS_OHR_ESA, @stdprefs}
      , eop_schemas => [ 'hma1.0/{eop,sar,opt,atm}.xsd' ]
      , gml_schemas => [ 'eop1.1/gmlSubset.xsd' ]
      , gml_version => '3.1.1eop'
      }

  , '1.1'     =>
      { prefixes    => {eop => NS_EOP_ESA, opt => NS_OPT_ESA, @stdprefs}
      , eop_schemas => [ 'eop1.1/{eop,sar,opt,atm}.xsd' ]
      , gml_schemas => [ 'eop1.1/gmlSubset.xsd' ]
      , gml_version => '3.1.1eop'
      }

  , '1.2beta' =>
      { prefixes    => {eop => NS_EOP_ESA, opt => NS_OPT_ESA, @stdprefs}
      , eop_schemas => [ 'eop1.2beta/{eop,sar,opt,atm}.xsd' ]
      , gml_schemas => [ 'eop1.1/gmlSubset.xsd' ]
      , gml_version => '3.1.1eop'
      }

  , '1.2.1' =>
      { prefixes    => {eop => NS_EOP_ESA, opt => NS_OPT_ESA, @stdprefs}
      , eop_schemas => [ 'eop1.2.1/{eop,sar,opt,atm}.xsd' ]
      , gml_schemas => [ 'eop1.2.1/gmlSubset.xsd' ]
      , gml_version => '3.1.1eop'
      }

# , '2.0' =>
#     { eop_schemas => [ 'eop2.0/*.xsd' ]
#     , gml_version => '3.2.1'
#     }

  );

my %measure =
  ( rad_deg   => sub { rad2deg $_[0] }
  , deg_rad   => sub { deg2rad $_[0] }
  , '%_float' => sub { $_[0] / 100 }
  , 'float_%' => sub { sprintf "%.2f", $_[0] / 100 }
  );
sub _convert_measure($@);

# This list must be extended, but I do not know what people need.
my @declare_always = ();


sub new($@) { my $class = shift; $class->SUPER::new('RW', @_) }

sub init($)
{   my ($self, $args) = @_;
    $args->{allow_undeclared} = 1
        unless exists $args->{allow_undeclared};

    my $version  =  $args->{eop_version}
        or error __x"EOP object requires an explicit eop_version";

    unless(exists $info{$version})
    {   exists $ns2version{$version}
            or error __x"EOP version {v} not recognized", v => $version;
        $version = $ns2version{$version};
    }
    $self->{GE_version} = $version;    
    my $info            = $info{$version};

    $args->{version}    = $info->{gml_version};
    if($info->{gml_schemas})  # using own GML 3.1.1 subset
    {   $self->_register_gml_version($info->{gml_version} => {});
    }

    $self->SUPER::init($args);

    $self->addPrefixes($info->{prefixes});

    (my $xsd = __FILE__) =~ s!\.pm!/xsd!;
    my @xsds    = map {glob "$xsd/$_"}
       @{$info->{eop_schemas} || []}, @{$info->{gml_schemas} || []};

    $self->importDefinitions(\@xsds);

    my $units = delete $args->{units};
    if($units)
    {   if(my $a = $units->{angle})
        {   $self->addHook(type => 'gml:AngleType'
              , after => sub { _convert_measure $a, @_} );
        }
        if(my $d = $units->{distance})
        {   $self->addHook(type => 'gml:MeasureType'
              , after => sub { _convert_measure $d, @_} );
        }
        if(my $p = $units->{percentage})
        {   $self->addHook(path => qr/Percentage/
              , after => sub { _convert_measure $p, @_} );
        }
    }

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
{   my ($thing, $data, %args) = @_;
    my $xml = XML::Compile->dataToXML($data);

    my $product = type_of_node $xml;
    my $version = $xml->getAttribute('version');
    defined $version
        or error __x"no version attribute in root element";

    my $self;
    if(ref $thing)   # instance method
    {   $self = $thing;
    }
    else             # class method
    {   exists $info{$version}
            or error __x"EOP version {version} not (yet) supported.  Upgrade Geo::EOP or inform author"
                , version => $version;

        $self    = $thing->new(eop_version => $version);
    }

    my $r       = $self->reader($product, %args);
    defined $r
        or error __x"do not understand root node {type}", type => $product;

    ($product, $r->($xml));
}

#---------------------------------


sub eopVersion() {shift->{GE_version}}

#--------------


sub printIndex(@)
{   my $self = shift;
    my $fh   = @_ % 2 ? shift : select;
    $self->SUPER::printIndex($fh
      , kinds => 'element', list_abstract => 0, @_); 
}

# This code will probaby move to Geo::GML
sub _convert_measure($@)   # not $$$$ for right context
{   my ($to, $node, $data, $path) = @_;
    ref $data eq 'HASH'  or return $data;
    my ($val, $from) = @$data{'_', 'uom'};
    defined $val && $from or return $data;

    return $val if $from eq $to;
    my $code = $measure{$from.'_'.$to} or return $data;
    $code->($val);
}

#----------------------


1;
