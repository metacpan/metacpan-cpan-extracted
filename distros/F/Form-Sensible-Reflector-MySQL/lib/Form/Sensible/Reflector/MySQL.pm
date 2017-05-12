use strict;
use warnings;

package Form::Sensible::Reflector::MySQL;
our $VERSION = 0.2;

=head1 NAME

Form::Sensible::Reflector::MySQL - Create a Form::Sensible object from a MySQL schema

=head1 SYNOPSIS

	use Form::Sensible;
	use Form::Sensible::Reflector::MySQL;
	my $reflector = ReflectorMySQL->new();
	my $form  = $reflector->reflect_from($dbh, 
		{
			form_name => $table_name,
			information_schema_dbh => DBI->connect(
				'DBI:mysql:database=information_schema;host=localhost', 'root', 'password',
			),
			# populate => 1,
			# only_columns => [qw[ id forename surname dob ] ],
		}
	);
	$form->add_field(
		Form::Sensible::Field::Toggle->new( 
			name => 'Submit form',
		)
	);
	my $renderer = Form::Sensible->get_renderer('HTML');
	my $html     = $renderer->render($form)->complete;
	exit;

=head1 DESCRIPTION

This module provides to L<Form::Sensible|Form::Sensible> the ability to simply
create from MySQL tables forms whose fields and validators reflect the schema of
the database table. Forms can be created empty, or from the value of 
a specified row. Joins are not supported.

=head2 ALPHA SOFTWARE

This module is to be considered a pre-release, to gather test feedback
and suggestions. It should not be considered stable for a production
environment, and its implementation is subject to change.

Specifically, type checking of large numberics (specifically doubles) 
is not well tested, and C<Select> fields (for C<ENUM> and C<SET>) 
seems to require some updating of C<Form::Sensible> itself.

=head2 REPRESENTATION OF THE SCHEMA

=head3 FIELD NAMES

Field names are taken from column names, or can be taken from column comments
(see L</information_schema_dbh> under L</reflect_form>).

=head3 REQUIRED FIELDS

Fields are marked as required if their database definition contains C<NOT NULL>.

=head3 DEFAULT VALUES

Default values are, by default, taken from the database - see L</no_db_defaults>, below L</reflect_from>.

=head3 FIELD TYPES

String and numeric types are mapped to the appropriate L<Form::Sensible::Field> types, with the 
exceptions described below. 

B<NB> Numeric fields may only contain numbers with decimal points (C<.>) but not commas.
This outght to be locale dependant, but as far as I can tell, MySQL only accepts data in this format
(L<http://dev.mysql.com/doc/refman/5.0/en/locale-support.html|http://dev.mysql.com/doc/refman/5.0/en/locale-support.html>).

=head4 ENUM AND SET

Set and enumeration columns are rendered as C<Select> fields. 

=head4 BOOLEAN TYPES

Boolean fields (L<Form::Sensible::Field::Toggle|Form::Sensible::Field::Toggle>) are expected
to be defined in the SQL schema as C<BIT(1)> columns, based on the rationale outlined in
comments on the MySQL website 
(L<http://dev.mysql.com/doc/refman/5.0/en/numeric-types.html>). 

B<NB> This is in contradiction to the MySQL behaviour of interpreting the declaration of
C<BOOLEAN> columns as C<TINYINT(1)>. Support for the latter could be added as a C<Toggle> field,
but what would a C<NULL> entry signfiy?

The generated L<Form::Sensible::Field::Toggle> has C<on_value> an C<off_value> of C<1> an C<0>, respectively.

=head4 BLOB-TYPE COLUMNS

These are currently converted to C<Text> and C<LongText> fields. That can of course be changed
by the user after the form as been created, but I am open to suggestions on how to better handle them.

=head4 TRIGGER

No L<Form::Sensible::Field::Trigger|Form::Sensible::Field::Trigger> is added to the form.
See L<the SYNOPSIS|SYNOPSIS>, above.

=head2 INTERNATIONALISATION

See C<lang> under L</reflect_from>.

=head1 METHODS

=head2 reflect_form

	ReflectorMySQL->new->reflect_from( $dbh, $options );

Creates a form from a MySQL table schema, optionally populating it 
with data from the table.

In the above example, C<$dbh> is a connected database handle, and
C<$options> a reference to a hash as follows:
	
=over 4

=item form_name

In keeping with L<Form::Sensible::Reflector|Form::Sensible::Reflector>,
this field can hold the name of the table, though that will be over-ridden
by any value in C<table_name>.

=item table_name

The name of the table upon which to reflect, if not supplied in C<form_name>.

=item no_db_defaults

Optinal. If a true value, will cancel the default behaviour of populating
the empty form with any C<DEFAULT> values set in the schema (aside from C<CURRENT_TIMESTAMP>.

=item only_columns

An anonymous list of the names of columns to use, to override the default behaviour
of using all columns.

=item populate

Optional. If supplied, causes the created form to be populated with data from 
a row in the table. The value of C<populate> should be a reference to a hash that
defines column names and values to be used in the selection of a record. 
No error checking is performed.

=item information_schema_dbh

Optional DBH connected to the C<information_schema> database.
If supplied, each field's C<display_name> will be set from the C<COMMENT>
recorded in the table definition, if available.

Field comments are created thus:

	CREATE TABLE foo (  
		forename VARCHAR(255) NOT NULL COMMENT 'First name'  
	)

	ALTER TABLE foo CHANGE COLUMN forename  
		forename VARCHAR(255) NOT NULL COMMENT 'Forename'  

Comments can be viewed with C<SHOW CREATE foo> or as follows:

	mysql5> USE information_schema;
	mysql5> SELECT column_name, column_comment FROM COLUMNS WHERE table_name='foo';  
	
Should L<Form::Sensible::Form|Form::Sensible::Form> one day support a C<display_name> attribute,
this method could supply it with the table's C<COMMENT>: at present, that value is stored in
the C<form_display_name> field of the caller.

=item lang

Defines the language of error messages that are not over-rideable using
the default means supplied by C<Form::Sensible>. The format should be that
used by HTML, as described at L<http://www.w3.org/International/articles/language-tags/>,
without hyphenation. 

The default language is C<enGB>. To use another language, supply another string,
and use it to create a namespace such as C<Form::Sensible::Reflector::MySQL::I18N::enGB>
that contains hash reference called C<$I18N>. Please see the bottom of this file's
source code for the required keys.

=back

=cut

use Form::Sensible 0.20012;
use Form::Sensible::Form;
use Form::Sensible::Field;
use Form::Sensible::Field::Trigger;
use DBI;
use DateTime::Format::MySQL;
use Carp;

=head1 EXPORTS

None.

=cut

# I'd not choose to use Moose on CPAN, or in a module with such a tiny API,
# but the other modules in the parent namespace do, so it is only polite
# to make a bit of an effort:
use Moose;

extends 'Form::Sensible::Reflector';

has 'accepts_multiple'	=> ( is => 'rw',  isa => 'HashRef', init_arg => undef ); 
has 'values' => ( is => 'rw', isa => 'HashRef', init_arg => undef );
has 'defaults' => ( is => 'rw', isa => 'HashRef', init_arg => undef );
has 'no_db_defaults' => ( is => 'rw', isa => 'Bool', init_arg => undef );
has 'table_metadata' => ( is => 'rw', isa => 'HashRef', init_arg => undef );
has 'only_columns' => (is => 'rw', isa => 'HashRef', init_arg => {} );
has 'i18n' => (is => 'rw', isa => 'HashRef', init_arg => {} );
has 'form_display_name' => (is => 'rw', isa => 'Str', init_arg => undef );

__PACKAGE__->meta->make_immutable;

our $NUMBER_RE = qr/^-?\d+(\.\d+)?$/;


# use Log4perl if we have it, otherwise stub:
# See Log::Log4perl::FAQ
BEGIN {
	eval { require Log::Log4perl; };

	# No Log4perl, so hide calls to it: see Log4perl FAQ
	if ($@) {
		no strict qw"refs";
		*{__PACKAGE__."::$_"} = sub { } for qw(TRACE DEBUG INFO WARN ERROR FATAL);
		*{__PACKAGE__."::LOGCONFESS"} = sub { confess @_ };
	}

	# Setup log4perl
	else {
		no warnings;
		no strict qw"refs";
		require Log::Log4perl::Level;
		Log::Log4perl::Level->import(__PACKAGE__);
		Log::Log4perl->import(":easy");
		# Add calls to present in early versions
		if ($Log::Log4perl::VERSION < 1.11){ 
			*{__PACKAGE__."::TRACE"} = *DEBUG;
		}
	}
}


# $options->{populate} = { id1 => value1, idN => valueN }
# Validity of supplied column names is not checked.
sub reflect_from {
	my ($self, $dbh, $options) = @_;
	
	$options->{form_name} = $options->{table_name} if exists $options->{table_name};
	
	# See http://www.w3.org/International/articles/language-tags/
	if (not $options->{lang}){ 
		$options->{lang} = 'enGB';
	}
	else {
		$options->{lang} =~ tr{-}{}s;
	}
	
	my $i18n = 'Form::Sensible::Reflector::MySQL::I18N::' . $options->{lang} ; # .'.pm';
	eval "require ".$i18n;
	$self->i18n( 
		eval '$'.$i18n.'::I18N'
	);
		
	$self->no_db_defaults( 
		(exists $options->{no_db_defaults} and $options->{no_db_defaults})? 1 : 0
	);
	
	$self->values( {} );
	$self->defaults( {} );
	$self->only_columns( 
		$options->{only_columns}? {
			map { $_=>1 } @{ $options->{only_columns} }
		} : {}
	);

	my $form = $self->SUPER::reflect_from( $dbh, $options );

	my $row;	
	if (exists $options->{populate}){
		LOGCONFESS "options->{populate} must be a hash of column/values used in the WHERE clause of the SELECT statement that populates the form"
		if not ref $options->{populate} or ref $options->{populate} ne 'HASH';
			
		my $cols = scalar keys %{$self->only_columns}? 
			join(',', map {'`'.$_.'`'} @{$options->{only_columns}})
			:	'*';

		my $sql = join' ', 'SELECT', $cols, 'FROM',  
			'`' .$form->{name}.'`',
			'WHERE',
			join(
				' AND ',
				map { 
					'`'.$_ .'`='. $dbh->quote( $options->{populate}->{$_} ) 
				} keys %{$options->{populate}}
			);
		DEBUG $sql;
		$row = $dbh->selectrow_hashref( $sql );
		# DEBUG Dumper $row;
		undef $row if scalar keys %$row == 0; 
	}

	for my $field ($form->get_fields){
		next if $field->field_type eq 'trigger';
		
		# Set selectable values for sets and enumerations:
		if (exists $self->values->{ $field->name }){ 
			$field->add_option( $_ => $_ ) 
				foreach @{ $self->values->{$field->name } };
		}
		
		# Allow sets to have more than one value:
		if (exists $self->{accepts_multiple}->{$field->name} ){
			$field->accepts_multiple(1);
		}
		
		# DB defaults:
		if ( $self->defaults->{ $field->name } ){
			$field->value( $self->defaults->{ $field->name } );
		}

		# Select fields (ENUM, SET) are a special case
		if ($field->{field_type} eq 'select'){
			my @s = exists( $self->accepts_multiple->{$field->name} )?
				split(/,/,$self->{values}->{$field->name})
				:	$self->{values}->{ $field->name };
		}
		
		# Populate?
		if (defined $row){
			if (exists $self->{values}->{ $field->name }){ 
				if ($field->{field_type} eq 'select'){
					my @s = exists( $self->{accepts_multiple}->{$field->name} )?
						split(/,/,$row->{$field->name})
					:	$row->{ $field->name };
					# Bug in Form::Sensible Select object - requires values
					$field->value( @s ) if not defined $field->value;
					eval { $field->set_selection( @s ) if @s; };
				}
			}
			else {
				$field->value( $row->{$field->name} );
			}	
		}
	} # Next field
	
	# Connect to the inforation schema to try to get column comments
	if (exists $options->{information_schema_dbh}){
		my $column_comments = $options->{information_schema_dbh}->selectall_hashref(
			"SELECT column_name, column_comment FROM COLUMNS WHERE table_name=?",
			'column_name',
			{}, 
			$form->{name}
		);
		foreach my $i (keys %$column_comments){
			next if not length $column_comments->{$i}->{column_comment};
			next if scalar keys %{$self->only_columns}
				and not $self->only_columns->{$form->field($i)->name};
			# column_name , column_comment    
			next if not defined $column_comments->{ $form->field( $i )->name };
			$form->field( $i )->display_name(
				$column_comments->{ $form->field( $i )->name }->{column_comment}
			);
		}
		# form display name:
		my $n =  $options->{information_schema_dbh}->selectrow_array(
			"SELECT table_comment FROM TABLES WHERE table_name=?",
			{}, 
			$form->{name}
		);
		# See http://www.cpantesters.org/cpan/report/921265d4-5157-11e0-9084-0c635704ce1c
		# ; InnoDB free: 52224 kB
		$n =~ s/;\sInnoDB\sfree:\s\d+\s.B$//;
		$self->form_display_name( $n );
	}
	
	return $form;
}


=head2 get_fieldnames

Private method inherited from L<Form::Sensible::Reflector|Form::Sensible::Reflector>.

=cut

sub get_fieldnames {
	my ($self, $form, $dbh) = @_;

	# Make sure a table name was supplied	
	LOGCONFESS "Argument one, the form object, should contain a name that represents the name of the table to reflect" 
		if not defined $form->{name};
	
	# Collect and store metadata from MySQL
	$self->{table_metadata}->{ $form->{name} } = 
		$dbh->selectall_hashref(
			'describe `' . $form->{name} .'`',
			'Field'
		);

	my @rv;
	if ( scalar keys %{ $self->{only_columns} } ){
		@rv = grep { 
				exists $self->{only_columns}->{$_} 
			} keys %{ $self->{table_metadata}->{ $form->{name} } };
	}
	else {
		@rv =  keys %{ $self->{table_metadata}->{ $form->{name} } };
	}
	
	return @rv;
}


# Should numbers be allowed to contain commas?
sub get_field_definition { 
	my ($self, $form, $dbh, $fieldname) = @_;
	my $mysql_type = $self->{table_metadata}->{ $form->{name} }->{$fieldname}->{Type};
	DEBUG $fieldname .': '.$mysql_type;
	my $f = { 
		name => $fieldname,
		field_class => 'Number'
	};

	# db defaults - not no_db_defaults
	if ( not( $self->no_db_defaults )
		and $self->{table_metadata}->{ $form->{name} }->{$fieldname}->{Default}
		and $mysql_type ne 'timestamp' # avoid a value of CURRENT_TIMESTAMP
	){
		$self->{defaults}->{$fieldname} =
			$self->{table_metadata}->{ $form->{name} }->{$fieldname}->{Default};
		DEBUG "Set $fieldname to default ", $self->{defaults}->{$fieldname};
	}

	# Numeric types - http://dev.mysql.com/doc/refman/5.0/en/numeric-types.html
	# NB display width with zero-padding for INT(M) -
	# Cf http://alexander.kirk.at/2007/08/24/what-does-size-in-intsize-of-mysql-mean/
	if ($mysql_type =~ /^tinyint/){
		$f->{integer_only} = 1;
		$f->{lower_bound} = $mysql_type =~ /unsigned/? 0 : -128;
		$f->{upper_bound} = $mysql_type =~ /unsigned/? 255 : 127;
	}
	elsif ($mysql_type =~ /^smallint/){
		$f->{integer_only} = 1;
		$f->{lower_bound} = $mysql_type =~ /unsigned/? 0 : -32768;
		$f->{upper_bound} = $mysql_type =~ /unsigned/? 65535 : 32767;
	}
	elsif ($mysql_type =~ /^mediumint/){
		$f->{integer_only} = 1;
		$f->{lower_bound} = $mysql_type =~ /unsigned/? 0 : -8388608;
		$f->{upper_bound} = $mysql_type =~ /unsigned/? 16777215 : 8388607;
	}
	elsif ($mysql_type =~ /^int/){
		$f->{integer_only} = 1;
		$f->{lower_bound} = $mysql_type =~ /unsigned/? 0 : -2147483648;
		$f->{upper_bound} = $mysql_type =~ /unsigned/? 4294967295 : 2147483647;
	}
	
	# Treat massive integers as strings or nothing works
	elsif ($mysql_type =~ /^bigint/){
		$f->{field_type} = 'Text';
		$f->{validation} = { code => $mysql_type =~ /unsigned/ ?
			sub { 
				use Math::BigInt;
				my $n = Math::BigInt->new( $_[0] );
				# return '_FIELDNAME_ is an invalid unsigned big integer' if $n eq 'NaN';
				return $self->i18n->{ubigint}->{nan} if $n eq 'NaN';
				return $self->i18n->{ubigint}->{not_int} if not $n->is_int;
				return $self->i18n->{ubigint}->{too_high} if $n > 8446744073709551615;
				return $self->i18n->{ubigint}->{too_low} if $n < 0;
				return 0;
			}
		:	sub { 
				use Math::BigInt ':constant';
				my $n = Math::BigInt->new( $_[0] );
				return $self->i18n->{sbigint}->{nan} if $n eq 'NaN';
				return $self->i18n->{sbigint}->{not_int} if not $n->is_int;
				return $self->i18n->{sbigint}->{too_high} if $n > 9223372036854775807;
				return $self->i18n->{sbigint}->{too_low} if $n < -9223372036854775808;
				return 0;
			}
		};
	}

	elsif ($mysql_type =~ /^(double|real)/){
		$f->{field_type} = 'Text';
		$f->{validation} = { code => sub {
				use Math::BigFloat ':constant';
				my $n = Math::BigFloat->new( $_[0] );
				return $self->i18n->{double}->{nan} if $n eq 'NaN';
				return $self->i18n->{double}->{oob}
					if ($n <= -1.7976931348623157E+308 and $n >= -2.2250738585072014E-308)
						or $n== 0
						or ($n <= 2.2250738585072014E-308 and $n >= 1.7976931348623157E+3080);
				return 0;
			}
		};
	}
	
	elsif ($mysql_type =~ /^(decimal|numeric) (?: \((\d+) (?:,(\d+))? \) )?$/x ){
		my ($m, $d) = ($2, $3);
		# $m apprently includes the decimal point:
		$m = 0 if $m < 0;
		$m ||= 65; # But not in 5.0.3-5.0.5, when is 64
		$d ||= 0;
		$f->{field_type} = 'Text';
		$f->{validation} = { code => sub {
				# Naively assume it's a nice decimal/number
				my ($mym, $myd) = $_[0] =~ /^(\d+) (?: \. (\d+) )?$/x;
				$mym ||= 0; 
				$myd ||= 0;
				return $self->i18n->{decimal}->{nan}
					if not $mym and not $myd and $_[0] !~ /^0*(\.0+)?$/x;
				return $self->i18n->{decimal}->{too_long}.$m
					if (length($mym) + length($myd)) > $m;
				return $self->i18n->{decimal}->{post_point}.$d
					if length($myd) > $d;
				return 0;
			}
		};
	}
	
	# Floating-Point (Approximate-Value) Types
	# Defaut range desc at http://help.scibit.com/mascon/masconMySQL_Field_Types.html
	# and Fixed-Point (Exact-Value) Types 		
	elsif ($mysql_type =~ /^(float|double precision)/){
		my ($d, $e);

		if ($mysql_type =~ /\((\d+),(\d+)\)/){
			($d, $e) = ($1, $2);
		}
		elsif ( $mysql_type =~ /^(numeric|decimal)(\((\d+)\))?/	){
			($d, $e) = ($2, undef);
		}
		
		if (defined $d){
			my $valid_re = $e?
			qr/^-?\d{1,$d}(\.\d{0,$e})?$/
			: qr/^-?\d{1,$d}$/;
			$f->{validation} = {
				code => sub { 
					return $self->i18n->{float}->{nan} unless $_[0] =~ $NUMBER_RE;
					return $self->i18n->{float}->{invalid}.$d if $_[0] !~ $valid_re;
					return 0;
				}
			};
			my $max = '9' x $d;
			$max .= '.' . ('9' x $e) if $e;
			$f->{upper_bound} = $max;
			if ($mysql_type =~ /unsigned/){
				$f->{lower_bound} = 0;				
			} else {
				$f->{lower_bound} = - $max;
			}
		}
		
		# No bounds
		else {
			my $sub;
			if ($mysql_type eq 'double'){
				$sub = sub {
					use Math::BigFloat ':constant';
					my $n = Math::BigFloat->new( $_[0] );
					return $self->i18n->{float}->{nan}  if $n->is_nan;
					return $self->i18n->{float}->{oob}  if not(
						($n < -1.7976931348623157E+308 
						and $n > -2.2250738585072014E-308
						) or $n==0 
						or (
						$n >= 2.2250738585072014E-308
							and $n <= 1.7976931348623157E+308
						)
					);
				}
			}
			else {
				$sub = sub {
					use Math::BigFloat ':constant';
					my $n = Math::BigFloat->new( $_[0] );
					return $self->i18n->{float}->{nan}  if $n->is_nan;
					return $self->i18n->{float}->{oob} if (
						$n >= -340282346600000016151267322115014000640.000000
						and $n <= -0.000000000000000000000000000000000000011754943510
					) 
					or $n == 0 
					or ($n >= 0.000000000000000000000000000000000000011754943510
						and $n <= 340282346600000016151267322115014000640.000000
					)
				}
			}
			$f->{validation} = { 
				code => $sub,
			};
		}
	}
	
	
	# BIT(1) == a true boolean == Toggle field boolean
	elsif ($mysql_type =~ /^bit\(1\)/){
		$f->{field_class} = 'Toggle';
		$f->{validation} = { 
			code => sub { 
				return $self->i18n->{bit1}->{oob} if $_[0] !~ qr/^[10]$/  
			},
		};
		$f->{on_value} = 1;
		$f->{off_value} = 0;
	}
	
	# Any other bit type
	elsif ($mysql_type =~ /^bit\((\d+)\)/){
		my $len = $1;
		$f->{maximum_length} = $len;
		my $min = $mysql_type =~ /not null/gi? 1 : 0;
		my $re = qr/^[10]{$min,$len}$/;
		$f->{field_class} = 'Text'; # to ignore numeric checks and skip to custom
		$f->{validation} = { 
			code => sub { 
				return $self->i18n->{bits}->{invalid}.$len
					if $_[0] !~ $re;
				return 0;
			},
		};
	}
	
	# Date/times
	elsif ($mysql_type =~ /datetime$/ ){
		$f->{field_class} = 'Text';
		$f->{validation} = { 
			code => sub {
				return $self->i18n->{datetime}->{year_length} if  $_[0] !~ /^(\d{4})/;
				return $self->i18n->{datetime}->{year_oob} if $1 < 1001;
				eval { DateTime::Format::MySQL->parse_datetime( $_[0] ) };
				return $self->i18n->{datetime}->{parser_error_prefix}.$@ || 0;
			},
		};
	}
	elsif ($mysql_type =~ /timestamp/ ){
		$f->{field_class} = 'Text';
		$f->{validation} = { 
			code => sub {
				return $self->i18n->{timestamp}->{year_length} if $_[0] !~ /^(\d{4})/;
				return $self->i18n->{timestamp}->{year_oob} if $1 < 1001;
				eval { DateTime::Format::MySQL->parse_timestamp( $_[0] ) };
				return $self->i18n->{timestamp}->{parser_error_prefix} . $@ 
					|| 0;
			},
		};
	}
	elsif ($mysql_type eq 'date'){
		$f->{field_class} = 'Text';
		$f->{validation} = { 
			code => sub {
				return $self->i18n->{date}->{year_length} if $_[0] !~ /^(\d{4})/;
				return $self->i18n->{date}->{year_oob} if $1 < 1001;
				eval { DateTime::Format::MySQL->parse_date( $_[0] ) };
				return $self->i18n->{date}->{parser_error_prefix}.$@ 
					|| 0;
			},
		};
	}
	elsif ($mysql_type eq 'time'){
		$f->{field_class} = 'Text';
		$f->{maximum_length} = 8;
		$f->{validation} = { 
			code => sub {
				return $self->i18n->{time}->{invalid} 
					if $_[0] !~ qr/^(\d{2})[-_":\/*,.](\d{2})[-_":\/*,.](\d{2})$/;
				return  $self->i18n->{time}->{hours} if $1 < 0 or $1 > 23;
				return  $self->i18n->{time}->{minutes} if $1 < 0 or $2 > 59;
				return  $self->i18n->{time}->{seconds} if $1 < 0 or $3 > 59;
			}
		};
	}
	elsif ($mysql_type =~ /year/){
		$f->{field_class} = 'Text';
		$f->{validation} = { 
			code => sub {
				if ($mysql_type =~ /year\(4\)/){
					return $self->i18n->{year4}->{oob} 
						if $_[0] !~ qr/^\d{4}$/ or $_[0] < 1901 or $_[0] > 2155;
					return 0;
				}
				else {
					return $self->i18n->{year}->{oob} if $_[0] !~ qr/^\d{2}$/;	
					return 0;
				}
			},
		};
	}
	
	# String types - decimal values from http://www.htmlite.com/mysql003.php
	elsif ($mysql_type =~ /^(var)?char\((\d+)\)$/ ){
		$f->{field_class} = 'Text';
		$f->{maximum_length} = $2;
	}
	elsif ($mysql_type eq 'tinytext' ){
		$f->{field_class} = 'Text';
		$f->{maximum_length} = 255;
	}
	elsif ($mysql_type eq 'text' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 65535;
	}
	elsif ($mysql_type eq 'mediumtext' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 16777215;
	}
	elsif ($mysql_type eq 'longtext' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 4294967295;
	}

	# length() works on characters unless 'use bytes'
	elsif ($mysql_type =~ /^(var)?binary\((\d+)\)$/  ){
		$f->{field_class} = 'Text';
		my ($len) = $2;
		$f->{validation} = { code => sub { 
			use bytes; 
			return 0 if length $_[0] <= $len; 
			return $self->i18n->{binary}->{too_long} . $len;
		} };
	}
	elsif ($mysql_type eq 'tinyblob' ){
		$f->{field_class} = 'Text';
		$f->{validation} = { code => sub { 
			use bytes; 
			return 0 if length $_[0] <= 255; 
			return $self->i18n->{tinyblob}->{too_long};
		} };
	}
	elsif ($mysql_type eq 'blob' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 65535;
		$f->{validation} = { code => sub { 
			use bytes; 
			return 0 if length $_[0] <= 65535; 
			return $self->i18n->{blob}->{too_long};
		} };
	}
	elsif ($mysql_type eq 'mediumblob' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 16777215;
		$f->{validation} = { code => sub { 
			use bytes; 
			return 0 if length $_[0] <= 16777215; 
			return $self->i18n->{mediumblob}->{too_long};
		} };
	}
	elsif ($mysql_type eq 'longblob' ){
		$f->{field_class} = 'LongText';
		$f->{maximum_length} = 4294967295;
		$f->{validation} = { code => sub { 
			use bytes; 
			return 0 if length $_[0] <= 4294967295; 
			return $self->i18n->{longblob}->{too_long};
		} };
	}
	
	# ENUM
	elsif ($mysql_type =~ /^enum\((.*?)\)$/){
		$f->{field_class} = 'Select';
		my @re;
		my $vs = $1 .',';
		foreach my $i (split /',/, $vs){
			# Bug in Form::Sensible Select object 
			# - requires values - Can't add values here, no objects to which to add
			push @{ $self->{values}->{$fieldname} }, substr $i, 1; 
			push @re, quotemeta( substr($i,1) );	
		}
		my $re = join '|', @re;
		$f->{validation} = { 
			regex => qr/^($re)$/i 
		};
	}

	# SET http://dev.mysql.com/doc/refman/5.0/en/set.html
	# Value must contain one or more values from the SET
	elsif ($mysql_type =~ /^set\((.*?)\)$/){
		$f->{field_class} = 'Select';
		$self->{accepts_multiple}->{$fieldname} = 1; 
		my @re;
		my $vs = $1 .',';
		foreach my $i (split /',/, $vs){
			# Bug in Form::Sensible Select object 
			# requires values - Can't add values here, no objects to which to add
			push @{ $self->{values}->{$fieldname} }, substr $i, 1; 
			push @re, quotemeta( substr($i,1) );	
		}
		my $re = join '|', @re;
		$f->{validation} = { code => sub {
			TRACE "$re vs ", join ' / ', @_;

			foreach my $i (split /,/, $_[0]){
				return 0 if $i !~ /^($re)$/i
			}
			return 1;
		} };
	}
	
	# Is the field required?
	$f->{validation}->{required} = 1 
		if not defined( $self->{table_metadata}->{ $form->{name} }->{$fieldname}->{Default} )
			and $self->{table_metadata}->{ $form->{name} }->{$fieldname}->{Null} eq 'NO';
	
	# warn Dumper $f;
	return $f;
}



1;


=head1 DEPENDENCIES

L<Moose|Moose>,
L<Form::Sensible::Reflector|Form::Sensible::Reflector>,
L<Form::Sensible|Form::Sensible>,
L<DBD::mysql|DBD::mysql>,
L<DateTime::Format::MySQL|DateTime::Format::MySQL>,
L<Math::BigInt>.

=head1 CAVEAT EMPTORIUM

=over 4

=item *

The C<Math::Big*> modules may help if you use numbers.

=item *

At the time of writing, the young L<Form::Sensible::Field::Select|Form::Sensible::Field::Select>
has a bug which prevents the correct setting of the selected entity, as well as preventing
multiple selections. This has been reported and will be fiex in the next release.

=item *

Numeric fields may not contain commas, as described under L<FIELD TYPES>.

=back

=head1 BUGS, PATCHES, SUGGESTIONS

Please make use of CPAN's Request Tracker. 

=head1 SEE ALSO

The MySQL Manual, L<Chater 10 Data Types|http://dev.mysql.com/doc/refman/5.0/en/data-types.html>.

L<Form::Sensible|Form::Sensible>,
L<Form::Sensible::Reflector|Form::Sensible::Reflector>,
L<Form::Sensible::Reflector::DBIC|Form::Sensible::Reflector::DBIC>,
L<Form::Sensible::Field|Form::Sensible::Field>.

=head1 AUTHOR AND COPYRIGHT

Copyright (C) Lee Goddard, 2010-2011. All Rights Reserved.

Made available under the same terms as Perl.
	
=cut

package Form::Sensible::Reflector::MySQL::I18N::enGB;

=head1 NAME

Form::Sensible::Reflector::MySQL::I18N::enGB - error messages

=head1 DESCRIPTION

This namesapce provides the default error messages for form
validation as described in L<Form::Sensible::Reflector::MySQL/INTERNATIONALISATION>.

=cut

use base 'Exporter';

our @EXPORT = qw( $I18N );

use constant {
	NAN => '_FIELDNAME_ is not a valid number',
	NOT_INT => '_FIELDNAME_ is not an integer',
};

our $I18N = {
	
	# Unsigned big integer
	ubigint => {
		nan => '_FIELDNAME_ is an invalid unsigned big integer',
		not_int => NOT_INT,
		too_high => '_FIELDNAME_ is higher than the maximum allowed value of 18446744073709551615',
		too_low => '_FIELDNAME_ is lower than the maximum allowed value of 0',
	},
	
	# Signed big integer
	sbigint => {
		nan => '_FIELDNAME_ is an invalid signed big integer',
		not_int => NOT_INT,
		too_high => '_FIELDNAME_ is higher than the maximum allowed value of 9223372036854775807',
		too_low => '_FIELDNAME_ is lower than the maximum allowed value of -9223372036854775808',
	},
	
	# Double/real
	double => {
		nan => NAN,
		oob => '_FIELDNAME_ is out of bounds. Ranges are -1.7976931348623157E+308 to -2.2250738585072014E-308, 0 and 2.2250738585072014E-308 to 1.7976931348623157E+308',
	},
	
	# Float/double precision
	float => {
		nan => NAN,
		oob => '_FIELDNAME is out of bounds. Ranges are –3.402823466E+38 to –1.175494351E-38, 0 and 1.175494351E-38 to 3.402823466E+38',
		invalid => '_FIELDNAME_ is not a valid number format - digit length should not exceed ',
	},

	# Decimal/numeric
	decimal => {
		nan => NAN,
		too_long => '_FIELDNAME_ has too many digits in total: the maximum is ',
		post_point => '_FIELDNAME_ has too many digits after the decimal point: the maximum is ',
	},
	
	bits => {
		invalid => '_FIELDNAME_ must be a binary number with a maximum bit-length of ',
	},
	
	bit1 => {
		oob => '_FIELDNAME_ must be \'on\' (1) or \'off\' (0)',
	},
	
	# varbinary/binary
	binary => {
		too_long => '_FIELDNAME_ should have no more bytes than ',
	},

	tinyblob => {
		too_long => '_FIELDNAME_ is longer than the maximum allowed length of 255 bytes',
	},

	blob => {
		too_long => '_FIELDNAME_ is longer than the maximum allowed length of 65535 bytes',
	},
	
	mediumblob => {
		too_long => '_FIELDNAME_ is longer than the maximum allowed length of 16777215 bytes',
	},
	
	longblob => {
		too_long => '_FIELDNAME_ is longer than the maximum allowed length of 4294967295 bytes',
	},
	
	datetime => {
		year_length => '_FIELDNAME_ must have a four-digit year',
		year_oob => '_FIELDNAME_ must have a year from 1001 to 9999',
		parser_error_prefix => '',
	},
			
	timestamp => {
		year_length => '_FIELDNAME_ must have a four-digit year',
		year_oob => '_FIELDNAME_ must have a year from 1001 to 9999',
		parser_error_prefix => '',
	},
		
	date => {
		year_length => '_FIELDNAME_ must have a four-digit year',
		year_oob => '_FIELDNAME_ must have a year from 1001 to 9999',
		parser_error_prefix => '',
	},

	time => {
		invalid => '_FIELDNAME_ is not a valid time format',
		hours => 'Hours in _FIELDNAME_ are out of range',
		minutes => 'Minutes in _FIELDNAME_ are out of range',
		seconds => 'Seconds in _FIELDNAME_ are out of range',
	},

	# year(4)
	year4 => {
		oob => '_FIELDNAME_ must be a year between 1901 and 2155',
	},
	year => {
		oob => '_FIELDNAME_ must be a year between 00 and 99',
	},
	
};

1;

=head1 AUTHOR AND COPYRIGHT

Copyright (C) Lee Goddard, 2010-2011. All Rights Reserved.

Made available under the same terms as Perl.

