package EO::Data;

use strict;
use warnings;

use EO;
use NEXT;
use Scalar::Util qw(weaken);
use EO::Hash;
#use EO::Locale;

our $VERSION = 0.96;
our @ISA = qw(EO);

exception EO::Error::InvalidParameter;

sub init {
  my $self = shift;
  my $string = '';
  if ($self->NEXT::init( @_ )) {
    $self->{e_data_content} = \$string;
    $self->{e_data_storage} = {};
    return 1;
  }
  return 0;
}

sub length {
  my $self = shift;
  return length( $self->content );
}

sub locales {
  my $self = shift;
  if (@_) {
    $self->{ e_data_locales} = shift;
    return $self;
  }
  return $self->{ e_data_locales };
}

sub locale {
  my $self = shift;
  if (@_) {
    $self->{ e_data_locale } = shift;
    return $self;
  }
  return $self->{ e_data_locale };
}

sub delete_storage {
  my $self = shift;
  my $storage = shift;
  if (!UNIVERSAL::isa($storage,  'EO::Storage')) {
    throw EO::Error::InvalidParameter
      text => 'storage must be an EO::Storage object';
  }
  delete($self->{e_data_storage}->{$storage});
  return $self;
}


sub add_storage {
  my $self = shift;
  my $storage = shift;
  if (!UNIVERSAL::isa($storage,  'EO::Storage')) {
    throw EO::Error::InvalidParameter
      text => 'storage must be an EO::Storage object';
  }
  $self->{e_data_storage}->{$storage} = $storage;
  weaken($self->{e_data_storage}->{$storage});
  return $self;
}

sub storage {
  my $self = shift;
  if(@_) {
    my $storage = shift;
    if (!UNIVERSAL::isa($storage,  'EO::Storage')) {
      throw EO::Error::InvalidParameter
	text => 'storage must be an EO::Storage object';
    }
    $self->{e_data_storage} = { $storage => $storage };
    weaken( $self->{e_data_storage}->{ $storage } );
    return $self;
  }
  return values %{$self->{e_data_storage}};
}

sub content {
  my $self = shift;
  if(@_) {
    my $content = shift;
    if(ref($content) eq 'SCALAR') {
      $self->{e_data_content} = $content;
    } elsif(ref($content) && $content->isa('EO::Data')) {
      $self->content($content->content_ref);
    } else {
      ${$self->{e_data_content}} = $content;
    }
    return $self;
  }
  return ${$self->{e_data_content}};
}

sub save {
  my $self = shift;
  foreach my $storage (values %{$self->{e_data_storage}}) {
    $storage->save($self);
  }
  return $self;
}

sub content_ref {
  my $self = shift;
  return $self->{e_data_content};
}

1;

__END__

=head1 NAME

EO::Data - holds data

=head1 SYNOPSIS

  use EO::Data;
  use EO::File;

  my $file    = EO::File->new( path => './myfile' );
  my $data    = $file->load();

  my $length  = $data->length();
  my $content = $data->content();

  

=head1 DESCRIPTION

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.


=head1 SEE ALSO

=cut


