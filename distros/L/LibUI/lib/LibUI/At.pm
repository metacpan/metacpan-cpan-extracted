package LibUI::At 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'Exporter';
    my @enum = qw[Leading Top Trailing Bottom];
    typedef 'LibUI::At' => Enum [@enum];
    our %EXPORT_TAGS;
    our @EXPORT_OK = @{ $EXPORT_TAGS{all} } = @enum;
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::At - Placement Specifier to Define Placement in Relation to Another
Control

=head1 SYNOPSIS

    use LibUI::At qw[:all];

=head1 DESCRIPTION

These values are used by L<LibUI::Grid>. You may import them individually or
with the C<:all> tag.

=head1 Values

=over

=item C<Leading> - Place before control

=item C<Top> - Place above control

=item C<Trailing> - Place behind control

=item C<Bottom> - Place below control

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

