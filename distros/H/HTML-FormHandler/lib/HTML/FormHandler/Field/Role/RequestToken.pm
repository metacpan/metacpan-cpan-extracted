package HTML::FormHandler::Field::Role::RequestToken;
$HTML::FormHandler::Field::Role::RequestToken::VERSION = '0.40068';
use Moose::Role;


has 'token_prefix' => (
  is => 'rw',
  default => '',
);

has 'token_field_name' => (
  is => 'rw',
  default => '_token',
);

before 'update_fields' => sub {
  my $self = shift;

  my $token_field = $self->field($self->token_field_name);
  $token_field->token_prefix($self->token_prefix);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormHandler::Field::Role::RequestToken

=head1 VERSION

version 0.40068

=head1 SYNOPSIS

Role with Moose attributes necessary for the RequestToken field

=head1 NAME

HTML::FormHandler::Field::Role::RequestToken

=head1 AUTHOR

FormHandler Contributors - see HTML::FormHandler

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Gerda Shank.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
