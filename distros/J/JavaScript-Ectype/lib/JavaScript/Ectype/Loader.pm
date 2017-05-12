package JavaScript::Ectype::Loader;
use strict;
use warnings;
use List::Util qw/max/;
use JavaScript::Ectype;
use base qw/Class::Accessor::Fast Class::Data::Inheritable/;

__PACKAGE__->mk_classdata( root_to_related_map => {});
__PACKAGE__->mk_accessors(qw/ectype/);

sub new{
    my ($class,%args) = @_;
    return bless {
        ectype => JavaScript::Ectype->new(%args)
    } ,$class;
}

sub is_modified_from{
    my ( $self,$from_time ) = @_;
    return ( $from_time < $self->newest_mtime ) ? 1 : 0;
}

sub get_content{
    my ($self) = @_;
    $self->ectype->convert;
}

sub load_content{
    my $self = shift;
    $self->ectype(
        JavaScript::Ectype->load(
            target => $self->ectype->target,
            path   => $self->ectype->path,
            minify => $self->ectype->minify,
        )
    );
    $self->root_to_related_map->{ $self->file_path } = [ $self->related_files ];
}

sub file_path{
    shift->ectype->file_path;
}

sub related_files{
    shift->ectype->related_files;
}

sub newest_mtime {
    my $self = shift;
    unless ( $self->root_to_related_map->{ $self->file_path } ) {
        $self->load_content;
    }
    return _newest_mtime( $self->file_path,
        @{ $self->root_to_related_map->{ $self->file_path } } );
}

sub _newest_mtime{
    my (@files) = @_;
    max map { -e $_ ? (stat $_)[9]: time } @files;
}


1;

__END__
=head1 NAME

JavaScript::Ectype::Loader - a JavaScript::Ectype wrapper 

=head1 SYNOPSYS


=head1 METHODS

=head2 new

=head2 file_path

=head2 related_files

=head2 get_content 

=head2 is_modified_from

=head2 load_content

=head2 newest_mtime

=head1 AUTHOR

Daichi Hiroki, C<< <hirokidaichi<AT>gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2009 Daichi Hiroki.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut



