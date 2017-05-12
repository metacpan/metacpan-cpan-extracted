package Lingua::Ogmios::Annotations::LogProcessing;

use strict;
use warnings;

use Lingua::Ogmios::Annotations::Element;
our @ISA = qw(Lingua::Ogmios::Annotations::Element);

sub new {
    my ($class, $fields) = @_;

    my @refTypes = ('list_modified_level');

#     warn join(":", keys %$fields) . "\n";
#     warn join(":", values %$fields) . "\n";

    if (!defined $fields->{'log_id'}) {
	$fields->{'log_id'} = -1;
    }

    my $log_processing = {
	'log_id' => $fields->{'log_id'},
	'next' => undef,
	'previous' => undef,
    };
    
    bless ($log_processing, $class);

    ########################################################################
#     my $i = 0;
#     my $reference_name;
#     my $ref;
#     foreach $ref (@refTypes) {
#  	if (exists $fields->{$ref}) {
#  	    $reference_name = $ref;
#  	    last;
#  	}
#  	$i++;
#     }
#     if ($i == scalar(@refTypes)) {
#  	warn ("reference (list) is not defined");
#     } else {
# 	$log_processing->list_modified_level($reference_name, $fields->{$reference_name});    
#     }
    ########################################################################


    if (defined $fields->{'software_name'}) {
	$log_processing->setSoftwareName($fields->{'software_name'});
    } else {
	$log_processing->{'software_name'} = undef;
    }
    if (defined $fields->{'command_line'}) {
	$log_processing->setCommandLine($fields->{'command_line'});
    } else {
	$log_processing->{'command_line'} = undef;
    }
    if (defined $fields->{'stamp'}) {
	$log_processing->setStamp($fields->{'stamp'});
    } else {
	$log_processing->{'stamp'} = undef;
    }
    if (defined $fields->{'tagset'}) {
	$log_processing->setTagset($fields->{'tagset'});
    } else {
	$log_processing->{'tagset'} = undef;
    }
    if (defined $fields->{'comments'}) {
	$log_processing->setComments($fields->{'comments'});
    } else {
	$log_processing->{'comments'} = undef;
    }
    if (defined $fields->{'list_modified_level'}) {
	$log_processing->list_modified_level('list_modified_level', $fields->{'list_modified_level'});    
    }

    return($log_processing);
}

sub list_modified_level {
    my $self = shift;
    my $ref;
    my $elt;

    if ((@_) && (scalar @_ == 2)) {
	$self->{'reference'} = shift;
	$self->{$self->{'reference'}} = [];
	$ref = shift;
	foreach $elt (@$ref) {
	    push @{$self->{$self->{'reference'}}}, $elt;
	}
    }
    return($self->{$self->{'reference'}});
}

sub next {
    my $self = shift;

    $self->{'next'} = shift if @_;
    return($self->{'next'});
}

sub previous {
    my $self = shift;

    $self->{'previous'} = shift if @_;
    return($self->{'previous'});
}

sub setId {
    my($self, $id) = @_;
    # $id is a reference of an array

    $self->{'log_id'} = $id;
}

sub getId {
    my($self) = @_;
    # id field is a reference of an array

    return($self->{'log_id'});
}

sub setComments {
    my($self, $Comments) = @_;
    # $Comments is a reference of an array

    $self->{'comments'} = $Comments;
}

sub getComments {
    my($self) = @_;
    # comments field is a reference of an array

    return($self->{'comments'});
}

sub setTagset {
    my($self, $Tagset) = @_;
    # $Tagset is a reference of an array

    $self->{'tagset'} = $Tagset;
}
sub getTagset {
    my($self) = @_;
    # tagset field is a reference of an array

    return($self->{'tagset'});
}

sub setStamp {
    my($self, $Stamp) = @_;

    $self->{'stamp'} = $Stamp;
}

sub getStamp {
    my($self) = @_;

    return($self->{'stamp'});
}

sub setCommandLine {
    my($self, $CommandLine) = @_;

    $self->{'command_line'} = $CommandLine;
}

sub getCommandLine {
    my($self) = @_;

    return($self->{'command_line'});
}

sub setSoftwareName {
    my($self, $SoftwareName) = @_;

    $self->{'software_name'} = $SoftwareName;
}

sub getSoftwareName {
    my($self) = @_;

    return($self->{'software_name'});
}

sub print {
    my ($self, $fh) = @_;
    if (!defined $fh) {
	$fh = \*STDERR
    }
    my $field;
    foreach $field (keys %$self) {
	if (defined $self->{$field}) {
	    print $fh "$field => " . $self->{$field} . "\n";
	}
    }
    return(0);
}

sub _getField {
    my ($self, $field) = @_;

    return($self->{$field});
}


sub _xmldecode { # to be optimized
    my ($self, $string) = @_;

    $string =~ s/&amp;/&/go;
    $string =~ s/&quot;/\"/og;
    $string =~ s/&apos;/\'/og;
    $string =~ s/&lt;/</og;
    $string =~ s/&gt;/>/og;

    return($string);
}

sub _xmlencode { # to be optimized
    my ($self, $string) = @_;

    $string =~ s/&/&amp;/og;
    $string =~ s/\"/&quot;/og;
    $string =~ s/\'/&apos;/og;
    $string =~ s/</&lt;/og;
    $string =~ s/>/&gt;/og;
    
    return($string);
}


sub XMLout {
    my ($self, $order) = @_;
#     my $field;

    return($self->SUPER::XMLout("log_processing", $order));

#     my $str;
    
#     $str = "\t<log_processing>\n";
#     foreach $field (@$order) {
# 	if (defined $self->_getField($field)) {
# 	    $str .= "\t\t<$field>" . $self->_xmlencode($self->_getField($field)) . "</$field>\n";
# 	}
#     }
#     $str .= "\t</log_processing>\n";
#     return($str);
}

sub reference {
    my ($self) = @_;

    return([]);
}


1;

__END__

=head1 NAME

Lingua::Ogmios::Annotations::LogProcessing - Perl extension for the log of the document processing.

=head1 SYNOPSIS

use Lingua::Ogmios::Annotations::???;

my $word = Lingua::Ogmios::Annotations::???::new($fields);


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 FIELDS

=over

=item *


=back


=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

