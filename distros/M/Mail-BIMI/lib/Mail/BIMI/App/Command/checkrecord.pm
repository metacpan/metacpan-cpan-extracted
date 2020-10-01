package Mail::BIMI::App::Command::checkrecord;
# ABSTRACT: Validate a given BIMI assertion record
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Indicator;
use Mail::BIMI::Record;
use Mail::DMARC;
use Term::ANSIColor qw{ :constants };


sub description { 'Check a given BIMI assertion record' }
sub usage_desc { "%c checkrecord %o <RECORD>" }

sub opt_spec {
  return (
    [ 'profile=s', 'SVG Profile to validate against ('.join('|',@Mail::BIMI::Indicator::VALIDATOR_PROFILES).')' ],
    [ 'domain=s', 'Optional domain' ],
  );
}

sub validate_args($self,$opt,$args) {
 $self->usage_error('No Record specified') if !@$args;
 $self->usage_error('Multiple Records specified') if scalar @$args > 1;
 $self->usage_error('Unknown SVG Profile') if $opt->profile && !grep {;$_ eq $opt->profile} @Mail::BIMI::Indicator::VALIDATOR_PROFILES;
}

sub execute($self,$opt,$args) {
  my $check_record = $args->[0];
  my $domain = $opt->domain // '-none-';

  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->header_from($opt->domain // 'reject.test.fastmaildmarc.com');
  $dmarc->validate;
  $dmarc->result->result('pass');
  my $bimi = Mail::BIMI->new(
    dmarc_object => $dmarc,
    domain => $domain,
    options => {
      force_record => $check_record,
      vmc_no_check_alt => $opt->domain ? 0 : 1,
      ( $opt->profile ? ( svg_profile => $opt->profile ) : () ),
    }
  );

  my $record = $bimi->record;
  #  my $record = Mail::BIMI::Record->new( domain => $domain, selector => $selector );
  say "BIMI domain checker";
  say '';
  say 'Requested:';
  say YELLOW.'  Domain    '.WHITE.': '.CYAN.$domain.RESET;
  say YELLOW.'  Record    '.WHITE.': '.CYAN.$check_record.RESET;
  say '';
  $record->app_validate;
  if ( $record->location && $record->location->indicator ) {
    say '';
    $record->location->indicator->app_validate;
  }
  if ( $record->authority && $record->authority->vmc ) {
    say '';
    $record->authority->vmc->app_validate;
    if ( $record->authority->vmc->indicator ) {
        say '';
        $record->authority->vmc->indicator->app_validate;
    }
  }
  say '';

  say 'An authenticated email with this record would receive the following BIMI results:';
  say '';
  my $result = $bimi->result;
  say "Authentication-Results: authservid.example.com; ".$result->get_authentication_results;
  my $headers = $result->headers;
  foreach my $header ( sort keys $headers->%* ) {
      say "$header: ".$headers->{$header};
  }

  $bimi->finish;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::App::Command::checkrecord - Validate a given BIMI assertion record

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi checkdomain' command

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI|Mail::BIMI>

=item * L<Mail::BIMI::App|Mail::BIMI::App>

=item * L<Mail::BIMI::Indicator|Mail::BIMI::Indicator>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::Record|Mail::BIMI::Record>

=item * L<Mail::DMARC|Mail::DMARC>

=item * L<Term::ANSIColor|Term::ANSIColor>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
