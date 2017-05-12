package Form::Toolkit::Form;
{
  $Form::Toolkit::Form::VERSION = '0.008';
}
require 5.010_000;
use Moose -traits => 'Form::Toolkit::Meta::Class::Trait::HasID';
use Class::Load;

use Form::Toolkit::Clerk::Hash;

use Form::Toolkit::Field;
use Form::Toolkit::Field::String;

use JSON;
use MIME::Base64;
use Scalar::Util;


with qw(MooseX::Clone);

=head1 NAME

Form::Toolkit::Form - A Moose base class for Form implementation

=cut

__PACKAGE__->meta->id_prefix('form_');

has 'jsoner' => ( isa => 'JSON' , is => 'ro', required => 1, lazy_build => 1);

has 'fields' => ( isa => 'ArrayRef[Form::Toolkit::Field]', is => 'ro' , required => 1 , default => sub{ [] } ,
                traits => ['Clone']);
has '_fields_idx' => ( isa => 'HashRef[Int]', is => 'ro' , required => 1, default => sub{ {} },
                     traits => [ 'Clone' ]);
has '_field_next_num' => ( isa => 'Int' , is => 'rw' , default => 0 , required => 1 ,
                         traits => ['Clone']);
has 'errors' => ( isa => 'ArrayRef[Str]' , is => 'rw' , default => sub{ [] } , required => 1 ,
                traits => [ 'Clone' ]);
has 'submit_label' => ( isa => 'Str' , is => 'rw' , default => 'Submit', required => 1 ,
                      traits => [ 'Clone' ]);

=head2 BUILD

Hooks in the Moose BUILD to call build_fields

=cut

sub BUILD{
  my ($self) = @_;
  $self->build_fields();
}

sub _build_jsoner{
  my ($self) = @_;
  return JSON->new->ascii(1)->pretty(0);
}


=head2 fast_clone

Returns fast clone of this form. This is field value focused and as shallow as possible,
so use with care if you want to change anything else than field values in your clones.

Benchmarking has shown this is 50x faster than the MooseX::Clone based clone method.

Usage:

 my $clone = $this->fast_clone();

=cut

sub fast_clone{
  my ($self) = @_;
  my $new_fields = [ map { $_->fast_clone() } @{ $self->fields() } ];
  return bless { %$self , fields => $new_fields } , Scalar::Util::blessed($self);
}

=head2 id

Shortcut to $this->meta->id();

=cut

sub id{
  my ($self) = @_;
  my ($package, $filename, $line) = caller;
  warn "Calling ->id() from $package ($filename: $line) is deprecated. Please use ->meta->id() instead";
  return $self->meta->id();
}

=head2 do_accept

Accepts a form visitor returns this visitor's visit_form method returned value.

Usage:

  my $result = $this->do_accept($visitor);

=cut

sub do_accept{
  my ($self, $visitor) = @_;
  unless( $visitor->can('visit_form') ){
    confess("Visitor $visitor cannot 'visit_form'");
  }
  return $visitor->visit_form($self);
}

=head2 build_fields

Called after Form creation to add_field to $self.

This should be the method you need to implement in your subclasses.

Usage:

  sub build_fields{
    my ($self) = @_;
    $self->add_field('Date' , 'a_date_field');
    $self->add_field('String' , 'a string field');
    # etc..
  }

=cut

sub build_fields{}

=head2 add_error

Adds an error to this form (as a string).

 $this->add_error('Something is globally wrong');

=cut

sub add_error{
  my ($self , $error) = @_;
  push @{$self->errors()} , $error;
}

=head2 add_field

Usage:

   $this->add_field('field_name');
   $this->add_field('FieldType', 'field_name'); ## 'FieldType' is turned into Form::Toolkit::Field::FieldType'.
   $this->add_field($field_instance);

=cut

sub add_field{
  my ($self, @rest)  = @_;

  my $field = shift @rest;
  if( ref($field) && $field->isa('Form::Toolkit::Field') ){
    return $self->_add_field($field);
  }
  if( ref( $field ) ){ confess("Argument $field not supported") ; }

  ## Field is not a ref at this point.
  my $name = shift @rest;
  ## defaut is to be a string.
  unless( $name ){ $name = $field , $field = 'String' ; }

  ## Try to load classes.
  my $ret;
  eval{
    my $f_class = $field;
    if( $f_class =~ /^\+/ ){
      $f_class =~ s/^\+//;
    }else{
      $f_class = 'Form::Toolkit::Field::'.$f_class;
    }
    Class::Load::load_class( $f_class );
    my $new_instance = $f_class->new({ form => $self , name => $name  });
    $ret =  $self->_add_field($new_instance);
  };
  unless( $@ ){ return $ret; }

  confess("Class $field is invalid: $@");
}

sub _add_field{
  my ($self , $field ) = @_;
  $field //= '';
  unless( ref($field) && $field->isa('Form::Toolkit::Field') ){ confess("Please give a JCOM::Form::Field Instance, not a $field"); }

  if( $self->field($field->name()) ){
    confess("A field named '".$field->name()."' already exists in this form");
  }

  push @{$self->fields()} , $field;
  ## set the index
  $self->_fields_idx->{$field->name()} = $self->_field_next_num();
  $self->_field_next_num($self->_field_next_num() + 1);
  return $field;
}

=head2 field

Get a field by name or undef.

Usage:

  my $field = $this->field('my_field');

=cut

sub field{
  my ($self, $name) = @_;
  my $idx = $self->_fields_idx->{$name};
  return defined $idx ? $self->fields->[$idx] : undef;
}

=head2 is_valid

Opposite of has_errors.

=cut

sub is_valid{
  my ($self) = @_;
  return ! $self->has_errors();
}

=head2 has_errors

Returns true if this form has errors, false otherwise.

Usage:

  if( $this->has_errors() ){
    ...
  }

=cut

sub has_errors{
  my ($self) = @_;
  return scalar(@{$self->errors()}) || grep { $_->has_errors }  @{$self->fields()};
}

=head2 dump_errors

Convenience debugging method.

Returns

 { _form => [ 'error1' , ... ],
   field1 => [ 'error' , ... ],
   field2 => [ 'error' , ... ],
   ...
 }

=cut

sub dump_errors{
  my ($self) = @_;
  my %field_errors = map{ $_->name() => $_->errors() } @{$self->fields()};
  return { _form => $self->errors(),
           %field_errors };
}

=head2 reset

Alias for clear. please override clear if you want. Don't touch this.

=cut

sub reset{
  goto &clear;
}

=head2 clear

Resets this form to its void state. After the call, this form is
ready to be used again.

=cut

sub clear{
  my ($self) = @_;
  $self->errors([]);
  map{ $_->clear() } @{$self->fields()};
}

=head2 values_hash

Returns a hash of values like that:

{
  a => 'aaa',
  b => 'bbb',
  multiplea => [ v1 , v2 , v3 ],
  multipleb => []
}

You can feed this hash to the L<Form::Toolkit::Clerk::Hash>
got populate a similar form.

=cut

sub values_hash{
  my ($self) = @_;

  my $ret = {};
  foreach my $field ( @{$self->fields()} ){
    $ret->{$field->name()} = $field->value_struct();
  }
  return $ret;
}

=head2 literal

Returns a litteral representation of this form (as a Base64 encoded JSON byte string).

Usage:

   print $this->litteral();

=cut

sub literal{
  my ($self) = @_;
  return MIME::Base64::encode_base64url(ref($self) .'|'. $self->jsoner()->encode($self->values_hash()));
}

=head2 from_literal

Class or instance method. Builds a new instance of form from the given litteral (See litteral).

If you are using Forms as other Form's field values, and if all your forms require
extra attribute, you can override that IN YOUR CONTAINER form. It will be called
as an instance method by the form filling Clerks. See example in test 11.

Usage:

  my $form = $this->from_literal($litteral);

=cut

sub from_literal{
  my ($class , $litteral, $attributes ) = @_;
  $attributes ||= {};
  my ($fclass, $json) = split('\|', MIME::Base64::decode_base64url($litteral) , 2 );
  my $jsoner = JSON->new();
  my $values_hash = $jsoner->decode($json);
  Class::Load::load_class($fclass);
  my $new_instance = $fclass->new(%$attributes);
  $new_instance->fill_hash($values_hash);
  return $new_instance;
}


=head2 fill_hash

Shortcut to fill this form with a pure Perl hash. After calling this,
the form will be validated and populated with error messages if necessary.

Usage:

 $this->fill_hash({ field1 => 'value' , field2 => undef , field3 => [ 'a' , 'b' , 'c' ]});

 $this->fill_hash($another_form->values_hash());

 if( $this->has_errors() ){

 }

=cut

sub fill_hash{
  my ($self, $hash) = @_;
  $hash //= {};
  Form::Toolkit::Clerk::Hash->new({ source => $hash })->fill_form($self);
}


__PACKAGE__->meta->make_immutable();
1; # End of Form::Toolkit::Form
