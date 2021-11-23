package Google::RestApi::Auth::ServiceAccount;

our $VERSION = '0.9';

use Google::RestApi::Setup;

use WWW::Google::Cloud::Auth::ServiceAccount ();

use parent 'Google::RestApi::Auth';

sub new {
  my $class = shift;

  my %p = @_;
  # order is important, resolve the overall config file first.
  resolve_config_file_path(\%p, 'config_file');
  resolve_config_file_path(\%p, 'account_file');
  
  my $self = config_file(%p);
  state $check = compile_named(
    config_dir   => ReadableDir, { optional => 1 },
    config_file  => ReadableFile, { optional => 1 },
    account_file => ReadableFile,
    scope        => ArrayRef[Str],
  );
  $self = $check->(%$self);
  $self = bless $self, $class;

  my $auth = WWW::Google::Cloud::Auth::ServiceAccount->new(
    credentials_path => $self->{account_file},
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
    or LOGDIE "Service Account Auth failed";
  return $self->{access_token};
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
