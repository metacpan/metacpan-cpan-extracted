package Flux::File::Cursor;
{
  $Flux::File::Cursor::VERSION = '1.01';
}

use Moo;

# ABSTRACT: file cursor

use MooX::Types::MooseLike::Base qw(:all);

use Params::Validate qw(:all);
use Carp;
use autodie;

has posfile => (
    is => 'ro',
    isa => Str,
    required => 1,
);

# TODO - role?
has read_only => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

sub position {
    my $self = shift;
    return 0 unless -e $self->posfile;
    open my $fh, '<', $self->posfile;
    my $position = join '', <$fh>;
    chomp $position;
    unless ($position =~ /^\d+$/) {
        die "Invalid position in posfile ".$self->posfile;
    }
    return $position;
}

sub set_position {
    my $self = shift;
    my ($position) = validate_pos(@_, { type => SCALAR, regex => qr/^\d+$/ });
    croak "Cursor is read-only" if $self->read_only;

    my $posfile = $self->posfile;
    my $posfile_new = "$posfile.new";
    open my $fh, '>', $posfile_new;
    print {$fh} "$position\n"; # adding \n for the better readability
    close $fh; # TODO - should we fsync? at least optionally?
    rename $posfile_new => $posfile;
    return;
}

1;

__END__

=pod

=head1 NAME

Flux::File::Cursor - file cursor

=head1 VERSION

version 1.01

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
