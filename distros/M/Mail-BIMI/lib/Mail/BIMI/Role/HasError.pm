package Mail::BIMI::Role::HasError;
# ABSTRACT: Class to model an error
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use Mail::BIMI::Trait::Cacheable;
use Mail::BIMI::Trait::CacheSerial;
use Mail::BIMI::Error;
use Sub::Install;

has errors => ( is => 'rw', isa => 'ArrayRef', lazy => 1, default => sub{return []}, traits => ['Cacheable','CacheSerial'] );



sub serialize_errors($self) {
  my @data = map {{
    code => $_->code,
    detail => $_->detail,
  }} $self->errors->@*;
  return \@data;
}


sub deserialize_errors($self,$value) {
  foreach my $error ($value->@*) {
    my $error_object = Mail::BIMI::Error->new(
      code => $error->{code},
      ( $error->{detail} ? ( detail => $error->{detail} ) : () ),
    );
    $self->add_error_object($error_object);
  }
}


sub add_error($self,$code,$detail=undef) {
  my $error = Mail::BIMI::Error->new(
    code=>$code,
    ($detail?(detail=>$detail):()),
  );
  $self->add_error_object($error);
}


sub add_error_object($self,$error) {
  if ( ref $error eq 'ARRAY' ) {
    foreach my $suberror ( $error->@* ){
        $self->add_error_object($suberror);
    }
  }
  else {
    $self->log_verbose(join(' : ',
      'Error',
      $error->code,
      $error->description,
      ( $error->detail ? $error->detail : () ),
    ));
    push $self->errors->@*, $error;
  }
}


sub error_codes($self) {
  my @error_codes = map { $_->code } $self->errors->@*;
  return \@error_codes;
}


sub filter_errors($self,$error) {
  return grep { $_->code eq $error } $self->errors->@*;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Role::HasError - Class to model an error

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Role for handling validation errors

=head1 METHODS

=head2 I<serialize_errors()>

Serialize the errors property for cache storage

=head2 I<deserialize_errors($value)>

De-serialize the errors property for cache storage

=head2 I<add_error($code,$detail)>

Add an error with the given code and optional detail to the current operation.

=head2 I<add_error_object($error)>

Add an existing error object, or objects, to the current operation

=head2 I<error_codes>

Return an ArrayRef of current error codes

=head2 I<filter_errors($error)>

Return error(s) matching the given error code

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Error|Mail::BIMI::Error>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::Trait::CacheSerial|Mail::BIMI::Trait::CacheSerial>

=item * L<Mail::BIMI::Trait::Cacheable|Mail::BIMI::Trait::Cacheable>

=item * L<Moose::Role|Moose::Role>

=item * L<Sub::Install|Sub::Install>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
