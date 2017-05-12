package Language::LispPerl::Printer;
$Language::LispPerl::Printer::VERSION = '0.007';
use strict;
use warnings;

=head2 to_perl

Pure function. Takes something Language::LispPerl related and
turns it into a pure perl data structure.

=cut

sub to_perl{
    my $thing = shift;

    # Object case. Easy.
    if( Scalar::Util::blessed( $thing ) ){
        return $thing->to_hash();
    }

    my $ref_thing = ref($thing);
    # Pure scalar thing. Easy.
    unless( $ref_thing ){
        return $thing;
    }
    if( $ref_thing eq 'ARRAY' ){
        return [ map{ to_perl( $_ ) } @{$thing} ];
    }
    if( $ref_thing eq 'HASH' ){
        my $hash = {};
        while( my ( $k , $v ) = each %$thing ){
            $hash->{$k} = to_perl( $v );
        }
        return $hash;
    }
    confess("Cannot turn $thing into pure perl structure");
}


sub to_string {
    my $obj = shift;
    return "" if !defined $obj;
    my $class = $obj->class();
    my $type  = $obj->type();
    my $s     = "";
    if ( $class eq "Seq" ) {
        if ( $type eq "vector" ) {
            $s = "[";
        }
        elsif ( ( $type eq "map" ) ) {
            $s = "{";
        }
        else {
            $s = "(";
        }
        foreach my $i ( @{ $obj->value() } ) {
            $s .= to_string($i) . " ";
        }
        if ( $type eq "vector" ) {
            $s .= "]";
        }
        elsif ( ( $type eq "map" ) ) {
            $s .= "}";
        }
        else {
            $s .= ")";
        }
        $s =~ s/ ([\)\]\}])$/$1/;
    }
    else {
        if ( $type eq "vector" ) {
            $s = "[";
            foreach my $i ( @{ $obj->value() } ) {
                $s .= to_string($i) . " ";
            }
            $s .= "]";
            $s =~ s/ \]$/\]/;
        }
        elsif ( $type eq "map" or $type eq "meta" ) {
            $s = "{";
            foreach my $i ( keys %{ $obj->value() } ) {
                $s .= $i . "=>" . to_string( $obj->value()->{$i} ) . " ";
            }
            $s .= "}";
            $s =~ s/ \}$/\}/;
        }
        elsif ( $type eq "xml" ) {
            $s = "<";
            $s .= $obj->{name};
            if ( defined $obj->{meta_data} ) {
                my %meta = %{ $obj->meta_data()->value() };
                foreach my $i ( keys %meta ) {
                    $s .= " " . $i . "=\"" . to_string( $meta{$i} ) . "\"";
                }
            }
            $s .= ">";
            foreach my $i ( @{ $obj->value() } ) {
                $s .= to_string($i) . " ";
            }
            $s .= "</" . $obj->{name} . ">";
        }
        elsif ( $type eq "function" or $type eq "macro" ) {
            $s = to_string( $obj->value() );
        }
        elsif ( $type eq "exception" ) {
            $s = "exception: ";
            $s .= $obj->{label} . " - ";
            $s .= $obj->value();
            foreach my $c ( @{ $obj->{caller} } ) {
                $s .= "\n\t" . to_string($c);
                $s .= "[";
                $s .= "file:" . $c->{pos}->{filename} . "; ";
                $s .= "line:" . $c->{pos}->{line} . "; ";
                $s .= "col:" . $c->{pos}->{col} . ";";
                $s .= "]";
            }
        }
        elsif( $type eq 'string' ){
            $s = $obj->value();
            $s =~ s/"/\\"/g;
            $s = '"'.$s.'"';
        }
        else {
            $s = $obj->value();
        }
    }
    return $s;
}

1;

