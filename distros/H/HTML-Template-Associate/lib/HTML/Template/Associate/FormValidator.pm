package HTML::Template::Associate::FormValidator;
use strict;

BEGIN {
	use Exporter ();
	require HTML::Template::Associate;
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = '2.01';
	@ISA         = qw ( HTML::Template::Associate Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

use constant CHECK_TYPE => 'Data::FormValidator::Results';
use constant ERROR_WRONG_TYPE => 'This class does not deal with that kind of result object'; 
use constant TMPL_PREFIX_VALID => 'VALID_';
use constant TMPL_PREFIX_MISSING => 'MISSING_';
use constant TMPL_PREFIX_INVALID => 'INVALID_';
use constant TMPL_PREFIX_UNKNOWN => 'UNKNOWN_';
use constant TMPL_PREFIX_MSGS => 'MSGS_';
use constant TMPL_POSTFIX_LOOP => 'FIELDS';
use constant METHOD_VALID => 'valid';
use constant METHOD_MISSING => 'missing';
use constant METHOD_INVALID => 'invalid';
use constant METHOD_UNKNOWN => 'unknown';
use constant METHOD_MSGS => 'msgs';
use constant TMPL_LOOP_FIELDNAME => 'FIELD_NAME';
use constant TMPL_LOOP_FIELDVALUE => 'FIELD_VALUE';

########################################### main pod documentation begin ##

=head1 NAME

	HTML::Template::Associate::FormValidator - HTML::Template::Associate Data::FormValidator plugin 

=head1 SYNOPSIS

	This class is not intended to be used directly but rather through a 
	HTML::Template::Associate. It provides concrete class functionality, it
	will take Data::FormValidator::Results object and reconstruct data structure
	to one appropriate for use by the HTML::Template. 
	
	use CGI qw/:standard/;
	use Data::FormValidator;
	use HTML::Template;
	use HTML::Template::Associate;
	
	my $cgi = CGI->new;
	#for testing purposes we can add some input to our cgi object
	$cgi->param( 'fullname', 'John Doe' );
	$cgi->param( 'phone', 6041112222 );
	$cgi->param( 'email', 'invalid@email' );
	
	my $input_profile = {
		optional => [ qw( company fax country ) ],
		required => [ qw( fullname phone email address city state zipcode ) ],
		constraints  => {
			email => 'email',
			fax => 'american_phone',
			phone => 'american_phone',
			zipcode	=> '/^\s*\d{5}(?:[-]\d{4})?\s*$/',
			state => "state",
		},
		defaults => { country => "Canada" },
		msgs => {
			prefix=> 'error_',
			missing => 'Not Here!',
			invalid => 'Problematic!',
			invalid_seperator => ' <br /> ',
			format => 'ERROR: %s',
			any_errors => 'some_errors',
		}
	};
	
	my $validator = Data::FormValidator->new;
	my $results = $validator->check ( scalar $cgi->Vars, $input_profile ); 
	
	my $associate = HTML::Template::Associate->new( {
		target => 'FormValidator', 
		results => $results,
		extra_arguments => [ $validator ] #not needed but just illustrated
	} ); 
	
	my $template = HTML::Template->new(
		filename => 'test.tmpl', 
		associate => [ $cgi, $associate ] 
	);
	
	print $template->output;
	
	#and in our test.tmpl file we could have
	
	Valid Fields:<br>
	<TMPL_LOOP NAME=VALID_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br> 
	</TMPL_LOOP>
	
	Missing Fields:<br>
	<TMPL_LOOP NAME=MISSING_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br> 
	</TMPL_LOOP>
	
	<TMPL_IF NAME=INVALID_phone>
	Phone: <TMPL_VAR NAME="phone"> you supplied is invalid.		
	</TMPL_IF>
	
	<TMPL_IF NAME=MISSING_city> 
	City name is missing, please fix this.
	</TMPL_IF>
	
	<!-- We can also access our normal field names 
	since $cgi object was passed as associate as well -->
	
	I think <TMPL_VAR NAME=country> is very big country. 
	
	<!-- Optional use of Data::FormValidator::Results msgs interface -->
	
	Message Fields:
	
	<TMPL_LOOP NAME=MSGS_FIELDS>
	Field Name: <TMPL_VAR NAME=FIELD_NAME><br>
	Field Value: <TMPL_VAR NAME=FIELD_VALUE><br>
	</TMPL_LOOP>
	
	<TMPL_IF NAME=MSGS_error_city>
	Our default error message set in the profiling code is: 
		<TMPL_VAR NAME=MSGS_error_city> 
	</TMPL_IF>

	The following will become available to your associate object/template:
	
	Key 	       /	            Perl		/ 	    Template
	
	Arrays / Loops
	
	VALID_FIELDS     / $associate->param(q{VALID_FIELDS});     / <TMPL_LOOP NAME=VALID_FIELDS>
	MISSING_FIELDS   / $associate->param(q{MISSING_FIELDS});   / <TMPL_LOOP NAME=MISSING_FIELDS>   
	INVALID_FIELDS   / $associate->param(q{INVALID_FIELDS});   / <TMPL_LOOP NAME=INVALID_FIELDS>
	UNKNOWN_FIELDS   / $associate->param(q{UNKNOWN_FIELDS});   / <TMPL_LOOP NAME=UNKNOWN_FIELDS>
	MSGS_FIELDS      / $associate->param(q{MSGS_FIELDS});      / <TMPL_LOOP NAME=MSGS_FIELDS>
	
	Variables  
	
	VALID_ParamA       / $associate->param(q{VALID_ParamA});       / <TMPL_VAR NAME=VALID_ParamA>
	MISSING_ParamB     / $associate->param(q{MISSING_ParamB});     / <TMPL_VAR NAME=MISSING_ParamB>
	INVALID_ParamC     / $associate->param(q{INVALID_ParamC});     / <TMPL_VAR NAME=INVALID_ParamC>
	UNKNOWN_ParamD     / $associate->param(q{UNKNOWN_ParamD});     / <TMPL_VAR NAME=UNKNOWN_ParamD>
	MSGS_prefix_ParamE / $associate->param(q{MSGS_prefix_ParamE}); / <TMPL_VAR NAME=MSGS_prefix_ParamE> 
	
	Inside Array / Loops we have the following structure:
	
	Perl
	
	VALID_FIELDS => [ { FIELD_NAME => X }, FIELD_VALUE => Y }, ... ]
	
	Template
	
	<TMPL_LOOP NAME=VALID_FIELDS>
	<TMPL_VAR NAME=FIELD_NAME> 
	<TMPL_VAR NAME=FIELD_VALUE>     
	</TMPL_LOOP>   
	
	For further explanation on what the VALID,MISSING,INVALID,UNKNOWN AND MSGS are
	please refer to Data::FormValidator::Results. Please note that MSGS 
	works somewhat diffrently then others and corresponds to $results->msgs([$config])
	interface.  

=head1 DESCRIPTION

	Map Data::FormValidator::Results object into a form suitable for use by HTML::Template

=head1 USAGE

	See above.

=head1 BUGS

	If you find any please report to author.

=head1 SUPPORT

	See License.

=head1 AUTHOR

	Alex Pavlovic
	alex.pavlovic@taskforce-1.com
	http://www.taskforce-1.com

=head1 COPYRIGHT

	This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.
	
	The full text of the license can be found in the
	LICENSE file included with this module.


=head1 SEE ALSO

	HTML::Template::Associate HTML::Template::Associate::DBI perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 init

	Usage     : $associate->init ( $results, $extra_arguments );
	Purpose   : Initiliazes the object
	Returns   : concrete object instance
	Argument  : Data::FormValidator::Results instance and extra hash of arguments passed to factory 
	Comments  : Factory class will call this method automatically during concrete object construction
		: Error is thrown depending whether the passed in results object is of correct type

	See Also   : HTML::Template::Associate Data::FormValidator::Results  

=cut

################################################## subroutine header end ##


sub init {
	my ( $self, $params ) = @_;
	my $results = $params->{results};
	$self->error ( ERROR_WRONG_TYPE ) unless $results->isa(CHECK_TYPE);  
	$self->runloop ( $results, METHOD_VALID, TMPL_PREFIX_VALID );
	$self->runloop ( $results, METHOD_MISSING, TMPL_PREFIX_MISSING ) if $results->has_missing; 
 	$self->runloop ( $results, METHOD_INVALID, TMPL_PREFIX_INVALID ) if $results->has_invalid;
	$self->runloop ( $results, METHOD_UNKNOWN, TMPL_PREFIX_UNKNOWN ) if $results->has_unknown;
	$self->runloop ( $results, METHOD_MSGS, TMPL_PREFIX_MSGS ) if keys %{$results->msgs};
	return $self;                          
}

################################################ subroutine header begin ##

=head2 runloop

	Usage     : used internally to assign various prefixes/names to variables and loops  

=cut

################################################## subroutine header end ##

sub runloop {
	my ( $self, $results, $method, $field_prefix ) = @_;
	my @fields = ref $results->$method eq q{ARRAY} ? 
		@{ $results->$method } : keys %{ $results->$method };	
	for my $field ( @fields ) {
		my $field_value = ref $results->$method eq q{ARRAY} ? 
			$results->$method ( $field ) : $results->$method->{$field};
			
		$field_value = ref $field_value eq q{ARRAY} ? 
			join q{,}, @$field_value : $field_value;
			
       	$self->param ( $field_prefix . $field, $field_value );
		my $loop_name = $field_prefix . TMPL_POSTFIX_LOOP;
		push @{ $self->{PARAMS}->{$loop_name} }, { 
			&TMPL_LOOP_FIELDNAME => $field,
			&TMPL_LOOP_FIELDVALUE => $field_value 
		};   
	}
	return $self;
}

1; #this line is important and will help the module return a true value
__END__
