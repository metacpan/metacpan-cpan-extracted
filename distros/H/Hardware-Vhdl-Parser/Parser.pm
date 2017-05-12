##################################################################
# Copyright (C) 2000 Greg London   All Rights Reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
##################################################################


##################################################################
# this module defines a grammar for the VHDL language
# that can be used by Parse::RecDescent
##################################################################

package Hardware::Vhdl::Parser;

use Parse::RecDescent;

use strict;
use vars qw($VERSION @ISA);


@ISA = ( 'Parse::RecDescent' );

$VERSION = '0.12';
#########################################################################


##################################################################
sub new
##################################################################
{
 my ($pkg) = @_;

 # get the vhdl grammar defined in this file
 my $vhdl_grammar = $pkg->grammar();

 # create a parser object, use SUPER:: to find the method via @ISA
 my $r_hash = $pkg->SUPER::new  ($vhdl_grammar);

 # bless it as a vhdl_parser object
 bless $r_hash, $pkg;
 return $r_hash;
} 



##################################################################
sub grammar
##################################################################
{















































# note, q{  statement should be on line 100, 
# to make it easier to find referenced line numbers

return  q{

#START_OF_GRAMMAR

####################################################
# define reserved words. case insensitive
####################################################
reserved_word_abs : 
	/abs/i

reserved_word_access : 
	/access/i

reserved_word_after : 
	/after/i

reserved_word_alias : 
	/alias/i

reserved_word_all : 
	/all/i

reserved_word_and : 
	/and/i

reserved_word_architecture : 
	/architecture/i

reserved_word_array : 
	/array/i

reserved_word_assert : 
	/assert/i

reserved_word_attribute : 
	/attribute/i

reserved_word_begin : 
	/begin/i

reserved_word_block : 
	/block/i

reserved_word_body : 
	/body/i

reserved_word_buffer : 
	/buffer/i

reserved_word_bus : 
	/bus/i

reserved_word_case : 
	/case/i

reserved_word_component : 
	/component/i

reserved_word_configuration : 
	/configuration/i

reserved_word_constant : 
	/constant/i

reserved_word_disconnect : 
	/disconnect/i

reserved_word_downto : 
	/downto/i

reserved_word_else : 
	/else/i

reserved_word_elsif : 
	/elsif/i

reserved_word_end : 
	/end/i

reserved_word_entity : 
	/entity/i

reserved_word_exit : 
	/exit/i

reserved_word_file : 
	/file/i

reserved_word_for : 
	/for/i

reserved_word_function : 
	/function/i

reserved_word_generate : 
	/generate/i

reserved_word_generic : 
	/generic/i

reserved_word_group : 
	/group/i

reserved_word_guarded : 
	/guarded/i

reserved_word_if : 
	/if/i

reserved_word_impure : 
	/impure/i

reserved_word_in : 
	/in/i

reserved_word_inertial : 
	/inertial/i

reserved_word_inout : 
	/inout/i

reserved_word_is : 
	/is/i

reserved_word_label : 
	/label/i

reserved_word_library : 
	/library/i

reserved_word_linkage : 
	/linkage/i

reserved_word_literal : 
	/literal/i

reserved_word_loop : 
	/loop/i

reserved_word_map : 
	/map/i

reserved_word_mod : 
	/mod/i

reserved_word_nand : 
	/nand/i

reserved_word_new : 
	/new/i

reserved_word_next : 
	/next/i

reserved_word_nor : 
	/nor/i

reserved_word_not : 
	/not/i

reserved_word_null : 
	/null/i

reserved_word_of : 
	/of/i

reserved_word_on : 
	/on/i

reserved_word_open : 
	/open/i

reserved_word_or : 
	/or/i

reserved_word_others : 
	/others/i

reserved_word_out : 
	/out/i

reserved_word_package : 
	/package/i

reserved_word_port : 
	/port/i

reserved_word_postponed : 
	/postponed/i

reserved_word_procedure : 
	/procedure/i

reserved_word_process : 
	/process/i

reserved_word_pure : 
	/pure/i

reserved_word_range : 
	/range/i

reserved_word_record : 
	/record/i

reserved_word_register : 
	/register/i

reserved_word_reject : 
	/reject/i

reserved_word_rem : 
	/rem/i

reserved_word_report : 
	/report/i

reserved_word_return : 
	/return/i

reserved_word_rol : 
	/rol/i

reserved_word_ror : 
	/ror/i

reserved_word_select : 
	/select/i

reserved_word_severity : 
	/severity/i

reserved_word_signal : 
	/signal/i

reserved_word_shared : 
	/shared/i

reserved_word_sla : 
	/sla/i

reserved_word_sll : 
	/sll/i

reserved_word_sra : 
	/sra/i

reserved_word_srl : 
	/srl/i

reserved_word_subtype : 
	/subtype/i

reserved_word_then : 
	/then/i

reserved_word_to : 
	/to/i

reserved_word_transport : 
	/transport/i

reserved_word_type : 
	/type/i

reserved_word_unaffected : 
	/unaffected/i

reserved_word_units : 
	/units/i

reserved_word_until : 
	/until/i

reserved_word_use : 
	/use/i

reserved_word_variable : 
	/variable/i

reserved_word_wait : 
	/wait/i

reserved_word_when : 
	/when/i

reserved_word_while : 
	/while/i

reserved_word_with : 
	/with/i

reserved_word_xnor : 
	/xnor/i

reserved_word_xor : 
	/xor/i



eofile : /^\Z/

####################################################
####################################################

design_file :  
	design_unit(s) eofile { $return = $item[1] }

design_unit : 
	context_clause(s?) library_unit  
	| <error> 

context_clause :
	  library_clause 
	| use_clause 

library_unit : 
	  entity_declaration 
	| architecture_body 
	| package_declaration 
	| package_body 
	| configuration_declaration 

library_clause : 
	reserved_word_library library_name_list ';'  

library_name_list : 
	identifier_comma_identifier

use_clause : 
	reserved_word_use  
	selected_name_comma_selected_name
	';' 

####################################################
####################################################

entity_declaration : 
	reserved_word_entity 
	entity_name 
	reserved_word_is 
	generic_declaration_section(?)
	port_declaration_section(?)
	entity_declaritive_item(?)
	begin_entity_section(?)
	reserved_word_end 
	reserved_word_entity(?) 
	identifier(?) 
	';'  
	 

begin_entity_section :
	reserved_word_begin
	( concurrent_assertion_statement |
	passive_concurrent_procedure_call_statement |
	passive_process_statement ) 

passive_concurrent_procedure_call_statement :
	concurrent_procedure_call_statement

passive_process_statement :
	process_statement

entity_declaritive_item : 
	| signal_declaration 
	| constant_declaration 
	| type_declaration 
	| subtype_declaration 
	| shared_variable_declaration 
	| file_declaration 
	| alias_declaration 
	| attribute_declaration 
	| attribute_specification 
	| disconnection_specification 
	| use_clause 
	| group_template_declaration 
	| group_declaration 
	| subprogram_declaration 
	| subprogram_body 

architecture_body :
	reserved_word_architecture 
		identifier 
	reserved_word_of 
		entity_name 
	reserved_word_is
		block_declarative_item(s?)
	reserved_word_begin
		concurrent_statement(s?)
	reserved_word_end 
	reserved_word_architecture(?) 
	identifier(?) 
	';' 
	| <error> 

configuration_declaration :
	reserved_word_configuration 
		identifier 
	reserved_word_of 
		entity_name 
	reserved_word_is
		use_clause_or_attribute_specification_or_group_declaration(s?)
		block_configuration
	reserved_word_end 
	reserved_word_configuration(?) 
	identifier(?) 
	';' 

use_clause_or_attribute_specification_or_group_declaration : 
	  use_clause 
	| attribute_specification 
	| group_declaration


block_configuration : 
                  reserved_word_for 
                          architecture_name
                  use_clause_or_for_use_clause(s?)
                  reserved_word_end 
                  reserved_word_for 
                  ';'

use_clause_or_for_use_clause :
	  use_clause
	| for_use_clause

for_use_clause : 
                  reserved_word_for
                  identifier
                  ':'
                  identifier
                  use_clause(?)
                  reserved_word_end 
                  reserved_word_for 
                  ';'

package_declaration :
	reserved_word_package 
		identifier 
	reserved_word_is
		package_declarative_item(s?)
	reserved_word_end 
	reserved_word_package(?) 
	identifier(?) 
	';'  
	| <error> 

package_declarative_item :
	  subprogram_declaration 
	| type_declaration 
	| subtype_declaration 
	| constant_declaration 
	| signal_declaration 
	| shared_variable_declaration 
	| file_declaration 
	| alias_declaration 
	| component_declaration 
	| attribute_declaration 
	| attribute_specification 
	| disconnection_specification 
	| use_clause 
	| group_template_declaration 
	| group_declaration 

package_body :
	reserved_word_package 
	reserved_word_body 
		identifier 
	reserved_word_is
		package_body_declarative_item(s?)
	reserved_word_end 
	reserved_word_package_and_body(?) 
	identifier(?) 
	';' 
	| <error> 

reserved_word_package_and_body :
	reserved_word_package 
	reserved_word_body

package_body_declarative_item :
	  subprogram_body 
	| subprogram_declaration 
	| type_declaration 
	| subtype_declaration 
	| constant_declaration 
	| shared_variable_declaration 
	| file_declaration 
	| alias_declaration 
	| use_clause 
	| group_template_declaration 
	| group_declaration 

####################################################
####################################################

subprogram_declaration : 
	subprogram_specification 
	';' 

subprogram_specification :
	procedure_specification | function_specification 

procedure_specification :
	reserved_word_procedure 
		identifier_or_operator_symbol
		parameter_interface_list(?) 

identifier_or_operator_symbol :
	identifier | operator_symbol

function_specification :
	pure_or_impure(?) 
	reserved_word_function 
		identifier_or_operator_symbol 
		parameter_interface_list(?) 
	reserved_word_return
		type_mark 
	| <error>

####
# parameter interface list
# used to declare io for functions or procedure declarations
####
parameter_interface_list : 
	'(' interface_list ')' 
	| <error>


pure_or_impure :
	reserved_word_pure | reserved_word_impure

subprogram_body :
	subprogram_specification 
	reserved_word_is
		subprogram_declarative_part(?)
	reserved_word_begin
		sequential_statement(s?)
	reserved_word_end 
	reserved_word_function_or_procedure(?)
	identifier_or_operator_symbol(?) 
	';' 
	| <error>

reserved_word_function_or_procedure : 
	reserved_word_function | reserved_word_procedure

subprogram_declarative_part :
	  subprogram_declaration 
	| subprogram_body 
	| type_declaration 
	| subtype_declaration 
	| file_declaration 
	| alias_declaration 
	| attribute_declaration 
	| attribute_specification 
	| use_clause 
	| group_template_declaration 
	| group_declaration  

type_declaration :
	reserved_word_type 
		identifier 
	is_type_definition(?) 
	';' 

is_type_definition : 
	reserved_word_is 
		type_definition

type_definition : 
	  enumeration_type_definition
	| integer_type_definition 
	| floating_type_definition 
	| physical_type_definition 
	| array_type_definition 
	| record_type_definition
	| access_type_definition 
	| file_type_definition 

constant_declaration :
	reserved_word_constant 
		identifier_comma_identifier 
	':'
		subtype_indication 
		default_value(?) 
	';' 

signal_declaration :
	reserved_word_signal 
		identifier_comma_identifier 
	':'
		subtype_indication  
		reserved_word_register_or_bus(?)
		default_value(?) 
	';' 

reserved_word_register_or_bus :
	reserved_word_register | reserved_word_bus

shared_variable_declaration : 
	reserved_word_shared 
	variable_declaration

variable_declaration :
	reserved_word_variable 
		identifier_comma_identifier 
	':'
		subtype_indication
		default_value(?)
	';'

file_declaration :
	reserved_word_file 
		identifier_comma_identifier 
	':'
		subtype_indication
		open_file_expression_is_string_expression_option(?)
	';'
	

open_file_expression_is_string_expression_option :
	open_file_expression_option(?) 
	reserved_word_is 
		string_expression 

open_file_expression_option :
	reserved_word_open 
		file_open_kind_expression 

alias_declaration :
	reserved_word_alias 
	identifier_or_character_literal_or_operator_symbol
		colon_subtype_indication(?)
	reserved_word_is
		name 
		signature(?) 
	';'

identifier_or_character_literal_or_operator_symbol : 
	identifier | character_literal | operator_symbol

colon_subtype_indication :
	':'
	subtype_indication

component_declaration :
	reserved_word_component 
		component_name 
	reserved_word_is(?)
		generic_declaration_section(?)
		port_declaration_section(?)
	reserved_word_end 
	reserved_word_component 
	component_name(?) 
	';'  
	| <error>

attribute_declaration :
	reserved_word_attribute 
		identifier 
	':' 
		type_mark 
	';'

attribute_specification :
	reserved_word_attribute 
		identifier 
	reserved_word_of 
		entity_name_list 
	':'
		entity_class 
	reserved_word_is 
		expression_rule 
	';'

entity_name_list :
	( reserved_word_others 
	| reserved_word_all 
	| id_char_op_comma_id_char_op )

id_char_op_comma_id_char_op :
	id_or_char_or_op_with_optional_signature
	comma_id_or_char_or_op_with_optional_signature(s?)

comma_id_or_char_or_op_with_optional_signature :
	','
	id_or_char_or_op_with_optional_signature

id_or_char_or_op_with_optional_signature :
	identifier_or_character_literal_or_operator_symbol
	signature(?)

entity_class :
 	(
	  reserved_word_entity	
	| reserved_word_architecture 
	| reserved_word_configuration 
	| reserved_word_procedure   
	| reserved_word_function	 
	| reserved_word_package 	   
	| reserved_word_type	
	| reserved_word_subtype	 
	| reserved_word_constant	   
	| reserved_word_signal	
	| reserved_word_variable 	 
	| reserved_word_component	   
	| reserved_word_label 	
	| reserved_word_literal	 
	| reserved_word_units	   
	| reserved_word_group	
	| reserved_word_file	
	)

configuration_specification :
	reserved_word_for 
		component_specification 
		binding_indication 
	';'

component_specification :
	reserved_word_others_all_or_one_or_more_instantiation_labels
	':' 
	component_name

reserved_word_others_all_or_one_or_more_instantiation_labels :
	  reserved_word_others 
	| reserved_word_all
	| instantiation_label_comma_instantiation_label

instantiation_label_comma_instantiation_label :
	instantiation_label
	comma_instantiation_label(s?)

comma_instantiation_label :
	','
	instantiation_label

binding_indication : 
	use_entity_or_configuration_or_open(?)
	generic_map_section(?)
	port_map_section(?)
	';'

use_entity_or_configuration_or_open :
	reserved_word_use 
		(
		reserved_word_entity_and_entity_name_arch_name_in_parens |
		reserved_word_configuration_and_configuration_name |
		reserved_word_open
		)

disconnection_specification :
	reserved_word_disconnect 
		(
		  reserved_word_others
		| reserved_word_all
		| signal_name_comma_signal_name 
		)
	':'
		type_mark
	reserved_word_after 
		time_expression 
	';'

group_template_declaration :
	reserved_word_group 
		identifier 
	reserved_word_is 
	list_of_entity_class_with_optional_box_in_parens 
	';'

list_of_entity_class_with_optional_box_in_parens :
	'(' entity_class_box_comma_entity_class_box ')'

entity_class_box_comma_entity_class_box :
	entity_class_with_optional_box_operator
	comma_entity_class_with_optional_box_operator(s?)

comma_entity_class_with_optional_box_operator :
	','
	entity_class_with_optional_box_operator

entity_class_with_optional_box_operator :
	entity_class
	box_operator(?)

box_operator : 
	'<>'

group_declaration :
	reserved_word_group 
		identifier 
	':' 
		group_template_name 
		'(' name_char_literal_comma_name_char_literal ')' 
	';'

name_char_literal_comma_name_char_literal :
	name_or_char_literal 
	comma_name_char_literal(s?)

comma_name_char_literal :
	','
	name_or_char_literal

name_or_char_literal :
	( name | character_literal )

use_clause : 
	reserved_word_use 
		selected_name_comma_selected_name 
	';'

selected_name_comma_selected_name :
	selected_name
	comma_selected_name(s?)

comma_selected_name :
	','
	selected_name

####################################################
####################################################
enumeration_type_definition :
	'(' id_or_char_comma_id_or_char ')'

id_or_char_comma_id_or_char :
	identifier_or_character_literal
	comma_id_or_char(s?)

comma_id_or_char :
	','
	identifier_or_character_literal

identifier_or_character_literal :
	identifier | character_literal

simple_expression_to_downto_simple_expression :
	simple_expression 
	reserved_word_to_or_downto 
	simple_expression 

reserved_word_to_or_downto :
	reserved_word_to | reserved_word_downto

range_attribute_name_or_simple_expression_to_downto_simple_expression :
	range_attribute_name |
	 simple_expression_to_downto_simple_expression

integer_type_definition :
	reserved_word_range 
	range_attribute_name_or_simple_expression_to_downto_simple_expression
 
floating_type_definition :
	reserved_word_range 
	range_attribute_name_or_simple_expression_to_downto_simple_expression 

physical_type_definition :
	reserved_word_range 
	range_attribute_name_or_simple_expression_to_downto_simple_expression
	reserved_word_units 
		identifier
	';'
		identifier_is_physical_literal(?)
	reserved_word_end 
	reserved_word_units 
		identifier(?)

identifier_is_physical_literal :
	identifier '=' physical_literal

array_type_definition :
	reserved_word_array 
	'(' array_type_mark_definition_or_array_discrete_range_definition ')'
	reserved_word_of
		element_subtype_indication

array_type_mark_definition_or_array_discrete_range_definition : 
	  type_mark_range_box_comma_type_mark_range_box 
	| array_discrete_range_definition

type_mark_range_box_comma_type_mark_range_box :
	type_mark_range_box
	comma_type_mark_range_box(s?)

comma_type_mark_range_box :
	','
	type_mark_range_box 

type_mark_range_box :
	type_mark reserved_word_range box_operator

array_discrete_range_definition :
	discrete_range_comma_discrete_range

discrete_range_comma_discrete_range :
	discrete_range
	comma_discrete_range(s?)

comma_discrete_range :
	','
	discrete_range

record_type_definition :
	reserved_word_record 
		record_element_definition(s) 
	reserved_word_end reserved_word_record identifier(?)

record_element_definition :
	identifier_comma_identifier 
	':'
	subtype_indication 
	';'

access_type_definition :
	reserved_word_access 
		subtype_indication

file_type_definition :
	reserved_word_file 
	reserved_word_of 
		type_mark

subtype_declaration :
	reserved_word_subtype 
		identifier 
	reserved_word_is 
		subtype_indication 
	';'

subtype_indication :
	# resolution_function_name 
	type_mark
	range_or_simple_or_discrete(?)  
	| <error>

range_or_simple_or_discrete :
	  reserved_word_range_range_attribute_name_or_simple_downto_expression
	| discrete_range_in_parens

discrete_range_in_parens :
 	'(' discrete_range ')'

reserved_word_range_range_attribute_name_or_simple_downto_expression :
	reserved_word_range 
	range_attribute_name_or_simple_expression_to_downto_simple_expression 		
	
discrete_range :
	  range_attribute_name 
	| simple_expression_to_downto_simple_expression
	| discrete_subtype_indication

discrete_subtype_indication : 
	subtype_indication

type_mark :
	type_name

####################################################
####################################################
concurrent_statement :
	  component_instantiation_statement 
	| block_statement 
	| process_statement 
	| concurrent_procedure_call_statement 
	| concurrent_assertion_statement 
	| concurrent_signal_assignment_statement 
	| generate_statement 

block_statement :
	block_label 
	':'
	reserved_word_block
		guard_expression_in_parens(?)
	reserved_word_is(?)
		generic_declaration_section(?)
		generic_map_section(?)
		port_declaration_section(?)
		port_map_section(?)
		block_declarative_item(s?)
	reserved_word_begin
		concurrent_statement(s?)
	reserved_word_end 
	reserved_word_block 
	block_label(?) 
	';'

guard_expression_in_parens :
	'(' guard_expression ')'

block_declarative_item :
	  subprogram_declaration 
	| subprogram_body	
	| type_declaration 
	| subtype_declaration 
	| constant_declaration 
	| signal_declaration 
	| shared_variable_declaration 
	| file_declaration 
	| alias_declaration 
	| component_declaration 
	| attribute_declaration 
	| attribute_specification 
	| configuration_specification 
	| disconnection_specification 
	| use_clause 
	| group_template_declaration 
	| group_declaration

process_statement :
	label_followed_by_colon(?)
	reserved_word_postponed(?)
	reserved_word_process
		sensitivity_list(?)
	reserved_word_is(?)
		process_declarative_item(s?)
	reserved_word_begin
		sequential_statement(s?)
	reserved_word_end 
	reserved_word_postponed(?) 
	reserved_word_process 
	process_label(?) 
	';'
	| <error>

label_followed_by_colon : 
	label ':'

sensitivity_list :
	'(' signal_name_comma_signal_name ')'

process_declarative_item :
	  subprogram_declaration 
	| subprogram_body 
	| type_declaration 
	| subtype_declaration 
	| constant_declaration 
	| variable_declaration 
	| file_declaration 
	| alias_declaration 
	| attribute_declaration 
	| attribute_specification 
	| use_clause 
	| group_template_declaration 
	| group_declaration 

concurrent_procedure_call_statement :
	label_followed_by_colon(?)
	reserved_word_postponed(?)
		procedure_name
		subprogram_parameter_section(?)
	';'

concurrent_assertion_statement :
	label_followed_by_colon(?)
	reserved_word_postponed(?)
	reserved_word_assert 
		boolean_expression 
	reserved_word_report_and_expression_rule(?)
	reserved_word_severity_and_expression_rule(?) 
	';'

reserved_word_report_and_expression_rule :
	reserved_word_report 
		expression_rule

reserved_word_severity_and_expression_rule :
	reserved_word_severity 
		expression_rule

concurrent_signal_assignment_statement :
	label_followed_by_colon(?) 
	reserved_word_postponed(?) 
	selected_or_conditional_signal_assignment

selected_or_conditional_signal_assignment : 
	selected_signal_assignment | conditional_signal_assignment

selected_signal_assignment :
	reserved_word_with 
		expression_rule 
	reserved_word_select
		name_or_aggregate 
	'<='
	reserved_word_guarded(?) 
	delay_mechanism(?)
		waveform_when_choices_comma_waveform_when_choices
	';'

waveform_when_choices_comma_waveform_when_choices :
	waveform_when_choices
	comma_waveform_when_choices(s?)

comma_waveform_when_choices :
	','
	waveform_when_choices

waveform_when_choices :
	waveform_rule reserved_word_when choices_pipe_choices 

conditional_signal_assignment :
	name_or_aggregate 
	'<=' 
	reserved_word_guarded(?) 
	delay_mechanism(?)
		waveform_rule 
		when_boolean_expression_else_waveform_rule(s?)
	';' 

name_or_aggregate : 
	name | aggregate

when_boolean_expression_else_waveform_rule :
	reserved_word_when 
		boolean_expression 
	reserved_word_else
		waveform_rule

component_instantiation_statement :
	instantiation_label 
	':'
	entity_configuration_component
	generic_map_section(?)
	port_map_section(?)
	';'
	| <error>

	
entity_configuration_component :
	reserved_word_entity_and_entity_name_arch_name_in_parens |
	reserved_word_configuration_and_configuration_name |
	reserved_word_component_and_component_name 



reserved_word_entity_and_entity_name_arch_name_in_parens :
	reserved_word_entity 
		entity_name 
		architecture_identifier_in_parens(?)  

reserved_word_configuration_and_configuration_name :
	reserved_word_configuration 
		configuration_name 

reserved_word_component_and_component_name :
	reserved_word_component(?) 
		component_name  

architecture_identifier_in_parens :
	 '(' architecture_identifier ')'  

generate_statement :
	generate_label ':'
		for_identifier_in_range_or_if_boolean_expression
	reserved_word_generate
		generate_block_declarative_item_and_begin(?)
		concurrent_statement(s?)
	reserved_word_end 
	reserved_word_generate 
	generate_label(?) 
	';'

for_identifier_in_range_or_if_boolean_expression :
	for_identifier_in_range | if_boolean_expression

for_identifier_in_range :
	reserved_word_for 
		identifier 
	reserved_word_in 
		discrete_range

if_boolean_expression :
	reserved_word_if 
		boolean_expression

generate_block_declarative_item_and_begin :
	block_declarative_item(s?)
	reserved_word_begin

####################################################
####################################################
sequential_statement :
	  wait_statement 
	| assertion_statement
	| report_statement 
	| signal_assignment_statement 
	| variable_assignment_statement 
	| procedure_call_statement 
	| if_statement 
	| case_statement 
	| loop_statement 
	| next_statement 
	| exit_statement 
	| return_statement 
	| null_statement
	| <error>

wait_statement :
	label_followed_by_colon(?)
	reserved_word_wait
		on_list_of_signal(?)
	reserved_word_until_and_boolean_expression(?)
	reserved_word_for_and_time_expression(?)
	';'

reserved_word_until_and_boolean_expression :
	reserved_word_until 
		boolean_expression

reserved_word_for_and_time_expression :
	reserved_word_for 
		time_expression

on_list_of_signal :
 	reserved_word_on 
		signal_name_comma_signal_name

assertion_statement :
	label_followed_by_colon(?)
	reserved_word_assert boolean_expression
	reserved_word_report_and_expression_rule(?)
	reserved_word_severity_and_expression_rule(?)
	';'

reserved_word_report_and_expression_rule :
	reserved_word_report 
		expression_rule

reserved_word_severity_and_expression_rule :
	reserved_word_severity 
		expression_rule

report_statement :
	label_followed_by_colon(?)
	reserved_word_report_and_expression_rule 
	reserved_word_severity_and_expression_rule(?)
	';'

signal_assignment_statement :
	label_followed_by_colon(?)
	name_or_aggregate 
	'<='
	delay_mechanism(?)
	waveform_rule
	';'

delay_mechanism :
	reserved_word_transport | inertial_with_optional_reject_time

inertial_with_optional_reject_time :
	reserved_word_reject_and_time_expression(?) 
	reserved_word_inertial

reserved_word_reject_and_time_expression :
	reserved_word_reject 
		time_expression

waveform_rule :
	  reserved_word_unaffected 
	| waveform_item_comma_waveform_item

waveform_item_comma_waveform_item :
	waveform_item
	comma_waveform_item(s?)

comma_waveform_item :
	','
	waveform_item

waveform_item :
	  null_with_optional_after_time_expression 
	| value_expression_with_optional_time_expression

null_with_optional_after_time_expression :
	reserved_word_null 
	reserved_word_after_and_time_expression(?) 

value_expression_with_optional_time_expression :
	value_expression 
	reserved_word_after_and_time_expression(?)

reserved_word_after_and_time_expression :
	reserved_word_after 
	time_expression 

variable_assignment_statement :
	label_followed_by_colon(?)
		name_or_aggregate 
	':=' 
		expression_rule 
	';'

procedure_call_statement :
	label_followed_by_colon(?)
		procedure_name 
		subprogram_parameter_section(?) 
	';'
	| <error>

if_statement :
	label_followed_by_colon(?)
	reserved_word_if 
		boolean_expression 
	reserved_word_then
		sequential_statement(s)
	optional_elsif_section(s?)
	optional_else_section(?)
	reserved_word_end 
	reserved_word_if 
	if_label(?) 
	';'
	| <error>

optional_elsif_section :
	reserved_word_elsif 
		boolean_expression 
	reserved_word_then
		sequential_statement(s)

optional_else_section :
	reserved_word_else 
		sequential_statement(s)

case_statement :
	label_followed_by_colon(?)
	reserved_word_case expression_rule reserved_word_is
		when_choices_sequential_statement(s)
	reserved_word_end reserved_word_case case_label(?) ';'

when_choices_sequential_statement :
	reserved_word_when 
		choices_pipe_choices 
	'=>' 
		sequential_statement(s)

loop_statement :
	label_followed_by_colon(?)
	while_boolean_or_for_identifier_in_discrete_range
	reserved_word_loop
		sequential_statement(s)
	reserved_word_end reserved_word_loop loop_label(?) ';'

while_boolean_or_for_identifier_in_discrete_range :
	  reserved_word_while_and_boolean_expression
	| reserved_word_for_identifier_in_discrete_range

reserved_word_while_and_boolean_expression :
	reserved_word_while 
		boolean_expression

reserved_word_for_identifier_in_discrete_range :
	reserved_word_for 
		identifier 
	reserved_word_in 
		discrete_range

next_statement :
	label_followed_by_colon(?) 
	reserved_word_next 
	loop_label(?) 
	reserved_word_when_and_boolean_expression(?) 
	';'

exit_statement :
	label_followed_by_colon(?) 
	reserved_word_exit 
	loop_label(?) 
	reserved_word_when_and_boolean_expression(?) 
	';'

reserved_word_when_and_boolean_expression :
	reserved_word_when 
		boolean_expression

return_statement :
	label_followed_by_colon(?) 
	reserved_word_return 
	expression_rule(?) 
	';'

null_statement :
	label_followed_by_colon(?) 
	reserved_word_null 
	';'


####################################################
# E.7 Interfaces and Associations
####################################################
interface_list :
	interface_item_semicolon_interface_item

interface_item_semicolon_interface_item :
	interface_item
	semicolon_interface_item(s?)

semicolon_interface_item :
	';'
	interface_item

interface_item :
	  constant_interface 
	| signal_interface 
	| variable_interface 
	| file_interface


constant_interface :
	reserved_word_constant(?) 
		identifier_comma_identifier 
	':' 
	reserved_word_in(?) 
		subtype_indication 
		default_value(?) 
	| <error>


signal_interface :
	reserved_word_signal(?) 
		identifier_comma_identifier 
	':' 
		mode(?) 
		subtype_indication 
	reserved_word_bus(?) 
		default_value(?) 
	| <error>

variable_interface :
	reserved_word_variable(?) 
		identifier_comma_identifier 
	':' 
		mode(?) 
		subtype_indication 
		default_value(?) 
	| <error>

file_interface :
	reserved_word_file 
		identifier_comma_identifier 
	':'
		subtype_indication 
	| <error>

mode : 
	  reserved_word_inout 
	| reserved_word_out 
	| reserved_word_in 
	| reserved_word_buffer 
	| reserved_word_linkage 

association_list :
	actual_formal_comma_actual_formal
	| <error>

actual_formal_comma_actual_formal :
	actual_part_with_optional_formal_part
	comma_actual_part_with_optional_formal_part(s?)
	| <error>

comma_actual_part_with_optional_formal_part :
	','
	actual_part_with_optional_formal_part
	| <error>

actual_part_with_optional_formal_part :
	formal_part_and_arrow(?) 
		actual_part
	| <error>

formal_part_and_arrow :
	formal_part '=>'
	| <error>

formal_part :
	  generic_name 
	| port_name 
	| parameter_name 
	| function_name generic_port_parameter_selection 
	| type_mark generic_port_parameter_selection 
	| <error>

generic_port_parameter_selection :
	'(' generic_name_port_name_parameter_name ')'
	| <error>

generic_name_port_name_parameter_name :
	generic_name | port_name | parameter_name
	| <error>

actual_part :
	  expression_rule 
	| variable_name 
	| reserved_word_open 
	| function_name_signal_name_or_variable_name_selection 
	| type_mark_signal_name_or_variable_name_selection
	| <error>


function_name_signal_name_or_variable_name_selection :
	function_name
	signal_name_or_variable_name_in_parens

type_mark_signal_name_or_variable_name_selection :
	type_mark
	signal_name_or_variable_name_in_parens

signal_name_or_variable_name_in_parens :
	'(' signal_name_or_variable_name ')'

signal_name_or_variable_name :
	signal_name | variable_name

####################################################
# E.8 Expressions
####################################################
boolean_expression :
	expression_rule

static_expression :
	expression_rule


expression_rule : 
	relation 
	logic_relation(s?)

logic_relation : 
	logic_relation_operator
	relation

logic_relation_operator : 
	  reserved_word_nand 
	| reserved_word_xnor 
	| reserved_word_and 
	| reserved_word_nor 
	| reserved_word_xor 
	| reserved_word_or 

relation :
	shift_expression 
	relation_shift_expression(?)

relation_shift_expression :
	relation_operator 
	shift_expression 

relation_operator : 
	  '/=' 
	| '<=' 
	| '>='
	| '=' 
	| '>' 
	| '<' 

shift_expression :
	simple_expression 
	shift_simple_expression(?)

shift_simple_expression :
	 shift_operator
	 simple_expression 

shift_operator : 
	  reserved_word_sll 
	| reserved_word_srl 
	| reserved_word_sla 
	| reserved_word_sra 
	| reserved_word_rol
	| reserved_word_ror 


simple_expression :
	sign(?) term optional_term(s?) 

sign :
	'+' | '-' 

optional_term :
	add_or_concat_operator term 

add_or_concat_operator :
	  '+' 
	| '-' 
	| '&'

term :
	factor
	optional_factor(s?) 

optional_factor :
	multiply_operator factor 

multiply_operator :
	  '*' 
	| '/' 
	| reserved_word_mod 
	| reserved_word_rem

factor :
	  reserved_word_abs_and_primary 
	| reserved_word_not_and_primary
	| primary_exp_primary 

reserved_word_abs_and_primary :
	reserved_word_abs primary

reserved_word_not_and_primary :
	reserved_word_not primary

primary_exp_primary :
	primary exponent_primary(?) 

exponent_primary :
	'**' primary 


# notes:
#
# the rules for "primary" is not mutually exclusive:
# there are rules that apply such that a given input text
# could be one of two different possible interpretations.
#
# there is no way to distinguish between the two possibilities
# by simply looking at the token being examined.
#
# 1)
#
# aggregate : '(' optional_choice_arrow(?) expression_rule [ ',' repeat ] ')'
# expression in paren : '(' expression_rule ')' 
#
# therefore an aggregate with one entry and no choice arrow is
# indistinguishable from an expression in paren.
#
#
# 2)
#
#  function_call       # token ( param=>(?) value [,repeat])(?)
#  literal->identifier # token
#
# therefore a function call with no input parameters is
# indistinguishable from a literal identifier.


primary : 
	  new_qualified_expression  # 'new' token ' ( yada )
	| new_subtype_indication    # 'new' token
	| qualified_expression   # token ' ( yada )
	| function_call 	 # token ( param=>(?) value [,repeat])(?)
	| literal
	| aggregate	# '(' choice=>(?) expression [,repeat] ')'
	| expression_rule_in_parens 
	| name 

new_qualified_expression :
	reserved_word_new 
	qualified_expression

new_subtype_indication :
	reserved_word_new 
	subtype_indication

qualified_expression :
	  type_mark_tick_aggregate   
	| type_mark_tick_expression  

type_mark_tick_expression :
	type_mark "'" '(' expression_rule ')'

type_mark_tick_aggregate :
	type_mark "'" aggregate

#
# temporary patch, don't allow function calls without a parameter list
#  in parenthesis. this will prevent identifiers from being mistaken
#  for function calls with no parameters.
#
# this means that functions with no parameters will be mistaken
# for identifiers. at least until this is fixed somehow.
#
function_call : 
	function_name 
	subprogram_parameter_section	#(?) 

expression_rule_in_parens : 
	'(' expression_rule ')'

# left recursion here.
# name = ( name | functionname) ... | (name | functioncall) 
# need to clean up "name" rule declaration
name :
	  attribute_name 
	| operator_symbol 
	| selected_name 
	| identifier_paren_one_or_expression_rule_comma_expression_rule
	| identifier_paren_discrete_range
	| identifier

identifier_paren_one_or_expression_rule_comma_expression_rule : 
	identifier '(' expression_rule_comma_expression_rule ')'

expression_rule_comma_expression_rule :
	expression_rule
	comma_expression_rule(s?)

comma_expression_rule :
	','
	expression_rule

identifier_paren_discrete_range : 
	identifier '(' discrete_range ')'

selected_name :
	identifier  '.' 
	( identifier  '.' )(?)
	reserved_word_all_or_identifier_or_character_literal_or_operator_symbol

reserved_word_all_or_identifier_or_character_literal_or_operator_symbol :
	reserved_word_all | identifier_or_character_literal_or_operator_symbol

operator_symbol :
	'"' graphic_character '"'

attribute_name :
	identifier "'" identifier 

signature :
	'[' 
	type_mark_comma_type_mark(?)  
	reserved_word_return_and_type_mark(?)
	']'

type_mark_comma_type_mark :
	type_mark
	comma_type_mark(s?)

comma_type_mark :
	','
	type_mark

reserved_word_return_and_type_mark :
	reserved_word_return 
	type_mark

literal :
	  reserved_word_null
	| character_literal
	| string_literal 
	| bit_string_literal 
	| based_literal_unit_name
	| decimal_literal_unit_name

character_literal :
	"'" graphic_character "'" 

string_literal :
	'"' graphic_character(s) '"'

bit_string_literal :
	b_or_o_or_x '"' based_integer '"'

b_or_o_or_x :
	'B' | 'O' | 'X'

decimal_literal_unit_name : 
	integer
	optional_fractional_part(?)
	optional_sci_notation(?)
	unit_name(?)

based_literal_unit_name :
	integer 
	'#' 
	based_integer optional_based_fraction_part(?) 
	'#' 
	optional_based_sci_notation(?)
	unit_name(?)


optional_fractional_part :
	  '.' integer

optional_sci_notation :
	 'E' sign(?) integer

optional_based_fraction_part :
	'.' based_integer 

optional_based_sci_notation :
	'E' sign(?) integer

integer :
	/\d+/

based_integer :
	/[A-Za-z0-9][A-Za-z0-9_]/


aggregate :
	'(' choice_expression_comma_choice_expression ')' 

choice_expression_comma_choice_expression :
	optional_choice_arrow_with_expression
	comma_optional_choice_arrow_with_expression(s?)

comma_optional_choice_arrow_with_expression :
	','
	optional_choice_arrow_with_expression

optional_choice_arrow_with_expression :
	optional_choice_arrow(?)
	expression_rule 

optional_choice_arrow :
	choices_pipe_choices '=>'

choices_pipe_choices :
	one_of_several_choices
	pipe_one_of_several_choices(s?)

pipe_one_of_several_choices :
	'|'
	one_of_several_choices

one_of_several_choices :
	reserved_word_others | simple_expression | discrete_range | identifier  

case_label : identifier
loop_label : identifier
if_label : identifier
label : identifier

identifier : /[A-Za-z][A-Za-z_0-9]*/ 


####
#### this needs some polish, need to disable whitespace
#### so that can accept a string literal of " " as valid
####
graphic_character :
	
	/[ A-Za-z0-9\-~`!@#$%^&*()_+={};:',.<>|]/
####################################################
# misc
####################################################
identifier_comma_identifier : 
	identifier
	comma_identifier(s?)

comma_identifier :
	','
	identifier

entity_name : identifier 

####
# generics
####
generic_declaration_section : 
	reserved_word_generic generic_interface_list(?) ';'
	| <error>

generic_interface_list : 
	'('
	 generic_interface_list_entry_semicolon_generic_interface_list_entry
	')' 
	| <error>

generic_interface_list_entry_semicolon_generic_interface_list_entry :
	generic_interface_list_entry
	semicolon_generic_interface_list_entry(s?)
	| <error>

semicolon_generic_interface_list_entry :
	';'
	generic_interface_list_entry
	| <error>

generic_interface_list_entry : 
	identifier_comma_identifier ':'
	subtype_indication 
	default_value(?) 
	| <error>

default_value : 
	':=' static_expression

generic_map_section : 
	reserved_word_generic 
	reserved_word_map 
	optional_generic_association_list(?)   
	| <error>

optional_generic_association_list :
	'(' generic_association_list ')' 
	| <error>

generic_association_list : 
	association_list 
	| <error>


####
# ports
####
port_declaration_section : 
	reserved_word_port 
	port_interface_list(?) ';'
	| <error>

port_interface_list : 
	'('
 	port_interface_list_entry_semicolon_port_interface_list_entry
	 ')' 
	| <error>

port_interface_list_entry_semicolon_port_interface_list_entry :
	port_interface_list_entry
	semicolon_port_interface_list_entry(s?)
	| <error>

semicolon_port_interface_list_entry :
	';'
	port_interface_list_entry
		| <error>

port_interface_list_entry : 
	port_name_comma_port_name 
	':'
	mode
	subtype_indication 
	default_value(?)  
	| <error>

port_name_comma_port_name :
	port_name
	comma_port_name(s?)
	| <error>

comma_port_name :
	','
	port_name

port_map_section : 
	reserved_word_port 
	reserved_word_map 
	optional_port_association_list(?)   
	| <error>

optional_port_association_list :
	'(' port_association_list ')' 
	| <error>

port_association_list : 
	association_list 
	| <error>


####
# parameters to procedure/function call
####
subprogram_parameter_section : 
	'(' parameter_association_list ')' 
	| <error>

parameter_association_list :
	association_list 
	| <error>

####
# instance labels
####

instantiation_label : identifier 

####
# signals
####
signal_name_comma_signal_name :
	signal_name
	comma_signal_name(s?)

comma_signal_name :
	','
	signal_name

signal_name : identifier


digit :
	/[0-9]/



########################################################
# oddball rules, need to confirm correctness
########################################################
procedure_name : identifier
function_name : identifier 
component_name : identifier 
architecture_name : identifier
configuration_name : identifier 
architecture_identifier : identifier
variable_name : identifier
generic_name : identifier
port_name : identifier
parameter_name : identifier
process_label : identifier
group_template_name : identifier
block_label : identifier
type_name : identifier
subtype_name : identifier
generate_label : identifier
resolution_function_name : identifier 
physical_literal : identifier

range_attribute_name : attribute_name

guard_expression : expression_rule
value_expression : expression_rule 
string_expression : expression_rule
time_expression : expression_rule 
file_open_kind_expression : expression_rule

static_expression : identifier

element_subtype_indication : subtype_indication

time_units : 
	'fs' | 'ps' | 'ns' | 'us' | 'ms' | 'sec' | 'min' | 'hr'


# given:
# (1 downto 0)
# 
# the '1 downto' gets confused as a decimal_literal_unit_name
# where 'downto' is the unit_name.
#
# unit_name is generally just an identifier, but to keep
# 'to' or 'downto' or similar confusions,
# unit_name will need to know the valid units available.
#
unit_name : time_units

#END_OF_GRAMMAR

	};   # end of return statement


} #end of sub grammar

#########################################################################
sub decomment_given_text
#########################################################################
{
 my ($obj,$text)=@_;

 my $filtered_text='';

 my $state = 'code';

 my ( $string_prior_to_comment, $string_after_comment);
 my ( $string_prior_to_quote, $string_after_quote);
 my ( $comment_string, $string_after_comment_string);
 my ( $quoted_string, $string_after_quoted_string);

 my $index_to_comment=0;
 my $index_to_quote =0;

 while (1)
  {
  if ($state eq 'code')
	{

	unless ( ($text =~ /--/) or ($text =~ /\"/) )
		{ 
		$filtered_text .= $text ;
		last;
		}


	# look for comment or quoted string
	( $string_prior_to_comment, $string_after_comment)
		= split( /--/ , $text, 2 );

	( $string_prior_to_quote, $string_after_quote)
		= split( /\"/ , $text, 2 );

	$index_to_comment = length($string_prior_to_comment);
	$index_to_quote   = length($string_prior_to_quote  );


	if($index_to_quote < $index_to_comment)
		{
		$state = 'quote'; 
		$filtered_text .= $string_prior_to_quote;
		$text =  $string_after_quote;
		$filtered_text .= '"' ;
		}
	else
		{ 
		$state = 'comment';
		$filtered_text .= $string_prior_to_comment;
		$text = '--' . $string_after_comment;
		}
	}

  elsif ($state eq 'comment')
	{
	# strip out everything from here to the next \n charater
	( $comment_string, $string_after_comment_string)
		= split( /\n/ , $text, 2  );

	$text = "\n" . $string_after_comment_string;

	$state = 'code';
	}

  elsif ($state eq 'quote')
	{
	# get the text until the next quote mark and keep it as a string
	( $quoted_string, $string_after_quoted_string)
		= split( /"/ , $text, 2  );

	$filtered_text .= $quoted_string . '"' ;
	$text =  $string_after_quoted_string;

	$state = 'code';
	}
  }

 ###################
 # make everything lower case, VHDL identifiers are case insensitive
 ###################
 ### $filtered_text = lc($filtered_text);  
  ## well, maybe this isn't such a good solution after all.

 return $filtered_text;

}


#########################################################################
sub Filename
#########################################################################
{
 my $obj = shift;

 while(@_)
	{
	my $filename = shift;
 	my $text = $obj->filename_to_text($filename);
 	$text = $obj->decomment_given_text($text);
 	$obj->design_file($text);
	}
}

#########################################################################
sub filename_to_text
#########################################################################
{
 my ($obj,$filename)=@_;
 open (FILE, $filename) or die "Cannot open $filename for read\n";
 my $text;
 while(<FILE>)
  {
  $text .= $_;
  }
 return $text;
}


#########################################################################
#########################################################################
#########################################################################
#########################################################################
#########################################################################
1;
__END__
#########################################################################
#########################################################################
#########################################################################
#########################################################################
#########################################################################
#########################################################################
#########################################################################

=head1 NAME

Hardware::Vhdl::Parser - A complete grammar for parsing VHDL code using perl

=head1 SYNOPSIS

  use Hardware::Vhdl::Parser;
  $parser = new Hardware::Vhdl::Parser;

  $parser->Filename(@ARGV);

=head1 DESCRIPTION


This module defines the complete grammar needed to parse any VHDL code.
By overloading this grammar, it is possible to easily create perl scripts
which run through VHDL code and perform specific functions.

For example, a Hierarchy.pm uses Hardware::Vhdl::Parser to overload the
grammar rule for component instantiations. This single modification
will print out all instance names that occur in the file being parsed.
This might be useful for creating an automatic build script, or a graphical
hierarchical browser of a VHDL design.

This module is currently in Beta release. All code is subject to change.
Bug reports are welcome.



DSLI information:


D - Development Stage

	a - alpha testing

S - Support Level

	d - developer

L - Language used

	p - perl only, no compiler needed, should be platform independent

I - Interface Style

	O - Object oriented using blessed references and / or inheritance




=head1 AUTHOR


Copyright (C) 2000 Greg London   All Rights Reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

email contact: greg42@bellatlantic.net

=head1 SEE ALSO

Parse::RecDescent version 1.77

perl(1).


=cut

