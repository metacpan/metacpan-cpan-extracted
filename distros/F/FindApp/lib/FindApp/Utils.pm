package FindApp::Utils;

use v5.10;
use strict;
use warnings;

use Exporter qw(import);
our %EXPORT_TAGS;

use FindApp::Utils::List    qw(uniq);
use FindApp::Utils::Package qw(PACKAGE);
use FindApp::Utils::Paths   qw(basename_noext dir_file_ext);

my $submod_glob; {
   my($dir, $file, $ext) = dir_file_ext $INC{PACKAGE->pmpath};
   $submod_glob = "$dir$file/*$ext";
}

for my $tail (map { basename_noext } glob $submod_glob) {
    my $module = PACKAGE->add($tail);
    eval qq{use $module ':all'; 1} || die;
    my $his_tags = $module->add("EXPORT_TAGS")->unbless;
    no strict "refs";
    while (my($sub_tag, $aref) = each %$his_tags) {
        next if $sub_tag eq "all";
        if ($EXPORT_TAGS{$sub_tag}) {
           warn "ignoring duplicate export tag $sub_tag from $module";
           next;
        } 
        $EXPORT_TAGS{$sub_tag} = $aref;
    }
    $EXPORT_TAGS{lc $tail} = $his_tags->{all};
}

our @EXPORT_OK = uniq sort map { @$_ } values %EXPORT_TAGS;

$EXPORT_TAGS{all} = \@EXPORT_OK;

1;

=encoding utf8

=head1 NAME

FindApp::Utils - FIXME

=head1 SYNOPSIS

 use FindApp::Utils;

=head1 DESCRIPTION

=head2 Public Methods

=over

=item FIXME

=back

=head2 Exports

=over

=item FIXME

=back

=head1 EXAMPLES

=head1 ENVIRONMENT

=head1 SEE ALSO

=over

=item L<FindApp>

=back

=head1 CAVEATS AND PROVISOS

=head1 BUGS AND LIMITATIONS

=head1 HISTORY

=head1 AUTHOR

Tom Christiansen << <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

