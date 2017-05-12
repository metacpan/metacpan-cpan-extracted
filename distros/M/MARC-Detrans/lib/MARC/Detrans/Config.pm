package MARC::Detrans::Config;

use strict;
use warnings;
use base qw( Class::Accessor );
use XML::SAX::ParserFactory;
use Carp qw( croak );

=head1 NAME 

MARC::Detrans::Config - Stores de-transliteration configuration data

=head1 SYNOPSIS

    use MARC::Detrans::Config;
    my $config = MARC::Detrans::Config->new( 'file.xml' );

=head1 DESCRIPTION

MARC::Detrans::Config will read detransliteration rules from an XML file which
you can then use to create a MARC::Detrans::Converter object to actually convert
MARC records.

    <?xml version="1.0" encoding="UTF-8"?>
    <config>

        <!-- the language we are detransliterating -->
        <language name="Russian" code="rus" />

        <!-- the script that will be used -->
        <script name="Cyrillic" code="(N" />

        <!-- which fields/subfields to detransliterate or copy -->
        <detrans-fields>
            <field tag="245">
                <subfield code="a" />
                <subfield code="q" />
                <subfield code="d" copy="true" />
            </field>
            <field tag="440">
                <subfield code="a" />
            </field>
        </detrans-fields>

        <!-- a single character mapping -->
        <rule>
            <roman>b</roman>
            <marc escape="(N">B</marc>
        </rule>

        <!-- more rules ... -->

        <!-- a single authority mapping -->
        <name>
            <roman>$aNicholas $bI, $cEmperor of Russia, $d1796-1855</roman>
            <marc>$a^ESC(NnIKOLAJ^ESCs, $bI, $c^ESC(NiMPERATOR^ESCs ^ESC(NwSEROSSIJSKIJ^ESCs, $d1796-1855</marc>
        </name>

    </config>

=head1 METHODS

=head2 new()

The constructor, which you should pass the file path for the XML configuration.
If you want to configure the MARC::Detrans::Config object manually you 
can not pass in a path, but you ordinarily wouldn't want to do this.

=cut 

sub new {
    my ( $class, $file ) = @_;
    croak( "config file doesn't exist" ) if $file and ! -f $file;
    my $self = bless { file => $file }, $class || $class;
    $self->_parse( $file );
    return( $self );
}

=head2 rules()

Returns a MARC::Detrans::Rules object that contains the transliteration
rules being used in the configuration.

=head2 names()

Returns a MARC::Detrans::Names object that contains the authority mappings
being used in the configuration.

=head2 allEscapeCodes()

Returns a list of all the MARC8 escape codes that are in use in this
configuration. Useful for when you are building 006 fields that itemize
the different character set codes in use.

=cut

sub allEscapeCodes {
    return @{ shift->{allEscapeCodes} };
}

=head2 detransFields() 

Returns a list of fields that the configuration lists as desiring 
de-transliteration. If you need to you can pass in an array of
field names you'd like to detransliterate...but normally you won't
want to do this since the value come from the XML configuration.

=cut

sub detransFields {
    my ($self,@fields) = @_;
    if ( @fields ) { $self->{lookForFields} = \@fields; }
    return @{ $self->{lookForFields} };
}

=head2 needsDetrans()

Returns true (1) or false (undef) to indicate whether the config lists
a particular field/subfield combination as needing detransliteration.

=cut

sub needsDetrans {
    my ( $self, %args ) = @_;
    croak( "must supply field and subfield parameters" ) 
        if ! exists $args{field} or ! exists $args{subfield};
    return 1 if $self->{detransFields}{$args{field}.$args{subfield}};
    return;
}

=head2 needsCopy()

Returns true (1) or false (undef) to indicate wheter the config lists
a particular field/subfield combination as needing a copy.

=cut

sub needsCopy {
    my ( $self, %args ) = @_;
    croak( "must supply field and subfield parameters" ) 
        if ! exists $args{field} or ! exists $args{subfield};
    return 1 if $self->{copyFields}{$args{field}.$args{subfield}};
    return; 
}

=head1 AUTHORS 

=over 4

=item * Ed Summers <ehs@pobox.com>

=cut

MARC::Detrans::Config->mk_accessors( qw(
    rules 
    names
    languageName
    languageCode
    scriptName
    scriptCode
    scriptOrientation
) );

sub _parse {
    my $self = shift;
    my $handler = ConfigHandler->new();
    my $parser = XML::SAX::ParserFactory->parser( Handler => $handler );
    ## we skip parsing if we don't have a file to parse, which
    ## can happen when the configuration is being manually configured
    ## in tests...
    $parser->parse_uri( $self->{ file } ) if $self->{ file };
    $self->rules( $handler->rules() );
    $self->names( $handler->names() );
    $self->languageName( $handler->languageName() );
    $self->languageCode( $handler->languageCode() );
    $self->scriptName( $handler->scriptName() );
    $self->scriptCode( $handler->scriptCode() );
    $self->scriptOrientation( $handler->scriptOrientation() );
    $self->{lookForFields} = $handler->{lookForFields};
    $self->{detransFields} = $handler->{detransFields};
    $self->{copyFields} = $handler->{copyFields};
    $self->{allEscapeCodes} = [ sort keys %{ $handler->{allEscapeCodes} } ];
}


## the SAX handler for the config file

package ConfigHandler;

use base qw( XML::SAX::Base );
use MARC::Detrans::Rules;
use MARC::Detrans::Rule;
use MARC::Detrans::Names;
use MARC::Detrans::Name;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new();
    $self->resetFlags();
    $self->{rules} = MARC::Detrans::Rules->new();
    $self->{names} = MARC::Detrans::Names->new();
    $self->{lookForFields} = [];
    $self->{detransFields} = {};
    $self->{copyFields} = {};
    $self->{allEscapeCodes} = {};
    return bless $self, $class || ref($class);
}

sub rules { return shift->{rules}; }
sub names { return shift->{names}; }
sub languageName { return shift->{languageName}; }
sub languageCode { return shift->{languageCode}; }
sub scriptName { return shift->{scriptName}; }
sub scriptCode { return shift->{scriptCode}; }
sub scriptOrientation { return shift->{scriptOrientation}; }

sub start_element {
    my ( $self, $data ) = @_;
    my $tag = $data->{Name};
    ## start of rule
    if ( $tag eq 'rule' ) { 
        $self->resetFlags();
        $self->{currentPosition} = $data->{Attributes}{'{}position'}{Value};
        $self->{insideRule} = 1;;
    }
    ## start of name 
    elsif ( $tag eq 'name' ) { 
        $self->resetFlags();
        $self->{insideName} = 1;
    }
    ## start of roman 
    elsif ( $tag eq 'roman' ) { 
        $self->{insideRoman} = 1;
    }
    ## start of marc 
    elsif ( $tag eq 'marc' ) {
        $self->{insideMarc} = 1;
        $self->{currentEscape} = $data->{Attributes}{'{}escape'}{Value};
        ## keep track of all escape codes used
        $self->{allEscapeCodes}{ $self->{currentEscape} }++ 
            if $self->{currentEscape};
    }
    ## language name/code
    elsif ( $tag eq 'language' ) {
        $self->{languageName} = $data->{Attributes}{'{}name'}{Value};
        $self->{languageCode} = $data->{Attributes}{'{}code'}{Value};
    }
    ## script name/code
    elsif ( $tag eq 'script' ) {
        $self->{scriptName} = $data->{Attributes}{'{}name'}{Value};
        $self->{scriptCode} = $data->{Attributes}{'{}code'}{Value};
        $self->{scriptOrientation}=$data->{Attributes}{'{}orientation'}{Value};
    }
    ## start of fields to detransliterate
    elsif ( $tag eq 'detrans-fields' ) { 
        $self->{insideDetransFields} = 1;
    }
    ## start of fields to copy
    elsif ( $tag eq 'copy-fields' ) { 
        $self->{insideCopyFields} = 1;
    }
    ## start of field in either detrans-fields and copy-fields
    elsif ( $tag eq 'field' ) {
        my $field = $data->{Attributes}{'{}tag'}{Value};
        $self->{field} = $field;
        push( @{ $self->{lookForFields} }, $field )
            unless grep /$field/, @{$self->{lookForFields}};
    }
    ## start of subfield in field element
    elsif ( $tag eq 'subfield' ) {
        my $subfield = $data->{Attributes}{'{}code'}{Value};
        my $field = $self->{field};
       
        ## figure out if this subfield needs copying or detransliterating
        my $copy = 0;
        if ( $data->{Attributes}{'{}copy'} 
            and $data->{Attributes}{'{}copy'}{Value} eq 'true' ) {
            $copy = 1;
        }
        ## add the field/subfield combo to appropriate hash 
        ## to use later to figure out if it needs detrans or copy
        if ( $copy ) { 
            $self->{copyFields}{$field.$subfield} = 1;
        } else { 
            $self->{detransFields}{$field.$subfield} = 1;
        }
    }
}

sub end_element {
    my ( $self, $data ) = @_;
    my $tag = $data->{Name};
    ## end of rule, so build the rule and add it 
    if ( $tag eq 'rule' ) {
        my $rule = MARC::Detrans::Rule->new(
            from        => $self->{romanText},
            to          => $self->{marcText},
            escape      => $self->{currentEscape},
            position    => $self->{currentPosition}
        );
        $self->{rules}->addRule( $rule );
        $self->resetFlags();
    }
    ## end of name, so build the name and ad it 
    elsif ( $tag eq 'name' ) { 
        my $name = MARC::Detrans::Name->new(
            from    => $self->{romanText},
            to      => $self->{marcText},
        );
        $self->{names}->addName( $name );
        $self->resetFlags();
    }
    ## end of marc section, store away the text
    elsif ( $tag eq 'marc' ) { 
        $self->{marcText} = $self->{currentText};
        $self->{currentText} = '';
        $self->{insideMarc} = 0;
    }
    ## end of roman section, store away the text
    elsif ( $tag eq 'roman' ) { 
        $self->{romanText} = $self->{currentText};
        $self->{currentText} = '';
        $self->{insideRoman} = 0;
    }
    ## end of detrans-fields
    elsif ( $tag eq 'detrans-fields' ) {
        $self->{insideDetransFields} = 0;
    }
    ## end of copy fields
    elsif ( $tag eq 'copy-fields' ) {
        $self->{insideCopyFields} = 0;
    }
}

sub characters {
    my ( $self, $data ) = @_;
    ## only store text if we're in a marc or roman tag 
    if ( $self->{insideMarc} or $self->{insideRoman} 
        or $self->{insideSubfield} ) { 
        $self->{currentText} .= $data->{Data};
    }
}

sub resetFlags {
    my $self = shift;
    $self->{insideRule} = 0;
    $self->{insideName} = 0;
    $self->{insideRoman} = 0;
    $self->{insideMarc} = 0;
    $self->{insideDetransFields} = 0;
    $self->{insideCopyFields} = 0;
    $self->{currentText} = '';
    $self->{marcText} = '';
    $self->{romanText} = '';
    $self->{currentEscape} = '';
    $self->{field} = '';
}

1;
