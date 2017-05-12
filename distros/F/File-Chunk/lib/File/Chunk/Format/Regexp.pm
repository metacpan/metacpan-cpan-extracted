# ABSTRACT: Chunk file regex base role

package File::Chunk::Format::Regexp;
{
  $File::Chunk::Format::Regexp::VERSION = '0.0035';
}
BEGIN {
  $File::Chunk::Format::Regexp::AUTHORITY = 'cpan:DHARDISON';
}
use Moose::Role;
use namespace::autoclean;

use MooseX::Params::Validate;
use MooseX::Types::Path::Class 'Dir', 'File';

use Path::Class::Rule;

with 'File::Chunk::Format';

requires 'chunk_regexp';

sub find_chunk_files {
    my $self = shift;
    my ($dir) = pos_validated_list( \@_, { isa => Dir, coerce => 1 } );

    my $rules = Path::Class::Rule->new->skip_vcs->file->name($self->chunk_regexp);

    return $rules->iter( $dir, { depthfirst => 1 } );
}

sub decode_chunk_filename {
    my $self = shift;
    my ($file) = pos_validated_list(\@_, { isa => File });

    my $re = $self->chunk_regexp;
    if ($file->basename =~ /^($re)$/) {
        return $1;
    }
    else {
        return undef;
    }
}


1;

__END__

=pod

=head1 NAME

File::Chunk::Format::Regexp - Chunk file regex base role

=head1 VERSION

version 0.0035

=head1 AUTHOR

Dylan William Hardison <dylan@hardison.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
