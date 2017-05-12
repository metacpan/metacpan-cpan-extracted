package Dist::Zilla::Plugin::IfBuilt;

our $DATE = '2015-06-17'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010001;
use strict;
use warnings;

use String::CommonPrefix qw(common_prefix);

use Moose;
with (
    'Dist::Zilla::Role::FileMunger',
    'Dist::Zilla::Role::FileFinderUser' => {
        default_finders => [':InstallModules', ':ExecFiles'],
    },
);

use namespace::autoclean;

sub munge_files {
    my $self = shift;

    $self->munge_file($_) for @{ $self->found_files };
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;
    my $code_comment_or_uncomment = sub {
        my ($header, $lines) = @_;
        if ($header =~ /IFBUILT/) {
            # require that the lines are all commented
            my $common_prefix = common_prefix(split /^/, $lines) // '';
            unless ($common_prefix =~ /^(\s*)(#\s*)/) {
                $self->log_fatal(["All lines inside #IFBUILT section needs to be commented: <%s>", $lines]);
            }
            my ($indent, $comment) = ($1, $2);
            # uncomment the lines
            $lines =~ s/^\Q$indent$comment/$indent/gm;
        } else {
            # comment the lines
            $lines =~ s/^/# /gm;
        }
        $lines;
    };
    if ($content =~ s{^(#\s*(IFBUILT|IFUNBUILT)\R)(.*?^)(#\s*END \2)}
                     {$1 . $code_comment_or_uncomment->($1, $3) . $4}egms) {
        $self->log_debug(["Processing #IFBUILT/#IFUNBUILT sections in %s", $file->name]);
        $file->content($content);
    }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Use code only in built (or unbuilt/raw) version

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::IfBuilt - Use code only in built (or unbuilt/raw) version

=head1 VERSION

This document describes version 0.02 of Dist::Zilla::Plugin::IfBuilt (from Perl distribution Dist-Zilla-Plugin-IfBuilt), released on 2015-06-17.

=head1 SYNOPSIS

In F<dist.ini>:

 [IfBuilt]
 [InsertBlock::FromModule]

In F<lib/Foo.pm>:

 ...
 # IFUNBUILT
 use warnings;
 # END IFUNBUILT

 # IFBUILT
 ##INSERT_BLOCK Function::Embeddable uniq
 # END IFBUILT
 # IFUNBUILT
 use List::MoreUtils 'uniq';
 # END IFUNBUILT
 ...

After build, the above section will become:

 ...
 # IFUNBUILT
 # use warnings;
 # END IFUNBUILT

 # IFBUILT
 sub uniq (@) {
     my %seen = ();
     my $k;
     my $seen_undef;
     grep { defined $_ ? not $seen{ $k = $_ }++ : not $seen_undef++ } @_;
 }
 # END IFBUILT
 # IFUNBUILT
 # use List::MoreUtils 'uniq';
 # END IFBUILT
 ...

=head1 DESCRIPTION

This plugin finds blocks like this:

 # IFBUILT
 # ...
 # END IFBUILT

or this:

 # IFUNBUILT
 ...
 # END IFBUILT

in your modules and scripts. All the lines inside C<# IFBUILT> ... C<# END
IFBUILT> must all be commented-out, and they will be uncommented (one character
C<#> removed from each line) in the built version. On the other hand, all the
lines inside C<# IFUNBUILT> ... C<# END IFUNBUILT> will be commented (one
character C<#> added to each line) in the built version.

This plugin is useful when you want to have code that is only present in the
built/unbuilt version. One use-case is when you want to replace a routine with
an inlined version in the built edition, like the example in Synopsis. In the
unbuilt/raw version, the routine is retrieved from a module. This allows testing
to work either with the unbuilt version (e.g. using C<< prove -l >>) or the
built version (e.g. using C<< dzil test >>).

=for Pod::Coverage .+

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock>,
L<Dist::Zilla::Plugin::InsertBlock::FromModule>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-IfBuilt>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-IfBuilt>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-IfBuilt>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
