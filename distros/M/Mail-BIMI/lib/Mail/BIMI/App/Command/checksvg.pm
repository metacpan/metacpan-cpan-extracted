package Mail::BIMI::App::Command::checksvg;
# ABSTRACT: Check an SVG for validation
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Indicator;
use File::Slurp qw{ read_file write_file };
use Term::ANSIColor qw{ :constants };


sub description { 'Check a SVG from a given URI or File for validity' }
sub usage_desc { "%c checksvg %o <URI>" }

sub opt_spec {
  return (
    [ 'profile=s', 'SVG Profile to validate against ('.join('|',@Mail::BIMI::Indicator::VALIDATOR_PROFILES).')' ],
    [ 'fromfile', 'Fetch from file instead of from URI' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No URI specified') if !@$args;
 $self->usage_error('Multiple URIs specified') if scalar @$args > 1;
 $self->usage_error('Unknown SVG Profile') if $opt->profile && !grep {;$_ eq $opt->profile} @Mail::BIMI::Indicator::VALIDATOR_PROFILES;
}

sub execute($self,$opt,$args) {
  my $uri = $args->[0];
  my $bimi = Mail::BIMI->new(domain=>'example.com');

  my %bimi_opt = (
    bimi_object => $bimi,
  );
  if ( $opt->fromfile ) {
    my $data = scalar read_file($uri);
    $bimi_opt{data} = $data;
  }
  else {
    $bimi_opt{uri} = $uri;
  }

  my $indicator = Mail::BIMI::Indicator->new(%bimi_opt);
  $indicator->validator_profile($opt->profile) if $opt->profile;
  say "BIMI SVG checker";
  say '';
  say 'Requested:';
  say YELLOW.($opt->fromfile?'File':'URI').WHITE.': '.$uri.RESET;
  say '';
  $indicator->app_validate;
  say '';

  $bimi->finish;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::App::Command::checksvg - Check an SVG for validation

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checksvg' command

=head1 REQUIRES

=over 4

=item * L<File::Slurp|File::Slurp>

=item * L<Mail::BIMI|Mail::BIMI>

=item * L<Mail::BIMI::App|Mail::BIMI::App>

=item * L<Mail::BIMI::Indicator|Mail::BIMI::Indicator>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Term::ANSIColor|Term::ANSIColor>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
