package List::Flatten::XS;
use strict;
use warnings;

our $VERSION = '0.02';

use XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

require Exporter;
our @ISA = qw/Exporter/;
our @EXPORT_OK = qw/flatten/;

1;
__END__

=encoding utf-8

=head1 NAME

List::Flatten::XS - L<List::Flatten> with XS

=head1 SYNOPSIS
    
    use List::Flatten::XS 'flatten';

    my $ref_1 = +{a => 10, b => 20, c => 'Hello'};
    my $ref_2 = bless +{a => 10, b => 20, c => 'Hello'}, 'Nyan';
    my $ref_3 = bless $ref_2, 'Waon';

    my $complex_list = [[["foo", "bar", 3], "baz", 5], $ref_1, "hoge", [$ref_2, ["huga", [1], "K"], $ref_3]];

    # got: ["foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3];
    my $flatted = flatten($complex_list);

    # got: ("foo", "bar", 3, "baz", 5, $ref_1, "hoge", $ref_2, "huga", 1, "K", $ref_3);
    my @flatted_with_array = flatten($complex_list);

    # got: [["foo", "bar", 3], "baz", 5, $ref_1, "hoge", $ref_2, ["huga", [1], "K"], $ref_3]
    my $flatted_level = flatten($complex_list, 1);

    # got: (["foo", "bar", 3], "baz", 5, $ref_1, "hoge", $ref_2, ["huga", [1], "K"], $ref_3)
    my @flatted_level_with_array = flatten($complex_list, 1);

=head1 DESCRIPTION

List::Flatten::XS is provided flatten routine like L<Ruby's Array.flatten|https://ruby-doc.org/core-2.2.0/Array.html#method-i-flatten>.
So, you can flat complex list with simply or you can flat with specify nested level.

=head1 LICENSE

Copyright (C) CodeHex.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

K E<lt>x00.x7f@gmail.comE<gt>

=cut

