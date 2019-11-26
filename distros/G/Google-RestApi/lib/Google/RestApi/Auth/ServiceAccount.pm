package Google::RestApi::Auth::ServiceAccount;

use strict;
use warnings;

our $VERSION = '0.4';

use 5.010_000;

use autodie;
use Type::Params qw(compile_named);
use Types::Standard qw(Str ArrayRef);
use WWW::Google::Cloud::Auth::ServiceAccount;
use YAML::Any qw(Dump);

no autovivification;

use Google::RestApi::Utils qw(config_file resolve_config_file);

use parent 'Google::RestApi::Auth';

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  my $self = config_file(@_);
  state $check = compile_named(
    config_file        => Str, { optional => 1 },
    parent_config_file => Str, { optional => 1 },  # only used internally
    account_file       => Str,
    scope              => ArrayRef[Str],
  );
  $self = $check->(%$self);
  $self = bless $self, $class;

  my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
    credentials_path => $self->account_file(),
    # undocumented feature of WWW::Google::Cloud::Auth::ServiceAccount
    scope            => join(' ', @{ $self->{scope} }),
  );
  $self->{auth} = $auth;

  return $self;
}

sub headers {
  my $self = shift;
  my $access_token = $self->access_token();
  $self->{headers} = [ Authorization => "Bearer $access_token" ];
  return $self->{headers};
}

sub access_token {
  my $self = shift;
  $self->{access_token} = $self->{auth}->get_token()
    or die "Service Account Auth failed";
  return $self->{access_token};
}

sub account_file {
  my $self = shift;
  $self->{_account_file} = resolve_config_file('account_file', $self)
    if !$self->{_account_file};
  return $self->{_account_file};
}

1;

__END__

=head1 NAME

Google::RestApi::Auth::ServiceAccount - Service Account support for Google Rest APIs

=head1 SYNOPSIS

  use Google::RestApi::Auth::ServiceAccount;

  my $sa = Google::RestApi::Auth::ServiceAccount->new(
    account_file => <path_to_account_json_file>,
    scope        => ['http://spreadsheets.google.com/feeds/'],
  );
  # generate an access token from the code returned from Google:
  my $token = $sa->access_token($code);

=head1 AUTHOR

Robin Murray E<lt>mvsjes@cpan.ork<gt>.

=head1 SEE ALSO

L<WWW::Google::Cloud::Auth::ServiceAccount>

L<https://developers.google.com/accounts/docs/OAuth2> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
