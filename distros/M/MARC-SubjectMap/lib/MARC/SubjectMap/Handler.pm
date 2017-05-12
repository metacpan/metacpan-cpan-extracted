package MARC::SubjectMap::Handler;

## SAX handler used to parse config files 
## internal use only 

use strict;
use warnings;
use base qw( XML::SAX::Base );

use MARC::SubjectMap;
use MARC::SubjectMap::Rule;
use MARC::SubjectMap::Rules;
use MARC::SubjectMap::Field;

sub new {
    my ($package,@args) = @_;
    my $self = $package->SUPER::new(@args);
    $self->{config} = MARC::SubjectMap->new();
    return $self;
}

sub config {
    return shift->{config};
}

sub start_element {
    my ($self,$data) = @_;
    my $name = $data->{Name};
    
    # start <fields> element 
    if ( $name eq 'fields' ) { 
        $self->{inside} = 'fields';
    }

    # start <field> element
    elsif ( $name eq 'field' ) {
        $self->{field} = MARC::SubjectMap::Field->new();
        ## pull out tag attribute 
        $self->{field}->tag( $data->{Attributes}{'{}tag'}{Value} );
        # these are optional
        $self->{field}->indicator1($data->{Attributes}{'{}indicator1'}{Value})
            if exists $data->{Attributes}{'{}indicator1'}{Value};
        $self->{field}->indicator2($data->{Attributes}{'{}indicator2'}{Value})
            if exists $data->{Attributes}{'{}indicator2'}{Value};
    }

    # start <rules> element 
    elsif ( $name eq 'rules' ) { 
        $self->{inside} = 'rules'; 
        $self->{rules} = MARC::SubjectMap::Rules->new();
    }

    # start <rule> element
    elsif ( $name eq 'rule' ) {
        $self->{rule} = MARC::SubjectMap::Rule->new();
        $self->{rule}->field( $data->{Attributes}{'{}field'}{Value} );
        $self->{rule}->subfield( $data->{Attributes}{'{}subfield'}{Value} );
    }
}

sub end_element {
    my ($self,$data) = @_;
    my $name = $data->{Name};

    # process sourceLanguage element
    if ( $name eq 'sourceLanguage' ) {
        $self->{config}->sourceLanguage( $self->{text} );
    }

    # process <fields> content 
    elsif ( $self->{inside} eq 'fields' ) { 
        if ( $name eq 'field' ) {
            $self->{config}->addField( $self->{field} );
        }
        elsif ( $name eq 'copy' ) { 
            $self->{field}->addCopy( $self->{text} );
        }
        elsif ( $name eq 'translate' ) { 
            $self->{field}->addTranslate( $self->{text} );
        }
    }

    # process <rules> content 
    elsif ( $self->{inside} eq 'rules' ) {
        if ( $name eq 'rules' ) { 
            $self->{config}->rules( $self->{rules} );
        }
        elsif ( $name eq 'rule' ) { 
            $self->{rules}->addRule( $self->{rule} );
        }
        elsif ( $name eq 'original' ) { 
            $self->{rule}->original( $self->{text} );
        }
        elsif ( $name eq 'translation' ) { 
            $self->{rule}->translation( $self->{text} );
        }
        elsif ( $name eq 'source' ) {
            $self->{rule}->source( $self->{text} );
        }
        elsif ( $name eq 'sourceSubfield' ) {
            $self->{rule}->sourceSubfield( $self->{text} );
        }
    }

    # closing tag so reset text
    $self->{text} = '';
}
    
sub characters {
    my ($self,$data) = @_;
    my $text = $data->{Data};
    $text =~ s/[\r\n]//g; # strip newlines
    $self->{text} .= $text;
}

1;
