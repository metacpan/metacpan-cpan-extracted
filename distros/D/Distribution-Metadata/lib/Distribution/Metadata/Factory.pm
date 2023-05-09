package Distribution::Metadata::Factory;
use v5.16;
use warnings;

use Distribution::Metadata;

sub new {
    my ($class, %option) = @_;
    my $inc = $option{inc} || \@INC;
    if ($option{fill_archlib}) {
        $inc = Distribution::Metadata->_fill_archlib($inc);
    }
    bless { inc => $inc, cache => {} }, $class;
}

sub create_from_module {
    my ($self, $module) = @_;
    local $Distribution::Metadata::CACHE = $self->{cache};
    Distribution::Metadata->new_from_module($module, inc => $self->{inc});
}

sub create_from_file {
    my ($self, $file) = @_;
    local $Distribution::Metadata::CACHE = $self->{cache};
    Distribution::Metadata->new_from_file($file, inc => $self->{inc});
}

1;

__END__

=for stopwords packlist

=encoding utf-8

=head1 NAME

Distribution::Metadata::Factory - create Distribution::Metadata objects with cache

=head1 SYNOPSIS

    use Distribution::Metadata::Factory;

    my $factory = Distribution::Metadata::Factory->new(inc => \@INC);

    my $info1 = $factory->create_from_module("Moose");
    my $info2 = $factory->create_from_module("Plack");
    my $info3 = $factory->create_from_file("/path/to/Moo.pm");

=head1 DESCRIPTION

This module creates Distribution::Metadata objects with cache.

If you creates many Distribution::Metadata objects,
then it may take quite a lot of time.
This is because C<< Distribution::Metadata->new >> scans C<@INC> directories,
parses packlist files, and parses install.json files many times.

Distribution::Metadata::Factory caches such results,
so you can create Distribution::Metadata objects even faster.

=head1 LICENSE

Copyright (C) 2015 Shoichi Kaji

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Shoichi Kaji E<lt>skaji@cpan.orgE<gt>

=cut

