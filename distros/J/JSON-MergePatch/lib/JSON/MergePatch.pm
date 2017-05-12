package JSON::MergePatch;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use parent 'Exporter';
use JSON::MaybeXS qw/encode_json decode_json/;
use List::MoreUtils qw/uniq/;
use Test::Deep::NoTest;

our @EXPORT = qw/json_merge_patch json_merge_diff/;


sub patch {
    my ($class, $target, $patch, $opt) = @_;
    if (defined $target && !$opt->{repeat}) {
        $target = decode_json($target);
    }

    if (ref $patch eq 'HASH') {
        unless (ref $target eq 'HASH') {
            $target = +{};
        }

        for my $key (keys %$patch) {
            if (defined $patch->{$key}) {
                $target->{$key} = __PACKAGE__->patch($target->{$key}, $patch->{$key}, {repeat => 1});
            }
            else {
                if (exists $target->{$key}) {
                    delete $target->{$key};
                }
            }
        }
        return ref $target ? encode_json($target) : $target;
    }

    return ref $patch ? encode_json($patch) : $patch;
}

sub diff {
    my ($class, $source, $target, $opt) = @_;

    my ($decoded_source, $decoded_target);
    if ($opt->{repeat}) {
        $decoded_source = $source;
        $decoded_target = $target;
    } else {
        $decoded_source = eval {
            decode_json($source);
        };
        if ($@) {
            return $source;
        }

        $decoded_target = eval {
            decode_json($target);
        };
        if ($@) {
            return $decoded_source;
        }
    }

    if (ref $decoded_source eq 'HASH' && ref $decoded_target eq 'HASH') {
        for my $key (uniq (keys %$decoded_target, keys %$decoded_source)) {
            $decoded_source->{$key} = __PACKAGE__->diff($decoded_source->{$key}, $decoded_target->{$key}, {repeat => 1});

            if (exists $decoded_target->{$key} && exists $decoded_source->{$key}) {
                if (
                    (!defined $decoded_target->{$key} && !defined $decoded_source->{$key}) ||
                    (defined $decoded_target->{$key} && defined $decoded_source->{$key} && $decoded_target->{$key} eq $decoded_source->{$key}) ||
                    (defined $decoded_target->{$key} && defined $decoded_source->{$key} && ref $decoded_source->{$key} eq 'HASH' && !%{$decoded_source->{$key}} && ref $decoded_target->{$key} eq 'HASH') ||
                    (defined $decoded_target->{$key} && defined $decoded_source->{$key} && ref $decoded_source->{$key} eq 'ARRAY' && eq_deeply($decoded_target->{$key}, $decoded_source->{$key}))
                ) {
                    delete $decoded_source->{$key};
                }
            }
        }
    }

    return $decoded_source;
}

sub json_merge_patch {
    __PACKAGE__->patch(@_);
}

sub json_merge_diff {
    __PACKAGE__->diff(@_);
}


1;
__END__

=encoding utf-8

=head1 NAME

JSON::MergePatch - JSON Merge Patch implementation

=head1 SYNOPSIS

    use JSON::MergePatch;
    use Test::More;

    my $target_json = '{"a":"b"}';
    my $patch = +{ 'a' => 'c' };

    my $result_json = json_merge_patch($target_json, $patch);
    my $diff = json_merge_diff($result_json, $target_json);

    is $result_json, '{"a":"c"}';
    is_deeply $diff, $patch;

    done_testing;

=head1 DESCRIPTION

JSON::MergePatch is JSON Merge Patch implementation for Perl.

=head1 METHODS

=head2 patch($target: Scalar, $patch: HashRef) :Scalar

This method merges patch into the target JSON.

    my $result_json = JSON::MergePatch->patch('{"a":"b"}', { 'a' => 'c' });
    # $result_json = '{"a":"c"}';

=head2 diff($source :Scalar, $target :Scalar) :HashRef

This method outputs diff between JSON.

    my $diff = JSON::MergePatch->diff('{"a":"c"}', '{"a":"b"}');
    # $diff = { 'a' => 'c' };

=head1 FUNCTIONS

=head2 json_merge_patch($target: Scalar, $patch: HashRef) :Scalar

Same as C<< patch() >> method.

=head2 json_merge_diff($source :Scalar, $target :Scalar) :HashRef

Same as C<< diff() >> method.

=head1 LICENSE

Copyright (C) Taishi Hiraga.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Taishi Hiraga E<lt>sojiro@cpan.orgE<gt>

=cut

