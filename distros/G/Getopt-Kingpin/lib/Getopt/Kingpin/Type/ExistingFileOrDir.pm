package Getopt::Kingpin::Type::ExistingFileOrDir;
use 5.008001;
use strict;
use warnings;
use Carp;
use Path::Tiny;

our $VERSION = "0.08";

sub set_value {
    my $self = shift;
    my ($value) = @_;

    my $p = path($value);
    if ($p->exists) {
        # ok
    } else {
        printf STDERR "error: path '%s' does not exist, try --help\n", $value;
        return undef, 1;
    }
    return $p;
}

1;
__END__

=encoding utf-8

=head1 NAME

Getopt::Kingpin::Type::ExistingFileOrDir - command line option object

=head1 SYNOPSIS

    use Getopt::Kingpin;
    my $kingpin = Getopt::Kingpin->new;
    my $lib_dir = $kingpin->flag('lib_dir', 'set lib_dir')->existing_file_or_dir();
    $kingpin->parse;

    printf "lib_dir : %s\n", $lib_dir;

=head1 DESCRIPTION

Getopt::Kingpin::Type::ExistingFileOrDir は、Getopt::Kingpin内で使用する型定義です。

=head1 METHOD

=head2 set_value($value)

$self->valueに値を設定します。
値は、Path::Tinyによって処理されます。
必ず存在するfileもしくはdirectoryである必要があります。

=head1 LICENSE

Copyright (C) sago35.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

sago35 E<lt>sago35@gmail.comE<gt>

=cut

