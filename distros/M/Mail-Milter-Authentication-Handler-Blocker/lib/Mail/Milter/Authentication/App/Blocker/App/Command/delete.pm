package Mail::Milter::Authentication::App::Blocker::App::Command::delete;
# ABSTRACT: Command to delete a block for a given file
our $VERSION = '2.20191120'; # VERSION
use 5.20.0;
use Mail::Milter::Authentication::App::Blocker::Pragmas;
use Mail::Milter::Authentication::App::Blocker::App -command;
use TOML;
use Text::Table;

sub abstract { 'Delete a block in a given file' }
sub description { 'Delete a block from a given toml file' };

sub opt_spec {
  return (
    [ 'file=s', 'Config file to operate on' ],
    [ 'id=s', 'ID of the block to delete' ],
  );
}

sub validate_args($self,$opt,$args) {
  # no args allowed but options!
  $self->usage_error('Must supply a filename') if ( !$opt->{file} );
  $self->usage_error('Supplied filename does not exist') if ( ! -e $opt->{file} );
  $self->usage_error('Must supply an id') if ( !$opt->{id} );
  $self->usage_error('No args allowed') if @$args;
}

sub execute($self,$opt,$args) {

  open ( my $inf, '<', $opt->{file} );
  my $body = do { local $/; <$inf> };
  close $inf;
  my ( $data, $error ) = from_toml( $body );

  if ( $error ) {
    say 'Error parsing file';
    say $error;
    exit 1;
  }

  if ( ! exists $data->{$opt->{id}} ) {
    say 'The given ID does not exist in that file';
    exit 1;
  }

  delete $data->{$opt->{id}};
  open my $outf, '>', $opt->{file};
  print $outf to_toml($data);
  close $outf;

  say 'Block deleted and file saved';

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::Milter::Authentication::App::Blocker::App::Command::delete - Command to delete a block for a given file

=head1 VERSION

version 2.20191120

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
