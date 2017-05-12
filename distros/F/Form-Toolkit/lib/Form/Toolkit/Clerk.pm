package Form::Toolkit::Clerk;
{
  $Form::Toolkit::Clerk::VERSION = '0.008';
}
use Moose;
use DateTime::Format::ISO8601;
use JSON;

has 'source' => ( required => 1 , is => 'ro' );

has '_date_parser' => ( is => 'ro' , default => sub{ DateTime::Format::ISO8601->new() });

=head1 NAME

Form::Toolkit::Clerk - A form clerk that can fill a form from some source.

=head2 SYNOPSIS

A Clerk knows how to fill a form from the input it expects.

=cut

=head2 fill_form

Fill the given form from the given source.

Usage:

  $this->fill_form($form);

=cut


sub fill_form{
  my ($self , $form) = @_;
  $form->do_accept($self);
}

sub _get_source_value{
  my ($self, $field) = @_;
  confess("Please implement that on $self");
}

=head2 visit_form

Fills the given form with values from the source hash.

See superclass L<Form::Toolkit::Clerk> for details.

=cut

sub visit_form{
  my ($self, $form) = @_;

  foreach my $field ( @{$form->fields()} ){
    my $m = '_fill_field_'.$field->meta->short_class();
    $self->$m($field, $form);
    $field->validate();
  }
  return $form;
}

sub _fill_field_Integer{
  my ($self, $field) = @_;
  my $int_str = $self->_get_source_value($field);
  unless( defined $int_str ){
    $field->clear_value();
    return;
  }

  if( $int_str !~ /-?\d+/ ){
    $field->add_error("Invalid Integer format. Please enter something like 123 (or -123)");
    return;
  }

  $field->value($int_str + 0);
}

sub _fill_field_Date{
  my ($self , $field) = @_;
  # Grab the date from the hash.
  if( my $date_str = $self->_get_source_value($field)  ){
    eval{
      $field->value($self->_date_parser()->parse_datetime($date_str));
    };
    if( $@ ){
      $field->add_error("Invalid date format in $date_str. Please use something like 2011-11-20");
    }
  }else{
    $field->clear_value();
  }
}

sub _fill_field_Form{
  my ($self, $field , $container_form ) = @_;
  my $str = $self->_get_source_value($field);
  unless(  $str ){
    $field->clear_value();
    return;
  }

  $field->value($container_form->from_literal($str));
}

sub _fill_field_String{
  my ($self, $field) = @_;
  my $str = $self->_get_source_value($field) ;
  if( defined $str ){
    $field->value($str);
  }else{
    $field->clear_value();
  }
}

sub _fill_field_Boolean{
  my ($self , $field) = @_;
  my $value = $self->_get_source_value($field);
  if( $value ){
    $field->value(1);
  }else{
    $field->clear_value();
  }
}

sub _fill_field_Set{
  my ($self, $field) = @_;
  my $value = $self->_get_source_value($field);
  unless( defined $value ){
    $field->clear_value();
    return;
  }

  unless( ref( $value ) eq 'ARRAY' ){
    $value = [ $value ];
  }

  $field->value($value);
}



__PACKAGE__->meta->make_immutable();
1;
