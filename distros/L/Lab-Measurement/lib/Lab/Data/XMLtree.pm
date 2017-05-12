#wird wohl auf die selbe architektur wie
#bei den ganzen rekursiven functionen
#rauslaufen.
#diese werden dann die methoden der
#unteren Lab::XMLtrees bemühen, anstatt sich
#selbst.

#allerdings bietet objektorientierter ansatz auch nachteile
#  ___declaration wird redundant gespeichert
# was passiert bei manueller erzeugung ungeblesster teile?
# und bei erzeugung aus xml/yaml?

#neue anmerkungen:
#
#___declaration gibt es dann gar nicht mehr
#deklararieren=datenstruktur aufbauen => deklaration steckt in datenstruktur selbst
#
#manuelle erzeugung kann man wohl durch overloading der zuweisung zwangsweise blessen (durch mergen)
#(geht wohl doch nicht)
#
#xml und yaml einlesen erzeugen ungeblesste trees, die dann gemerget werden
##anmerkung 040901: overloading geht wohl nicht.
##neue daten müssen mit merge eingefügt werden.
##man kann aber z.b. auch regelmässig die datenstruktur durchbrowsen und
##checken, ob alles geblessed ist

##mit tie gehts.

##es gibt zwei Klassen, LIST und NODE
##LIST ist ein HASHREF mit nodename=>NODE
##
##NODE ist entweder skalarer Wert
##oder hashref oder arrayref, geblessed als LISTNODE, HASHNODE
##(LIST1,LIST2) oder (key1=>LIST1,key2=>LIST2)
##key(-namen) speichern sie dann wohl am besten ...
##
##NODE und LIST jeweils als TIE::etc.
##vielleicht sollte man LISTNODE intern auch als hash machen
##damit es richtig verwirrend wird

package Lab::Data::XMLtree;
our $VERSION = '3.542';

use strict;
use warnings;
use encoding::warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

use XML::DOM;
use XML::Generator ();
use Data::Dumper;
use XML::Twig;
use Encode;
use vars qw($VERSION);

our $AUTOLOAD;

our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT      = qw();

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $definition = shift;

    my $self = {};
    if ( ( ref $_[0] ) =~ /HASH/ ) {
        $self = shift;
    }
    $self->{___declaration} = $definition;
    bless( $self, $class );
    return $self;
}

sub read_xml {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $def   = shift;
    if ( my $xml_filename = shift ) {
        if ( my $perlnode_list = _load_xml( $def, $xml_filename ) ) {

            #print Dumper($perlnode_list);
            return $class->new( $def, $perlnode_list );
        }
        warn
            "I'm having difficulties reading the file $xml_filename! Please help!\n";
    }
    warn "No file read!\n";
    return undef;
}

sub read_yaml {
    my $proto    = shift;
    my $class    = ref($proto) || $proto;
    my $def      = shift;
    my $filename = shift;
    use YAML ();
    if ( my $perlnode_list = YAML::LoadFile($filename) ) {
        return $class->new( $def, $perlnode_list );
    }
    return undef;
}

#--------------------------------------#

#methods
sub merge_tree {
    my $self       = shift;
    my $merge_tree = shift;
    _merge_node_lists( $self->{___declaration}, $self, $merge_tree );
}

sub save_xml {
    my $self     = shift;
    my $filename = shift;
    my $data     = shift;

    #warum nicht $self?????
    my $rootname  = shift;
    my $generator = XML::Generator->new(
        pretty      => 0,
        escape      => 'high-bit',
        conformance => 'strict'
    );
    my $t = XML::Twig->new(
        pretty_print  => 'indented',
        keep_encoding => 1,
    );

    $t->parse(
        join "",
        $generator->xmldecl( encoding => 'ISO-8859-1' ),
        $generator->$rootname(
            @{
                _write_node_list(
                    $generator, $self->{___declaration}, $data
                )
            }
        ),
    );
    $t->print_to_file($filename);
}

sub save_yaml {
    my $self     = shift;
    my $filename = shift;
    my $data     = shift;
    my $rootname = shift;
    my $save_hash;    #pseudo-geprüftes save
    for my $defnode_name ( keys %{ $self->{___declaration} } ) {
        $save_hash->{$defnode_name} = $data->{$defnode_name}
            if ( $data->{$defnode_name} );
    }
    use YAML ();
    YAML::StoreFile( $filename, $save_hash );
}

sub to_string {
    Dumper(@_);
}

sub AUTOLOAD {
    my $self  = shift;
    my @parms = @_;
    my $type  = ref($self) or croak "$self is not an object";
    my $name  = $AUTOLOAD;
    $name =~ s/.*://;
    return _getset_node_list_from_string(
        $self, $self->{___declaration},
        $name, @parms
    );
}

sub DESTROY {
}

#--------------------------------------#

#private utility functions
#for read_xml
sub _load_xml {
    my $definition = shift;
    my $filename   = shift;
    my $parser     = new XML::DOM::Parser;
    my $doc;
    if ( eval { $doc = $parser->parsefile($filename); } ) {
        return _parse_domnode_list(
            [ $doc->getDocumentElement()->getChildNodes() ], $definition );
    }
    else {
        warn "Parsing $filename failed!";
        return undef;
    }
}

#recursive ones
#for merge
sub _merge_node_lists {
    my $defnode_list              = shift;    #    hashref, declaration-type
    my $destination_perlnode_list = shift;
    my $source_perlnode_list      = shift;
    for my $node_name ( keys %$defnode_list ) {
        if ( defined $source_perlnode_list->{$node_name} ) {
            my ( $type, $key_name, $children_defnode_list )
                = _get_defnode_type( $defnode_list->{$node_name} );

            # browse all elements of this $node_name (multiple if type is array or hash)
            # if they have children, merge children's content as well
            for my $key_val (
                _magic_keys(
                    $defnode_list, $source_perlnode_list, $node_name
                )
                ) {
                if ($children_defnode_list) {
                    my $dp;

                    #create destination node if necessary
                    unless (
                        $dp = _magic_get_perlnode(
                            $defnode_list, $destination_perlnode_list,
                            $node_name,    $key_val
                        )
                        ) {
                        $dp = {};
                        _magic_set_perlnode(
                            $defnode_list,
                            $destination_perlnode_list, $node_name, $key_val,
                            $dp
                        );
                    }
                    _merge_node_lists(
                        $children_defnode_list,
                        $dp,
                        _magic_get_perlnode(
                            $defnode_list, $source_perlnode_list,
                            $node_name,    $key_val
                        )
                    );
                }
                else {
                    _magic_set_perlnode(
                        $defnode_list,
                        $destination_perlnode_list,
                        $node_name,
                        $key_val,
                        _magic_get_perlnode(
                            $defnode_list, $source_perlnode_list,
                            $node_name,    $key_val
                        )
                    );
                }
            }
        }
    }
}

#for load xml
sub _parse_domnode_list {
    my $domnode_list = shift;    #listref
    my $defnode_list = shift;    #hashref

    my $r;

    #for all included dom elements
    my %auto_numbering;
    for my $domnode (@$domnode_list) {

        #for all allowed subnodes of given data element
        for my $node_name ( keys %$defnode_list ) {

            #names match? => allowed
            if (   ( $domnode->getNodeType() == ELEMENT_NODE )
                && ( $domnode->getNodeName() eq $node_name ) ) {

                #find child's attributes
                my ( $type, $key, $children_defnode_list )
                    = _get_defnode_type( $defnode_list->{$node_name} );
                my $key_val;
                if ( defined $key ) {
                    $key_val = $domnode->getAttribute($key);
                }
                unless ( ( defined $key_val ) && ( $key_val ne "" ) ) {
                    if ( defined $auto_numbering{$node_name} ) {
                        $key_val = $auto_numbering{$node_name};
                        $auto_numbering{$node_name}++;
                    }
                    else {
                        $key_val = 0;
                        $auto_numbering{$node_name} = 1;
                    }
                }

                #get content for child
                my $rr;
                if ($children_defnode_list) {
                    $rr = _parse_domnode_list(
                        \@{ $domnode->getChildNodes() },
                        $children_defnode_list
                    );
                }
                else {
                    my ($text_node) = $domnode->getChildNodes();
                    if (   ( defined $text_node )
                        && ( $text_node->getNodeType() == TEXT_NODE ) ) {
                        $rr = encode( "iso-8859-1", $text_node->getData() );
                    }
                }
                for ($type) {
                    if    (/SCALAR/) { $r->{$node_name}             = $rr }
                    elsif (/HASH/)   { $r->{$node_name}->{$key_val} = $rr }
                    elsif (/ARRAY/)  { $r->{$node_name}->[$key_val] = $rr }
                }
            }
        }
    }
    return $r;
}

#for save xml
sub _write_node_list {
    my $generator     = shift;
    my $defnode_list  = shift;    #    hashref, declaration-type
    my $perlnode_list = shift;
    my $xmlnode_list;
    for my $node_name ( keys %$defnode_list ) {
        if ( defined $perlnode_list->{$node_name} ) {
            my ( $type, $key_name, $children_defnode_list )
                = _get_defnode_type( $defnode_list->{$node_name} );
            for my $key_val (
                _magic_keys( $defnode_list, $perlnode_list, $node_name ) ) {
                my $perlnode_content;
                if ($children_defnode_list) {
                    $perlnode_content = _write_node_list(
                        $generator,
                        $children_defnode_list,
                        _magic_get_perlnode(
                            $defnode_list, $perlnode_list,
                            $node_name,    $key_val
                        )
                    );
                }
                else {
                    push(
                        @$perlnode_content,
                        $generator->xmlcdata(
                            _magic_get_perlnode(
                                $defnode_list, $perlnode_list,
                                $node_name,    $key_val
                            )
                        )
                    );
                }

                #print "\n\nHier: ",Dumper($perlnode_content);
                push(
                    @$xmlnode_list,
                    $generator->$node_name(
                          ( defined $key_name )
                        ? { $key_name => $key_val }
                        : {},
                        @$perlnode_content
                    )
                );
            }
        }
    }
    return $xmlnode_list;
}

#for autoloader
sub _getset_node_list_from_string {
    my $perlnode_list       = shift;
    my $defnode_list        = shift;
    my $nodes_string        = shift;
    my $nodes_string_backup = $nodes_string;
    if ( !defined($nodes_string) || $nodes_string eq "" ) {
        Lab::Exception::CorruptParameter->throw( error =>
                "Missing parameter in XMLtree::_getset_node_list_from_string(): 'nodes_string'\n"
        );
    }

    my @parms = @_;

    #browse through all defined notes at the current root of the defnode_list
    for my $node_name ( keys %$defnode_list ) {
        if ( $nodes_string =~ /^$node_name/ ) {

            #is the right node
            $nodes_string =~ s/^$node_name\_?//;
            my ( $type, $key, $children )
                = _get_defnode_type( $defnode_list->{$node_name} );
            if ( $nodes_string gt "" ) {

                #user wants deeper node
                my $key_val;
                if ( ( $type =~ /P?ARRAY/ ) || ( $type =~ /P?HASH/ ) ) {
                    $key_val = shift @parms;    # key must be given!
                }
                return ( defined $children )
                    ? _getset_node_list_from_string(
                    _magic_get_perlnode(
                        $defnode_list, $perlnode_list,
                        $node_name,    $key_val,
                        'P?SCALAR',    'P?ARRAY',
                        'P?HASH'
                    ),
                    $children,
                    $nodes_string,
                    @parms
                    )
                    : undef;
            }
            else {
                #wants to get/set this node
                #sollte bei ref(rückgabewert) !~ /SCALAR/ vielleicht eher eine liste von keys zurückgeben (hash) oder anzahl (array)
                if (@parms) {
                    my $param = shift @parms;
                    if ( ( ref $param ) =~ /HASH/ ) {
                        if ( $type =~ /P?HASH/ ) {

                            #set mit hashref
                            #setzt einen ganzen tree, z.b. alle achsen
                            return %{ $perlnode_list->{$node_name} }
                                = %$param;
                        }
                    }
                    elsif ( ( ref $param ) =~ /ARRAY/ ) {
                        if ( $type =~ /P?ARRAY/ ) {

                            #set mit arrayref
                            #z.b. alle blöcke
                            return @{ $perlnode_list->{$node_name} }
                                = @$param;
                        }
                    }
                    elsif ( !( ref $param ) ) {

                        #skalarer parameter
                        if ( $type =~ /P?HASH/ ) {

                            #parameter muss key sein
                            #es geht jetzt also um ein konkretes element
                            if (@parms) {

                                #set
                                my $nextparam;
                                if ( defined $children ) {
                                    if ( ( ref $nextparam ) =~ /HASH/ ) {

                                        #alle children auf einmal setzen
                                        return
                                            %{ $perlnode_list->{$node_name}
                                                ->{$param} } = %$nextparam;
                                    }
                                }
                                else {
                                    if ( !( ref $param ) ) {

                                        #skalaren wert für element ohne children setzen
                                        return $perlnode_list->{$node_name}
                                            ->{$param} = $nextparam;
                                    }
                                }
                            }
                            else {
                                #get
                                if (
                                    defined(
                                        $perlnode_list->{$node_name}->{$param}
                                    )
                                    ) {
                                    return $perlnode_list->{$node_name}
                                        ->{$param};
                                }
                                else {
                                    warn
                                        "Attempt to access non-existing element $node_name(\"$param\")\n";
                                    return undef;
                                }
                            }
                        }
                        elsif ( $type =~ /P?ARRAY/ ) {

                            #parameter muss index sein
                            #es geht jetzt also um ein konkretes element
                            if (@parms) {

                                #set
                                my $nextparam;
                                if ( defined $children ) {
                                    if ( ( ref $nextparam ) =~ /HASH/ ) {

                                        #alle children auf einmal setzen
                                        return
                                            %{ $perlnode_list->{$node_name}
                                                ->[$param] } = %$nextparam;
                                    }
                                }
                                else {
                                    if ( !( ref $param ) ) {

                                        #skalaren wert für element ohne children setzen
                                        return $perlnode_list->{$node_name}
                                            ->[$param] = $nextparam;
                                    }
                                }
                            }
                            else {
                                #get
                                return $perlnode_list->{$node_name}->[$param];
                            }
                        }
                        elsif ( $type =~ /P?SCALAR/ ) {

                            #simple set
                            #anymore parameters ignored (same above)
                            return $perlnode_list->{$node_name} = $param;
                        }
                    }
                }
                else {
                    #simple get (context sensitive)
                    return $perlnode_list->{$node_name} unless wantarray;
                    if ( $type =~ /P?ARRAY/ ) {
                        return @{ $perlnode_list->{$node_name} };
                    }
                    elsif ( $type =~ /P?HASH/ ) {
                        return %{ $perlnode_list->{$node_name} };
                    }
                    return $perlnode_list->{$node_name};
                }
            }
        }
    }
    carp(
        "XMLtree warning: attempt to access undeclared element '$nodes_string_backup'"
    );
}

#--------------------------------------#

#other private utility functions
sub _get_defnode_type {
    my $node = shift;
    my $type = $node->[0];
    my ( $key, $children );
    my $key_val;
    if ( defined $node->[1] ) {    #use very strict;
        if ( ( ref $node->[1] ) eq 'HASH' ) {
            $children = $node->[1];
        }
        else {
            $key = $node->[1];
            if ( defined $node->[2] ) {
                if ( ( ref $node->[2] ) eq 'HASH' ) {
                    $children = $node->[2];
                }
            }
        }
    }
    return ( $type, $key, $children );
}

sub _magic_keys {
    my $defnode_list  = shift;
    my $perlnode_list = shift;
    my $node_name     = shift;
    my $stype         = (@_) ? shift : 'SCALAR';
    my $atype         = (@_) ? shift : 'ARRAY';
    my $htype         = (@_) ? shift : 'HASH';
    my ( $type, $key_name, $children_defnode_list )
        = _get_defnode_type( $defnode_list->{$node_name} );
    return
          ( $type =~ /$stype/ ) ? ('SCALAR')
        : ( $type =~ /$atype/ )
        ? ( 0 .. ( -1 + @{ $perlnode_list->{$node_name} } ) )
        : ( $type =~ /$htype/ )
        ? ( sort keys %{ $perlnode_list->{$node_name} } )
        : undef;
}

sub _magic_get_perlnode {
    my $defnode_list  = shift;
    my $perlnode_list = shift;
    my $node_name     = shift;
    my $key           = shift;
    my $stype         = (@_) ? shift : 'SCALAR';
    my $atype         = (@_) ? shift : 'ARRAY';
    my $htype         = (@_) ? shift : 'HASH';

    my ( $type, $key_name, $children_defnode_list )
        = _get_defnode_type( $defnode_list->{$node_name} );

    if ( $type =~ $stype ) {
        $perlnode_list->{$node_name} = undef
            unless defined( $perlnode_list->{$node_name} );
    }
    elsif ( $type =~ $htype ) {
        $perlnode_list->{$node_name}->{$key} = {}
            unless defined( $perlnode_list->{$node_name}->{$key} );
    }
    elsif ( $type =~ $atype ) {
        $perlnode_list->{$node_name}->[$key] = {}
            unless defined( $perlnode_list->{$node_name}->[$key] );
    }

    return
          ( $type =~ $stype ) ? $perlnode_list->{$node_name}
        : ( $type =~ $htype ) ? $perlnode_list->{$node_name}->{$key}
        : ( $type =~ $atype ) ? $perlnode_list->{$node_name}->[$key]
        :                       undef;
}

sub _magic_set_perlnode {
    my $defnode_list  = shift;
    my $perlnode_list = shift;
    my $node_name     = shift;
    my $key           = shift;
    my $val           = shift;
    my $stype         = (@_) ? shift : 'SCALAR';
    my $atype         = (@_) ? shift : 'ARRAY';
    my $htype         = (@_) ? shift : 'HASH';
    my ( $type, $key_name, $children_defnode_list )
        = _get_defnode_type( $defnode_list->{$node_name} );

    if ( $type =~ /$stype/ ) {
        $perlnode_list->{$node_name} = $val;
    }
    elsif ( $type =~ /$htype/ ) {
        $perlnode_list->{$node_name}->{$key} = $val;
    }
    elsif ( $type =~ /$atype/ ) {
        $perlnode_list->{$node_name}->[$key] = $val;
    }
}

1;

__END__

=encoding utf8

=head1 NAME

Lab::Data::XMLtree - Handle and store XML and perl data structures with precise declaration.

=head1 SYNOPSIS

    use Lab::Data::XMLtree;
    
    my $data_declaration = {
        info                     => [#              type B
            'SCALAR',
            {
                basename    => ['PSCALAR'],#        type A
                title       => ['SCALAR'],#         type A
                place       => ['SCALAR']#          type A
            }
        ],
        column                  => [#               type K
            'ARRAY',
            'id',
            {
                # PSCALAR means that this element will not
                # be saved. Does not work for YAML yet.
                min         => ['PSCALAR'],#        type A
                max         => ['PSCALAR'],#        type A
                description => ['SCALAR']#          type A
            }
        ],
        axis                    => [#               type F
            'HASH',
            'label',
            {
                unit        => ['SCALAR'],#         type A
                logscale    => ['SCALAR'],#         type A
                description => ['SCALAR']#          type A
            }
        ]
    };
    #create Lab::Data::XMLtree object from file
    $data=Lab::Data::XMLtree->read_xml($data_declaration,'filename.xml');

    #the autoloader
    # get
    print $data->info_title;
    # get with $id
    print $data->column_description($id);
    # set with $key and $value
    $data->axis_description($label,'descriptiontext');
   
    #save data as YAML
    $data->save_yaml('filename.yaml');

=head1 DESCRIPTION

C<Lab::Data::XMLtree> will take you to similar spots as XML::Simple does, but in a
bigger bus and with fewer wild animals.

That's not a bad thing. You get more control of the data
transformation processes and you get some extra functionality.

=head1 DATA DECLARATION

Lab::Data::XMLtree uses a data declaration, that describes, what the
perl data structure looks like, and how this data structure
is converted to XML.

=head1 CONSTRUCTORS

=head2 new($declaration,[$data])

Create a new Lab::Data::XMLtree. $data must be hashref and should match the declaration. Returns Lab::XMLtree object.

The first two elements define the folding behaviour.

=over

=item SCALAR|PSCALAR

Element occurs zero or one time. No folding necessary.

Examples:

    $data->{dataset_title}='content';

=item ARRAY|PARRAY

Element occurs zero or more times. Folding will be done using an array reference. If $id is given, this XML element will be used as an id.

Example:

    $data->{column}->[4]->{label}='testlabel';

=item HASH|PHASH

Element occurs zero or more times. Folding will be done using a hash reference. If $key is given, this XML element will be used as a key.

Example:

    $data->{axis}->{gate voltage}->{unit}="mV";

=back

=head2 read_xml($declaration,$filename)

Opens a XML file $filename. Returns Lab::Data::XMLtree object.

=head2 read_yaml($declaration,$filename)

Opens a YAML file $filename. Returns Lab::Data::XMLtree object.

=head1 METHODS

=head2 merge_tree($tree)

Merge another Lab::Data::XMLtree into this one. Other tree must not necessarily be blessed.

=head2 save_xml($filename)

Saves the tree as XML to $filename.

=head2 save_yaml($filename)

Saves the tree as YAML to $filename. PSCALAR etc. don't work yet.

=head2 to_string()

Returns a stringified version of the object. (Using Data::Dumper.)

=head2 autoload

Get/set anything you want. Accounts the data declaration.

=head1 PRIVATE FUNCTIONS

=over 8

=item _load_xml($declaration,$filename)

=item _merge_node_lists($declaration,$destination_perlnode_list,$source_perlnode_list)

=item _parse_domnode_list($domnode_list,$defnode_list)

=item _write_node_list($generator,$defnode_list,$perlnode_list)

=item _getset_node_list_from_string($perlnode_list,$defnode_list,$nodes_string)

=item _get_defnode_type($defnode)

=item _magic_keys($defnode_list,$perlnode_list,$node_name,[@types])

=item _magic_get_perlnode($defnode_list,$perlnode_list,$node_name,$key,[@types])

=item _magic_set_perlnode($defnode_list,$perlnode_list,$node_name,$key,$value,[@types])

=back

=head1 CAVEATS/BUGS

Lab::Data::XMLtree does not support all possible kinds of perl data structures.
It is also not too flexible when it comes to XML. It simply supports
something that I needed.

=head1 SEE ALSO

=over 4

=item XML::Simple

Lab::Data::XMLtree is similar to XML::Simple (L<XML::Simple>).

=item XML::DOM

Lab::Data::XMLtree can use XML::DOM (L<XML::DOM>) to retrieve stored data.

=item XML::Generator

Lab::XMLtree can use XML::Generator (L<XML::Generator>) to store data as XML.

=item YAML

Lab::XMLtree can use YAML (L<YAML>) for data storage.

=back

=head1 AUTHOR/COPYRIGHT

Copyright 2004-2006 Daniel Schröer (L<http://www.danielschroeer.de>), 2011 Andreas K. Hüttel

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
