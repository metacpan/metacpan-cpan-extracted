package HTML::FormFu::Constraint::DBIC::Unique;

use strict;
our $VERSION = '2.02'; # VERSION

use Moose;
use MooseX::Attribute::FormFuChained;

extends 'HTML::FormFu::Constraint';

use Carp qw( carp croak );

use HTML::FormFu::Util qw( DEBUG_CONSTRAINTS debug );

has model          => ( is => 'rw', traits  => ['FormFuChained'] );
has resultset      => ( is => 'rw', traits  => ['FormFuChained'] );
has column         => ( is => 'rw', traits  => ['FormFuChained'] );
has method_name    => ( is => 'rw', traits  => ['FormFuChained'] );
has self_stash_key => ( is => 'rw', traits  => ['FormFuChained'] );
has others         => ( is => 'rw', traits  => ['FormFuChained'] );
has id_field       => ( is => 'rw', traits  => ['FormFuChained'] );

sub constrain_value {
    my ( $self, $value ) = @_;

    return 1 if !defined $value || $value eq '';

    for (qw/ resultset /) {
        if ( !defined $self->$_ ) {
            # warn and die, as errors are swallowed by HTML-FormFu
            carp  "'$_' is not defined";
            croak "'$_' is not defined";
        }
    }

    # get stash
    my $stash = $self->form->stash;

    my $schema;

    if ( defined $stash->{schema} ) {
        $schema = $stash->{schema};
    }
    elsif ( defined $stash->{context} && defined $self->model ) {
        $schema = $stash->{context}->model( $self->model );
    }
    elsif ( defined $stash->{context} ) {
        $schema = $stash->{context}->model;
    }

    if ( !defined $schema ) {
        # warn and die, as errors are swallowed by HTML-FormFu
        carp  'could not find DBIC schema';
        croak 'could not find DBIC schema';
    }

    my $resultset = $schema->resultset( $self->resultset );

    if ( !defined $resultset ) {
        # warn and die, as errors are swallowed by HTML-FormFu
        carp  'could not find DBIC resultset';
        croak 'could not find DBIC resultset';
    }

    if ( my $method_name = $self->method_name ) {
		# warn  "using $method_name to look for $value";

		# need to be able to tell $method_name about record on the form stash
		my $pk_val;

		if ( defined( my $self_stash_key = $self->self_stash_key ) ) {

			if ( defined( my $self_stash = $stash->{ $self_stash_key } ) ) {

				my ($pk) = $resultset->result_source->primary_columns;

				$pk_val = $self_stash->$pk;
			}
		}

    	return $resultset->$method_name( $value, $pk_val );
    }
    else {

		my $column = $self->column || $self->parent->name;
		my %others;
		if ( $self->others ) {
			my @others = ref $self->others ? @{ $self->others }
						   : $self->others;

			my $params = $self->form->input;

			%others =
                grep {
                    defined && length
                }
                map {
                    $_ => $self->get_nested_hash_value( $params, $_ )
                } @others;

		}

		my $existing_row = eval {
			$resultset->find( { %others, $column => $value } );
		};

		if ( my $error = $@ ) {
			# warn and die, as errors are swallowed by HTML-FormFu
			carp  $error;
			croak $error;
		}

		# if a row exists, first check whether it matches a known object on the
		# form stash

		if ( $existing_row && defined( my $self_stash_key = $self->self_stash_key ) ) {

			if ( defined( my $self_stash = $stash->{ $self_stash_key } ) ) {

				my ($pk) = $resultset->result_source->primary_columns;

				if ( $existing_row->$pk eq $self_stash->$pk ) {
					return 1;
				}
			}
		}
        elsif ( $existing_row && defined (my $id_field = $self->id_field ) ) {
            my $value = $self->get_nested_hash_value( $self->form->input, $id_field );
            if ( defined $value && length $value ) {
                my ($pk) = $resultset->result_source->primary_columns;
                return ($existing_row->$pk eq $value);
            }
        }

		return !$existing_row;

    }
}

after repeatable_repeat => sub {
    my ( $self, $repeatable, $new_block ) = @_;

    # rename any 'id_field' fields
	if ( my $id_field = $self->id_field ) {
		my $block_fields = $new_block->get_fields;

		my $field = $repeatable->get_field_with_original_name( $id_field, $block_fields );

		if ( defined $field ) {
			DEBUG_CONSTRAINTS && debug(
				sprintf "Repeatable renaming constraint 'id_field' '%s' to '%s'",
					$id_field,
					$field->nested_name,
			);

			$self->id_field( $field->nested_name );
		}
	}
};

1;

__END__

=head1 NAME

HTML::FormFu::Constraint::DBIC::Unique - unique constraint for HTML::FormFu::Model::DBIC

=head1 VERSION

version 2.02

=head1 SYNOPSIS

    $form->stash->{schema} = $dbic_schema; # DBIC schema

    $form->element('text')
         ->name('email')
         ->constraint('DBIC::Unique')
         ->resultset('User')
         ;


    $form->stash->{context} = $c; # Catalyst context

    $form->element('text')
         ->name('email')
         ->constraint('DBIC::Unique')
         ->model('DBIC::User')
         ;

    $form->element('text')
         ->name('user')
         ->constraint('DBIC::Unique')
         ->model('DBIC')
         ->resultset('User')
         ;


    or in a config file:
    ---
    elements:
      - type: text
        name: email
        constraints:
          - Required
          - type: DBIC::Unique
            model: DBIC::User
      - type: text
        name: user
        constraints:
          - Required
          - type: DBIC::Unique
            model: DBIC::User
            column: username


=head1 DESCRIPTION

Checks if the input value exists in a DBIC ResultSet.

=head1 METHODS

=head2 model

Arguments: $string # a Catalyst model name like 'DBIC::User'

=head2 resultset

Arguments: $string # a DBIC resultset name like 'User'

=head2 self_stash_key

reference to a key in the form stash. if this key exists, the constraint
will check if the id matches the one of this element, so that you can
use your own name.

=head2 id_field

Use this key to define reference field which consist of primary key of
resultset. If the field exists (and $self_stash_key not defined), the
constraint will check if the id matches the primary key of row object:

    ---
    elements:
      - type:  Hidden
        name:  id
        constraints:
          - Required

      - type:  Text
        name:  value
        label: Value
        constraints:
          - Required
          - type:       DBIC::Unique
            resultset:  ControlledVocab
            id_field:   id

=head2 others

Use this key to manage unique compound database keys which consist of
more than one column. For example, if a database key consists of
'category' and 'value', use a config file such as this:

    ---
    elements:
      - type:  Text
        name:  category
        label: Category
        constraints:
          - Required

      - type:  Text
        name:  value
        label: Value
        constraints:
          - Required
          - type:       DBIC::Unique
            resultset:  ControlledVocab
            others:     category

=head2 method_name

Name of a method which will be called on the resultset. The method is passed
two argument; the value of the field, and the primary key value (usually `id`)
of the record in the form stash (as defined by self_stash_key). An example
config might be:

    ---
    elements:
      - type: text
        name: user
        constraints:
          - Required
          - type: DBIC::Unique
            model: DBIC::User
            method_name: is_username_available


=head2 SEE ALSO

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

L<HTML::FormFu::FormFu>

=head1 AUTHOR

Jonas Alves C<jgda@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.
