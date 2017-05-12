package Dist::Zilla::Plugin::Preload;

# DISABLE_PRELOAD
our $DATE = '2015-03-24'; # DATE
our $VERSION = '0.01'; # VERSION

use 5.010001;
use strict;
use warnings;

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

sub _add_preload {
    my ($self, $preloads, $filename, $str, $line) = @_;

    unless ($str =~ /^\s*require\s+(\w+(?:::\w+)*)\s*;\s*$/) {
        $self->log_fatal(["File %s: Syntax error on preload line: '%s', should be: 'require someModule; #PRELOAD'"], $filename, $line);
    }
    $preloads->{$1}++;
}

sub munge_file {
    my ($self, $file) = @_;
    my $content = $file->content;

    return if $content =~ /^#\s*DISABLE_PRELOAD\s*$/m;

    my %preloads;
    while ($content =~ /^((.*)#\s*PRELOAD)\s*$/gm) {
        $self->_add_preload(\%preloads, $file->name, $2, $1);
    }

    return unless keys %preloads;

    $self->log(["File %s: Found modules to preload: %s", $file->name, [sort keys %preloads]]);

    undef $self->{_cond};
    unless ($content =~ s{^(\s*)(#\s*INSERT_PRELOADS:\s*(.+))\s*$}{$1 . $self->_insert_preloads(\%preloads, $file->name, $3)." $2\n"}egm) {
        $self->log_fatal(["File %s: contains #PRELOAD's but no line with correct #INSERT_PRELOADS found"], $file->name);
    }
    $content =~ s!^(\s*)(.*?)\s*(#\s*PRELOAD)\s*$!${1}unless ($self->{_cond}) { $2 } $3!mg;

    $file->content($content);
}

sub _insert_preloads {
    my($self, $preloads, $filename, $cond) = @_;

    $self->{_cond} = $cond;
    "if ($cond) { ".join("; ", map {"require $_"} sort keys %$preloads)." }";
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Preload modules on some condition

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Preload - Preload modules on some condition

=head1 VERSION

This document describes version 0.01 of Dist::Zilla::Plugin::Preload (from Perl distribution Dist-Zilla-Plugin-Preload), released on 2015-03-24.

=head1 SYNOPSIS

In dist.ini:

 [Preload]

In lib/MyMain.pm:

 package MyMain;
 use constant PRELOAD_MODULES => $ENV{PRELOAD};

In lib/MyOther.pm:

 use MyMain;

 # INSERT_PRELOADS: MyMain::PRELOAD_MODULES

 sub foo {
     require Data::Dump; # PRELOAD
     ...
 }

 sub bar {
     require Text::ANSITable; # PRELOAD
     ...
 }

 ...

After build, lib/MyOther.pm will become:

 use MyMain;
 if (MyMain::PRELOAD_MODULES) { require Data::Dump; require Text::ANSITable; } # INSERT_PRELOADS: MyMain::PRELOAD_MODULES

 sub foo {
     unless (MyMain::PRELOAD_MODULES) { require Data::Dump } # PRELOAD
     ...
 }

 sub bar {
     unless (MyMain::PRELOAD_MODULES) { require Text::ANSITable } # PRELOAD
     ...
 }

 ...

=head1 DESCRIPTION

This plugin is a Dist::Zilla-based alternative to L<preload>, please read the
rationale of that module first.

First, this plugin will search C<# PRELOAD> directives in a script/module file.
The line must be in the form of:

 require SomeModule; # PRELOAD

Then, this plugin will search for C<# INSERT_PRELOADS: condition> directive. The
directive must exist if there are C<# PRELOAD> directives in the same file.
I<condition> is a Perl expression that should determine whether modules should
be preloaded. To allow Perl to optimize things away, the expression should be a
constant, like in the example above.

This plugin will replace this line:

 # INSERT_PRELOADS: condition

to this:

 if (condition) { require SomeModule; require AnotherModule; ... } # INSERT_PRELOADS: condition

where each module mentioned in C<# PRELOAD> lines will be put in.

Finally, the C<# PRELOAD> lines will also be changed, from:

 require SomeModule; # PRELOAD

to:

 unless (condition) { require SomeModule } # PRELOAD

The final effect is, if preloading is turned on, then modules will be loaded by
the C<# INSERT_PRELOADS> line and the C<# PRELOAD> lines will become no-ops. On
the other hand if preloading is turned off, C<# INSERT_PRELOADS> line will
become a no-op while C<# PRELOAD> lines will load the modules as usual.

=for Pod::Coverage .+

=head1 SEE ALSO

L<preload>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-Preload>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-Preload>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-Preload>

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
