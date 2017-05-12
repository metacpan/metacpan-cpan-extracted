use strict;

### ######################################################################
### ######################################################################
package Devel::Diagram::Render::UXF20::Package; # A UML "package", which is (several) Perl modules

sub Render {
    my ($self, $pckg) = @_;
    my $xml = <<EOT;
    <Package>
        <Name>$pckg->{'Name'}</Name>
        <Note>$pckg->{'_fileName'}</Note>
EOT
    for my $className ( keys %{$pckg->{'Classes'}} ) {
        next unless $className; #temp
        $xml .= Render Devel::Diagram::Render::UXF20::Class($pckg->{'Classes'}->{$className});
    }
    
    $xml .= '    </Package>';

    return $xml;
}

### ######################################################################
### ######################################################################
package Devel::Diagram::Render::UXF20::Class; # A UML "class" is a Perl "package"

sub Render {
    my ($self, $clss) = @_;
    my $note = ''; # hmmm? <Note>what?</Note>
    my $xml = <<EOT;
    <Class>
        $note
        <Name>$clss->{'Name'}</Name>
        $note
EOT
    for my $operationName ( keys %{$clss->{'Operations'}} ) {
        my $operation = $clss->{'Operations'}->{$operationName};
        $xml .= Render Devel::Diagram::Render::UXF20::Operation($operation);
    }
    
    for my $attributeName ( keys %{$clss->{'Attributes'}} ) {
        my $attribute = $clss->{'Attributes'}->{$attributeName};
        $xml .= Render Devel::Diagram::Render::UXF20::Attribute($attribute);
    }

    $xml .= '    </Class>';
    return $xml;
}

### ######################################################################
### ######################################################################
package Devel::Diagram::Render::UXF20::Operation; # Discovered as "sub something {"

sub Render {
    my ($self, $operation) = @_;
    
    my $note = ''; # hmmm? <Note>what?</Note>
    my $xml = <<EOT;
    <Operation>
        <Name>$operation->{'Name'}</Name>
        $note
    </Operation>
EOT
    return $xml;
}

### ######################################################################
### ######################################################################
package Devel::Diagram::Render::UXF20::Attribute; # Discovered by pattern matching

sub Render {
    my ($self, $attribute) = @_;

    my $note = ''; # hmmm? <Note>what?</Note>
    my $xml = <<EOT;
    <Attribute>
        <Name>$attribute->{'Name'}</Name>
        $note
    </Attribute>
EOT
    return $xml;
}

### ######################################################################
### ######################################################################


### ######################################################################
### ######################################################################
### ######################################################################
### ######################################################################
### ######################################################################
package Devel::Diagram::Render::UXF20; # A container for all the stuff we'll discover here.
use vars qw($VERSION);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

#######################################################################################
#######################################################################################
sub Render {
    my ($cls, $diagram) = @_;
    
    my $xml = <<EOT;
<?xml version="1.0"?>
<!DOCTYPE UXF SYSTEM "DTD/uml.dtd">
EOT

    my $date = localtime;
    my $moduleVersion = ''; # hmmm . . .

    $xml .= <<EOT;
<UXF Version="2.0">
	<TaggedValue>
		<Tag>Generator</Tag>
		<Value>Devel::Diagram::Render::UXF20 version $VERSION</Value>
		<Tag>Author</Tag>
		<Value>Glenn Wood</Value>
		<Tag>Date</Tag>
		<Value>$date</Value>
		<Tag>Version</Tag>
		<Value>$moduleVersion</Value>
	</TaggedValue>
EOT
    
    # Loop over all Packages, rendering each via Devel::Diagram::Render::UXF20::Package
    map 
    {
        my $pkg = $diagram->{'Packages'}->{$_};
        if ( ref($pkg) eq 'HASH' ) {warn Dumper($pkg)."\nFROM: '$_'}"; next;}
        $xml .= Render Devel::Diagram::Render::UXF20::Package($pkg);
    }        
    keys %{$diagram->{'Packages'}};

    $xml .= '</UXF>';

    return $xml;
}

1;

=pod

=head1 NAME

Devel::Diagram::Render::UXF20 - Render a Devel::Diagram as UXF 2.0

=head1 SYNOPSIS

=head1 DESCRIPTION

    See http://www.yy.ics.keio.ac.jp/~suzuki/project/uxf/uxf.html


=head1 AUTHOR

C<Devel::Diagram::Render::UXF20> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2003 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut


