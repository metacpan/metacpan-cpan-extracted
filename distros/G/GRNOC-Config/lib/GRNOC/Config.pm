#--------------------------------------------------------------------
#----- Copyright(C) 2015 The Trustees of Indiana University
#--------------------------------------------------------------------
#----- a simple config module for use in all GRNOC programs with passwords
#-----
#---------------------------------------------------------------------

package GRNOC::Config;

use warnings;
use strict;

require Data::Dumper;
require XML::Simple;
require XML::XPath;
require XML::LibXML;

=head1 NAME

GRNOC::Config - The GRNOC Default Config parser

=head1 VERSION

Version 1.0.9

=cut

    our $VERSION = '1.0.9';


=head1 SYNOPSIS

A module to allow everyone to access config files in a fairly standard way.
Uses XML::XPath and XML::Simple to parse our XML files, and stores all configs it has access to in this module

Setting debug to true will give you extra debugging output (default is off)
Setting force_array to true will return everything in an array even if there is only 1 object returned (default is on)

When asking for attributes denoted by '@' it will return only the attribute(s) without the hash

    use GRNOC::Config;

    my $foo = GRNOC::Config->new(config_file => '/etc/grnoc/db.xml', debug => 0, force_array => 0 schema => '/path/to/schema.csd')
    my $db_username = $foo->get("/config/db/credentials");
    print $db_username->{'user'};
    print $db_username->{'password'};

    #just 1 attribute
    my $user = $foo->get("/config/db/credentials[1]/@user");
    my $password = $foo->get("/config/db/credentials[1]/@password");

    #if I have more than 1 result I get an array
    my $hosts = $foo->get("/config/hosts") or die Dumper($foo->get_error());   
    foreach my $host ($hosts){
	print $host->{'hostname'};
    }

    ##turn debugging on
    $foo->{'debug'} = 1;
    
    ##get errors
    print Dumper($foo->get_errors());

    # I always want an array... even if I only get 1 result
    $foo->{'force_array'} = 1;
    $db_username = $foo->get("/config/db/credentials") or die Dumper($foo->get_error());
    print @{db_username}[0]->{'user'}
    print @{db_username}[0]->{'password'}

   $user = $foo->get("/config/db/credentials[1]/@user") or die Dumper($foo->get_error());
   $password = $foo->get("/config/db/credentials[1]/@password") or die Dumper($foo->get_error());
   $user = @{$user}[0];
   $password = @{$password}[0];
 
   my $valid = $foo->validate();

   if(!$valid){
     print STDERR Dumper($foo->get_error());
   }

   my $valid2 = $foo->validate("/path/to/new/schema.xsd");

    ...

=cut

=head2 getOLD 

returns the requested data from the config file must pass in the path of the node/attribute you want
from the XML.  Attributes are denoted by '@'

to get an attribute the call would look like

    $foo->get("/path/to/@object");

=cut


sub getOLD{
    my $self = shift;
    my $path = shift;
    if($path eq ''){
	$self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
	return undef;
    }
    if(!defined($self->{'config'})){
	$self->{'error'}{'msg'} = "Config not loaded!!\n";
	return undef;
    }

    my $xp = $self->{'config'};
    
    my $exists;
    eval { $exists = $xp->exists($path); }; $self->{'error'}{'error'} = $@ if $@;
    
    if($exists){
	if($self->{'debug'}){
	    print STDERR $path . " exists!";
	}
	$self->{'error'} = {};

	my $nodeset;
	eval { $nodeset = $xp->find($path); }; $self->{'error'}{'error'} = $@ if $@;
	my @results;
	my @nodelist;
	eval { @nodelist= $nodeset->get_nodelist; }; $self->{'error'}{'error'} = $@ if $@;
	if($#nodelist <= 1 && !($self->{'force_array'})){
	    my $temp;
	    eval { $temp = XML::XPath::XMLParser::as_string($nodelist[0]); }; $self->{'error'}{'error'} = $@ if $@;
	    if($temp =~ /^<.*\/>$/){
		return XML::Simple::XMLin($temp,ForceArray => $self->{'force_array'});
	    }elsif($temp =~ /.*=\"(.*)\"/){
		return $1;
	    }else{
		return XML::Simple::XMLin($temp, ForceArray => $self->{'force_array'});
	    }
	}else{
	    foreach my $node (@nodelist){
		my $temp;
		eval { $temp = XML::XPath::XMLParser::as_string($node); }; $self->{'error'}{'error'} = $@ if $@;
		
		if($temp =~ /^<.*\/>$/){
		    push(@results,XML::Simple::XMLin($temp, ForceArray => $self->{'force_array'}));
		}elsif($temp =~ /.*=\"(.*)\"/){
		    push(@results,$1);
		}else{
		    push(@results,XML::Simple::XMLin($temp, ForceArray => $self->{'force_array'}));
		}
	    }
	    return \@results;
	}
    }else{
	$self->{'error'}{'msg'} = $path . " does not exist in the config";
	return undef;
    }
}

=head2 get2 

returns the requested data from the config file must pass in the path of the node/attribute you want
from the XML.  Attributes are denoted by '@'

to get an attribute the call would look like

    $foo->get2("/path/to/@object");

=cut


sub get2{
    my $self = shift;
    my $path = shift;
    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }
    #return "hello";
    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
           print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    ###ok ready to parse
    my $root=$self->{'doc'}->getDocumentElement();
    my $rvalue=$root->findvalue($path);
    if(defined $rvalue){
      $self->{'error'}{'msg'} = $path . " does not exist in the config";
      return $rvalue;
    }
    return undef ;
}


=head2 get

returns the requested data from the config file must pass in the path of the node/attribute you want
from the XML.  Attributes are denoted by '@'

to get an attribute the call would look like

    $foo->get3("/path/to/@object");

=cut


sub get{
    my $self = shift;
    my $path = shift;
    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
	    print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    ###ok ready to parse
    my $root=$self->{'doc'}->getDocumentElement();
    
    my @path_args = split('\/',$path);
    #looking for attributes?
    if($path_args[$#path_args] =~ /@/){
	my @nodes = $root->findnodes($path);

	my @tmp;
	if($#nodes >= 1 || $self->{'force_array'}){
	    #print STDERR "returning an array of values\n";
	    foreach my $node (@nodes){
		push(@tmp,$node->getValue());
	    }
	    return \@tmp;
	}else{
	    #print STDERR "returning a single value\n";
	    if(!defined($nodes[0])){
		return undef;
	    }
	    return $nodes[0]->getValue();
	}

	$self->{'error'}{'msg'} = "$path does not exist in the config";
	return undef;
    }else{
	#looking for nodes
	my @nodes = $root->findnodes( $path );
	my @tmp;
       
	if($#nodes >= 0){
	    if($#nodes >= 1 || $self->{'force_array'}){
		#print STDERR "Returning an array of nodes\n";
		foreach my $node (@nodes){
		    push(@tmp,XML::Simple::XMLin($node->toString(), ForceArray => $self->{'force_array'}));
		}
		#print STDERR Data::Dumper::Dumper(@tmp);
		if(defined($nodes[0])){
		    return \@tmp;
		}

	    }else{
		#print STDERR "Returning a single node\n";
		return XML::Simple::XMLin($nodes[0]->toString(),ForceArray => $self->{'force_array'});
		
	    }
	}
	$self->{'error'}{'msg'} = "$path does not exist in the config";
	return undef;
    }

    return undef ;
}


=head2 update_node

=cut

sub update_node{
    my $self = shift;
    my $path = shift;
    my $new_value = shift;


    if($path eq ''){
	$self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
            print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    $path .= "/text()";

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;

    if($nodes->size() == 1){
	$node = $nodes->pop();
    }else{
	$self->{'error'}{'msg'} = "Multiple Nodes at that Path please specify\n";
	return undef;
    }

    if(defined($new_value)){
	$node->setData($new_value);
    }

    my $res = _save_xml($self);
    return $res;
}

=head2 add_node


=cut

sub add_node{
    my $self = shift;
    my $path = shift;
    my $node_name = shift;
    my $node_value = shift;

    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
	    print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;

    if($nodes->size() == 1){
        $node = $nodes->pop();
    }else{
        $self->{'error'}{'msg'} = "Multiple Nodes at that Path please specify\n";
        return undef;
    }

    my $new_node = $self->{'doc'}->createElement($node_name);
    if(defined($node_value)){
	$new_node->appendText($node_value);
    }

    $node->appendChild($new_node);

    my $res = _save_xml($self);
    return $res;
}

=head2 delete_nodes

=cut

sub delete_nodes{
    my $self = shift;
    my $path = shift;

    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
	return undef;
    }

    if(!defined($self->{'doc'})){
	$self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
            print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;
    
    while(my $node = $nodes->pop()){
	my $parent = $node->parentNode;
	$parent->removeChild($node);
    }

    return _save_xml($self);
}




=head2 delete_node

=cut

sub delete_node{
    my $self = shift;
    my $path = shift;

    if($path eq ''){
	$self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
            print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;

    if($nodes->size() == 1){
        $node = $nodes->pop();
    }else{
        print STDERR "Multiple Nodes at that path\n";
        $self->{'error'}{'msg'} = "Multiple Nodes at that Path please specify\n";
        return undef;
    }

    my $parent = $node->parentNode;
    $parent->removeChild($node);

    return _save_xml($self);

}

=head2 update_attribute

=cut

sub update_attribute{
    my $self = shift;
    my $path = shift;
    my $attribute_name = shift;
    my $attribute_value = shift;

    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if($attribute_name eq ''){
	$self->{'error'}{'msg'} = "Attribute not specified.  Please specify an attribute\n";
	return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
            print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;

    if($nodes->size() == 1){
        $node = $nodes->pop();
    }else{
        $self->{'error'}{'msg'} = "Multiple Nodes at that Path please specify\n";
        return undef;
    }


    if(defined($node->getAttribute($attribute_name))){
	$node->setAttribute($attribute_name,$attribute_value);
    }else{
	$self->{'error'}{'msg'} = "That attribute is not defined, add the attribute before trying to update\n";
	return undef;
    }

    _save_xml($self);
}

=head2 add_attribute

=cut

sub add_attribute{
    my $self = shift;
    my $path = shift;
    my $attribute_name = shift;
    my $attribute_value = shift;
    
    if($path eq ''){
        $self->{'error'}{'msg'} = "Path not specified.  Please specify a path\n";
        return undef;
    }

    if($attribute_name eq ''){
        $self->{'error'}{'msg'} = "Attribute not specified.  Please specify an attribute\n";
        return undef;
    }

    if(!defined($self->{'doc'})){
        $self->{'error'}{'msg'} = "Config not loaded!!\n";
        if($self->{'debug'}){
            print STDERR "cannot find doc!\n";
        }
        return undef;
    }

    my $root = $self->{'doc'}->getDocumentElement();
    my $nodes = $root->find($path);
    my $node;

    if($nodes->size() == 1){
        $node = $nodes->pop();
    }else{
        $self->{'error'}{'msg'} = "Multiple Nodes at that Path please specify\n";
        return undef;
    }

    if(defined($node->getAttribute($attribute_name))){
	$self->{'error'}{'msg'} = "That attribute is already defined, try updating instead of adding again\n";
	return undef;
    }else{
	$node->setAttribute($attribute_name,$attribute_value);
    }

    _save_xml($self);

}


sub _save_xml{
    my $self = shift;
    
    if($self->{'debug'}){
	print STDERR "Writing file " . $self->{'config_file'} . "\n";
    }

    open my $CONFIG, "> " . $self->{'config_file'};
    binmode $CONFIG;
    print $CONFIG $self->{'doc'}->toString();
    close $CONFIG;
    return 1;
}

=head2 validate

    my $valid = $config->validate();

    or 
  
    my $valid = $config->validate("/path/to/schema.xsd");

    returns 1 if xml validates
    returns 0 if it fails to valiate
    returns -1 if there is a problem with your schema

=cut

sub validate{
    my $self = shift;
    my $new_schema = shift;

    #did the user pass in a new schema file?
    if(defined($new_schema)){
	$self->{'schema_file'} = $new_schema;
	_load_schema($self);
    }

    if($self->{'debug'}){
	print STDERR "Validating document with schema\n";
    }

    if(defined($new_schema)){
	
    }

    if(defined($self->{'schema'}) && $self->{'schema'} ne ''){
	my $valid = -1;
	
	eval{ $valid =  $self->{'schema'}->validate($self->{'doc'}) };
	
	if($@){
	    $self->{'error'}{'backtrace'} = $@;
	    $self->{'error'}{'msg'} = "File failed to validate\n";
	}
	
	if($valid == 0){
	    return 1;
	}else{
	    return 0;
	    }
    }else{
	if($self->{'debug'}){
	    warn "No schema to validate against\n";
	}
	return -1;
    }

}

sub _load_schema{
    my $self = shift;
    
    my $schema;
    

    if($self->{'debug'}){
	warn "Loading schema file " . $self->{'schema_file'} . "\n";
    }

    eval{ $schema = XML::LibXML::Schema->new( location => $self->{'schema_file'}) };

    if($@){
	if($self->{'debug'}){
	    warn "Unable to load Schema!\n";
	    warn Data::Dumper::Dumper($@);
	    warn Data::Dumper::Dumper($schema);
	}

	$self->{'error'}{'msg'} = "Unable to load Schema\n";
	$self->{'error'}{'backtrace'} = $@;
    }

    if(defined($schema)){
	warn "Successfully Loaded Schema\n";
	$self->{'schema'} = $schema;
	return 1;
    }else{
	$self->{'schema'} = undef;
	return 0;
    }
}

=head2 get_error

returns any error that is generated from this module

=cut


sub get_error{
    my $self = shift;		
    return $self->{'error'};
}

sub _read_config{
    my $self = shift;
    my $ref;
    my $config = $self->{'config_file'};
    ##first check for config file exist 
    if($config ne '' && -e $config){
	eval { $ref = XML::XPath->new(filename => $config); }; $self->{'error'}{'error'} = $@ if $@; 
	if(!defined($ref)){
	    $self->{'error'}{'msg'} = "XPath was unable to parse config file";
	    $self->{'error'}{'backtrace'} = $self;
	    return undef;
	}
    }else{

	if($config eq ''){
	    $self->{'error'}{'msg'} = "No File to parse!! ";
	    $self->{'error'}{'backtrace'} = $self;
	}else{
	    $self->{'error'}{'msg'} = "File does not exist!! ";
	    $self->{'error'}{'backtrace'} = $self;
	}

	return undef;
    }
    return $ref;
}

sub _read_config2{
    my $self = shift;
    my $ref;
    my $config_filename = $self->{'config_file'};
    my $parser= XML::LibXML->new() ;
    my $doc;
    if(defined($self->{'xml_string'})){
	eval{$doc = $parser->parse_string( $self->{'xml_string'});}; $self->{'error'}{'error'} = $@ if $@;
	if(!defined($doc)){
	    $self->{'error'}{'msg'} = "LibXML was unable to prase string";
	    $self->{'error'}{'backtrace'} = $self;
	}else{
	    return $doc;
	}

    }

    if (not (defined $config_filename && (-e $config_filename) )){
        if($config_filename eq ''){
            $self->{'error'}{'msg'} = "No File to parse!! ";
            $self->{'error'}{'backtrace'} = $self;
        }else{
            $self->{'error'}{'msg'} = "File does not exist!! ";
            $self->{'error'}{'backtrace'} = $self;
        }
        return undef;
    }
    
    eval {$doc=$parser->parse_file($config_filename); }; $self->{'error'}{'error'} = $@ if $@;
    if(!defined($doc)){
	$self->{'error'}{'msg'} = "LibXML was unable to parse config file";
	$self->{'error'}{'backtrace'} = $self;
	return undef;
    }    
    
    #this is the successfull exit;
    return $doc;
   
}



=head2 new 
  Creates a new GRNOC::Config object

    my $config = GRNOC::Config->new(config_file => $file, force_array => 0, debug => 0);

    or

    my $config = GRNOC::Config->new( xml_string => $string);

=cut


sub new {
 
    my $that = shift;
    my $class = ref($that) || $that;
    my %args = (@_);
    my $self = \%args;
    if(!(defined($self->{'debug'}))){
	$self->{'debug'} = 0;
    }
  
    if(!(defined($self->{'force_array'}))){
	$self->{'force_array'} = 1;
    }

    $self->{'doc'}    = _read_config2($self);
    if(!defined ($self->{'doc'}) ){
	$self->{'error'}{'msg'} .= "Unable to initialize config";
    }
    
    
    if(defined($self->{'schema'})){
	$self->{'schema_file'} = $self->{'schema'};
	_load_schema($self);
    }

    bless ($self,$class);
    return $self;
}

1;
