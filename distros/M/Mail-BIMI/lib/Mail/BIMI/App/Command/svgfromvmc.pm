package Mail::BIMI::App::Command::svgfromvmc;
# ABSTRACT: Extract the SVG from a VMC
our $VERSION = '3.20240313'; # VERSION
use 5.20.0;
BEGIN { $ENV{MAIL_BIMI_CACHE_DEFAULT_BACKEND} = 'Null' };
use Mail::BIMI::Prelude;
use Mail::BIMI::App -command;
use Mail::BIMI;
use Mail::BIMI::Indicator;
use Mail::BIMI::VMC;
use File::Slurp;


sub description { 'Extract the SVG from a VMC' }
sub usage_desc { "%c svgfromvmc %o" }

sub opt_spec {
  return (
    [ 'domain=s', 'Extract SVG from VMC in BIMI record at domain' ],
    [ 'selector=s', 'Optional selector when domain specified' ],
    [ 'uri=s', 'Extract SVG from VMC at URI' ],
    [ 'file=s', 'Extract SVG from VMC in file' ],
    [ 'output=s', 'Write SVG to this file, if not specified will write to STDOUT' ],
  );
}

sub validate_args($self,$opt,$args) {
  $self->usage_error('Extra args specified') if scalar @$args;
  my $options;
  $options++ if $opt->domain;
  $options++ if $opt->uri;
  $options++ if $opt->file;
  $self->usage_error('Must specify domain, uri, or file') if $options==0;
  $self->usage_error('Must specify ONLY ONE of domain, uri, or file') if $options>1;
  $self->usage_error('Selector cannot be specified without domain') if $opt->selector && !$opt->domain;
}

sub execute($self,$opt,$args) {

  my $indicator;

  my $domain = $opt->domain // 'example.com';
  my $selector = $opt->selector // 'default';
  my $dmarc = Mail::DMARC::PurePerl->new;
  $dmarc->header_from($domain);
  $dmarc->validate;
  $dmarc->result->result('pass');
  my %bimi_options = (
    dmarc_object => $dmarc,
    domain => $domain,
    selector => $selector,
    options => {
      vmc_no_check_alt => 1,
    },
  );
  $bimi_options{options}->{vmc_from_file} = $opt->file if $opt->file;
  my $bimi = Mail::BIMI->new(%bimi_options);
  my $vmc;

  if ($opt->domain) {
    $vmc = eval{$bimi->record->authority->vmc};
    $indicator = eval{$vmc->indicator};
  }
  elsif($opt->uri) {
    $vmc = Mail::BIMI::VMC->new( check_domain => $domain, check_selector => $selector, uri => $opt->uri, bimi_object => $bimi );
    $indicator = eval{$vmc->indicator};
  }
  elsif($opt->file) {
    $vmc = Mail::BIMI::VMC->new( check_domain => $domain, check_selector => $selector, uri => $opt->file, bimi_object => $bimi );
    $indicator = eval{$vmc->indicator};
  }

  my $svg = eval{$indicator->data_uncompressed};
  if (!$svg) {
    warn "Could not extract SVG";
    exit 1;
  }

  if ($opt->output) {
    write_file($opt->output, $svg) || warn "Could not write file";
  }
  else {
    say $svg;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::App::Command::svgfromvmc - Extract the SVG from a VMC

=head1 VERSION

version 3.20240313

=head1 DESCRIPTION

App::Cmd class implementing the 'mailbimi svgfromvmc' command

=head1 REQUIRES

=over 4

=item * L<File::Slurp|File::Slurp>

=item * L<Mail::BIMI|Mail::BIMI>

=item * L<Mail::BIMI::App|Mail::BIMI::App>

=item * L<Mail::BIMI::Indicator|Mail::BIMI::Indicator>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::VMC|Mail::BIMI::VMC>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
