package MARC::SubjectMap::Rules;

use strict;
use warnings;
use BerkeleyDB;
use File::Temp qw( tempfile );
use Storable qw( freeze thaw );
use MARC::SubjectMap::XML qw( startTag endTag comment );
use Carp qw( croak );

=head1 NAME

MARC::SubjectMap::Rules - storage for rules

=head1 SYNOPSIS

    my $rules = MARC::SubjectMap->new();
    $rules->addRule( $rule );

=head1 DESCRIPTION

Since there may be a very large set of translation rules in a given
configuration the MARC::SubjectMap::Rules class allows the rules and lookup
tables to stored on disk rather than memory.

=head1 METHODS

=head2 new()

Create rule storage.

=cut

sub new {
    my ($class) = @_;
    my ($fh,$filename) = tempfile(); 
    #tie my %storage, 'DB_File', $filename, O_RDWR|O_CREAT, 0666, $DB_BTREE;
    tie my %storage, 'BerkeleyDB::Btree';
    return bless { rules => \%storage }, ref($class) || $class; 
}

=head2 addRule()

Add a rule to the rules storage. A rule must be a MARC::SubjectMap::Rule
object.

    $rules->addRule( $rule );

=cut

sub addRule {
    my ($self,$rule) = @_;
    croak( "must supply MARC::SubjectMap::Rule object" )
        if ref($rule) ne 'MARC::SubjectMap::Rule'; 
    croak( "MARC::SubjectMap::Rule lacks field attribute" )
        if ! $rule->field();
    croak( "MARC::SubjectMap::Rule lacks subfield attribute" )
        if ! $rule->subfield();
    croak( "MARC::SubjectMap::Rule lacks original attribute" )
        if ! $rule->original();
    
    # make key for storage
    my $key = join ('-',$rule->original(),$rule->field(),$rule->subfield());

    # add the rule
    $self->{rules}{$key} = freeze($rule);
}

=head2 getRule()

Look up a rule in storage using the field, subfield and original text.
If no rule is found you will be returned undef.
    
    my $rule = $rules->getRule( field => '600', subfield => 'a', 
        original => 'Africa' );

=cut

sub getRule {
    my ($self,%args) = @_;
    croak( "must supply field parameter" ) if ! exists $args{field};
    croak( "must supply subfield parameter" ) if ! exists $args{subfield};
    croak( "must supply original parameter" ) if ! exists $args{original};
    my $key = join('-',$args{original},$args{field},$args{subfield});
    return unless exists( $self->{rules}{$key} );
    return thaw($self->{rules}{$key});
}

## there can be lots of rules so this takes a filehandle

sub toXML {
    my ($self,$fh) = @_;
    print $fh comment( "the rule mappings themselves" ), "\n";
    print $fh startTag( "rules" ), "\n\n";
    while ( my($k,$v) = each(%{$self->{rules}}) ) {
        my $rule = thaw($v);
        print $fh $rule->toXML(), "\n";
    }
    print $fh endTag( "rules" ), "\n";
}

1;
