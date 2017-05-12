#!/usr/bin/env perl

use warnings;
use strict;

package Gwybodaeth::Write;

use Gwybodaeth::Escape;

=head1 NAME

Write::Write - Main class for applying maps to data.

=head1 SYNOPSIS

    use base qw(Write);

=head1 DESCRIPTION

This class is intended to be subclassed thus has no public methods bar new().

=over
=cut

use Carp qw(croak);
use XML::Twig;

# Allow output to be in utf8
binmode( STDOUT, ':utf8' );
binmode( STDERR, ':utf8' );

=item new()

Returns an instance of whichever class has subclassed Gwybodaeth::Write.;

=cut
 
sub new {
    my $class = shift;
    my $self = { ids => {}, Data => ""};
    $self->{XML} = XML::Twig->new(pretty_print => 'nice');
    bless $self, $class;
    return $self;
}

# Check cleanliness of input data 
sub _check_data {
    my $self        = shift;
    my $triple_data = shift;
    my $data        = shift;
    my $data_type   = shift;      # data type of $data;
    
    # Check $triple_data is the correct data type.
    unless (ref($triple_data) eq 'ARRAY') { 
        croak "expected array ref as first argument";
    }

    my $triples = ${ $triple_data }[0];
    my $functions = ${ $triple_data }[1]; 

    # Check that both array elements are the correct data types in 
    # $triple_data.
    unless (eval{ $triples->isa('Gwybodaeth::Triples') }) {
        croak 'expected a Gwybodaeth::Triples object as first argument of array';
    }
    unless (ref($functions) eq 'HASH') {
        croak 'expected a hash ref as second argument of array';
    }
    
    # Check $data is in the correct data type.
    unless (ref($data) eq $data_type) {
        croak "expected $data_type in the second array ref";
    }
    return 1;
}

sub _print2str {
    my $self = shift;
    my $str = shift;

    $self->{Data} .= $str;

    return 1;
}

sub _extract_field {
    my $self = shift;
    my $data = shift;
    my $field = shift;


    # The object is a specific field
    if ($field =~ m/^\"     # string's first char is a double quote
                    Ex:
                    \$      # $ sign
                    (       # start variable scope
                    [\:\w]+ # one or more word or colon chars
                    \/?     # possible forward slash
                    [\:\w]* # zero or more word or colon chars
                    )       # end variable scope
                    (       # start option scope
                    (\^\^|\@)   # ^^ or @
                    .*      # zero or more of any non \n chars
                    )?      # end option scope and make the scope 
                            # non essential
                    \"$     # string's last cha is a double quote
                    /x) { 
        # Remeber that _get_field() is often subclassed
        # so we can't assume what form of data it returns.
        return $self->_get_field($data,$1,$2);
    }
    # The object is a concatination of fields 
    if ($field =~ m/^[\"\<] # string's first char is a double quote
                            # or an opening angle bracket
                    Ex:
                    .*\+    # zero or more non \n char followed by a plus
                    /x) {
        return $self->_cat_field($data, $field);
    }
    if ($field =~ m/^\$     # string's first char is a doller sign
                    (       # start scope
                    [\:\w]+ # one or more word or colon chars
                    \/?     # possible forward slash
                    [\:\w]* # zero or more word or colon chars
                    )       # end scope
                    $/x) {
        return $self->_get_field($data,$1);
    } 
    if ($field =~ m/^\<     # string's first char is an opening angle bracket
                    Ex:
                    \$      # $ sign
                    (       # start scope
                    [\:\w]+ # one or more word or colon chars
                    \/?     # possible forward slash
                    [\:\w]* # zero or more word or colon chars
                    )       # close scope
                    \>$     # string's last char is a closing angle bracket
                    /x) {
        return $self->_get_field($data,$1);
    } 
    if ( $field =~ m/\@Split/x) {
        return $self->_split_field($data, $field);
    }
    
    # If it doesn't match any of the above, allow it to be a bareword field
    return "$field";
}

# Concatinate fields
sub _cat_field {
    my $self = shift;
    my $data = shift;
    (my $field = shift) =~ s/
                            # any char followed by Ex:
                            .Ex://x;

    my $string = qq{};

    my @values = split /\+/x, $field;

    for my $val (@values) {
        # Extract ${num} variables from data
        if ($val =~ m/\$    # $ sign
                    (       # start variable scope
                    [\:\w]+ # one or more word or colon characters
                    )       # end variable scope
                    /x) {
            $string .= $self->_get_field($data,$1);
        }
        # Put a space; 
        elsif ($val =~ m/\'\s*\' # single quoted zero or more whitespace char
                        /x) {
            $string .= " ";
        } 
        # Print a literal
        else {
            $string .= $val;
        }
    }
    return $string;
}

# How to interpret the @Split grammar
sub _split_field {
    my($self, $data, $field) = @_;

    my @strings;
    
    if ($field =~ m/\@Split # Split grammar
                    \(      # open bracket
                    Ex:
                    \$      # $ sign
                    (       # start variable scope
                    \d+     # one or more numeric character
                    )       # end variable scope
                    ,
                    "(.)"   # doublpe quoted any non \n char - delimeter 
                    \)      # close bracket
                    /x) {
        my $delimeter = $2;

        @strings = split /$delimeter/x, $self->_get_field($data,$1);
        return \@strings;
    }

    return $field;
}

sub _write_meta_data {
    my $self = shift;

    my $namespace = Gwybodaeth::NamespaceManager->new();
    my $name_hash = $namespace->get_namespace_hash();
    my $base = $namespace->get_base();

    $self->_print2str("<?xml version=\"1.0\"?>\n<rdf:RDF\n");
    for my $keys (keys %{ $name_hash }) {
        (my $key = $keys) =~ s/
                              # string ends in a colon
                              :$//x;
        next if ($key eq "");
        $self->_print2str("xmlns:$key=\"" . $name_hash->{$keys} . "\"\n");
    }
    if (${ $base }) {
        $self->_print2str("xml:base=\"${ $base }\"\n");
    }
    $self->_print2str(">\n");
    
    return 1;
}

sub _write_triples {
    my ($self,@vars) = @_;
    return $self->_really_write_triples(@vars);
}

sub _really_write_triples {
    my ($self, $row, $triples, $id) = @_;

    for my $triple_key ( keys %{ $triples } ) {

        my $subject = $self->_if_parse($triple_key,$row);
        $self->_print2str("<".$subject);
        if ($id) {
            chomp(my $id_text = $self->_extract_field($row,$id));
            if (ref($id_text) eq 'ARRAY') {
                for my $obj (@{ $id_text }) {
                    $self->_print2str($self->_about_or_id($obj));
                }
            } else {
                $self->_print2str($self->_about_or_id($id_text));
            }
            $self->_print2str('"');
        } 
        $self->_print2str(">\n");

        my @verbs = @{ $triples->{$triple_key}{'predicate'} };
        for my $indx (0..$#verbs ) {
            $self->_get_verb_and_object(
                                $verbs[$indx],
                                $triples->{$triple_key}{'obj'}[$indx],
                                $row);
        }
        $self->_print2str("</".$subject.">\n");
    }
    return;
}

sub _get_verb_and_object {
    my($self, $verb, $object, $row) = @_;

    my $obj_text = "";
    unless ( eval{ $object->isa('Gwybodaeth::Triples') } ) {
        $obj_text = $self->_get_object($row, $object);
    }

    if (ref($obj_text) eq 'ARRAY') {
        for my $obj (@{ $obj_text }) {
            $self->_print_verb_and_object($verb, $obj, $row, $object);
        }
    } else {
        $self->_print_verb_and_object($verb, $obj_text, $row, $object);
    }
    return 1;
}

sub _print_verb_and_object {
    my ($self, $verb, $object, $row, $unparsed_obj) = @_;
    my $esc = Gwybodaeth::Escape->new();

    my $predicate = $self->_if_parse($verb,$row);
    my $obj="";
    $self->_print2str("<" . $predicate );

    if ( $unparsed_obj =~ m/\<  # opening angle bracket 
                            Ex:
                            \$  # $ sign
                            \w+ # one or more word chars
                            \/? # a possible forward slash
                            \w* # zero or more word chars
                            \>$ # string ends with a closing angle brackt
                            /x ) {
        # We have a reference
        $self->_print2str(' rdf:resource="#');
        my $parsed_obj = $self->_get_object($row,$unparsed_obj);
        if (ref($parsed_obj) eq 'ARRAY') {
            for my $obj (@{ $parsed_obj }) {
                $self->_print2str($esc->escape($obj));
            }
        } else {
            $obj = $esc->escape($parsed_obj);
            $self->_print2str($obj);
        }
        $self->_print2str("\"/>\n");
    } else {
        $self->_print2str(">");
        if (eval{$unparsed_obj->isa('Gwybodaeth::Triples')}) {
            $obj =  $esc->escape($self->_get_object($row,$unparsed_obj));
            $self->_print2str($obj);
        } else {
            $obj = $esc->escape($self->_get_object($row,$object));
            $self->_print2str($obj);
        }
        $self->_print2str("</" . $predicate . ">\n");
    }
    return 1;
}

sub _get_object {
    my($self, $row, $object) = @_;

    if (eval {$object->isa('Gwybodaeth::Triples')}) {
        $self->_write_triples($row, $object);
    } else {
        return $self->_extract_field($row, $object);
    }
    return "";
}

sub _about_or_id {
    my($self, $text) = @_;

    if ($text =~ /\s/x or $text =~ /[^A-Z]+ # one or more non capital letters/x)
    { 
        $self->_print2str(' rdf:about="#');
    } else {
        $self->_print2str(' rdf:ID="');
    }
    return $text;
}
sub _if_parse {
    my($self, $token, $row) = @_;

    if ($token =~ m/\@If
                    \(      # open bracket
                    (       # start question scope
                    .+      # one or more non \n char
                    )       # end question scope
                    \;
                    (       # start 'true' scope
                    .+      # one or more non \n char
                    )       # end 'true' scope
                    \;
                    (       # start 'false' scope
                    .+
                    )       # end 'false scope
                    \)      # close bracket
                    /ix) {
        my($question,$true,$false) = ($1, $2, $3);

        $true =~ s/\'//gx;
        $false =~ s/\'//gx;

        my @q_split = split q{=}, $question;

        $q_split[0] =~ s/\'//gx;
        $q_split[1] =~ s/\'//gx;

        my $ans = qq{};
        if ($token =~ m/\<  # opening angle bracket
                        Ex
                        \:  # a colon
                        (   # start scope
                        .+  # one or more non \n chars
                        \+  # a plus sign
                        )   # end scope
                        \@If/ix ) {
            ($ans .= $1) =~ s/\+//gx;
            $ans .= qq{:};
        }

        if ($q_split[0] =~ m/^\$    # first char of the string is a $
                            (\w+)   # one or more word characters scoped
                                    # as the field
                            /x) {
            $q_split[0] = $self->_get_field($row,$1);
        }

        # If the returned field is an ARRAY join the elements
        # into one scalar string.
        if (ref($q_split[0]) eq 'ARRAY') {
            $q_split[0] = join ' ', @{ $q_split[0] };
        }

        if ($q_split[0] eq $q_split[1]) {
            $ans .= $true;
        } else {
            $ans .= $false;
        }
        $token = $ans;
    }
    return $token;
}

# Structure the serialized data string into an XML::Twig object.
sub _structurize {
    my $self = shift;

    my $twig = $self->{XML};

    my $xml = $self->{Data};

    $twig->safe_parse($xml);

    return $self->_set_datatype($twig);
}

sub _set_datatype {
    my($self, $twig) = @_;

    my $elt = $twig->root;
    while( $elt = $elt->next_elt($twig->root) ) {
        if ($elt->text_only =~ m/(  # begin text scope
                                .+  # one or more of any non \n character
                                )   # end text scope
                                \^\^# matches ^^
                                (   # begin datatype scope
                                \w+ # one ore more word character
                                )   # end datatype scope
                                $   # end of string/x ) {
           $elt->set_text($1);
           $elt->set_att(
                 'rdf:datatype' => "http://www.w3.org/TR/xmlschema-2/#".$2
           );
        } 
        elsif ($elt->text_only =~ m/
                                (   # begin text scope
                                .+  # one or more of any non \n character
                                )   # end text scope
                                \@  # 'at' symbol
                                (   # begin lang scope
                                \w+ # one or more word characters
                                )   # end of lang scope
                                $   # end of string/x ) {
            $elt->set_text($1);
            $elt->set_att(
                    'xml:lang' => $2
            );
        }
    }

    return $twig;
}
1;
__END__
=back

=head1 AUTHOR

Iestyn Pryce, <imp25@cam.ac.uk>

=head1 ACKNOWLEDGEMENTS

I'd like to thank the Ensemble project (L<www.ensemble.ac.uk>) for funding me to work on this project in the summer of 2009.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Iestyn Pryce <imp25@cam.ac.uk>

This library is free software; you can redistribute it and/or modify it under
the terms of the BSD license.
