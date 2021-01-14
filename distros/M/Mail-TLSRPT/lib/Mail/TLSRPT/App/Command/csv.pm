package Mail::TLSRPT::App::Command::csv;
# ABSTRACT: Process tlsrpt reports into csv
our $VERSION = '2.20210112'; # VERSION
use 5.20.0;
use Mail::TLSRPT::Pragmas;
use Mail::TLSRPT::App -command;
use Mail::TLSRPT::Report;


sub abstract { 'Process tlsrpt files into csv' }
sub description { 'Process tlsrpt files and output as csv' };
sub usage_desc { "%c csv %o FILE <FILE> <FILE>" }

sub opt_spec {
  return (
    [ 'output=s', 'Write results to filename (defaults to STDOUT)' ],
  );
}

sub validate_args($self,$opt,$args) {
  $self->usage_error('No files specified') if !@$args;
}

sub execute($self,$opt,$args) {

  my $tlsrpt;

  my @all_output;
  my $add_header = 1;

  foreach my $file ( $args->@* ) {

    $self->usage_error("File $file does not exist") if ! -e $file;

    open my $fh, '<', $file or die 'Could not open input file';
    my @file_contents = <$fh>;
    close $fh;
    my $payload = join('',@file_contents);

    my $tlsrpt = eval{ Mail::TLSRPT::Report->new_from_json($payload) };
    my $error = $@;

    if ( $tlsrpt ) {
        push @all_output, $tlsrpt->as_csv({add_header=>$add_header});
        $add_header = 0;
    }
    else {
        warn "Could not parse file $file: $error";
    }

  }

  my $output= join("\n",@all_output);

  if ( $opt->output ) {
    open my $fh, '>', $opt->output or die 'Could not open output file';
    print $fh $output;
    close $fh;
  }
  else {
    say $output;
  }

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::TLSRPT::App::Command::csv - Process tlsrpt reports into csv

=head1 VERSION

version 2.20210112

=head1 DESCRIPTION

App::Cmd class implementing the 'tlsrpt csv' command

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
