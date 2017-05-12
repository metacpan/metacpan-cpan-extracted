package Lingua::Ogmios::LearningDataSet;


use strict;
use warnings;

our $VERSION='0.1';

sub new {

    my $class = shift;

    my $learningDataSet = {
	'relation' => undef,
	'attributes' => [],
	'attribute_index' => {},
	'dataset' => [],
	'comments' => [],
	'classes' => {},
	    
    };

    bless $learningDataSet, $class;

    return($learningDataSet);
}

sub relation {
    my $self = shift;

    if (@_) {
	$self->{relation} = shift;
    }
    return($self->{relation});
}

sub attributes {
    my $self = shift;

    if (@_) {
	$self->{attributes} = shift;
    }
    return($self->{attributes});
}

sub countValAttr {
    my $self = shift;

    return(scalar(@{$self->{attributes}}));
}

sub attribute_index {
    my $self = shift;

    if (@_) {
	$self->{attribute_index} = shift;
    }
    return($self->{attribute_index});
}

sub classes {
    my $self = shift;

    if (@_) {
	my $classes = shift;
	if (ref($classes) eq "HASH") {
	    $self->{classes} = {};
	    %{$self->{classes}} = %$classes;
	} elsif (ref($classes) eq "ARRAY"){
	    
	    my $i = 0;
	    $self->{classes} = {};
	    for($i=0; $i < scalar(@$classes); $i++) {
		$self->{classes}->{$classes->[$i]} = $i + 1;
	    }
	} elsif (ref($classes) eq "") {
	    # TODO
	}
    }
    return($self->{classes});
}

sub firstClass {
    my $self = shift;

    # if (@_) {
    # 	$self->{'fistClass'} = shift;
    # }

    my @tmp = sort { $self->classes->{$a} <=> $self->classes->{$b} } keys %{$self->classes};

    return($tmp[0]);
}

sub existsInClasses {
    my ($self, $class) = @_;

    # warn $self->classes  . "\n";
    return(exists($self->classes->{$class}));
}

sub dataset {
    my $self = shift;

    if (@_) {
	$self->{dataset} = shift;
    }
    return($self->{dataset});
}

sub comments {
    my $self = shift;

    if (@_) {
	$self->{comments} = shift;
    }
    return($self->{comments});
}

sub addAttribute {
    my ($self, $attr) = @_;

    push @{$self->attributes}, $attr;
    $self->attribute_index->{$attr->name} = scalar(@{$self->attributes}) - 1;
    $attr->index(scalar(@{$self->attributes}) - 1);
    return($self->attribute_index->{$attr->name});
}

sub delAttribute {
    my ($self, $attr_name) = @_;
    
    splice @{$self->attributes}, $self->attribute_index->{$attr_name}, 1;
    delete $self->attribute_index->{$attr_name};
    
}

sub getAttributeIndex {
    my ($self, $attr_name) = @_;

    return($self->attribute_index->{$attr_name});
    
}


sub existsAttribute {
    my ($self, $attr_name) = @_;

    return(exists $self->attribute_index->{$attr_name});

}

sub addData {
    my ($self, $data) = @_;

    push @{$self->dataset}, $data;

}

sub addComment {
    my ($self, $comment) = @_;

    push @{$self->comments}, $comment;
}

sub getARFF {
    my $self = shift;
    my $printheader = shift;

    my $arffString;

    if ((!defined $printheader) || ($printheader == 1)) {
	$arffString .= $self->getARFFHeader;
    }

    $arffString .= '@DATA' . "\n";
    $arffString .= $self->getARFFData;    
    return($arffString);
}

sub getARFFData {
    my $self = shift;

    my $arffString;
    my $data;

    foreach $data (@{$self->dataset}) {
	$arffString .= $data->getARFF . "\n";
    }
    return($arffString);
}
sub getARFFHeader {
    my $self = shift;

    my $arffString;
    my $comment;
    my $attribute;
    my $data;

    foreach $comment (@{$self->comments}) {
	$arffString .= "% $comment\n";
    }
    $arffString .= '@RELATION ' . $self->relation . "\n\n";
	
    foreach $attribute (@{$self->attributes}) {
	$arffString .= $attribute->getARFF . "\n";
    }
    $arffString .= '@ATTRIBUTE class {' . join (",", sort({$self->classes->{$a} <=> $self->classes->{$b}} keys(%{$self->classes}))) . "}\n";
    $arffString .= "\n";

    return($arffString);
}

sub getSVM {
    my $self = shift;
    my $printComments = shift;
    my $SVMString;
    my $comment;
    my $data;

    if ((!defined $printComments) || ($printComments == 1)) {
	foreach $comment (@{$self->comments}) {
	    $SVMString .= "# $comment\n";
	}
    }

    foreach $data (@{$self->dataset}) {
	$SVMString .= $data->getSVM($self->classes, $printComments) . "\n";
    }
    return($SVMString);
    
}

sub loadAttributesFromFile {
    my ($self, $filename, $type, $prefix) = @_;
    my $line;
    my $attr;

    warn "openning $filename\n";
    open FILE, $filename or die "No such file $filename\n";
    binmode(FILE, ":utf8");

    while($line = <FILE>) {
	chomp $line;
	if ($line !~ /^\s*#/o) {
	    $attr = Lingua::Ogmios::LearningDataSet::Attribute->new(
		{"name" => "$prefix". "_" . $line,
		 "type" => uc($type),
		 "prefix" => $prefix,
		 "value" => $line,
		}
		);
	    $self->addAttribute($attr);
	}
    }

    close FILE;
}

sub parseARFF {
    my ($self, $filename) = @_;

    my $line;
    my $relation;
    my $attribute;
    my $name;
    my $type;
    my $data;
    my $info_attr;
    my $prefix;
    my @classes;
    my @tmp ;

    open FILE, $filename or die "No such file $filename\n";
    binmode(FILE, ":utf8");
    while($line = <FILE>) {
	chomp $line;

	# Relation
	if ($line =~ /\@relation\s+/io) {
	    $relation = $'; # '
  	    $relation =~ s/^['"]//o;
	    $relation =~ s/['"]$//o;
	    $self->relation($relation);
	}

	# Attribute
	if ($line =~ /\@attribute\s+/io) {
	    $info_attr = $'; # '
            ($name, $type) = split / /, $info_attr;
	    if ($name eq "class") {
		$type =~ s/^{//o;
		$type =~ s/}$//o;
		@classes = split /\s*,\s*/, $type;
		$self->classes(\@classes);
	    } else {
		@tmp = split /_/, $name;
		$prefix = shift @tmp;
		
		$attribute = Lingua::Ogmios::LearningDataSet::Attribute->new(
		    {"name" => $name,
		     "type" => $type,
		     "prefix" => $prefix,
		     "value" => join('_', @tmp),
		    }
		    );
		$self->addAttribute($attribute);
	    }
	}
	
	# Data
	if ($line =~ /\@data\s*/io) {
	    # warn "$line\n";
	    # while($line = <FILE>) {
	    # 	chomp $line;
	    $self->parseDataset(\*FILE);
	    # }
	}

    }

    close FILE;
    return(1);
}

sub parseData {
    my ($self, $fh, $line) = @_;

    my $addr_val;
    my $addr;
    my $val;
    my $data;
    my @values;
    my $index;
    # warn "line: $line\n";
    if ($line =~ /{/o) {
	$data = Lingua::Ogmios::LearningDataSet::Data->new({type => "sparse", 'countVal' => $self->countValAttr});
	$line =~ s/^{\s*//o;
	$line =~ s/\s*}$//o;
    } else {
	$data = Lingua::Ogmios::LearningDataSet::Data->new({type => "normal", 'countVal' => $self->countValAttr});
    }
    @values = split /\s*,\s*/, $line;
    $addr_val = pop @values;
    if (defined $addr_val) {
    if ($data->isSparse) {
	($addr, $val) = split /\s+/, $addr_val;
    } else {
	$val = $addr_val;
    }
    } else {
	$val = undef;
    }
    # warn "line: $line\n$addr\n$val\n";
    
    if ((defined $val) && ($self->existsInClasses($val))) {
	# warn "\n\n==>$val\n";exit;
    } else {
	$val = $self->firstClass;
	if (defined $addr_val) {
	    push @values, $addr_val;
	}
    }
    # warn "val: $val\n";
    $data->class($val);

    # warn "\n\n====>" . $data->class . "\n";exit;

#	$data->countVal($val);
    $index = 0;
    foreach $addr_val (@values) {
	if ($data->isSparse) {
	    ($addr, $val) = split /\s+/, $addr_val;
	} else {
	    $val = $addr_val;
	    $addr = $index;
	}
	$data->value($addr, $val);
	$index++;
    }

    $self->addData($data);
}

sub parseDataset {
    my ($self, $fh) = @_;

    my $line;
    while ($line = <$fh>) { 
	chomp $line;
	if ($line !~ /^\s*$/o) {
	    $self->parseData($fh, $line);
	}
    }
}
sub printAttributes {
    my ($self, $corresp, $fh) = @_;
    my $name;
    my $attribute;

    if (!defined $fh) {
	$fh = \*STDOUT;
    }
    binmode($fh, ":utf8");

    if (!defined $corresp) {
	$corresp = 0;
    }
    foreach $attribute (@{$self->attributes}) {
	$name =  $attribute->name;
	$name =~ s/^[^_]+_//;
	print $fh "$name";
	if ($corresp == 1) {
	    print $fh "\t" . $attribute->name;
	    print $fh "\t" . $attribute->type;
	}
	print $fh "\n";
    }

}


sub printDataset {
    my ($self, $fh) = @_;

    my $data;
    if (!defined $fh) {
	$fh = \*STDOUT;
    }
    binmode($fh, ":utf8");

    foreach $data (@{$self->dataset}) {
	print $fh $data->getARFF . "\n";
	print $fh $data->getSVM($self->classes) . "\n";
    }
}
sub printRelation {
    my ($self, $fh) = @_;

    if (!defined $fh) {
	$fh = \*STDOUT;
    }
    binmode($fh, ":utf8");

    print $fh $self->relation . "\n";
    
}

1;

__END__

=head1 NAME

Lingua::Ogmios::LearningDataSet - Perl extension for managing a learning data set

=head1 SYNOPSIS

use Lingua::Ogmios::LearningDataSet;

$learningDataSet = Lingua::Ogmios::LearningDataSet->new();

=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
