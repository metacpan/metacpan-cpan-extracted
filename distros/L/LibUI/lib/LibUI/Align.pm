package LibUI::Align 0.01 {
    use 5.008001;
    use strict;
    use warnings;
    use Affix;
    use parent 'Exporter';
    my @enum = qw[Fill Start Center End];
    typedef 'LibUI::Align' => Enum [@enum];
    our %EXPORT_TAGS;
    our @EXPORT_OK = @{ $EXPORT_TAGS{all} } = @enum;
};
1;
#
__END__

=pod

=encoding utf-8

=head1 NAME

LibUI::Align - Alignment Specifiers to Define Placement Within the Reserved
Area

=head1 SYNOPSIS

    use LibUI::Align qw[:all];

=head1 DESCRIPTION

These values are used by L<LibUI::Grid>. You may import them individually or
with the C<:all> tag.

=head1 Values

=over

=item C<Fill> - Fill area

=item C<Start> - Place at start

=item C<Center> - Place in center

=item C<End> - Place at end

=back

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

