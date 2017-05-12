package Dist::Zilla::Role::Rinci::CheckDefinesMeta;

our $DATE = '2016-01-17'; # DATE
our $VERSION = '0.04'; # VERSION

use 5.010001;
use Moose::Role;

sub check_dist_defines_rinci_meta {
    no strict 'refs';

    my $self = shift;

    # cache result
    state $res;
    return $res if defined $res;

    $res = 0;

    {
        my $files = $self->zilla->find_files(':InstallModules');
        local @INC = ("lib", @INC);
        for my $file (@$files) {
            my $name = $file->name;
            next if $name =~ /\.pod\z/i;
            $name =~ s!\Alib/!!;
            require $name;
            my $pkg = $name; $pkg =~ s/\.pm\z//; $pkg =~ s!/!::!g;
            if (keys %{"$pkg\::SPEC"}) {
                $self->log_debug(["Found that %%%s\::SPEC contains stuffs",
                                  $pkg]);
                $res = 1;
                goto DONE;
            }
        }
    }

    {
        require File::Temp;
        require PPI::Document;
        my $files = $self->zilla->find_files(':ExecFiles');
        for my $file (@$files) {
            my $path = do {
                # even though file is a DZF:OnDisk, name() won't always be the
                # actual path (e.g. when we use DZP:AddFile::FromFS which
                # creates a DZF:OnDisk object which points to src but then
                # re-set the name to dest), so in any case we need to write to
                # tempfile first
                my ($temp_fh, $temp_path) = File::Temp::tempfile();
                print $temp_fh $file->content;
                $temp_path;
            };
            #$self->log(["path=%s (exists? %s)", $path, ((-f $path) ? 1:0)]);
            my $doc = PPI::Document->new($path);
            for my $node ($doc->children) {
                next unless $node->isa("PPI::Statement");
                my @chld = $node->children;
                next unless @chld;
                next unless $chld[0]->isa("PPI::Token::Symbol") &&
                    $chld[0]->content =~ /\A\$(main::)?SPEC\z/;
                my $i = 1;
                while ($i < @chld) {
                    last unless $chld[$i]->isa("PPI::Token::Whitespace");
                    $i++;
                }
                next unless $i < @chld;
                next unless $chld[$i]->isa("PPI::Structure::Subscript") &&
                    $chld[$i]->content =~ /\A\{/;
                $i++;
                while ($i < @chld) {
                    last unless $chld[$i]->isa("PPI::Token::Whitespace");
                    $i++;
                }
                next unless $i < @chld;
                next unless $chld[$i]->isa("PPI::Token::Operator") &&
                    $chld[$i]->content eq '=';
                $self->log_debug(
                    ['Found that %s contains assignment to $SPEC{...}',
                     $file->name]);
                $res = 1;
                goto DONE;
            }
        }
    }

  DONE:
    $res;
}

no Moose::Role;
1;
# ABSTRACT: Role to check if dist defines Rinci metadata

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Rinci::CheckDefinesMeta - Role to check if dist defines Rinci metadata

=head1 VERSION

This document describes version 0.04 of Dist::Zilla::Role::Rinci::CheckDefinesMeta (from Perl distribution Dist-Zilla-Role-Rinci-CheckDefinesMeta), released on 2016-01-17.

=head1 METHODS

=head2 $obj->check_dist_defines_rinci_meta => bool

Will return true if dist defines Rinci metadata. Currently this is done via the
following: 1) load all the module files and check whether C<%SPEC> in the
corresponding package contains stuffs; 2) analyze all the scripts using L<PPI>
and try to find any assignment like C<< $SPEC{something} = { ... } >> (this
might miss some stuffs).

=head1 SEE ALSO

L<Rinci>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Role-Rinci-CheckDefinesMeta>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Role-Rinci-CheckDefinesMeta>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Role-Rinci-CheckDefinesMeta>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
