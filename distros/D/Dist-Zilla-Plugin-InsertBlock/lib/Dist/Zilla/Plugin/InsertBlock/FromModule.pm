package Dist::Zilla::Plugin::InsertBlock::FromModule;

use 5.010001;
use strict;
use warnings;

use Module::Path::More qw(module_path);

use parent qw(Dist::Zilla::Plugin::InsertBlock);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-09-16'; # DATE
our $DIST = 'Dist-Zilla-Plugin-InsertBlock'; # DIST
our $VERSION = '0.103'; # VERSION

sub BUILD {
    my $self = shift;

    if ($self->zilla->plugin_named('InsertBlock')) {
        # if user also loads InsertBlock plugin, use another directive so the
        # two don't clash
        $self->_directive_re(qr/INSERT_BLOCK_FROM_MODULE/);
    } else {
        $self->_directive_re(qr/INSERT_BLOCK(?:_FROM_MODULE)?/);
    }
}

sub _insert_block {
    my($self, $module, $name, $target) = @_;

    local @INC = ("lib", @INC);
    my $file = module_path(module=>$module) or
        $self->log_fatal(["can't find path for module %s", $module]);

    $self->SUPER::_insert_block($file, $name, $target);
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Insert a block of text from another module

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::InsertBlock::FromModule - Insert a block of text from another module

=head1 VERSION

This document describes version 0.103 of Dist::Zilla::Plugin::InsertBlock::FromModule (from Perl distribution Dist-Zilla-Plugin-InsertBlock), released on 2021-09-16.

=head1 SYNOPSIS

In dist.ini:

 [InsertBlock::FromModule]

In lib/Baz.pm:

 ...

 # BEGIN_BLOCK: some_code

 ...

 # END_BLOCK

In lib/Foo/Base.pm:

 ...

 =head1 ATTRIBUTES

 =for BEGIN_BLOCK: base_attributes

 =head2 attr1

 =head2 attr2

 =for END_BLOCK: base_attributes

 ...

In lib/Foo/Bar.pm:

 ...

 # INSERT_BLOCK_FROM_MODULE: Bar some_code

 ...

 =head1 ATTRIBUTES

 # INSERT_BLOCK_FROM_MODULE: Foo::Base base_attributes

 =head2 attr3

 ...

=head1 DESCRIPTION

This plugin is just like L<Dist::Zilla::Plugin::InsertBlock>, but instead of
filename in the first argument, you specify module name. Module name will then
be converted into path using L<Module::Path::More>. Die when module path is not
found.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-InsertBlock>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-InsertBlock>.

=head1 SEE ALSO

L<Dist::Zilla::Plugin::InsertBlock>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2016, 2015 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-InsertBlock>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
