# Copyright (c) 2024-2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: generic module for extracting information from filesystems


package File::Information::VerifyResult;

use v5.10;
use strict;
use warnings;

use parent 'File::Information::VerifyBase';

use Carp;

use File::Information::VerifyTestResult;

our $VERSION = v0.07;

# ----------------

sub _new {
    my ($pkg, %opts) = @_;
    my $self = $pkg->SUPER::_new(%opts);
    my %tests;
    my $failed;
    my %passed_by_class;

    $self->{tests} = \%tests;

    foreach my $name (File::Information::VerifyTestResult->_supported_tests) {
        my $res = File::Information::VerifyTestResult->_new(test => $name, %opts{'instance', 'base', 'base_from', 'base_to', 'extractor', 'db', 'lifecycle_from', 'lifecycle_to'});
        my $class = $res->can('_class') ? $res->_class : $res->isa(__PACKAGE__) ? File::Information::VerifyTestResult->CLASS_STRONG : File::Information::VerifyTestResult->CLASS_WEAK;
        $tests{$name} = $res;

        $failed ||= $res->has_failed;
        $passed_by_class{$class} ||= $res->has_passed;
    }

    if ($failed) {
        $self->{status} = $pkg->STATUS_FAILED;
    } elsif ($passed_by_class{File::Information::VerifyTestResult->CLASS_METADATA} && $passed_by_class{File::Information::VerifyTestResult->CLASS_STRONG}) {
        $self->{status} = $pkg->STATUS_PASSED;
    } elsif (scalar grep {$_} values %passed_by_class) {
        $self->{status} = $pkg->STATUS_INSUFFICIENT_DATA;
    } else {
        $self->{status} = $pkg->STATUS_NO_DATA;
    }

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::Information::VerifyResult - generic module for extracting information from filesystems

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use File::Information;

    my File::Information::Inode $inode = ...;

    my File::Information::VerifyResult $result = $inode->verify;

    my $passed = $base->has_passed;

This package inherits from L<File::Information::VerifyBase>.

=head1 METHODS

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
