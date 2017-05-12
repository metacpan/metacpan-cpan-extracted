package MARC::SubjectMap;

use strict;
use warnings;
use Carp qw( croak );
use MARC::Field;
use MARC::SubjectMap::XML qw( startTag endTag element comment );
use MARC::SubjectMap::Rules;
use MARC::SubjectMap::Handler;
use XML::SAX::ParserFactory;
use IO::File;

our $VERSION = '0.93';

=head1 NAME

MARC::SubjectMap - framework for translating subject headings

=head1 SYNOPSIS 

    use MARC::SubjectMap;
    my $map = MARC::SubjectMap->newFromConfig( "config.xml" );

    my $batch = MARC::Batch->new( 'USMARC', 'batch.dat' );
    while ( my $record = $batch->next() ) {
        my $new = $map->translateRecord( $record );
        ...
    }

=head1 DESCRIPTION

MARC::SubjectMap is a framework for providing translations of subject
headings. MARC::SubjectMap is essentially a configuration which contains
a list of fields/subfields to translate or copy, and a list of rules
for translating one field/subfield value into another.

Typical usage of the framework will be to use the C<subjmap-template>
command line application to generate a template XML configuration from a 
batch of MARC records. You tell C<subjmap-template> the fields you'd like
to translate and/or copy and it will look through the records and extract
and add rule templates for the unique values. For example:

    subjmap-template --in=marc.dat --out=config.xml --translate=650ab 

Once the template configuration has been filled in with translations,
the MARC batch file can be run through another command line utility called
C<subjmap> which will add new subject headings where possible using 
the configuration file. If a subject headings can't be translated it will be 
logged to a file so that the configuration file can be improved if necessary. 
    
    subjmap --in=marc.dat --out=new.dat --config=config.xml --log=log.txt

The idea is that all the configuration is done in the XML file, and the
command line programs take care of driving these modules for you. Methods
and related modules are listed below for the sake of completeness, and if
you want to write your own driving program for some reason.

=head1 METHODS

=head2 new()

The constructor which accepts no arguments.

=cut 

sub new {
    my ($class) = @_;
    my $self = { 
        fields          => [], 
        sourceLanguage  => '', 
        error           => '', 
        stats           => { recordsProcessed=>0, fieldsAdded=>0, errors=>0 } 
    };
    return bless $self, ref($class) || $class;
}

=head2 newFromConfig()

Factory method for creating a MARC::SubjectMap object from an XML 
configuration. If there is an error you will get it on STDERR.

    my $mapper = MARC::SubjectMap->new( 'config.xml' ); 

=cut

sub newFromConfig {
    my ($package,$file) = @_; 
    my $handler = MARC::SubjectMap::Handler->new();
    my $parser = XML::SAX::ParserFactory->parser( Handler => $handler );
    eval { $parser->parse_uri( $file ) };
    croak( "invalid configuration file: $file: $@" ) if $@;
    return $handler->config();
}

=head2 writeConfig()

Serializes the configuration to disk as XML.

=cut 

sub writeConfig {
    my ($self,$file) = @_;
    my $fh = IO::File->new( ">$file" ) 
        or croak( "unable to write to file $file: $! " );
    $self->toXML($fh);
}

=head2 addField()

Adds a field specification to the configuration. Each specification defines the
fields and subfields to look for and copy/translate in MARC data. The 
information is bundled up in a MARC::SubjectMap::Field object.

=cut 

sub addField {
    my ($self,$field) = @_;
    croak( "must supply MARC::SubjectMap::Field object" ) 
        if ref($field) ne 'MARC::SubjectMap::Field';
    push( @{ $self->{fields} }, $field );
}

=head2 fields()

Returns a list of MARC::SubjectMap::Field objects which specify the
fields/subfields in MARC data that will be copied and/or translated.

=cut 

sub fields {
    my ($self) = @_;
    return @{ $self->{fields} };
}

=head2 rules()

Get/set the rules being used in this configuration. You should pass
in a MARC::SubjectMap::Rules object if you are setting the rules.

    $map->rules( $rules );

The reason why a sepearte object is used to hold the Rules as opposed to the
fields being contained in the MARC::SubjectMap object is that there can be 
many (thousands perhaps) of rules -- which need to be stored differently than
the handful of fields. 

=cut

sub rules {
    my ($self,$rules) = @_;
    croak( "must supply MARC::SubjectMap::Rules object if setting rules" )
        if $rules and ref($rules) ne 'MARC::SubjectMap::Rules';
    $self->{rules} = $rules if $rules;
    return $self->{rules};
}

=head2 sourceLanguage()

Option for specifying the three digit language code to be expected in 
translation records. If a record is passed is translated that is not of the
expected source language then a log message will be generated.

=cut

sub sourceLanguage {
    my ($self,$lang) = @_;
    $self->{sourceLanguage} = $lang if defined $lang;
    return $self->{sourceLanguage};
}

=head2 translateRecord()

Accepts a MARC::Record object and returns a translated version of it
if there were any translations that could be performed. If no translations
were possible undef will be returned.

=cut

sub translateRecord {
    my ($self,$record) = @_;
    croak( "must supply MARC::Record object to translateRecord()" )
        if ! ref($record) or ! $record->isa( 'MARC::Record' );

    my $record_id = $record->field('001') ?  $record->field('001')->data() : '';
    $record_id =~ s/ +$//;

    $self->{stats}{recordsProcessed}++;

    ## log message if the record isn't the expected language
    if ( language($record) ne $self->sourceLanguage() ) {
        $self->log( sprintf( "record language=%s instead of %s",
            language($record), $self->sourceLanguage() ) );
    }

    ## create a copy of the record to add to
    my $clone = $record->clone();
    my $found = 0;

    # process each field that we need to look at
    foreach my $field ( $self->fields() ) { 

        my @marcFields = $record->field( $field->tag() );
        my $fieldCount = 0;

        foreach my $marcField ( @marcFields ) {
            $fieldCount++;

            # do the translation
            my $new = $self->translateField( $marcField, $field );
            my $error = $self->error();

            if ( $new ) { 
                $clone->insert_grouped_field($new);
                $self->{stats}{fieldsAdded}++;
                $found = 1;
                $self->log("record $record_id: translated \"" .
                    $marcField->as_string() . '" to "' . 
                    $new->as_string() . '"') ;
            } 
            elsif ( $error ) {
                $self->log("record $record_id: $error");
            }
            else {
                # the field didn't match subfield filters or
                # it only had copy actions and no translations
                # so we just continue along
            }
        }
    }
    return $clone if $found;
    return;
}

# you won't want to call this directly so there's no POD for it
# warning: subroutine that's longer than your console window alert
# TODO: break this up

sub translateField {
    # args are MARC::SubjectMap object, the MARC::Field to translate
    # and the MARC::SubjectMap::Field object which defines how we translate
    my ($self,$field,$fieldConfig) = @_;
    croak( "must supply MARC::Field object to translateField()" )
        if !ref($field) or !$field->isa('MARC::Field');
    croak( "must pass in MARC::SubjectMap::Field" ) 
        if !ref($fieldConfig) or !$fieldConfig->isa('MARC::SubjectMap::Field');

    # make sure error flag is undef
    $self->error( undef );

    ## subfields with subfield 2 already present are not translated
    if ($field->subfield(2)) {
        $self->error( "subfield 2 already present" );
        return;
    }

    ## don't bother translating if it doesn't meet indicator criteria
    ## no error set here since it really isn't an error just a filter
    my $indicator1 = $fieldConfig->indicator1();
    my $indicator2 = $fieldConfig->indicator2();
    return if defined $indicator1 and $indicator1 ne $field->indicator(1) ;
    return if defined $indicator2 and $indicator2 ne $field->indicator(2) ;

    ## these are subfields we can copy wholesale 
    my @copySubfields = $fieldConfig->copy();

    my (@subfields,%sources,$lastSource,$didTranslation);
    foreach my $subfield ( $field->subfields() ) {
        my ($subfieldCode,$subfieldValue) = @$subfield;

        ## remove trailing period if present
        $subfieldValue =~ s|\.$||;

        ## if we just copy this subfield lets do it and move on
        if ( grep /^$subfieldCode$/, @copySubfields ) {
            push( @subfields, $subfieldCode, $subfieldValue );
            next;
        }

        ## remove trailing whitespace since all rules have had their
        ## original , but remember it so we can add it
        ## back on to the translated subfield
        my $trailingSpaces = '';
        if ( $subfieldValue =~ /( +)$/ ) {
            $trailingSpaces = $1;
        }
        
        ## look up the rule!
        my $rule = $self->{rules}->getRule( 
            field       => $field->tag(),
            subfield    => $subfieldCode, 
            original    => $subfieldValue, );

        ## if we have a matching rule
        if ( $rule ) { 
           if ( $rule->translation() ) {
                $didTranslation = 1;
                push( @subfields, $subfieldCode, 
                    $rule->translation() . $trailingSpaces );
            } else {
                $self->{stats}{errors}++;
                $self->error("missing translation for rule: ".$rule->toString);
                return;
            }
    
            ## if a subfield a store away the source
            $sources{ $subfieldCode } = $rule->source();
            $lastSource = $rule->source();
        }

        ## uhoh we don't know what to do with this subfield
        else {
            $self->{stats}{errors}++;
            $self->error( 
                sprintf( 
                    'could not translate "%s" from %s $%s',
                    $subfieldValue, $field->tag(), $subfieldCode 
                )
            );
            return;
        }
    }

    ## if we didn't translate anything no need to make a new field
    ## note we dont' set an error message since this isn't really an error
    return if ! $didTranslation;

    ## if the last subfield doesn't end in a <.> or a <)> add a period
    $subfields[-1] .= '.' if ( $subfields[-1] !~ /[.)]/ );

    ## the configuration determines what subfield should have precedence
    ## in determining the source of the subfield.
    my $sourceSubfield = $fieldConfig->sourceSubfield();
    if ( exists $sources{ $sourceSubfield } ) {
        push( @subfields, '2', $sources{ $sourceSubfield } );
    } elsif ( defined $lastSource ) {
        push( @subfields, '2', $lastSource );
    } else {
        $self->{stats}{errors}++;
        $self->log( "missing source for new field: ".join('', @subfields ) );
    }
   
    return MARC::Field->new($field->tag(),$field->indicator(1),7,@subfields);
}

=head2 stats()

Returns a hash of statistics for conversions performed by a MARC::SubjectMap
object.

=cut

sub stats {
    return %{ shift->{stats} };
}

=head2 setLog()

Set a file to send diagnostic messages to. If unspecified messages will go to
STDERR. Alternatively you can pass in a IO::Handle object. 

=cut

## logging methods

sub setLog {
    my ($self,$f) = @_;
    if ( ref($f) ) {
        $self->{log} = $f; 
    } else {
        $self->{log} = IO::File->new( ">$f" );
    }
}

sub log {
    my ($self,$msg) = @_;
    $msg .= "\n";
    if ( $self->{log} ) {
        $self->{log}->print( $msg );
    } else {
        print STDERR $msg;
    }
}

# returns entire object as XML
# this is essentially the configuration
# since it can be big a filehandle must be passed in

sub toXML {
    my ($self,$fh) = @_;
    print $fh qq(<?xml version="1.0" encoding="ISO-8859-1"?>\n);
    print $fh startTag( "config" ),"\n\n";
    
    # language limiter if present
    my $lang = $self->sourceLanguage() || '';
    print $fh comment( "the original language" ), "\n";
    print $fh element( "sourceLanguage", $self->sourceLanguage() ), "\n\n";

    ## add fields
    print $fh comment( "the fields and subfields to be processed" )."\n";
    print $fh startTag( "fields" ), "\n\n";
    foreach my $field ( $self->fields() ) {
        print $fh $field->toXML(), "\n";
    }
    print $fh endTag( "fields" ), "\n\n";

    ## add rules
    if ( $self->rules() ) { 
        $self->rules()->toXML( $fh );
    }

    print $fh "\n", endTag( "config" ), "\n";
}

# helper to extract the language code from the 008

sub language {
    my $r = shift;
    my $f008 = $r->field('008');
    return '' if ! $f008;
    return substr( $f008->data(), 35, 3 );
}


# helper to store a single error message, not really for public use

sub error {
    my ($self,$msg) = @_;
    if ( $msg ) { $self->{error} = $msg; }
    return $self->{error};
}

sub DESTROY {
    my $self = shift;
    ## close log file handle if its open
    $self->{log}->close() if exists( $self->{log} ); 
}

=head1 SEE ALSO

=over 4 

=item * L<MARC::SubjectMap::Rules>

=item * L<MARC::SubjectMap::Rule>

=item * L<MARC::SubjectMap::Field>

=back

=head1 AUTHORS

=over 4

=item * Ed Summers <ehs@pobox.com>

=back

=cut

1;
