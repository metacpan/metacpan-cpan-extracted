package Mail::BIMI::Role::Data;
# ABSTRACT: Class to retrieve data files
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use File::Slurp qw{ read_file write_file };



sub get_file_name($self,$file) {
  my $base_file = __FILE__;
  $base_file =~ s/\/Role\/Data.pm$/\/Data\/$file/;
  if ( ! -e $base_file ) {
    die "File $file is missing";
  }
  return $base_file;
}


sub get_data_from_file($self,$file) {
  my $base_file = $self->get_file_name($file);
  my $body = read_file($base_file);
  return $body;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Role::Data - Class to retrieve data files

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Role for classes which require access to locally packaged files

=head1 METHODS

=head2 I<get_file_name($file)>

Returns the full path and filename for included file $file

=head2 I<get_data_from_file($file)>

Returns the contents of included file $file

=head1 REQUIRES

=over 4

=item * L<File::Slurp|File::Slurp>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose::Role|Moose::Role>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
