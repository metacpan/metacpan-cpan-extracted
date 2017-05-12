# ABSTRACT: Write chunked files from the shell.
package File::Chunk::Script::Write;
{
  $File::Chunk::Script::Write::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Script::Write::AUTHORITY = 'cpan:DHARDISON';
}
use Moose;
use namespace::autoclean;

use MooseX::Types::Path::Class 'File';
use File::Chunk::Handle;

with 'File::Chunk::Script';

has 'output_file' => (
    traits    => ['Getopt'],
    is        => 'ro',
    isa       => File,
    coerce    => 1,
    required  => 1,
    cmd_aliases => 'o',
);

has 'key' => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has 'limit' => (
    traits      => ['Getopt'],
    is          => 'ro',
    isa         => 'Int',
    cmd_aliases => 'l',
    predicate   => 'has_limit',
);

sub new_handle { 
    my ($self, $file) = @_;
    
    return File::Chunk::Handle->new(file => $file);
}


sub run {
    my $self = shift;
    my $h      = $self->new_handle($self->output_file);
    my $writer = $h->new_writer($self->key, $self->has_limit ? ( $self->limit ) : () );

    while (<STDIN>) {
        $writer->print($_);
    }
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

File::Chunk::Script::Write - Write chunked files from the shell.

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
