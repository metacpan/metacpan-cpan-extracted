package Dist::Zilla::Plugin::ReversionAfterRelease;
our $VERSION = '0.2';
use Moose;
extends 'Dist::Zilla::Plugin::ReversionOnRelease';
with 'Dist::Zilla::Role::AfterRelease';

# Don't munge files before release
sub munge_files { }

# Munge files after release
sub after_release {
    my $self = shift;
    $self->SUPER::munge_files;
    for my $file (@{ $self->found_files }) {
        open my $fh, '>:raw:encoding('.$file->encoding.')', $file->name
            or die "Can't write ".$file->name.": $!";
        print $fh $file->content;
        close $fh
            or die "Can't write ".$file->name.": $!";
    }
    return;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=encoding utf-8

=head1 NAME

Dist::Zilla::Plugin::ReversionAfterRelease - Bump and reversion after distribution release

=head1 SYNOPSIS

  [VersionFromModule]
  [UploadToCPAN]
  [CopyFilesFromRelease]
  filename = Changes
  
  ; commit source files as of "dzil release" with any
  ; allowable modifications (e.g Changes)
  [Git::Commit / Commit_This_Release] ; commit files/Changes (as released)
  commit_msg = Release %v
  
  ; tag as of "dzil release"
  [Git::Tag]
  
  ; update Changes with timestamp of release
  [NextRelease]
  
  [ReversionAfterRelease]
  
  ; commit source files after modification
  [Git::Commit / Commit_Next_Version] ; commit Changes/version (for new dev)
  allow_dirty =
  allow_dirty_match =
  commit_msg = Bump Version to %v

=head1 DESCRIPTION

This Dist::Zilla plugin will bump the version of your module I<after> a successful release.

Similar to L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease> but uses the more permisable reversioning from L<ReversionOnRelease|Dist::Zilla::Plugin::ReversionOnRelease>.

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<ReversionOnRelease|Dist::Zilla::Plugin::ReversionOnRelease>,
L<BumpVersionAfterRelease|Dist::Zilla::Plugin::BumpVersionAfterRelease>.
 
Dist::Zilla roles:
L<AfterRelease|Dist::Zilla::Plugin::AfterRelease>,
L<FileMunger|Dist::Zilla::Role::FileMunger>.

=head1 AUTHOR

Vernon Lyon E<lt>vlyon@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2018 Vernon Lyon

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
